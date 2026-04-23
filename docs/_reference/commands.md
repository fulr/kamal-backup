---
title: Commands
description: Command reference for the kamal-backup executable and the most common Kamal alias flows.
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

Recommended Kamal aliases:

```yaml
aliases:
  backup: accessory exec backup "kamal-backup backup"
  backup-list: accessory exec backup "kamal-backup list"
  backup-check: accessory exec backup "kamal-backup check"
  backup-evidence: accessory exec backup "kamal-backup evidence"
  backup-version: accessory exec backup "kamal-backup version"
  backup-schedule: accessory exec backup "kamal-backup schedule"
  backup-logs: accessory logs backup -f
```

Optional drill alias after a scratch restore target is configured:

```yaml
aliases:
  backup-drill: accessory exec backup "kamal-backup drill latest --file-target /restore/files --check 'test -d /restore/files/data/storage'"
```

That alias assumes `RESTORE_DATABASE_URL` or `RESTORE_SQLITE_DATABASE_PATH` already points at a non-production restore target for the accessory.

The production interface is the accessory container. There is no installation step on the app host.

```sh
kamal-backup backup
kamal-backup drill [snapshot-or-latest]
kamal-backup restore-db [snapshot-or-latest]
kamal-backup restore-files [snapshot-or-latest] [target-dir]
kamal-backup restore-local [snapshot-or-latest]
kamal-backup list
kamal-backup check
kamal-backup evidence
kamal-backup schedule
kamal-backup version
```

Use `kamal-backup help [command]` for task-specific usage.

## Commands

| Command | Description |
|---|---|
| `backup` | Create one database backup and one file snapshot for the current app. It runs `forget --prune` afterward unless `RESTIC_FORGET_AFTER_BACKUP=false`. |
| `drill [snapshot-or-latest]` | Run a restore drill, print JSON with the result, and store the latest drill record under `KAMAL_BACKUP_STATE_DIR`. Use `--local` for the current local database and file paths, or `--file-target` for a scratch file path. |
| `restore-db [snapshot-or-latest]` | Restore a database backup from a snapshot. Defaults to `latest`. Requires `KAMAL_BACKUP_ALLOW_RESTORE=true` and restore-specific database environment. |
| `restore-files [snapshot-or-latest] [target-dir]` | Restore the file snapshot into a target directory. Defaults to `latest /restore/files`. In-place restores require `KAMAL_BACKUP_ALLOW_IN_PLACE_FILE_RESTORE=true`. |
| `restore-local [snapshot-or-latest]` | Restore the latest database and file snapshots into the current local database settings and `BACKUP_PATHS`. This is the lower-level local restore primitive behind `drill --local`. |
| `list` | Show restic snapshots for the configured app tags. |
| `check` | Run `restic check` and store the latest result under `KAMAL_BACKUP_STATE_DIR`. |
| `evidence` | Print redacted JSON you can attach to ops records or security reviews, including latest snapshots, latest check result, latest drill result, retention, and tool versions. |
| `schedule` | Run the foreground scheduler loop used by the Docker image default command. |
| `version` | Print the running `kamal-backup` version. `--version` and `-v` do the same. |

## Alias Notes

| Alias | Purpose |
|---|---|
| `backup` | Run one backup immediately. |
| `backup-list` | Show snapshots for the configured app tags. |
| `backup-check` | Run `restic check`. |
| `backup-evidence` | Print redacted operational evidence JSON. |
| `backup-version` | Show the running `kamal-backup` version inside the accessory. |
| `backup-schedule` | Run the foreground scheduler loop manually. Mostly useful for debugging. |
| `backup-logs` | Tail backup accessory logs. |
| `backup-drill` | Optional alias for the standard restore drill after scratch restore targets are configured. |

Restore commands are intentionally not part of the default alias block. They require explicit restore flags and restore-specific targets, so call the accessory directly.

`drill` is the operator-facing command for restore drills. `restore-db`, `restore-files`, and `restore-local` remain available when you want the lower-level building blocks directly.

`drill --local` is meant to run on a developer machine or another non-production environment where the current `DATABASE_URL` or `SQLITE_DATABASE_PATH` and `BACKUP_PATHS` point at local scratch data. If the backup was taken from different production file paths, set `LOCAL_RESTORE_SOURCE_PATHS` to those source paths before running the local drill.
