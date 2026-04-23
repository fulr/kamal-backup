require "json"
require "thor"
require_relative "app"
require_relative "redactor"
require_relative "version"

module KamalBackup
  class CLI < Thor
    class << self
      attr_accessor :command_env
    end

    package_name "kamal-backup"
    map %w[-v --version] => :version
    map "restore-db" => :restore_database
    map "restore-files" => :restore_files
    map "restore-local" => :restore_local
    remove_command :tree

    def self.basename
      "kamal-backup"
    end

    def self.start(argv = ARGV, env: ENV)
      self.command_env = env
      super(argv)
    rescue Error => e
      warn("kamal-backup: #{Redactor.new(env: env).redact_string(e.message)}")
      exit(1)
    rescue Interrupt
      warn("kamal-backup: interrupted")
      exit(130)
    ensure
      self.command_env = nil
    end

    def initialize(args = [], local_options = {}, config = {})
      super
      @app = App.new(env: self.class.command_env || ENV)
    end

    desc "backup", "Run one backup immediately"
    def backup
      app.backup
    end

    desc "restore-db [SNAPSHOT]", "Restore a database dump"
    def restore_database(snapshot = "latest")
      app.restore_database(snapshot)
    end

    desc "restore-files [SNAPSHOT] [TARGET_DIR]", "Restore backed up files into a target directory"
    def restore_files(snapshot = "latest", target_dir = "/restore/files")
      app.restore_files(snapshot, target: target_dir)
    end

    desc "restore-local [SNAPSHOT]", "Restore database and files into the current local environment"
    def restore_local(snapshot = "latest")
      app.restore_local(snapshot)
    end

    desc "drill [SNAPSHOT]", "Run a restore drill and record the result"
    method_option :local, type: :boolean, default: false, desc: "Restore into the current local database and file paths"
    method_option :check, type: :string, desc: "Run a verification command after the restore"
    method_option :"file-target", type: :string, default: "/restore/files", desc: "File restore target for non-local drills"
    def drill(snapshot = "latest")
      result = app.drill(
        snapshot,
        local: options[:local],
        check_command: options[:check],
        file_target: options[:"file-target"]
      )

      puts(JSON.pretty_generate(result))
      exit(1) if app.drill_failed?(result)
    end

    desc "list", "List matching restic snapshots"
    def list
      puts(app.snapshots)
    end

    desc "check", "Run restic check and record the latest result"
    def check
      puts(app.check)
    end

    desc "evidence", "Print redacted operational evidence as JSON"
    def evidence
      puts(app.evidence)
    end

    desc "schedule", "Run the foreground scheduler loop"
    def schedule
      app.schedule
    end

    desc "version", "Print the running kamal-backup version"
    def version
      puts(VERSION)
    end

    private
      attr_reader :app
  end
end
