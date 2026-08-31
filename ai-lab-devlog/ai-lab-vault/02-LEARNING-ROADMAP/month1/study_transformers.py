"""Month 1 — Transformers study: pipeline(), AutoTokenizer, AutoModelForCausalLM.

Runs a small causal LM (distilgpt2) to demonstrate the three core HF APIs.
"""
import time

MODEL = "distilgpt2"

print("=" * 60)
print("1) pipeline()  — high-level text generation")
print("=" * 60)
from transformers import pipeline

t0 = time.time()
gen = pipeline("text-generation", model=MODEL)
print(f"model loaded in {time.time()-t0:.1f}s")

out = gen("Hugging Face is", max_new_tokens=25, num_return_sequences=1)
print("input -> 'Hugging Face is'")
print("output ->", out[0]["generated_text"])

print()
print("=" * 60)
print("2) AutoTokenizer — tokenize a string, inspect ids")
print("=" * 60)
from transformers import AutoTokenizer

t0 = time.time()
tok = AutoTokenizer.from_pretrained(MODEL)
print(f"tokenizer loaded in {time.time()-t0:.1f}s, vocab={len(tok)}")

text = "The quick brown fox jumps"
enc = tok(text, return_tensors="pt")
print("text:", text)
print("input_ids:", enc["input_ids"].tolist())
print("attention_mask:", enc["attention_mask"].tolist())
print("tokens:", tok.convert_ids_to_tokens(enc["input_ids"][0]))
print("decode back:", repr(tok.decode(enc["input_ids"][0])))
print("pad_token:", tok.pad_token, "eos_token:", tok.eos_token)

print()
print("=" * 60)
print("3) AutoModelForCausalLM — manual generate() (no pipeline)")
print("=" * 60)
from transformers import AutoModelForCausalLM

t0 = time.time()
model = AutoModelForCausalLM.from_pretrained(MODEL)
print(f"model loaded in {time.time()-t0:.1f}s, params={sum(p.numel() for p in model.parameters())/1e6:.0f}M")

prompt = "Once upon a time,"
inputs = tok(prompt, return_tensors="pt")
ids = model.generate(**inputs, max_new_tokens=25, do_sample=True, temperature=0.9)
print("prompt:", prompt)
print("generated:", tok.decode(ids[0], skip_special_tokens=True))
