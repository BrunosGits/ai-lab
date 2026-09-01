# 🔍 OpenSearch Contributions

*Learning a large open source project* · Started 2026-08-07

This document is the master plan for contributing to [OpenSearch](https://github.com/opensearch-project/OpenSearch), the open source search engine. The goal is to learn how a large open source project actually works by doing the work: read the code, reproduce a real issue, send a real patch. Every change ships through a fork, a PR and maintainer review, and each contribution lands a journal entry and a roadmap update.

---

## 🖥️ Environment & Setup

- [x] Project scaffold (repo, journal, project log, roadmap)
- [x] Docker on the VPS for reproduction
- [x] JDK 21 + Gradle build working
- [x] VPS checkout of `OpenSearch` kept clean (restore after each session)

### Commands learned — Setup

**Reproduction (Docker)**
- `docker run` / `docker compose` — OpenSearch containers for issue reproduction
- Sweep multiple versions: 2.3.0 and 2.19.6, strings 1980 to 20000 chars

**Tests & coverage (Gradle + JDK 21)**
- `./gradlew :server:test --tests "<FQCN>"` — run a single test class (e.g. `EngineConfigTests`)
- `./gradlew :test:framework:test --tests "<FQCN>"` — WLM tests, 83 pass
- `jacoco` report — coverage proof; a `pc` (partially covered) on a `||` line means operand short-circuit, not a real bug
- Codecov patch target is auto-derived from the project baseline (71.43%), not a fixed 80%

**Git history hygiene**
- `git filter-repo` — rewrite author identities (the PublishProject cleanup)
- `git push --force` — update history after the rewrite
- Lesson: a stale global git identity misattributes commits for weeks

**GitHub coordination**
- `gh issue comment <n> --body <msg>` — post findings/repros
- `gh pr comment <n>` — post code suggestions for contributors
- `gh pr create --head <fork>:<branch>` — open PR from fork branch
- `gh run watch <id>` — watch CI
- `gh repo fork <repo> --clone=false` — create fork without cloning
- Patch recovery: `ssh vps "cd ~/OpenSearch && git diff branch~1..branch"` → apply to clean clone

---

## 🐛 Issue Tracks

### #6323 — Long strings cut at 2000 characters (2023 bug) 🔄
- [x] Reproduced on 2.3.0 and 2.19.6 — no truncation exists in vanilla OpenSearch
- [x] Swept 1980 to 20000 chars, pipelines, remote reindex — all layers intact
- [x] Exact error message reproduced only via a long string in a key position (dot expansion)
- [x] Minimal reproduction posted using the reporter's exact string
- [ ] Maintainer confirmation of the field-name theory
- [ ] Fix once confirmed

### #17561 — Inaccurate codec error message 🟡
- [x] Root cause: error message lists hardcoded codecs, not the accepted list
- [x] Fix: error message derived from the same list validation accepts (built-ins + registered Lucene codecs + aliases, deduped + sorted)
- [x] Two tests cover it
- [x] `EngineConfigTests` green on the VPS (JDK 21)
- [x] e2e verified: `not_a_codec` returns the full list, `best_compression` still works
- [x] Fix recovered from VPS, pushed to `BrunosGits/OpenSearch:fix/17561-codec-error-message`
- [x] PR #22749 opened, DCO fixed, CI running
- [x] Merge conflict resolved (rebase onto latest main, kept both the codec tests and upstream's new toBuilder test in `EngineConfigTests`), `EngineConfigTests` green on the VPS
- [x] Reviewer approved; PR #22749 now `MERGEABLE`
- [ ] gradle-check green, then merge

### #22654 — MONITOR mode workload group rejections (helping) 🟡
- [x] PR #22701 confirmed duplicate of merged #22610, commented, tagged triage to close
- [x] PR #22654 root-caused: fix correct, codecov/patch at 60% (target auto 71.43%)
- [x] Coverage gap: missing `isPresent() == false` branch in `rejectIfNeeded`
- [x] Minimal test designed, 83 WLM tests green on VPS
- [x] jacoco report proves line 274 fully covered (80%)
- [x] Humanized comment posted with the exact test code
- [x] Author applied the test, codecov hit 80%, CI green
- [ ] Waiting on maintainer review

### #22494 — Cache compiled regex automatons (plan B) 🕳️
- [x] Author ZiwenWan pinged — production-tested PoC exists, strong latency numbers
- [x] Code paths mapped: `RegexpQuery`, `AutomatonQuery`, `KeywordFieldMapper` + cache API
- [x] Strategy: monitor and coordinate, do not duplicate
- [ ] Author opens PR, review/help as needed

### #21323 — Lucene stderr warnings (watching) 👀
- PR #21359 stalled in review — monitor only, do not duplicate

### #22706 — Flaky AnalyticsQueryTaskCleanupIT test 🔵
- [x] Root caused: test injects raw `TaskCancelledException` on streaming channel, but production wraps in `StreamException(StreamErrorCode.CANCELLED)` via `toWireError`
- [x] Streaming transport doesn't propagate non-`StreamException` errors, so failure is silently swallowed
- [x] Fix: one line change in failure injector lambda to send `StreamException` instead of raw exception
- [x] Commented claiming the issue with root cause analysis
- [x] One line fix written (`StreamException` in the failure injector lambda)
- [ ] PR #22750 currently mixes both this fix and the codec fix (#17561); split it by dropping the codec commit so #22750 carries only this fix
- [ ] Rebase the split branch onto latest main, push via SSH, confirm #22750 turns mergeable

---

## 🧩 Follow-ups discovered

- [ ] WLM MONITOR mode has zero user-facing docs — two confusing monitor concepts (`WlmMode.MONITOR_ONLY` vs `ResiliencyMode.MONITOR`)
- [ ] Local scroll requests bypass the transport interceptor and listener — MONITOR guard not hit there
- [ ] Integration test gaps for the MONITOR behavior documented

---

## ✅ Completed Contributions

### #22676 — LATE_MATERIALIZATION profile metrics (analytics engine) ✅
- [x] PR #22676: emit `physical_plan` and `data_node_metrics` for LM stage when `profile=true`
- [x] Reviewed: posted three issues (wire BWC guard, static test provisioning flag, shard label uniqueness)
- [x] Author addressed feedback, CI green
- [x] **Merged by mch2 on 2026-08-31**

---

## 🔄 Contribution Loop (the habit)

```
Find → Claim → Reproduce → Root-cause → Fix → Test → Comment → PR → Journal → Update ROADMAP
```

Small issues get claimed within days. Claim fast and be ready to reproduce fast. Always check for an existing PR before commenting.

---

## 📈 Skills to build along the way

- Reading a large Java codebase (server, plugins, test framework)
- Reproducing issues across versions with Docker
- Writing coverage-proof unit tests and reading jacoco/codecov
- Coordinating with third-party contributors and maintainers

---

