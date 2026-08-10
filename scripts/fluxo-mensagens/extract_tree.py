"""Reconstruct the tree (nodes + directed edges) from a Miro flowchart PDF.

The PDF stores each box, connector and arrowhead as vector shapes (plus the
tiny Bold text we already extract). This script combines both sources:

- boxes   = Bold text containers (the 506 steps)
- shapes  = closed loops that surround a box (the drawn box outline)
- edges   = open polyline clusters; each end is matched to the box it touches
- arrows  = small closed loops (triangles) merged into a connector, whose apex
            points at the target box

Output is graph.json with nodes (from Bold text) plus a `shapes` map and a
list of directed edges with their polyline paths for rendering.

Usage:
    python extract_tree.py <input.pdf> <output.json>
"""

import argparse
import json
import math
import re
from collections import Counter, defaultdict

from pdfminer.high_level import extract_pages
from pdfminer.layout import LTChar, LTLine, LTTextContainer, LTTextLine, LTCurve

EPS = 0.6


# ---------- low level: all vector segments ----------
def extract_segments(pdf_path):
    segs = []
    for page in extract_pages(pdf_path):
        for el in page:
            if isinstance(el, LTLine):
                segs.append(((el.x0, el.y0), (el.x1, el.y1)))
            elif isinstance(el, LTCurve):
                pts = list(el.pts)
                for i in range(len(pts) - 1):
                    segs.append((pts[i], pts[i + 1]))
    return segs


def cluster_segments(segs):
    parent = list(range(len(segs)))

    def find(x):
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x

    def union(a, b):
        ra, rb = find(a), find(b)
        if ra != rb:
            parent[rb] = ra

    end2idx = {}
    for i, (p1, p2) in enumerate(segs):
        for p in (p1, p2):
            key = (round(p[0] / EPS), round(p[1] / EPS))
            if key in end2idx:
                union(end2idx[key], i)
            else:
                end2idx[key] = i
    clusters = defaultdict(list)
    for i in range(len(segs)):
        clusters[find(i)].append(segs[i])
    return list(clusters.values())


def clen(c):
    return sum(math.hypot(p2[0] - p1[0], p2[1] - p1[1]) for p1, p2 in c)


def bbox(c):
    xs = [p for s in c for p in (s[0][0], s[1][0])]
    ys = [p for s in c for p in (s[0][1], s[1][1])]
    return (min(xs), min(ys), max(xs), max(ys))


def vertex_degrees(c):
    keyed = []
    for p1, p2 in c:
        for p in (p1, p2):
            k = (round(p[0] / EPS), round(p[1] / EPS))
            if not keyed or keyed[-1][0] != k:
                keyed.append((k, p))
    deg = Counter(k for k, _ in keyed)
    return keyed, deg


def is_closed(c):
    _, deg = vertex_degrees(c)
    return sum(1 for k in deg if deg[k] % 2 == 1) == 0


# ---------- boxes (Bold text) ----------
def is_bold(element):
    for line in element:
        if not isinstance(line, LTTextLine):
            continue
        for ch in line:
            if isinstance(ch, LTChar):
                return 'Bold' in ch.fontname
    return False


def extract_boxes(pdf_path):
    boxes = []
    for page in extract_pages(pdf_path):
        for element in page:
            if not isinstance(element, LTTextContainer) or not is_bold(element):
                continue
            lines = [l.strip() for l in element.get_text().split('\n') if l.strip()]
            if not lines:
                continue
            x0, y0, x1, y1 = element.bbox
            boxes.append(dict(x0=x0, y0=y0, x1=x1, y1=y1,
                              cx=(x0 + x1) / 2, cy=(y0 + y1) / 2,
                              first=lines[0], lines=lines))
    return boxes


# ---------- small geometry helpers ----------
def dist_point_to_box(p, b, pad=0.0):
    dx = max(b['x0'] - pad - p[0], 0, p[0] - b['x1'] - pad)
    dy = max(b['y0'] - pad - p[1], 0, p[1] - b['y1'] - pad)
    return math.hypot(dx, dy)


def box_contains(b, x0, y0, x1, y1):
    return x0 <= b['x0'] and y0 <= b['y0'] and x1 >= b['x1'] and y1 >= b['y1']


def find_cycle(cluster, eps=0.08):
    """Find the small closed loop inside a connector cluster, if any.

    A connector is a dangling path (the line) attached at one vertex to a
    closed loop (the arrowhead triangle). Arrowheads are tiny, so the loop
    search uses a fine grid. Returns the loop's bbox and vertices, or None.
    """
    pts = []
    for p1, p2 in cluster:
        pts.append(p1)
        pts.append(p2)
    unique = {}
    for p in pts:
        key = (round(p[0] / eps), round(p[1] / eps))
        unique.setdefault(key, p)

    adj = defaultdict(set)
    edgekeys = set()
    for p1, p2 in cluster:
        k1 = (round(p1[0] / eps), round(p1[1] / eps))
        k2 = (round(p2[0] / eps), round(p2[1] / eps))
        if k1 == k2:
            continue
        adj[k1].add(k2)
        adj[k2].add(k1)
        edgekeys.add((min(k1, k2), max(k1, k2)))

    loops = []
    for k1 in adj:
        nbrs = sorted(adj[k1])
        for i in range(len(nbrs)):
            k2 = nbrs[i]
            for k3 in nbrs[i + 1:]:
                if (min(k2, k3), max(k2, k3)) in edgekeys:
                    xs = [unique[k1][0], unique[k2][0], unique[k3][0]]
                    ys = [unique[k1][1], unique[k2][1], unique[k3][1]]
                    if (max(xs) - min(xs)) <= 6 and (max(ys) - min(ys)) <= 6:
                        loops.append(dict(keys=(k1, k2, k3),
                                          bbox=(min(xs), min(ys), max(xs), max(ys))))
    if not loops:
        return None
    loop = min(loops, key=lambda l: (l['bbox'][2] - l['bbox'][0]) * (l['bbox'][3] - l['bbox'][1]))
    return loop


def apex_of_cycle(cluster, cycle, far_from, eps=0.08):
    """Tip of the arrowhead: the loop vertex farthest from the connector end."""
    keyed = {}
    for p1, p2 in cluster:
        for p in (p1, p2):
            keyed.setdefault((round(p[0] / eps), round(p[1] / eps)), p)
    loop_verts = [keyed[k] for k in cycle['keys']]
    apex = max(loop_verts, key=lambda p: math.hypot(p[0] - far_from[0],
                                                    p[1] - far_from[1]))
    return apex


def all_cycles(cluster, maxsz=3.0, eps=0.03):
    """Return all small closed loops (arrowheads) inside a connector cluster.

    Arrowhead triangles can be tiny (the base can be ~0.1 pt wide), so the
    fine grid eps must be smaller than the smallest triangle.
    """
    unique = {}
    for p1, p2 in cluster:
        for p in (p1, p2):
            unique.setdefault((round(p[0] / eps), round(p[1] / eps)), p)

    adj = defaultdict(set)
    edgekeys = set()
    for p1, p2 in cluster:
        k1 = (round(p1[0] / eps), round(p1[1] / eps))
        k2 = (round(p2[0] / eps), round(p2[1] / eps))
        if k1 == k2:
            continue
        adj[k1].add(k2)
        adj[k2].add(k1)
        edgekeys.add((min(k1, k2), max(k1, k2)))

    loops = []
    for k1 in adj:
        nbrs = sorted(adj[k1])
        for i in range(len(nbrs)):
            k2 = nbrs[i]
            for k3 in nbrs[i + 1:]:
                if (min(k2, k3), max(k2, k3)) in edgekeys:
                    xs = [unique[k1][0], unique[k2][0], unique[k3][0]]
                    ys = [unique[k1][1], unique[k2][1], unique[k3][1]]
                    if (max(xs) - min(xs)) <= maxsz and (max(ys) - min(ys)) <= maxsz:
                        loops.append(dict(keys=(k1, k2, k3),
                                          bbox=(min(xs), min(ys), max(xs), max(ys))))
    seen = set()
    out = []
    for cy in loops:
        ks = frozenset(cy['keys'])
        if ks in seen:
            continue
        seen.add(ks)
        out.append(cy)
    return out


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('pdf')
    ap.add_argument('out')
    args = ap.parse_args()

    boxes = extract_boxes(args.pdf)
    segs = extract_segments(args.pdf)
    print('raw segments:', len(segs))

    # detect node outlines on the raw clusters (doubled copies make the
    # corners connect), then rebuild a clean connector-only segment set
    clusters_raw = cluster_segments(segs)
    shapes = {}
    outline_idx = set()
    arrowheads = []
    for ci, c in enumerate(clusters_raw):
        if not is_closed(c):
            continue
        x0, y0, x1, y1 = bbox(c)
        if (x1 - x0) > 8 or (y1 - y0) > 8:
            continue
        n = min(range(len(boxes)),
                key=lambda i: math.hypot(boxes[i]['cx'] - (x0 + x1) / 2,
                                        boxes[i]['cy'] - (y0 + y1) / 2))
        if box_contains(boxes[n], x0, y0, x1, y1):
            shapes[n] = (x0, y0, x1, y1)
            outline_idx.add(ci)
        else:
            arrowheads.append((x0, y0, x1, y1))
    print('boxes:', len(boxes), 'shapes:', len(shapes), 'arrowheads:', len(arrowheads))

    # connectors and arrowheads are drawn twice (fill + stroke), so dedupe;
    # this does NOT break outlines because we already removed them
    segs_conn = []
    for ci, c in enumerate(clusters_raw):
        if ci not in outline_idx:
            segs_conn.extend(c)
    uniq = set((min(p1, p2), max(p1, p2)) for p1, p2 in segs_conn)
    clusters2 = cluster_segments(list(uniq))
    print('connector clusters:', len(clusters2))

    # effective box geometry: shape bbox if we have it, else the text bbox
    def eff_box(i):
        if i in shapes:
            x0, y0, x1, y1 = shapes[i]
            return dict(x0=x0, y0=y0, x1=x1, y1=y1, cx=(x0 + x1) / 2, cy=(y0 + y1) / 2)
        return boxes[i]

    def nearest_box(p, pad=0.0):
        best = (1e9, None)
        for i in range(len(boxes)):
            d = dist_point_to_box(p, eff_box(i), pad)
            if d < best[0]:
                best = (d, i)
        return best

    edges = []          # dict: src, dst, path[], arrow
    for c in clusters2:
        if clen(c) < 0.4:
            continue
        cycs = all_cycles(c)
        if not cycs:
            continue
        keyed, deg = vertex_degrees(c)
        far = [p for k, p in keyed if deg[k] == 1]
        loop_pts = {}
        for p1, p2 in c:
            for p in (p1, p2):
                loop_pts.setdefault((round(p[0] / 0.03), round(p[1] / 0.03)), p)
        for cy in cycs:
            verts = [loop_pts[k] for k in cy['keys']]
            if len(verts) < 3:
                continue
            if far:
                # arrowhead merged with its line: the apex points into the
                # target box, the dangling end points back at the source
                apex = max(verts, key=lambda v: min(math.hypot(v[0] - f[0], v[1] - f[1])
                                                    for f in far))
                src_p = max(far, key=lambda f: math.hypot(f[0] - apex[0], f[1] - apex[1]))
            else:
                # short connector merged between two box outlines: pick the
                # loop vertex nearest a box as the apex (points into target),
                # the box farthest from it is the source
                apex = min(verts, key=lambda v: nearest_box(v)[0])
                src_p = max(loop_pts.values(),
                            key=lambda p: math.hypot(p[0] - apex[0], p[1] - apex[1]))
            d1, i1 = nearest_box(src_p)
            d2, i2 = nearest_box(apex)
            if i1 == i2:
                continue
            edges.append(dict(src=i1, dst=i2, path=[src_p, apex], arrow=apex))

    # standalone arrowheads: the line is a separate cluster whose dangling
    # end lands on the triangle base
    open_clusters = [c for c in clusters2 if not is_closed(c) and clen(c) >= 1.0]
    matched_keys = set()
    for c in clusters2:
        if clen(c) < 1.0 or is_closed(c):
            continue
        cycs = all_cycles(c)
        if not cycs:
            continue
        keyed, deg = vertex_degrees(c)
        if any(deg[k] == 1 for k in keyed):
            continue
        loop_pts = {}
        for p1, p2 in c:
            for p in (p1, p2):
                loop_pts.setdefault((round(p[0] / 0.03), round(p[1] / 0.03)), p)
        for cy in cycs:
            verts = [loop_pts[k] for k in cy['keys']]
            if len(verts) < 3:
                continue
            dists = [(math.hypot(verts[i][0] - verts[j][0], verts[i][1] - verts[j][1]), i, j)
                     for i in range(3) for j in range(i + 1, 3)]
            d, bi, bj = max(dists)
            apex = verts[3 - bi - bj]
            base_mid = ((verts[bi][0] + verts[bj][0]) / 2, (verts[bi][1] + verts[bj][1]) / 2)
            best = (2.0, None)
            for oc in open_clusters:
                kd, odeg = vertex_degrees(oc)
                for k, p in kd:
                    if odeg[k] != 1:
                        continue
                    dd = math.hypot(p[0] - base_mid[0], p[1] - base_mid[1])
                    if dd < best[0]:
                        best = (dd, oc)
            if best[1] is None:
                continue
            kd, odeg = vertex_degrees(best[1])
            far = [p for k, p in kd if odeg[k] == 1]
            src_p = max(far, key=lambda f: math.hypot(f[0] - base_mid[0], f[1] - base_mid[1]))
            d1, i1 = nearest_box(src_p)
            d2, i2 = nearest_box(apex)
            if i1 == i2:
                continue
            key = (min(i1, i2), max(i1, i2))
            if key in matched_keys:
                continue
            matched_keys.add(key)
            edges.append(dict(src=i1, dst=i2, path=[src_p, apex], arrow=apex))

    # dedupe by box pair
    by_pair = {}
    for e in edges:
        key = (min(e['src'], e['dst']), max(e['src'], e['dst']))
        by_pair.setdefault(key, e)
    edges = list(by_pair.values())

    # "Fim -> Sem pesquisa" edges are reversed: the arrowhead points up into a
    # decision diamond, the line to Fim is unarrowed. Fim boxes are terminal.
    present = {(e['src'], e['dst']) for e in edges}
    for e in list(edges):
        src, dst = e['src'], e['dst']
        if boxes[src]['first'].startswith('Fim') and \
           boxes[dst]['first'].startswith(('Sem pesquisa', 'Opção 2 - Sem pesquisa')) and \
           (dst, src) not in present:
            e['src'], e['dst'] = dst, src
            present.discard((src, dst))
            present.add((dst, src))
    print('edges:', len(edges))

    deg = Counter()
    for e in edges:
        deg[e['src']] += 1
        deg[e['dst']] += 1
    print('nodes touched:', len(deg), '/', len(boxes))

    out = dict(nodes=[dict(id=i, **b) for i, b in enumerate(boxes)],
               edges=[dict(src=e['src'], dst=e['dst'], path=e['path'], arrow=e['arrow'])
                      for e in edges],
               arrowheads=[dict(x=(a[0] + a[2]) / 2, y=(a[1] + a[3]) / 2) for a in arrowheads])
    with open(args.out, 'w') as f:
        json.dump(out, f, ensure_ascii=False)
    print('written', args.out)


if __name__ == '__main__':
    main()
