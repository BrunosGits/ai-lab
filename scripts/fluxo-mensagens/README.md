# fluxo-mensagens

Converts a Miro-style flowchart PDF into readable deliverables. The original
PDF is a single-page Miro export where every box uses a ~0.1pt Bold font and
every floating label a Regular font, so the file is unreadable when printed.
This pipeline rebuilds the layout from spatial positions and renders it big.

Outputs:

- **Interactive HTML** — overview map colored by flow, per-flow spatial maps
  with zoom, a verbatim reading view, search and a detail panel.
- **Reading PDF** — A4, one section per flow, every box as a card with its
  text and the "Opção X →" destinations.

## Usage

```
./run.sh <input.pdf> [output-prefix]
```

This creates a `.venv`, installs `requirements.txt` and produces
`<prefix>.html`, `<prefix>-leitura.html` and `<prefix>-leitura.pdf`.

Steps can also be run individually:

```
python extract_graph.py <input.pdf> <graph.json>          # PDF → data
python extract_tree.py  <input.pdf> <tree.json>           # PDF → directed edges
python render_html.py  <graph.json> <out.html> --tree tree.json
python render_pdf.py   <out.html> <print.html> --pdf out.pdf
```

`render_html.py` splits the diagram into flows by default on X bands and a set
of entry node ids (matching the original diagram). Point `--bands` and
`--entry-ids` elsewhere when a new diagram lays its flows differently.

## How it works

- `extract_graph.py` walks the PDF pages, tags text containers as boxes (Bold
  font) or labels (Regular font), and infers edges by pairing each
  "Opção X / Todas as opções" label with its two nearest boxes. Writes
  `graph.json`.
- `extract_tree.py` reads the vector layer (the PDF does store real connectors
  and arrowheads, drawn twice as fill + stroke). It removes the box outlines,
  dedupes the doubled segments, then recovers each directed edge from its
  arrowhead triangle: the triangle apex points at the target box, the dangling
  line end points at the source box. Writes `tree.json` with directed edges and
  arrow anchor points.
- `render_html.py` classifies each box (pergunta, termo, pesquisa, equipe,
  fim, nota, mensagem), groups boxes into flows, builds a parent tree by BFS
  from the entry nodes and embeds everything in a standalone HTML. With
  `--tree tree.json` the real directed edges replace the inferred ones and the
  maps draw actual arrowheads.
- `render_pdf.py` renders the reading version and calls headless Chrome to
  produce the PDF.

Note: `extract_graph.py` alone infers arrows from label positions, best
treated as hints. Pass the `tree.json` from `extract_tree.py` to show the real
connectors recovered from the vector layer. The current run recovers 487
directed edges across 500 of the 506 boxes (0 bidirectional conflicts), up
from 274: the arrowhead search uses a fine grid, short connectors are kept,
and connectors that sit between two box outlines are resolved by picking the
arrowhead vertex nearest a box as the target and the farthest point as the
source. Known caveat: the few "Fim → Sem pesquisa" arrows are reversed in the
extraction and flipped to "Sem pesquisa → Fim" because the arrowhead points up
into a decision diamond, not into the Fim box. The reading order per flow
(y position, then x) is stable.
