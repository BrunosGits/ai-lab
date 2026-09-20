# Backburn — Tools Parked for Later

> Not a phase, not now. Tools evaluated and kept for when a future month needs them.
> Each row: why parked, when to try, cost, link. Try in order when Phase X asks for it.

## Parked

| Tool | Why backburn for ai-lab (6-month) | When to try | Cost | Link | JEV Use Case |
|---|---|---|---|---|---|
| CubeSandbox 11.8k MicroVM E2B | Month 2 generic-code PythonExecutor exec() in month2/app.py is enough for 85pct (17/20) free hf-inference; Cube needs KVM x86_64 kvm-ok + ~1GB control plane (CubeAPI/CubeMaster) on 51.79.71.160 40GB 11G free — overkill now | After BSLBSL/ai-lab-m2-agent public and you need 100ms Snapshot/Rollback, concurrent 50 without host 502 — e.g. Month 3 parallel evals or Month 5 RAG Volume S3 | $0 Apache 2.0 PVM | https://github.com/TencentCloud/CubeSandbox | `Score` sandbox safety (network/fs/cpu risk); `Choice` allow/deny/quarantine; `Noul` "is this code malicious?" — runtime guard |
| PDFCraft 8.4k AGPL-3.0 90+ Next.js 15 WASM | ai-lab is text/models (distilgpt2, banking77); pdfcraft is document AI — Workflow Editor 23 templates, 90+ tools (Organize 27/Edit 19/Convert 22/From 13/Optimize 8/Secure 6) — a new document track, duplicates ai-lab-summary.pdf print.css and Month 6 portfolio PDF use case at 90-tool scale; AGPL-3.0 copyleft if embedded | When Month 5 Agentic AI RAG needs PDF to vectors to Qdrant (extract tables/images via WASM before Qdrant), or Month 6 portfolio wants Merge and Compress / Report Assembly for ai-lab-summary.pdf | $0 AGPL-3.0 ghcr.io/pdfcrafttool/pdfcraft | https://github.com/PDFCraftTool/pdfcraft | `Score` extraction quality (tables, layout, text); `Choice` route to best parser (pdfplumber/pymupdf/marker); `Noul` "is this PDF corrupt?" |
| mimic 1.6k MIT uv mitmproxy | Month 2 generic-code is synthetic (fibonacci/csv filter) — no real app API yet; mimic captures your own iPhone/web app traffic (mimic record to <mac-ip>:8080 to http://mitm.it cert to mimic gen) and gives from hinge_client import Hinge without writing hinge_client.py; blocked by Certificate pinning (banking/IG) and DPoP sender-constrained tokens | When Month 3 Backend needs to call a real mobile/web app private API with no public docs (Copy as cURL/HAR not enough) — e.g. bank/delivery/social on Mac+iPhone same Wi-Fi | $0 MIT uv tool install mimic-client | https://github.com/littledivy/mimic | `Choice` pick mimic model per task; `Score` output fidelity vs original; `Noul` "is this a faithful reproduction?" |
| `typesafe-jev` | TypeSafe JEV opencode skill for structured eval | Month 3 Backend or offline dataset labeling | $0 (skill) + API usage ~$0.042/Mtok | https://docs.typesafe.ai/ | Code quality gates, dataset labeling, agent routing, backburn triage |

## Notes

- All three are tools, not phases. Revisit in Month 3 (Backend agent demo) or Month 5 (MCP/RAG).
- mimic needs Mac + iPhone same LAN + mitm.it cert trust — not for VPS headless.
- PDFCraft keep as separate Docker service via ghcr.io + Caddy handle_path /pdf* if ever integrated (avoids AGPL-3.0 embed).
- CubeSandbox needs KVM check kvm-ok + x86_64 before any install.
- typesafe-jev skill created at ~/.config/opencode/skills/typesafe-jev/; API key in Infisical /typesafe.

## Related

- [[02-LEARNING-ROADMAP/skeleton]] — active roadmap (Month 2 in progress)
- [[00-META/tags]] — #status/not-started #domain/learning
