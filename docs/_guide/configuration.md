---
title: Configuration
description: Required environment, database settings, restic repository options, retention, and scheduler flags.
nav_order: 2
---

## Common environment

```sh
APP_NAME=chatwithwork
DATABASE_ADAPTER=postgres
RESTIC_REPOSITORY=s3:https://s3.example.com/chatwithwork-backups
RESTIC_PASSWORD=change-me
BACKUP_PATHS=/data/storage
```

`BACKUP_PATHS` accepts colon-separated or newline-separated paths. Every configured path must exist before a backup starts.

## Database settings

PostgreSQL:

```sh
DATABASE_ADAPTER=postgres
DATABASE_URL=postgres://app@app-db:5432/app_production
PGPASSWORD=change-me
```

MySQL/MariaDB:

```sh
DATABASE_ADAPTER=mysql
DATABASE_URL=mysql2://app@app-mysql:3306/app_production
MYSQL_PWD=change-me
```

SQLite:

```sh
DATABASE_ADAPTER=sqlite
SQLITE_DATABASE_PATH=/data/db/production.sqlite3
```

If `DATABASE_ADAPTER` is omitted, `kamal-backup` tries to detect the adapter from `DATABASE_URL` or `SQLITE_DATABASE_PATH`.

## Restic and S3-compatible storage

`kamal-backup` passes standard restic environment through unchanged. For S3-compatible repositories, configure credentials as Kamal secrets:

```sh
AWS_ACCESS_KEY_ID=...
AWS_SECRET_ACCESS_KEY=...
AWS_DEFAULT_REGION=...
```

Use object storage credentials scoped to the backup bucket or prefix. They should not have access to unrelated buckets.

## Retention

Defaults:

```sh
RESTIC_KEEP_LAST=7
RESTIC_KEEP_DAILY=7
RESTIC_KEEP_WEEKLY=4
RESTIC_KEEP_MONTHLY=6
RESTIC_KEEP_YEARLY=2
```

After a successful backup, `kamal-backup` runs `restic forget --prune` with the configured retention policy.

## Scheduler

The default container command is:

```sh
kamal-backup schedule
```

Scheduler settings:

```sh
BACKUP_SCHEDULE_SECONDS=86400
BACKUP_START_DELAY_SECONDS=0
RESTIC_CHECK_AFTER_BACKUP=false
RESTIC_CHECK_READ_DATA_SUBSET=5%
```
