# 🧪 AI Lab VPS

*Learning · Building · Publishing (GitHub + HF)*

This document is the master plan for a personal AI engineering laboratory hosted on an OVHcloud VPS. The goal is to learn Linux administration, Docker, backend development and agentic AI by building real projects — publishing each one publicly on GitHub and Hugging Face as a portfolio. The infrastructure is built in phases (0–4), while a 5-month roadmap guides the studies; every month ends with a published demo, a journal entry and an updated roadmap.

---

## 📦 Infrastructure — Phase 0–4

### Phase 0 — Prep

- [x] OVH edge firewall: allow 22/80/443 only
- [x] SSH from Mac (id_ed25519)
- [x] Rescue mode instructions noted
- [x] apt update + upgrade (Debian 13)
- [x] TZ America/Sao_Paulo · hostname ai-lab · timesync

> Rescue: OVH dashboard → VPS → Reboot into rescue mode (netboot) → connect via SSH to rescue IP w/ password → mount /dev/sda1 (or vg) → recover. Recovery credentials: debian password (`VPS_SECRET` in Infisical) or OVH root-password reset. Step-by-step runbook: `rescue-drill.md`.

### Commands learned — Phase 0

**SSH**
- `ssh debian@51.79.71.160` — connect via key auth
- `ssh -o BatchMode=yes <user>@...` — non-interactive (never prompts)
- `ssh -o PreferredAuthentications=none <user>@...` — probe which auth methods the server offers
- `ssh-keygen` — generate `~/.ssh/id_ed25519`
- `scp -o BatchMode=yes <file> <user>@...:~/path` — copy file to server

**Infisical**
- `infisical login status` — check auth
- `infisical secrets --projectId <id> --env prod` — list secrets
- `infisical secrets set KEY=value --projectId <id> --env prod --path /folder --type shared` — create/update
- `infisical secrets delete KEY --projectId <id> --env prod --path /folder --type shared` — delete
- `infisical run -- <cmd>` — inject secrets at runtime (Phase 3 pattern)

**Time tracker (local)**
- `python3 scripts/time-tracker.py start|close|status|summary`

**RDP tunnel (GUI)**
- `ssh -f -N -L 3389:localhost:3389 debian@51.79.71.160` — background tunnel, reconnect to 127.0.0.1:3389

### Phase 1 — Server Foundation

- [x] qemu-guest-agent installed (consistent OVH snapshots)
- [x] swapfile 2 GB + swappiness=10
- [x] unattended-upgrades (security only)
- [x] user bruno (sudo) created
- [x] SSH key copied + login verified (2nd session)
- [x] sshd hardened: root+password OFF (sshd -t → reload)
- [x] passwd -l root (OVH email password dead)
- [x] Fail2Ban SSH jail
- [x] UFW 22/80/443 active
- [ ] DOCKER-USER default-drop (Phase 2)

### Commands learned — Phase 1

**Packages & system**
- `sudo apt-get update && sudo apt-get upgrade` — update packages
- `sudo apt-get install -y <pkg>` — install
- `free -h` — memory/swap usage
- `sudo fallocate -l 2G /swapfile` + `sudo mkswap` + `sudo swapon` — swap file
- `echo "vm.swappiness=10" | sudo tee /etc/sysctl.d/99-swap.conf` — persist swap tuning
- `unattended-upgrades -d --dry-run` — preview what would be upgraded

**Users & hardening**
- `sudo useradd -m -s /bin/bash -G sudo <user>` — create admin user
- `sudo usermod -aG adm,systemd-journal <user>` — extra groups
- `sudo passwd -l <user>` / `sudo passwd -S <user>` — lock / show status
- `visudo -cf <file>` — validate sudoers before applying
- `sudo sshd -t` — validate sshd config; `sudo sshd -T` — show effective runtime config
- Note: OpenSSH uses **first-value-wins** — a drop-in like `sshd_config.d/60-hardening.conf` does NOT override an earlier `50-cloud-init.conf`; edit the first file instead.

**Firewall**
- `sudo ufw allow <port>/tcp` · `sudo ufw --force enable` · `sudo ufw status verbose`
- `sudo fail2ban-client status sshd` — banned IPs per jail

**Networking / processes**
- `sudo ss -ltnp | grep :<port>` — listening sockets + process
- `ps aux | grep <name>` · `lsof -nP -iTCP:<port> -sTCP:LISTEN` — find processes/ports

### Phase 1.5 — Systemd-first (learn Linux before Docker)

- [x] PostgreSQL via apt installed (→ single PG 17 container in Phase 3, apt cluster dropped)
- [x] FastAPI "hello" as systemd unit + gunicorn
- [x] journalctl / systemctl mastered
- [ ] app containerized in Phase 3 (same app)

### Commands learned — Phase 1.5

**Systemd**
- `sudo systemctl enable --now <svc>` · `sudo systemctl restart <svc>` · `sudo systemctl is-active <svc>` · `sudo systemctl status <svc>`
- `sudo systemctl daemon-reload` — reload unit files after editing
- `systemctl list-units --type=service --state=running` — running services

**Journalctl (logs)**
- `journalctl -u <svc>` — service logs · `-f` follow · `-n <N>` last N lines

**PostgreSQL**
- `pg_lsclusters` — list clusters/ports/status
- `sudo -u postgres psql -c "SQL"` — run SQL as postgres user
- `sudo ss -ltnp | grep 5432` — check it's localhost-only

**Python app**
- `sudo apt-get install python3-venv` — prerequisite for venvs
- `python3 -m venv .venv` — create virtual env
- `./.venv/bin/pip install fastapi gunicorn uvicorn` — deps
- `./.venv/bin/gunicorn --workers 2 --worker-class uvicorn.workers.UvicornWorker --bind 127.0.0.1:8000 main:app` — serve app
- `curl -s http://127.0.0.1:8000/` — test local service

### Phase 2 — Docker

- [ ] Rescue mode drill (runbook: `rescue-drill.md`)
- [ ] remove desktop GUI (Xfce/xrdp/Chrome/OpenCode Desktop) — free RAM for Docker
- [ ] Docker Engine (official repo) + Compose plugin
- [ ] bruno added to docker group
- [ ] daemon.json: log rotation (10m × 3) · live-restore · builder GC
- [ ] DOCKER-USER default-drop persisted via netfilter-persistent (survives reboot)
- [ ] hello-world test passed

### Phase 3 — Slim Stack (only what's studied now)

- [ ] DNS plan: sslip.io/nip.io for tests → custom ~$10/yr domain before going public
- [ ] PostgreSQL 17 container (matching apt version — apt cluster dropped)
- [ ] Caddy reverse proxy (only 80/443 published)
- [ ] pinned image tags · restart: unless-stopped
- [ ] internal-only network (nothing else exposed)
- [ ] Systemd FastAPI moved into container
- [ ] Secrets via Infisical: `infisical run -- docker compose up -d` (no .env on server)

### Phase 4 — Backup & Resume

- [ ] scripts/backup.sh: pg_dump -Fc + volume tar (age)
- [ ] systemd timer nightly (user bruno) — not cron
- [ ] rclone → Backblaze B2 (primary, 10 GB free tier) · OVH Object Storage as alt
- [ ] Monthly restore drill (OVH mount option) + one full-rebuild drill
- [ ] Pause/resume runbook in README (recreate in minutes)

---

## 📚 Learning Roadmap — every month ends with a PUBLISH step

### Month 1 — Linux + Docker

- **Study:** HF Transformers · HF Datasets · HF Spaces
- **Build:** first chatbot Space
- **Publish:** Space (live demo) + GitHub repo + journal entry + ROADMAP update
- [ ] Transformers: pipeline(), AutoTokenizer, AutoModelForCausalLM
- [ ] Datasets: download, filter, publish one
- [ ] Chatbot Space duplicated + modified + public
- [ ] Repo flipped public (when polished)

### Month 2 — Backend

- **Study:** HF Inference API (huggingface_hub) · SmolAgents · Redis 7
- **Build:** agent demo (calls APIs, executes code)
- **Publish:** Space + repo
- [ ] Inference API: swap models without changing code
- [ ] SmolAgents: agent with tools + ReAct loop
- [ ] Redis 7 added (cache/queues when app needs it)
- [ ] FastAPI REST + auth + async mastered

### Month 3 — AI Integration

- **Study:** OpenCode Zen (multi-model) · Evaluation (BLEU · ROUGE · BERTScore · LLM-as-Judge)
- **Build:** LLM Evaluation Lab (FastAPI on VPS)
- **Publish:** eval UI Space + repo + dataset (results/prompts)
- [ ] Models via Zen + HF (multiple providers)
- [ ] Metrics implemented + stored in PostgreSQL
- [ ] Eval dataset published on HF
- [ ] Dashboard/UI for comparing models, cost, latency

### Month 4 — Agentic AI

- **Study:** MCP · RAG · Embeddings · Qdrant
- **Build:** MCP Playground + Agent Evaluation Lab
- **Publish:** agent lab Space + repo
- [ ] MCP server: tools + resources (agent ↔ tools)
- [ ] Qdrant added: embeddings + semantic search
- [ ] RAG pipeline end-to-end (docs → vectors → answers)
- [ ] Agent eval: planning, tool use, memory, reliability

### Month 5 — Professional

- **Study:** Langfuse Cloud · CI/CD · Monitoring · Portfolio
- **Build:** portfolio (projects + demos unified)
- **Publish:** everything
- [ ] Langfuse Cloud wired (prompts, costs, latency, errors)
- [ ] CI/CD pipeline (tests + deploy on push)
- [ ] All 5 project repos public + READMEs + demos
- [ ] ROADMAP 100% complete · HF profile pinned · GitHub grid full

---

## 🔄 Publish Loop (the habit) — repeat every month

```
Study → Build → Publish → Journal → Update ROADMAP → Flip repo public
              │          │
              │          └─ HF: Space (demo) + Dataset + Collection
              └──────────── GitHub: repo + README + demo link + badge
```

---

## 🗄️ Backup — 3 Layers

| Layer | Where | What |
|---|---|---|
| **Code** | GitHub | compose · Caddyfile · scripts · migrations |
| **Config** | Infisical (cloud) | secrets — never on server, never committed |
| **Data** | Backblaze B2 (primary, 10 GB free) | encrypted (dumps + volumes) |

**Secrets (Infisical):** API keys and passwords live in Infisical Cloud, injected at runtime with `infisical run`. No `.env` files on the server or in Git — removes the top secret-leak risk and simplifies restore (no secrets to back up).

---

## 🔐 Services & Access

| Service | Account | Login method | Where the key lives |
|---|---|---|---|
| **OVH** | VPS-1 | Direct login (web) — dashboard + emailed root password | — (root password removed from Infisical) |
| **Infisical** | mac-cli machine identity | Universal-auth (client-id + secret) → `INFISICAL_TOKEN` in `~/.zshrc` | Infisical itself |
| **VPS (SSH)** | `bruno` / `debian` | Key auth (`~/.ssh/id_ed25519`) · passwordless sudo | key on Mac + server |
| **GitHub** | `BrunosGits` | Classic PAT used for `git push` (token-in-URL, scrubbed after) · web login direct | `/github/GITHUB_TOKEN` in Infisical |
| **Hugging Face** | — | Access token (HF dashboard → Access Tokens) | `/huggingface/Access Token` in Infisical |
| **Langfuse Cloud** | us.cloud.langfuse.com | Public/Secret keys (MCP basic-auth header pre-made) | `/langfuse/*` in Infisical |
| **OpenCode Zen** | — | Zen API key | `/opencode-zen/OpenCodeAPI` in Infisical |
| **OpenCode Desktop** (VPS GUI) | local app | Direct login with Zen key (not Infisical-managed) | app config on VPS |

---

## 💻 Machine Config — OVHcloud VPS-1

| | |
|---|---|
| **Provider** | OVHcloud VPS-1 2027 |
| **Plan** | VPS Local Storage |
| **CPU** | 2 vCPU |
| **RAM** | 4 GB |
| **Disk** | 40 GB SSD (local storage) |
| **OS** | Debian 13 (Trixie) |
| **Backup** | OVH Automated Backup (1 rotation) — daily, included |
| **Billing** | Monthly — 4.49 €/month (with coupon) |
| **Region** | Canada East (Beauharnois) — good latency from Brazil |
| **IPv4** | Included |
| **SSH** | `debian@51.79.71.160` (key auth) |

## 💰 Project Costs

| Item | Cost |
|---|---|
| OVH VPS-1 | 4.49 €/month (with coupon) |
| Plan printing service (4 pages) | R$ 4,00 |
| **Total so far** | 4.49 €/month + R$ 4,00 |
