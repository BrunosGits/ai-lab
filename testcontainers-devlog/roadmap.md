# 🧪 Testcontainers Contribution Lab

*Learning · Contributing · Publishing (GitHub + HF)* · Started 2026-08-25

This document is the master plan for a personal Testcontainers contribution laboratory hosted on the AI Lab VPS (OVHcloud). The goal is to learn multi-language open source development (Java, Rust, Go, Python) by contributing real fixes to the Testcontainers project family, publishing each contribution as a PR and documenting the journey in an Obsidian vault.

---

## 📦 Contribution Phases

### Phase 0 — Environment Setup

- [x] VPS ready: Java 21, Rust 1.85, Docker 29.7.2
- [x] Fork testcontainers-java → `BrunosGits/testcontainers-java`
- [x] Fork testcontainers-rs → `BrunosGits/testcontainers-rs`
- [x] Clone forks on VPS at `/home/bruno/ai-lab/`
- [x] Create Obsidian vault at `testcontainers-devlog/testcontainers-vault/`
- [x] Install formatting tools: `npm` (for Gradle spotless), `rustup nightly + rustfmt + clippy`

### Phase 1 — First Contributions (Good First Issues)

#### Java #9876 — Debug Logging Lazy Evaluation
- [x] **Analyze**: Root cause — `logger()` calls `getDockerImageName()` triggering ECR resolution even when debug disabled
- [x] **Implement**: Change `logger()` to constant name, add `isDebugEnabled()` guards in `doStart()` and `tryStart()`
- [x] **Test**: `./gradlew :testcontainers:compileJava` + GenericContainer/WaitStrategy tests pass
- [ ] **PR**: Open PR to `testcontainers/testcontainers-java` with fix
- [ ] **Review**: Address maintainer feedback

#### Rust #926 — Add org.testcontainers=true Label
- [x] **Analyze**: Only `org.testcontainers.managed-by=testcontainers` added, missing standard `org.testcontainers=true`
- [x] **Implement**: Add label in `ContainerRequest::from()`, update test expectation
- [x] **Test**: `cargo +nightly fmt --all -- --check`, `cargo clippy`, `cargo test --features blocking` (85 passed)
- [ ] **PR**: Open PR to `testcontainers/testcontainers-rs` with fix
- [ ] **Review**: Address maintainer feedback

### Phase 2 — Expand to Other Languages

#### Go — Equivalent Label Consistency
- [ ] Fork testcontainers/testcontainers-go
- [ ] Find label implementation in Go codebase
- [ ] Add `org.testcontainers=true` default label
- [ ] Test and PR

#### Python — Equivalent Label Consistency
- [ ] Fork testcontainers/testcontainers-python
- [ ] Find label implementation in Python codebase
- [ ] Add `org.testcontainers=true` default label
- [ ] Test and PR

### Phase 3 — Module Contributions

- [ ] Identify missing database/module containers across languages
- [ ] Follow Testcontainers new module checklist (default image, deps, API, docs)
- [ ] Implement incubating modules (3-month evaluation)
- [ ] Cross-language module parity

### Phase 4 — Ecosystem Leadership

- [ ] Join Testcontainers Slack, participate in discussions
- [ ] Review other contributors' PRs
- [ ] Mentor new contributors
- [ ] Propose and implement cross-language improvements

---

## 📚 Learning Roadmap — every contribution ends with a PUBLISH step

### Month 1 (Aug 2026) — Java + Rust Basics

- **Study:** Testcontainers architecture, SLF4J logging, Rust async/tokio, Bollard Docker client
- **Contribute:** #9876 (Java), #926 (Rust)
- **Publish:** 2 PRs + vault entries + session log
- [x] Java: SLF4J 1.7 lazy logging patterns (`isDebugEnabled()` guard)
- [x] Rust: BTreeMap labels, async test patterns, cargo workspace
- [ ] Repo flipped public when PRs polished

### Month 2 (Sep 2026) — Go + Python Parity

- **Study:** Go testcontainers, Python testcontainers, cross-language label patterns
- **Contribute:** Label consistency in Go and Python
- **Publish:** 2 PRs + vault entries
- [ ] Go: Find label injection point in Go runner
- [ ] Python: Find label injection point in Python runner

### Month 3 (Oct 2026) — Module Deep Dive

- **Study:** Module checklist, incubating policy, wait strategies, reusable containers
- **Contribute:** New module or module improvement
- **Publish:** Module PR + detailed analysis
- [ ] Pick a missing database (e.g., TiDB, QuestDB, Pinecone)
- [ ] Implement across 2+ languages

### Month 4 (Nov 2026) — Advanced Patterns

- [ ] Reusable containers across languages
- [ ] Testcontainers Desktop integration
- [ ] Ryuk/moby-ryuk cleanup patterns
- [ ] CI/CD for testcontainers forks

### Month 5 (Dec 2026) — Portfolio Polish

- [ ] All PRs merged or well-documented
- [ ] Vault comprehensive (issues, implementations, sessions)
- [ ] HF Space demo: "Testcontainers Label Checker" (multi-language)
- [ ] GitHub profile: 5+ Testcontainers PRs merged
- [ ] Blog post: "Cross-language Testcontainers Patterns"

---

## 🔄 Publish Loop (the habit) — repeat every contribution

```
Analyze → Implement → Test (VPS) → Document (Vault) → PR → Review → Merge
                                    │
                                    └─ Vault: analysis.md + implementation.md + test-results.md
                                    └─ Session: YYYY-MM-DD-issue.md
                                    └─ PR Tracking: PR-<repo>-<issue>.md
```

---

## 🗄️ Vault Structure — 3 Layers

| Layer | Location | Purpose |
|---|---|---|
| **Templates** | `00-META/templates/` | Reusable templates for issues, PRs, sessions |
| **Issues** | `01-ISSUES/<repo>-<issue>/` | Analysis, implementation, test results per issue |
| **PRs** | `02-PR-TRACKING/` | PR status, review notes, merge timeline |
| **Sessions** | `03-SESSION-LOGS/` | Daily logs linking to issues/PRs |

---

## 🔐 Services & Access

| Service | Account | Purpose | Key Location |
|---|---|---|---|
| **GitHub** | `BrunosGits` | Fork management, PR creation | `~/.ssh/id_ed25519_github` |
| **VPS (SSH)** | `bruno` | Build, test, Docker | `~/.ssh/id_ed25519` |
| **Docker Hub** | — | Test image pulls | Not needed (public images) |
| **Testcontainers Slack** | `bruno.lima` | Community discussion | Browser |
| **Infisical** | AI Lab project | Secrets (if needed) | `infisical` CLI |

---

## 💻 Machine Config — OVHcloud VPS-1 (shared with AI Lab)

| | |
|---|---|
| **Provider** | OVHcloud VPS-1 2027 |
| **Plan** | VPS Local Storage |
| **CPU** | 2 vCPU |
| **RAM** | 4 GB |
| **Disk** | 40 GB SSD |
| **OS** | Debian 13 (Trixie) |
| **Java** | 21 (Temurin via SDKMAN or apt) |
| **Rust** | 1.85 stable + nightly (rustup) |
| **Docker** | 29.7.2 (official repo) |
| **Gradle** | Wrapper (`./gradlew`) |

---

## 💰 Project Costs

| Item | Cost |
|---|---|
| OVH VPS-1 (shared) | 4.49 €/month |
| Domain (optional) | ~$10/yr |
| **Total** | 4.49 €/month |
