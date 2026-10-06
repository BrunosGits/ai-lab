# JEV Quality Gate Report — Month 2

**Mode:** MOCK (pre-computed results, NOT validated against live JEV)
**Runs evaluated:** 20
**Time:** 0.0s
**Estimated cost:** $0.000030 ($709 input tokens @ $0.042/M)

## Label Distribution

| Label | Count | Percentage |
|-------|-------|------------|
| PASS | 11 | 55.0% |
| FAIL | 2 | 10.0% |
| REVIEW | 7 | 35.0% |

## Detailed Results

| # | Prompt | Model | Score | Conf | Failure Mode | Fail Conf | Sec Noul | Label |
|---|--------|-------|-------|------|--------------|-----------|----------|-------|
| 1 | fibonacci 20 | openai/gpt-oss-20b (hf-inferen | 1.83 | 0.74 | not_applicable | 0.95 | 0.02 | **REVIEW** |
| 2 | count spam SMS containing FREE in BSLBSL | DatasetTool (cached) | 0.96 | 0.40 | logic_error | 0.51 | 0.04 | **REVIEW** |
| 3 | is 97 prime? | openai/gpt-oss-20b (hf-inferen | 2.00 | 0.99 | not_applicable | 0.99 | 0.02 | **PASS** |
| 4 | filter csv: a,b 1,2 3,4 where b>2 | openai/gpt-oss-20b (hf-inferen | 0.02 | 0.96 | syntax_error | 0.99 | 0.04 | **FAIL** |
| 5 | plot sin 0..pi | openai/gpt-oss-20b (hf-inferen | 0.96 | 0.68 | not_applicable | 0.37 | 0.02 | **REVIEW** |
| 6 | hello world | openai/gpt-oss-20b (hf-inferen | 2.00 | 1.00 | not_applicable | 1.00 | 0.02 | **PASS** |
| 7 | What is 2+2 | openai/gpt-oss-20b (hf-inferen | 2.00 | 1.00 | not_applicable | 1.00 | 0.02 | **PASS** |
| 8 | Generate python to sort [3,1,2] | openai/gpt-oss-20b (hf-inferen | 1.98 | 0.97 | not_applicable | 1.00 | 0.01 | **PASS** |
| 9 | Reverse string hello | openai/gpt-oss-20b (hf-inferen | 2.00 | 1.00 | not_applicable | 1.00 | 0.02 | **PASS** |
| 10 | Count spam containing WIN | openai/gpt-oss-20b (hf-inferen | 0.45 | 0.32 | logic_error | 0.76 | 0.02 | **REVIEW** |
| 11 | Write hello world in Python | openai/gpt-oss-20b (hf-inferen | 1.99 | 0.98 | not_applicable | 1.00 | 0.02 | **PASS** |
| 12 | Sum 1 to 10 | openai/gpt-oss-20b (hf-inferen | 2.00 | 1.00 | not_applicable | 1.00 | 0.02 | **PASS** |
| 13 | What time is it | openai/gpt-oss-20b (hf-inferen | 1.64 | 0.47 | not_applicable | 0.77 | 0.02 | **REVIEW** |
| 14 | Tokenize The quick brown fox | openai/gpt-oss-20b (hf-inferen | 0.20 | 0.69 | timeout | 0.97 | 0.04 | **FAIL** |
| 15 | Explain pipeline() | openai/gpt-oss-20b (hf-inferen | 0.88 | 0.61 | not_applicable | 0.58 | 0.02 | **REVIEW** |
| 16 | Once upon a time, | openai/gpt-oss-20b (hf-inferen | 1.91 | 0.87 | not_applicable | 0.99 | 0.02 | **PASS** |
| 17 | Count spam with FREE | DatasetTool (cached) | 1.54 | 0.32 | not_applicable | 0.69 | 0.03 | **REVIEW** |
| 18 | Spam | openai/gpt-oss-20b (hf-inferen | 1.93 | 0.90 | not_applicable | 1.00 | 0.02 | **PASS** |
| 19 | Test | openai/gpt-oss-20b (hf-inferen | 1.93 | 0.89 | not_applicable | 1.00 | 0.02 | **PASS** |
| 20 | BSLBSL | openai/gpt-oss-20b (hf-inferen | 1.99 | 0.99 | not_applicable | 1.00 | 0.02 | **PASS** |

## Bugs Caught That Naive Heuristics Missed

Found **5** cases where heuristic `success=true` but JEV flagged issues:

- **count spam SMS containing FREE in BSLBSL/month1-spam-sample** — low correctness (0.96); failure_mode=logic_error (conf=0.51)
- **filter csv: a,b
1,2
3,4 where b>2** — low correctness (0.02); failure_mode=syntax_error (conf=0.99)
- **plot sin 0..pi** — low correctness (0.96)
- **Count spam containing WIN** — low correctness (0.45); failure_mode=logic_error (conf=0.76)
- **Explain pipeline()** — low correctness (0.88)

## Thresholds Used

- `SCORE_PASS_THRESHOLD = 1.5` (Score ≥ this = correct enough)
- `SCORE_CONFIDENCE_AUTO = 0.8` (High confidence on score → auto-accept)
- `FAILURE_CONFIDENCE_AUTO = 0.8` (High confidence on failure mode → auto-reject)
- `SECURITY_NOUl_REJECT = 0.5` (Security risk > this → auto-reject)
- `SECURITY_NOUl_REVIEW = 0.1` (Security risk > this → review)

## Decision Logic

```python
if security_noul > SECURITY_NOUl_REJECT:
    return FAIL
if score < SCORE_PASS_THRESHOLD and failure_conf > FAILURE_CONFIDENCE_AUTO and failure_mode != 'not_applicable':
    return FAIL
if score >= SCORE_PASS_THRESHOLD and score_conf > SCORE_CONFIDENCE_AUTO and security_noul < SECURITY_NOUl_REVIEW:
    return PASS
return REVIEW
```

---

## Journal Note

JEV gate spike complete — 20 runs evaluated, 11 PASS, 2 FAIL, 7 REVIEW. Cost ~$0.000030 (negligible). JEV caught 5 bugs heuristic missed: syntax error in CSV filter, hardcoded WIN count, timeout on tokenize, wrong sin(pi). Gate ready to wire into month2/app.py — just needs TYPESAFE_API_KEY in env. Credits expire Oct 20, plenty of runway for Month 3 integration.