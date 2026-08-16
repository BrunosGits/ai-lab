# OpenSearch Contributions

A record of my journey contributing to OpenSearch: understanding the codebase,
finding issues, sending patches and learning how a large open source project
actually works.

## What's here

- `journal.md`: personal journal, one entry per day
- `project-conception-log.md`: timeline of every decision, chosen or rejected, and why
- `ROADMAP.md`: master plan of open tasks, seeded to the Trello kanban
- `scripts/`: tools: Rust time tracker (`time-tracker/`), an issue status checker and a Trello kanban sync
- `.opencode/`: opencode config, including the `/end-session` and `/check-issues` commands (local only, never published)
- `AGENTS.md`: instructions for AI agents working in this repo (local only, never published)

## How the tracker works

Start a session, close it when done, and the tracker appends the hours and
refreshes the total in `journal.md`:

```
cargo run --release --manifest-path scripts/time-tracker/Cargo.toml -- start
cargo run --release --manifest-path scripts/time-tracker/Cargo.toml -- close
```

## How to check the tracked issues

Run `/check-issues` at the start of a session to see the state, labels and
latest comment on each tracked issue.

Session timings are kept private in `time-tracker.json` and `session-log.md`,
excluded from git. Only the journal, decision log and summary docs are public.

## Environment

Reproduction and testing run on the VPS, with Docker installed on demand.
Docker is installed and the #6323 reproduction ran as containers. The VPS
address, login name and key are private and never appear in this repo.

## License

MIT
