---
description: Close the time tracker session, then write the journal entry and the conception-log decision for today.
---

End this working session and record it. Do the steps in order.

1. Close the tracker: `cargo run --release --manifest-path scripts/time-tracker/Cargo.toml -- close`. Keep the printed start, end and totals for later.
2. Read `journal.md`. If today already has a dated entry, merge the new content into it. Otherwise prepend a new entry at the top with heading `## <date>: <short title>` and the fields, in this exact order: `**Mood:**`, `**Story:**`, `**What I learned:**`, `**Feelings / notes:**`, `**Did:**`.
3. Read `project-conception-log.md`. If today's session produced any real decision (chosen, considered, rejected), add a dated section at the top of the decision timeline with one `**Decision: ...**` block per decision.
4. Run `scripts/check-achievements.sh`. If it prints new achievements, add a dated entry for each under the top of the achievements list in `achievements.md` with the name, what earned it, and one line of feeling. Skip silently when nothing is new.
5. If the session completed any roadmap or plan items, tick them off in this repo's plan file `ai-lab-summary.md`.
6. Run `scripts/trello-kanban.sh sync`. It reads the plan file and pushes new unchecked tasks to the Personal Kanban board. It is idempotent and safe to rerun. Skip only if Trello credentials are not set up yet.
7. If today is a new journal day, refresh the total time in the right-aligned line at the top of `journal.md` using the tracker totals.
8. Write the prose under the user's humanizer rules: no semicolons, no em or en dashes, no AI-writing tells, first person, and never mention the Mac. The fields only contain the user's own facts. Do not invent any. Let the user read and approve the journal text before moving on.
9. Commit with a message like `docs: journal, <summary>` and push to origin main.

Do not stop the tracker if the session is already closed. Do not touch `time-tracker.json` or `session-log.md` contents beyond what the `close` command does. Session data stays private. Only journal, conception log and summary docs get committed.
