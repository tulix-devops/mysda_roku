// B · Guide, navigation rethought (owner, 2026-10-06: "really bad navigation
// designs, we can do better"). Not another menu skin: Languages, Radio and
// Catch-up are views of ONE schedule (a filter, a channel set, the past), so
// they live IN the guide; Account is the only true destination.
//   G1 · Category spine: the guide's own left column is a list of filters.
//   G2 · Channel list + day timeline: channels down the left, the focused
//        channel's whole day (past included) on the right, a big live preview.
const fs = require('fs');
const path = require('path');
const OUT = path.join(__dirname, 'canvas', 'project');
const b = (id) => '/_blob/' + id;
const G = { ground: '#050B1E', panel: '#0A1630', cell: '#0F1E3C', live: '#15284D', line: '#1B2C52', gold: '#FAD35A', red: '#F0262B', t2: '#9FADC8', t3: '#6B7A99' };
const cond = "font-family: 'Barlow Condensed', sans-serif; font-weight: 700";
const ICON = {
  user: 'M26.5 12.5a6.5 6.5 0 1 1-13 0 6.5 6.5 0 0 1 13 0zM7 34c0-7.5 5.5-11.5 13-11.5S33 26.5 33 34',
  search: 'M27 17a10 10 0 1 1-20 0 10 10 0 0 1 20 0zM24.5 24.5L34 34',
  back: 'M24 9L13 20l11 11',
  down: 'M11 16l9 9 9-9',
  play: 'M12 7l21 13-21 13z',
  restart: 'M8 13a14 14 0 1 1-2 9M4.5 8l2.1 7.3 7-2.3'
};
const svg = (k, c, s = 30, w = 3) => `<svg width="${s}" height="${s}" viewBox="0 0 40 40" fill="none" stroke="${c}" stroke-width="${w}" stroke-linecap="round" stroke-linejoin="round"><path d="${ICON[k]}"/></svg>`;
const logoPlate = (id, w, h) => `<div style="width: ${w}px; height: ${h}px; border-radius: 12px; background: #FFFFFF; display: flex; align-items: center; justify-content: center; flex-shrink: 0"><img src="${b(id)}" alt="" style="width: ${w - 8}px; height: ${h - 6}px; object-fit: contain"></div>`;
const header = () => `<img src="${b('ec7c10bad0117787e03b001592d65bba')}" alt="mySDAtv" style="position: absolute; left: 72px; top: 30px; width: 150px; height: 78px">
  <div style="position: absolute; right: 72px; top: 42px; display: flex; align-items: center; gap: 18px">
    <span style="${cond}; font-size: 34px">3:20 PM</span><span style="font-weight: 600; font-size: 24px; color: ${G.t2}; margin-right: 14px">Sunday, Oct 5</span>
    <div style="width: 56px; height: 56px; border-radius: 28px; background: ${G.cell}; display: flex; align-items: center; justify-content: center">${svg('search', G.t2, 28)}</div>
    <div style="width: 56px; height: 56px; border-radius: 28px; background: ${G.cell}; display: flex; align-items: center; justify-content: center">${svg('user', G.t2, 28)}</div>
  </div>`;
const btn = (label, primary, icon) => `<div style="height: 64px; padding: 0 30px; border-radius: 32px; background: ${primary ? G.gold : G.cell}; color: ${primary ? G.ground : '#FFFFFF'}; display: flex; align-items: center; gap: 12px; font-weight: 700; font-size: 25px; ">${icon ? svg(icon, primary ? G.ground : '#FFFFFF', 22, 4) : ''}${label}</div>`;
const pill = (t, bg, fg) => `<span style="height: 34px; padding: 0 14px; border-radius: 17px; background: ${bg}; color: ${fg}; display: inline-flex; align-items: center; gap: 8px; font-weight: 700; font-size: 18px; letter-spacing: 1px">${t}</span>`;
const LIVE = pill('<span style="width: 8px; height: 8px; border-radius: 4px; background: #FFFFFF"></span>LIVE', G.red, '#FFFFFF');

// ------------------------------------------------------------------ G1 ----
const SPINE = [['All channels', '40'], ['English', '24'], ['Español', '6'], ['Português', '3'], ['More languages', '7'], ['3ABN family', '11'], ['LLBN family', '9'], ['Radio', '10']];
function spine(focusIdx, selIdx, inSpine) {
  const rows = SPINE.map(([l, n], i) => {
    const f = inSpine && i === focusIdx, s = i === selIdx && !f;
    return `<div style="height: 62px; border-radius: 31px; display: flex; align-items: center; padding: 0 22px; background: ${f ? G.gold : (s ? 'rgba(250,211,90,0.1)' : 'transparent')}; color: ${f ? G.ground : (s ? G.gold : '#E6EAF2')}; font-weight: ${f || s ? 700 : 600}; font-size: 25px; ${f ? 'box-shadow: 0 10px 30px rgba(250,211,90,0.3)' : ''}"><span>${l}</span><span style="margin-left: auto; font-weight: 600; font-size: 21px; opacity: ${f ? 0.8 : 0.55}">${n}</span></div>`;
  }).join('');
  return `<div style="position: absolute; left: 56px; top: 150px; width: 300px; display: flex; flex-direction: column; gap: 4px">
    <div style="${cond}; font-size: 20px; letter-spacing: 3px; color: ${G.t3}; padding: 0 22px 10px">BROWSE</div>${rows}
  </div>
  <div style="position: absolute; left: 72px; bottom: 40px; width: 268px; border-radius: 22px; background: ${G.panel}; box-shadow: 0 0 0 1px ${G.line}; padding: 18px 20px; box-sizing: border-box; display: flex; gap: 14px; align-items: flex-start">
    <div style="width: 40px; height: 40px; border-radius: 20px; background: ${G.cell}; display: flex; align-items: center; justify-content: center; flex-shrink: 0">${svg('restart', G.gold, 22, 4)}</div>
    <div style="font-size: 19px; line-height: 1.4; color: ${G.t2}"><span style="color: #FFFFFF; font-weight: 700">Catch-up</span> · move left in the guide to go back up to 21 days</div>
  </div>`;
}
function g1Grid(rows, focusRow, guideFocus) {
  const L = 380, W = 1848 - L, CH = 300, X0 = CH + 12, PPM = (W - X0) / 120, NOW = 20;
  const m = (hm) => { const [h, mm] = hm.split(':').map(Number); return (h - 15) * 60 + mm; };
  const cell = (s, e, title, focus, sub) => {
    const a = m(s), bb = Math.min(m(e), 120), live = a <= NOW && bb > NOW;
    return `<div style="position: absolute; top: 0; left: ${X0 + a * PPM}px; width: ${Math.max(0, (bb - a) * PPM - 8)}px; height: 92px; border-radius: 16px; overflow: hidden; background: ${focus ? G.gold : (live ? G.live : G.cell)}; color: ${focus ? G.ground : '#FFFFFF'}; box-sizing: border-box; padding: 12px 18px; display: flex; flex-direction: column; justify-content: center; gap: 4px; ${focus ? 'box-shadow: 0 12px 34px rgba(250,211,90,0.35)' : ''}"><div style="font-weight: 700; font-size: 23px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis">${title}</div>${sub ? `<div style="font-weight: 500; font-size: 18px; opacity: 0.75; white-space: nowrap">${sub}</div>` : ''}</div>`;
  };
  const rowsHtml = rows.map(([logo, name, ch, cells], ri) => `<div style="position: relative; height: 92px; opacity: ${ri < 5 ? 1 : 0.5}">
      <div style="position: absolute; left: 0; top: 0; width: ${CH}px; height: 92px; border-radius: 16px; background: ${G.panel}; display: flex; align-items: center; gap: 14px; padding: 0 12px; box-sizing: border-box">${logoPlate(logo, 104, 72)}<div style="display: flex; flex-direction: column; gap: 2px; min-width: 0"><span style="font-weight: 700; font-size: 21px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis">${name}</span><span style="${cond}; font-size: 17px; color: ${G.t3}">${ch}</span></div></div>
      ${cells.map((c) => cell(c[0], c[1], c[2], guideFocus && ri === focusRow && c[3], c[4])).join('')}</div>`).join('');
  const ticks = [0, 30, 60, 90].map((t, i) => `<span style="position: absolute; left: ${X0 + t * PPM}px">${['3:00 PM', '3:30', '4:00 PM', '4:30'][i]}</span>`).join('');
  return `<div style="position: absolute; left: ${L}px; top: 486px; width: ${W}px; height: 40px; ${cond}; font-size: 25px; color: ${G.t2}">
      <span style="position: absolute; left: 0; top: -4px; height: 36px; padding: 0 16px; border-radius: 18px; background: ${G.cell}; display: inline-flex; align-items: center; gap: 8px; font-size: 22px; color: #FFFFFF">${svg('back', G.t2, 18, 4)}TODAY</span>${ticks}</div>
    <div style="position: absolute; left: ${L}px; top: 532px; width: ${W}px; display: flex; flex-direction: column; gap: 8px">${rowsHtml}</div>
    <div style="position: absolute; left: ${L + X0 + NOW * PPM - 2}px; top: 524px; width: 4px; height: 512px; background: ${G.gold}; border-radius: 2px"></div>
    <div style="position: absolute; left: ${L + X0 + NOW * PPM - 30}px; top: 486px; height: 32px; padding: 0 12px; border-radius: 16px; background: ${G.gold}; color: ${G.ground}; ${cond}; font-size: 22px; display: flex; align-items: center">3:20</div>`;
}
function g1Hero(thumb, logo, eyebrow, title, time, pct, next) {
  return `<div style="position: absolute; left: 380px; top: 136px; width: 528px; height: 297px; border-radius: 22px; overflow: hidden; background: #000000"><img src="${b(thumb)}" alt="" style="width: 100%; height: 100%; object-fit: cover"><div style="position: absolute; left: 16px; top: 16px">${LIVE}</div></div>
  <div style="position: absolute; left: 948px; top: 140px; right: 72px; display: flex; flex-direction: column; gap: 14px">
    <div style="display: flex; align-items: center; gap: 16px">${logoPlate(logo, 98, 70)}<span style="${cond}; font-size: 30px; color: ${G.gold}">${eyebrow}</span></div>
    <div style="${cond}; font-size: 62px; line-height: 1">${title}</div>
    <div style="display: flex; align-items: center; gap: 18px; font-size: 25px; color: ${G.t2}"><span>${time}</span><div style="width: 280px; height: 6px; border-radius: 3px; background: ${G.line}"><div style="width: ${pct}; height: 6px; border-radius: 3px; background: ${G.gold}"></div></div></div>
    <div style="font-size: 23px; color: ${G.t2}">${next}</div>
    <div style="display: flex; gap: 20px; margin-top: 6px">${btn('Watch live', true, 'play')}${btn('Start over', false, 'restart')}</div>
  </div>`;
}
const ENG = [
  ['242bd1a56c08d0855ef8ca15fcbcd4ef', '3ABN', 'CH 1', [['15:00', '16:00', '3ABN TODAY BIBLE Q&amp;A', true], ['16:00', '16:30', 'KIDS CAMP KITCHEN FUN'], ['16:30', '16:45', 'TINY TOTS KITCHEN'], ['16:45', '17:00', 'TINY TOTS WORSHIP']]],
  ['e40d84f762578caed15688344a03391c', '3ABN Proclaim', 'CH 2', [['15:00', '16:00', 'REVELATION OF JESUS CHRIST'], ['16:00', '16:30', 'WHITE HORSE MEDIA'], ['16:30', '17:00', 'WHITE HORSE MEDIA']]],
  ['3cd27ca3e7d58e9a1aa8273e9c19caa4', '3ABN Kids Network', 'CH 5', [['15:00', '15:15', 'HERE I AM SEND ME'], ['15:15', '15:30', 'TINY TOTS WORSHIP'], ['15:30', '16:00', 'TINY TOTS FOR JESUS'], ['16:00', '16:15', 'BIBLE TREASURES'], ['16:15', '16:30', 'TINY TOTS WORSHIP'], ['16:30', '16:45', 'BIBLE GEMS'], ['16:45', '17:00', 'FIT CLUB']]],
  ['8a4ae2c264a612734dc50b5aabb7da57', 'HopeChannel', 'CH 9', [['15:00', '16:00', 'Live programming', false, '3:00 – 4:00 PM'], ['16:00', '17:00', 'Live programming', false, '4:00 – 5:00 PM']]],
  ['e2f268b5a36bee5d8c269ca003c3de9e', 'It is Written TV', 'CH 24', [['15:00', '16:00', 'Live programming', false, '3:00 – 4:00 PM'], ['16:00', '17:00', 'Live programming', false, '4:00 – 5:00 PM']]]
];
const ESP = [
  ['f6c61295f0443e7ad9bb2b7f1a99ddee', '3ABN Latino', 'CH 28', [['15:00', '15:30', 'MARAVILLOSA CREACIÓN', true], ['15:30', '16:00', 'REMEDIOS CASEROS'], ['16:00', '16:30', 'ESTRELLITAS DE JESÚS'], ['16:30', '17:00', 'JESUS 4 ASIA NOW']]],
  ['b01b57a70c67310359e8c88197b9f4a7', 'Nuevo Tiempo', 'CH 31', [['15:00', '16:00', 'Live programming', false, '3:00 – 4:00 PM'], ['16:00', '17:00', 'Live programming', false, '4:00 – 5:00 PM']]],
  ['1665be3f90d7999cb068ba7946955070', 'LLBN Latino', 'CH 32', [['15:00', '16:00', 'Live programming', false, '3:00 – 4:00 PM'], ['16:00', '17:00', 'Live programming', false, '4:00 – 5:00 PM']]]
];
const g1a = header() + spine(1, 1, false) +
  g1Hero('c4daed39c492a92a3a5a2eeb01619e11', '242bd1a56c08d0855ef8ca15fcbcd4ef', 'ENGLISH · 3ABN · CH 1', '3ABN TODAY BIBLE Q&amp;A', '3:00 – 3:55 PM · 35 min left', '36%', '<span style="color: #FFFFFF; font-weight: 600">Next 4:00 PM</span> · 3ABN KIDS CAMP KITCHEN FUN') +
  g1Grid(ENG, 0, true);
const g1b = header() + spine(2, 1, true) +
  g1Hero('599477377df6b3d7972470835520c306', 'f6c61295f0443e7ad9bb2b7f1a99ddee', 'ESPAÑOL · 3ABN LATINO · CH 28', 'MARAVILLOSA CREACIÓN', '3:00 – 3:28 PM · 8 min left', '71%', '<span style="color: #FFFFFF; font-weight: 600">Next 3:30 PM</span> · REMEDIOS CASEROS') +
  g1Grid(ESP, 0, false) +
  `<div style="position: absolute; left: 380px; top: 840px; width: 1468px; height: 92px; border-radius: 16px; box-shadow: inset 0 0 0 2px ${G.line}; display: flex; align-items: center; padding: 0 26px; box-sizing: border-box; font-size: 22px; color: ${G.t2}"><span style="color: #FFFFFF; font-weight: 700; margin-right: 12px">+3 more Español channels</span>Better Vida Mejor · Sum TV Latino · Good News Mas TV</div>`;

// ------------------------------------------------------------------ G2 ----
const LIST = [
  ['242bd1a56c08d0855ef8ca15fcbcd4ef', '3ABN', '3ABN TODAY BIBLE Q&amp;A', '36%'],
  ['e40d84f762578caed15688344a03391c', '3ABN Proclaim', 'REVELATION OF JESUS CHRIST', '35%'],
  ['3cd27ca3e7d58e9a1aa8273e9c19caa4', '3ABN Kids Network', 'TINY TOTS WORSHIP', '36%'],
  ['8a4ae2c264a612734dc50b5aabb7da57', 'HopeChannel', 'Live now · 3 PM hour', '33%'],
  ['e2f268b5a36bee5d8c269ca003c3de9e', 'It is Written TV', 'Live now · 3 PM hour', '33%'],
  ['6ec2f978278a61060737b8b22d12c18e', 'Amazing Facts', 'Live now · 3 PM hour', '33%'],
  ['163b3b93da32b56730990408244fbfaa', 'Good News TV', 'Live now · 3 PM hour', '33%']
];
function g2List(focusIdx, listFocus) {
  const rows = LIST.map(([logo, name, now, pct], i) => {
    const f = i === focusIdx;
    const bg = f ? (listFocus ? G.gold : G.live) : 'transparent';
    const fg = f && listFocus ? G.ground : '#FFFFFF';
    return `<div style="height: 108px; border-radius: 22px; background: ${bg}; display: flex; align-items: center; gap: 18px; padding: 0 14px; ${f && listFocus ? 'box-shadow: 0 12px 34px rgba(250,211,90,0.3)' : ''}">
      ${logoPlate(logo, 116, 82)}
      <div style="display: flex; flex-direction: column; gap: 6px; min-width: 0; flex-grow: 1">
        <span style="font-weight: 700; font-size: 25px; color: ${fg}">${name}</span>
        <span style="font-weight: 500; font-size: 20px; color: ${f && listFocus ? G.ground : G.t2}; opacity: ${f && listFocus ? 0.8 : 1}; white-space: nowrap; overflow: hidden; text-overflow: ellipsis">${now}</span>
        <div style="height: 4px; border-radius: 2px; background: ${f && listFocus ? 'rgba(5,11,30,0.2)' : G.line}"><div style="width: ${pct}; height: 4px; border-radius: 2px; background: ${f && listFocus ? G.ground : G.red}"></div></div>
      </div></div>`;
  }).join('');
  return `<div style="position: absolute; left: 56px; top: 140px; width: 560px">
      <div style="height: 60px; border-radius: 30px; background: ${G.cell}; display: inline-flex; align-items: center; gap: 12px; padding: 0 22px; margin: 0 0 14px 14px; font-weight: 700; font-size: 24px">English <span style="color: ${G.t2}; font-weight: 600">· 24 channels</span>${svg('down', G.t2, 24, 4)}</div>
      <div style="display: flex; flex-direction: column; gap: 6px">${rows}</div>
    </div>`;
}
const TL = [
  ['2:00', 'ACTION 4 LIFE', '917133d468c5f2657305a93b11198669', 'past'],
  ['2:30', 'A WOLF IN SHEEP’S CLOTHING', '677cf0801d486ffa412e4bf103d043d0', 'past'],
  ['3:00', '3ABN TODAY BIBLE Q&amp;A', 'c4daed39c492a92a3a5a2eeb01619e11', 'live'],
  ['4:00', 'KIDS CAMP KITCHEN FUN', '', 'later'],
  ['4:30', 'TINY TOTS KITCHEN', '', 'later']
];
function g2Right(shown, focusTl) {
  const cards = TL.map(([t, title, thumb, st], i) => {
    const f = i === focusTl;
    return `<div style="width: 268px; flex-shrink: 0; display: flex; flex-direction: column; gap: 10px; transform: scale(${f ? 1.04 : 1}); transform-origin: left bottom">
      <div style="position: relative; height: 151px; border-radius: 18px; overflow: hidden; background: ${thumb ? '#000000' : G.cell}; box-shadow: ${f ? `0 0 0 4px ${G.gold}, 0 14px 34px rgba(0,0,0,0.6)` : 'none'}; display: flex; align-items: center; justify-content: center">
        ${thumb ? `<img src="${b(thumb)}" alt="" style="width: 100%; height: 100%; object-fit: cover; opacity: ${st === 'past' ? 0.85 : 1}">` : `<span style="${cond}; font-size: 30px; color: ${G.t3}">${t} PM</span>`}
        <div style="position: absolute; left: 10px; top: 10px">${st === 'live' ? LIVE : (st === 'past' ? pill('REPLAY', 'rgba(5,11,30,0.85)', '#FFFFFF') : pill('LATER', 'rgba(5,11,30,0.6)', G.t2))}</div>
      </div>
      <div style="${cond}; font-size: 22px; color: ${f ? G.gold : G.t2}">${t} PM</div>
      <div style="font-weight: 700; font-size: 21px; line-height: 1.2; color: ${f ? '#FFFFFF' : '#DDE3EE'}; overflow: hidden; display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical">${title}</div>
    </div>`;
  }).join('');
  return `<div style="position: absolute; left: 672px; top: 140px; width: 760px; height: 428px; border-radius: 26px; overflow: hidden; background: #000000; box-shadow: 0 30px 80px rgba(0,0,0,0.6)"><img src="${b(shown === 1 ? '677cf0801d486ffa412e4bf103d043d0' : 'c4daed39c492a92a3a5a2eeb01619e11')}" alt="" style="width: 100%; height: 100%; object-fit: cover"><div style="position: absolute; left: 20px; top: 20px">${shown === 1 ? pill('REPLAY · 2:30 PM', 'rgba(5,11,30,0.85)', '#FFFFFF') : LIVE}</div></div>
  <div style="position: absolute; left: 1468px; top: 146px; right: 72px; display: flex; flex-direction: column; gap: 14px">
    <span style="${cond}; font-size: 26px; color: ${G.gold}">3ABN · CH 1</span>
    <div style="${cond}; font-size: 48px; line-height: 1.02">${shown === 1 ? 'A WOLF IN SHEEP’S CLOTHING' : '3ABN TODAY BIBLE Q&amp;A'}</div>
    <div style="font-size: 23px; color: ${G.t2}">${shown === 1 ? 'Today · 2:30 – 2:58 PM · 28 min' : '3:00 – 3:55 PM · 35 min left'}</div>
    <div style="display: flex; flex-direction: column; gap: 14px; margin-top: 12px">${shown === 1 ? btn('Play from start', true, 'play') + btn('Back to live', false) : btn('Watch live', true, 'play') + btn('Start over', false, 'restart')}</div>
  </div>
  <div style="position: absolute; left: 672px; top: 610px; right: 72px; display: flex; align-items: center; gap: 16px">
    <span style="${cond}; font-size: 30px">TODAY ON 3ABN</span>
    <span style="height: 40px; padding: 0 16px; border-radius: 20px; background: ${G.cell}; display: inline-flex; align-items: center; gap: 8px; font-weight: 700; font-size: 20px">${svg('back', G.t2, 18, 4)}Yesterday</span>
    <span style="margin-left: auto; font-size: 20px; color: ${G.t2}">37 programmes · 21 days back</span>
  </div>
  <div style="position: absolute; left: 672px; top: 670px; width: 1176px; display: flex; gap: 24px; overflow: hidden">${cards}</div>`;
}
const g2a = header() + g2List(0, true) + g2Right(2, -1);
const g2b = header() + g2List(0, false) + g2Right(1, 1);

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
  ['BG1a-Spine', 'B · G1 · Category spine, focus in the guide', g1a],
  ['BG1b-Spine-Filter', 'B · G1 · Category spine, focus on Español (the guide filters live)', g1b],
  ['BG2a-ChannelList', 'B · G2 · Channel list + day timeline, focus on a channel', g2a],
  ['BG2b-ChannelList-Replay', 'B · G2 · Channel list + day timeline, a replay focused', g2b]
];
for (const [f, t, body] of boards) fs.writeFileSync(path.join(OUT, f + '.dc.html'), page(t, body));
console.log(boards.map((x) => x[0]).join(' '));
