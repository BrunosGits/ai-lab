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

## Progress so far

Active contribution tracks, newest first:

- **#22676** LATE_MATERIALIZATION profile metrics (analytics engine): reviewed the PR end to end, mapped the Rust and Java changes, built a diagnosis plan for a flaky sandbox-check test, codecov green at 80%
- **#22654** MONITOR mode workload group rejections (helping): confirmed a duplicate PR was already merged, root-caused a 60% codecov gap to a missing branch in `rejectIfNeeded`, designed and shared a coverage test that the author applied, codecov now green at 80%, awaiting maintainer review
- **#17561** Inaccurate codec error message: root cause is a hardcoded list in the error message, fix derives the message from the accepted codec list, two tests cover it, e2e verified, commit `c135dc26` pushed to the fork, awaiting maintainer review
- **#6323** Long strings cut at 2000 characters: reproduced on 2.3.0 and 2.19.6, swept 1980 to 20000 chars across pipelines and remote reindex, no truncation exists, minimal repro posted, awaiting maintainer confirmation of the field-name theory
- **#22494** Regex automaton cache: code paths mapped, coordinating with the author who has a production-tested PoC, do not duplicate
- **#21323** Lucene stderr warnings: watching a stalled PR, monitor only

Full details and checklists live in `ROADMAP.md`.

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
