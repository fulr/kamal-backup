---
layout: home
title: Home
description: "Rails-friendly encrypted backups for Kamal apps: PostgreSQL, MySQL, SQLite, and file-backed Active Storage on mounted volumes."
permalink: /
hero:
  name: kamal-backup
  text: Back up Postgres, MySQL, SQLite, and Rails file data from Kamal
  tagline: Run encrypted backups, restore drills, and evidence collection for CASA and other security reviews from one Kamal accessory.
  actions:
    - theme: brand
      text: Get Started
      link: /getting-started/
    - theme: alt
      text: How It Works
      link: /how-backups-work/
    - theme: alt
      text: GitHub
      link: https://github.com/crmne/kamal-backup
  image:
    src: /assets/images/logo.svg
    alt: kamal-backup
    width: 256
    height: 256
features:
  - icon: 🗄️
    title: PostgreSQL, MySQL, and SQLite
    details: Use `pg_dump`, `mariadb-dump` or `mysqldump`, and `sqlite3 .backup` to capture the database with tools Rails developers already know.
  - icon: 📁
    title: Active Storage on Mounted Volumes
    details: Back up file-backed Active Storage and other mounted app paths in one restic file snapshot per run.
  - icon: 🔒
    title: Restore Drills, Not Wishful Thinking
    details: Run deliberate database and file restores with explicit targets and safety checks before a reviewer asks for proof.
  - icon: ✅
    title: Evidence for CASA and Reviews
    details: Produce a redacted JSON summary with latest snapshots, latest check result, retention settings, and tool versions.
---
