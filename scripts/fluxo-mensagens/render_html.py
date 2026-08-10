"""Render an interactive HTML from graph.json.

Groups the boxes into flows. By default the original diagram is split on X
bands (the flows are laid out left to right) and a few entry boxes form their
own "entrada" group. Both settings can be overridden for other diagrams.

Pass --tree tree.json (produced by extract_tree.py) to replace the inferred
links with the real directed edges recovered from the PDF vectors. Each edge
then carries the arrowhead anchor point, and the frontend draws the arrow.

Usage:
    python render_html.py <graph.json> <output.html>
    python render_html.py <graph.json> <output.html> --bands 200,400 --entry-ids 10,11
    python render_html.py <graph.json> <output.html> --tree tree.json
"""

import argparse
import collections
import html
import json
import os
import re
from collections import defaultdict, deque

HERE = os.path.dirname(os.path.abspath(__file__))

DEFAULT_FLOWS = ['paciente-cimzia', 'paciente-bimzelx', 'paciente-exame', 'medico']
DEFAULT_ENTRADA = [226, 227, 228, 141, 427]
DEFAULT_BANDS = [175, 360, 540]

FLOW_LABELS = {
    'entrada': 'Entrada e menu principal',
    'paciente-cimzia': 'Paciente · Cimzia',
    'paciente-bimzelx': 'Paciente · Bimzelx',
    'paciente-exame': 'Paciente · Exame',
    'medico': 'Profissional da saúde',
}
FLOW_COLORS = {
    'entrada': '#7c3aed',
    'paciente-cimzia': '#2563eb',
    'paciente-bimzelx': '#059669',
    'paciente-exame': '#ea580c',
    'medico': '#db2777',
}

TYPE_LABELS = {
    'opcao': 'Pergunta / escolha',
    'termo': 'Termo de consentimento',
    'pesquisa': 'Pesquisa de satisfação',
    'equipe': 'Transferência p/ equipe',
    'fim': 'Fim do fluxo',
    'nota': 'Nota',
    'msg': 'Mensagem / informação',
}


def flow_of(n, entrada, bands):
    if n['id'] in entrada:
        return 'entrada'
    cx = n['cx']
    for i, b in enumerate(bands):
        if cx < b:
            return DEFAULT_FLOWS[i]
    return DEFAULT_FLOWS[len(bands)]


def node_type(n):
    t = n['first']
    if re.match(r'^Fim(\b| \(|$)', t) or t == 'Fim':
        return 'fim'
    if re.match(r'^Opç\w+', t, re.I):
        return 'opcao'
    if re.search(r'Termo|Introdução|Consentimento', t):
        return 'termo'
    if re.search(r'Pesquisa|Avalia|Despedida', t):
        return 'pesquisa'
    if re.search(r'Equipe|Atendimento|transferi|especialistas', t):
        return 'equipe'
    if 'NOTA' in t or 'OBS' in t:
        return 'nota'
    return 'msg'


def build_children(G, roots):
    adj = defaultdict(list)
    for i, j, labels in G['edges']:
        adj[i].append((j, labels))
        adj[j].append((i, labels))
    parent = {}
    seen = set()
    for s in roots:
        if s in seen:
            continue
        seen.add(s)
        q = deque([s])
        while q:
            u = q.popleft()
            for v, labels in adj[u]:
                if v in seen:
                    continue
                seen.add(v)
                parent[v] = (u, labels)
                q.append(v)
    children = collections.defaultdict(list)
    for v, (u, labels) in parent.items():
        children[u].append((v, labels))
    for n in G['nodes']:
        children.setdefault(n['id'], [])
    return children


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('graph', help='graph.json produced by extract_graph.py')
    ap.add_argument('out', help='output .html file')
    ap.add_argument('--title', default='Fluxo de Mensagens Receptivas · WhatsApp · Sempre em Frente',
                    help='document title shown in the page')
    ap.add_argument('--entry-ids', default=','.join(map(str, DEFAULT_ENTRADA)),
                    help='node ids that form the "entrada" group (default: original diagram)')
    ap.add_argument('--bands', default=','.join(map(str, DEFAULT_BANDS)),
                    help='X coordinates splitting the flows left to right')
    ap.add_argument('--tree', default=None,
                    help='tree.json with real directed edges + arrow anchors (from extract_tree.py)')
    args = ap.parse_args()

    G = json.load(open(args.graph))
    nodes = G['nodes']
    entrada = {int(x) for x in args.entry_ids.split(',') if x.strip()}
    bands = [float(x) for x in args.bands.split(',') if x.strip()]

    directed = None
    if args.tree:
        T = json.load(open(args.tree))
        if len(T['nodes']) != len(nodes):
            raise SystemExit(f"node mismatch: graph.json has {len(nodes)}, tree.json {len(T['nodes'])}")
        for a, b in zip(nodes, T['nodes']):
            if a['first'] != b['first']:
                raise SystemExit('node order differs between graph.json and tree.json')
        directed = [(e['src'], e['dst'], e.get('arrow')) for e in T['edges']]
        print('directed edges from tree:', len(directed))

    for n in nodes:
        n['flow'] = flow_of(n, entrada, bands)

    flow_nodes = collections.defaultdict(list)
    for n in nodes:
        flow_nodes[n['flow']].append(n)

    flow_names = [f for f in DEFAULT_FLOWS if f in flow_nodes]
    flow_labels = dict(FLOW_LABELS)
    flow_colors = dict(FLOW_COLORS)
    for n in nodes:
        flow_labels.setdefault(n['flow'], n['flow'].replace('-', ' ').title())
        flow_colors.setdefault(n['flow'], '#64748b')

    children = build_children(G, [i for i in entrada if any(i in (e[0], e[1]) for e in G['edges'])])
    outgoing = {str(u): [dict(v=v, labels=labels) for v, labels in ch]
                for u, ch in children.items()}

    arrows = []
    if directed:
        # use the real directed edges as the tree
        succ = collections.defaultdict(list)
        for src, dst, arrow in directed:
            succ[src].append(dst)
            if arrow:
                arrows.append(dict(src=src, dst=dst, ax=arrow[0], ay=arrow[1]))
        for src in nodes:
            succ.setdefault(src['id'], [])
        outgoing = {str(u): [dict(v=v, labels=[]) for v in ch] for u, ch in succ.items()}
        print('outgoing nodes with edges:', sum(1 for v in succ.values() if v))

    read_order = {}
    for f, ns in flow_nodes.items():
        read_order[f] = [n['id'] for n in sorted(ns, key=lambda n: (-n['y0'], n['x0']))]

    payload = {
        'flows': ['entrada'] + flow_names if 'entrada' in flow_nodes else flow_names,
        'flowLabels': flow_labels,
        'flowColors': flow_colors,
        'typeLabels': TYPE_LABELS,
        'scale': 10,
        'overviewScale': 2.6,
        'nodes': [dict(id=n['id'], flow=n['flow'], type=node_type(n),
                       first=n['first'], body=n['lines'][1:],
                       x=round(n['x0'], 1), y=round(n['y0'], 1),
                       x1=round(n['x1'], 1), y1=round(n['y1'], 1)) for n in nodes],
        'edgeLabels': [dict(x=l['x0'], y=l['y0'], text=l['text']) for l in G['edge_labels']],
        'fimLabels': [dict(x=l['x0'], y=l['y0'], text=l['text']) for l in G['fim_labels']],
        'outgoing': outgoing,
        'readingOrder': read_order,
        'arrows': arrows,
    }

    js_payload = json.dumps(payload, ensure_ascii=False)
    template = open(os.path.join(HERE, 'template.html')).read()
    css = open(os.path.join(HERE, 'style.css')).read()
    js = open(os.path.join(HERE, 'app.js')).read()

    out = (template.replace('__TITLE__', html.escape(args.title))
                   .replace('/*__CSS__*/', css)
                   .replace('//__JS__//', js)
                   .replace('PAYLOAD__JSON__', js_payload))
    with open(args.out, 'w') as f:
        f.write(out)
    print(f"written {args.out} ({len(out)} bytes, {len(nodes)} nodes)")


if __name__ == '__main__':
    main()
