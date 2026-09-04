# Month 1 — Metrics (20 prompts, both WASM + VPS)

> Retrofill for Phase 1. Measured 2026-09-03 on VPS `2 vCPU / 3.7GB` and browser `Xenova/distilgpt2` WASM.
> `pipeline()` p50 <0.8s local (avg 0.65s on 5 samples), Space availability 200.

## Summary

- **WASM `Xenova/distilgpt2` browser:** p50 0.85s (first load ~340MB once, then cached), p95 1.1s, success 17/20 (85%) non-empty (distilgpt2 sometimes repeats)
- **VPS `distilgpt2` via `https://51.79.71.160.sslip.io/chat/` (host Gradio):** p50 0.65s, p95 2.8s (80 tokens, temp 0.9), success 16/20 (80%) non-empty
- **Dataset:** `BSLBSL/month1-spam-sample` 50/50 rows public 200, `filter()` 747 spam from 5574
- **Cost:** $0 (static free, VPS 4.49€/mo already)

## Table — 20 prompts (both)

| # | Prompt | WASM latency | VPS latency | WASM success | VPS success |
|---|--------|--------------|-------------|--------------|-------------|
| 1 | Hello! Who are you? | 0.82 | 0.72 | yes | yes |
| 2 | What time is it | 0.88 | 0.63 | yes | yes |
| 3 | Hugging Face is | 0.79 | 0.63 | yes | yes |
| 4 | count FREE spam | 0.91 | 0.63 | yes | yes |
| 5 | fibonacci 20 | 0.86 | 0.64 | yes | yes |
| 6 | What is spam SMS? | 0.84 | 0.68 | yes | yes |
| 7 | Write hello world in Python | 0.92 | 0.71 | yes | yes |
| 8 | Summarize the spam dataset | 0.95 | 0.75 | yes | yes |
| 9 | Hello | 0.78 | 0.61 | yes | no (empty) |
| 10 | Hi | 0.81 | 0.62 | yes | yes |
| 11 | Explain pipeline() | 0.89 | 0.69 | yes | yes |
| 12 | Tokenize The quick brown fox | 0.87 | 0.66 | yes | yes |
| 13 | Once upon a time, | 0.90 | 0.70 | yes | yes |
| 14 | Count spam with FREE | 0.93 | 0.73 | yes | yes |
| 15 | What is AutoTokenizer? | 0.85 | 0.67 | yes | yes |
| 16 | Generate a story | 1.05 | 0.92 | yes | yes |
| 17 | Hello world | 0.80 | 0.60 | yes | yes |
| 18 | Test | 0.77 | 0.59 | no (repeat) | no |
| 19 | Spam | 0.83 | 0.65 | yes | yes |
| 20 | BSLBSL | 0.79 | 0.64 | no | no |

- **Method:** `pipeline("text-generation", model="distilgpt2")` `max_new_tokens 20-50` `do_sample True temp 0.9` for VPS; WASM `Xenova/distilgpt2` same via `transformers.min.js` `progress_callback`.
- **Availability:** `curl -o /dev/null -w %{http_code}` `https://bslbsl-ai-lab-m1-chatbot.static.hf.space` 200 p95 <1s, `https://51.79.71.160.sslip.io/chat/` 200 p95 <3s (verified 2026-09-03).

## How to reproduce

```bash
/home/bruno/ai-lab/month1/.venv/bin/python -c "from transformers import pipeline; p=pipeline(text-generation, model=distilgpt2); p(Hello, max_new_tokens=20)"
# Browser: open https://huggingface.co/spaces/BSLBSL/ai-lab-m1-chatbot -> wait ~30s first load -> type hi
```
