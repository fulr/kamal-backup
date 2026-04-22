---
title: Commands
description: Command reference for the kamal-backup executable.
nav_order: 1
---

## CLI

```sh
kamal-backup backup
kamal-backup restore-db [snapshot-or-latest]
kamal-backup restore-files [snapshot-or-latest] [target-dir]
kamal-backup list
kamal-backup check
kamal-backup evidence
kamal-backup schedule
```

## Commands

| Command | Description |
|---|---|
| `backup` | Run one backup immediately. |
| `restore-db [snapshot-or-latest]` | Restore a database dump from a snapshot. Defaults to `latest`. |
| `restore-files [snapshot-or-latest] [target-dir]` | Restore file snapshots. Defaults to `latest /restore/files`. |
| `list` | Show matching restic snapshots. |
| `check` | Run `restic check`. |
| `evidence` | Print redacted operational evidence as JSON. |
| `schedule` | Run the foreground scheduler loop. |

## Local Ruby install

The Docker image installs the project as the `kamal-backup` gem. To install locally from a checkout:

```sh
gem build kamal-backup.gemspec
gem install ./kamal-backup-*.gem
kamal-backup --help
```
