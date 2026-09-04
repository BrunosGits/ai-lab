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

def respond(message, history):
    prompt = ""
    for u, a in history:
        prompt += f"User: {u}\nAssistant: {a}\n"
    prompt += f"User: {message}\nAssistant:"
    full_prompt = f"You are a helpful assistant. Be concise.\n\n{prompt}"
    token = os.environ.get("HF_TOKEN") or os.environ.get("HUGGINGFACE_TOKEN")
    try:
        from huggingface_hub import InferenceClient
        client = InferenceClient(token=token) if token else InferenceClient()
        try:
            resp = client.chat_completion(
                model=MODEL_INFERENCE,
                messages=[{"role": "user", "content": message}],
                max_tokens=128,
                temperature=0.7,
            )
            return resp.choices[0].message.content.strip()
        except Exception:
            out = client.text_generation(full_prompt, model=MODEL_INFERENCE, max_new_tokens=128, temperature=0.7, stop_sequences=["\nUser:"])
            return out.strip() if isinstance(out, str) else str(out).strip()
    except Exception as e:
        try:
            return _local_generate(prompt, max_new_tokens=80) or f"[local fallback] {e}"
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
