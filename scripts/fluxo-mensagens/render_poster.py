"""Split each flow map into a faithful grid of A4 landscape poster pages.

Keeps the exact rectangle structure of the original Miro export: every box is
drawn at its real position and size, scaled by --scale, and the scaled canvas
is sliced into a regular grid of pages. Each page shows its crop with the
real arrows (from tree.json) and a mini-map that highlights which tile the
page covers, so the whole diagram reads as a cut-out poster.

Usage:
    python render_poster.py <interactive.html> <tree.json> <poster.html> \
        [--pdf out.pdf] [--scale 30] [--text-mult 1.0] [--flows f1,f2] \
        [--chrome /path/to/chrome]
"""

import argparse
import html
import json
import math
import os
import re
import shutil
import subprocess

HERE = os.path.dirname(os.path.abspath(__file__))
CHROME_CANDIDATES = [
    '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    '/Applications/Chromium.app/Contents/MacOS/Chromium',
]

PAGE_W, PAGE_H = 842.0, 595.0      # A4 landscape, points
MARGIN = 10.0
HEADER_H = 40.0
MAP_W = PAGE_W - 2 * MARGIN
MAP_H = PAGE_H - 2 * MARGIN - HEADER_H


def find_chrome():
    for p in CHROME_CANDIDATES:
        if os.path.exists(p):
            return p
    return shutil.which('chromium') or shutil.which('google-chrome') or shutil.which('chrome')


def load_payload(interactive_html):
    m = re.search(r'window\.__PAYLOAD__ = (\{.*?\});\n</script>',
                  open(interactive_html).read(), re.S)
    if not m:
        raise SystemExit('payload not found in ' + interactive_html)
    return json.loads(m.group(1))


def esc(s):
    return html.escape(str(s), quote=True)


def seg_rect_intersect(p1, p2, rx0, ry0, rx1, ry1):
    """First intersection of segment p1->p2 with the rectangle boundary,
    assuming p1 is inside the rectangle. Returns the exit point or None."""
    dx = p2[0] - p1[0]
    dy = p2[1] - p1[1]
    t = None
    if dx != 0:
        for x in (rx0, rx1):
            t0 = (x - p1[0]) / dx
            if t0 > 0 and (t is None or t0 < t):
                t = t0
    if dy != 0:
        for y in (ry0, ry1):
            t0 = (y - p1[1]) / dy
            if t0 > 0 and (t is None or t0 < t):
                t = t0
    if t is None:
        return None
    return (p1[0] + dx * t, p1[1] + dy * t)


def poster_layout(flow_nodes, scale):
    pad = 5
    min_x = min(n['x'] for n in flow_nodes)
    max_x = max(n['x1'] for n in flow_nodes)
    min_y = min(n['y'] for n in flow_nodes)
    max_y = max(n['y1'] for n in flow_nodes)
    origin_x = min_x - pad
    origin_y = max_y + pad
    w = (max_x - min_x + 2 * pad) * scale
    h = (max_y - min_y + 2 * pad) * scale
    return dict(origin_x=origin_x, origin_y=origin_y, w=w, h=h,
                min_x=min_x, max_x=max_x, min_y=min_y, max_y=max_y)


def to_poster(p, layout, scale):
    return ((p[0] - layout['origin_x']) * scale,
            (layout['origin_y'] - p[1]) * scale)


def node_poster(n, layout, scale):
    x0, y0 = to_poster((n['x'], n['y1']), layout, scale)
    x1, y1 = to_poster((n['x1'], n['y']), layout, scale)
    return x0, y0, x1, y1


def build_svg(tile, layout, scale, flow, nodes, by_id, arrows, edge_labels,
              fim_labels, colors, text_mult, flow_colors):
    c, r = tile['c'], tile['r']
    ox = c * MAP_W
    oy = r * MAP_H
    out = []
    fsz = 0.10 * scale * text_mult

    # arrows first (drawn under the boxes)
    for a in arrows:
        src = by_id.get(a['src'])
        dst = by_id.get(a['dst'])
        if not src or not dst:
            continue
        if not (tile['boxes'] & {a['src'], a['dst']}):
            continue
        sx0, sy0, sx1, sy1 = node_poster(src, layout, scale)
        tx0, ty0, tx1, ty1 = node_poster(dst, layout, scale)
        p_s = ((sx0 + sx1) / 2, (sy0 + sy1) / 2)
        p_d = ((tx0 + tx1) / 2, (ty0 + ty1) / 2)
        if 'ax' in a:
            p_t = to_poster((a['ax'], a['ay']), layout, scale)
        else:
            p_t = p_d
        start = seg_rect_intersect(p_s, p_t, sx0, sy0, sx1, sy1)
        if start is None:
            start = p_s
        color = flow_colors.get(src['flow'], '#64748b')
        out.append(f'<line x1="{start[0]-ox:.2f}" y1="{start[1]-oy:.2f}" '
                   f'x2="{p_t[0]-ox:.2f}" y2="{p_t[1]-oy:.2f}" '
                   f'stroke="{color}" stroke-width="{max(0.8, 0.05*scale):.2f}" '
                   f'opacity="0.8"/>')
        # arrowhead at the tip
        dx = p_t[0] - start[0]
        dy = p_t[1] - start[1]
        ln = math.hypot(dx, dy)
        if ln > 1e-6:
            ux, uy = dx / ln, dy / ln
            L = max(2.5, 0.10 * scale)
            W = L * 0.55
            bx = p_t[0] - ux * L
            by = p_t[1] - uy * L
            px = -uy
            py = ux
            pts = [(p_t[0], p_t[1]),
                   (bx + px * W, by + py * W),
                   (bx - px * W, by - py * W)]
            pts = ' '.join(f'{x-ox:.2f},{y-oy:.2f}' for x, y in pts)
            out.append(f'<polygon points="{pts}" fill="{color}" opacity="0.85"/>')

    # boxes
    for nid in tile['boxes']:
        n = by_id[nid]
        x0, y0, x1, y1 = node_poster(n, layout, scale)
        if x1 - ox < 0 or y1 - oy < 0 or x0 - ox > MAP_W or y0 - oy > MAP_H:
            continue
        color = flow_colors.get(n['flow'], '#64748b')
        out.append(f'<rect x="{x0-ox:.2f}" y="{y0-oy:.2f}" width="{x1-x0:.2f}" '
                   f'height="{y1-y0:.2f}" fill="#ffffff" fill-opacity="0.92" '
                   f'stroke="{color}" stroke-width="{max(0.8, 0.04*scale):.2f}"/>')
        lines = [n['first']] + n['body']
        cy = (y0 + y1) / 2 - ((len(lines) - 1) / 2) * fsz
        for ln in lines:
            out.append(f'<text x="{(x0+x1)/2-ox:.2f}" y="{cy-oy:.2f}" '
                       f'font-family="Helvetica,Arial,sans-serif" font-size="{fsz:.2f}" '
                       f'text-anchor="middle" fill="#0f172a">{esc(ln)}</text>')
            cy += fsz

    # edge labels (floating "Opção X" texts)
    for l in edge_labels:
        p = to_poster((l['x'], l['y']), layout, scale)
        if 0 <= p[0] - ox <= MAP_W and 0 <= p[1] - oy <= MAP_H:
            out.append(f'<text x="{p[0]-ox:.2f}" y="{p[1]-oy:.2f}" '
                       f'font-family="Helvetica,Arial,sans-serif" font-size="{max(1.6, fsz*0.8):.2f}" '
                       f'text-anchor="middle" fill="#b45309">{esc(l["text"])}</text>')

    for l in fim_labels:
        p = to_poster((l['x'], l['y']), layout, scale)
        if 0 <= p[0] - ox <= MAP_W and 0 <= p[1] - oy <= MAP_H:
            out.append(f'<text x="{p[0]-ox:.2f}" y="{p[1]-oy:.2f}" '
                       f'font-family="Helvetica,Arial,sans-serif" font-size="{fsz:.2f}" '
                       f'font-weight="bold" text-anchor="middle" fill="#475569">{esc(l["text"])}</text>')

    return ('<svg class="map" width="%.0f" height="%.0f" viewBox="0 0 %.0f %.0f">%s</svg>'
            % (MAP_W, MAP_H, MAP_W, MAP_H, ''.join(out)))


def build_minimap(layout, cols, rows, c, r, color):
    mm_w, mm_h = 150.0, 34.0
    sw = mm_w - 2
    sh = mm_h - 2
    sx = layout['w'] / cols / max(1e-9, layout['w'])
    out = [f'<svg class="mini" width="{mm_w:.0f}" height="{mm_h:.0f}">']
    out.append(f'<rect x="0" y="0" width="{mm_w}" height="{mm_h}" fill="#fff" '
               f'stroke="#cbd5e1" stroke-width="0.6"/>')
    cell_w = sw / cols
    cell_h = sh / rows
    for rr in range(rows):
        for cc in range(cols):
            fill = color if (rr == r and cc == c) else '#e2e8f0'
            out.append(f'<rect x="{1+cc*cell_w:.2f}" y="{1+rr*cell_h:.2f}" '
                       f'width="{cell_w-0.4:.2f}" height="{cell_h-0.4:.2f}" '
                       f'fill="{fill}" stroke="#94a3b8" stroke-width="0.3"/>')
    out.append(f'<text x="{mm_w/2}" y="{mm_h+6:.2f}" font-size="5.5" '
               f'text-anchor="middle" fill="#475569">linha {r+1} · coluna {c+1}</text>')
    out.append('</svg>')
    return ''.join(out)


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('interactive')
    ap.add_argument('tree')
    ap.add_argument('out')
    ap.add_argument('--pdf', help='output PDF (needs Chrome)')
    ap.add_argument('--scale', type=float, default=30.0)
    ap.add_argument('--text-mult', type=float, default=1.0,
                    help='multiplier for the box text size')
    ap.add_argument('--flows', help='comma separated subset of flows')
    ap.add_argument('--chrome', help='path to the Chrome binary')
    ap.add_argument('--title',
                    default='Fluxo de Mensagens Receptivas · WhatsApp · Sempre em Frente')
    args = ap.parse_args()

    data = load_payload(args.interactive)
    tree = json.load(open(args.tree))
    by_id = {n['id']: n for n in data['nodes']}
    tree_arrows = {e['src']: {e['dst']: e['arrow']} for e in tree['edges']}

    # merge tree anchors into the payload arrows
    arrow_by_pair = {}
    for a in data.get('arrows', []):
        pair = (a['src'], a['dst'])
        ta = tree_arrows.get(a['src'], {}).get(a['dst'])
        if ta:
            a['ax'], a['ay'] = ta[0], ta[1]
        arrow_by_pair[pair] = a

    selected = args.flows.split(',') if args.flows else data['flows']
    flows = [f for f in data['flows'] if f in selected]

    arrow_index = list(arrow_by_pair.values())
    sheets = []
    page_no = 0
    total_pages = 0

    # cover sheet
    cover = ['<section class="sheet cover">',
             f'<h1>{esc(args.title)}</h1>',
             '<p>Mapa paginado a partir do fluxograma original. Cada fluxo é '
             'recortado numa grade de páginas A4 paisagem mantendo a posição '
             'exata dos retângulos e das setas. As páginas de cada fluxo '
             'formam um pôster: siga linha a linha, esquerda para a direita.',
             '</p>']
    cover.append('<table>')
    for f in flows:
        name = data['flowLabels'].get(f, f)
        color = data['flowColors'].get(f, '#64748b')
        ids = data['readingOrder'][f]
        ns = [by_id[i] for i in ids]
        lay = poster_layout(ns, args.scale)
        cols = math.ceil(lay['w'] / MAP_W)
        rows = math.ceil(lay['h'] / MAP_H)
        n = cols * rows
        cover.append(f'<tr><td><span class="dot" style="background:{color}"></span>'
                     f'<b>{esc(name)}</b></td><td>{len(ids)} passos</td>'
                     f'<td>grade {cols}×{rows}</td><td>{n} páginas</td></tr>')
        total_pages += n
    cover.append('</table>')
    cover.append(f'<p class="total">{total_pages} páginas no total.</p>')
    cover.append('</section>')
    sheets.append(''.join(cover))

    # flow sections
    for f in flows:
        name = data['flowLabels'].get(f, f)
        color = data['flowColors'].get(f, '#64748b')
        ids = data['readingOrder'][f]
        ns = [by_id[i] for i in ids]
        lay = poster_layout(ns, args.scale)
        cols = math.ceil(lay['w'] / MAP_W)
        rows = math.ceil(lay['h'] / MAP_H)
        flow_tiles = []
        for r in range(rows):
            for c in range(cols):
                tile = dict(r=r, c=c)
                tile['boxes'] = set()
                for i in ids:
                    n = by_id[i]
                    x0, y0, x1, y1 = node_poster(n, lay, args.scale)
                    if (x1 >= c * MAP_W and x0 <= (c + 1) * MAP_W and
                            y1 >= r * MAP_H and y0 <= (r + 1) * MAP_H):
                        tile['boxes'].add(i)
                flow_tiles.append(tile)
        for tile in flow_tiles:
            page_no += 1
            svg = build_svg(tile, lay, args.scale, f, [by_id[i] for i in ids],
                            by_id, arrow_index, data.get('edgeLabels', []),
                            data.get('fimLabels', []), None, args.text_mult,
                            data['flowColors'])
            mini = build_minimap(lay, cols, rows, tile['r'], tile['c'], color)
            sheets.append(
                f'<section class="sheet">'
                f'<div class="head" style="border-color:{color}">'
                f'<div><b>{esc(name)}</b> · linha {tile["r"]+1} de {rows}, '
                f'coluna {tile["c"]+1} de {cols}'
                f'<span class="sub">página {page_no} de {total_pages}</span></div>'
                f'{mini}</div>'
                f'<div class="mapbox">{svg}</div>'
                f'</section>')

    tpl = """<!DOCTYPE html>
<html lang="pt-BR"><head><meta charset="utf-8">
<title>__TITLE__</title>
<style>
@page { size: A4 landscape; margin: 0; }
*{box-sizing:border-box}
body{font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Arial,sans-serif;
     color:#0f172a;margin:0}
.sheet{width:842pt;height:595pt;page-break-after:always;overflow:hidden;padding:10pt;position:relative}
.sheet.cover{display:flex;flex-direction:column;justify-content:center;padding:40pt}
.sheet.cover h1{font-size:22pt;margin:0 0 10pt}
.sheet.cover p{font-size:10.5pt;color:#334155;max-width:520pt}
.sheet.cover table{border-collapse:collapse;margin-top:14pt;font-size:10.5pt}
.sheet.cover td{padding:4pt 12pt 4pt 0;border-bottom:1px solid #e2e8f0}
.sheet.cover .dot{display:inline-block;width:8pt;height:8pt;border-radius:50%;margin-right:6pt}
.sheet.cover .total{font-weight:600;margin-top:12pt}
.head{display:flex;justify-content:space-between;align-items:flex-start;
     border-bottom:2.5pt solid;padding-bottom:5pt;margin-bottom:5pt;font-size:11pt}
.head .sub{display:block;font-size:8.5pt;color:#64748b;font-weight:400}
.mapbox{width:822pt;height:539pt}
.map{width:822pt;height:539pt}
</style></head><body>
<!--__SHEETS__-->
</body></html>"""
    final = tpl.replace('__TITLE__', esc(args.title)).replace('<!--__SHEETS__-->', ''.join(sheets))
    with open(args.out, 'w') as f:
        f.write(final)
    print(f"written {args.out} ({len(final)} bytes, {len(sheets)} pages, scale {args.scale})")

    if args.pdf:
        chrome = args.chrome or find_chrome()
        if not chrome:
            raise SystemExit('Chrome not found; pass --chrome /path/to/Google\\ Chrome')
        url = 'file://' + os.path.abspath(args.out)
        subprocess.run([chrome, '--headless=new', '--disable-gpu', '--no-first-run',
                        '--no-pdf-header-footer', '--virtual-time-budget=4000',
                        '--print-to-pdf=' + args.pdf, url], check=True)
        print(f"written {args.pdf}")


if __name__ == '__main__':
    main()
