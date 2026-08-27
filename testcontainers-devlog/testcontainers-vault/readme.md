<p align="center">
  <img src="../../assets/icon-512.png" width="96" alt="Testcontainers beaker icon"/>
</p>

# 🧪 Testcontainers Vault

**Issue Analysis · Implementation Logs · PR Tracking · Session Journal · Architecture Study**

An Obsidian vault documenting every Testcontainers contribution. Each issue gets a complete trail: analysis → implementation → tests → PR → review.

## Structure
```
testcontainers-vault/
├── 00-META/
│   ├── templates/       # pr-log.md, issue-analysis.md, session-log.md
│   └── standards/       # Standards reference
├── 01-ISSUES/
│   ├── java-9876-debug-logging/
│   ├── rust-926-standard-label/
│   └── Architecture/
│       ├── Container-Lifecycle/
│       ├── Wait-Strategies/
│       ├── Networking/
│       ├── Resource-Reaper/
│       └── Reusable-Containers/
├── 02-PR-TRACKING/
├── 03-SESSION-LOGS/
├── 04-STANDARDS/        # Quick reference cards
├── 05-ARCHITECTURE/     # Architecture deep dives (new)
│   ├── Architecture-INDEX-java.md
│   ├── Architecture-INDEX-rust.md
│   ├── Architecture-INDEX-python.md
│   ├── Features-INDEX.md
│   ├── Modules-INDEX.md
│   └── Investigations-INDEX.md
├── diagrams/            # Mermaid diagrams (new)
├── scripts/             # Automation scripts (new)
├── readme.md
└── roadmap.md
```

## Issues In Progress

| Issue | Repo | Language | Status | Vault Folder |
|---|---|---|---|---|
| [#9876](https://github.com/testcontainers/testcontainers-java/issues/9876) | testcontainers-java | Java | ✅ Done | `01-ISSUES/java-9876-debug-logging/` |
| [#926](https://github.com/testcontainers/testcontainers-rs/issues/926) | testcontainers-rs | Rust | ✅ Done | `01-ISSUES/rust-926-standard-label/` |

## Quick Commands

```bash
# View vault on VPS
cd /home/bruno/ai-lab/testcontainers-devlog/testcontainers-vault

# Create new issue folder
mkdir -p 01-ISSUES/<repo>-<issue>/{analysis,implementation,test-results}.md

# Create PR tracking
cp 00-META/templates/pr-log.md 02-PR-TRACKING/PR-<repo>-<issue>.md
```

## Standards Reference

Quick reference cards for each language's contribution standards:

- [Java Standards](04-STANDARDS/java-standards.md)
- [Rust Standards](04-STANDARDS/rust-standards.md)
- [Python Standards](04-STANDARDS/python-standards.md)

Full references and PR #11982 lessons learned in `00-META/standards/`.

## Architecture Study

Deep-dive architecture analysis for all three implementations:

- [Architecture-INDEX-java](Architecture-INDEX-java.md) — Java (Gradle, 60+ modules)
- [Architecture-INDEX-rust](Architecture-INDEX-rust.md) — Rust (Cargo, tokio, bollard)
- [Architecture-INDEX-python](Architecture-INDEX-python.md) — Python (uv + Make, MkDocs)

Cross-language feature analysis:
- [Features-INDEX](Features-INDEX.md) — Container lifecycle, wait strategies, networking, etc.
- [Modules-INDEX](Modules-INDEX.md) — Module catalog comparison
- [Investigations-INDEX](Investigations-INDEX.md) — Investigation progress tracking

## Philosophy
- **One issue = one folder** — complete traceability
- **Template-driven** — consistent structure across issues
- **VPS-verified** — all test results from actual VPS runs
- **Cross-linked** — session logs → issues → PRs → roadmap
- **Multi-language** — Java, Rust, Python with cross-references