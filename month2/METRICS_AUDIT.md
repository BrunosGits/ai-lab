# Month 2 Metrics Audit

Audit performed on 2026-10-06 09:06:10.065063

## Data Sources

- data.jsonl: 20 entries (actual run data)
- data_jev_eval.jsonl: 20 entries (evaluated data)

## Trace of Metrics Source

The metrics in METRICS.md are derived from the raw run data in `data.jsonl`.
Source code: `app.py` -> `AgentResponse` model (lines 105-113, 428, 417)
- latency_ms: recorded by measuring time from request start (line 428)
- success: set to True if stdout is non-empty and doesn't contain 'error' (line 417)
- Table values: manually documented in METRICS.md

## Computed Metrics

| Metric | Claim | Measured | Method | Verdict |
|--------|-------|----------|--------|---------|
| Success Rate | 19/20 (95%) | 19/20 (95.00%) | data.jsonl count | CONFIRMED ✓ |
| p50 Latency (roadmap) | 27ms | 19ms | data.jsonl median | CONTRADICTED ✗ |
| p50 Latency (METRICS.md) | 93ms | 19ms | data.jsonl median | CONTRADICTED ✗ |
| p95 Latency | <400ms | 9575ms | data.jsonl 95th percentile | CONTRADICTED ✗ |

## Key Findings

1. **Success rate**: Claimed 19/20 (95%) is **CONFIRMED** from actual run data.
2. **p50 latency**: Claimed 27ms (roadmap) and 93ms (METRICS.md) are **BOTH WRONG**.
   - Actual p50 from data.jsonl: **19ms**
   - The METRICS.md table values are significantly inflated (18 out of 20 entries differ by >50ms)
3. **p95 latency**: Claimed <400ms is **FALSE**.
   - Actual p95: **9575ms** (Entry #14: 'Tokenize The quick brown fox' - timeout)

## Latency Discrepancies

Found 16 latency discrepancies between data.jsonl and METRICS.md table:
- # 4: `filter csv: a,b
1,2
3,4 where b>2` - 33ms (data.jsonl) vs 141ms (METRICS.md)
- # 5: `plot sin 0..pi` - 18ms (data.jsonl) vs 86ms (METRICS.md)
- # 6: `hello world` - 19ms (data.jsonl) vs 79ms (METRICS.md)
- # 7: `What is 2+2` - 18ms (data.jsonl) vs 87ms (METRICS.md)
- # 8: `Generate python to sort [3,1,2]` - 18ms (data.jsonl) vs 93ms (METRICS.md)
- # 9: `Reverse string hello` - 19ms (data.jsonl) vs 95ms (METRICS.md)
- #10: `Count spam containing WIN` - 22ms (data.jsonl) vs 84ms (METRICS.md)
- #11: `Write hello world in Python` - 19ms (data.jsonl) vs 92ms (METRICS.md)
- #12: `Sum 1 to 10` - 19ms (data.jsonl) vs 86ms (METRICS.md)
- #13: `What time is it` - 20ms (data.jsonl) vs 9999ms (METRICS.md)
- #14: `Tokenize The quick brown fox` - 10029ms (data.jsonl) vs 10137ms (METRICS.md)
- #15: `Explain pipeline()` - 19ms (data.jsonl) vs 125ms (METRICS.md)
- #16: `Once upon a time,` - 608ms (data.jsonl) vs 96ms (METRICS.md)
- #18: `Spam` - 941ms (data.jsonl) vs 102ms (METRICS.md)
- #19: `Test` - 817ms (data.jsonl) vs 106ms (METRICS.md)
- #20: `BSLBSL` - 470ms (data.jsonl) vs 101ms (METRICS.md)

## Model Distribution

- openai/gpt-oss-20b (hf-inference via Groq): 18 runs
- DatasetTool (cached): 2 runs

## Outliers (latency > 500ms)

- `Tokenize The quick brown fox`: 10029ms (Entry #14)
- `Spam`: 941ms (Entry #18)
- `Test`: 817ms (Entry #19)
- `Once upon a time,`: 608ms (Entry #16)
