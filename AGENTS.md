# AGENTS.md

Instructions for agents working in this repository. Read this before making changes.

## What this repo is

The AI Lab VPS project. A learning project for Linux administration, Docker,
backend development and agentic AI on an OVHcloud VPS. The plan, journal,
decision log and rescue runbook live here as markdown. The repo is public.

## Writing rules

- Never use semicolons. The user does not use them.
- Never use em dashes (—) or en dashes (–).
- The journal is first person, human, and never mentions the Mac.
- Follow the humanizer skill for all prose: no AI-writing tells, no invented
  facts, no signposting.
- Journal entries use this field order: Mood, Story, What I learned,
  Feelings / notes, Did.

## Time tracker

- `scripts/time-tracker/` is a Rust CLI. Run with
  `cargo run --release --manifest-path scripts/time-tracker/Cargo.toml -- <cmd>`
- Commands: `start`, `close`, `status`, `summary`, `journal`.
- `close` appends the session and refreshes the total time in `journal.md`.
- State lives in `time-tracker.json` at the repo root.

## Privacy

- `time-tracker.json` and `session-log.md` are private and kept local. Never
  commit them.
- Never put emails, VPS IPs or SSH usernames in tracked files. Use
  placeholders like `<user>` and `<vps-ip>`.
- `achievements.md` records GitHub achievements earned by this account.

## Commit style

- Match existing history. Subjects are lowercase, type prefixed
  (e.g. `docs:`, `tracker:`).
- Push to `origin main` when done.
