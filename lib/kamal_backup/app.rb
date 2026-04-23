require "fileutils"
require "json"
require "time"
require "tmpdir"
require_relative "command"
require_relative "config"
require_relative "databases/base"
require_relative "databases/mysql"
require_relative "databases/postgres"
require_relative "databases/sqlite"
require_relative "evidence"
require_relative "redactor"
require_relative "restic"
require_relative "scheduler"

module KamalBackup
  class App
    attr_reader :config, :redactor

    def initialize(env: ENV, config: nil, redactor: nil, restic: nil, database: nil, evidence_class: Evidence, scheduler_class: Scheduler)
      @config = config || Config.new(env: env)
      @redactor = redactor || Redactor.new(env: @config.env)
      @restic = restic
      @database = database
      @evidence_class = evidence_class
      @scheduler_class = scheduler_class
    end

    def backup
      config.validate_backup

      timestamp = current_timestamp
      restic.ensure_repository
      database.backup(restic, timestamp)
      restic.backup_paths(config.backup_paths, tags: ["type:files", "run:#{timestamp}"])

      if config.forget_after_backup?
        restic.forget_after_success
      end

      if config.check_after_backup?
        restic.check
      end

      true
    end

    def restore_database(snapshot = "latest")
      config.validate_restic
      config.validate_restore_allowed

      perform_database_restore(snapshot)
      true
    end

    def restore_files(snapshot = "latest", target: "/restore/files")
      config.validate_restic
      config.validate_restore_allowed

      perform_file_restore(snapshot, target: target)
      true
    end

    def restore_local(snapshot = "latest")
      config.validate_local_restore

      perform_database_restore(snapshot, local: true)
      perform_local_file_restore(snapshot)
      true
    end

    def drill(snapshot = "latest", local: false, check_command: nil, file_target: "/restore/files")
      started_at = Time.now.utc
      result = {
        status: "ok",
        mode: local ? "local" : "targeted",
        operator: drill_operator,
        requested_snapshot: snapshot,
        started_at: started_at.iso8601
      }

      begin
        if local
          config.validate_local_restore
          result[:database] = perform_database_restore(snapshot, local: true)
          result[:files] = perform_local_file_restore(snapshot)
        else
          config.validate_restic
          config.validate_restore_allowed
          result[:database] = perform_database_restore(snapshot)
          result[:files] = perform_file_restore(snapshot, target: file_target)
        end

        if check_command
          result[:check] = run_drill_check(check_command)

          if result[:check][:status] == "failed"
            result[:status] = "failed"
            result[:error] = result[:check][:error]
          end
        end
      rescue StandardError => e
        result[:status] = "failed"
        result[:error] = redactor.redact_string(e.message)
      ensure
        result[:finished_at] = Time.now.utc.iso8601
        write_last_restore_drill(result)
      end

      result
    end

    def drill_failed?(result)
      result.fetch(:status) != "ok"
    rescue KeyError
      true
    end

    def snapshots
      config.validate_restic
      restic.snapshots.stdout
    end

    def check
      config.validate_restic
      restic.check.stdout
    end

    def evidence
      config.validate_restic
      @evidence_class.new(config, restic: restic, redactor: redactor).to_json
    end

    def schedule
      config.validate_backup
      @scheduler_class.new(config) { backup }.run
    end

    private
      def current_timestamp
        Time.now.utc.strftime("%Y%m%dT%H%M%SZ")
      end

      def perform_database_restore(snapshot, local: false)
        adapter = database
        resolved_snapshot = resolve_snapshot(snapshot, tags: ["type:database", "adapter:#{adapter.adapter_name}"])
        filename = restic.database_file(resolved_snapshot, adapter.adapter_name)

        if filename
          if local
            adapter.restore_local(restic, resolved_snapshot, filename)
          else
            adapter.restore(restic, resolved_snapshot, filename)
          end

          {
            snapshot: resolved_snapshot,
            adapter: adapter.adapter_name,
            filename: filename,
            target: restore_database_target(adapter, local: local)
          }
        else
          raise ConfigurationError, "could not find database backup file in snapshot #{resolved_snapshot}"
        end
      end

      def perform_file_restore(snapshot, target:)
        resolved_snapshot = resolve_snapshot(snapshot, tags: ["type:files"])
        validated_target = config.validate_file_restore_target(target)
        restic.restore_snapshot(resolved_snapshot, validated_target)

        {
          snapshot: resolved_snapshot,
          target: validated_target
        }
      end

      def perform_local_file_restore(snapshot)
        resolved_snapshot = resolve_snapshot(snapshot, tags: ["type:files"])
        Dir.mktmpdir("kamal-backup-restore-") do |stage_dir|
          restic.restore_snapshot(resolved_snapshot, stage_dir)
          replace_local_backup_paths(stage_dir)
        end

        {
          snapshot: resolved_snapshot,
          source_paths: config.local_restore_source_paths,
          target_paths: config.backup_paths
        }
      end

      def replace_local_backup_paths(stage_dir)
        config.local_restore_path_pairs.each do |source_path, target_path|
          replace_local_backup_path(stage_dir, source_path, target_path)
        end
      end

      def replace_local_backup_path(stage_dir, source_path, target_path)
        source = staged_backup_path(stage_dir, source_path)
        target = File.expand_path(target_path)

        if File.exist?(source)
          FileUtils.rm_rf(target)
          FileUtils.mkdir_p(File.dirname(target))
          FileUtils.mv(source, target)
        else
          raise ConfigurationError, "restored file snapshot is missing #{source_path}"
        end
      end

      def staged_backup_path(stage_dir, path)
        File.join(stage_dir, path.to_s.sub(%r{\A/+}, ""))
      end

      def restore_database_target(adapter, local:)
        target = if local
          adapter.local_restore_target_identifier
        else
          adapter.restore_target_identifier
        end

        redactor.redact_string(target.to_s)
      end

      def run_drill_check(command)
        result = Command.capture(
          CommandSpec.new(argv: ["sh", "-lc", command]),
          redactor: redactor
        )
        output = result.stdout.empty? ? result.stderr : result.stdout

        {
          status: "ok",
          command: redactor.redact_string(command),
          output: redactor.redact_string(output.strip)
        }
      rescue CommandError => e
        {
          status: "failed",
          command: redactor.redact_string(command),
          error: redactor.redact_string(e.message)
        }
      end

      def write_last_restore_drill(payload)
        FileUtils.mkdir_p(config.state_dir)
        File.write(config.last_restore_drill_path, JSON.pretty_generate(payload))
      rescue SystemCallError
        nil
      end

      def drill_operator
        config.value("USER") || config.value("USERNAME")
      end

      def restic
        @restic ||= Restic.new(config, redactor: redactor)
      end

      def database
        @database ||= Databases::Base.build(config, redactor: redactor)
      end

      def resolve_snapshot(argument, tags:)
        if argument == "latest"
          snapshot = restic.latest_snapshot(tags: tags)

          if snapshot
            snapshot["short_id"] || snapshot["id"]
          else
            raise ConfigurationError, "no restic snapshot found for #{tags.join(", ")}"
          end
        else
          argument
        end
      end
  end
end
