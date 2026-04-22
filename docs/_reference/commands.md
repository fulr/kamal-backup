---
title: Commands
description: Command reference for the kamal-backup executable.
nav_order: 1
---

## CLI

Production commands normally run inside the backup accessory:

```sh
bin/kamal accessory exec backup "kamal-backup evidence"
```

With the recommended aliases from the getting-started guide, the same command becomes:

```sh
bin/kamal backup-evidence
```

The gem is still useful as a laptop-side operator CLI for restore drills, but it is not required on the production app host.

```sh
kamal-backup backup
kamal-backup restore-db [snapshot-or-latest]
kamal-backup restore-files [snapshot-or-latest] [target-dir]
kamal-backup list
kamal-backup check
kamal-backup evidence
kamal-backup schedule
kamal-backup version
```

## Commands

| Command | Description |
|---|---|
| `backup` | Run one backup immediately. It creates one logical database snapshot and one file snapshot containing every configured `BACKUP_PATHS` entry. It runs `forget --prune` afterward unless `RESTIC_FORGET_AFTER_BACKUP=false`. |
| `restore-db [snapshot-or-latest]` | Restore a database dump from a snapshot. Defaults to `latest`. Requires `KAMAL_BACKUP_ALLOW_RESTORE=true` and restore-specific database environment. |
| `restore-files [snapshot-or-latest] [target-dir]` | Restore file snapshots. Defaults to `latest /restore/files`. In-place restores require `KAMAL_BACKUP_ALLOW_IN_PLACE_FILE_RESTORE=true`. |
| `list` | Show matching restic snapshots for the configured app. |
| `check` | Run `restic check` and store the latest result under `KAMAL_BACKUP_STATE_DIR`. |
| `evidence` | Print redacted operational evidence as JSON, including latest snapshots, check status, retention, and tool versions. |
| `schedule` | Run the foreground scheduler loop used by the Docker image default command. |
| `version` | Print the gem version. `--version` and `-v` do the same. |

## Local Ruby install

The Docker image installs the project as the `kamal-backup` gem. To install the same executable locally from a checkout:

```sh
gem build kamal-backup.gemspec
gem install ./kamal-backup-*.gem
kamal-backup --help
```
