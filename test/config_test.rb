require_relative "test_helper"

class ConfigTest < Minitest::Test
  def test_detects_postgres_from_database_url
    config = KamalBackup::Config.new(env: base_env("DATABASE_URL" => "postgres://app@db/app"))

    assert_equal "postgres", config.database_adapter
  end

  def test_detects_mysql_from_mysql2_database_url
    config = KamalBackup::Config.new(env: base_env("DATABASE_URL" => "mysql2://app@db/app"))

    assert_equal "mysql", config.database_adapter
  end

  def test_detects_sqlite_from_path
    config = KamalBackup::Config.new(env: base_env("SQLITE_DATABASE_PATH" => "/data/db.sqlite3"))

    assert_equal "sqlite", config.database_adapter
  end

  def test_parses_colon_and_newline_backup_paths
    config = KamalBackup::Config.new(env: base_env("BACKUP_PATHS" => "/data/storage:/data/uploads\n/data/other"))

    assert_equal ["/data/storage", "/data/uploads", "/data/other"], config.backup_paths
  end

  def test_loads_local_yaml_config_from_the_current_project
    Dir.mktmpdir do |dir|
      config_dir = File.join(dir, "config")
      FileUtils.mkdir_p(config_dir)
      File.write(
        File.join(config_dir, "kamal-backup.local.yml"),
        <<~YAML
          app_name: local-app
          database_adapter: sqlite
          sqlite_database_path: tmp/development.sqlite3
          backup_paths:
            - storage
            - tmp/uploads
          local_restore_source_paths:
            - /data/storage
            - /data/uploads
        YAML
      )

      config = KamalBackup::Config.new(env: { "RESTIC_REPOSITORY" => "/tmp/restic", "RESTIC_PASSWORD" => "secret" }, cwd: dir)

      assert_equal "local-app", config.app_name
      assert_equal "sqlite", config.database_adapter
      assert_equal "tmp/development.sqlite3", config.value("SQLITE_DATABASE_PATH")
      assert_equal ["storage", "tmp/uploads"], config.backup_paths
      assert_equal ["/data/storage", "/data/uploads"], config.local_restore_source_paths
    end
  end

  def test_loads_restic_repository_and_password_sources_from_yaml
    Dir.mktmpdir do |dir|
      password_file = File.join(dir, "restic-password")
      repository_file = File.join(dir, "restic-repository")
      File.write(password_file, "secret")
      File.write(repository_file, "/tmp/restic")
      config_dir = File.join(dir, "config")
      FileUtils.mkdir_p(config_dir)
      File.write(
        File.join(config_dir, "kamal-backup.yml"),
        <<~YAML
          app_name: file-app
          restic_repository_file: #{repository_file}
          restic_password_file: #{password_file}
        YAML
      )

      config = KamalBackup::Config.new(env: {}, cwd: dir)

      assert_equal repository_file, config.restic_repository_file
      assert_equal password_file, config.restic_password_file
      config.validate_restic
    end
  end

  def test_restic_password_command_satisfies_password_validation
    config = KamalBackup::Config.new(env: {
      "APP_NAME" => "test-app",
      "RESTIC_REPOSITORY" => "/tmp/restic-repo",
      "RESTIC_PASSWORD_COMMAND" => "pass show restic/test-app"
    })

    config.validate_restic
  end

  def test_restic_validation_accepts_missing_remote_files_when_file_checks_are_disabled
    config = KamalBackup::Config.new(env: {
      "APP_NAME" => "test-app",
      "RESTIC_REPOSITORY_FILE" => "/remote/restic-repository",
      "RESTIC_PASSWORD_FILE" => "/remote/restic-password"
    })

    config.validate_restic(check_files: false)
  end

  def test_restic_validation_rejects_missing_password_sources
    config = KamalBackup::Config.new(env: {
      "APP_NAME" => "test-app",
      "RESTIC_REPOSITORY" => "/tmp/restic-repo"
    })

    error = assert_raises(KamalBackup::ConfigurationError) { config.validate_restic }
    assert_match(/RESTIC_PASSWORD, RESTIC_PASSWORD_FILE, or RESTIC_PASSWORD_COMMAND is required/, error.message)
  end

  def test_environment_overrides_local_yaml_config
    Dir.mktmpdir do |dir|
      config_dir = File.join(dir, "config")
      FileUtils.mkdir_p(config_dir)
      File.write(
        File.join(config_dir, "kamal-backup.local.yml"),
        <<~YAML
          app_name: file-app
        YAML
      )

      config = KamalBackup::Config.new(env: { "APP_NAME" => "env-app" }, cwd: dir)

      assert_equal "env-app", config.app_name
    end
  end

  def test_infers_local_defaults_from_a_rails_postgres_app
    Dir.mktmpdir do |dir|
      config_dir = File.join(dir, "config")
      FileUtils.mkdir_p(config_dir)
      File.write(
        File.join(config_dir, "database.yml"),
        <<~YAML
          default: &default
            adapter: postgresql
            pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
            username: app

          development:
            <<: *default
            database: app_development
            host: localhost
            port: 5432
        YAML
      )
      File.write(
        File.join(config_dir, "deploy.yml"),
        <<~YAML
          service: app
        YAML
      )

      config = KamalBackup::Config.new(env: { "RESTIC_REPOSITORY" => "/tmp/restic", "RESTIC_PASSWORD" => "secret" }, cwd: dir)

      assert_equal "app", config.app_name
      assert_equal "postgres", config.database_adapter
      assert_equal "app", config.value("PGUSER")
      assert_equal "app_development", config.value("PGDATABASE")
      assert_equal "localhost", config.value("PGHOST")
      assert_equal [File.join(dir, "storage")], config.backup_paths
      assert_equal File.join(dir, "tmp", "kamal-backup"), config.state_dir
    end
  end

  def test_infers_local_defaults_from_a_rails_sqlite_app
    Dir.mktmpdir do |dir|
      config_dir = File.join(dir, "config")
      FileUtils.mkdir_p(config_dir)
      File.write(
        File.join(config_dir, "database.yml"),
        <<~YAML
          development:
            adapter: sqlite3
            database: storage/development.sqlite3
        YAML
      )

      config = KamalBackup::Config.new(env: { "RESTIC_REPOSITORY" => "/tmp/restic", "RESTIC_PASSWORD" => "secret" }, cwd: dir)

      assert_equal "sqlite", config.database_adapter
      assert_equal File.join(dir, "storage", "development.sqlite3"), config.value("SQLITE_DATABASE_PATH")
      assert_equal [File.join(dir, "storage")], config.backup_paths
    end
  end

  def test_local_yaml_overrides_inferred_rails_defaults
    Dir.mktmpdir do |dir|
      config_dir = File.join(dir, "config")
      FileUtils.mkdir_p(config_dir)
      File.write(
        File.join(config_dir, "database.yml"),
        <<~YAML
          development:
            adapter: sqlite3
            database: storage/development.sqlite3
        YAML
      )
      File.write(
        File.join(config_dir, "kamal-backup.local.yml"),
        <<~YAML
          sqlite_database_path: custom/dev.sqlite3
          backup_paths:
            - uploads
        YAML
      )

      config = KamalBackup::Config.new(env: { "RESTIC_REPOSITORY" => "/tmp/restic", "RESTIC_PASSWORD" => "secret" }, cwd: dir)

      assert_equal "custom/dev.sqlite3", config.value("SQLITE_DATABASE_PATH")
      assert_equal ["uploads"], config.backup_paths
    end
  end

  def test_refuses_suspicious_backup_path
    config = KamalBackup::Config.new(env: base_env("DATABASE_ADAPTER" => "postgres", "DATABASE_URL" => "postgres://app@db/app", "BACKUP_PATHS" => "/"))

    error = assert_raises(KamalBackup::ConfigurationError) { config.validate_backup_paths }
    assert_match(/refusing suspicious backup path/, error.message)
  end

  def test_validates_existing_backup_paths
    Dir.mktmpdir do |dir|
      config = KamalBackup::Config.new(env: base_env("BACKUP_PATHS" => dir))

      config.validate_backup_paths
    end
  end

  def test_remote_backup_validation_skips_local_path_existence_checks
    config = KamalBackup::Config.new(env: base_env(
      "DATABASE_ADAPTER" => "sqlite",
      "SQLITE_DATABASE_PATH" => "/remote/db/production.sqlite3",
      "BACKUP_PATHS" => "/remote/storage"
    ))

    config.validate_backup(check_files: false)
  end

  def test_refuses_production_like_restore_target
    config = KamalBackup::Config.new(env: base_env)

    error = assert_raises(KamalBackup::ConfigurationError) do
      config.validate_database_restore_target("postgres://app@db/app_production")
    end
    assert_match(/production-looking/, error.message)
  end

  def test_local_machine_restore_does_not_require_a_restore_flag
    Dir.mktmpdir do |dir|
      config = KamalBackup::Config.new(env: base_env("BACKUP_PATHS" => dir))

      config.validate_local_machine_restore
    end
  end

  def test_local_machine_restore_refuses_production_environment_without_override
    config = KamalBackup::Config.new(env: base_env(
      "BACKUP_PATHS" => "/tmp/storage",
      "RAILS_ENV" => "production"
    ))

    error = assert_raises(KamalBackup::ConfigurationError) { config.validate_local_machine_restore }
    assert_match(/restore local refuses to run with RAILS_ENV=production/, error.message)
  end

  def test_local_machine_restore_accepts_missing_target_paths
    config = KamalBackup::Config.new(env: base_env(
      "BACKUP_PATHS" => "/tmp/storage"
    ))

    config.validate_local_machine_restore
  end

  def test_local_machine_restore_source_paths_must_match_target_path_count
    config = KamalBackup::Config.new(env: base_env(
      "BACKUP_PATHS" => "/tmp/storage:/tmp/uploads",
      "LOCAL_RESTORE_SOURCE_PATHS" => "/data/storage"
    ))

    error = assert_raises(KamalBackup::ConfigurationError) { config.validate_local_machine_restore }
    assert_match(/LOCAL_RESTORE_SOURCE_PATHS must contain the same number of paths as BACKUP_PATHS/, error.message)
  end

  def test_retention_args_use_restic_flags
    config = KamalBackup::Config.new(env: base_env("RESTIC_KEEP_LAST" => "3", "RESTIC_KEEP_DAILY" => "0"))

    assert_includes config.retention_args, "--keep-last"
    assert_includes config.retention_args, "3"
    refute_includes config.retention_args, "--keep-daily"
  end

  def test_forget_after_backup_defaults_to_true
    config = KamalBackup::Config.new(env: base_env)

    assert config.forget_after_backup?
  end

  def test_forget_after_backup_can_be_disabled
    config = KamalBackup::Config.new(env: base_env("RESTIC_FORGET_AFTER_BACKUP" => "false"))

    refute config.forget_after_backup?
  end
end
