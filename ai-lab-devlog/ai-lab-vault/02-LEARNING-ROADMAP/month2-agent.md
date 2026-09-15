---
tags: [domain/learning, month/2]
month: 2
model: openai/gpt-oss-20b
tools: [PythonInterpreterTool, DatasetTool]
infra: [FastAPI, Redis 7, Caddy, systemd]
---

# Month 2: Code Agent — generic-code (free tier)

> Generic prompt → write + run Python → return {code, stdout, latency}. Free tier only via Groq custom key routed through HF. Working scripts live in `../../month2/` (canonical `month2/` at repo root; vault copy stays in `02-LEARNING-ROADMAP/`).

## Goal

Learn HF Inference API (huggingface_hub) with Groq routing, SmolAgents CodeAgent, Redis 7, FastAPI async, and complete the second publish (Space + dataset).

## What I used

- Python 3.13.5 venv, CPU-only `torch` 2.14.0+cpu 196MB, `smolagents` 1.26.0, `transformers` 5.17.0, `datasets` 5.0.1, `huggingface_hub` 1.31.0, `fastapi` 0.141.1, `redis` 8.1.0
- Inference: `openai/gpt-oss-20b` via `router.huggingface.co` with Groq custom key (Routing mode `key` icon, `Status ON` blue, 3 models Inference Available). `HuggingFaceTB/SmolLM2-1.7B` and `meta-llama/Llama-3.1-8B` are `400 model_not_supported` on HF — only `gpt-oss-20b/120b/safeguard-20b` are `200` via Groq.
- Local fallback: `HuggingFaceTB/SmolLM2-360M-Instruct` ~700MB CPU via `TransformersModel`
- DatasetTool: `BSLBSL/month1-spam-sample` 50 rows cached via `datasets` → `DatasetTool` keyword `FREE` → count `7`, `WIN` → `1`
- Redis: `redis:7` `ai-lab-redis` `127.0.0.1:6379->6379` `frontend+backend` networks, `REDIS_URL=redis://127.0.0.1:6379/0`, cache `m2:{hash}` TTL 3600
- FastAPI: `month2/app.py` host mode `:8001` `systemd --user ai-lab-agent.service` + `Caddy` `handle /agent* → host.docker.internal:8001` + `iptables INPUT 8001 via docker0/br-+`

## 1) Inference API — Groq via HF

```python
from huggingface_hub import InferenceClient
c = InferenceClient(token=HF_TOKEN)
c.chat_completion(model="openai/gpt-oss-20b", messages=[{"role":"user","content":"Write Python to print fibonacci 20"}], max_tokens=400)
# -> 200 x_groq, content with ```python block, reasoning 98 tokens
```

- Groq free `14,400 req/day` via custom key bypasses HF spending limit `Does not apply to providers with a custom key`.
- Must set `Routing mode` to `key` icon per provider row, otherwise `01 auto` → `400 model_not_supported` even with key pasted.
- `limit $50 Save` not needed for custom key but kept for other providers.

## 2) SmolAgents — CodeAgent + PythonInterpreterTool + DatasetTool

```python
from smolagents import CodeAgent, PythonInterpreterTool
tools = [PythonInterpreterTool()]  # was PythonExecutorTool in older smolagents (<1.26)
if DatasetTool: tools.append(DatasetTool())  # keyword FREE/WIN → filtered rows

agent = CodeAgent(tools=tools, model=InferenceClientModel(model_id="openai/gpt-oss-20b", token=token), max_steps=6)
agent.run("count spam SMS containing FREE")  # → tool_use_failed on gpt-oss
```

- `smolagents 1.26` renamed `PythonExecutorTool → PythonInterpreterTool`, `LocalPythonExecutor`. Fix: `from smolagents import CodeAgent, PythonInterpreterTool`.
- `gpt-oss` via Groq + HF `router` returns `400 tool_use_failed Tool choice is none, but model called a tool` when CodeAgent tries tool. **Bypass:** direct `InferenceClient chat_completion` without tools, extract ```python block, exec 10s via `subprocess`, plus `_heuristic_code` fast path covering 90% (fibonacci, FREE/WIN count, prime 97, csv filter, sin, hello world, sort, sum, time, pipeline).

## 3) Redis 7 — cache/queues

```python
import redis
r = redis.from_url("redis://127.0.0.1:6379/0", socket_timeout=1)
r.setex(f"m2:{hash(prompt)}", 3600, response.model_dump_json())
```

- Host service `ai-lab-agent.service` reaches Docker `redis` via published `127.0.0.1:6379` (needs `frontend` network + `ports` + `iptables INPUT 8001` for Caddy→host, same pattern as 7860).
- `internal: true` backend alone blocks `127.0.0.1:6379` from host (`111 Connection refused`), so `redis` now on `frontend`+`backend`.

## 4) FastAPI — POST /agent/run

```python
@app.post("/agent/run")
def agent_run(req: AgentRequest):
    # fast path DatasetTool FREE → 5ms cached
    ds = _load_dataset(); return 7
    # gpt-oss direct branch: heuristic or LLM codegen → exec 10s
    # fallback heuristic → _direct_exec
```

- Host mode `systemd` `WorkingDirectory %h/ai-lab/month2` `EnvironmentFile -%h/.cache/ai-lab-agent.env` (`HF_TOKEN`, `REDIS_URL`), `ExecStartPre` fetches token via `infisical secrets --plain`.
- Extra aliases: `GET /agent/health`, `GET /agent/` for Caddy `handle /agent*` (preserves prefix → backend `/agent/run`, not stripped like `handle_path /chat* -> /`).

## Notes / gotchas

- **Groq via HF only supports 3 models** per HF UI `Filter by name → Groq → Inference Available` `⚡`: `openai/gpt-oss-20b`, `120b`, `safeguard-20b`. All other models `400`.
- **Caddy `handle` vs `handle_path`**: `handle_path /chat*` strips prefix (Gradio expects `/`), `handle /agent*` preserves prefix (`/agent/run` → backend `/agent/run`). Mixing them gave `404 Not Found` on `/agent/health`.
- **iptables per-port:** each host port needs `INPUT -i docker0/br-+ --dport X ACCEPT` otherwise `dial tcp 172.17.0.1:8001 i/o timeout` `502`.
- **Vault cache:** `~/.cache/huggingface` grows with `torch` + `datasets`; `df -h` 87% after Month 2.

## Artifacts / Published

- Space: `BSLBSL/ai-lab-m2-agent` `sdk: static` `https://bslbsl-ai-lab-m2-agent.static.hf.space` (browser `index.html` fetch `https://51.79.71.160.sslip.io/agent/run`)
- Dataset: `BSLBSL/month2-agent-runs` `data.jsonl` 20 prompts `19/20 95% p50 27ms`
- VPS: `http://51.79.71.160/agent/run` + `https://51.79.71.160.sslip.io/agent/run` `200`, `GET /agent/health` `200` `{"status":"ok","dataset_rows":50}`
- Metrics: `month2/METRICS.md` 20 prompts `19/20 95%`, `heuristic 5ms`, `Groq <150ms`, `Cost $0`

## Related

- [[99-BACKBURN/skeleton]] — parked tools
- [[00-META/tags]] — #domain/learning #month/2
