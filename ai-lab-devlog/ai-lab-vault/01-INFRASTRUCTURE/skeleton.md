# Infrastructure

> Knowledge base for the AI Lab infrastructure (Phases 0–4). Deep-dive notes
> live here; the master plan lives in `../roadmap.md`.

## Overview

The AI Lab runs on an OVHcloud VPS (Debian 13). Work was built in phases:
0 (prep), 1 (server foundation + hardening), 1.5 (systemd-first),
2 (Docker), 3 (slim stack: Postgres 17 · Caddy · FastAPI), 4 (backup & resume).

## Areas to document

- [[01-INFRASTRUCTURE/skeleton]] — this stub
- SSH hardening & Fail2Ban
- Firewall: UFW → iptables/DOCKER-USER
- Docker Engine + compose stack layout
- Postgres / Caddy / FastAPI services
- Infisical runtime secret injection

## Related

- [[00-META/tags]]
