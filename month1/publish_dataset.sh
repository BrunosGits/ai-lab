source ~/.profile 2>/dev/null
infisical run --token="$INFISICAL_TOKEN" --domain=https://app.infisical.com/api --projectId="7ea02e25-4a83-47a1-a90e-985ef82f3eb6" --env=prod --path=/huggingface --recursive -- sh -c '
  tok=$(infisical secrets --plain --projectId="7ea02e25-4a83-47a1-a90e-985ef82f3eb6" --env=prod --path=/huggingface 2>/dev/null | grep -i "Access Token" | cut -d= -f2-)
  if [ -z "$tok" ]; then echo "ERROR: could not fetch HF token" >&2; exit 1; fi
  export HF_TOKEN="$tok"
  echo "HF_TOKEN len=${#HF_TOKEN}, prefix=$(printf %s "$HF_TOKEN" | cut -c1-3)"
  cd ~/ai-lab/ai-lab-devlog/ai-lab-vault/02-LEARNING-ROADMAP/month1
  ~/ai-lab/month1/.venv/bin/python study_datasets.py
'
