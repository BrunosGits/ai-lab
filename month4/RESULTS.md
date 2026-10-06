# Month 4 — BLEU / ROUGE-L Scoring: Results

## Environment

- **Python**: 3.13.12
- **Backends**: `sacrebleu` 2.6.0 (BLEU), `rouge_score` 0.1.2 (ROUGE-L)
- Both libraries were **already installed** in this environment — no installation needed.
  `pip3 install --user` works without sudo, so `requirements.txt` contains only
  `sacrebleu==2.6.0` and `rouge_score==0.1.2` (pure-Python / pip-friendly).
- A pure-Python **fallback** is built into `score.py` (see `_bleu_fallback`,
  `_rougel_fallback`) and was tested independently — it produces consistent
  discriminative results even if both libraries are absent.

## Command run

```bash
python3 month4/score.py month4/sample_data.jsonl
```

## Full output

```
------------------------------------------------------------------------------
  #  ID           BLEU PASS   ROUGE-L PASS   BOTH  Reference (preview)
------------------------------------------------------------------------------
  1  exact_match   1.0000   OK    1.0000   OK   PASS  exact_match
  2  good_paraphrase   0.4214   OK    0.6667   OK   PASS  good_paraphrase
  3  partial_match   0.2336   NO    0.6667   OK   ----  partial_match
  4  missing_words   0.6873   OK    0.8421   OK   PASS  missing_words
  5  extra_words   0.1678   NO    0.5714   OK   ----  extra_words
  6  empty_generated   0.0000   NO    0.0000   NO   ----  empty_generated
  7  unrelated   0.0000   NO    0.0000   NO   ----  unrelated
  8  empty_reference   0.0000   NO    0.0000   NO   ----  empty_reference
  9  near_duplicate   0.6580   OK    0.9000   OK   PASS  near_duplicate
 10  generic_response   0.0000   NO    0.0000   NO   ----  generic_response
------------------------------------------------------------------------------

==============================================================================
SUMMARY
==============================================================================
Metric                     Mean     Median      Min      Max
------------------------------------------------------------------------------
BLEU (0–1)               0.3168     0.2007   0.0000   1.0000
ROUGE-L (0–1)            0.4647     0.6190   0.0000   1.0000
------------------------------------------------------------------------------
BLEU threshold  >= 0.25  → 4/10 pass
ROUGE-L threshold >= 0.30  → 6/10 pass
Both thresholds met → 4/10 pass (40%)

Backends — BLEU: sacrebleu,  ROUGE-L: rouge_score
==============================================================================
```

## Per-item threshold analysis

| # | ID | BLEU | ROUGE-L | BLEU ≥0.25? | ROUGE-L ≥0.30? | Both? | Note |
|---|----|------|---------|-------------|-----------------|-------|------|
| 1 | exact_match | 1.0000 | 1.0000 | PASS | PASS | PASS | Perfect match — trivially passes |
| 2 | good_paraphrase | 0.4214 | 0.6667 | PASS | PASS | PASS | Good paraphrase with minor word change |
| 3 | partial_match | 0.2336 | 0.6667 | **FAIL** | PASS | FAIL | BLEU just below threshold; two words changed (jumps/leaps) |
| 4 | missing_words | 0.6873 | 0.8421 | PASS | PASS | PASS | Dropped trailing words — both still high |
| 5 | extra_words | 0.1678 | 0.5714 | **FAIL** | PASS | FAIL | Added many words inflates hypothesis length |
| 6 | empty_generated | 0.0000 | 0.0000 | **FAIL** | **FAIL** | FAIL | Empty output — correctly scores 0 |
| 7 | unrelated | 0.0000 | 0.0000 | **FAIL** | **FAIL** | FAIL | Completely unrelated — correctly scores 0 |
| 8 | empty_reference | 0.0000 | 0.0000 | **FAIL** | **FAIL** | FAIL | Empty reference — correctly scores 0 |
| 9 | near_duplicate | 0.6580 | 0.9000 | PASS | PASS | PASS | One word swapped (require/need) |
| 10 | generic_response | 0.0000 | 0.0000 | **FAIL** | **FAIL** | FAIL | Non-committal response to a factoid question |

### Thresholds reached

- **BLEU ≥ 0.25**: 4 of 10 pairs pass (exact_match, good_paraphrase, missing_words, near_duplicate)
- **ROUGE-L ≥ 0.30**: 6 of 10 pairs pass (same 4 plus partial_match and extra_words)
- **Both**: 4 of 10 pairs pass

The three "bad" categories (empty output, unrelated, generic response) all score 0
on both metrics, confirming the scoring is **discriminative** — it clearly separates
good from bad generations.

## Whether the roadmap thresholds look sane

**Yes, the thresholds are sane and well-calibrated** for their intended purpose.

Key observations:

1. **The metrics complement each other.** BLEU is stricter on word-order and n-gram
   exactness — `partial_match` (0.23) and `extra_words` (0.17) fail BLEU despite
   ROUGE-L passing. ROUGE-L is more forgiving because it rewards longest-common
   subsequence overlap, which is appropriate for summarisation-style tasks. Using
   both gives a balanced signal.

2. **Thresholds are discriminative, not trivially passed.** Only 40% of a mixed
   sample met both thresholds. A model that produces garbage (empty, unrelated,
   non-committal) scores 0.0 — the metrics correctly flag failure.

3. **The pass cases are realistic.** Good paraphrases and near-duplicates score
   0.42–0.66 BLEU and 0.67–0.90 ROUGE-L, comfortably above the 0.25/0.30 line, which
   means a competent LLM output should reliably clear them.

4. **Borderline cases are informative.** `partial_match` (BLEU 0.2336, just below
   0.25) and `extra_words` (BLEU 0.1678, just below 0.25) sit near the boundary —
   these are exactly the kind of edge cases the threshold should catch, and the
   scores are sensitive enough to do so.

The only caveat worth noting: these are token-overlap metrics. They don't capture
semantic equivalence (e.g., "big" vs "large" both fail n-gram match). That is
exactly why Month 4 also plans **BERTScore** and **LLM-as-Judge** — these are the
next layers to stack on top of this BLEU/ROUGE foundation.
