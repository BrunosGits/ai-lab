<p align="center">
  <img src="../assets/icon-512.png" width="128" alt="AI Lab beaker icon"/>
</p>

# 🧪 AI Lab VPS

**Learning · Building · Publishing (GitHub + HF)**

A personal AI engineering laboratory on an OVHcloud VPS, the sandbox where I learn Linux administration, Docker, backend development and agentic AI by building real projects. Each one gets published publicly as a portfolio.

## What's here

- `roadmap.md` — master plan: infrastructure Phases 0–4, a 5-month learning roadmap, backup strategy and a services/access matrix
- `../journal.md` — personal journal, one entry per day
- `../achievements.md` — running record of GitHub achievements earned by this account
- `rescue-drill.md` — rescue-mode runbook (tested 2026-08-06)
- `../assets/` — project beaker icon (SVG + PNG exports, favicon)
- `../hello/` — FastAPI "hello" app (containerized in Phase 3)
- `../scripts/` — `backup.sh` (age-encrypted backups to Backblaze B2, nightly via systemd timer)
- `../.opencode/` — opencode config, including the `/end-session` command
- `../print.css` + `../ai-lab-summary.pdf` — printable PDF of the plan

## Infrastructure status

| Phase | Status |
|---|---|
| 0 — Prep | ✅ complete |
| 1 — Server Foundation | ✅ complete (SSH hardening, UFW, edge firewall, Fail2Ban) |
| 1.5 — Systemd-first | ✅ mostly complete |
| 2 — Docker | ✅ complete |
| 3 — Slim Stack (Postgres 17 · Caddy · FastAPI) | ✅ complete |
| 4 — Backup & Resume (Backblaze B2) | ✅ complete |

## Philosophy

- **Systemd-first** — learn Linux before Docker
- **Slim stack** — only what's being studied now, nothing exposed but 80/443
- **Secrets in Infisical** — no `.env` on the server, no secrets in git
- **Publish everything** — code → GitHub, demos → Hugging Face, config → Infisical, data → encrypted backups

## License

[MIT](../LICENSE) © 2026 Bruno Lima
