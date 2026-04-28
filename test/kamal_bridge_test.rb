require_relative "test_helper"

class KamalBridgeTest < Minitest::Test
  def stub_command_capture(result)
    original = KamalBackup::Command.method(:capture)
    specs = []

    KamalBackup::Command.define_singleton_method(:capture) do |spec, **_kwargs|
      specs << spec
      result
    end

    yield(specs)
  ensure
    KamalBackup::Command.define_singleton_method(:capture) { |*args, **kwargs, &block| original.call(*args, **kwargs, &block) }
  end

  def test_remote_version_uses_the_version_line_from_kamal_output
    output = <<~OUT
      Launching command from new container...
        INFO [50d63bd8] Running docker run ghcr.io/crmne/kamal-backup:latest kamal-backup version on example.com
      App Host: example.com
      0.1.2
    OUT
    bridge = KamalBackup::KamalBridge.new(redactor: KamalBackup::Redactor.new(env: {}))

    stub_command_capture(KamalBackup::CommandResult.new(stdout: output, stderr: "", status: 0)) do |specs|
      assert_equal "0.1.2", bridge.remote_version(accessory_name: "backup")
      assert_equal ["kamal", "accessory", "exec", "backup", "kamal-backup version"], specs.first.argv
    end
  end

  def test_accessory_environment_merges_clear_env_and_secret_placeholders
    output = <<~YAML
      accessories:
        backup:
          env:
            clear:
              APP_NAME: chatwithwork
              RESTIC_REPOSITORY_FILE: /var/lib/kamal-backup/restic-repository
            secret:
              - RESTIC_PASSWORD
              - AWS_ACCESS_KEY_ID
    YAML
    bridge = KamalBackup::KamalBridge.new(redactor: KamalBackup::Redactor.new(env: {}))

    stub_command_capture(KamalBackup::CommandResult.new(stdout: output, stderr: "", status: 0)) do
      env = bridge.accessory_environment(accessory_name: "backup")

      assert_equal "chatwithwork", env.fetch("APP_NAME")
      assert_equal "/var/lib/kamal-backup/restic-repository", env.fetch("RESTIC_REPOSITORY_FILE")
      assert_equal "configured", env.fetch("RESTIC_PASSWORD")
      assert_equal "configured", env.fetch("AWS_ACCESS_KEY_ID")
    end
  end
end
