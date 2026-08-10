"""Build a print-friendly HTML and optional multi-page PDF from the interactive HTML.

Reads the payload embedded in the interactive HTML, groups all boxes by flow
in reading order and writes an A4 card document. If --pdf is given, renders it
with headless Chrome.

Usage:
    python render_pdf.py <interactive.html> <print.html> [--pdf out.pdf] [--chrome /path/to/chrome]
"""

import argparse
import html
import json
import os
import re
import shutil
import subprocess

HERE = os.path.dirname(os.path.abspath(__file__))
CHROME_CANDIDATES = [
    '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    '/Applications/Chromium.app/Contents/MacOS/Chromium',
]


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


def card(n, data, by_id):
    out = ['<div class="card">']
    out.append('<h3>' + esc(n['first']) + '<span class="badge ' + esc(n['type']) + '">'
               + esc(data['typeLabels'].get(n['type'], n['type'])) + '</span></h3>')
    body = '\n'.join(n['body']).strip()
    if body:
        out.append('<div class="body">' + esc(body) + '</div>')
    outs = data['outgoing'].get(str(n['id']), [])
    if outs:
        links = []
        for link in outs:
            tgt = by_id.get(link['v'])
            labels = ', '.join(link['labels']) if link['labels'] else ''
            links.append('<b>&rarr; ' + esc(labels) + '</b> '
                         + esc(tgt['first'] if tgt else '#' + str(link['v'])))
        out.append('<div class="out">' + ' '.join(links) + '</div>')
    out.append('</div>')
    return ''.join(out)


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('interactive', help='interactive HTML produced by render_html.py')
    ap.add_argument('out', help='output print HTML')
    ap.add_argument('--pdf', help='optional output PDF (needs Chrome)')
    ap.add_argument('--chrome', help='path to the Chrome binary')
    ap.add_argument('--title',
                    default='Fluxo de Mensagens Receptivas · WhatsApp · Sempre em Frente')
    args = ap.parse_args()

    data = load_payload(args.interactive)
    by_id = {n['id']: n for n in data['nodes']}

    sections = []
    for f in data['flows']:
        name = data['flowLabels'][f]
        color = data['flowColors'][f]
        ids = data['readingOrder'][f]
        cards = ''.join(card(by_id[i], data, by_id) for i in ids)
        sections.append('<section class="flow"><h2 style="background:'
                        + esc(color) + '">' + esc(name)
                        + '<span class="cnt">' + str(len(ids)) + ' passos</span></h2>'
                        + cards + '</section>')

    tpl = open(os.path.join(HERE, 'print_template.html')).read()
    final = tpl.replace('__TITLE__', html.escape(args.title)).replace('<!--__FLOWS__-->', ''.join(sections))
    with open(args.out, 'w') as f:
        f.write(final)
    print(f"written {args.out} ({len(final)} bytes, {len(data['nodes'])} cards)")

    if args.pdf:
        chrome = args.chrome or find_chrome()
        if not chrome:
            raise SystemExit('Chrome not found; pass --chrome /path/to/Google\\ Chrome')
        url = 'file://' + os.path.abspath(args.out)
        subprocess.run([chrome, '--headless=new', '--disable-gpu', '--no-first-run',
                        '--no-pdf-header-footer', '--virtual-time-budget=3000',
                        '--print-to-pdf=' + args.pdf, url], check=True)
        print(f"written {args.pdf}")


if __name__ == '__main__':
    main()
