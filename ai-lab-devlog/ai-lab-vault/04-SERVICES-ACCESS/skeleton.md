# Services & Access

> Map of every service used by the AI Lab, how to reach it, and where its
> credentials live. **Store names and Infisical paths only — never token
> values, keys, passwords, IPs, or usernames.**

## Services

| Service | Login method | Where the key lives (Infisical) |
|---------|--------------|---------------------------------|
| OVH VPS | web dashboard | `/vps/...` |
| Infisical (machine identity) | universal-auth client-id + secret | Infisical itself |
| VPS (SSH) | key auth | key on computer + server |
| GitHub | SSH key + `gh` CLI | key on computer |
| Hugging Face | access token | `/huggingface/...` |
| Langfuse Cloud | public/secret keys | `/langfuse/...` |
| OpenCode Zen | Zen API key | `/opencode-zen/...` |
| OpenRouter | API key | `/openrouter/...` |
| Trello | API key + secret + token | `/trello/...` |
| NVIDIA | NVAPI key | `/nvidia/...` |

> **Rule:** Never write actual secret values in this vault. If you need a value,
> fetch it then from Infisical — never commit it.

## Related

- [[00-META/tags]]
