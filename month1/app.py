"""Month 1 — ai-lab-m1-chatbot (private test)

Dual mode: tries HF Inference API (HuggingFaceTB/SmolLM2-135M-Instruct) first,
falls back to local distilgpt2 pipeline if providers not enabled / offline.
Private Space: BSLBSL/ai-lab-m1-chatbot — Phase 3 test, Phase 4 will flip public.
Dataset: https://huggingface.co/datasets/BSLBSL/month1-spam-sample
"""
import os
import gradio as gr

MODEL_INFERENCE = "HuggingFaceTB/SmolLM2-135M-Instruct"
MODEL_LOCAL = "distilgpt2"

_local_gen = None

def _local_generate(prompt, max_new_tokens=80):
    global _local_gen
    if _local_gen is None:
        from transformers import pipeline
        _local_gen = pipeline("text-generation", model=MODEL_LOCAL)
    out = _local_gen(prompt, max_new_tokens=max_new_tokens, num_return_sequences=1, do_sample=True, temperature=0.9)
    text = out[0]["generated_text"]
    return text[len(prompt):].strip() if text.startswith(prompt) else text.strip()

def _history_to_prompt(message, history):
    parts = []
    for item in history or []:
        try:
            if isinstance(item, dict):
                role = item.get("role")
                content = item.get("content")
                # content can be str or list of dicts
                if isinstance(content, list):
                    content = " ".join([c.get("text","") if isinstance(c, dict) else str(c) for c in content])
                content = str(content) if content is not None else ""
                if role == "user":
                    parts.append(f"User: {content}")
                elif role == "assistant":
                    parts.append(f"Assistant: {content}")
                else:
                    parts.append(f"{role}: {content}" if role else content)
            elif isinstance(item, (list, tuple)) and len(item) == 2:
                u, a = item
                # u/a can be dicts in new Gradio
                if isinstance(u, dict):
                    u = u.get("text") or u.get("content") or str(u)
                if isinstance(a, dict):
                    a = a.get("text") or a.get("content") or str(a)
                parts.append(f"User: {u}")
                parts.append(f"Assistant: {a}")
            else:
                parts.append(str(item))
        except Exception:
            parts.append(str(item))
    prompt = "\n".join(parts)
    if prompt:
        prompt += f"\nUser: {message}\nAssistant:"
    else:
        prompt = f"User: {message}\nAssistant:"
    return prompt

def respond(message, history):
    # Extract text if message is dict (multimodal)
    if isinstance(message, dict):
        message = message.get("text") or message.get("content") or str(message)
    prompt = _history_to_prompt(message, history)
    full_prompt = f"You are a helpful assistant. Be concise.\n\n{prompt}"
    token = os.environ.get("HF_TOKEN") or os.environ.get("HUGGINGFACE_TOKEN")
    # Try HF Inference first
    try:
        from huggingface_hub import InferenceClient
        client = InferenceClient(token=token) if token else InferenceClient()
        try:
            resp = client.chat_completion(
                model=MODEL_INFERENCE,
                messages=[{"role": "user", "content": str(message)}],
                max_tokens=128,
                temperature=0.7,
            )
            return resp.choices[0].message.content.strip()
        except Exception as e1:
            # fallback text_generation
            try:
                out = client.text_generation(full_prompt, model=MODEL_INFERENCE, max_new_tokens=128, temperature=0.7)
                return out.strip() if isinstance(out, str) else str(out).strip()
            except Exception as e2:
                raise Exception(f"chat {e1} / text {e2}")
    except Exception as e:
        # Local fallback - distilgpt2
        try:
            return _local_generate(prompt, max_new_tokens=80) or f"[local fallback - no output] {e}"
        except Exception as e2:
            return f"Error (inference: {e} | local: {e2})"

demo = gr.ChatInterface(
    fn=respond,
    title="ai-lab-m1-chatbot (private test)",
    description="Month 1 — HF Inference API (`HuggingFaceTB/SmolLM2-135M-Instruct`) with local `distilgpt2` fallback. Dataset: [BSLBSL/month1-spam-sample](https://huggingface.co/datasets/BSLBSL/month1-spam-sample) — Phase 3 private, Phase 4 public.",
    examples=["Hello! Who are you?", "What does spam SMS look like?", "Hugging Face is"],
)

if __name__ == "__main__":
    demo.launch(server_name="0.0.0.0", server_port=7860)
