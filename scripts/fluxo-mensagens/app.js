(function () {
'use strict';

var D = window.__PAYLOAD__;
var nodes = D.nodes;
var byId = {};
nodes.forEach(function (n) { byId[n.id] = n; });
var flowColors = D.flowColors, flowLabels = D.flowLabels, typeLabels = D.typeLabels;
var scales = {};         // per flow, current zoom
var currentPage = null;
var currentView = {};    // flow -> 'mapa'|'leitura'
var zoom = {};           // flow -> scale factor
var selected = null;
var edgesVisible = true;

function esc(s) {
  return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}
function norm(s) {
  return String(s).toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g,'');
}
function flowColor(f) { return flowColors[f] || '#64748b'; }
function flowName(f) { return flowLabels[f] || f; }
function typeColor(t) { return typeLabels[t] ? t : 'msg'; }
function typeName(t) { return typeLabels[t] || 'Mensagem / informação'; }

// ---------- geometry helpers ----------
function flowExtent(flow) {
  var ids = flow === 'overview' ? null : (D.readingOrder[flow] || []);
  var list = ids ? ids.map(function(id){ return byId[id]; }) : nodes;
  var minX=1e9,maxX=-1e9,minY=1e9,maxY=-1e9;
  list.forEach(function(n){
    minX=Math.min(minX,n.x); maxX=Math.max(maxX,n.x1);
    minY=Math.min(minY,n.y); maxY=Math.max(maxY,n.y1);
  });
  return {minX:minX, maxX:maxX, minY:minY, maxY:maxY, pad:8};
}
function pos(n, ext, sc) {
  var cx=(n.x+n.x1)/2, cy=(n.y+n.y1)/2;
  return { left: (cx-ext.minX+ext.pad)*sc, top: (ext.maxY-cy+ext.pad)*sc };
}
function size(n, sc) {
  return { w: Math.max((n.x1-n.x)*sc, 2*sc), h: Math.max((n.y1-n.y)*sc, 1.5*sc) };
}

// arrowhead tip: the point on the target box edge crossed by the line, or the
// real anchor point (from the PDF vectors) when available
function arrowTip(p1, p2, b, ext, sc, anchor) {
  if (anchor) {
    return { x: (anchor.ax-ext.minX+ext.pad)*sc, y: (ext.maxY-anchor.ay+ext.pad)*sc };
  }
  var s = size(b, sc);
  var bx = p2.left - s.w/2, by = p2.top - s.h/2;
  var dx = p2.left-p1.left, dy = p2.top-p1.top;
  if (dx===0 && dy===0) return p2;
  var t = 1e9;
  [['x',bx],['x',bx+s.w],['y',by],['y',by+s.h]].forEach(function(edge){
    var coord = edge[0], val = edge[1], t0;
    if (coord==='x' && dx!==0) t0=(val-p1.left)/dx;
    else if (coord==='y' && dy!==0) t0=(val-p1.top)/dy;
    else return;
    if (t0>0 && t0<=t) t=t0;
  });
  if (!isFinite(t)) return p2;
  return { x: p1.left+dx*t, y: p1.top+dy*t };
}
function arrowHead(p1, tip, color, sc) {
  var ang = Math.atan2(tip.y-p1.y, tip.x-p1.x);
  var L = Math.max(5, 1.4*sc);
  var W = L*0.62;
  var p2x = tip.x - L*Math.cos(ang), p2y = tip.y - L*Math.sin(ang);
  var per = Math.PI/2;
  var a = {x:p2x + W*Math.cos(ang+per), y:p2y + W*Math.sin(ang+per)};
  var c = {x:p2x + W*Math.cos(ang-per), y:p2y + W*Math.sin(ang-per)};
  var poly = document.createElementNS('http://www.w3.org/2000/svg','polygon');
  poly.setAttribute('points', tip.x+','+tip.y+' '+a.x+','+a.y+' '+c.x+','+c.y);
  poly.setAttribute('fill', color);
  poly.setAttribute('opacity', 0.85);
  return poly;
}

// ---------- build pages ----------
var pagesEl = document.getElementById('pages');
var tabsEl = document.getElementById('tabs');

function addTab(id, label) {
  var b = document.createElement('button');
  b.textContent = label;
  b.dataset.tab = id;
  b.addEventListener('click', function(){ showPage(id); });
  tabsEl.appendChild(b);
}
function addPage(id) {
  var div = document.createElement('div');
  div.className = 'page';
  div.id = 'page-' + id;
  pagesEl.appendChild(div);
}

addTab('overview', 'Visão geral');
addPage('overview');
D.flows.forEach(function(f){
  addTab(f, flowName(f));
  addPage(f);
  currentView[f] = 'mapa';
  zoom[f] = D.scale;
});
currentView['overview'] = 'mapa';
zoom['overview'] = D.overviewScale;

function showPage(id) {
  currentPage = id;
  Array.prototype.forEach.call(tabsEl.children, function(b){
    b.classList.toggle('active', b.dataset.tab === id);
  });
  Array.prototype.forEach.call(pagesEl.children, function(p){
    p.classList.toggle('active', p.id === 'page-' + id);
  });
  renderPage(id);
  applySearch();
}

function renderPage(id) {
  var el = document.getElementById('page-' + id);
  if (id === 'overview') { renderOverview(el); return; }
  renderFlow(id, el);
}

// ---------- mapa ----------
function renderMapa(el, flow) {
  var ext = flowExtent(flow);
  var sc = zoom[flow];
  var wrap = document.createElement('div');
  wrap.className = 'map-wrap';
  var stage = document.createElement('div');
  stage.className = 'map-stage';
  stage.style.width = (ext.maxX-ext.minX+2*ext.pad)*sc + 'px';
  stage.style.height = (ext.maxY-ext.minY+2*ext.pad)*sc + 'px';
  stage.style.transform = 'scale(1)';

  // edges (SVG) with arrowheads
  var arrowByPair = {};
  (D.arrows || []).forEach(function(a){ arrowByPair[a.src+'->'+a.dst] = a; });
  var svg = document.createElementNS('http://www.w3.org/2000/svg','svg');
  svg.setAttribute('class','edges');
  svg.style.position='absolute'; svg.style.left='0'; svg.style.top='0';
  svg.style.width=stage.style.width; svg.style.height=stage.style.height;
  svg.style.overflow='visible'; svg.style.pointerEvents='none';
  Object.keys(D.outgoing).forEach(function(u){
    var a = byId[+u]; if(!a) return;
    var pa = pos(a, ext, sc);
    D.outgoing[u].forEach(function(link){
      var b = byId[link.v]; if(!b) return;
      if (a.flow !== flow && b.flow !== flow) return;
      var pb = pos(b, ext, sc);
      var tip = arrowTip(pa, pb, b, ext, sc, arrowByPair[u+'->'+link.v]);
      var color = flowColor(a.flow);
      var line = document.createElementNS('http://www.w3.org/2000/svg','line');
      line.setAttribute('x1',pa.left); line.setAttribute('y1',pa.top);
      line.setAttribute('x2',tip.x); line.setAttribute('y2',tip.y);
      line.setAttribute('stroke', color);
      line.setAttribute('stroke-width', sc>6?1.2:0.7);
      line.setAttribute('opacity', sc>6?0.55:0.4);
      svg.appendChild(line);
      var ah = arrowHead({x: pa.left, y: pa.top}, tip, color, sc);
      if (ah) svg.appendChild(ah);
    });
  });
  stage.appendChild(svg);

  // nodes
  (D.readingOrder[flow]||[]).forEach(function(id){
    var n = byId[id]; if(!n) return;
    var p = pos(n, ext, sc), s = size(n, sc);
    var d = document.createElement('div');
    d.className = 'node ' + n.type;
    d.style.left = p.left+'px'; d.style.top = p.top+'px';
    d.style.width = s.w+'px'; d.style.height = s.h+'px';
    d.style.borderColor = flowColor(n.flow);
    d.dataset.id = n.id;
    d.title = n.first + '\n' + n.body.join('\n');
    var t = document.createElement('div');
    t.className='t';
    t.textContent = n.first;
    d.appendChild(t);
    d.addEventListener('click', function(){ openPanel(n.id); });
    stage.appendChild(d);
  });

  // edge labels
  D.edgeLabels.forEach(function(l){
    var b = document.createElement('div');
    b.className='edge-label';
    b.style.left=(l.x-ext.minX+ext.pad)*sc+'px';
    b.style.top=(ext.maxY-l.y+ext.pad)*sc+'px';
    b.textContent = l.text;
    stage.appendChild(b);
  });
  // fim badges
  D.fimLabels.forEach(function(l){
    var b = document.createElement('div');
    b.className='fim-badge';
    b.style.left=(l.x-ext.minX+ext.pad)*sc+'px';
    b.style.top=(ext.maxY-l.y+ext.pad)*sc+'px';
    b.textContent = l.text;
    stage.appendChild(b);
  });

  wrap.appendChild(stage);
  el.innerHTML='';
  el.appendChild(wrap);

  // zoom controls for this page
  attachZoom(el, stage);
}

function attachZoom(el, stage) {
  el.addEventListener('wheel', function(ev){
    if (currentPage==='overview') return;
    ev.preventDefault();
    var delta = ev.deltaY < 0 ? 1.15 : 1/1.15;
    zoom[currentPage] = Math.min(30, Math.max(2, zoom[currentPage]*delta));
    renderPage(currentPage);
  }, {passive:false});
  stage.addEventListener('click', function(ev){
    if (ev.target === stage || ev.target === svgOf(stage)) closePanel();
  });
}
function svgOf(stage){ return stage.querySelector('svg'); }

// ---------- leitura ----------
function renderLeitura(el, flow) {
  el.innerHTML = '';
  var cont = document.createElement('div');
  cont.className='leitura';
  D.readingOrder[flow].forEach(function(id){
    var n = byId[id];
    var card = document.createElement('div');
    card.className='card';
    card.dataset.id = n.id;
    var h = document.createElement('h3');
    h.textContent = n.first;
    var b = document.createElement('span');
    b.className='badge ' + n.type;
    b.textContent = typeName(n.type);
    h.appendChild(b);
    card.appendChild(h);
    var body = document.createElement('div');
    body.className='body';
    body.textContent = n.body.join('\n');
    card.appendChild(body);
    var outs = D.outgoing[n.id] || [];
    if (outs.length) {
      var o = document.createElement('div');
      o.className='out';
      outs.forEach(function(link, idx){
        var target = byId[link.v];
        var tag = document.createElement('div');
        var lbls = (link.labels||[]).join(', ');
        tag.innerHTML = '<b>→ ' + esc(lbls) + '</b> ' + esc(target ? target.first : ('#'+link.v));
        tag.style.cursor='pointer';
        tag.addEventListener('click', function(){ openPanel(link.v); });
        o.appendChild(tag);
      });
      card.appendChild(o);
    }
    card.addEventListener('click', function(ev){
      if (ev.target.closest('.out')) return;
      openPanel(n.id);
    });
    cont.appendChild(card);
  });
  el.appendChild(cont);
}

// ---------- flow page with view toggle ----------
function renderFlow(flow, el) {
  el.innerHTML = '';
  var bar = document.createElement('div');
  bar.className='viewbar';
  [['mapa','Mapa da árvore'],['leitura','Leitura na ordem do fluxo']].forEach(function(v){
    var b = document.createElement('button');
    b.textContent = v[1];
    b.classList.toggle('active', currentView[flow]===v[0]);
    b.addEventListener('click', function(){
      currentView[flow]=v[0];
      renderFlow(flow, el);
      applySearch();
    });
    bar.appendChild(b);
  });
  el.appendChild(bar);
  var bodyEl = document.createElement('div');
  bodyEl.id='flow-body-'+flow;
  el.appendChild(bodyEl);
  if (currentView[flow]==='mapa') renderMapa(bodyEl, flow);
  else renderLeitura(bodyEl, flow);
}

// ---------- overview ----------
function renderOverview(el) {
  el.innerHTML='';
  var ext = flowExtent('overview');
  var sc = zoom['overview'];
  var wrap = document.createElement('div');
  wrap.className='map-wrap';
  var stage = document.createElement('div');
  stage.className='map-stage';
  stage.style.width=(ext.maxX-ext.minX+2*ext.pad)*sc+'px';
  stage.style.height=(ext.maxY-ext.minY+2*ext.pad)*sc+'px';
  nodes.forEach(function(n){
    var p=pos(n,ext,sc), s=size(n,sc);
    var d=document.createElement('div');
    d.className='node '+n.type;
    d.style.left=p.left+'px'; d.style.top=p.top+'px';
    d.style.width=Math.max(s.w,8)+'px'; d.style.height=Math.max(s.h,8)+'px';
    d.style.borderColor=flowColor(n.flow);
    d.style.fontSize='5px';
    d.dataset.id=n.id;
    d.title=n.first+'\n'+n.body.join('\n');
    var t=document.createElement('div'); t.className='t'; t.textContent=n.first; d.appendChild(t);
    d.addEventListener('click', function(){ openPanel(n.id); });
    stage.appendChild(d);
  });
  var leg=document.createElement('div');
  leg.className='legend';
  D.flows.forEach(function(f){
    var sp=document.createElement('span');
    sp.innerHTML='<span class="sw" style="background:'+flowColor(f)+'"></span>'+esc(flowName(f));
    leg.appendChild(sp);
  });
  wrap.appendChild(leg);
  wrap.appendChild(stage);
  el.appendChild(wrap);
}

// ---------- panel ----------
var panel = document.getElementById('panel');
function openPanel(id){
  selected = id;
  var n = byId[id];
  var body = document.getElementById('panel-body');
  var out = [];
  out.push('<h2>'+esc(n.first)+'</h2>');
  out.push('<span class="badge '+n.type+'">'+esc(typeName(n.type))+'</span>');
  out.push('<div class="flow-tag">'+esc(flowName(n.flow))+'</div>');
  if (n.body.length) out.push('<pre>'+esc(n.body.join('\n'))+'</pre>');
  var outs = D.outgoing[id]||[];
  if (outs.length){
    out.push('<div class="links"><strong>Segue para:</strong>');
    outs.forEach(function(link){
      var target=byId[link.v];
      out.push('<div><b>'+esc((link.labels||[]).join(', '))+'</b> → <a href="#" data-goto="'+link.v+'">'+esc(target?target.first:('#'+link.v))+'</a></div>');
    });
    out.push('</div>');
  }
  body.innerHTML = out.join('');
  body.querySelectorAll('a[data-goto]').forEach(function(a){
    a.addEventListener('click', function(ev){
      ev.preventDefault();
      openPanel(+a.dataset.goto);
    });
  });
  panel.classList.add('open');
}
function closePanel(){ panel.classList.remove('open'); selected=null; }
document.getElementById('panel-close').addEventListener('click', closePanel);

// ---------- search ----------
var lastQuery='';
function applySearch(){
  var q=norm(document.getElementById('search').value).trim();
  if (q===lastQuery) return;
  lastQuery=q;
  var matches={};
  if (q){
    nodes.forEach(function(n){
      var hay=norm(n.first+' '+n.body.join(' '));
      if (hay.indexOf(q)!==-1) matches[n.id]=true;
    });
  }
  var el = document.getElementById('page-'+currentPage);
  if (!el) return;
  var count=0;
  el.querySelectorAll('.node').forEach(function(d){
    var id=+d.dataset.id;
    d.classList.toggle('dim', !!q && !matches[id]);
    d.classList.toggle('hl', !!q && !!matches[id]);
    if (matches[id]) count++;
  });
  el.querySelectorAll('.card').forEach(function(d){
    var id=+d.dataset.id;
    d.classList.toggle('dim', !!q && !matches[id]);
    d.classList.toggle('hl', !!q && !!matches[id]);
    if (matches[id]) count++;
  });
  toast(q? (count+' resultado'+(count===1?'':'s')) : '');
}

document.getElementById('search').addEventListener('input', applySearch);

// ---------- buttons ----------
document.getElementById('btn-zoom-in').addEventListener('click', function(){
  zoom[currentPage]=Math.min(30, zoom[currentPage]*1.25); renderPage(currentPage);
});
document.getElementById('btn-zoom-out').addEventListener('click', function(){
  zoom[currentPage]=Math.max(1.5, zoom[currentPage]/1.25); renderPage(currentPage);
});
document.getElementById('btn-fit').addEventListener('click', function(){
  zoom[currentPage]= currentPage==='overview'?D.overviewScale:D.scale; renderPage(currentPage);
});
document.getElementById('toggle-edges').addEventListener('change', function(){
  edgesVisible=this.checked;
  var el=document.getElementById('page-'+currentPage);
  if (!el) return;
  el.querySelectorAll('svg.edges').forEach(function(s){ s.style.display=edgesVisible?'block':'none'; });
  el.querySelectorAll('.edge-label').forEach(function(d){ d.style.display=edgesVisible?'':'none'; });
});

function toast(msg){
  var t=document.getElementById('toast');
  t.textContent=msg;
  t.classList.toggle('show', !!msg);
}

// ---------- stats ----------
(function(){
  var byFlow={};
  nodes.forEach(function(n){ byFlow[n.flow]=(byFlow[n.flow]||0)+1; });
  var parts=D.flows.map(function(f){ return esc(flowName(f))+': '+byFlow[f]+' passos'; });
  parts.push('Total: '+nodes.length+' passos');
  document.getElementById('stats').innerHTML=parts.join(' · ');
})();

// init
showPage('overview');
})();
