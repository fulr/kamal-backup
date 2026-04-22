---
title: Restore Drills
description: Run deliberate database and file restores with explicit safety flags.
nav_order: 3
---

Restores are designed to be explicit manual operations. Every restore command requires:

```sh
KAMAL_BACKUP_ALLOW_RESTORE=true
```

## Database restores

Database restores use restore-specific environment by default. They do not restore to `DATABASE_URL`.

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

Use restore drills regularly. A backup that has never been restored is only an assumption.
