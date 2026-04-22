require_relative "test_helper"

class CLITest < Minitest::Test
  class FakeRestic
    attr_reader :backup_path_calls, :forget_calls

    def initialize
      @backup_path_calls = []
      @forget_calls = 0
    end

    def ensure_repository!
    end

    def backup_paths(paths, tags:)
      @backup_path_calls << { paths: paths, tags: tags }
    end

    def forget_after_success!
      @forget_calls += 1
    end
  end

  class FakeDatabase
    def backup(_restic, _timestamp)
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

      cli = KamalBackup::CLI.new(env: base_env(
        "DATABASE_ADAPTER" => "sqlite",
        "SQLITE_DATABASE_PATH" => db,
        "BACKUP_PATHS" => "#{first_path}:#{second_path}"
      ))
      restic = FakeRestic.new
      cli.instance_variable_set(:@restic, restic)
      cli.instance_variable_set(:@database, FakeDatabase.new)

      cli.backup

      assert_equal 1, restic.backup_path_calls.size
      assert_equal [first_path, second_path], restic.backup_path_calls.first.fetch(:paths)
      assert_includes restic.backup_path_calls.first.fetch(:tags), "type:files"
      assert restic.backup_path_calls.first.fetch(:tags).any? { |tag| tag.start_with?("run:") }
      assert_equal 1, restic.forget_calls
    end
  end

  def test_start_redacts_error_messages
    fake = Object.new
    def fake.run(_argv)
      raise KamalBackup::ConfigurationError, "bad postgres://app:secret@db/app with secret"
    end

    _, err = capture_io do
      error = assert_raises(SystemExit) do
        original_new = KamalBackup::CLI.method(:new)
        begin
          KamalBackup::CLI.define_singleton_method(:new) { |env:| fake }
          KamalBackup::CLI.start(["backup"], env: { "DATABASE_URL" => "postgres://app:secret@db/app", "PGPASSWORD" => "secret" })
        ensure
          KamalBackup::CLI.define_singleton_method(:new) { |env: ENV| original_new.call(env: env) }
        end
      end
      assert_equal 1, error.status
    end

    refute_includes err, "secret"
    assert_includes err, "postgres://[REDACTED]@db/app"
  end

  def test_version_command_prints_version
    cli = KamalBackup::CLI.new(env: base_env)

    out, _ = capture_io { cli.run(["--version"]) }

    assert_equal "#{KamalBackup::VERSION}\n", out
  end

  def test_backup_can_skip_forget_for_append_only_repositories
    Dir.mktmpdir do |dir|
      db = File.join(dir, "app.sqlite3")
      files = File.join(dir, "storage")
      File.write(db, "")
      FileUtils.mkdir_p(files)

      cli = KamalBackup::CLI.new(env: base_env(
        "DATABASE_ADAPTER" => "sqlite",
        "SQLITE_DATABASE_PATH" => db,
        "BACKUP_PATHS" => files,
        "RESTIC_FORGET_AFTER_BACKUP" => "false"
      ))
      restic = FakeRestic.new
      cli.instance_variable_set(:@restic, restic)
      cli.instance_variable_set(:@database, FakeDatabase.new)

      cli.backup

      assert_equal 0, restic.forget_calls
    end
  end
end
