---
title: Configuration
description: The simple YAML-first configuration path for the backup accessory.
nav_order: 3
---

## The Simple Setup

Generate the backup config:

```sh
bundle exec kamal-backup init
```

That creates one file for backup settings:

```txt
config/kamal-backup.yml
```

Edit that file, then mount it into the accessory with Kamal `files:`. Keep secrets in Kamal secrets.

That is the normal configuration story:

- `config/kamal-backup.yml` has app, database, restic repository, paths, and schedule.
- `config/deploy.yml` only says how to run the accessory and which secrets to pass.
- `config/kamal-backup.local.yml` is only for unusual local restore targets.

## `config/kamal-backup.yml`

```yaml
accessory: backup
app_name: chatwithwork
database_adapter: postgres
database_url: postgres://chatwithwork@chatwithwork-db:5432/chatwithwork_production
backup_paths:
  - /data/storage
restic_repository: s3:https://s3.example.com/chatwithwork-backups
restic_init_if_missing: true
backup_schedule_seconds: 86400
```

For MySQL:

```yaml
database_adapter: mysql
database_url: mysql2://app@app-mysql:3306/app_production
```

For SQLite:

```yaml
database_adapter: sqlite
sqlite_database_path: /data/db/production.sqlite3
```

## `config/deploy.yml`

```yaml
accessories:
  backup:
    image: ghcr.io/crmne/kamal-backup:latest
    host: chatwithwork.com
    files:
      - config/kamal-backup.yml:/app/config/kamal-backup.yml:ro
    env:
      secret:
        - PGPASSWORD
        - RESTIC_PASSWORD
        - AWS_ACCESS_KEY_ID
        - AWS_SECRET_ACCESS_KEY
    volumes:
      - "chatwithwork_storage:/data/storage:ro"
      - "chatwithwork_backup_state:/var/lib/kamal-backup"
```

The `files:` line is what keeps the non-secret backup settings out of environment variables. Kamal uploads the YAML file and mounts it read-only into the accessory.

## Secrets

The common path is still to let Kamal pass secrets:

```sh
RESTIC_PASSWORD=...
PGPASSWORD=...
AWS_ACCESS_KEY_ID=...
AWS_SECRET_ACCESS_KEY=...
```

If you do not want the restic password value in the process environment, point restic at a mounted file instead:

```yaml
restic_password_file: /run/secrets/restic-password
```

The same works for the repository string when needed:

```yaml
restic_repository_file: /run/secrets/restic-repository
```

## Validate Before Boot

Run this before booting or rebooting the accessory:

```sh
bundle exec kamal-backup validate
```

With a normal `config/deploy.yml`, `validate` checks the backup accessory config before the accessory has to be running. It catches missing app, database, restic, and backup path settings early.

## Local Restores

For normal Rails apps, no local backup config is needed. `restore local` and `drill local` use:

- production source settings from `config/kamal-backup.yml`
- local database settings from `config/database.yml`
- local Active Storage path from `storage`
- local state under `tmp/kamal-backup`

Only add `config/kamal-backup.local.yml` when your local targets are nonstandard:

```yaml
database_url: postgres://localhost/chatwithwork_development
backup_paths:
  - storage
state_dir: tmp/kamal-backup
```

## Useful Options

```yaml
restic_check_after_backup: true
restic_check_read_data_subset: 5%
restic_forget_after_backup: true
restic_keep_last: 7
restic_keep_daily: 7
restic_keep_weekly: 4
restic_keep_monthly: 6
restic_keep_yearly: 2
backup_start_delay_seconds: 0
```

Environment variables can still override YAML values when you need an emergency override, but the clean setup is YAML for configuration and Kamal secrets for secrets.
