# Testcontainers Codebase Study Index

> A structured study of the testcontainers codebases across Java, Rust, and Python.

---

## 1. Study Overview

**Purpose:** Understand how the testcontainers codebases work across three languages, from repository structure to runtime behavior and individual features.

**Projects:**
- [testcontainers-java](https://github.com/testcontainers/testcontainers-java) — 8.7k★
- [testcontainers-rs](https://github.com/testcontainers/testcontainers-rs) — 1.1k★
- [testcontainers-python](https://github.com/testcontainers/testcontainers-python) — 2.3k★

**Primary Questions:**
- How is each codebase structured?
- How do the major systems interact?
- How does container lifecycle work?
- How do wait strategies work?
- How does networking and resource management work?
- Which architectural patterns are used?
- What are the important differences between the implementations?

---

## 2. Start Here

### Architecture Deep Dives
- [[Architecture-INDEX-java]] — Java implementation (Gradle, 60+ modules)
- [[Architecture-INDEX-rust]] — Rust implementation (Cargo workspace, core crate)
- [[Architecture-INDEX-python]] — Python implementation (uv + Make, uv package manager)

### Cross-Language Feature Analysis
- [[Features-INDEX]] — Container lifecycle, wait strategies, networking, logging, resource reaper, reusable containers

### Module Catalog
- [[Modules-INDEX]] — Cross-language module comparison (databases, queues, cloud, etc.)

### Investigations
- [[Investigations-INDEX]] — Progress tracking for deep dives

---

## 3. Architecture

- [[Architecture-INDEX-java]] — Java (Gradle, 60+ modules, SLF4J, JUnit)
- [[Architecture-INDEX-rust]] — Rust (Cargo workspace, tokio, bollard)
- [[Architecture-INDEX-python]] — Python (uv + Make, MkDocs, release-please)

---

## 4. Feature Investigations

| Feature | Java | Rust | Python | Status |
|---------|------|------|--------|--------|
| Container Lifecycle | [[Container-Lifecycle/analysis]] | [[Container-Lifecycle/analysis]] | [[Container-Lifecycle/analysis]] | 🟡 In Progress |
| Wait Strategies | [[Wait-Strategies/analysis]] | [[Wait-Strategies/analysis]] | [[Wait-Strategies/analysis]] | 🟡 In Progress |
| Networking | [[Networking/analysis]] | [[Networking/analysis]] | [[Networking/analysis]] | 🟡 In Progress |
| Resource Reaper | [[Resource-Reaper/analysis]] | [[Resource-Reaper/analysis]] | [[Resource-Reaper/analysis]] | 🔴 Not Started |
| Reusable Containers | [[Reusable-Containers/analysis]] | [[Reusable-Containers/analysis]] | [[Reusable-Containers/analysis]] | 🔴 Not Started |

**Legend:** 🟢 Completed · 🟡 In Progress · 🔴 Not Started · ⚠️ Needs Verification

---

## 5. Module Catalog

- [[Modules-INDEX]] — Cross-language module comparison (60+ Java, core Rust, community Python)

---

## 6. Source Code References

When documenting code, always include:

- Repository
- File path
- Class/function
- Relevant line range
- Git commit when relevant

Example:
```
testcontainers-java/core/src/main/java/org/testcontainers/containers/GenericContainer.java
→ GenericContainer.start() [lines 320-380]
```

---

## 7. External References

- [[Testcontainers Slack](https://slack.testcontainers.org)]
- [[Java Docs](https://java.testcontainers.org)]
- [[Rust Docs](https://docs.rs/testcontainers)]
- [[Python Docs](https://testcontainers-python.readthedocs.io)]
- [[Java Contributing](https://java.testcontainers.org/contributing/)]
- [[Rust Contributing](https://github.com/testcontainers/testcontainers-rs/blob/main/CONTRIBUTING.md)]
- [[Python Contributing](https://github.com/testcontainers/testcontainers-python/blob/main/docs/contributing.md)]