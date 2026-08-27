# Testcontainers Contribution Vault

## Structure
```
testcontainers-vault/
├── 00-META/
│   ├── templates/       # Templates for issues and PRs
│   └── standards/       # Standards reference
├── 01-ISSUES/           # Issue-specific analysis and implementation
│   ├── java-9876-debug-logging/
│   ├── rust-926-standard-label/
│   └── Architecture/    # Architecture study
├── 02-PR-TRACKING/      # PR tracking documents
├── 03-SESSION-LOGS/     # Daily session logs
├── 04-STANDARDS/        # Quick reference cards
├── 05-ARCHITECTURE/     # Architecture deep dives
│   ├── Architecture-INDEX-java.md
│   ├── Architecture-INDEX-rust.md
│   ├── Architecture-INDEX-python.md
│   ├── Features-INDEX.md
│   ├── Modules-INDEX.md
│   ├── Investigations-INDEX.md
│   └── diagrams/
│       ├── java-architecture.mmd
│       ├── rust-architecture.mmd
│       ├── python-architecture.mmd
│       ├── container-lifecycle.mmd
│       └── wait-strategies.mmd
├── scripts/             # Automation scripts
│   ├── generate-module-list-java.sh
│   ├── generate-module-list-rust.sh
│   ├── generate-module-list-python.sh
│   └── update-indexes.sh
├── diagrams/            # Mermaid diagrams
│   ├── java-architecture.mmd
│   ├── rust-architecture.mmd
│   ├── python-architecture.mmd
│   ├── container-lifecycle.mmd
│   └── wait-strategies.mmd
├── readme.md
└── roadmap.md
```

## Issues in Progress

| Issue | Repo | Language | Status | Vault Folder |
|---|---|---|---|---|
| [#9876](https://github.com/testcontainers/testcontainers-java/issues/9876) | testcontainers-java | Java | ✅ Done | `01-ISSUES/java-9876-debug-logging/` |
| [#926](https://github.com/testcontainers/testcontainers-rs/issues/926) | testcontainers-rs | Rust | ✅ Done | `01-ISSUES/rust-926-standard-label/` |

## Quick Links
- [Java Repo](https://github.com/testcontainers/testcontainers-java)
- [Rust Repo](https://github.com/testcontainers/testcontainers-rs)
- [Testcontainers Slack](https://slack.testcontainers.org)

## Standards Reference

| Language | Quick Ref | Full Refs | Fix Lessons |
|----------|-----------|-----------|-------------|
| Java | [04-STANDARDS/java-standards.md](../04-STANDARDS/java-standards.md) | [00-META/standards/java/](../00-META/standards/java/) | [fix-best-practices.md](../00-META/standards/java/fix-best-practices.md) |
| Rust | [04-STANDARDS/rust-standards.md](../04-STANDARDS/rust-standards.md) | [00-META/standards/rust/](../00-META/standards/rust/) | [fix-best-practices.md](../00-META/standards/rust/fix-best-practices.md) |
| Python | [04-STANDARDS/python-standards.md](../04-STANDARDS/python-standards.md) | [00-META/standards/python/](../00-META/standards/python/) | [fix-best-practices.md](../00-META/standards/python/fix-best-practices.md) |

## Architecture Reference

| Language | Architecture Index | Features | Modules | Investigations |
|----------|-------------------|----------|---------|----------------|
| Java | [Architecture-INDEX-java](../Architecture-INDEX-java.md) | [Features-INDEX](../Features-INDEX.md) | [Modules-INDEX](../Modules-INDEX.md) | [Investigations-INDEX](../Investigations-INDEX.md) |
| Rust | [Architecture-INDEX-rust](../Architecture-INDEX-rust.md) | [Features-INDEX](../Features-INDEX.md) | [Modules-INDEX](../Modules-INDEX.md) | [Investigations-INDEX](../Investigations-INDEX.md) |
| Python | [Architecture-INDEX-python](../Architecture-INDEX-python.md) | [Features-INDEX](../Features-INDEX.md) | [Modules-INDEX](../Modules-INDEX.md) | [Investigations-INDEX](../Investigations-INDEX.md) |

## Quick Links
- [Java Repo](https://github.com/testcontainers/testcontainers-java)
- [Rust Repo](https://github.com/testcontainers/testcontainers-rs)
- [Python Repo](https://github.com/testcontainers/testcontainers-python)
- [Testcontainers Slack](https://slack.testcontainers.org)
- [Testcontainers Website](https://testcontainers.com)