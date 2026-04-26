$LOAD_PATH.unshift(File.expand_path("lib", __dir__))
require "kamal_backup/version"

Gem::Specification.new do |spec|
  spec.name = "kamal-backup"
  spec.version = KamalBackup::VERSION
  spec.authors = ["crmne"]
  spec.summary = "Scheduled Rails backups, restore drills, and evidence for Kamal apps"
  spec.description = "Back up PostgreSQL, MySQL, SQLite, and file-backed Active Storage files into restic on a schedule, then run restore drills and produce review evidence."
  spec.homepage = "https://github.com/crmne/kamal-backup"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2"

  spec.metadata = {
    "source_code_uri" => spec.homepage,
    "changelog_uri" => "#{spec.homepage}/releases",
    "rubygems_mfa_required" => "true"
  }

  spec.files = Dir.chdir(__dir__) do
    Dir["lib/**/*", "exe/*", "README.md", "LICENSE"]
  end
  spec.bindir = "exe"
  spec.executables = ["kamal-backup"]
  spec.require_paths = ["lib"]

  spec.add_dependency "thor", "~> 1.5"
  spec.add_development_dependency "minitest"
end
