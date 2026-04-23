# kamal-backup

`kamal-backup` is a small Docker image for Kamal accessories. It creates encrypted, restic-backed backups for self-hosted apps by backing up database dumps and mounted application files together.

The Docker image is the normal production interface. The image ships the `kamal-backup` executable directly, so operators run it through the accessory container.

It is aimed at common Kamal backup needs:

- Kamal Postgres backup
- Kamal MySQL and MariaDB backup
- Kamal Active Storage backup
- Kamal restic backup
- Restore drills and evidence for security reviews such as CASA

## What It Backs Up

`kamal-backup` handles two data surfaces:

1. A logical database dump from PostgreSQL, MySQL/MariaDB, or SQLite.
2. Mounted application files such as Rails Active Storage.

Database backups are logical dumps, not raw database data directories. File backups use one `restic backup` snapshot per run containing all configured mounted paths, so `restore-files latest` restores all file paths from that run.

Database dump snapshots are tagged with `kamal-backup`, `app:<name>`, `type:database`, `adapter:<adapter>`, and `run:<timestamp>`. The dump object uses a flat restic stdin filename such as `databases-chatwithwork-postgres-20260422T120000Z.pgdump` because restic stdin backups do not support nested virtual paths consistently.

## Quick Start With Kamal

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

Run manual commands:

```sh
bin/kamal backup
bin/kamal backup-list
bin/kamal backup-check
bin/kamal backup-evidence
bin/kamal backup-version
bin/kamal backup-schedule
bin/kamal backup-logs
```

Alias reference:

| Alias | Expands to | Use |
|---|---|---|
| `bin/kamal backup` | `accessory exec backup "kamal-backup backup"` | Run one backup immediately. |
| `bin/kamal backup-list` | `accessory exec backup "kamal-backup list"` | Show restic snapshots for the configured app. |
| `bin/kamal backup-check` | `accessory exec backup "kamal-backup check"` | Run `restic check` and store the latest check result. |
| `bin/kamal backup-evidence` | `accessory exec backup "kamal-backup evidence"` | Print redacted backup evidence JSON. |
| `bin/kamal backup-version` | `accessory exec backup "kamal-backup version"` | Print the running `kamal-backup` version. |
| `bin/kamal backup-schedule` | `accessory exec backup "kamal-backup schedule"` | Run the foreground scheduler loop manually. Mostly useful for debugging. |
| `bin/kamal backup-logs` | `accessory logs backup -f` | Tail the backup accessory logs. |

Restore commands are intentionally not part of the default alias block. They require explicit restore flags and restore-specific targets, so run them with raw Kamal commands such as:

```sh
bin/kamal accessory exec backup \
  --env KAMAL_BACKUP_ALLOW_RESTORE=true \
  --env RESTORE_DATABASE_URL=postgres://app@app-db:5432/app_restore \
  "kamal-backup restore-db 19ce9f99"
```

## Commands

Commands usually run inside the production backup accessory with `bin/kamal accessory exec backup "kamal-backup <command>"`, or through Kamal aliases such as `bin/kamal backup`.

```sh
kamal-backup backup
kamal-backup restore-db [snapshot-or-latest]
kamal-backup restore-files [snapshot-or-latest] [target-dir]
kamal-backup list
kamal-backup check
kamal-backup evidence
kamal-backup schedule
kamal-backup version
```

Use `kamal-backup help [command]` for command-specific usage and examples.

| Command | What it does |
|---|---|
| `backup` | Runs one immediate backup, creating one database snapshot and one file snapshot for all `BACKUP_PATHS`. |
| `restore-db [snapshot-or-latest]` | Restores a database dump. Defaults to `latest` and requires explicit restore environment. |
| `restore-files [snapshot-or-latest] [target-dir]` | Restores file paths from a file snapshot. Defaults to `latest /restore/files`. |
| `list` | Lists restic snapshots for the configured app tags. |
| `check` | Runs `restic check` and records the latest result for evidence output. |
| `evidence` | Prints redacted JSON with backup configuration, latest snapshots, check status, and tool versions. |
| `schedule` | Runs the foreground scheduler loop used by the container default command. |
| `version` | Prints the running `kamal-backup` version. `--version` and `-v` do the same. |

The default container command is:

```sh
kamal-backup schedule
```

## Configuration

Required common environment:

```sh
APP_NAME=chatwithwork
DATABASE_ADAPTER=postgres
RESTIC_REPOSITORY=s3:https://s3.example.com/chatwithwork-backups
RESTIC_PASSWORD=change-me
BACKUP_PATHS=/data/storage
```

`BACKUP_PATHS` accepts colon-separated or newline-separated paths. Every path must exist. Suspicious broad paths such as `/`, `/var`, `/etc`, and `/root` are refused unless `KAMAL_BACKUP_ALLOW_SUSPICIOUS_PATHS=true`.

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

Retention defaults:

```sh
RESTIC_KEEP_LAST=7
RESTIC_KEEP_DAILY=7
RESTIC_KEEP_WEEKLY=4
RESTIC_KEEP_MONTHLY=6
RESTIC_KEEP_YEARLY=2
RESTIC_FORGET_AFTER_BACKUP=true
```

Set `RESTIC_FORGET_AFTER_BACKUP=false` for append-only repositories, such as a restic REST server started with `--append-only`. In that mode, run retention and prune from the backup server or another trusted maintenance process with delete permissions.

Scheduler and checks:

```sh
BACKUP_SCHEDULE_SECONDS=86400
BACKUP_START_DELAY_SECONDS=0
RESTIC_CHECK_AFTER_BACKUP=false
RESTIC_CHECK_READ_DATA_SUBSET=5%
```

For S3-compatible restic repositories, provide the standard restic/AWS variables as Kamal secrets:

```sh
AWS_ACCESS_KEY_ID=...
AWS_SECRET_ACCESS_KEY=...
AWS_DEFAULT_REGION=...
```

## Restore Drills

Restores are intentionally hard to run by accident. Every restore command requires:

```sh
KAMAL_BACKUP_ALLOW_RESTORE=true
```

Database restores use restore-specific environment by default. They do not restore to `DATABASE_URL`.

PostgreSQL restore:

```sh
bin/kamal accessory exec backup \
  --env KAMAL_BACKUP_ALLOW_RESTORE=true \
  --env RESTORE_DATABASE_URL=postgres://app@app-db:5432/app_restore \
  "kamal-backup restore-db latest"
```

MySQL/MariaDB restore:

```sh
bin/kamal accessory exec backup \
  --env KAMAL_BACKUP_ALLOW_RESTORE=true \
  --env RESTORE_DATABASE_URL=mysql2://app@app-mysql:3306/app_restore \
  "kamal-backup restore-db latest"
```

SQLite restore:

```sh
bin/kamal accessory exec backup \
  --env KAMAL_BACKUP_ALLOW_RESTORE=true \
  --env RESTORE_SQLITE_DATABASE_PATH=/restore/db/restore.sqlite3 \
  "kamal-backup restore-db latest"
```

File restore:

```sh
bin/kamal accessory exec backup \
  --env KAMAL_BACKUP_ALLOW_RESTORE=true \
  "kamal-backup restore-files latest /restore/files"
```

Restore targets that look production-like are refused unless:

```sh
KAMAL_BACKUP_ALLOW_PRODUCTION_RESTORE=true
```

File restores to configured backup paths are refused unless:

```sh
KAMAL_BACKUP_ALLOW_IN_PLACE_FILE_RESTORE=true
```

## Evidence

`kamal-backup evidence` prints a redacted JSON summary suitable for operational evidence:

- app name
- current time
- database adapter
- redacted restic repository
- configured file backup paths
- whether client-side forget/prune is enabled
- retention policy
- latest database and file snapshots
- last tracked `restic check` result
- image version
- installed tool versions

Secrets, passwords, access keys, and database URL credentials are redacted.

Run:

```sh
bin/kamal accessory exec backup "kamal-backup evidence"
```

## Local Development

Install the CLI dependencies:

```sh
bundle install
```

Run tests:

```sh
bin/test
```

Run docs locally:

```sh
cd docs
bundle install
bundle exec jekyll serve --livereload
```

Published docs are configured for `https://kamal-backup.dev`.

Build the image:

```sh
docker build -t kamal-backup .
```

CI publishes container images to `ghcr.io/crmne/kamal-backup`. Pull requests build the image without pushing; branch, tag, SHA, default-branch `latest`, and default-branch version tags are pushed on non-PR builds. The version tag comes from `lib/kamal_backup/version.rb`, and default-branch pushes also create the matching GitHub release.

The Docker image installs the bundled gems and copies the Ruby CLI from `exe/` and `lib/`, which is why `kamal-backup` is on `PATH` inside the container.

In normal Kamal use, there is no installation step on the app host. Run the command inside the accessory:

```sh
bin/kamal accessory exec backup "kamal-backup evidence"
```

Run a local backup against a filesystem restic repository:

```sh
export APP_NAME=local-app
export DATABASE_ADAPTER=sqlite
export SQLITE_DATABASE_PATH=/tmp/app.sqlite3
export BACKUP_PATHS=/tmp/app-files
export RESTIC_REPOSITORY=/tmp/kamal-backup-restic
export RESTIC_PASSWORD=local-password
export RESTIC_INIT_IF_MISSING=true

bundle exec exe/kamal-backup backup
bundle exec exe/kamal-backup list
bundle exec exe/kamal-backup evidence
```

An example Docker Compose setup for local integration work is in `examples/docker-compose.integration.yml`.

## Container Contents

The image is based on Debian slim Ruby and includes:

- Ruby runtime
- `pg_dump` and `pg_restore`
- `mariadb-dump` or `mysqldump`, plus `mariadb` or `mysql`
- `sqlite3`
- `restic`
- CA certificates
- `tini`

## Security Notes

- Subprocesses are executed with argument arrays, not shell interpolation.
- The CLI redacts secrets in errors and evidence output.
- Database backups use logical dump tools.
- File data should be mounted read-only in the backup accessory.
- Restores require explicit environment flags.
- Object storage credentials should be least-privilege for the backup bucket or prefix.

## Non-Goals

- Not a hosted backup service.
- Not a replacement for database point-in-time recovery.
- Not a physical replication tool.
- Not a secret manager.

## License

MIT
