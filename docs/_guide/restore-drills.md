---
title: Restore Drills
description: Run deliberate database and file restores, and record the result in the language a reviewer expects.
nav_order: 4
---

Restores are designed to be explicit manual operations. Every restore command requires:

```sh
KAMAL_BACKUP_ALLOW_RESTORE=true
```

For production-adjacent drills, run restore commands through the backup accessory so they use the same image and tool versions as scheduled backups.

When you run a drill, record:

- when you ran it;
- who ran it;
- which snapshot you restored;
- which restore target you used;
- whether the restored data looked correct.

That note matters almost as much as the command output when you later need to explain your process to a reviewer.

## Local development restore

For a small Rails app, the quickest restore drill is often the local development machine:

```sh
KAMAL_BACKUP_ALLOW_RESTORE=true bundle exec exe/kamal-backup restore-local
```

`restore-local` restores the latest database snapshot into the current `DATABASE_URL` or `SQLITE_DATABASE_PATH`, and restores the latest file snapshot back into the current `BACKUP_PATHS`. If the production file path differs from the local file path, set `LOCAL_RESTORE_SOURCE_PATHS` to the production path list and keep `BACKUP_PATHS` pointed at the local targets. It refuses to run when `RAILS_ENV`, `RACK_ENV`, `APP_ENV`, or `KAMAL_ENVIRONMENT` is set to `production` unless you explicitly override that safety check.

That is useful when you want a fast answer to "can we really bring this app back?" without provisioning extra infrastructure.

For larger apps, treat `restore-local` as a developer convenience, not the main drill. Run the production-adjacent drill below against a scratch database and scratch file path that look more like the real deployment.

## Database restores

Database restores use restore-specific environment by default. They do not restore into `DATABASE_URL`.

PostgreSQL:

```sh
bin/kamal accessory exec backup \
  --env KAMAL_BACKUP_ALLOW_RESTORE=true \
  --env RESTORE_DATABASE_URL=postgres://app@app-db:5432/app_restore \
  "kamal-backup restore-db latest"
```

MySQL/MariaDB:

```sh
bin/kamal accessory exec backup \
  --env KAMAL_BACKUP_ALLOW_RESTORE=true \
  --env RESTORE_DATABASE_URL=mysql2://app@app-mysql:3306/app_restore \
  "kamal-backup restore-db latest"
```

SQLite:

```sh
bin/kamal accessory exec backup \
  --env KAMAL_BACKUP_ALLOW_RESTORE=true \
  --env RESTORE_SQLITE_DATABASE_PATH=/restore/db/restore.sqlite3 \
  "kamal-backup restore-db latest"
```

Restore targets that look production-like are refused unless:

```sh
KAMAL_BACKUP_ALLOW_PRODUCTION_RESTORE=true
```

## File restores

File restores default to `/restore/files`:

```sh
bin/kamal accessory exec backup \
  --env KAMAL_BACKUP_ALLOW_RESTORE=true \
  "kamal-backup restore-files latest /restore/files"
```

Restoring into configured backup paths is refused unless:

```sh
KAMAL_BACKUP_ALLOW_IN_PLACE_FILE_RESTORE=true
```

Use restore drills regularly. A backup that has never been restored is still only an assumption.
