---
title: How Backups Work
description: What restic does here, what happens during a backup run, and what list, check, and evidence mean in practice.
nav_order: 2
---

## Restic in this setup

`kamal-backup` uses [restic](https://restic.net/) as the backup engine and repository format.

In normal Kamal use, you do not install restic on the Rails app host. The backup accessory image already contains the `restic` binary. You point that accessory at a restic repository, usually:

- S3-compatible object storage;
- a restic REST server;
- a filesystem path for local development.

If you choose a `rest:` repository, `kamal-backup` does not install or run that server for you. It is a separate service you operate yourself.

## What happens during `kamal-backup backup`

When a backup run starts, `kamal-backup` does five things:

1. It validates the app name, restic repository, database settings, and `BACKUP_PATHS`.
2. It creates a database backup using the database-native export tool:
   PostgreSQL uses `pg_dump`, MySQL/MariaDB use `mariadb-dump` or `mysqldump`, and SQLite uses `sqlite3 .backup`.
3. It streams that database backup into restic and tags it with `type:database`, `adapter:<adapter>`, and `run:<timestamp>`.
4. It runs one `restic backup` for all configured `BACKUP_PATHS` and tags that snapshot with `type:files` plus the same `run:<timestamp>`.
5. It optionally runs `restic forget --prune` and `restic check`, depending on configuration.

The result is one database snapshot and one file snapshot per run.

## What gets backed up

`kamal-backup` is built for two data surfaces:

- your app database: PostgreSQL, MySQL/MariaDB, or SQLite;
- file data that lives on mounted volumes, such as file-backed Rails Active Storage.

If your Rails app already stores Active Storage blobs directly in S3, there may be no local file path for `BACKUP_PATHS` to capture. In that case, `kamal-backup` still covers the database side, but S3 object backup and retention are a separate concern.

## What the commands mean

- `backup`: Create one new database snapshot and one new file snapshot.
- `list`: Show restic snapshots for this app so you can see recent runs and snapshot IDs.
- `check`: Run `restic check` and store the latest result in `KAMAL_BACKUP_STATE_DIR`.
- `evidence`: Print a redacted JSON summary with current backup settings, latest snapshots, latest check result, and tool versions. This is meant to be attached to internal ops records or security reviews.
- `restore-db`: Restore a database backup into an explicitly configured restore target.
- `restore-files`: Restore a file snapshot into a target directory, usually `/restore/files`.
- `restore-local`: Restore the latest database and file snapshots into the current local development database and file paths.

## Snapshot tags

Database snapshots are tagged with:

- `kamal-backup`
- `app:<name>`
- `type:database`
- `adapter:<adapter>`
- `run:<timestamp>`

File snapshots are tagged with:

- `kamal-backup`
- `app:<name>`
- `type:files`
- `run:<timestamp>`
- `path:<label>` for each configured file path

The shared `run:<timestamp>` tag lets you correlate the database backup and the file backup from the same run.
