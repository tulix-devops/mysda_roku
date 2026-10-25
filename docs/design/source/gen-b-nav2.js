// B · Guide: five more navigation concepts (owner, 2026-10-06: "try 5 different
// navigations"). Shapes stay B-1 (pill controls, soft 14 px cells).
const fs = require('fs');
const path = require('path');
const OUT = path.join(__dirname, 'canvas', 'project');
const b = (id) => '/_blob/' + id;
const G = { ground: '#050B1E', panel: '#0B1733', cell: '#10203F', live: '#16294F', line: '#1C2E55', gold: '#FAD35A', red: '#F0262B', t2: '#A9B6CF' };
const ICON = {
  guide: 'M5 9h30M5 20h30M5 31h30M14 5v30',
  globe: 'M35 20a15 15 0 1 1-30 0 15 15 0 0 1 30 0zM27 20c0 8.3-3.1 15-7 15s-7-6.7-7-15 3.1-15 7-15 7 6.7 7 15zM5 20h30M8 12.5h24M8 27.5h24',
  radio: 'M7.5 14h25a3.5 3.5 0 0 1 3.5 3.5v14a3.5 3.5 0 0 1-3.5 3.5h-25A3.5 3.5 0 0 1 4 31.5v-14A3.5 3.5 0 0 1 7.5 14zM20 24.5a5.5 5.5 0 1 1-11 0 5.5 5.5 0 0 1 11 0zM25 21h6M25 27.5h6M9 14l21-9',
  catchup: 'M8 13a14 14 0 1 1-2 9M4.5 8l2.1 7.3 7-2.3M20 12v8l6 3.5',
  user: 'M26.5 12.5a6.5 6.5 0 1 1-13 0 6.5 6.5 0 0 1 13 0zM7 34c0-7.5 5.5-11.5 13-11.5S33 26.5 33 34',
  menu: 'M7 11h26M7 20h26M7 29h26',
  down: 'M11 16l9 9 9-9'
};
const NAV = [['guide', 'Guide', 'Today across 24 channels'], ['globe', 'Languages', '16 channels, 9 languages'], ['radio', 'Radio', '10 stations'], ['catchup', 'Catch-up', 'The last 21 days'], ['user', 'Account', 'Log in for catch-up']];
const svg = (k, c, s = 34, w = 3) => `<svg width="${s}" height="${s}" viewBox="0 0 40 40" fill="none" stroke="${c}" stroke-width="${w}" stroke-linecap="round" stroke-linejoin="round"><path d="${ICON[k]}"/></svg>`;
const cond = "font-family: 'Barlow Condensed', sans-serif; font-weight: 700";
const LOGO = (x, y, w) => `<img src="${b('ec7c10bad0117787e03b001592d65bba')}" alt="mySDAtv" style="position: absolute; left: ${x}px; top: ${y}px; width: ${w}px; height: ${Math.round(w * 108 / 207)}px">`;
const CLOCK = `<div style="position: absolute; right: 64px; top: 48px; height: 56px; border-radius: 28px; background: ${G.panel}; display: flex; align-items: center; gap: 16px; padding: 0 24px; ${cond}; font-size: 32px">3:20 PM <span style="color: ${G.t2}; font-weight: 600">SUN OCT 5</span></div>`;

// The guide body. o = { left, right, previewLeft, infoLeft, top, rows, title }.
function guide(o) {
  const left = o.left, right = o.right || 64, W = 1920 - right - left, CH = 300, X0 = CH + 16, PPM = (W - X0) / 120, NOW = 20;
  const top = o.top || 0, nRows = o.rows || 5;
  const m = (hm) => { const [h, mm] = hm.split(':').map(Number); return (h - 15) * 60 + mm; };
  const cell = (s, e, title, focus, generic) => {
    const a = m(s), bb = Math.min(m(e), 120), live = a <= NOW && bb > NOW;
    const time = generic ? (s.startsWith('15') ? '3:00' : '4:00') + ' · live programming' : '';
    return `<div style="position: absolute; top: 0; left: ${X0 + a * PPM}px; width: ${Math.max(0, (bb - a) * PPM - 8)}px; height: 84px; border-radius: 14px; overflow: hidden; background: ${focus ? G.gold : (live ? G.live : G.cell)}; color: ${focus ? G.ground : '#FFFFFF'}; box-sizing: border-box; padding: 10px 16px; display: flex; flex-direction: column; justify-content: center; gap: 2px; ${focus ? 'box-shadow: 0 10px 30px rgba(250,211,90,0.35)' : ''}"><div style="font-weight: 700; font-size: 23px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis">${title}</div>${time ? `<div style="font-weight: 500; font-size: 19px; opacity: 0.8">${time}</div>` : ''}</div>`;
  };
  const row = (logo, name, cells) => `<div style="position: relative; height: 84px"><div style="position: absolute; left: 0; top: 0; width: ${CH}px; height: 84px; border-radius: 14px; background: ${G.panel}; display: flex; align-items: center; gap: 14px; padding: 0 12px; box-sizing: border-box"><div style="width: 100px; height: 66px; border-radius: 12px; background: #FFFFFF; display: flex; align-items: center; justify-content: center; flex-shrink: 0"><img src="${b(logo)}" alt="" style="width: 92px; height: 60px; object-fit: contain"></div><span style="font-weight: 600; font-size: 22px">${name}</span></div>${cells.join('')}</div>`;
  const hr = (n) => [cell('15:00', '16:00', n, false, true), cell('16:00', '17:00', n, false, true)];
  const rows = [
    row('242bd1a56c08d0855ef8ca15fcbcd4ef', '3ABN', [cell('15:00', '16:00', '3ABN TODAY BIBLE Q&amp;A', true), cell('16:00', '16:30', 'KIDS CAMP KITCHEN FUN'), cell('16:30', '16:45', 'TINY TOTS KITCHEN'), cell('16:45', '17:00', 'TINY TOTS WORSHIP')]),
    row('e40d84f762578caed15688344a03391c', '3ABN Proclaim', [cell('15:00', '16:00', 'REVELATION OF JESUS CHRIST'), cell('16:00', '16:30', 'WHITE HORSE MEDIA'), cell('16:30', '17:00', 'WHITE HORSE MEDIA')]),
    row('3cd27ca3e7d58e9a1aa8273e9c19caa4', '3ABN Kids', [cell('15:00', '15:15', 'HERE I AM SEND ME'), cell('15:15', '15:30', 'TINY TOTS WORSHIP'), cell('15:30', '16:00', 'TINY TOTS FOR JESUS'), cell('16:00', '16:15', 'BIBLE TREASURES'), cell('16:15', '16:30', 'TINY TOTS WORSHIP'), cell('16:30', '16:45', 'BIBLE GEMS'), cell('16:45', '17:00', 'FIT CLUB')]),
    row('8a4ae2c264a612734dc50b5aabb7da57', 'HopeChannel', hr('HopeChannel')),
    row('e2f268b5a36bee5d8c269ca003c3de9e', 'It is Written TV', hr('It is Written TV'))
  ].slice(0, nRows).join('');
  const btn = (label, primary, icon) => `<div style="height: 64px; padding: 0 30px; border-radius: 32px; background: ${primary ? G.gold : G.cell}; color: ${primary ? G.ground : '#FFFFFF'}; display: flex; align-items: center; gap: 12px; font-weight: 700; font-size: 26px; ${primary ? `box-shadow: 0 0 0 5px ${G.ground}, 0 0 0 9px ${G.gold}` : ''}">${icon || ''}${label}</div>`;
  const playIc = `<svg width="20" height="20" viewBox="0 0 24 24"><path d="M6 3l15 9-15 9z" fill="${G.ground}"/></svg>`;
  const pL = o.previewLeft != null ? o.previewLeft : left, pw = o.pw || 560, ph = Math.round(pw * 9 / 16);
  const iL = o.infoLeft != null ? o.infoLeft : pL + pw + 40;
  const ticks = [0, 30, 60, 90].map((t, i) => `<span style="position: absolute; left: ${X0 + t * PPM}px">${['3:00 PM', '3:30', '4:00 PM', '4:30'][i]}</span>`).join('');
  const titleHtml = o.title === false ? '' : `<div style="position: absolute; left: ${left}px; top: 44px; display: flex; align-items: baseline; gap: 18px"><span style="${cond}; font-size: 48px; letter-spacing: 1px">TV GUIDE</span><span style="font-weight: 600; font-size: 24px; color: ${G.t2}">Today · 24 channels</span></div>`;
  const gTop = 486 + top;
  return `${titleHtml}
  <div style="position: absolute; left: ${pL}px; top: ${132 + top}px; width: ${pw}px; height: ${ph}px; border-radius: 20px; overflow: hidden; background: #000000"><img src="${b('c4daed39c492a92a3a5a2eeb01619e11')}" alt="" style="width: 100%; height: 100%; object-fit: cover"><div style="position: absolute; left: 16px; top: 16px; height: 34px; padding: 0 14px; border-radius: 17px; background: ${G.red}; display: flex; align-items: center; gap: 8px; font-weight: 700; font-size: 19px"><span style="width: 8px; height: 8px; border-radius: 4px; background: #FFFFFF"></span>LIVE PREVIEW</div></div>
  <div style="position: absolute; left: ${iL}px; top: ${136 + top}px; right: 64px; display: flex; flex-direction: column; gap: 12px">
    <div style="display: flex; align-items: center; gap: 16px"><div style="width: 98px; height: 70px; border-radius: 12px; background: #FFFFFF; display: flex; align-items: center; justify-content: center"><img src="${b('242bd1a56c08d0855ef8ca15fcbcd4ef')}" alt="" style="width: 88px; height: 62px; object-fit: contain"></div><span style="${cond}; font-size: 30px; color: ${G.gold}">3ABN · CH 1</span></div>
    <div style="${cond}; font-size: 60px; line-height: 1">3ABN TODAY BIBLE Q&amp;A</div>
    <div style="display: flex; align-items: center; gap: 18px; font-size: 25px; color: ${G.t2}"><span>3:00 – 3:55 PM</span><div style="width: 300px; height: 6px; border-radius: 3px; background: ${G.line}"><div style="width: 36%; height: 6px; border-radius: 3px; background: ${G.gold}"></div></div><span>35 min left</span></div>
    <div style="font-size: 24px; color: ${G.t2}"><span style="color: #FFFFFF; font-weight: 600">Next 4:00 PM</span> · 3ABN KIDS CAMP KITCHEN FUN</div>
    <div style="display: flex; gap: 20px; margin-top: 10px">${btn('Watch live', true, playIc)}${btn('Start over', false, svg('catchup', '#FFFFFF', 24, 4))}</div>
  </div>
  <div style="position: absolute; left: ${left}px; top: ${gTop}px; width: ${W}px; height: 40px; ${cond}; font-size: 26px; color: ${G.t2}">${ticks}</div>
  <div style="position: absolute; left: ${left}px; top: ${gTop + 44}px; width: ${W}px; display: flex; flex-direction: column; gap: 8px">${rows}</div>
  <div style="position: absolute; left: ${left + X0 + NOW * PPM - 2}px; top: ${gTop + 38}px; width: 4px; height: ${nRows * 92 + 4}px; background: ${G.gold}; border-radius: 2px"></div>
  <div style="position: absolute; left: ${left + X0 + NOW * PPM - 30}px; top: ${gTop + 4}px; height: 32px; padding: 0 12px; border-radius: 16px; background: ${G.gold}; color: ${G.ground}; ${cond}; font-size: 22px; display: flex; align-items: center">3:20</div>`;
}
const DIM = (x = 0) => `<div style="position: absolute; left: ${x}px; top: 0; right: 0; bottom: 0; background: rgba(5,11,30,0.72)"></div>`;

// N4 · Bottom dock: a floating capsule bar centred at the bottom edge.
function n4() {
  const items = NAV.map(([k, l], i) => `<div style="height: 64px; border-radius: 32px; display: flex; align-items: center; gap: 12px; padding: 0 24px; background: ${i === 0 ? G.gold : 'transparent'}; color: ${i === 0 ? G.ground : G.t2}; ${cond}; font-size: 28px; letter-spacing: 0.5px">${svg(k, i === 0 ? G.ground : G.t2, 30)}${l.toUpperCase()}</div>`).join('');
  return LOGO(64, 36, 150) + CLOCK + guide({ left: 64, rows: 4 }).replace('<span style="' + cond + '; font-size: 48px; letter-spacing: 1px">TV GUIDE</span>', '<span style="' + cond + '; font-size: 48px; letter-spacing: 1px; margin-left: 180px">TV GUIDE</span>') +
    `<div style="position: absolute; left: 50%; bottom: 36px; transform: translateX(-50%); display: flex; gap: 6px; padding: 10px; border-radius: 42px; background: rgba(11,23,51,0.96); box-shadow: 0 0 0 1px ${G.line}, 0 20px 60px rgba(0,0,0,0.7)">${items}</div>`;
}
// N5 · Hero menu: a big condensed text menu in the top-left, cable-box style;
// the preview and the programme move right of it; the guide runs full width.
function n5() {
  const items = NAV.map(([k, l], i) => `<div style="height: 60px; border-radius: 30px; display: flex; align-items: center; gap: 16px; padding: 0 22px; margin-left: -22px; width: 360px; box-sizing: border-box; background: ${i === 0 ? 'rgba(250,211,90,0.14)' : 'transparent'}; color: ${i === 0 ? G.gold : '#E4E8F0'}; ${cond}; font-size: 38px; letter-spacing: 0.5px">${l.toUpperCase()}${i === 0 ? `<span style="margin-left: auto; width: 10px; height: 10px; border-radius: 5px; background: ${G.gold}"></span>` : ''}</div>`).join('');
  return LOGO(64, 36, 168) + CLOCK + `<div style="position: absolute; left: 86px; top: 150px; display: flex; flex-direction: column; gap: 6px">${items}</div>` +
    `<div style="position: absolute; left: 470px; top: 140px; width: 2px; height: 300px; background: ${G.line}"></div>` +
    guide({ left: 64, previewLeft: 510, pw: 480, title: false });
}
// N6 · Menu sheet: at rest only a MENU pill; pressed, a sheet slides in.
function n6() {
  const rows = NAV.map(([k, l, sub], i) => `<div style="height: 96px; border-radius: 24px; display: flex; align-items: center; gap: 20px; padding: 0 22px; background: ${i === 1 ? G.gold : (i === 0 ? 'rgba(250,211,90,0.1)' : 'transparent')}; color: ${i === 1 ? G.ground : '#FFFFFF'}">
      <div style="width: 56px; height: 56px; border-radius: 28px; background: ${i === 1 ? 'rgba(5,11,30,0.12)' : G.cell}; display: flex; align-items: center; justify-content: center">${svg(k, i === 1 ? G.ground : (i === 0 ? G.gold : G.t2), 30)}</div>
      <div style="display: flex; flex-direction: column"><span style="${cond}; font-size: 34px; letter-spacing: 0.5px; color: ${i === 0 ? G.gold : 'inherit'}">${l.toUpperCase()}</span><span style="font-weight: 500; font-size: 20px; opacity: 0.75">${sub}</span></div></div>`).join('');
  return `<div style="position: absolute; left: 64px; top: 48px; height: 56px; border-radius: 28px; background: ${G.panel}; display: flex; align-items: center; gap: 12px; padding: 0 24px 0 18px; ${cond}; font-size: 28px">${svg('menu', '#FFFFFF', 30)}MENU</div>` + CLOCK +
    guide({ left: 64, title: false }).replace('', '') +
    `<div style="position: absolute; left: 230px; top: 44px; display: flex; align-items: baseline; gap: 18px"><span style="${cond}; font-size: 48px; letter-spacing: 1px">TV GUIDE</span><span style="font-weight: 600; font-size: 24px; color: ${G.t2}">Today · 24 channels</span></div>` +
    DIM(0) +
    `<div style="position: absolute; left: 0; top: 0; width: 520px; height: 1080px; background: ${G.panel}; box-shadow: 30px 0 80px rgba(0,0,0,0.6); border-radius: 0 36px 36px 0">
      ${LOGO(48, 40, 186)}
      <div style="position: absolute; left: 28px; top: 190px; width: 464px; display: flex; flex-direction: column; gap: 10px">${rows}</div>
      <div style="position: absolute; left: 50px; bottom: 50px; font-weight: 600; font-size: 21px; color: ${G.t2}">BACK closes the menu</div>
    </div>`;
}
// N7 · Title dropdown: the screen title is the menu ("TV GUIDE ▾").
function n7() {
  const rows = NAV.map(([k, l, sub], i) => `<div style="height: 84px; border-radius: 42px; display: flex; align-items: center; gap: 18px; padding: 0 22px; background: ${i === 2 ? G.gold : 'transparent'}; color: ${i === 2 ? G.ground : '#FFFFFF'}">${svg(k, i === 2 ? G.ground : (i === 0 ? G.gold : G.t2), 32)}<div style="display: flex; flex-direction: column"><span style="${cond}; font-size: 32px; color: ${i === 0 ? G.gold : 'inherit'}">${l.toUpperCase()}</span><span style="font-weight: 500; font-size: 19px; opacity: 0.75">${sub}</span></div>${i === 0 ? `<span style="margin-left: auto; font-weight: 700; font-size: 18px; color: ${G.gold}">NOW</span>` : ''}</div>`).join('');
  return LOGO(64, 36, 150) + CLOCK + guide({ left: 64, title: false }) + DIM(0) +
    `<div style="position: absolute; left: 240px; top: 40px; height: 68px; border-radius: 34px; background: ${G.gold}; color: ${G.ground}; display: flex; align-items: center; gap: 12px; padding: 0 22px 0 28px; ${cond}; font-size: 44px; letter-spacing: 1px; box-shadow: 0 0 0 5px ${G.ground}, 0 0 0 9px ${G.gold}">TV GUIDE${svg('down', G.ground, 32, 4)}</div>` +
    `<div style="position: absolute; left: 240px; top: 132px; width: 470px; padding: 12px; box-sizing: border-box; border-radius: 34px; background: ${G.panel}; box-shadow: 0 0 0 1px ${G.line}, 0 30px 80px rgba(0,0,0,0.7); display: flex; flex-direction: column; gap: 6px">${rows}</div>`;
}
// N8 · Edge strip: a 72 px strip, icons only, the active one marked by a gold
// bar; the label of the focused icon appears as a tag beside it.
function n8() {
  const items = NAV.map(([k, l], i) => `<div style="position: relative; width: 72px; height: 72px; display: flex; align-items: center; justify-content: center">${i === 0 ? `<div style="position: absolute; left: 0; top: 16px; width: 5px; height: 40px; border-radius: 3px; background: ${G.gold}"></div>` : ''}${svg(k, i === 0 ? G.gold : G.t2, 34)}</div>`).join('');
  return `<div style="position: absolute; left: 0; top: 0; width: 72px; height: 1080px; background: ${G.panel}; box-shadow: 1px 0 0 ${G.line}"><div style="position: absolute; left: 0; top: 300px; display: flex; flex-direction: column; gap: 18px">${items}</div></div>` +
    LOGO(104, 36, 150) + CLOCK + guide({ left: 104 }).replace(`left: 104px; top: 44px; display: flex`, `left: 284px; top: 44px; display: flex`);
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
<link href="https://fonts.googleapis.com/css2?family=Barlow+Condensed:wght@600;700&amp;family=Barlow:wght@500;600;700&amp;display=swap" rel="stylesheet">
<style>
body{margin:0}
</style>
</helmet>
<div style="width: 1920px; height: 1080px; position: relative; overflow: hidden; background: ${G.ground}; color: #FFFFFF; font-family: Barlow, sans-serif">${body}
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
const boards = [
  ['BN4-BottomDock', 'B · Nav 4 · Bottom dock', n4()],
  ['BN5-HeroMenu', 'B · Nav 5 · Hero menu', n5()],
  ['BN6-MenuSheet', 'B · Nav 6 · Menu sheet (open)', n6()],
  ['BN7-TitleDropdown', 'B · Nav 7 · Title dropdown (open)', n7()],
  ['BN8-EdgeStrip', 'B · Nav 8 · Edge strip', n8()]
];
for (const [f, t, body] of boards) fs.writeFileSync(path.join(OUT, f + '.dc.html'), page(t, body));
console.log(boards.map((x) => x[0]).join(' '));
