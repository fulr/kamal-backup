require_relative "test_helper"

class AppTest < Minitest::Test
  class FakeRestic
    attr_reader :backup_path_calls, :check_calls, :database_file_calls
    attr_reader :ensure_repository_calls, :forget_calls, :latest_snapshot_calls, :restore_snapshot_calls

    def initialize
      @backup_path_calls = []
      @check_calls = 0
      @database_file_calls = []
      @ensure_repository_calls = 0
      @forget_calls = 0
      @latest_snapshot_calls = []
      @restore_snapshot_calls = []
    end

    def ensure_repository
      @ensure_repository_calls += 1
    end

    def backup_paths(paths, tags:)
      @backup_path_calls << { paths: paths, tags: tags }
    end

    def forget_after_success
      @forget_calls += 1
    end

    def check
      @check_calls += 1
      KamalBackup::CommandResult.new(stdout: "checked", stderr: "", status: 0)
    end

    def latest_snapshot(tags:)
      @latest_snapshot_calls << tags
      { "short_id" => "latest-snapshot" }
    end

    def database_file(snapshot, adapter)
      @database_file_calls << { snapshot: snapshot, adapter: adapter }
      "database.dump"
    end

    def restore_snapshot(snapshot, target)
      @restore_snapshot_calls << { snapshot: snapshot, target: target }
    end
  end

  class FakeDatabase
    attr_reader :backup_calls, :restore_calls

    def initialize(adapter_name: "sqlite")
      @adapter_name = adapter_name
      @backup_calls = []
      @restore_calls = []
    end

    def adapter_name
      @adapter_name
    end

    def backup(restic, timestamp)
      @backup_calls << { restic: restic, timestamp: timestamp }
    end

    def restore(restic, snapshot, filename)
      @restore_calls << { restic: restic, snapshot: snapshot, filename: filename }
    end
  end

  def test_backup_creates_one_file_snapshot_for_all_paths
    Dir.mktmpdir do |dir|
      db = File.join(dir, "app.sqlite3")
      first_path = File.join(dir, "storage")
      second_path = File.join(dir, "uploads")
      File.write(db, "")
      FileUtils.mkdir_p(first_path)
      FileUtils.mkdir_p(second_path)
      restic = FakeRestic.new
      database = FakeDatabase.new

      app = KamalBackup::App.new(
        env: base_env(
          "DATABASE_ADAPTER" => "sqlite",
          "SQLITE_DATABASE_PATH" => db,
          "BACKUP_PATHS" => "#{first_path}:#{second_path}"
        ),
        restic: restic,
        database: database
      )

      app.backup

      assert_equal 1, restic.ensure_repository_calls
      assert_equal 1, database.backup_calls.size
      assert_equal 1, restic.backup_path_calls.size
      assert_equal [first_path, second_path], restic.backup_path_calls.first.fetch(:paths)
      assert_includes restic.backup_path_calls.first.fetch(:tags), "type:files"
      assert restic.backup_path_calls.first.fetch(:tags).any? { |tag| tag.start_with?("run:") }
      assert_equal 1, restic.forget_calls
    end
  end

  def test_backup_can_skip_forget_for_append_only_repositories
    Dir.mktmpdir do |dir|
      db = File.join(dir, "app.sqlite3")
      files = File.join(dir, "storage")
      File.write(db, "")
      FileUtils.mkdir_p(files)
      restic = FakeRestic.new

      app = KamalBackup::App.new(
        env: base_env(
          "DATABASE_ADAPTER" => "sqlite",
          "SQLITE_DATABASE_PATH" => db,
          "BACKUP_PATHS" => files,
          "RESTIC_FORGET_AFTER_BACKUP" => "false"
        ),
        restic: restic,
        database: FakeDatabase.new
      )

      app.backup

      assert_equal 0, restic.forget_calls
    end
  end

  def test_backup_can_run_restic_check_after_success
    Dir.mktmpdir do |dir|
      db = File.join(dir, "app.sqlite3")
      files = File.join(dir, "storage")
      File.write(db, "")
      FileUtils.mkdir_p(files)
      restic = FakeRestic.new

      app = KamalBackup::App.new(
        env: base_env(
          "DATABASE_ADAPTER" => "sqlite",
          "SQLITE_DATABASE_PATH" => db,
          "BACKUP_PATHS" => files,
          "RESTIC_CHECK_AFTER_BACKUP" => "true"
        ),
        restic: restic,
        database: FakeDatabase.new
      )

      app.backup

      assert_equal 1, restic.check_calls
    end
  end

  def test_restore_database_uses_latest_snapshot_for_the_selected_adapter
    restic = FakeRestic.new
    database = FakeDatabase.new(adapter_name: "postgres")
    app = KamalBackup::App.new(
      env: base_env(
        "DATABASE_ADAPTER" => "postgres",
        "KAMAL_BACKUP_ALLOW_RESTORE" => "true"
      ),
      restic: restic,
      database: database
    )

    app.restore_database("latest")

    assert_equal [%w[type:database adapter:postgres]], restic.latest_snapshot_calls
    assert_equal [{ snapshot: "latest-snapshot", adapter: "postgres" }], restic.database_file_calls
    assert_equal 1, database.restore_calls.size
    assert_equal "latest-snapshot", database.restore_calls.first.fetch(:snapshot)
    assert_equal "database.dump", database.restore_calls.first.fetch(:filename)
  end

  def test_restore_files_uses_latest_snapshot_and_expands_the_target_path
    Dir.mktmpdir do |dir|
      files = File.join(dir, "storage")
      target = File.join(dir, "restored-files")
      FileUtils.mkdir_p(files)

      restic = FakeRestic.new
      app = KamalBackup::App.new(
        env: base_env(
          "BACKUP_PATHS" => files,
          "KAMAL_BACKUP_ALLOW_RESTORE" => "true"
        ),
        restic: restic,
        database: FakeDatabase.new
      )

      app.restore_files("latest", target: target)

      assert_equal [%w[type:files]], restic.latest_snapshot_calls
      assert_equal [{ snapshot: "latest-snapshot", target: File.expand_path(target) }], restic.restore_snapshot_calls
    end
  end
end
