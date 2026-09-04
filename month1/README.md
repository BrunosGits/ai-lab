---
title: ai-lab-m1-chatbot
sdk: gradio
app_file: app.py
pinned: false
tags:
  - month1
  - chatbot
  - inference-api
  - smollm2
datasets:
  - BSLBSL/month1-spam-sample
---

# ai-lab-m1-chatbot (private test — Month 1)

> **Phase 3 private test.** Inference API chatbot (`HuggingFaceTB/SmolLM2-135M-Instruct`) via `huggingface_hub.InferenceClient` + Gradio `ChatInterface`.
> Public dataset: [BSLBSL/month1-spam-sample](https://huggingface.co/datasets/BSLBSL/month1-spam-sample) (50 spam SMS rows). Phase 4 will flip this Space public and wire the demo link into the roadmap.

## Run locally
```bash
# HF token lives in Infisical at /huggingface "Access Token" (space in key)
tok=$(infisical secrets --plain --projectId=7ea02e25-4a83-47a1-a90e-985ef82f3eb6 --env=prod --path=/huggingface 2>/dev/null | grep -i "Access Token" | cut -d= -f2-)
HF_TOKEN="$tok" ~/ai-lab/month1/.venv/bin/python ~/ai-lab/month1/app.py
# open http://localhost:7860
```

## Files
- `app.py` — Gradio + Inference API
- `requirements.txt` — Space deps
- `study_transformers.py`, `study_datasets.py` — Month 1 study (pipeline, AutoTokenizer, AutoModelForCausalLM, datasets filter/publish)

## Related
- Vault: `ai-lab-devlog/ai-lab-vault/02-LEARNING-ROADMAP/month1-transformers-datasets.md`
- Roadmap: `ai-lab-devlog/roadmap.md` Month 1
