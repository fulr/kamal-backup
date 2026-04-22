---
title: Getting Started
description: Add kamal-backup as a Kamal accessory and run the first backup.
nav_order: 1
---

## Add the accessory

Add a backup accessory to your Kamal deploy config:

```yaml
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

The image installs the `kamal-backup` gem, so the executable is available inside the accessory container:

```sh
bin/kamal accessory exec backup "kamal-backup backup"
bin/kamal accessory exec backup "kamal-backup list"
bin/kamal accessory exec backup "kamal-backup evidence"
```

## What gets backed up

Each backup run creates:

- one logical database dump stored through restic stdin;
- one `type:files` restic snapshot containing all configured `BACKUP_PATHS` entries.

Database dump snapshots are tagged with `kamal-backup`, `app:<name>`, `type:database`, `adapter:<adapter>`, and `run:<timestamp>`. File snapshots use `type:files`, the same run tag, and informational `path:<label>` tags for the configured paths. Restore selects by `type:files`, not by one path tag.
