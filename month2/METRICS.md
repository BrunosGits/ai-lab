# Month 2 — Metrics (placeholder, to fill after VPS deploy)

> Target: Success >=85% (17/20) generic-code stdout==expected, p50 <4s local 360M / <2s hf-inference 1.7B, tokens avg <400, tool calls avg 1.5-2.5, Cost $0.

## Prompts (20) — run via POST /agent/run

| # | Prompt | Expected stdout | Latency | Success |
|---|--------|----------------|---------|---------|
| 1 | fibonacci 20 | [0,1,1,2,3,5,8,13,21,34,55,89,144,233,377,610,987,1597,2584,4181] |  |  |
| 2 | count spam SMS containing FREE in BSLBSL/month1-spam-sample | 3 (or dataset count) |  |  |
| 3 | is 97 prime? | True |  |  |
| 4 | csv filter a,b / 1,2 / 3,4 where b>2 | 3,4 |  |  |
| 5 | plot sin 0..pi (ascii or values) |  |  |  |
| 6-20 | ... |  |  |  |

Run: `for p in prompts; do curl -s -X POST http://51.79.71.160:8001/agent/run -H 'Content-Type: application/json' -d "{\"prompt\":\"$p\"}"; done`

## How to reproduce

```bash
curl -s http://51.79.71.160:8001/health
curl -s -X POST http://51.79.71.160:8001/agent/run -d '{"prompt":"fibonacci 20"}' | jq
```
