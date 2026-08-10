"""Extract boxes and labels from a Miro-style flowchart PDF into graph.json.

The original PDF is a single-page Miro export with tiny (0.1pt) text. Every
box is drawn with a Bold font, every floating label with a Regular font.
This script rebuilds structured data from spatial positions only:

- nodes:  the Bold text boxes (steps of the flow)
- labels: Regular text, split into edge labels ("Opção X", "Todas as opções"),
          "Fim" badges and everything else
- edges:  inferred by picking, for each edge label, the two nearest boxes

Usage:
    python extract_graph.py <input.pdf> <output.json>
"""

import argparse
import json
import math
import re

from pdfminer.high_level import extract_pages
from pdfminer.layout import LTChar, LTTextContainer, LTTextLine


def is_bold(element):
    for line in element:
        if not isinstance(line, LTTextLine):
            continue
        for ch in line:
            if isinstance(ch, LTChar):
                return 'Bold' in ch.fontname
    return False


def dist_to_node(p, n):
    dx = max(n['x0'] - p[0], 0, p[0] - n['x1'])
    dy = max(n['y0'] - p[1], 0, p[1] - n['y1'])
    return math.hypot(dx, dy)


def dist_seg(p, a, b):
    ax, ay = a
    bx, by = b
    px, py = p
    dx, dy = bx - ax, by - ay
    if dx == 0 and dy == 0:
        return math.hypot(px - ax, py - ay)
    t = ((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy)
    t = max(0, min(1, t))
    cx, cy = ax + t * dx, ay + t * dy
    return math.hypot(px - cx, py - cy)


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('pdf', help='path to the flowchart PDF')
    ap.add_argument('out', help='path for the output graph.json')
    args = ap.parse_args()

    nodes = []
    labels = []
    for page in extract_pages(args.pdf):
        for element in page:
            if not isinstance(element, LTTextContainer):
                continue
            x0, y0, x1, y1 = element.bbox
            lines = [l.strip() for l in element.get_text().split('\n') if l.strip()]
            if not lines:
                continue
            rec = dict(x0=x0, y0=y0, x1=x1, y1=y1,
                       cx=(x0 + x1) / 2, cy=(y0 + y1) / 2,
                       first=lines[0], lines=lines)
            (nodes if is_bold(element) else labels).append(rec)

    def cat_label(l):
        t = l['first']
        if re.match(r'^Fim\b', t):
            return 'fim'
        if re.match(r'^(Todas as opções|Opç\w+)', t, re.I):
            return 'edge'
        return 'other'

    edge_labels = [l for l in labels if cat_label(l) == 'edge']
    fim_labels = [l for l in labels if cat_label(l) == 'fim']

    pair_map = {}
    for L in edge_labels:
        p = (L['cx'], L['cy'])
        cand = sorted(range(len(nodes)), key=lambda i: dist_to_node(p, nodes[i]))[:10]
        best = None
        for i in cand:
            for j in cand:
                if i >= j:
                    continue
                s = dist_seg(p, (nodes[i]['cx'], nodes[i]['cy']),
                             (nodes[j]['cx'], nodes[j]['cy'])) \
                    + 0.6 * (dist_to_node(p, nodes[i]) + dist_to_node(p, nodes[j]))
                if best is None or s < best[0]:
                    best = (s, i, j)
        if best:
            pair_map.setdefault((min(best[1], best[2]), max(best[1], best[2])), []).append(L['first'])

    edges = [(i, j, pair_map[(i, j)]) for (i, j) in pair_map]

    graph = dict(
        nodes=[dict(id=k, **n) for k, n in enumerate(nodes)],
        edges=edges,
        edge_labels=[dict(x0=l['x0'], y0=l['y0'], text=l['first']) for l in edge_labels],
        fim_labels=[dict(x0=l['x0'], y0=l['y0'], text=l['first']) for l in fim_labels],
    )
    with open(args.out, 'w') as f:
        json.dump(graph, f, ensure_ascii=False)
    print(f"nodes: {len(nodes)}  edge_labels: {len(edge_labels)}  "
          f"fim: {len(fim_labels)}  edge pairs: {len(edges)}")


if __name__ == '__main__':
    main()
