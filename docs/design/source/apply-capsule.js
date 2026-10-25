// Applies the chosen Showcase navigation (N2 · floating capsule, owner 2026-10-06)
// to the Showcase screens: drops the top menu, adds the globe mark, the capsule
// (at rest, the screen's destination selected) and the clock, and moves the page
// content right to clear the capsule (x 96 -> 184).
const fs = require('fs');
const path = require('path');
const DIR = path.join(__dirname, 'canvas', 'project');
const ICON = {
  home: 'M6 19L20 7l14 12M10 16v17h20V16M17 33v-9h6v9',
  channels: 'M8.5 12h23a3.5 3.5 0 0 1 3.5 3.5v13a3.5 3.5 0 0 1-3.5 3.5h-23A3.5 3.5 0 0 1 5 28.5v-13A3.5 3.5 0 0 1 8.5 12zM14 36h12M15 5l5 6 5-6',
  radio: 'M7.5 14h25a3.5 3.5 0 0 1 3.5 3.5v14a3.5 3.5 0 0 1-3.5 3.5h-25A3.5 3.5 0 0 1 4 31.5v-14A3.5 3.5 0 0 1 7.5 14zM20 24.5a5.5 5.5 0 1 1-11 0 5.5 5.5 0 0 1 11 0zM25 21h6M25 27.5h6M9 14l21-9',
  catchup: 'M8 13a14 14 0 1 1-2 9M4.5 8l2.1 7.3 7-2.3M20 12v8l6 3.5',
  account: 'M26.5 12.5a6.5 6.5 0 1 1-13 0 6.5 6.5 0 0 1 13 0zM7 34c0-7.5 5.5-11.5 13-11.5S33 26.5 33 34'
};
const KEYS = ['home', 'channels', 'radio', 'catchup', 'account'];
function capsule(selected) {
  const rows = KEYS.map((k) => {
    const sel = k === selected;
    return `<div style="width: 72px; height: 72px; border-radius: 36px; background: ${sel ? 'rgba(255,255,255,0.18)' : 'transparent'}; display: flex; align-items: center; justify-content: center"><svg width="36" height="36" viewBox="0 0 40 40" fill="none" stroke="${sel ? '#FFFFFF' : '#A6ABB8'}" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><path d="${ICON[k]}"/></svg></div>`;
  }).join('\n      ');
  return `
  <div style="position: absolute; left: 0; top: 0; width: 220px; height: 1080px; background: linear-gradient(90deg, rgba(7,8,12,0.7), rgba(7,8,12,0))"></div>
  <img src="/_blob/626310db1af1e2cf0f2088632ef8c777" alt="mySDAtv" style="position: absolute; left: 54px; top: 56px; width: 60px; height: 60px">
  <div style="position: absolute; left: 32px; top: 250px; width: 104px; padding: 16px; box-sizing: border-box; border-radius: 52px; background: rgba(24,26,34,0.82); box-shadow: 0 0 0 1px rgba(255,255,255,0.08), 0 30px 80px rgba(0,0,0,0.6); display: flex; flex-direction: column; gap: 12px">
      ${rows}
  </div>`;
}
const CLOCK = '\n  <div style="position: absolute; right: 96px; top: 56px; font-weight: 600; font-size: 27px; color: #A6ABB8">3:20 PM</div>';

const jobs = { 'C1-Home': 'home', 'C2-Channel': 'channels', 'C3-Channels': 'channels', 'C4-Radio': 'radio', 'C5-Catchup': 'catchup', 'C8-Account': 'account' };
for (const [name, sel] of Object.entries(jobs)) {
  const f = path.join(DIR, name + '.dc.html');
  let s = fs.readFileSync(f, 'utf8');
  // 1. The top menu block, whole (it ends at the first "\n  </div>" after it).
  const start = s.indexOf('<div style="position: absolute; left: 96px; top: 40px; right: 96px; height: 80px;');
  let hasMenu = start >= 0;
  if (hasMenu) {
    const end = s.indexOf('\n  </div>', start) + '\n  </div>'.length;
    s = s.slice(0, start) + '<!--NAV-->' + s.slice(end);
  }
  // 2. Content right of the capsule.
  s = s.replace(/left: 96px/g, 'left: 184px').replace(/left: 500px; top: 140px; width: 1300px/, 'left: 588px; top: 140px; width: 1212px').replace(/width: 1728px/g, 'width: 1640px');
  // 3. Nav last in the root (it paints over the page), clock with it.
  const nav = capsule(sel) + (name === 'C1-Home' || name === 'C3-Channels' || name === 'C4-Radio' || name === 'C5-Catchup' ? CLOCK : '');
  s = s.replace('<!--NAV-->', '');
  const rootEnd = s.lastIndexOf('</div>\n</x-dc>');
  s = s.slice(0, rootEnd) + nav.trimStart().replace(/^/, '') + '\n' + s.slice(rootEnd);
  fs.writeFileSync(f, s);
  console.log(name, hasMenu ? 'menu replaced' : 'no top menu', '-> capsule:', sel);
}
