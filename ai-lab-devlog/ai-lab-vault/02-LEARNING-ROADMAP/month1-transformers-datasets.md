---
tags: [domain/learning, month/1]
month: 1
model: distilgpt2
---

# Month 1: Transformers + Datasets

> The Month 1 study block: HF **Transformers** (`pipeline`, `AutoTokenizer`,
> `AutoModelForCausalLM`) and **Datasets** (download, filter, publish).
> Working scripts live in `../../month1/` (canonical `month1/` at repo root; vault copy stays in `02-LEARNING-ROADMAP/month1/`).

## Goal

Learn the core Hugging Face `transformers` and `datasets` APIs on the VPS, and
complete the first "publish" of the learning roadmap (a public dataset).

## What I used

- Python 3.13.5 venv, CPU-only `torch`, `transformers`, `datasets`, `huggingface_hub`
- Model: `distilgpt2` (82M params, ~340MB) — fits the VPS CPU/RAM
- Dataset: `ucirvine/sms_spam` (5,574 rows)

## Environment setup

```bash
python3 -m venv .venv
./.venv/bin/pip install torch --index-url https://download.pytorch.org/whl/cpu
./.venv/bin/pip install transformers datasets huggingface_hub
```

## 1) pipeline() — high-level text generation

```python
from transformers import pipeline
gen = pipeline("text-generation", model="distilgpt2")
gen("Hugging Face is", max_new_tokens=25)
# -> "Hugging Face is a simple, simple, and useful tool that can help you identify..."
```

- `pipeline` bundles tokenizer + model + post-processing into one object.
- One call gets a result; pass `num_return_sequences` for more.

## 2) AutoTokenizer — strings <-> ids

```python
from transformers import AutoTokenizer
tok = AutoTokenizer.from_pretrained("distilgpt2")
tok("The quick brown fox jumps", return_tensors="pt")
# {'input_ids': tensor([[464, 2068, 7586, 21831, 18045]]),
#  'attention_mask': tensor([[1, 1, 1, 1, 1]])}
tok.convert_ids_to_tokens([464, 2068, 7586, 21831, 18045])
# ['The', 'Ġquick', 'Ġbrown', 'Ġfox', 'Ġjumps']   # Ġ = space (BPE)
tok.decode([464, 2068])  # 'The quick'
```

- Tokenizer decides vocabulary; BPE uses a `Ġ` marker for leading spaces.
- `return_tensors="pt"` gives tensors ready for a model.
- distilgpt2 has no pad_token (only `<|endoftext|>` as eos).

## 3) AutoModelForCausalLM — manual generate()

```python
from transformers import AutoTokenizer, AutoModelForCausalLM
tok = AutoTokenizer.from_pretrained("distilgpt2")
model = AutoModelForCausalLM.from_pretrained("distilgpt2")
inputs = tok("Once upon a time,", return_tensors="pt")
ids = model.generate(**inputs, max_new_tokens=25, do_sample=True, temperature=0.9)
tok.decode(ids[0], skip_special_tokens=True)
```

- Give a manual path when you need control `pipeline` hides (temperature, sampling).
- Model caches weights separately from the tokenizer.

## 4) Datasets — download, filter, publish

```python
from datasets import load_dataset
ds = load_dataset("ucirvine/sms_spam")["train"]   # 5574 rows
# features: {'sms': string, 'label': ClassLabel['ham','spam']}

spam = ds.filter(lambda r: r["label"] == 1)        # 747 rows
sample = spam.select(range(50))                    # deterministic 50-row subset

sample.push_to_hub("BSLBSL/month1-spam-sample", token=HF_TOKEN)
```

- Published: https://huggingface.co/datasets/BSLBSL/month1-spam-sample (50 rows, ~10.5 kB)
- `filter` keeps rows where the callable returns True.

## Notes / gotchas

- **HF username is `BSLBSL`**, not `BrunosGits` — the fine-grained token scopes `repo.write` to `BSLBSL`, so push to `BSLBSL/...`.
- HF token lives in Infisical at `/huggingface` under the key `Access Token` (has a space, so it can't be injected as a normal env var by `infisical run` — fetch it with `infisical secrets --plain` instead).
- torch CPU wheel is large; we freed ~5G of VPS disk first.
- HF cache lands in `~/.cache/huggingface` (~340MB for distilgpt2 + sms_spam).

## Artifacts / Published

- Dataset: `BSLBSL/month1-spam-sample` (public, 50 rows)
- Scripts: `../../month1/study_transformers.py`, `../../month1/study_datasets.py`
- Space: `BSLBSL/ai-lab-m1-chatbot` (public, sdk static, host https://bslbsl-ai-lab-m1-chatbot.static.hf.space) — browser `Xenova/distilgpt2` WASM via `@xenova/transformers` (real pipeline, no server), ~340MB first load then cached
- VPS demo: `https://51.79.71.160.sslip.io/chat/` and `http://51.79.71.160/chat/` (Gradio `month1/app.py` host mode, distilgpt2 + SmolLM2 fallback, Caddy handle_path /chat, Lets Encrypt cert)
- Repo: `month1/app.py`, `month1/index.html`, `month1/Dockerfile` (CPU torch), `month1/requirements.txt`

## Status — 2026-09-03

- Root README restored (was moved to ai-lab-devlog, GitHub showed no front page)
- Month 1 study scripts consolidated to `../../month1/` (vault copy kept)
- Chatbot dual mode built (HF Inference + local), hit Inference Providers not enabled (all models 400) and Gradio 402 PRO, chose hybrid static plus host
- Fixed disk ninety seven percent (CUDA 3.25GB -> CPU 0.8GB, prune ten gig), fixed firewall INPUT ordering and Caddy handle_path plus host.docker.internal, obtained Lets Encrypt cert
- Fixed Gradio six dict history crash, added direct IP handling for VPN, then switched static to browser WASM so it always works on phone and VPN

## Next

- Enable HF Inference Providers if you want the browser mock to call the router, or keep browser WASM as primary deliverable and mark Month 1 done in roadmap and skeleton

## Related

- [[02-LEARNING-ROADMAP/skeleton]]
- [[00-META/tags]]
