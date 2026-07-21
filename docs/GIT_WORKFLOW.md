# Git Workflow

## Branches

- `main` is stable and should always represent a buildable state.
- Work happens in short-lived branches.
- Branch names should describe intent:
  - `feature/calendar-week-view`
  - `feature/task-editor`
  - `chore/repository-setup`
  - `test/calendar-layout`
  - `docs/readme`

## Commits

Use small commits that tell the story of the change. Prefer conventional prefixes:

- `feat:` user-facing functionality
- `fix:` bug fixes
- `test:` automated or manual test assets
- `docs:` documentation
- `chore:` repository, tooling, or project maintenance
- `refactor:` internal code changes without behavior changes

Examples:

```bash
git commit -m "feat: add SwiftData task models"
git commit -m "test: cover calendar month grid generation"
git commit -m "docs: document local-first MVP scope"
```

## Pull Requests

Each meaningful slice should be merged through a pull request, even for solo
development. The PR should include:

- What changed.
- How it was verified.
- Linked issue numbers when relevant.
- Known limitations or follow-up work.

Repository settings are intentionally simple:

- Wiki disabled.
- Discussions disabled.
- Projects disabled for now.
- Merge commits disabled.
- Squash and rebase merges enabled.
- Branches are deleted after merge.

## Issue-Driven Development

GitHub Issues are the working backlog. Prefer taking one issue or one tightly
related group of issues at a time.

Good implementation prompt:

```text
Implement issue #14. Keep the change scoped, add tests, commit, push, and open a PR.
```

For larger work:

```text
Implement issues #14, #15, and #24 as one calendar foundation slice. Commit in
logical steps and keep main buildable.
```

## Verification

Before opening or merging a PR, run the most relevant local checks. Once the
Xcode project exists, the default command should be:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -project CalRem.xcodeproj -scheme CalRem -destination 'platform=macOS'
```
