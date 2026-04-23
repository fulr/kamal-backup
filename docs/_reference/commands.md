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

The production interface is the accessory container. There is no installation step on the app host.

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

Use `kamal-backup help [command]` for task-specific usage.

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

Restore commands are intentionally not part of the default alias block. They require explicit restore flags and restore-specific targets, so call the accessory directly.
