require "fileutils"
require "tempfile"
require_relative "base"

module KamalBackup
  module Databases
    class Sqlite < Base
      def adapter_name
        "sqlite"
      end

      def dump_extension
        "sqlite3"
      end

      def backup(restic, timestamp)
        source = sqlite_source
        Tempfile.create(["kamal-backup-", ".sqlite3"]) do |tempfile|
          tempfile.close
          Command.capture(
            CommandSpec.new(argv: ["sqlite3", source, ".backup #{sqlite_literal(tempfile.path)}"]),
            redactor: redactor
          )
          restic.backup_file(
            tempfile.path,
            filename: database_filename(timestamp),
            tags: backup_tags(timestamp)
          )
        end
      end

      def restore(restic, snapshot, filename)
        validate_restore_target
        restic.write_dump_to_path(snapshot, filename, restore_target)
      end

      def restore_local(restic, snapshot, filename)
        validate_local_restore_target
        restic.write_dump_to_path(snapshot, filename, sqlite_source)
      end

      def dump_command
        raise NotImplementedError, "SQLite backup uses .backup into a temporary file"
      end

      def restore_command
        raise NotImplementedError, "SQLite restore writes the database file directly"
      end

      def restore_target_identifier
        restore_target
      end

      def local_restore_target_identifier
        sqlite_source
      end

      private
        def sqlite_source
          config.required_value("SQLITE_DATABASE_PATH")
        end

        def restore_target
          config.required_value("RESTORE_SQLITE_DATABASE_PATH")
        end

        def validate_restore_target
          source = File.expand_path(sqlite_source)
          target = File.expand_path(restore_target)
          if source == target && !config.allow_in_place_file_restore?
            raise ConfigurationError, "refusing in-place SQLite restore to #{target}; set KAMAL_BACKUP_ALLOW_IN_PLACE_FILE_RESTORE=true to override"
          end

          super
        end

        def validate_local_restore_target
          config.validate_local_database_restore_target(local_restore_target_identifier)
        end

        def sqlite_literal(value)
          "'#{value.to_s.gsub("'", "''")}'"
        end
    end
  end
end
