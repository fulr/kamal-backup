require_relative "lib/kamal_backup/version"

Gem::Specification.new do |spec|
  spec.name = "kamal-backup"
  spec.version = KamalBackup::VERSION
  spec.authors = ["Carmine Paolino"]
  spec.email = ["carmine@paolino.me"]

  spec.summary = "Kamal-first restic backups for databases and mounted application files."
  spec.description = "A small CLI and Docker image for encrypted, verifiable Kamal accessory backups using restic."
  spec.homepage = "https://kamal-backup.dev"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1"

  spec.metadata = {
    "homepage_uri" => spec.homepage,
    "source_code_uri" => "https://github.com/crmne/kamal-backup",
    "changelog_uri" => "https://github.com/crmne/kamal-backup/releases",
    "bug_tracker_uri" => "https://github.com/crmne/kamal-backup/issues",
    "funding_uri" => "https://github.com/sponsors/crmne",
    "rubygems_mfa_required" => "true"
  }

  spec.files = Dir[
    "LICENSE",
    "README.md",
    "exe/kamal-backup",
    "lib/**/*.rb"
  ]
  spec.bindir = "exe"
  spec.executables = ["kamal-backup"]
  spec.require_paths = ["lib"]
end
