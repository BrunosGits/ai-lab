"""Month 2 — SmolAgents study: CodeAgent + PythonExecutorTool + DatasetTool"""
print("="*60)
print("1) imports — smolagents + tools")
print("="*60)
try:
    from smolagents import CodeAgent, PythonExecutorTool, InferenceClientModel
    print("smolagents ok:", CodeAgent, PythonExecutorTool)
    print("DatasetTool will be app.DatasetTool (reads BSLBSL/month1-spam-sample)")
    print("Try: agent = CodeAgent(tools=[PythonExecutorTool(), DatasetTool()], model=InferenceClientModel('HuggingFaceTB/SmolLM2-1.7B-Instruct'))")
except Exception as e:
    print("smolagents not installed (pip install smolagents):", e)

print()
print("="*60)
print("2) free tier — 1.7B via hf-inference (needs HF_TOKEN + toggle ON)")
print("="*60)
print("Toggle: https://huggingface.co/settings/inference-providers -> hf-inference ON (free)")
print("Test: from huggingface_hub import InferenceClient; InferenceClient().chat_completion(model='HuggingFaceTB/SmolLM2-1.7B-Instruct', messages=[{'role':'user','content':'hi'}])")

print()
print("="*60)
print("3) local 360M — TransformersModel fallback (~700MB CPU)")
print("="*60)
print("from smolagents import TransformersModel; m=TransformersModel('HuggingFaceTB/SmolLM2-360M-Instruct')")
