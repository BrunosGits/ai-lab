# Month 2 Metrics Trace Summary

## Task
Audit Month 2 metrics claims. The roadmap and month2/METRICS.md claim:
- **Success 19/20 (95%)**
- **p50 27ms**

## Trace of Metrics Source

### Where metrics are computed in the code

**File:** `month2/app.py`

**1. AgentResponse model (lines 105-113)**
```python
class AgentResponse(BaseModel):
    prompt: str
    code: str
    stdout: str
    latency_ms: int
    model: str
    tool_calls: int
    success: bool
    error: Optional[str] = None
```
This model defines the structure of the response.

**2. Latency measurement (line 428)**
```python
latency_ms = int((time.time()-t0)*1000)
```
- `t0` is set at line 288: `t0 = time.time()`
- Latency is measured in milliseconds by subtracting the start time from the end time

**3. Success determination (line 417)**
```python
success = bool(stdout and "error" not in stdout.lower()[:200])
```
Success is set to `True` if stdout is non-empty and doesn't contain "error" in the first 200 characters.

**4. Data recording (line 429)**
```python
resp = AgentResponse(prompt=prompt, code=code[:4000], stdout=stdout[:4000], latency_ms=latency_ms, model=model_name, tool_calls=tool_calls or 1, success=success, error=error)
```
The response is logged/recorded.

### Where metrics are documented

**File:** `month2/METRICS.md`

The table in METRICS.md documents 20 runs with:
- Prompt text
- Latency (in ms)
- Model used
- Success/No/err status
- stdout snippet

The summary stats (19/20, p50 27ms) are derived from:
1. **Success rate**: Counted manually from the table (19 successes out of 20)
2. **p50 latency**: The roadmap claims 27ms, but METRICS.md's table shows a median of 93ms (if you take the table's own latency values)

### Where metrics are stored

**File:** `month2/data.jsonl`

This file contains the actual run data from 20 executions:
- Each line is a JSON object with `prompt`, `code`, `stdout`, `latency_ms`, `model`, `success`
- This is the ground truth data used for validation

## Metrics Recomputed from Actual Data

**Source:** `month2/data.jsonl` (20 entries)

### Success Rate
- **Claim:** 19/20 (95%)
- **Measured:** 19/20 (95.00%)
- **Method:** Count entries with `success: true`
- **Verdict:** ✓ CONFIRMED

### p50 Latency
- **Claim (roadmap):** 27ms
- **Claim (METRICS.md):** 93ms (median of table values)
- **Measured:** 19ms (median of actual latencies)
- **Method:** Statistics.median([latency_ms values])
- **Verdict:** ✗ CONTRADICTED

**Discrepancy:** Claimed 27ms/93ms vs measured 19ms

### p95 Latency
- **Claim:** <400ms
- **Measured:** 9575ms
- **Method:** 95th percentile of latencies
- **Verdict:** ✗ CONTRADICTED

**Discrepancy:** Claimed <400ms vs measured 9575ms

## Root Cause Analysis

The data.jsonl file contains the actual run data. The METRICS.md table shows significantly inflated latency values:

- **18 out of 20 entries** have latency discrepancies (>50ms difference)
- Most entries in data.jsonl are ~15-20ms
- METRICS.md table shows much higher values (~70-100ms for simple prompts)
- Exception: Entry #13 ("What time is it") shows 9999ms in table but 20ms in data.jsonl
- Exception: Entry #14 ("Tokenize The quick brown fox") shows 10137ms in table but 10029ms in data.jsonl (closer match)

**Conclusion:** The METRICS.md table values appear to be incorrect or represent different runs. The data.jsonl file is the source of truth.

## Model Distribution

From data.jsonl:
- `openai/gpt-oss-20b (hf-inference via Groq)`: 18 runs
- `DatasetTool (cached)`: 2 runs

## Outliers (latency > 500ms)

1. **Tokenize The quick brown fox**: 10029ms (Entry #14) - timeout
2. **Spam**: 941ms (Entry #18)
3. **Test**: 817ms (Entry #19)
4. **Once upon a time,**: 608ms (Entry #16)

## Deliverables

1. ✅ `month2/metrics_audit.py` - Audit script that recomputes metrics from data
2. ✅ `month2/METRICS_AUDIT.md` - Detailed audit report with table and verdicts
3. ✅ This trace summary document

## Audit Command

```bash
python3 month2/metrics_audit.py
```

This script will:
- Load data.jsonl and data_jev_eval.jsonl
- Compute success rate, p50, p95 latencies
- Compare with claims
- Generate METRICS_AUDIT.md report
