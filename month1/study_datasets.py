"""Month 1 — Datasets study: load_dataset, filter, publish one.

Downloads a small dataset (sms_spam), inspects it, builds a filtered subset,
and (optionally) pushes it to the Hugging Face Hub.
"""
import os
import time

from datasets import load_dataset, Dataset

print("=" * 60)
print("1) load_dataset — fetch + inspect")
print("=" * 60)
t0 = time.time()
ds = load_dataset("ucirvine/sms_spam")["train"]
print(f"loaded in {time.time()-t0:.1f}s, rows={len(ds)}")
print("features:", ds.features)
# peek at a few rows
for i in range(3):
    print(f"\nrow {i}:")
    for k, v in ds[i].items():
        print(f"  {k}: {v}")

print()
print("=" * 60)
print("2) filter — build a subset")
print("=" * 60)
# sms_spam: label 1 = spam, 0 = ham
print("label counts:", {lbl: sum(1 for r in ds if r["label"] == lbl) for lbl in [0, 1]})
spam = ds.filter(lambda r: r["label"] == 1)
print("spam rows:", len(spam))

# take a small deterministic subset to keep the published dataset tiny
sample = spam.select(range(min(50, len(spam))))
print("filtered sample rows:", len(sample))
print("first filtered:", sample[0]["sms"])

print()
print("=" * 60)
print("3) publish — push to HF Hub")
print("=" * 60)
token = os.environ.get("HF_TOKEN")
repo = os.environ.get("HF_DATASET_REPO", "BSLBSL/month1-spam-sample")
if not token:
    print("No HF_TOKEN env set — skipping publish (run via `infisical run` to inject it).")
    raise SystemExit(0)

sample.push_to_hub(repo, token=token, private=False)
print(f"published dataset to https://huggingface.co/datasets/{repo}")
