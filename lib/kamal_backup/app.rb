require "fileutils"
require "tmpdir"
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

      adapter = database
      resolved_snapshot = resolve_snapshot(snapshot, tags: ["type:database", "adapter:#{adapter.adapter_name}"])
      filename = restic.database_file(resolved_snapshot, adapter.adapter_name)

      if filename
        adapter.restore(restic, resolved_snapshot, filename)
        true
      else
        raise ConfigurationError, "could not find database backup file in snapshot #{resolved_snapshot}"
      end
    end

    def restore_files(snapshot = "latest", target: "/restore/files")
      config.validate_restic
      config.validate_restore_allowed

      resolved_snapshot = resolve_snapshot(snapshot, tags: ["type:files"])
      validated_target = config.validate_file_restore_target(target)
      restic.restore_snapshot(resolved_snapshot, validated_target)
      true
    end

    def restore_local(snapshot = "latest")
      config.validate_local_restore

      restore_local_database(snapshot)
      restore_local_files(snapshot)
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

      def restore_local_database(snapshot)
        adapter = database
        resolved_snapshot = resolve_snapshot(snapshot, tags: ["type:database", "adapter:#{adapter.adapter_name}"])
        filename = restic.database_file(resolved_snapshot, adapter.adapter_name)

        if filename
          adapter.restore_local(restic, resolved_snapshot, filename)
        else
          raise ConfigurationError, "could not find database backup file in snapshot #{resolved_snapshot}"
        end
      end

      def restore_local_files(snapshot)
        resolved_snapshot = resolve_snapshot(snapshot, tags: ["type:files"])

        Dir.mktmpdir("kamal-backup-restore-") do |stage_dir|
          restic.restore_snapshot(resolved_snapshot, stage_dir)
          replace_local_backup_paths(stage_dir)
        end
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
