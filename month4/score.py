#!/usr/bin/env python3
"""
Month 4 — LLM Evaluation Lab: scoring foundation
================================================

Computes BLEU and ROUGE-L between ground-truth reference text and generated
text.

Primary path  — uses the installed ``sacrebleu`` (BLEU) and ``rouge_score``
(ROUGE-L) libraries.

Defensive path — if either library is missing, an inline pure-Python fallback
implementation is used so the script never crashes with ``ImportError``.

Usage
-----
    # Score every {reference, generated} pair in a JSONL file
    python3 score.py sample_data.jsonl

    # Score a single pair on the command line
    python3 score.py --single "reference text" "generated text"

JSONL format — each line is a JSON object with at least:
    {"reference": "...", "generated": "..."}
Optionally an ``"id"`` field; if absent the line number is used.

Roadmap thresholds (Month 4):  BLEU >= 0.25,  ROUGE-L >= 0.30
"""

from __future__ import annotations

import json
import math
import statistics
import sys
from dataclasses import dataclass
from typing import List, Tuple

# ── roadmap thresholds ──────────────────────────────────────────────
BLEU_THRESHOLD = 0.25
ROUGE_THRESHOLD = 0.30

# ── graceful library import with fallback ───────────────────────────
try:
    from sacrebleu.metrics import BLEU as _SacreBLEU

    _BLEU_BACKEND = "sacrebleu"
except Exception:  # pragma: no cover
    _SacreBLEU = None
    _BLEU_BACKEND = "fallback"

try:
    from rouge_score import rouge_scorer as _RougeScorer

    _ROUGE_BACKEND = "rouge_score"
except Exception:  # pragma: no cover
    _RougeScorer = None
    _ROUGE_BACKEND = "fallback"


# ════════════════════════════════════════════════════════════════════
#  Fallback implementations (pure Python, no external deps)
# ════════════════════════════════════════════════════════════════════


def _tokenize(text: str) -> List[str]:
    """Simple whitespace + lowercase tokenizer."""
    return text.lower().strip().split()


def _ngrams(tokens: List[str], n: int) -> List[str]:
    return [tuple(tokens[i : i + n]) for i in range(len(tokens) - n + 1)]


def _modified_ngram_precision(
    ref_tokens: List[str], hyp_tokens: List[str], n: int
) -> float:
    """Modified n-gram precision with clipping."""
    ref_ngrams = _ngrams(ref_tokens, n)
    hyp_ngrams = _ngrams(hyp_tokens, n)
    if len(hyp_ngrams) == 0:
        return 0.0
    ref_counts: dict = {}
    for g in ref_ngrams:
        ref_counts[g] = ref_counts.get(g, 0) + 1
    hyp_counts: dict = {}
    for g in hyp_ngrams:
        hyp_counts[g] = hyp_counts.get(g, 0) + 1
    # clip
    matched = 0
    for g, c in hyp_counts.items():
        matched += min(c, ref_counts.get(g, 0))
    return matched / len(hyp_ngrams)


def _brevity_penalty(ref_len: int, hyp_len: int) -> float:
    if hyp_len == 0:
        return 0.0
    ratio = hyp_len / ref_len if ref_len > 0 else 0.0
    if ratio > 1.0:
        return 1.0
    return math.exp(1.0 - 1.0 / ratio) if ratio > 0 else 0.0


def _bleu_fallback(reference: str, hypothesis: str) -> float:
    """Simple 4-gram BLEU with brevity penalty (0–100 scale)."""
    ref_tokens = _tokenize(reference)
    hyp_tokens = _tokenize(hypothesis)
    ref_len = len(ref_tokens)
    hyp_len = len(hyp_tokens)

    if hyp_len == 0 or ref_len == 0:
        return 0.0

    ps = [_modified_ngram_precision(ref_tokens, hyp_tokens, n) for n in (1, 2, 3, 4)]
    # geometric mean (skip zero precisions via log)
    log_ps = [math.log(p) for p in ps if p > 0]
    if not log_ps:
        return 0.0
    bp = _brevity_penalty(ref_len, hyp_len)
    score = bp * math.exp(sum(log_ps) / len(log_ps))
    return score * 100.0


def _lcs_length(a: List[str], b: List[str]) -> int:
    """Longest Common Subsequence length (token level) via DP."""
    m, n = len(a), len(b)
    # Use two-row DP for memory efficiency
    prev = [0] * (n + 1)
    curr = [0] * (n + 1)
    for i in range(1, m + 1):
        curr[0] = 0
        for j in range(1, n + 1):
            if a[i - 1] == b[j - 1]:
                curr[j] = prev[j - 1] + 1
            else:
                curr[j] = max(prev[j], curr[j - 1])
        prev, curr = curr, prev
    return prev[n]


def _rougel_fallback(reference: str, hypothesis: str) -> float:
    """Simple ROUGE-L F1 (0–1 scale)."""
    ref_tokens = _tokenize(reference)
    hyp_tokens = _tokenize(hypothesis)
    if not ref_tokens or not hyp_tokens:
        return 0.0
    lcs = _lcs_length(ref_tokens, hyp_tokens)
    recall = lcs / len(ref_tokens)
    precision = lcs / len(hyp_tokens)
    if recall + precision == 0:
        return 0.0
    return 2.0 * recall * precision / (recall + precision)


# ════════════════════════════════════════════════════════════════════
#  Unified scorer interface
# ════════════════════════════════════════════════════════════════════


def compute_bleu(reference: str, hypothesis: str) -> float:
    """Return BLEU score on a 0–1 scale."""
    if not hypothesis.strip() or not reference.strip():
        return 0.0
    if _SacreBLEU is not None:
        try:
            metric = _SacreBLEU(effective_order=True)
            score = metric.sentence_score(hypothesis, [reference])
            return score.score / 100.0  # sacrebleu returns 0–100
        except Exception:
            return _bleu_fallback(reference, hypothesis) / 100.0
    return _bleu_fallback(reference, hypothesis) / 100.0


def compute_rougel(reference: str, hypothesis: str) -> float:
    """Return ROUGE-L F1 score on a 0–1 scale."""
    if not hypothesis.strip() or not reference.strip():
        return 0.0
    if _RougeScorer is not None:
        try:
            scorer = _RougeScorer.RougeScorer(
                rouge_types=["rougeL"], use_stemmer=True
            )
            scores = scorer.score(reference, hypothesis)
            return scores["rougeL"].fmeasure
        except Exception:
            return _rougel_fallback(reference, hypothesis)
    return _rougel_fallback(reference, hypothesis)


# ════════════════════════════════════════════════════════════════════
#  Data structures
# ════════════════════════════════════════════════════════════════════


@dataclass
class Result:
    idx: int
    ref_id: str
    bleu: float
    rougel: float

    @property
    def bleu_pass(self) -> bool:
        return self.bleu >= BLEU_THRESHOLD

    @property
    def rougel_pass(self) -> bool:
        return self.rougel >= ROUGE_THRESHOLD

    @property
    def both_pass(self) -> bool:
        return self.bleu_pass and self.rougel_pass


# ════════════════════════════════════════════════════════════════════
#  Main scoring logic
# ════════════════════════════════════════════════════════════════════


def score_pair(reference: str, hypothesis: str) -> Tuple[float, float]:
    return compute_bleu(reference, hypothesis), compute_rougel(reference, hypothesis)


def score_jsonl(path: str) -> List[Result]:
    results: List[Result] = []
    with open(path, "r", encoding="utf-8") as f:
        for idx, line in enumerate(f, 1):
            line = line.strip()
            if not line:
                continue
            obj = json.loads(line)
            ref = obj.get("reference", "")
            hyp = obj.get("generated", "")
            # accept aliases
            if not ref:
                ref = obj.get("ref", "")
            if not hyp:
                hyp = obj.get("gen", "")
            pair_id = obj.get("id", str(idx))
            bleu, rougel = score_pair(ref, hyp)
            results.append(
                Result(idx=idx, ref_id=str(pair_id), bleu=bleu, rougel=rougel)
            )
    return results


def print_table(results: List[Result]) -> None:
    """Print a results table with per-item scores and pass/fail."""
    # Column headers
    sep = "-" * 78
    print(sep)
    print(
        f"{'#':>3}  {'ID':<8} {'BLEU':>8} {'PASS' if True else '':>4}  "
        f"{'ROUGE-L':>8} {'PASS':>4}  {'BOTH':>5}  Reference (preview)"
    )
    print(sep)
    for r in results:
        bleu_str = f"{r.bleu:.4f}"
        rouge_str = f"{r.rougel:.4f}"
        bp = "OK" if r.bleu_pass else "NO"
        rp = "OK" if r.rougel_pass else "NO"
        both = "PASS" if r.both_pass else "----"
        ref_preview = r.ref_id if r.ref_id.isdigit() else r.ref_id
        print(
            f"{r.idx:>3}  {str(r.ref_id):<8} {bleu_str:>8} {bp:>4}  "
            f"{rouge_str:>8} {rp:>4}  {both:>5}  {ref_preview:<30.30}"
        )
    print(sep)


def print_summary(results: List[Result]) -> None:
    """Print summary statistics (mean, median, pass rate)."""
    if not results:
        print("No results to summarize.")
        return

    bleus = [r.bleu for r in results]
    rouges = [r.rougel for r in results]
    passes = [1 if r.both_pass else 0 for r in results]

    print("\n" + "=" * 78)
    print("SUMMARY")
    print("=" * 78)
    print(f"{'Metric':<20} {'Mean':>10} {'Median':>10} {'Min':>8} {'Max':>8}")
    print("-" * 78)
    print(
        f"{'BLEU (0–1)':<20} {statistics.mean(bleus):>10.4f} "
        f"{statistics.median(bleus):>10.4f} {min(bleus):>8.4f} {max(bleus):>8.4f}"
    )
    print(
        f"{'ROUGE-L (0–1)':<20} {statistics.mean(rouges):>10.4f} "
        f"{statistics.median(rouges):>10.4f} {min(rouges):>8.4f} {max(rouges):>8.4f}"
    )
    print("-" * 78)
    print(
        f"BLEU threshold  >= {BLEU_THRESHOLD:.2f}  → "
        f"{sum(r.bleu_pass for r in results)}/{len(results)} pass"
    )
    print(
        f"ROUGE-L threshold >= {ROUGE_THRESHOLD:.2f}  → "
        f"{sum(r.rougel_pass for r in results)}/{len(results)} pass"
    )
    print(
        f"Both thresholds met → {sum(passes)}/{len(results)} pass "
        f"({statistics.mean(passes) * 100:.0f}%)"
    )
    print(f"\nBackends — BLEU: {_BLEU_BACKEND},  ROUGE-L: {_ROUGE_BACKEND}")
    print("=" * 78)


def run_single(reference: str, hypothesis: str) -> None:
    bleu, rougel = score_pair(reference, hypothesis)
    result = Result(idx=1, ref_id="single", bleu=bleu, rougel=rougel)
    print_table([result])
    print_summary([result])


def main(argv: List[str]) -> int:
    if len(argv) < 2:
        print(__doc__)
        return 1

    if argv[1] == "--single":
        if len(argv) < 4:
            print("Usage: python3 score.py --single <reference> <generated>")
            return 1
        reference = argv[2]
        hypothesis = argv[3]
        run_single(reference, hypothesis)
        return 0

    # JSONL mode
    path = argv[1]
    results = score_jsonl(path)
    if not results:
        print(f"No valid entries found in {path}")
        return 1
    print_table(results)
    print_summary(results)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
