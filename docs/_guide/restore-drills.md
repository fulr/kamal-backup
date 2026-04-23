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
