# Investigations Index — Progress Tracking

> Tracking deep-dive investigations across Java, Rust, and Python testcontainers codebases.

---

## 1. Progress Overview

| Investigation | Java | Rust | Python | Status | Updated |
|---------------|------|------|--------|--------|---------|
| Container Lifecycle | 🟡 | 🟡 | 🟡 | In Progress | 2026-08-26 |
| Wait Strategies | 🟡 | 🟡 | 🟡 | In Progress | 2026-08-26 |
| Networking | 🟡 | 🟡 | 🟡 | In Progress | 2026-08-26 |
| Resource Reaper | 🔴 | 🔴 | 🔴 | Not Started | — |
| Reusable Containers | 🔴 | 🔴 | 🔴 | Not Started | — |

**Legend:** 🟢 Completed · 🟡 In Progress · 🔴 Not Started · ⚠️ Needs Verification

---

## 2. By Feature Area

### Container Lifecycle
- **Analysis:** [[Container-Lifecycle/analysis]]
- **Implementation:** [[Container-Lifecycle/implementation]]
- **Comparison:** [[Container-Lifecycle/comparison]]
- **Status:** 🟡 In Progress (all three languages)

### Wait Strategies
- **Analysis:** [[Wait-Strategies/analysis]]
- **Comparison:** [[Wait-Strategies/comparison]]
- **Status:** 🟡 In Progress

### Networking
- **Analysis:** [[Networking/analysis]]
- **Status:** 🟡 In Progress

### Resource Reaper (Ryuk)
- **Analysis:** [[Resource-Reaper/analysis]]
- **Status:** 🔴 Not Started

### Reusable Containers
- **Analysis:** [[Reusable-Containers/analysis]]
- **Status:** 🔴 Not Started

---

## 3. By Language

### Java
| Investigation | Status | Notes |
|---------------|--------|-------|
| Container Lifecycle | 🟡 | `GenericContainer.start()`, `tryStart()`, `ResourceReaper` |
| Wait Strategies | 🟡 | `WaitStrategy` interface, 8+ implementations |
| Networking | 🟡 | `Network` class, port binding |
| Resource Reaper | 🔴 | `ResourceReaper` + Ryuk |
| Reusable Containers | 🔴 | `withReuse(true)` |

### Rust
| Investigation | Status | Notes |
|---------------|--------|-------|
| Container Lifecycle | 🟡 | `ContainerAsync`, `AsyncRunner`, `SyncRunner` |
| Wait Strategies | 🟡 | `WaitFor` enum with 7 variants |
| Networking | 🟡 | `Network`, port mapping |
| Resource Reaper | 🔴 | Ryuk integration |
| Reusable Containers | 🔴 | `ReuseDirective` |

### Python
| Investigation | Status | Notes |
|---------------|--------|-------|
| Container Lifecycle | 🟡 | `Container.start()`, `DockerClient` |
| Wait Strategies | 🟡 | `WaitStrategy` base class |
| Networking | 🟡 | `Network`, port binding |
| Resource Reaper | 🔴 | Ryuk integration |
| Reusable Containers | 🔴 | `reuse=True` |

---

## 4. Investigation Progress Tracker

| Investigation | Phase | Java | Rust | Python | Target Date |
|---------------|-------|------|------|--------|-------------|
| Container Lifecycle | Analysis | 🟡 | 🟡 | 🟡 | 2026-08-30 |
| Container Lifecycle | Implementation | 🔴 | 🔴 | 🔴 | 2026-09-05 |
| Container Lifecycle | Comparison | 🔴 | 🔴 | 🔴 | 2026-09-10 |
| Wait Strategies | Analysis | 🟡 | 🟡 | 🟡 | 2026-08-30 |
| Wait Strategies | Comparison | 🔴 | 🔴 | 🔴 | 2026-09-05 |
| Networking | Analysis | 🟡 | 🟡 | 🟡 | 2026-09-10 |
| Resource Reaper | Analysis | 🔴 | 🔴 | 🔴 | 2026-09-15 |
| Reusable Containers | Analysis | 🔴 | 🔴 | 🔴 | 2026-09-15 |

---

## 5. Quick Links

- **Analysis Files:** `01-ISSUES/Architecture/`
- **Implementation Files:** `01-ISSUES/Architecture/*/implementation.md`
- **Comparison Files:** `01-ISSUES/Architecture/*/comparison.md`

### Quick Navigation
- [[Container-Lifecycle/analysis]]
- [[Container-Lifecycle/implementation]]
- [[Container-Lifecycle/comparison]]
- [[Wait-Strategies/analysis]]
- [[Wait-Strategies/comparison]]
- [[Networking/analysis]]
- [[Resource-Reaper/analysis]]
- [[Reusable-Containers/analysis]]