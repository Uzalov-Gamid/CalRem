# CalRem

CalRem is a native macOS planner that combines Reminders-style task lists with
TickTick-style calendar visualization.

The first version is intentionally local-first and personal: no accounts, no
authorization flow, no backend, and no team features. It is built for one Mac and
one user first, with a calm Apple-like interface and reliable core planning
behavior.

## MVP Scope

- Create and manage task lists.
- Create, edit, complete, and delete tasks.
- Schedule tasks as undated, all-day, or timed tasks.
- Show every dated task in the calendar.
- Visualize timed tasks as calendar blocks with a start and end time.
- Persist data locally.
- Schedule local macOS reminder notifications.

## Not in v0.1

- User accounts or sign in.
- Cloud backend.
- Collaboration.
- Payments or subscriptions.
- Cross-device sync.
- Apple Reminders or Calendar sync as the primary data source.

## Development

The repository uses `main` as the stable branch. Work should happen in short-lived
branches named by intent, for example `feature/task-editor` or
`chore/repository-setup`.

Xcode is installed at `/Applications/Xcode.app`. If command-line tools are not
globally pointed at Xcode, use:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -version
```

More detail lives in:

- [Project brief](docs/PROJECT_BRIEF.md)
- [Git workflow](docs/GIT_WORKFLOW.md)
- [Local-first decision](docs/decisions/0001-local-first-no-auth.md)
