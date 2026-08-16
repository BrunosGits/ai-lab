# Project Conception Log

Timeline of decisions behind the OpenSearch contribution project. Every idea considered, chosen or
rejected, and why. This complements the private session log (what was done, kept local) and journal.md
(how it felt). Updated whenever a decision is made.

---

## 2026-08-14: WLM and issue triage decisions

Decision: PR #22701 (read block auto-release) is a duplicate of merged #22610.
- Considered: helping fix the PR and getting it merged
- Chosen: post a comment explaining it is a duplicate and close this path
- Why: PR #22610 was merged Aug 11 with the same setting, plus exclude_patterns, full registration, and tests. The PR branch conflicts with main and its gradle-check fails because the setting is not registered. No value in fixing a duplicate.

Decision: PR #22654 (monitor mode workload group rejections) is the active track.
- Considered: waiting for the author, or doing the work ourselves
- Chosen: investigate, design the exact missing test, verify locally, and post the fix in a comment
- Why: the fix is correct, gradle-check passes, only codecov/patch fails at 60% (target 80%). The gap is one branch (isPresent() == false). A single test fixes it. The author is responsive. Posting the exact test code lets them apply it fast and get green.

Decision: codecov target is auto-derived from project baseline, not fixed 80%.
- Discovered: codecov.yml sets project target at 70% + 1% = 71.43%. Patch target defaults to project baseline.
- Result: 4/5 lines = 80% clears the check. The remaining partial on line 277 (|| operand short-circuit) is acceptable.

Finding: local scroll requests bypass the MONITOR guard.
- Both the transport interceptor and the search listener are skipped for local _search/scroll on the coordinating node.
- This is a follow-up fix, not in scope for #22654.

Finding: WLM has zero user-facing documentation.
- Two confusing monitor concepts exist: WlmMode.MONITOR_ONLY (cluster default) vs ResiliencyMode.MONITOR (group setting).
- A docs PR should be opened separately.

---

## 2026-08-13: Issue triage and #22494 coordination

Decision: #22701 is a duplicate of #22610 (merged Aug 11).
- Verified: main already has cluster.blocks.read.auto_release, exclude_patterns, registration, and tests.
- Action: posted comment on #22701 recommending close as duplicate.

Decision: #22654 is the active help target.
- Root-caused codecov 60% gap to one missing branch (isPresent() == false).
- Designed exact test, verified with 83 WLM tests + jacoco on VPS (4/5 lines covered = 80%).
- Posted humanized comment with exact test code.

Decision: #22494 (cache compiled regex automatons) - monitor and coordinate.
- Author ZiwenWan has production PoC (~50% CPU reduction, halved p99 latency) and is willing to PR.
- Maintainer sandeshkr419 engaged.
- Independent validation: found all call sites (RegexpQuery, AutomatonQuery, KeywordFieldMapper, ConstantKeywordFieldMapper), confirmed Lucene 10.5 AutomatonQuery unconditionally rebuilds CompiledAutomaton (no injection point), cache infra pattern from IndicesFieldDataCache.
- Plan: ping author, monitor their PR, independent investigation continues in parallel.

Finding: #6323 reproduction complete.
- 138-char dotted key reproduces exact error via PUT and painless reindex.
- Length-invariant: short keys (.start, a..b) fail, end. passes.
- Values read back full length - no truncation at 2000 chars.
- Comment posted with findings.

Finding: #17561 fix committed and e2e tested.
- Commit c135dc26 on fork branch fix/17561-codec-error-message.
- Unit tests: CodecTests 16/16 + InternalTranslogManagerTests 5/5 green.
- e2e: bad codec returns 400 with full set; valid codec returns 200.
- Pushed to BrunosGits/opensearch-fork.

---

## 2026-08-07: Contribution strategy

Decision: work from a fork, never directly on upstream.
- Considered: committing to opensearch-project/OpenSearch directly
- Chosen: personal fork plus PR workflow, since this account only has pull access to upstream
- Why: expected for an external contributor. Every change goes through PR review by maintainers, not a direct push.

Decision: issue-first contribution process.
- Considered: picking a change and submitting it directly
- Chosen: follow CONTRIBUTING.md, open an issue and discuss before implementing code
- Why: OpenSearch explicitly says when in doubt, open an issue. A discussed change survives review. A guessed change may conflict with the project's architectural direction.

Decision: DCO configured before the first contribution.
- Chosen: every commit carries Signed-off-by: Real Name <email>, using the real name
- Why: OpenSearch requires a Developer Certificate of Origin on every commit and does not accept anonymous or pseudonymous contributions.

Decision: the goal of PR #1 is learning, not picking Rust.
- Considered: choosing the first issue because a component is written in Rust
- Chosen: let the issue lead. The codebase is mostly Java (server/, modules/, plugins/, libs/, test/, qa/, distribution/).
- Why: the objective of PR #1 is to learn how a large professional open source project works.
- Noted: Rust exists in sandbox/ analytics components (the analytics-backend-datafusion Cargo component). Worth exploring later on its own terms.

Decision: find the issue before installing anything.
- Considered: cloning the ~620 MB repo and installing Java and Gradle right away
- Chosen: pick the issue first, then clone and build
- Why: avoids a long setup for a change that may not be wanted. OpenSearch itself recommends checking existing issues and discussing before implementing.

Decision: OpenCode explores, never writes, until we understand the problem.
- Chosen: read and understand the issue first, use OpenCode to explore and explain the codebase, and only let it implement once we understand the problem.
- Why: keeps this a genuine engineering and maintainer-review exercise instead of submitting AI-generated code.

---

## 2026-08-07: Issue hunt and the repro environment

Decision: target issue #6323 (strings over 2000 chars interrupted during reindex).
- Considered: #21323 (Lucene stderr warnings), #22287 (GCS keystore typo), #22550 (empty store type), #12097 (backport conflicts), #18239 (skip segment_n uploads)
- Chosen: #6323, the only issue that was genuinely unclaimed and had an engaged maintainer
- Why: every other candidate already had an open PR or a volunteer. Small well-scoped issues in OpenSearch get claimed within days, confirmed four times in one session. #6323 is deep, but the maintainer invited a minimal reproduction as the first step, which matches the understand-before-implementing rule.
- Status: reproduction pending, the next step is a minimal repro on the VPS

Decision: #21323 is off the table.
- Considered: taking it once the volunteer did not respond
- Rejected: PR #21359 by Chocochip101 already fixes it, stalled in review for months. A competing PR would be redundant. Coordination comments were posted instead to point everyone at the existing PR.

Decision: reproduce on the VPS via Docker, installed later on demand.
- Considered: running locally (there are no official macOS OpenSearch builds, only Docker or a tarball plus a downloaded JDK), installing Docker immediately
- Chosen: the VPS with Docker, installed only when the go-ahead is given
- Why: Docker makes version switching trivial for reproduction, keeps this machine clean, and Docker is already the planned path in the AI Lab project
- Status: Docker NOT installed yet, pending a go signal
- Privacy: the VPS address, login name and key stay out of tracked files, <vps-ip> and <user> placeholders only

Decision: also volunteer for #17561 (bad index.codec error message).
- Considered: waiting on #6323 alone, or picking #22238 (snapshots over 1000 fail to list)
- Chosen: volunteer for #17561 as a second track, #22238 rejected because the fix would land in the OpenSearch-Dashboards JS repo, not OpenSearch core, and its scope is still unresolved
- Why: we cannot sit idle waiting for #6323 to move. #17561 is small, single-file, and the maintainer (dbwiddis) already pointed at the exact lines in EngineConfig.java. The original author soft-volunteered in 2025 but never submitted anything, and the open design question about the codec list got no answer.
- Status: coordination comment posted 2026-08-07. If both issues get approval, they get coordinated, with #6323 as the primary track.
- Noted: volunteering for two issues is a deliberate bet on the pool being competitive, where a single-track plan stalls for weeks.

Noted: the issue pool is competitive. Good first issue items get claimed within days. The way to win one is to claim fast, or pick the deep unclaimed ones like #6323.

Decision: keep #22494 (cache compiled regex automatons) as plan B, without commenting.
- Considered: #22581 (analytics-engine LIST/VALUES rejects types), #22475 (parseDouble script aggregation crash), #22673 (flag for persistent tasks during snapshot restore), #11882 (analyzers on non-text sub fields)
- Chosen: #22494, a performance enhancement to cache compiled regex automatons. The author filed it with PoC numbers, the search triage (sandeshkr419) engaged, it was updated 2026-08-05, and no PR exists.
- Why not the others: #22581 and #22673 are untriaged with zero maintainer engagement and no signal, #22475 author is actively digging into it, #11882 already has two volunteers in the thread.
- Status: recorded only, NO comment posted. Used only if both #6323 and #17561 fall through. Watch: the author holds a PoC and may submit a PR before we ever need it.

---

## Standing decisions (apply always)

- Publish everything: code and progress notes go to this public repo.
- Privacy: never write emails or other personal information in docs or commits. If one leaks in, scrub it from past history and force-push.
- Session data stays private: time-tracker.json and session-log.md live only on this machine.
