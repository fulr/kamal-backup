---
layout: home
title: Home
description: "The easiest scheduled backup setup for Rails apps deployed with Kamal: databases, file-backed Active Storage, restore drills, and security review evidence."
permalink: /
hero:
  name: kamal-backup
  text: Scheduled backups for Rails apps deployed with Kamal
  tagline: Back up PostgreSQL, MySQL, SQLite, and file-backed Active Storage files from one Kamal accessory, then run restore drills and produce evidence for security reviews like CASA.
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
  - icon: 🕒
    title: Runs on a Schedule
    details: Boot the accessory and it runs `kamal-backup schedule` by default. Set `BACKUP_SCHEDULE_SECONDS` and keep daily backups moving without cron glue.
  - icon: 🗄️
    title: Databases and Active Storage
    details: Back up PostgreSQL, MySQL/MariaDB, or SQLite with database-native tools, plus file-backed Active Storage files from mounted volumes such as `/data/storage`.
  - icon: 🔒
    title: Restore Drills Built In
    details: Restore locally or into scratch production-side targets, run verification commands, and record the result instead of trusting backup logs.
  - icon: ✅
    title: Evidence for Security Reviews
    details: Produce redacted JSON with latest database and Active Storage snapshots, `restic check`, restore drills, retention settings, and tool versions for security reviews like CASA.
---
