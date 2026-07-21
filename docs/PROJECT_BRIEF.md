# CalRem Project Brief

## Product Direction

CalRem is a native macOS planner for one person on one Mac. It should feel close
to Apple Reminders in simplicity, but it must make scheduled tasks visible in a
calendar the way TickTick does.

The core product promise is simple:

> A task can live in a list, and when it has a date or time range, it appears in
> the calendar.

## Version 0.1 Goal

Build a reliable local MVP with two polished foundations:

- Task lists and reminders.
- Calendar visualization for dated and timed tasks.

The app should be useful before any account system, backend, sync, or
collaboration exists.

## Core User Flows

1. Create a list.
2. Create a task in that list.
3. Add a date, start time, and end time to the task.
4. See the task in the task list.
5. See the same task as a block in the calendar.
6. Edit the task from either the list or the calendar.
7. Complete or delete the task.
8. Close and reopen the app without losing data.
9. Add a local reminder notification for a future task.

## Design Principles

- Native macOS first.
- Minimalist, calm, Apple-like.
- No landing page inside the app.
- Dense enough for repeated productivity use.
- Clear task state without visual noise.
- Calendar blocks should make time ranges obvious at a glance.

## Technical Principles

- SwiftUI for the app UI.
- SwiftData for local persistence.
- UserNotifications for local reminders.
- Keep EventKit as a future integration, not an MVP dependency.
- Keep scheduling and calendar date math testable outside SwiftUI views.
- Prefer small, reviewable branches and commits.

## Release Criteria

Version `v0.1.0` is ready when a user can create a list, create a task with a
date and time range, see it in the list and calendar, persist it after relaunch,
and schedule/cancel a local reminder.
