# 🧪 Testcontainers Vault Roadmap

*Issue tracking · Implementation logs · PR management · Architecture Study* · Started 2026-08-25

Master plan for the Testcontainers contribution vault. Mirrors the main `testcontainers-devlog/roadmap.md` but focused on vault organization and issue lifecycle.

---

## 📦 Vault Phases

### Phase 0 — Vault Initialization

- [x] Create folder structure (`00-META`, `01-ISSUES`, `02-PR-TRACKING`, `03-SESSION-LOGS`)
- [x] Create templates: `pr-log.md`, `issue-analysis.md`
- [x] Create index.md with quick links
- [x] Document first two issues (#9876 Java, #926 Rust)

### Phase 0.5 — Standards Documentation

- [x] Add Java quick reference card
- [x] Add Rust quick reference card
- [x] Add Python quick reference card
- [x] Copy full contributing guides to `00-META/standards/`
- [x] Document PR #11982 lessons learned (`fix-best-practices.md`)

### Phase 1 — First Issue Cycles

#### Java #9876 — Debug Logging Lazy Evaluation

- [x] `analysis.md` — Root cause, SLF4J 1.7 constraints, fix strategy
- [x] `implementation.md` — 3-line change in GenericContainer.java
- [x] `test-results.md` — Compile + GenericContainer + WaitStrategy tests pass
- [ ] `PR-java-9876.md` — PR link, review notes, merge status

#### Rust #926 — Add org.testcontainers=true Label

- [x] `analysis.md` — Ecosystem inconsistency, label injection point
- [x] `implementation.md` — 2 files: request.rs + async_runner.rs test update
- [x] `test-results.md` — fmt, clippy, 85 tests pass (1 pre-existing fail)
- [ ] `PR-rust-926.md` — PR link, review notes, merge status

### Phase 2 — Architecture Study (New)

#### Architecture Documentation

- [x] Architecture-INDEX-java.md — Java (Gradle, 60+ modules, SLF4J, JUnit)
- [x] Architecture-INDEX-rust.md — Rust (Cargo, tokio, bollard)
- [x] Architecture-INDEX-python.md — Python (uv + Make, MkDocs, release-please)
- [x] Features-INDEX.md — Cross-language feature comparison
- [x] Modules-INDEX.md — Module catalog comparison
- [x] Investigations-INDEX.md — Progress tracking

#### Mermaid Diagrams

- [x] java-architecture.mmd
- [x] rust-architecture.mmd
- [x] python-architecture.mmd
- [x] container-lifecycle.mmd
- [x] wait-strategies.mmd

#### Automation Scripts

- [x] generate-module-list-java.sh
- [x] generate-module-list-rust.sh
- [x] generate-module-list-python.sh
- [x] update-indexes.sh

#### Investigation Files

- [x] Container Lifecycle — analysis.md, implementation.md, comparison.md
- [x] Wait Strategies — analysis.md, comparison.md
- [x] Networking — analysis.md
- [x] Resource Reaper — analysis.md
- [x] Reusable Containers — analysis.md

### Phase 3 — Template Refinement

- [ ] Add `session-log.md` template with VPS command references
- [ ] Add cross-reference tags (issue ↔ PR ↔ session)
- [ ] Create `04-DECISIONS/` for architectural choices
- [ ] Add `05-REFERENCES/` for upstream docs, Slack threads, related PRs

### Phase 4 — Scale to Multi-Language

- [ ] Add Go issue folder template
- [ ] Add Python issue folder template
- [ ] Create language-specific test command references
- [ ] Document cross-language patterns (labels, wait strategies, reusable containers)

### Phase 5 — Knowledge Synthesis

- [ ] Generate "Patterns Learned" document from completed issues
- [ ] Create contribution checklist for new contributors
- [ ] Export vault as PDF/HTML for portfolio
- [ ] Link to HF Space demo (if built)

---

## 📚 Issue Lifecycle — every issue follows this path

```
01-ISSUES/<repo>-<issue>/
├── analysis.md        # Problem, root cause, proposed fix, files to change
├── implementation.md  # Exact changes, code snippets, rationale
└── test-results.md    # Commands run, output, pass/fail, screenshots

02-PR-TRACKING/PR-<repo>-<issue>.md
└── PR link, status, review notes, merge date

03-SSESSION-LOGS/YYYY-MM-DD-<slug>.md
└── Daily log linking to issues worked on
```

---

## 🔄 Vault Update Loop — repeat per issue

```
New Issue → Create folder → Fill analysis.md → Implement → Test on VPS
    → Fill implementation.md + test-results.md → Create PR → Fill PR tracking
    → Log session → Update vault roadmap → Update main roadmap
```

---

## 🗄️ Cross-References

| Vault Doc | Main Roadmap | GitHub |
|---|---|---|
| `01-ISSUES/java-9876/analysis.md` | Phase 1 Java | #9876 |
| `01-ISSUES/rust-926/analysis.md` | Phase 1 Rust | #926 |
| `01-ISSUES/Architecture/Container-Lifecycle/analysis.md` | Phase 2 | — |
| `01-ISSUES/Architecture/Wait-Strategies/analysis.md` | Phase 2 | — |
| `02-PR-TRACKING/PR-java-9876.md` | Phase 1 Java | PR link |
| `02-PR-TRACKING/PR-rust-926.md` | Phase 1 Rust | PR link |
| `03-SESSION-LOGS/2026-08-25-*.md` | Month 1 | — |

---

## 📋 Templates (in `00-META/templates/`)

### `issue-analysis.md`

```markdown
# Issue Analysis: <Title>

## Issue Reference
- **Issue**: #<number>
- **Repository**: <repo>
- **Link**: <URL>
- **Type**: Bug / Enhancement / Good First Issue

## Problem Statement
...

## Root Cause Analysis
...

## Proposed Solution
...

## Files to Modify
...

## Testing Strategy
...

## Risks / Considerations
...
```

### `pr-log.md`

```markdown
# PR Log: <Title>

## PR Information
- **Issue**: #<number>
- **Repository**: <repo>
- **PR Link**: <URL>
- **Status**: Draft / Open / Merged / Closed
- **Created**: YYYY-MM-DD
- **Merged**: YYYY-MM-DD

## Changes Summary
- ...

## Testing
- [ ] Format check passed
- [ ] All tests passed
- [ ] Manual verification done

## Review Notes
...

## Related
- Issue: #
- Discussion:
```

### `session-log.md`

```markdown
# Session Log: YYYY-MM-DD

## Date
YYYY-MM-DD

## Issues Worked On
1. **<Repo> #<Issue>** - <Brief description>
2. ...

## Summary
...

## Commands Run (VPS)
```bash
# ...
```

## Next Steps
- ...
```