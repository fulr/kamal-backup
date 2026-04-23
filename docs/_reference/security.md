---
title: Security and Restore Safety
description: How kamal-backup handles secrets, subprocesses, backup formats, and deliberate restores.
nav_order: 2
---

## Secrets

`kamal-backup` redacts secrets in evidence and command failure output. It treats values from keys containing words such as `password`, `secret`, `token`, `key`, and `credential` as sensitive.

Do not put cloud credentials in clear Kamal environment. Use Kamal secrets for:

- `RESTIC_PASSWORD`;
- `AWS_ACCESS_KEY_ID`;
- `AWS_SECRET_ACCESS_KEY`;
- database passwords such as `PGPASSWORD` and `MYSQL_PWD`.

## Subprocess execution

External tools are executed with argument arrays, not shell interpolation. The backup container does not need application source code.

## Database backups

Database backups use database-native export tools:

- PostgreSQL: `pg_dump --format=custom --no-owner --no-privileges`
- MySQL/MariaDB: `mariadb-dump` or `mysqldump` with transaction-safe defaults
- SQLite: `sqlite3 <db> ".backup ..."`

This is why the docs talk about database backups rather than raw database directories. `kamal-backup` is exporting application data with the tools Rails teams already use for dumps and restores.

## Deliberate restores

All restore commands require `KAMAL_BACKUP_ALLOW_RESTORE=true`.

Database restores use restore-specific targets:

- PostgreSQL/MySQL/MariaDB: `RESTORE_DATABASE_URL`
- SQLite: `RESTORE_SQLITE_DATABASE_PATH`

Production-looking targets are refused unless `KAMAL_BACKUP_ALLOW_PRODUCTION_RESTORE=true`.

File restores into configured backup paths are refused unless `KAMAL_BACKUP_ALLOW_IN_PLACE_FILE_RESTORE=true`.

Those checks are there to make restore drills deliberate. They also help when you need to explain to a reviewer that backup restores cannot quietly point back at production by accident.
