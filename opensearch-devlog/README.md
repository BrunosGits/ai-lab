# OpenSearch Contributions

A record of my journey contributing to OpenSearch: understanding the codebase,
finding issues, sending patches and learning how a large open source project
actually works.

## Progress so far

Active contribution tracks, newest first:

- **✅ #22676** LATE_MATERIALIZATION profile metrics (analytics engine): **Merged 2026-08-31** — Reviewed PR, identified wire BWC guard violation, static test provisioning flag, shard label uniqueness. Merged by mch2.
- **#22654** MONITOR mode workload group rejections (helping): Confirmed a duplicate PR was already merged (#22610), root-caused a 60% codecov gap to a missing branch in `rejectIfNeeded` (line 274: missing `isPresent() == false` check), designed and shared a coverage test that the author applied, codecov now green at 80%, awaiting maintainer review.
- **#17561** Inaccurate codec error message: Root cause is a hardcoded list in the error message, fix derives the message from the accepted codec list (built-ins + registered Lucene codecs + aliases, deduped + sorted). Two tests cover it, e2e verified via `EngineConfigTests`, commit `c135dc26` pushed to the fork, awaiting maintainer review.
- **#6323** Long strings cut at 2000 characters: Reproduced on 2.3.0 and 2.19.6, swept 1980 to 20000 chars across pipelines and remote reindex, no truncation exists, minimal repro posted, awaiting maintainer confirmation of the field-name theory.
- **#22494** Regex automaton cache: Code paths mapped (`RegexpQuery`, `AutomatonQuery`, `KeywordFieldMapper` + cache API), coordinating with the author who has a production-tested PoC, do not duplicate.
- **#21323** Lucene stderr warnings: Watching a stalled PR, monitor only.

## Environment & Testing Strategy

Reproduction and testing run on the VPS with Docker installed on demand. The validation strategy employs:

| Test Dimension | Options/Details | Specific Approach |
|----------------|-----------------|-------------------|
| **Environment** | VPS + Docker on demand | Containers for isolation, host for development |
| **Build System** | JDK 21 + Gradle | `:server:test`, `:test:framework:test` targets |
| **Validation** | Unit tests ∥ Coverage ∥ e2e | jacoco reports, codecov (≥71.43% baseline), manual verification |
| **Reproduction** | Docker containers ∥ Version sweep | 2.3.0 & 2.19.6, string lengths 1980-20000 chars |
| **Git Hygiene** | filter-repo ∥ force push | Author identity cleanup, history rewriting |

### Key Validation Practices
- **Unit Testing**: `./gradlew :server:test --tests "<FQCN>"` for targeted validation (e.g., `./gradlew :test:framework:test --tests "WLMTests"`)
- **Coverage Analysis**: jacoco reports identify `pc` (partially covered) vs true gaps; short-circuit `||` lines marked as `pc` are not real bugs
- **Codecov**: Patch target auto-derived from project baseline (71.43%), not a fixed threshold
- **Reproduction**: Docker containers with `docker run`/`docker compose` for issue isolation across versions
- **Version Testing**: Sweep across 2.3.0 and 2.19.6 to validate regression ranges and fix validity
- **Git Coordination**: `gh` CLI for issue/PR comments (`gh issue comment <n> --body <msg>`), fork creation (`gh repo fork <repo> --clone=false`), CI monitoring (`gh run watch <id>`)
- **Smoke Testing**: Service startup/shutdown cycles, basic cluster formation and indexing validation

## How to check the tracked issues

Run `/check-issues` at the start of a session to see the state, labels and
latest comment on each tracked issue.

Example command sequence:
```
# Check all tracked issues
/check-issues

# For specific PR investigation
gh pr view <NUMBER> --repo <OWNER>/<REPO>
gh issue view <NUMBER> --repo <OWNER>/<REPO>

# Local validation after fix
./gradlew :server:test --tests "<TestClass>"
./gradlew jacocoTestReport
```

## License

MIT
