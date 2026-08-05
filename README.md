<p align="center">
  <img src="assets/icon-512.png" width="128" alt="AI Lab beaker icon"/>
</p>

# 🧪 AI Lab VPS

**Learning · Building · Publishing (GitHub + HF)**

A personal AI engineering laboratory on an OVHcloud VPS — the sandbox where I learn Linux administration, Docker, backend development and agentic AI by building real projects, each one published publicly as a portfolio.

## What's here

- `ai-lab-summary.md` — master plan: infrastructure Phases 0–4, a 5-month learning roadmap, backup strategy and a services/access matrix
- `assets/` — project beaker icon (SVG + PNG exports, favicon)
- `hello/` — FastAPI "hello" app, first run as a systemd unit (Phase 1.5), to be containerized in Phase 3
- `scripts/` — time tracker
- `print.css` + `ai-lab-summary.pdf` — printable PDF of the plan
- `session-log.md` — session journal

## Infrastructure status

| Phase | Status |
|---|---|
| 0 — Prep | ✅ complete |
| 1 — Server Foundation | ✅ complete (SSH hardening, UFW, edge firewall, Fail2Ban) |
| 1.5 — Systemd-first | ✅ mostly complete |
| 2 — Docker | ⏳ next |
| 3 — Slim Stack (Postgres 17 · Caddy · FastAPI) | pending |
| 4 — Backup & Resume (Backblaze B2) | pending |

## Philosophy

- **Systemd-first** — learn Linux before Docker
- **Slim stack** — only what's being studied now, nothing exposed but 80/443
- **Secrets in Infisical** — no `.env` on the server, no secrets in git
- **Publish everything** — code → GitHub, demos → Hugging Face, config → Infisical, data → encrypted backups

## License

[MIT](LICENSE) © 2026 Bruno Lima
