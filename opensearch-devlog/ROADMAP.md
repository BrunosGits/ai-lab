# OpenSearch contributions

*First PR · learning a large open source project* · Started 2026-08-07

Master plan for contributing to [OpenSearch](https://github.com/opensearch-project/OpenSearch).
The goal is to land real fixes through the issue-first, fork-based workflow and learn how a large
open source project actually works. Every change ships through a fork, a PR and maintainer review.

---

## Current track

- [x] Install Docker on the VPS for reproduction
- [x] Reproduce #6323 (strings over 2000 chars) on a recent OpenSearch
  - No truncation found on 2.3.0 or 2.19.6, swept 1980 to 20000 chars, all layers intact
  - Exact error message reproduced only via long string in a key position (dot expansion)
  - Findings posted in #6323, waiting on the reporter's original reindex script
- [x] Fix #17561 (inaccurate  error message)
  - Commit c135dc26 on fork branch fix/17561-codec-error-message
  - Unit tests green, e2e verified, pushed to BrunosGits/opensearch-fork
  - Waiting for maintainer review
- [ ] Fix #6323 (if maintainer confirms the field-name theory)
- [ ] Help #22654 (monitor mode workload group rejections)
  - Codecov gap identified: missing isPresent() == false test
  - Exact test code posted in PR comment
  - Waiting for author to apply and codecov to go green
  - Then request maintainer review
- [ ] Fallback to #22494 (cache compiled regex automatons) if #6323 and #17561 both fall through
  - Author pinged with questions, PoC exists, monitoring
  - Independent code path analysis complete
- [ ] Document WLM MONITOR mode (zero user-facing docs found)
- [ ] Fix local scroll bypass in TransportSearchScrollAction (MONITOR guard gap)

---

## Completed

- [x] Project scaffold (repo, journal, time tracker, project log, roadmap)
- [x] Docker on VPS for reproduction
- [x] #6323 minimal reproduction posted
- [x] #17561 fix implemented, tested, pushed
- [x] #22701 identified as duplicate of merged #22610, commented
- [x] #22654 codecov gap root-caused, test fix designed and posted
- [x] #22494 author pinged, code paths mapped
- [x] WLM integration test gaps documented
- [x] Local scroll bypass identified

---

## On hold / watching

- #21323 (Lucene stderr warnings) - PR #21359 stalled in review
- #22494 author PR (monitor and coordinate)
- #22654 author response (waiting for test fix application)
- #6323 maintainer response (waiting for confirmation)
- #17561 maintainer review
