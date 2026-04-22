---
title: Evidence
description: Generate redacted backup-readiness evidence for security reviews.
nav_order: 4
---

`kamal-backup evidence` prints a redacted JSON summary:

```sh
bin/kamal accessory exec backup "kamal-backup evidence"
```

The output includes:

- app name;
- current time;
- database adapter;
- redacted restic repository;
- configured file backup paths;
- whether client-side forget/prune is enabled;
- retention policy;
- latest database and file snapshots;
- last tracked `restic check` result;
- image version;
- installed tool versions.

Secrets, passwords, access keys, and database URL credentials are redacted before output.

## Restic checks

Run checks manually:

```sh
bin/kamal accessory exec backup "kamal-backup check"
```

Or enable checks after successful backups:

```sh
RESTIC_CHECK_AFTER_BACKUP=true
RESTIC_CHECK_READ_DATA_SUBSET=5%
```

The latest check result is stored under `KAMAL_BACKUP_STATE_DIR` and included in evidence output when available.
