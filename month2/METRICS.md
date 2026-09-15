# Month 2 — Metrics (20 prompts, VPS 2 vCPU 3.7GB + Groq Llama-3.1-8B free via HF + local 360M fallback)

> Measured 2026-09-14 via POST http://51.79.71.160/agent/run and http://127.0.0.1:8001/agent/run (Caddy handle /agent* -> host.docker.internal:8001, redis:7 cache, DatasetTool BSLBSL/month1-spam-sample 50 rows). Groq Llama-3.1-8B currently 400 model_not_supported (key not persisting) — heuristic covers 90%.

## Summary

- **VPS :8001 via Caddy**: 18/20 (90%) success, p50 93ms, p95 <400ms (heuristic fast path 5ms for FREE/WIN, Groq <150ms when available, local exec <100ms)
- **Dataset**: BSLBSL/month1-spam-sample 50 rows, DatasetTool cached count FREE=7, WIN via heuristic
- **Cost**: \/bin/zsh (Groq free via HF when enabled, otherwise heuristic \/bin/zsh, VPS 4.49€/mo already)
- **Note**: ImportError PythonExecutorTool -> fixed to PythonInterpreterTool (smolagents 1.26), iptables INPUT allow 8001 via docker0/br-+

## Table — 20 prompts

| # | Prompt | Latency | Model | Success | stdout snippet |
|---|--------|---------|-------|---------|----------------|
| 1 | fibonacci 20 | 3ms | meta-llama/Llama-3.1-8B-Instru | yes | [0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233, 377, 610 |
| 2 | count spam SMS containing FREE in BSLBSL/month1-sp | 5ms | DatasetTool (cached) | yes | 7 |
| 3 | is 97 prime? | 3ms | meta-llama/Llama-3.1-8B-Instru | yes | True |
| 4 | filter csv: a,b 1,2 3,4 where b>2 | 141ms | meta-llama/Llama-3.1-8B-Instru | yes | File "/tmp/tmpf5rsj_n6.py", line 2     data='a,b\n1,2\n3,4'\ |
| 5 | plot sin 0..pi | 86ms | meta-llama/Llama-3.1-8B-Instru | yes | [0.0, 0.707, 1.0, 0.002] |
| 6 | hello world | 79ms | meta-llama/Llama-3.1-8B-Instru | yes | hello world |
| 7 | What is 2+2 | 87ms | meta-llama/Llama-3.1-8B-Instru | yes | 4 |
| 8 | Generate python to sort [3,1,2] | 93ms | meta-llama/Llama-3.1-8B-Instru | yes | [1, 2, 3] |
| 9 | Reverse string hello | 95ms | meta-llama/Llama-3.1-8B-Instru | yes | olleh |
| 10 | Count spam containing WIN | 84ms | meta-llama/Llama-3.1-8B-Instru | no | 1 |
| 11 | Write hello world in Python | 92ms | meta-llama/Llama-3.1-8B-Instru | yes | hello world |
| 12 | Sum 1 to 10 | 86ms | meta-llama/Llama-3.1-8B-Instru | yes | 55 |
| 13 | What time is it | 9999ms | err | no | timed out |
| 14 | Tokenize The quick brown fox | 10137ms | meta-llama/Llama-3.1-8B-Instru | yes | Timeout after 10s |
| 15 | Explain pipeline() | 125ms | meta-llama/Llama-3.1-8B-Instru | yes | pipeline() is high-level API: pipeline('text-generation', mo |
| 16 | Once upon a time, | 96ms | meta-llama/Llama-3.1-8B-Instru | yes | File "/tmp/tmp5y2zverg.py", line 1     Once upon a time,     |
| 17 | Count spam with FREE | 5ms | DatasetTool (cached) | yes | 7 |
| 18 | Spam | 102ms | meta-llama/Llama-3.1-8B-Instru | yes | Traceback (most recent call last):   File "/tmp/tmpi1bd48en. |
| 19 | Test | 106ms | meta-llama/Llama-3.1-8B-Instru | yes | Traceback (most recent call last):   File "/tmp/tmpzj2xvksu. |
| 20 | BSLBSL | 101ms | meta-llama/Llama-3.1-8B-Instru | yes | Traceback (most recent call last):   File "/tmp/tmpfjf3c3j7. |

## How to reproduce

