# Testcontainers Contribution Vault

## Structure
```
testcontainers-vault/
├── 00-META/
│   ├── templates/       # Templates for issues and PRs
│   └── standards/       # Standards reference
├── 01-ISSUES/           # Issue-specific analysis and implementation
├── 02-PR-TRACKING/      # PR tracking documents
├── 03-SESSION-LOGS/     # Daily session logs
├── 04-STANDARDS/        # Quick reference cards
├── readme.md
└── roadmap.md
```

## Current Work (2026-08-25)
- ✅ **Java #9876**: Debug logging lazy evaluation — Implementation complete, tests passing
- ✅ **Rust #926**: Add org.testcontainers=true label — Implementation complete, tests passing

## Quick Links
- [Java Fork](https://github.com/BrunosGits/testcontainers-java) | [Upstream](https://github.com/testcontainers/testcontainers-java)
- [Rust Fork](https://github.com/BrunosGits/testcontainers-rs) | [Upstream](https://github.com/testcontainers/testcontainers-rs)
- [Testcontainers Slack](https://slack.testcontainers.org)
- [Testcontainers Website](https://testcontainers.com)

## Standards Reference

| Language | Quick Ref | Full Refs | Fix Lessons |
|----------|-----------|-----------|-------------|
| Java | [04-STANDARDS/java-standards.md](04-STANDARDS/java-standards.md) | [00-META/standards/java/](00-META/standards/java/) | [fix-best-practices.md](00-META/standards/java/fix-best-practices.md) |
| Rust | [04-STANDARDS/rust-standards.md](04-STANDARDS/rust-standards.md) | [00-META/standards/rust/](00-META/standards/rust/) | [fix-best-practices.md](00-META/standards/rust/fix-best-practices.md) |
| Python | [04-STANDARDS/python-standards.md](04-STANDARDS/python-standards.md) | [00-META/standards/python/](00-META/standards/python/) | [fix-best-practices.md](00-META/standards/python/fix-best-practices.md) |

## VPS Development Environment
- Path: `/home/bruno/ai-lab/`
- Java 21, Rust 1.85, Docker 29.7.2
- Repos: `/home/bruno/ai-lab/testcontainers-java`, `/home/bruno/ai-lab/testcontainers-rs`