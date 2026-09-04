---
title: ai-lab-m1-chatbot
sdk: static
pinned: false
tags:
  - month1
  - chatbot
  - static
  - inference-api
datasets:
  - BSLBSL/month1-spam-sample
---

# ai-lab-m1-chatbot (Month 1 — Static + VPS)

> **Month 1 — Static Space (free) + VPS Gradio fallback.** Static page tries HF Inference API (`HuggingFaceTB/SmolLM2-135M-Instruct`) first, VPS `http://51.79.71.160.sslip.io/chat` runs Gradio with local `distilgpt2` fallback. Dataset: [BSLBSL/month1-spam-sample](https://huggingface.co/datasets/BSLBSL/month1-spam-sample).

## Demos
- **Static (this Space):** this page — client-side JS to HF Inference
- **VPS (live):** [http://51.79.71.160.sslip.io/chat](http://51.79.71.160.sslip.io/chat) — Gradio (`month1/app.py`) via Caddy `handle_path /chat*`

## Source
- `app.py` — Gradio + dual-mode Inference/local
- `index.html` — static frontend
- `study_transformers.py`, `study_datasets.py` — Month 1 study
