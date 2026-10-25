// Ported 2026-10-06 from wpa_live_roku/tools/check-scope.js (prefix Sd).
// Static scope check for the SceneGraph components: every function a
// component's scripts CALL must be DEFINED in a script that component
// includes. source/ is not in component scope on its own
// (knowledge/dev-roku/source-dir-not-in-component-scope), and a call to a
// function no included script defines only fails on the device.
//
//   node tools/check-scope.js
//
// Also flags: a <component> name used as a child tag that no file defines,
// a script uri that does not exist, and a few BrightScript reserved words
// used as local names (step, rem, box, run, tab, pos, sub) - the ones whose
// compile errors name nothing - as assignments, loop variables, parameter
// names and sub/function names.
//
// WHAT "CLEAN" DOES NOT COVER (review C10, 2026-09-29) - check these by hand:
//   * only Sd*-prefixed calls are resolved; a missing screen-local helper
//     (no Wp prefix) or another component's function is not reported
//   * callFunc("x") targets are not matched to the target's <interface>
//     (knowledge/dev-roku/callfunc-needs-interface-declaration)
//   * source/main.brs (source scope) is not checked
//   * reserved words beyond the listed ones (mod, then, to, stop, type ...)
const fs = require("fs");
const path = require("path");
const root = path.resolve(__dirname, "..");

const walk = (dir) => fs.readdirSync(dir, { withFileTypes: true }).flatMap((d) =>
  d.isDirectory() ? walk(path.join(dir, d.name)) : [path.join(dir, d.name)]);

const allXmls = walk(path.join(root, "components")).filter((f) => f.endsWith(".xml"));
// Optional: limit the report to the components named on the command line
// (the legacy screens carry their own unrelated findings).
const only = process.argv.slice(2).map((a) => a.toLowerCase());
const xmls = only.length ? allXmls.filter((f) => only.includes(path.basename(f, ".xml").toLowerCase())) : allXmls;
const builtins = new Set(["Main"]);
const defined = new Set(allXmls.map((f) => (fs.readFileSync(f, "utf8").match(/<component name="(\w+)"/) || [])[1]).filter(Boolean));
const sgNodes = new Set(["Group", "Rectangle", "Poster", "Label", "Timer", "Animation", "RowList", "MarkupGrid", "MarkupList",
  "Video", "Font", "LayoutGroup", "MiniKeyboard", "Keyboard", "Vector2DFieldInterpolator", "FloatFieldInterpolator",
  "ColorFieldInterpolator", "KeyboardDialog", "ProgressDialog", "Dialog", "interface", "field", "function", "children", "script", "component", "BusySpinner"]);

let problems = 0;
const report = (f, msg) => { problems++; console.log(`${path.relative(root, f)}: ${msg}`); };
const strip = (src) => src.replace(/"[^"\n]*"/g, '""').replace(/'.*$/gm, "");

for (const x of xmls) {
  const xml = fs.readFileSync(x, "utf8");
  // pkg:/ paths from the root; a bare name (uri="X.brs") sits beside the XML.
  const uris = [...xml.matchAll(/<script[^>]*uri="([^"]+)"/g)].map((m) => m[1].startsWith("pkg:/")
    ? m[1].slice(5)
    : path.relative(root, path.join(path.dirname(x), m[1])).split(path.sep).join("/"));
  const defs = new Set();
  const calls = new Map();
  for (const u of uris) {
    const p = path.join(root, u);
    if (!fs.existsSync(p)) { report(x, `script missing: ${u}`); continue; }
    const src = strip(fs.readFileSync(p, "utf8"));
    for (const m of src.matchAll(/^\s*(?:function|sub)\s+(\w+)/gim)) defs.add(m[1].toLowerCase());
    for (const m of src.matchAll(/\b(Sd\w+)\s*\(/g)) if (!calls.has(m[1].toLowerCase())) calls.set(m[1].toLowerCase(), `${u}: ${m[1]}`);
    for (const m of src.matchAll(/^\s*(step|rem|box|run|tab|pos|sub)\s*=/gim)) report(x, `${u}: reserved word assigned: ${m[1]}`);
    for (const m of src.matchAll(/^\s*(?:function|sub)\s+(step|rem|box|run|tab|pos|sub)\s*\(/gim)) report(x, `${u}: reserved word as a function name: ${m[1]}`);
    for (const m of src.matchAll(/^\s*for\s+(?:each\s+)?(step|rem|box|run|tab|pos|sub|m)\b/gim)) report(x, `${u}: reserved word as a loop variable: ${m[1]}`);
    for (const m of src.matchAll(/^\s*(?:function|sub)\s+\w+\s*\(([^)]*)\)/gim)) {
      for (const prm of m[1].split(",")) {
        const nm = (prm.trim().split(/\s|=/)[0] || "").toLowerCase();
        if (["step", "rem", "box", "run", "tab", "pos", "sub"].includes(nm)) report(x, `${u}: reserved word as a parameter: ${nm}`);
      }
    }
  }
  for (const [name, where] of calls) if (!defs.has(name) && !builtins.has(name)) report(x, `calls ${where}() - not defined in any included script`);
  for (const m of xml.replace(/<!--[\s\S]*?-->/g, "").matchAll(/<(\w+)[\s>\/]/g)) {
    const tag = m[1];
    if (!sgNodes.has(tag) && !defined.has(tag) && !/^(xml|ContentNode)$/.test(tag)) report(x, `child tag <${tag}> is not a known node or component`);
  }
  // Functions named in observeField / functionName / interface must exist.
  const raw = uris.map((u) => path.join(root, u)).filter(fs.existsSync).map((p) => fs.readFileSync(p, "utf8")).join("\n");
  for (const m of raw.matchAll(/observeField(?:Scoped)?\([^,]+,\s*"(\w+)"\)/g)) if (!defs.has(m[1].toLowerCase())) report(x, `observer handler not defined: ${m[1]}`);
  for (const m of xml.replace(/<!--[\s\S]*?-->/g, "").matchAll(/onChange="(\w+)"/g)) if (!defs.has(m[1].toLowerCase())) report(x, `onChange handler not defined: ${m[1]}`);
  for (const m of xml.matchAll(/<function name="(\w+)"/g)) if (!defs.has(m[1].toLowerCase())) report(x, `interface function not defined: ${m[1]}`);
  for (const m of raw.matchAll(/functionName = "(\w+)"/g)) if (!defs.has(m[1].toLowerCase())) report(x, `task function not defined: ${m[1]}`);
  for (const m of raw.matchAll(/createChild\("(\w+)"\)|CreateObject\("roSGNode", "(\w+)"\)/g)) {
    const n = m[1] || m[2];
    if (!sgNodes.has(n) && !defined.has(n) && n !== "ContentNode") report(x, `creates unknown node ${n}`);
  }
}
// main.brs is in source scope: everything under source/.
console.log(problems ? `\n${problems} problem(s)` : "scope check: clean");
process.exit(problems ? 1 : 0);
