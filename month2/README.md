---
title: ai-lab-m2-agent
sdk: static
pinned: false
tags:
  - month2
  - agent
  - smolagents
  - code-agent
datasets:
  - BSLBSL/month1-spam-sample
---

# ai-lab-m2-agent — Month 2 (generic-code, free tier)

> Generic prompt → SmolAgents `CodeAgent` + `PythonExecutorTool` + `DatasetTool` → `{code, stdout, latency}`. Free tier only: `openai/gpt-oss-20b via Groq (3 models Inference Available)` via `hf-inference` (toggle ON) or local `SmolLM2-360M-Instruct` (~700MB CPU).

## Tools

- `python_interpreter` (`PythonExecutorTool`, 10s timeout, no network) — fibonacci, csv filter, plot sin, prime 97, etc.
- `dataset_search` (`DatasetTool`, reads `BSLBSL/month1-spam-sample` 50 rows) — `keyword`/`limit` → filtered spam SMS for dataset-aware prompts (e.g. count FREE).

## Demos

- **VPS (live):** `http://51.79.71.160.sslip.io/agent/` and `POST /agent/run` via Caddy `handle_path /agent*` → `host.docker.internal:8001` (host FastAPI, like `/chat`)
- **Static fallback:** `index.html` calls `POST /agent/run` with JS; works with or without HF token.

## API

```bash
curl -s http://51.79.71.160:8001/health
curl -s -X POST http://51.79.71.160:8001/agent/run -H 'Content-Type: application/json' -d '{"prompt":"fibonacci 20"}'
curl -s -X POST http://51.79.71.160:8001/agent/run -H 'Content-Type: application/json' -d '{"prompt":"count spam SMS containing FREE in BSLBSL/month1-spam-sample"}'
```

## Run locally

```bash
pip install -r requirements.txt
HF_TOKEN=hf_xxx REDIS_URL=redis://localhost:6379/0 uvicorn app:app --port 8001
```

## Metrics

Target ≥85% (17/20) generic-code stdout==expected, p50 <4s local 360M / <1s Groq via HF, tokens avg <400, tool calls avg 1.5–2.5. Cost $0. See `METRICS.md`.
