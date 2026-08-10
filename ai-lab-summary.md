# 🧪 AI Lab VPS

*Learning · Building · Publishing (GitHub + HF)* · Started 2026-08-04

This document is the master plan for a personal AI engineering laboratory hosted on an OVHcloud VPS. The goal is to learn Linux administration, Docker, backend development and agentic AI by building real projects, publishing each one publicly on GitHub and Hugging Face as a portfolio. The infrastructure is built in phases (0–4), while a 5-month roadmap guides the studies. Every month ends with a published demo, a journal entry and an updated roadmap.

---

## 📦 Infrastructure — Phase 0–4

### Phase 0 — Prep

- [x] OVH edge firewall: allow 22/80/443 only
- [x] SSH from computer (id_ed25519)
- [x] Rescue mode instructions noted
- [x] apt update + upgrade (Debian 13)
- [x] TZ America/Sao_Paulo · hostname ai-lab · timesync

> Rescue: OVH dashboard → VPS → Reboot into rescue mode (netboot) → connect via SSH to rescue IP w/ password → mount /dev/sda1 (or vg) → recover. Recovery credentials: user password (`VPS_SECRET` in Infisical) or OVH root-password reset. Step-by-step runbook: `rescue-drill.md`.

### Commands learned — Phase 0

**SSH**
- `ssh <user>@<vps-ip>` — connect via key auth
- `ssh -o BatchMode=yes <user>@...` — non-interactive (never prompts)
- `ssh -o PreferredAuthentications=none <user>@...` — probe which auth methods the server offers
- `ssh-keygen` — generate `~/.ssh/id_ed25519`
- `scp -o BatchMode=yes <file> <user>@...:~/path` — copy file to server

**Git**
- `git push` — send your local commits to GitHub (sync local → remote)
- `git pull` — bring remote changes down (sync remote → local)
- Both together (fetch → merge/rebase) is usually just called "sync"
- **Commit** — a saved snapshot of the project at one point in time. Holds the diff, author, timestamp and a message. Chained into history, each one knows its parent. `git add` stages (selects) the files, `git commit` saves the snapshot locally.
- **Push vs commit** — commit saves locally, push uploads to GitHub. Edit → add → commit → push. Work is only visible on GitHub after a push.

**Infisical**
- `infisical login status` — check auth
- `infisical secrets --projectId <id> --env prod` — list secrets
- `infisical secrets set KEY=value --projectId <id> --env prod --path /folder --type shared` — create/update
- `infisical secrets delete KEY --projectId <id> --env prod --path /folder --type shared` — delete
- `infisical run -- <cmd>` — inject secrets at runtime (Phase 3 pattern)

**Time tracker (local, Rust)**
- `cargo run --release --manifest-path scripts/time-tracker/Cargo.toml -- start|close|status|summary`
- Rust rewrite of the original Python; `scripts/time-tracker.py` kept as reference

**RDP tunnel (GUI)** — removed 2026-08-07 with the desktop GUI (xrdp purged). The VPS is headless from now on; GUI tooling stays on the computer.

### Phase 1 — Server Foundation

- [x] qemu-guest-agent installed (consistent OVH snapshots)
- [x] swapfile 2 GB + swappiness=10
- [x] unattended-upgrades (security only)
- [x] user <user> (sudo) created
- [x] SSH key copied + login verified (2nd session)
- [x] sshd hardened: root+password OFF (sshd -t → reload)
- [x] passwd -l root (OVH email password dead)
- [x] Fail2Ban SSH jail
- [x] UFW 22/80/443 active
- [x] DOCKER-USER default-drop (Phase 2)

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
- `sudo sshd -t` — validate sshd config, `sudo sshd -T` — show effective runtime config
- Note: OpenSSH uses **first-value-wins**. A drop-in like `sshd_config.d/60-hardening.conf` does NOT override an earlier `50-cloud-init.conf`, edit the first file instead.

**Firewall**
- `sudo iptables -S INPUT` / `sudo ip6tables -S INPUT` — show host firewall rules
- `sudo iptables -L DOCKER-USER -n -v` — container forward rules
- `sudo netfilter-persistent save` — persist iptables rules (replaces ufw)
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

- [x] Rescue mode drill (runbook: `rescue-drill.md`)
- [x] remove desktop GUI (Xfce/xrdp/Chrome/OpenCode Desktop) — free RAM for Docker
- [x] Docker Engine (official repo) + Compose plugin
- [x] <user> added to docker group
- [x] daemon.json: log rotation (10m × 3) · live-restore · builder GC
- [x] DOCKER-USER default-drop persisted via netfilter-persistent (survives reboot)
- [x] hello-world test passed

### Phase 3 — Slim Stack (only what's studied now)

- [ ] DNS plan: sslip.io/nip.io for tests → custom ~$10/yr domain before going public
- [ ] PostgreSQL 17 container (matching apt version, apt cluster dropped)
- [ ] Caddy reverse proxy (only 80/443 published)
- [ ] pinned image tags · restart: unless-stopped
- [ ] internal-only network (nothing else exposed)
- [ ] Systemd FastAPI moved into container
- [ ] Secrets via Infisical: `infisical run -- docker compose up -d` (no .env on server)

### Phase 4 — Backup & Resume

- [ ] scripts/backup.sh: pg_dump -Fc + volume tar (age)
- [ ] systemd timer nightly (user) — not cron
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

**Secrets (Infisical):** API keys and passwords live in Infisical Cloud, injected at runtime with `infisical run`. No `.env` files on the server or in Git, which removes the top secret-leak risk and simplifies restore (no secrets to back up).

---

## 🔐 Services & Access

| Service | Account | Login method | Where the key lives |
|---|---|---|---|
| **OVH** | VPS-1 | Direct login (web) — dashboard + emailed root password | — (root password removed from Infisical) |
| **Infisical** | mac-cli machine identity | Universal-auth (client-id + secret) → `INFISICAL_TOKEN` in `~/.zshrc` | Infisical itself |
| **VPS (SSH)** | `<user>` | Key auth (`~/.ssh/id_ed25519`) · passwordless sudo | key on computer + server |
| **GitHub** | `BrunosGits` | Classic PAT used for `git push` (token-in-URL, scrubbed after) · web login direct | `/github/GITHUB_TOKEN` in Infisical |
| **Hugging Face** | — | Access token (HF dashboard → Access Tokens) | `/huggingface/Access Token` in Infisical |
| **Langfuse Cloud** | us.cloud.langfuse.com | Public/Secret keys (MCP basic-auth header pre-made) | `/langfuse/*` in Infisical |
| **OpenCode Zen** | Big Pickle model LLM | Zen API key | `/opencode-zen/OpenCodeAPI` in Infisical |
| **Llama 3.2 (local)** | — | Ollama on the computer (`localhost:11434`, free fallback) | — (runs locally) |

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
| **SSH** | `<user>@<vps-ip>` (key auth) |

## 💰 Project Costs

| Item | Cost |
|---|---|
| OVH VPS-1 | 4.49 €/month (with coupon) |
| Plan printing service (4 pages) | R$ 4,00 |
| **Total so far** | 4.49 €/month + R$ 4,00 |
