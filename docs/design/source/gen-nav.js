// Generates the Showcase left-navigation option boards (C · Nav options).
const fs = require('fs');
const path = require('path');
const OUT = path.join(__dirname, 'canvas', 'project');
const b = (id) => '/_blob/' + id;

const ICON = {
  home: 'M6 19L20 7l14 12M10 16v17h20V16M17 33v-9h6v9',
  channels: 'M8.5 12h23a3.5 3.5 0 0 1 3.5 3.5v13a3.5 3.5 0 0 1-3.5 3.5h-23A3.5 3.5 0 0 1 5 28.5v-13A3.5 3.5 0 0 1 8.5 12zM14 36h12M15 5l5 6 5-6',
  radio: 'M7.5 14h25a3.5 3.5 0 0 1 3.5 3.5v14a3.5 3.5 0 0 1-3.5 3.5h-25A3.5 3.5 0 0 1 4 31.5v-14A3.5 3.5 0 0 1 7.5 14zM20 24.5a5.5 5.5 0 1 1-11 0 5.5 5.5 0 0 1 11 0zM25 21h6M25 27.5h6M9 14l21-9',
  catchup: 'M8 13a14 14 0 1 1-2 9M4.5 8l2.1 7.3 7-2.3M20 12v8l6 3.5',
  account: 'M26.5 12.5a6.5 6.5 0 1 1-13 0 6.5 6.5 0 0 1 13 0zM7 34c0-7.5 5.5-11.5 13-11.5S33 26.5 33 34'
};
const ITEMS = [['home', 'Home'], ['channels', 'Channels'], ['radio', 'Radio'], ['catchup', 'Catch-up'], ['account', 'Account']];
const svg = (d, color, size = 40) =>
  `<svg width="${size}" height="${size}" viewBox="0 0 40 40" fill="none" stroke="${color}" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><path d="${d}"/></svg>`;

// The Home content of C1, placed at x = left; dimmed when the rail holds focus.
function content(left, dim, heroFocus) {
  const onNow = [
    ['0ac5dbae153d93324008faeb65c388ea', 'e40d84f762578caed15688344a03391c', 'Revelation of Jesus Christ', '3ABN Proclaim · until 3:57', '35%'],
    ['4c1200060836665f27945f02be21cf3f', '3cd27ca3e7d58e9a1aa8273e9c19caa4', 'Tiny Tots Worship', '3ABN Kids · until 3:29', '36%'],
    ['599477377df6b3d7972470835520c306', 'f6c61295f0443e7ad9bb2b7f1a99ddee', 'Maravillosa Creación', '3ABN Latino · until 3:28', '71%'],
    ['47e13eaa7d6c8fe02b87cd4c4db3c6f7', '8a4ae2c264a612734dc50b5aabb7da57', 'HopeChannel', 'Live now · 3 PM hour', '33%'],
    ['fd3818e84422d8b0a384d0b8e35d2f3a', 'e2f268b5a36bee5d8c269ca003c3de9e', 'It is Written TV', 'Live now · 3 PM hour', '33%']
  ].map(([t, l, title, meta, pct]) => `
      <div style="width: 384px; display: flex; flex-direction: column; gap: 10px; flex-shrink: 0">
        <div style="position: relative; width: 384px; height: 216px; border-radius: 14px; overflow: hidden; background: #12141B">
          <img src="${b(t)}" alt="" style="width: 100%; height: 100%; object-fit: cover; opacity: 0.88">
          <div style="position: absolute; left: 12px; top: 12px; width: 72px; height: 51px; border-radius: 7px; background: #FFFFFF; display: flex; align-items: center; justify-content: center"><img src="${b(l)}" alt="" style="width: 66px; height: 47px; object-fit: contain"></div>
          <div style="position: absolute; left: 0; bottom: 0; width: 384px; height: 5px; background: rgba(255,255,255,0.2)"><div style="width: ${pct}; height: 5px; background: #1E8BFF"></div></div>
        </div>
        <div style="font-weight: 700; font-size: 23px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis">${title}</div>
        <div style="font-weight: 600; font-size: 19px; color: #A6ABB8">${meta}</div>
      </div>`).join('');
  const watch = heroFocus
    ? 'background: #FFFFFF; color: #07080C; transform: scale(1.06); transform-origin: left center; box-shadow: 0 14px 40px rgba(0,0,0,0.6)'
    : 'background: rgba(255,255,255,0.14); color: #FFFFFF';
  return `
  <img src="${b('c4daed39c492a92a3a5a2eeb01619e11')}" alt="" style="position: absolute; left: 0; top: 0; width: 1920px; height: 640px; object-fit: cover; filter: blur(36px); opacity: 0.55; transform: scale(1.12)">
  <div style="position: absolute; left: 0; top: 0; width: 1920px; height: 660px; background: linear-gradient(0deg, #07080C 0%, rgba(7,8,12,0.4) 45%, rgba(7,8,12,0.2) 100%)"></div>
  <div style="position: absolute; left: 0; top: 0; width: 1300px; height: 660px; background: linear-gradient(90deg, rgba(7,8,12,0.88) 0%, rgba(7,8,12,0) 100%)"></div>
  <div style="position: absolute; left: 0; top: 0; width: 1920px; height: 1080px; opacity: ${dim}">
    <div style="position: absolute; right: 96px; top: 56px; font-weight: 600; font-size: 27px; color: #A6ABB8">3:20 PM</div>
    <div style="position: absolute; left: ${left}px; top: 170px; width: 860px; display: flex; flex-direction: column; gap: 18px">
      <div style="display: flex; align-items: center; gap: 14px">
        <div style="height: 36px; padding: 0 14px; border-radius: 18px; background: #F0262B; display: flex; align-items: center; gap: 8px; font-weight: 800; font-size: 18px; letter-spacing: 1px"><span style="width: 8px; height: 8px; border-radius: 4px; background: #FFFFFF"></span>ON NOW</div>
        <span style="font-weight: 700; font-size: 24px; color: #DADDE5">3ABN</span>
      </div>
      <h1 style="margin: 0; font-weight: 800; font-size: 72px; line-height: 1.02; letter-spacing: -1.5px">3ABN Today Bible Q&amp;A</h1>
      <div style="display: flex; align-items: center; gap: 18px; font-weight: 600; font-size: 24px; color: #A6ABB8">
        <span>3:00 – 3:55 PM</span>
        <div style="width: 260px; height: 6px; border-radius: 3px; background: rgba(255,255,255,0.18)"><div style="width: 36%; height: 6px; border-radius: 3px; background: #1E8BFF"></div></div>
        <span>35 min left</span>
      </div>
      <div style="display: flex; gap: 16px; margin-top: 16px">
        <div style="height: 72px; padding: 0 38px; border-radius: 36px; display: flex; align-items: center; gap: 12px; font-weight: 800; font-size: 26px; ${watch}">Watch live</div>
        <div style="height: 72px; padding: 0 34px; border-radius: 36px; background: rgba(255,255,255,0.14); display: flex; align-items: center; font-weight: 700; font-size: 26px; margin-left: 10px">Start over</div>
        <div style="height: 72px; padding: 0 34px; border-radius: 36px; background: rgba(255,255,255,0.14); display: flex; align-items: center; font-weight: 700; font-size: 26px">3ABN channel</div>
      </div>
    </div>
    <div style="position: absolute; right: 96px; top: 150px; width: 480px; height: 270px; border-radius: 18px; overflow: hidden; box-shadow: 0 30px 80px rgba(0,0,0,0.7)">
      <img src="${b('c4daed39c492a92a3a5a2eeb01619e11')}" alt="" style="width: 100%; height: 100%; object-fit: cover">
      <div style="position: absolute; left: 14px; bottom: 14px; width: 84px; height: 60px; border-radius: 8px; background: #FFFFFF; display: flex; align-items: center; justify-content: center"><img src="${b('242bd1a56c08d0855ef8ca15fcbcd4ef')}" alt="" style="width: 76px; height: 54px; object-fit: contain"></div>
    </div>
    <div style="position: absolute; left: ${left}px; top: 594px; font-weight: 800; font-size: 32px">On now</div>
    <div style="position: absolute; left: ${left}px; top: 650px; display: flex; gap: 24px">${onNow}</div>
    <div style="position: absolute; left: ${left}px; top: 1020px; font-weight: 800; font-size: 32px; color: #A6ABB8">Channels</div>
  </div>`;
}

const page = (title, body) => `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>${title}</title>
<script src="./support.js"></script>
</head>
<body>
<x-dc>
<helmet>
<link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@500;600;700;800&amp;display=swap" rel="stylesheet">
<style>
body{margin:0}
</style>
</helmet>
<div style="width: 1920px; height: 1080px; position: relative; overflow: hidden; background: #07080C; color: #FFFFFF; font-family: 'Plus Jakarta Sans', sans-serif">${body}
</div>
</x-dc>
<script type="text/x-dc" data-dc-script data-props='{"$preview":{"width":1920,"height":1080}}'>
class Component extends DCLogic {
  renderVals() {
    return {};
  }
}
</script>
</body>
</html>
`;

// N1 · Icon column: 128 px of glyphs; focus opens labels over a scrim, the page stays.
function n1(open) {
  const rows = ITEMS.map(([k, label], i) => {
    const selected = k === 'home', focused = open && k === 'channels';
    let style, color;
    if (focused) { style = 'background: #FFFFFF; color: #07080C'; color = '#07080C'; }
    else if (selected) { style = 'color: #FFFFFF'; color = '#FFFFFF'; }
    else { style = 'color: #A6ABB8'; color = '#A6ABB8'; }
    const w = open ? 340 : 72;
    const lab = open ? `<span style="font-weight: ${selected || focused ? 800 : 600}; font-size: 28px; white-space: nowrap">${label}</span>` : '';
    const bar = selected && !open ? '<div style="position: absolute; left: -28px; top: 18px; width: 6px; height: 36px; border-radius: 3px; background: #FFFFFF"></div>' : '';
    const dot = selected && open ? '<span style="margin-left: auto; width: 10px; height: 10px; border-radius: 5px; background: #FFFFFF"></span>' : '';
    return `<div style="position: relative; width: ${w}px; height: 72px; border-radius: 36px; display: flex; align-items: center; gap: 20px; padding: 0 16px; box-sizing: border-box; ${style}">${bar}${svg(ICON[k], color)}${lab}${dot}</div>`;
  }).join('\n');
  const scrim = open ? '<div style="position: absolute; left: 0; top: 0; width: 1100px; height: 1080px; background: linear-gradient(90deg, rgba(7,8,12,0.97) 0%, rgba(7,8,12,0.9) 35%, rgba(7,8,12,0) 100%)"></div>' : '<div style="position: absolute; left: 0; top: 0; width: 220px; height: 1080px; background: linear-gradient(90deg, rgba(7,8,12,0.85), rgba(7,8,12,0))"></div>';
  const brand = open
    ? `<img src="${b('ec7c10bad0117787e03b001592d65bba')}" alt="mySDAtv" style="position: absolute; left: 44px; top: 40px; width: 160px; height: 83px">`
    : `<img src="${b('626310db1af1e2cf0f2088632ef8c777')}" alt="mySDAtv" style="position: absolute; left: 34px; top: 48px; width: 60px; height: 60px">`;
  return content(168, open ? 0.45 : 1, !open) + scrim + brand +
    `<div style="position: absolute; left: 28px; top: 300px; display: flex; flex-direction: column; gap: 14px">${rows}</div>`;
}

// N2 · Floating capsule: a glass pill floating mid-left; it widens on focus.
function n2(open) {
  const rows = ITEMS.map(([k, label]) => {
    const selected = k === 'home', focused = open && k === 'channels';
    const circle = focused ? '#FFFFFF' : (selected ? 'rgba(255,255,255,0.18)' : 'transparent');
    const ic = focused ? '#07080C' : (selected ? '#FFFFFF' : '#A6ABB8');
    const lab = open ? `<span style="font-weight: ${focused || selected ? 800 : 600}; font-size: 27px; color: ${focused || selected ? '#FFFFFF' : '#A6ABB8'}">${label}</span>` : '';
    return `<div style="display: flex; align-items: center; gap: 18px; height: 72px"><div style="width: 72px; height: 72px; border-radius: 36px; background: ${circle}; display: flex; align-items: center; justify-content: center; flex-shrink: 0; ${focused ? 'box-shadow: 0 10px 30px rgba(0,0,0,0.6)' : ''}">${svg(ICON[k], ic, 36)}</div>${lab}</div>`;
  }).join('\n');
  const w = open ? 330 : 104;
  const capsule = `<div style="position: absolute; left: 32px; top: 250px; width: ${w}px; padding: 16px; box-sizing: border-box; border-radius: 52px; background: rgba(24,26,34,0.82); box-shadow: 0 0 0 1px rgba(255,255,255,0.08), 0 30px 80px rgba(0,0,0,0.6); display: flex; flex-direction: column; gap: 12px">${rows}</div>`;
  const scrim = open ? '<div style="position: absolute; left: 0; top: 0; width: 900px; height: 1080px; background: linear-gradient(90deg, rgba(7,8,12,0.85) 0%, rgba(7,8,12,0) 100%)"></div>' : '';
  const brand = `<img src="${b('626310db1af1e2cf0f2088632ef8c777')}" alt="mySDAtv" style="position: absolute; left: 54px; top: 56px; width: 60px; height: 60px">`;
  return content(184, open ? 0.5 : 1, !open) + scrim + brand + capsule;
}

// N3 · Labelled sidebar: always open, labels always shown; focus is a white pill.
function n3(open) {
  const rows = ITEMS.map(([k, label]) => {
    const selected = k === 'home', focused = open && k === 'channels';
    let bg = 'transparent', fg = '#A6ABB8', wt = 600;
    if (focused) { bg = '#FFFFFF'; fg = '#07080C'; wt = 800; }
    else if (selected) { fg = '#FFFFFF'; wt = 800; bg = open ? 'transparent' : 'rgba(255,255,255,0.1)'; }
    const bar = selected && !focused ? '<span style="margin-left: auto; width: 8px; height: 8px; border-radius: 4px; background: #F0262B"></span>' : '';
    return `<div style="height: 70px; border-radius: 35px; background: ${bg}; color: ${fg}; display: flex; align-items: center; gap: 18px; padding: 0 22px; font-weight: ${wt}; font-size: 27px">${svg(ICON[k], fg, 36)}${label}${bar}</div>`;
  }).join('\n');
  const side = `<div style="position: absolute; left: 0; top: 0; width: 320px; height: 1080px; background: #0D0E13; box-shadow: 1px 0 0 rgba(255,255,255,0.06)">
    <img src="${b('ec7c10bad0117787e03b001592d65bba')}" alt="mySDAtv" style="position: absolute; left: 40px; top: 40px; width: 180px; height: 94px">
    <div style="position: absolute; left: 24px; top: 210px; width: 272px; display: flex; flex-direction: column; gap: 10px">${rows}</div>
    <div style="position: absolute; left: 40px; bottom: 48px; font-weight: 600; font-size: 22px; color: #6E7380">Sunday, Oct 5</div>
  </div>`;
  return content(384, 1, !open) + side;
}

const boards = [
  ['N1a-IconColumn', 'N1 · Icon column, at rest', n1(false)],
  ['N1b-IconColumn-Open', 'N1 · Icon column, focus in the rail', n1(true)],
  ['N2a-Capsule', 'N2 · Floating capsule, at rest', n2(false)],
  ['N2b-Capsule-Open', 'N2 · Floating capsule, focus in the rail', n2(true)],
  ['N3a-Sidebar', 'N3 · Labelled sidebar, focus on the page', n3(false)],
  ['N3b-Sidebar-Focus', 'N3 · Labelled sidebar, focus in the rail', n3(true)]
];
for (const [file, title, body] of boards) fs.writeFileSync(path.join(OUT, file + '.dc.html'), page(title, body));
console.log(boards.map((x) => x[0]).join('\n'));
