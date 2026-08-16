# Journal

Personal diary of the OpenSearch contribution project: memories, feelings, stories.
One entry per day, newest first. This is not the session log (that's the private session log, kept local,
for times/commands/verdicts).

<p align=right><b>Total time on the project: 5h 40m</b></p>

---

## 2026-08-13

### Mood
Productive. Good rhythm between investigation and collaboration.

### Story
Worked on the opensearch contribution project. First, investigated PR #22701 (read block auto-release) — found it's a duplicate of already-merged #22610, posted a comment explaining this, and closed that path.

Then moved to PR #22654 (monitor mode workload group rejections). The PR fixes a bug where MONITOR mode workload groups were incorrectly rejecting requests with 429. The fix was correct but codecov/patch failed at 60% (target 80%).

Investigated deeply with subagents: confirmed the coverage gap (one missing branch isPresent() == false in rejectIfNeeded), designed a minimal test to cover it, ran 83 WLM tests on the VPS (all pass), generated a jacoco report proving the test flips line 274 to fully covered (80%, clearing the 71.43% auto target), and posted a humanized comment with the exact test code for the author.

Also discovered a bypass: local scroll requests skip both the transport interceptor and the listener, so MONITOR guard isn't hit there. And WLM has zero user-facing docs (two confusing monitor concepts). Filed those as follow-ups.

Waited for author response on the test fix.

### What I learned
Codecov patch target is auto-derived from project baseline (71.43% here), not a fixed 80%. Jacoco pc (partially covered) on a line with || means operand short-circuit, not a real bug. The WLM monitor terminology is overloaded: WlmMode.MONITOR_ONLY (cluster default) vs ResiliencyMode.MONITOR (group setting) — users can't discover this without docs. Subagent parallel investigation is powerful for covering multiple angles fast.

### Feelings / notes
Good session. The investigation-to-action loop worked: find gap, design fix, verify locally, comment with exact code. The author (SaiManas2106) has been responsive on their other PRs, so likely they'll apply the test and get green.

### Did
Analyzed PR #22701, confirmed duplicate of #22610, posted comment. Analyzed PR #22654, root-caused codecov 60% gap. Ran 83 WLM unit tests on VPS (all pass). Generated jacoco coverage report, verified 4/5 lines = 80%. Drafted and posted humanized PR comment with exact test fix. Investigated integration test gaps, interceptor bypass, cancellation consistency, doc gaps, related issues. Restored VPS checkout to clean state.

---

## 2026-08-13: Issue updates and fixes committed

**Mood:** focused, satisfied with the double progress

**Story:** Today two tracked issues moved forward. For #6323 I posted a minimal reproduction using the reporter's exact string: the 138-char dotted key fails identically via direct PUT and painless reindex promotion, and short keys like .start and a..b fail the same way — confirming the error is structural (dot expansion), not value truncation at ~2000 chars. For #17561 I committed the fix to the fork and built a distribution node that now lists the full accepted codec set (lucene_default + all registered Lucene codecs + built-ins) instead of the old hardcoded [default, lz4, best_compression, zlib]. The end-to-end test confirmed not_a_codec returns the full list and best_compression still succeeds. Both issues have comment threads on GitHub.

On the planning side I mapped the code paths and competitive landscape for #22494 (cache compiled regex automatons). The author ZiwenWan has a production-tested PoC with strong latency numbers and is happy to contribute a PR, so the approach is to monitor and coordinate rather than duplicate effort. The code analysis showed the exact call sites (RegexpQuery, AutomatonQuery, KeywordFieldMapper) and the cache infrastructure API to use.

**What I learned:** Two issues can advance in parallel when one is a field-name theory and the other a setting-derivation fix. And a working PoC from a third party changes the calculus on a fallback issue — the plan shifts from implement independently to monitor and coordinate.

**Feelings / notes:** Good to close out the session with concrete progress on the two main tracks and a clear path on the third.

**Did:** closed the time tracker, posted the #6323 minimal-reproduction comment, posted the #17561 update comment, committed and pushed the #17561 fix to BrunosGits/opensearch-fork, mapped the #22494 code paths and competitive landscape, and planned the next session.

---

## 2026-08-11: The fix that ran green

**Mood:** methodical, then proud of the first green run

**Story:** Morning, the #6323 reproduction. Two OpenSearch versions, 2.3.0 and 2.19.6, everything I could throw at the reindex API, strings from 1980 to 20000 chars, pipelines, remote reindex. Every value came back identical. The error the reporter saw comes from field-name validation, I reproduced it verbatim by putting a long string where a field name goes, the dots get read as object separators. The cutoff does not exist in vanilla OpenSearch.

Evening, the #17561 fix. The codec error message now comes from the same list the validation accepts, the five built-ins, every registered Lucene codec and the CodecAliases aliases, deduped and sorted. Two tests cover it. I ran EngineConfigTests on the VPS with JDK 21, six tests, zero failures, and posted the results asking for the green light.

Then a cleanup. The Mac's git identity was set to PublishProject, so three commits here and one on the expandir fork were attributed to that account. I rewrote the authorship to BrunosGits with git-filter-repo, force-pushed both and fixed the Mac identity.

**What I learned:** A negative result, written up carefully, is still progress. A fix only earns its place once it runs against the real codebase. A stale global git identity can misattribute commits for weeks.

**Feelings / notes:** The first green run on the real code was worth the ten minutes the 2-core build took. I have now made an OpenSearch change that compiles and passes.

**Did:** swept 2.3.0 and 2.19.6 for the #6323 cutoff, found nothing, pinned the error to field-name validation and posted the evidence. Implemented the #17561 fix with two tests, ran them green on the VPS and posted the results. Rewrote the PublishProject commits on this repo and the expandir fork, force-pushed both, fixed the Mac git identity.

---

## 2026-08-07: The project begins

**Mood:** eager, ready, humbled

**Story:** First day of a new project, this one about contributing to OpenSearch. The goal is to
learn how a large open source project actually works by doing the work: reading the code, finding
a real issue, sending a real patch.

The day had three parts. First the hunt for an issue. Almost everything I liked already had a PR
or a volunteer, which was the first lesson. I commented on #21323, the Lucene warning logs at
startup, thinking it was open, but a PR was already on it, stalled in review. Wasted words there.
Then I found #6323, a bug from 2023 where long strings get cut at 2000 characters, still broken,
no one working on it. The maintainer had been asking for a minimal reproduction for months. I
claimed it and promised the repro first.

Second, the environment. To reproduce #6323 I need to run OpenSearch, and the plan is Docker on
the VPS, installed later on demand. The VPS details stay out of this repo.

Third, since one issue is a single point of failure, I claimed a second one, #17561, a small bug
where the error message lists the wrong codec values. I also kept a third in my pocket, #22494,
cached regex automaton compilation, without commenting on it, in case both fall through.

**What I learned:** Small issues in OpenSearch get claimed within days. The ones left are deep,
like #6323, or untriaged with no one caring. To have a real chance I need to claim fast and be
ready to reproduce fast. I also learned to check for an existing PR before commenting, the
expensive way.

**Feelings / notes:** The humbling part is how fast things get taken. The good part is that two
maintainers have answered, which is more attention than I expected on the first day.

**Did:** set up the project scaffold for OpenSearch contributions, modeled on the AI Lab project.
Commented on #21323, later found redundant. Claimed #6323 and #17561 with coordination comments.
Recorded #22494 as plan B without commenting. Added check-issues for tracking.
