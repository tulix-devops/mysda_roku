// Minimal local stand-in for the Design canvas runtime, enough to render the
// mySDAtv boards to PNG: {{holes}}, <sc-for>, <sc-if>, <helmet>, renderVals().
class DCLogic { constructor(props) { this.props = props || {}; this.state = {}; } setState() {} forceUpdate() {} }
window.DCLogic = DCLogic;

function lookup(scope, path) {
  path = path.trim();
  if (path === 'true') return true;
  if (path === 'false') return false;
  let v = scope;
  for (const k of path.split('.')) { if (v == null) return undefined; v = v[k]; }
  return v;
}
function interp(str, scope) {
  return str.replace(/\{\{([^}]+)\}\}/g, (_, p) => { const v = lookup(scope, p); return v == null ? '' : String(v); });
}
function render(node, scope, out) {
  if (node.nodeType === 3) { out.appendChild(document.createTextNode(interp(node.nodeValue, scope))); return; }
  if (node.nodeType !== 1) return;
  const tag = node.tagName.toLowerCase();
  if (tag === 'sc-for') {
    const m = node.getAttribute('list').match(/\{\{([^}]+)\}\}/);
    const list = (m && lookup(scope, m[1])) || [];
    const as = node.getAttribute('as') || 'item';
    list.forEach((item, i) => {
      const s = Object.assign(Object.create(scope), { [as]: item, $index: i });
      for (const c of node.childNodes) render(c, s, out);
    });
    return;
  }
  if (tag === 'sc-if') {
    const m = node.getAttribute('value').match(/\{\{([^}]+)\}\}/);
    if (m && lookup(scope, m[1])) for (const c of node.childNodes) render(c, scope, out);
    return;
  }
  const el = document.createElementNS(node.namespaceURI, node.localName);
  for (const a of node.attributes) el.setAttribute(a.name, interp(a.value, scope));
  for (const c of node.childNodes) render(c, scope, el);
  out.appendChild(el);
}
document.addEventListener('DOMContentLoaded', () => {
  const xdc = document.querySelector('x-dc');
  const src = document.querySelector('script[data-dc-script]').textContent;
  const Component = new Function('DCLogic', src + '\nreturn Component;')(DCLogic);
  const vals = new Component({}).renderVals();
  const tpl = document.createElement('template');
  tpl.innerHTML = xdc.innerHTML;
  const helmet = tpl.content.querySelector('helmet');
  if (helmet) { for (const c of [...helmet.childNodes]) document.head.appendChild(c); helmet.remove(); }
  const frag = document.createDocumentFragment();
  for (const c of tpl.content.childNodes) render(c, vals, frag);
  xdc.replaceWith(frag);
  document.body.style.margin = '0';
});
