// Showcase header fix (owner, 2026-10-06): "Logo at navigation is not correct"
// (the globe crop cut through the "SDA" letters) and "we are not indicating
// screen titles". The whole mySDAtv logo now sits above the capsule (144x75,
// centred on it) and each screen names itself at the content's left edge.
const fs = require('fs');
const path = require('path');
const DIR = path.join(__dirname, 'canvas', 'project');
const MARK = '<img src="/_blob/626310db1af1e2cf0f2088632ef8c777" alt="mySDAtv" style="position: absolute; left: 54px; top: 56px; width: 60px; height: 60px">';
const LOGO = '<img src="/_blob/ec7c10bad0117787e03b001592d65bba" alt="mySDAtv" style="position: absolute; left: 12px; top: 40px; width: 144px; height: 75px">';
const title = (t, sub) => `\n  <div style="position: absolute; left: 184px; top: 46px; display: flex; align-items: baseline; gap: 18px"><span style="font-weight: 800; font-size: 46px; letter-spacing: -0.5px">${t}</span>${sub ? `<span style="font-weight: 600; font-size: 24px; color: #A6ABB8">${sub}</span>` : ''}</div>`;
const jobs = {
  'C1-Home': ['Home', 'Sunday, Oct 5'],
  'C2-Channel': ['Channels', '/ 3ABN'],
  'C3-Channels': ['Channels', '40 live channels'],
  'C4-Radio': ['Radio', '10 stations'],
  'C5-Catchup': ['Catch-up', '21 days of every channel'],
  'C8-Account': ['Account', '']
};
for (const [name, [t, sub]] of Object.entries(jobs)) {
  const f = path.join(DIR, name + '.dc.html');
  let s = fs.readFileSync(f, 'utf8');
  if (!s.includes(MARK)) throw new Error(name + ': mark not found');
  s = s.replace(MARK, LOGO + title(t, sub));
  if (name === 'C2-Channel') {
    // The old "‹ Channels" crumb is now the title.
    const i = s.indexOf('<div style="position: absolute; left: 184px; top: 60px;');
    const j = s.indexOf('</div>', i) + '</div>'.length;
    s = s.slice(0, i) + s.slice(j);
  }
  fs.writeFileSync(f, s);
  console.log(name, '->', t);
}
