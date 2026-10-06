"""Model registry — swap models without changing app code.

Selection:
  MODEL=<alias>                 picks a model from the registry below
  EXTRA_MODELS='{"alias": {"model_id": "...", "provider": "hf-inference|local"}}'
                                adds/overrides registry entries at runtime (no code change)

Providers:
  hf-inference  -> smolagents.InferenceClientModel (HF Inference Providers, e.g. gpt-oss via Groq)
  groq          -> same chat-completions calling convention via huggingface_hub.InferenceClient
  local         -> smolagents.TransformersModel (CPU/GPU local weights)
  heuristic     -> no LLM, direct-exec fallback built into app.py

To add a model permanently, add one entry to MODELS below. To add one
temporarily (e.g. on the VPS), set EXTRA_MODELS — no edit to app.py needed.
"""
import json
import os

# alias -> {"model_id": <provider model id>, "provider": <provider key>, "label": <display name>}
MODELS = {
    # default — preserves Month 2 behavior (gpt-oss via HF Inference Providers / Groq key)
    "gpt-oss-20b": {
        "model_id": "openai/gpt-oss-20b",
        "provider": "hf-inference",
        "label": "openai/gpt-oss-20b (hf-inference via Groq)",
    },
    "gpt-oss-120b": {
        "model_id": "openai/gpt-oss-120b",
        "provider": "hf-inference",
        "label": "openai/gpt-oss-120b (hf-inference via Groq)",
    },
    "gpt-oss-safeguard-20b": {
        "model_id": "openai/gpt-oss-safeguard-20b",
        "provider": "hf-inference",
        "label": "openai/gpt-oss-safeguard-20b (hf-inference via Groq)",
    },
    # local fallback (~700MB, CPU)
    "smollm2-360m-instruct": {
        "model_id": "HuggingFaceTB/SmolLM2-360M-Instruct",
        "provider": "local",
        "label": "HuggingFaceTB/SmolLM2-360M-Instruct (local)",
    },
    # no LLM at all — heuristic/direct-exec only
    "heuristic": {
        "model_id": None,
        "provider": "heuristic",
        "label": "fallback-exec (no LLM)",
    },
}

DEFAULT_ALIAS = "gpt-oss-20b"

# Order used when the requested model cannot be built.
FALLBACK_ORDER = ["gpt-oss-20b", "gpt-oss-120b", "gpt-oss-safeguard-20b", "smollm2-360m-instruct", "heuristic"]


def registry() -> dict:
    """Registry = built-in MODELS overlaid with EXTRA_MODELS env JSON."""
    reg = dict(MODELS)
    extra = os.environ.get("EXTRA_MODELS")
    if extra:
        try:
            for alias, spec in json.loads(extra).items():
                spec = dict(spec)
                spec.setdefault("label", f"{spec.get('model_id')} ({spec.get('provider')})")
                reg[alias] = spec
        except Exception as e:
            print(f"[models] EXTRA_MODELS ignored (bad JSON): {e}")
    return reg


def _build(spec: dict):
    """Build a smolagents model from a registry spec. Returns (label, model|None)."""
    provider = spec["provider"]
    model_id = spec.get("model_id")
    label = spec.get("label") or f"{model_id} ({provider})"

    if provider == "heuristic":
        return label, None

    if provider in ("hf-inference", "groq"):
        token = os.environ.get("HF_TOKEN") or os.environ.get("HUGGINGFACE_TOKEN")
        if not token:
            raise RuntimeError("HF_TOKEN/HUGGINGFACE_TOKEN not set")
        from smolagents import InferenceClientModel
        return label, InferenceClientModel(model_id=model_id, token=token)

    if provider == "local":
        from smolagents import TransformersModel
        return label, TransformersModel(model_id=model_id, device_map="auto")

    raise ValueError(f"unknown provider: {provider}")


def select_model():
    """Select model by MODEL env var; fall back through FALLBACK_ORDER on failure.

    Returns (label, model_id_or_None, provider, model_or_None).
    """
    reg = registry()
    requested = os.environ.get("MODEL", DEFAULT_ALIAS)
    chain = [requested] + [a for a in FALLBACK_ORDER if a != requested]
    for alias in chain:
        spec = reg.get(alias)
        if spec is None:
            print(f"[models] unknown MODEL alias '{alias}' — known: {sorted(reg)}")
            continue
        try:
            label, model = _build(spec)
            return label, spec.get("model_id"), spec["provider"], model
        except Exception as e:
            print(f"[models] {alias} ({spec.get('model_id')}) failed: {e}")
    return "fallback-exec (no LLM)", None, "heuristic", None
