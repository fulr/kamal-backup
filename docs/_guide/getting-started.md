---
title: Getting Started
description: Add kamal-backup as a Kamal accessory and run the first backup.
nav_order: 1
---

## Add the accessory

Add a backup accessory to your Kamal deploy config:

```yaml
aliases:
  backup: accessory exec backup "kamal-backup backup"
  backup-list: accessory exec backup "kamal-backup list"
  backup-check: accessory exec backup "kamal-backup check"
  backup-evidence: accessory exec backup "kamal-backup evidence"
  backup-version: accessory exec backup "kamal-backup version"
  backup-schedule: accessory exec backup "kamal-backup schedule"
  backup-logs: accessory logs backup -f

accessories:
  backup:
    image: ghcr.io/crmne/kamal-backup:latest
    host: chatwithwork.com
    env:
      clear:
        APP_NAME: chatwithwork
        DATABASE_ADAPTER: postgres
        DATABASE_URL: postgres://chatwithwork@chatwithwork-db:5432/chatwithwork_production
        BACKUP_PATHS: /data/storage
        RESTIC_REPOSITORY: s3:https://s3.example.com/chatwithwork-backups
        RESTIC_INIT_IF_MISSING: "true"
        BACKUP_SCHEDULE_SECONDS: "86400"
      secret:
        - PGPASSWORD
        - RESTIC_PASSWORD
        - AWS_ACCESS_KEY_ID
        - AWS_SECRET_ACCESS_KEY
    volumes:
      - "chatwithwork_storage:/data/storage:ro"
```

Boot it:

```sh
bin/kamal accessory boot backup
bin/kamal accessory logs backup
```

## Run manually

The production interface is the accessory container. The image ships the `kamal-backup` executable, so you can run one-off commands through Kamal:

```sh
bin/kamal backup
bin/kamal backup-list
bin/kamal backup-check
bin/kamal backup-evidence
bin/kamal backup-version
bin/kamal backup-schedule
bin/kamal backup-logs
```

Recommended aliases:

| Alias | Expands to | Use |
|---|---|---|
| `bin/kamal backup` | `accessory exec backup "kamal-backup backup"` | Run one backup immediately. |
| `bin/kamal backup-list` | `accessory exec backup "kamal-backup list"` | Show restic snapshots for the configured app. |
| `bin/kamal backup-check` | `accessory exec backup "kamal-backup check"` | Run `restic check` and store the latest check result. |
| `bin/kamal backup-evidence` | `accessory exec backup "kamal-backup evidence"` | Print redacted backup evidence JSON. |
| `bin/kamal backup-version` | `accessory exec backup "kamal-backup version"` | Print the running `kamal-backup` version. |
| `bin/kamal backup-schedule` | `accessory exec backup "kamal-backup schedule"` | Run the foreground scheduler loop manually. Mostly useful for debugging. |
| `bin/kamal backup-logs` | `accessory logs backup -f` | Tail the backup accessory logs. |

Restore commands are intentionally not aliased in the default block. They require explicit restore flags and restore-specific targets, so run `bin/kamal accessory exec backup "kamal-backup ..."` directly.

You do not need any installation step on the app host. The accessory image already contains the `kamal-backup` executable.

## What gets backed up

Each backup run creates:

- one logical database dump stored through restic stdin;
- one `type:files` restic snapshot containing all configured `BACKUP_PATHS` entries.

Database dump snapshots are tagged with `kamal-backup`, `app:<name>`, `type:database`, `adapter:<adapter>`, and `run:<timestamp>`. File snapshots use `type:files`, the same run tag, and informational `path:<label>` tags for the configured paths. Restore selects by `type:files`, not by one path tag.
