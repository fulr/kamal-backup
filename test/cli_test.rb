require_relative "test_helper"

class CLITest < Minitest::Test
  def test_start_redacts_error_messages
    fake = Object.new
    def fake.backup
      raise KamalBackup::ConfigurationError, "bad postgres://app:secret@db/app with secret"
    end

    _, err = capture_io do
      error = assert_raises(SystemExit) do
        original_new = KamalBackup::App.method(:new)
        begin
          KamalBackup::App.define_singleton_method(:new) { |**| fake }
          KamalBackup::CLI.start(["backup"], env: { "DATABASE_URL" => "postgres://app:secret@db/app", "PGPASSWORD" => "secret" })
        ensure
          KamalBackup::App.define_singleton_method(:new) { |**kwargs| original_new.call(**kwargs) }
        end
      end
      assert_equal 1, error.status
    end

    refute_includes err, "secret"
    assert_includes err, "postgres://[REDACTED]@db/app"
  end

  def test_version_command_prints_version
    out, _ = capture_io { KamalBackup::CLI.start(["--version"], env: base_env) }

    assert_equal "#{KamalBackup::VERSION}\n", out
  end

  def test_help_lists_commands
    out, = capture_io { KamalBackup::CLI.start([], env: base_env) }

    assert_includes out, "kamal-backup help [COMMAND]"
    assert_includes out, "kamal-backup backup"
    assert_includes out, "kamal-backup drill [SNAPSHOT]"
    assert_includes out, "kamal-backup restore-db [SNAPSHOT]"
    assert_includes out, "kamal-backup restore-local [SNAPSHOT]"
  end

  def test_drill_prints_json_output
    fake = Object.new
    def fake.drill(*, **)
      { status: "ok", mode: "local" }
    end

    def fake.drill_failed?(result)
      result.fetch(:status) != "ok"
    end

    out, _ = capture_io do
      original_new = KamalBackup::App.method(:new)
      begin
        KamalBackup::App.define_singleton_method(:new) { |**| fake }
        KamalBackup::CLI.start(["drill", "--local"], env: base_env)
      ensure
        KamalBackup::App.define_singleton_method(:new) { |**kwargs| original_new.call(**kwargs) }
      end
    end

    assert_includes out, "\"status\": \"ok\""
    assert_includes out, "\"mode\": \"local\""
  end

  def test_drill_exits_non_zero_when_the_drill_failed
    fake = Object.new
    def fake.drill(*, **)
      { status: "failed", error: "restore failed" }
    end

    def fake.drill_failed?(result)
      result.fetch(:status) != "ok"
    end

    out, _ = capture_io do
      original_new = KamalBackup::App.method(:new)
      begin
        KamalBackup::App.define_singleton_method(:new) { |**| fake }
        error = assert_raises(SystemExit) do
          KamalBackup::CLI.start(["drill"], env: base_env)
        end
        assert_equal 1, error.status
      ensure
        KamalBackup::App.define_singleton_method(:new) { |**kwargs| original_new.call(**kwargs) }
      end
    end

    assert_includes out, "\"status\": \"failed\""
    assert_includes out, "\"error\": \"restore failed\""
  end
end
