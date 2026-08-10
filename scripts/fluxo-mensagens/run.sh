#!/usr/bin/env bash
set -euo pipefail

# Converts a Miro-style flowchart PDF (tiny fonts, spatial layout only) into:
#   1. an interactive HTML (overview + per-flow map + reading view)
#   2. a multi-page reading PDF
#
# Usage:
#   ./run.sh <input.pdf> [output-prefix]
# Example:
#   ./run.sh "Fluxo de Mensagens Receptivas.pdf" fluxo
#     -> fluxo.html, fluxo-leitura.html, fluxo-leitura.pdf

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "usage: $0 <input.pdf> [output-prefix]" >&2
  exit 1
fi

INPUT="$1"
PREFIX="${2:-${INPUT%.pdf}}"

if [[ ! -f "$INPUT" ]]; then
  echo "input not found: $INPUT" >&2
  exit 1
fi

PYTHON="${HERE}/.venv/bin/python"
if [[ ! -x "$PYTHON" ]]; then
  echo "setting up virtualenv…"
  python3 -m venv "${HERE}/.venv"
  "${HERE}/.venv/bin/pip" install --quiet -r "${HERE}/requirements.txt"
fi

TMP_GRAPH="${TMPDIR:-/tmp}/fluxo-graph.json"
TMP_TREE="${TMPDIR:-/tmp}/fluxo-tree.json"

echo "1/4 extracting graph…"
"$PYTHON" "${HERE}/extract_graph.py" "$INPUT" "$TMP_GRAPH"

echo "2/4 extracting real directed edges (vectors)…"
"$PYTHON" "${HERE}/extract_tree.py" "$INPUT" "$TMP_TREE"

echo "3/4 rendering interactive HTML (with arrows)…"
"$PYTHON" "${HERE}/render_html.py" "$TMP_GRAPH" "${PREFIX}.html" --tree "$TMP_TREE"

echo "4/4 rendering reading PDF…"
"$PYTHON" "${HERE}/render_pdf.py" "${PREFIX}.html" "${PREFIX}-leitura.html" --pdf "${PREFIX}-leitura.pdf"

echo "done:"
echo "  ${PREFIX}.html"
echo "  ${PREFIX}-leitura.html"
echo "  ${PREFIX}-leitura.pdf"
