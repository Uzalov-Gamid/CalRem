# Decision 0001: Local-First MVP With No Authentication

## Status

Accepted.

## Context

The first version of CalRem is for personal use on one MacBook. The goal is to
perfect the core planner behavior before expanding into sync, accounts, sharing,
or platform services.

## Decision

Version `v0.1` will not include authentication, user accounts, cloud backend,
team collaboration, subscriptions, or cross-device sync.

The app will store its own local data and use local macOS notifications for
reminders. Apple Reminders and Calendar integration may be explored later, but
the MVP will not depend on those services as the primary source of truth.

## Consequences

- The MVP can be built faster and with fewer failure modes.
- User data remains local to the Mac.
- The data model can focus on task lists, task scheduling, and calendar
  visualization.
- Future sync will require a deliberate migration plan instead of being an
  accidental early dependency.
