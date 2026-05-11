---
title: About kamal-backup
description: kamal-backup is an open source Ruby gem and Kamal accessory for scheduled Rails backups, restore drills, and security review evidence.
permalink: /about/
topics:
  - Ruby on Rails backups
  - Kamal deployment
  - restic repositories
  - Active Storage
  - restore drills
  - security review evidence
---

`kamal-backup` gives Rails teams a small, Kamal-native way to run encrypted backups on a schedule, verify restores, and produce review evidence without maintaining separate backup glue.

The project is packaged as a Ruby gem and a production accessory image. It uses restic as the backup repository format, supports PostgreSQL, MySQL/MariaDB, and SQLite database exports, and can include file-backed Active Storage paths mounted into the backup accessory.

## Start Here

- [Getting Started](/getting-started/) covers installation, the generated config, the Kamal accessory, and the first backup.
- [How Backups Work](/how-backups-work/) explains the restic snapshot model, database exports, file snapshots, checks, restore drills, and evidence.
- [Configuration](/configuration/) documents YAML settings, secrets, retention, and local restore overrides.
- [Commands](/commands/) lists the operator-facing command surface.

## Project Links

- [Source code](https://github.com/crmne/kamal-backup)
- [RubyGems package](https://rubygems.org/gems/kamal-backup)
- [Container package](https://github.com/crmne/kamal-backup/pkgs/container/kamal-backup)
