# AI Lab Vault

> Structured knowledge base for the AI Lab project itself — infrastructure,
> the learning roadmap, ops runbooks, and the services/access map.
> (Not the subproject codebase vaults — those live in each `*-devlog/`.)

---

## 1. Overview

**Purpose:** Capture everything about operating and growing the AI Lab on the
OVHcloud VPS: how the infrastructure was built, what's being studied, how to
run and recover it, and where every service/credential lives.

**Entry points:**
- [[INDEX]] (this note) — map of the whole vault
- `../roadmap.md` — master plan: infra Phases 0–4 + 5-month learning roadmap
- `../rescue-drill.md` — rescue-mode runbook
- `../../journal.md` — the running journal
- `../../achievements.md` — GitHub achievements record

---

## 2. Sections

| Section | Path | Contents |
|---------|------|----------|
| Infrastructure | [[01-INFRASTRUCTURE/skeleton]] | Phases 0–4 knowledge, commands learned, firewall/stack layout |
| Learning Roadmap | [[02-LEARNING-ROADMAP/skeleton]] | Month 1–5 studies, model tooling, published artifacts |
| Ops / Runbooks | [[03-OPS/skeleton]] | Backup, rescue, docker, journal workflows |
| Services & Access | [[04-SERVICES-ACCESS/skeleton]] | Service matrix (names + Infisical paths only — no secrets) |

---

## 3. Conventions

- **INDEX first.** Start here; navigate deeper only when needed.
- **No secrets in this vault.** Store secret *locations* (Infisical paths, tool
  names), never token values, keys, passwords, IPs, or usernames.
- Use the templates in [[00-META/tags]] and `00-META/templates/` for new notes.
- This vault is committed to the `BrunosGits/ai-lab` repository as its backup —
  commit changes so the backup stays current.

**Legend:** 🟢 Complete · 🟡 In progress · 🔴 Not started
