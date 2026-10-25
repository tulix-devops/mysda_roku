// B · Guide, all eight screens in both rethought navigation models (owner,
// 2026-10-06: "all screens… both G1 and G2"). Shapes are B-1; one focus per screen.
//   G1 · Category spine: the guide's left column filters; time is catch-up.
//   G2 · Channel list + day timeline.
const fs = require('fs');
const path = require('path');
const OUT = path.join(__dirname, 'canvas', 'project');
const b = (id) => '/_blob/' + id;
const G = { ground: '#050B1E', panel: '#0A1630', cell: '#0F1E3C', live: '#15284D', line: '#1B2C52', gold: '#FAD35A', red: '#F0262B', t2: '#9FADC8', t3: '#6B7A99' };
const cond = "font-family: 'Barlow Condensed', sans-serif; font-weight: 700";
const ICON = {
  user: 'M26.5 12.5a6.5 6.5 0 1 1-13 0 6.5 6.5 0 0 1 13 0zM7 34c0-7.5 5.5-11.5 13-11.5S33 26.5 33 34',
  search: 'M27 17a10 10 0 1 1-20 0 10 10 0 0 1 20 0zM24.5 24.5L34 34',
  back: 'M24 9L13 20l11 11', fwd: 'M16 9l11 11-11 11', down: 'M11 16l9 9 9-9', up: 'M11 24l9-9 9 9',
  play: 'M12 7l21 13-21 13z', restart: 'M8 13a14 14 0 1 1-2 9M4.5 8l2.1 7.3 7-2.3',
  pause: 'M13 9v22M27 9v22', check: 'M9 21l7 7 15-16', lock: 'M11 18h18a3 3 0 0 1 3 3v12a3 3 0 0 1-3 3H11a3 3 0 0 1-3-3V21a3 3 0 0 1 3-3zM14 18v-5a6 6 0 0 1 12 0v5'
};
const svg = (k, c, s = 30, w = 3) => `<svg width="${s}" height="${s}" viewBox="0 0 40 40" fill="none" stroke="${c}" stroke-width="${w}" stroke-linecap="round" stroke-linejoin="round"><path d="${ICON[k]}"/></svg>`;
const plate = (id, w, h, r = 12) => `<div style="width: ${w}px; height: ${h}px; border-radius: ${r}px; background: #FFFFFF; display: flex; align-items: center; justify-content: center; flex-shrink: 0"><img src="${b(id)}" alt="" style="width: ${w - 8}px; height: ${h - 6}px; object-fit: contain"></div>`;
const pill = (t, bg, fg) => `<span style="height: 34px; padding: 0 14px; border-radius: 17px; background: ${bg}; color: ${fg}; display: inline-flex; align-items: center; gap: 8px; font-weight: 700; font-size: 18px; letter-spacing: 1px">${t}</span>`;
const LIVE = pill('<span style="width: 8px; height: 8px; border-radius: 4px; background: #FFFFFF"></span>LIVE', G.red, '#FFFFFF');
// A button; `focus` adds the gold ring (only ever ONE focused element a screen).
const btn = (label, primary, icon, focus) => `<div style="height: 64px; padding: 0 30px; border-radius: 32px; background: ${primary ? G.gold : G.cell}; color: ${primary ? G.ground : '#FFFFFF'}; display: flex; align-items: center; gap: 12px; font-weight: 700; font-size: 25px; white-space: nowrap; ${focus ? `box-shadow: 0 0 0 5px ${G.ground}, 0 0 0 9px ${primary ? G.gold : '#FFFFFF'}` : ''}">${icon ? svg(icon, primary ? G.ground : '#FFFFFF', 22, 4) : ''}${label}</div>`;
const header = (crumb) => `<img src="${b('ec7c10bad0117787e03b001592d65bba')}" alt="mySDAtv" style="position: absolute; left: 72px; top: 30px; width: 150px; height: 78px">
  ${crumb ? `<div style="position: absolute; left: 252px; top: 50px; display: flex; align-items: center; gap: 10px; ${cond}; font-size: 30px; color: ${G.t2}">${svg('back', G.t2, 26, 4)}${crumb}</div>` : ''}
  <div style="position: absolute; right: 72px; top: 42px; display: flex; align-items: center; gap: 18px">
    <span style="${cond}; font-size: 34px">3:20 PM</span><span style="font-weight: 600; font-size: 24px; color: ${G.t2}; margin-right: 14px">Sunday, Oct 5</span>
    <div style="width: 56px; height: 56px; border-radius: 28px; background: ${G.cell}; display: flex; align-items: center; justify-content: center">${svg('search', G.t2, 28)}</div>
    <div style="width: 56px; height: 56px; border-radius: 28px; background: ${G.cell}; display: flex; align-items: center; justify-content: center">${svg('user', G.t2, 28)}</div>
  </div>`;
const VIDEO = (id) => `<img src="${b(id)}" alt="" style="position: absolute; inset: 0; width: 1920px; height: 1080px; object-fit: cover; filter: blur(6px); transform: scale(1.03)">`;

// ------------------------------------------------------------- data ----
const L = {
  abn: '242bd1a56c08d0855ef8ca15fcbcd4ef', pro: 'e40d84f762578caed15688344a03391c', kids: '3cd27ca3e7d58e9a1aa8273e9c19caa4',
  hope: '8a4ae2c264a612734dc50b5aabb7da57', iiw: 'e2f268b5a36bee5d8c269ca003c3de9e', af: '6ec2f978278a61060737b8b22d12c18e', gn: '163b3b93da32b56730990408244fbfaa',
  lat: 'f6c61295f0443e7ad9bb2b7f1a99ddee', nt: 'b01b57a70c67310359e8c88197b9f4a7', llbnlat: '1665be3f90d7999cb068ba7946955070',
  r1: '2888c735f196e4ced270258e4bd0be07', r2: 'dfe63e8c017361de0001a951b2020d2e', r3: '7a52b253fa820b19ca2052f34366480f', r4: 'c3213fdf92f289d37c4272c832a8e8dd', r5: '5208d441840f2b0e53a315bbda40e0db', r6: 'c72a58266bbb3eeb731eaa768070d32a'
};
const T = { now3abn: 'c4daed39c492a92a3a5a2eeb01619e11', wolf: '677cf0801d486ffa412e4bf103d043d0', action: '917133d468c5f2657305a93b11198669', proNow: '0ac5dbae153d93324008faeb65c388ea', proIIW: '653491aec2d0952a7094d2935614b6b7', proPaul: '17e0616bb1dfe499be2559ba86cf7ea7', kidsBuzz: '9ed3f789c476b6ac7046dc81329884dc', kidsNow: '4c1200060836665f27945f02be21cf3f', latNow: '599477377df6b3d7972470835520c306', hope2: 'a6d6fc68979c3232e0db6cac7afd6b3e', hope3: '47e13eaa7d6c8fe02b87cd4c4db3c6f7', iiw2: '9deb069f8233c879a067b185cdf3873b', iiw3: 'fd3818e84422d8b0a384d0b8e35d2f3a', carter5: '07c58215b9f879d07074321905f8dd66', carter530: 'fb366e55403dbba5dcf6255c5f073fb1', carterOct1: 'baf69888e1507df3a205effe8c2920b3', y1500: '09cd58a21532737a4cbc03a37e5424c6', y1600: '5f1ebad597cb3a611138b655b8d1dcea', y1800: 'c5509560b951f7e24f97d7ccca4558cf', y1830: '01fe2a39338e9d9ed47e3493240a096a' };

// ---------------------------------------------------------- G1 parts ----
const SPINE = [['All channels', '40'], ['English', '24'], ['Español', '6'], ['Português', '3'], ['More languages', '7'], ['3ABN family', '11'], ['LLBN family', '9'], ['Radio', '10']];
function spine(sel, focus) {
  const rows = SPINE.map(([l, n], i) => {
    const f = i === focus, s = i === sel && !f;
    return `<div style="height: 62px; border-radius: 31px; display: flex; align-items: center; padding: 0 22px; background: ${f ? G.gold : (s ? 'rgba(250,211,90,0.1)' : 'transparent')}; color: ${f ? G.ground : (s ? G.gold : '#E6EAF2')}; font-weight: ${f || s ? 700 : 600}; font-size: 25px; ${f ? 'box-shadow: 0 10px 30px rgba(250,211,90,0.3)' : ''}"><span>${l}</span><span style="margin-left: auto; font-weight: 600; font-size: 21px; opacity: ${f ? 0.8 : 0.55}">${n}</span></div>`;
  }).join('');
  return `<div style="position: absolute; left: 56px; top: 150px; width: 300px; display: flex; flex-direction: column; gap: 4px"><div style="${cond}; font-size: 20px; letter-spacing: 3px; color: ${G.t3}; padding: 0 22px 10px">BROWSE</div>${rows}</div>
  <div style="position: absolute; left: 72px; bottom: 40px; width: 268px; border-radius: 22px; background: ${G.panel}; box-shadow: 0 0 0 1px ${G.line}; padding: 18px 20px; box-sizing: border-box; display: flex; gap: 14px; align-items: flex-start"><div style="width: 40px; height: 40px; border-radius: 20px; background: ${G.cell}; display: flex; align-items: center; justify-content: center; flex-shrink: 0">${svg('restart', G.gold, 22, 4)}</div><div style="font-size: 19px; line-height: 1.4; color: ${G.t2}"><span style="color: #FFFFFF; font-weight: 700">Catch-up</span> · move left in the guide to go back up to 21 days</div></div>`;
}
// The guide grid. win = [startHour, startMin]; span in minutes; now = minutes
// from the window start (or null); rows: [logo, name, ch, cells]; a cell:
// [start, end, title, {focus, sub, thumb}].
function grid({ win, span = 120, now, rows, rowH = 92, ticks, chip, Lx = 380, top = 486 }) {
  const _u = 0, W = 1848 - Lx, CH = 300, X0 = CH + 12, PPM = (W - X0) / span;
  const m = (hm) => { const [h, mm] = hm.split(':').map(Number); return (h - win[0]) * 60 + mm - win[1]; };
  const cell = ([s, e, title, o = {}]) => {
    const a = Math.max(m(s), 0), bb = Math.min(m(e), span), live = now !== null && a <= now && bb > now;
    const w = Math.max(0, (bb - a) * PPM - 8);
    const thumb = o.thumb && w > 330;
    return `<div style="position: absolute; top: 0; left: ${X0 + a * PPM}px; width: ${w}px; height: ${rowH}px; border-radius: 16px; overflow: hidden; background: ${o.focus ? G.gold : (live ? G.live : G.cell)}; color: ${o.focus ? G.ground : '#FFFFFF'}; box-sizing: border-box; padding: 10px ${thumb ? 10 : 18}px; display: flex; align-items: center; gap: 14px; ${o.focus ? 'box-shadow: 0 12px 34px rgba(250,211,90,0.35)' : ''}">
      ${thumb ? `<div style="width: ${Math.round((rowH - 20) * 16 / 9)}px; height: ${rowH - 20}px; border-radius: 10px; overflow: hidden; flex-shrink: 0; background: #000000"><img src="${b(o.thumb)}" alt="" style="width: 100%; height: 100%; object-fit: cover"></div>` : ''}
      <div style="display: flex; flex-direction: column; gap: 4px; min-width: 0"><div style="font-weight: 700; font-size: 23px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis">${title}</div>${o.sub ? `<div style="font-weight: 500; font-size: 18px; opacity: 0.75; white-space: nowrap">${o.sub}</div>` : ''}</div></div>`;
  };
  const rowsHtml = rows.map(([logo, name, ch, cells]) => `<div style="position: relative; height: ${rowH}px">
      <div style="position: absolute; left: 0; top: 0; width: ${CH}px; height: ${rowH}px; border-radius: 16px; background: ${G.panel}; display: flex; align-items: center; gap: 14px; padding: 0 12px; box-sizing: border-box">${plate(logo, 104, 72)}<div style="display: flex; flex-direction: column; gap: 2px; min-width: 0"><span style="font-weight: 700; font-size: 21px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis">${name}</span><span style="${cond}; font-size: 17px; color: ${G.t3}">${ch}</span></div></div>
      ${cells.map(cell).join('')}</div>`).join('');
  const tk = ticks.map(([t, label]) => `<span style="position: absolute; left: ${X0 + t * PPM}px">${label}</span>`).join('');
  const total = rows.length * (rowH + 8);
  return `<div style="position: absolute; left: ${Lx}px; top: ${top}px; width: ${W}px; height: 40px; ${cond}; font-size: 25px; color: ${G.t2}">
      <span style="position: absolute; left: 0; top: -4px; height: 36px; padding: 0 16px; border-radius: 18px; background: ${G.cell}; display: inline-flex; align-items: center; gap: 8px; font-size: 22px; color: #FFFFFF">${svg('back', G.t2, 18, 4)}${chip}</span>${tk}</div>
    <div style="position: absolute; left: ${Lx}px; top: ${top + 46}px; width: ${W}px; display: flex; flex-direction: column; gap: 8px">${rowsHtml}</div>
    ${now !== null ? `<div style="position: absolute; left: ${Lx + X0 + now * PPM - 2}px; top: ${top + 38}px; width: 4px; height: ${total + 4}px; background: ${G.gold}; border-radius: 2px"></div><div style="position: absolute; left: ${Lx + X0 + now * PPM - 30}px; top: ${top}px; height: 32px; padding: 0 12px; border-radius: 16px; background: ${G.gold}; color: ${G.ground}; ${cond}; font-size: 22px; display: flex; align-items: center">3:20</div>` : ''}`;
}
function hero({ thumb, logo, logoArt, eyebrow, title, time, pct, next, buttons, badge }) {
  const media = logoArt
    ? `<div style="position: absolute; left: 380px; top: 136px; width: 528px; height: 297px; border-radius: 22px; background: #FFFFFF; display: flex; align-items: center; justify-content: center"><img src="${b(logoArt)}" alt="" style="width: 400px; height: 284px; object-fit: contain"><div style="position: absolute; left: 16px; top: 16px">${badge || LIVE}</div></div>`
    : `<div style="position: absolute; left: 380px; top: 136px; width: 528px; height: 297px; border-radius: 22px; overflow: hidden; background: #000000"><img src="${b(thumb)}" alt="" style="width: 100%; height: 100%; object-fit: cover"><div style="position: absolute; left: 16px; top: 16px">${badge || LIVE}</div></div>`;
  return media + `<div style="position: absolute; left: 948px; top: 140px; right: 72px; display: flex; flex-direction: column; gap: 14px">
    <div style="display: flex; align-items: center; gap: 16px">${plate(logo, 98, 70)}<span style="${cond}; font-size: 30px; color: ${G.gold}">${eyebrow}</span></div>
    <div style="${cond}; font-size: 60px; line-height: 1">${title}</div>
    <div style="display: flex; align-items: center; gap: 18px; font-size: 25px; color: ${G.t2}"><span>${time}</span>${pct ? `<div style="width: 280px; height: 6px; border-radius: 3px; background: ${G.line}"><div style="width: ${pct}; height: 6px; border-radius: 3px; background: ${G.gold}"></div></div>` : ''}</div>
    ${next ? `<div style="font-size: 23px; color: ${G.t2}">${next}</div>` : ''}
    <div style="display: flex; gap: 20px; margin-top: 6px">${buttons}</div>
  </div>`;
}
const TICKS15 = [[0, '3:00 PM'], [30, '3:30'], [60, '4:00 PM'], [90, '4:30']];
const hour = (n) => [['15:00', '16:00', 'Live programming', { sub: '3:00 – 4:00 PM' }], ['16:00', '17:00', 'Live programming', { sub: '4:00 – 5:00 PM' }]];
const ENG = (focusFirst) => [
  [L.abn, '3ABN', 'CH 1', [['15:00', '16:00', '3ABN TODAY BIBLE Q&amp;A', { focus: focusFirst }], ['16:00', '16:30', 'KIDS CAMP KITCHEN FUN'], ['16:30', '16:45', 'TINY TOTS KITCHEN'], ['16:45', '17:00', 'TINY TOTS WORSHIP']]],
  [L.pro, '3ABN Proclaim', 'CH 2', [['15:00', '16:00', 'REVELATION OF JESUS CHRIST'], ['16:00', '16:30', 'WHITE HORSE MEDIA'], ['16:30', '17:00', 'WHITE HORSE MEDIA']]],
  [L.kids, '3ABN Kids Network', 'CH 5', [['15:00', '15:15', 'HERE I AM SEND ME'], ['15:15', '15:30', 'TINY TOTS WORSHIP'], ['15:30', '16:00', 'TINY TOTS FOR JESUS'], ['16:00', '16:15', 'BIBLE TREASURES'], ['16:15', '16:30', 'TINY TOTS WORSHIP'], ['16:30', '16:45', 'BIBLE GEMS'], ['16:45', '17:00', 'FIT CLUB']]],
  [L.hope, 'HopeChannel', 'CH 9', hour()],
  [L.iiw, 'It is Written TV', 'CH 24', hour()]
];
const ESP = [
  [L.lat, '3ABN Latino', 'CH 28', [['15:00', '15:30', 'MARAVILLOSA CREACIÓN'], ['15:30', '16:00', 'REMEDIOS CASEROS'], ['16:00', '16:30', 'ESTRELLITAS DE JESÚS'], ['16:30', '17:00', 'JESUS 4 ASIA NOW']]],
  [L.nt, 'Nuevo Tiempo', 'CH 31', hour()],
  [L.llbnlat, 'LLBN Latino', 'CH 32', hour()]
];
const RADIOS = [[L.r1, '3ABN Radio', 'English'], [L.r2, '3ABN Music Channel', 'Music'], [L.r3, '3ABN Australia Radio', 'English'], [L.r4, '3ABN Latino Radio', 'Español'], [L.r5, 'Novo Tempo Radio', 'Português']];

const g1 = {};
g1[1] = header() + spine(1, -1) + hero({ thumb: T.now3abn, logo: L.abn, eyebrow: 'ENGLISH · 3ABN · CH 1', title: '3ABN TODAY BIBLE Q&amp;A', time: '3:00 – 3:55 PM · 35 min left', pct: '36%', next: '<span style="color: #FFFFFF; font-weight: 600">Next 4:00 PM</span> · 3ABN KIDS CAMP KITCHEN FUN', buttons: btn('Watch live', true, 'play') + btn('Start over', false, 'restart') }) +
  grid({ win: [15, 0], now: 20, rows: ENG(true), ticks: TICKS15, chip: 'TODAY' });
g1[2] = header() + spine(1, 2) + hero({ thumb: T.latNow, logo: L.lat, eyebrow: 'ESPAÑOL · 3ABN LATINO · CH 28', title: 'MARAVILLOSA CREACIÓN', time: '3:00 – 3:28 PM · 8 min left', pct: '71%', next: '<span style="color: #FFFFFF; font-weight: 600">Next 3:30 PM</span> · REMEDIOS CASEROS', buttons: btn('Watch live', true, 'play') + btn('Start over', false, 'restart') }) +
  grid({ win: [15, 0], now: 20, rows: ESP, ticks: TICKS15, chip: 'TODAY' }) +
  `<div style="position: absolute; left: 380px; top: 840px; width: 1468px; height: 92px; border-radius: 16px; box-shadow: inset 0 0 0 2px ${G.line}; display: flex; align-items: center; padding: 0 26px; box-sizing: border-box; font-size: 22px; color: ${G.t2}"><span style="color: #FFFFFF; font-weight: 700; margin-right: 12px">+3 more Español channels</span>Better Vida Mejor · Sum TV Latino · Good News Mas TV</div>`;
g1[3] = header() + spine(7, -1) + hero({ logoArt: L.r1, logo: L.r1, eyebrow: 'RADIO · ENGLISH', title: '3ABN RADIO', time: 'Live radio · plays around the clock', next: 'Radio has no schedule: every station is one live stream.', buttons: btn('Listen', true, 'play') + btn('All 10 stations', false), badge: pill('<span style="width: 8px; height: 8px; border-radius: 4px; background: #FFFFFF"></span>ON AIR', G.red, '#FFFFFF') }) +
  grid({ win: [15, 0], now: 20, ticks: TICKS15, chip: 'TODAY', rows: RADIOS.map(([l, n, lang], i) => [l, n, lang.toUpperCase(), [['15:00', '17:00', i === 0 ? 'Live radio · on air now' : 'Live radio', { focus: i === 0, sub: 'Around the clock · ' + lang }]]]) });
g1[4] = header() + spine(1, -1) + hero({ thumb: T.wolf, logo: L.abn, eyebrow: 'CATCH-UP · TODAY · 3ABN', title: 'A WOLF IN SHEEP’S CLOTHING', time: '2:30 – 2:58 PM · 28 min · recorded', next: 'Recordings play for DVR subscribers.', buttons: btn('Play from start', true, 'play') + btn('Back to live', false), badge: pill('REPLAY · 2:30 PM', 'rgba(5,11,30,0.85)', '#FFFFFF') }) +
  grid({ win: [14, 0], span: 90, now: 80, chip: 'EARLIER TODAY', ticks: [[0, '2:00 PM'], [30, '2:30'], [60, '3:00 PM']], rows: [
    [L.abn, '3ABN', 'CH 1', [['14:00', '14:30', 'ACTION 4 LIFE', { thumb: T.action }], ['14:30', '15:00', 'A WOLF IN SHEEP’S CLOTHING', { thumb: T.wolf, focus: true }], ['15:00', '15:55', '3ABN TODAY BIBLE Q&amp;A', { thumb: T.now3abn }]]],
    [L.pro, '3ABN Proclaim', 'CH 2', [['14:00', '14:30', 'IN THE FOOTSTEPS OF PAUL', { thumb: T.proPaul }], ['14:30', '15:00', 'IT IS WRITTEN', { thumb: T.proIIW }], ['15:00', '15:57', 'REVELATION OF JESUS CHRIST', { thumb: T.proNow }]]],
    [L.kids, '3ABN Kids Network', 'CH 5', [['14:00', '14:30', 'STARTING WITH JESUS'], ['14:30', '14:45', 'GRANDMA’S HOUSE'], ['14:45', '15:00', 'BIBLE BUZZ'], ['15:00', '15:15', 'HERE I AM SEND ME'], ['15:15', '15:30', 'TINY TOTS WORSHIP']]],
    [L.hope, 'HopeChannel', 'CH 9', [['14:00', '15:00', '2 PM hour', { thumb: T.hope2 }], ['15:00', '16:00', '3 PM hour', { thumb: T.hope3 }]]],
    [L.iiw, 'It is Written TV', 'CH 24', [['14:00', '15:00', '2 PM hour', { thumb: T.iiw2 }], ['15:00', '16:00', '3 PM hour', { thumb: T.iiw3 }]]]
  ] });

// ---------------------------------------------------------- shared ----
// Programme detail (series): reached from a guide cell or a timeline card.
const detail = (crumb) => `<img src="${b(T.carter5)}" alt="" style="position: absolute; inset: 0; width: 1920px; height: 1080px; object-fit: cover; filter: blur(44px); opacity: 0.32; transform: scale(1.1)">
  <div style="position: absolute; inset: 0; background: linear-gradient(90deg, rgba(5,11,30,0.97), rgba(5,11,30,0.7))"></div>
  ${header(crumb)}
  <div style="position: absolute; left: 72px; top: 150px; width: 480px; height: 270px; border-radius: 22px; overflow: hidden; background: #000000"><img src="${b(T.carter5)}" alt="" style="width: 100%; height: 100%; object-fit: cover"><div style="position: absolute; left: 16px; top: 16px">${pill('REPLAY', 'rgba(5,11,30,0.85)', '#FFFFFF')}</div></div>
  <div style="position: absolute; left: 600px; top: 150px; right: 72px; display: flex; flex-direction: column; gap: 16px">
    <div style="display: flex; align-items: center; gap: 16px">${plate(L.abn, 98, 70)}<span style="${cond}; font-size: 30px; color: ${G.gold}">3ABN · CH 1</span></div>
    <div style="${cond}; font-size: 80px; line-height: 1">THE CARTER REPORT</div>
    <div style="font-size: 27px; color: ${G.t2}">Saturday, Oct 4 · 5:00 – 5:29 PM · 29 min · recorded</div>
    <div style="display: flex; gap: 20px; margin-top: 12px">${btn('Play from start', true, 'play', true)}${btn('Show in the guide', false)}</div>
    <div style="display: flex; align-items: center; gap: 12px; font-size: 21px; color: ${G.t2}">${svg('lock', G.gold, 24, 3.4)}Recordings play for DVR subscribers</div>
  </div>
  <div style="position: absolute; left: 72px; top: 520px; display: flex; align-items: baseline; gap: 16px"><span style="${cond}; font-size: 36px">MORE OF THE CARTER REPORT</span><span style="font-weight: 600; font-size: 24px; color: ${G.t2}">30 recordings in the last 21 days</span></div>
  <div style="position: absolute; left: 72px; top: 586px; display: flex; gap: 24px">${[[T.carter5, 'Sat, Oct 4', '5:00 PM · this one'], [T.carter530, 'Sat, Oct 4', '5:30 PM'], [T.carterOct1, 'Wed, Oct 1', '6:00 PM'], ['9daaddb9d81d4a824a686bcb491bda70', 'Wed, Oct 1', '4:30 AM'], ['bf02a70ba3514f723332f615adc1e38c', 'Wed, Oct 1', '4:00 AM']].map(([t, d, h], i) => `<div style="width: 330px; display: flex; flex-direction: column; gap: 10px"><div style="height: 186px; border-radius: 18px; overflow: hidden; background: #000000; ${i === 0 ? `box-shadow: inset 0 0 0 3px ${G.line}` : ''}"><img src="${b(t)}" alt="" style="width: 100%; height: 100%; object-fit: cover; opacity: ${i === 0 ? 0.6 : 0.9}"></div><div style="${cond}; font-size: 24px">${d}</div><div style="font-size: 20px; color: ${G.t2}">${h}</div></div>`).join('')}</div>`;
// Account: reached from the round button top-right.
const account = () => `${header('Account')}
  <div style="position: absolute; left: 72px; top: 160px; width: 820px; height: 840px; border-radius: 28px; background: ${G.panel}; box-shadow: 0 0 0 1px ${G.line}; padding: 52px; box-sizing: border-box; display: flex; flex-direction: column; gap: 22px">
    <div style="${cond}; font-size: 60px; line-height: 1">LOG IN FOR CATCH-UP</div>
    <div style="font-size: 25px; line-height: 1.5; color: ${G.t2}">Use the email and password of your mysdatv.com subscription.</div>
    <div style="display: flex; flex-direction: column; gap: 10px; margin-top: 10px"><span style="${cond}; font-size: 22px; letter-spacing: 1px; color: ${G.t2}">EMAIL</span><div style="height: 78px; border-radius: 39px; background: ${G.gold}; color: ${G.ground}; display: flex; align-items: center; padding: 0 30px; font-weight: 600; font-size: 27px; box-shadow: 0 0 0 5px ${G.panel}, 0 0 0 9px ${G.gold}">[YOUR EMAIL] · OK to type</div></div>
    <div style="display: flex; flex-direction: column; gap: 10px"><span style="${cond}; font-size: 22px; letter-spacing: 1px; color: ${G.t2}">PASSWORD</span><div style="height: 78px; border-radius: 39px; background: ${G.cell}; display: flex; align-items: center; padding: 0 30px; font-size: 27px; color: ${G.t2}">••••••••</div></div>
    <div style="height: 78px; border-radius: 39px; background: ${G.cell}; display: flex; align-items: center; justify-content: center; font-weight: 700; font-size: 27px; margin-top: 8px">Log in</div>
    <div style="font-size: 22px; color: ${G.t3}; margin-top: auto">Live channels, languages and radio stay free without an account.</div>
  </div>
  <div style="position: absolute; left: 932px; top: 160px; right: 72px; display: flex; flex-direction: column; gap: 24px">
    <div style="border-radius: 28px; background: ${G.panel}; box-shadow: 0 0 0 1px ${G.line}; padding: 40px 44px; display: flex; flex-direction: column; gap: 18px">
      <div style="${cond}; font-size: 40px">WHAT CATCH-UP GIVES YOU</div>
      ${['Go back in the guide up to 21 days and play anything', 'Start a live programme over from the top', 'Every recording of a series in one row'].map((p) => `<div style="display: flex; gap: 16px; align-items: center; font-size: 26px; font-weight: 600"><div style="width: 44px; height: 44px; border-radius: 22px; background: rgba(250,211,90,0.14); display: flex; align-items: center; justify-content: center; flex-shrink: 0">${svg('check', G.gold, 24, 4)}</div>${p}</div>`).join('')}
    </div>
    <div style="border-radius: 28px; background: ${G.panel}; box-shadow: 0 0 0 1px ${G.line}; padding: 36px 44px; display: flex; gap: 36px; align-items: center">
      <div style="width: 270px; height: 270px; border-radius: 20px; background: #FFFFFF; display: flex; align-items: center; justify-content: center; flex-shrink: 0"><img src="${b('ade3e22c8d4e928c90c54e00fb911009')}" alt="Donation QR code" style="width: 246px; height: 246px; object-fit: contain"></div>
      <div style="display: flex; flex-direction: column; gap: 12px"><div style="${cond}; font-size: 38px; color: ${G.gold}">OR GIVE INSTEAD</div><div style="font-size: 24px; line-height: 1.5; color: #DDE3EE">A tax-deductible donation to mySDAtv unlocks catch-up for a whole year. Scan with your phone. Temporary promotion.</div></div>
    </div>
  </div>`;
g1[5] = detail('Guide');
g1[8] = account();

// G1 player states: the mini guide is a slice of the same guide; OK is info.
g1[6] = VIDEO(T.proNow) + `<div style="position: absolute; left: 0; bottom: 0; width: 1920px; height: 600px; background: linear-gradient(0deg, rgba(5,11,30,0.97) 0%, rgba(5,11,30,0.9) 62%, rgba(5,11,30,0) 100%)"></div>
  <div style="position: absolute; right: 72px; top: 48px; ${cond}; font-size: 36px">3:20 PM</div>
  <div style="position: absolute; left: 72px; top: 520px; display: flex; align-items: center; gap: 14px">${pill('ENGLISH · 24', G.cell, '#FFFFFF')}<span style="font-weight: 600; font-size: 22px; color: ${G.t2}">Up / Down to browse · OK to switch · Left for earlier</span></div>` +
  grid({ win: [15, 0], now: 20, chip: 'NOW', ticks: TICKS15, Lx: 72, top: 600, rows: [ENG(false)[0], [L.pro, '3ABN Proclaim', 'CH 2 · WATCHING', [['15:00', '16:00', 'REVELATION OF JESUS CHRIST', { focus: true }], ['16:00', '16:30', 'WHITE HORSE MEDIA'], ['16:30', '17:00', 'WHITE HORSE MEDIA']]], ENG(false)[2]] });
const infoBar = (extra) => `<div style="position: absolute; left: 72px; right: 72px; bottom: 56px; border-radius: 32px; background: rgba(10,22,48,0.95); box-shadow: 0 0 0 1px ${G.line}, 0 30px 80px rgba(0,0,0,0.6); padding: 30px 36px; box-sizing: border-box; display: flex; flex-direction: column; gap: 22px">
    <div style="display: flex; align-items: center; gap: 30px">
      ${plate(L.kids, 180, 128, 16)}
      <div style="display: flex; flex-direction: column; gap: 10px; flex-grow: 1; min-width: 0">
        <div style="display: flex; align-items: center; gap: 14px">${LIVE}<span style="${cond}; font-size: 26px; color: ${G.gold}">3ABN KIDS NETWORK · CH 5</span></div>
        <div style="${cond}; font-size: 56px; line-height: 1">TINY TOTS WORSHIP</div>
        <div style="display: flex; align-items: center; gap: 16px; font-size: 22px; color: ${G.t2}"><span>3:15</span><div style="width: 520px; height: 6px; border-radius: 3px; background: ${G.line}"><div style="width: 36%; height: 6px; border-radius: 3px; background: ${G.gold}"></div></div><span>3:29 PM</span><span style="margin-left: 20px"><span style="color: #FFFFFF; font-weight: 600">Next 3:30</span> TINY TOTS FOR JESUS</span></div>
      </div>
      <div style="display: flex; flex-direction: column; gap: 14px; flex-shrink: 0">${btn('Start over', true, 'restart', true)}${btn('Open guide', false)}</div>
    </div>${extra || ''}
  </div>`;
g1[7] = VIDEO(T.kidsNow) + `<div style="position: absolute; right: 72px; top: 48px; ${cond}; font-size: 36px">3:20 PM</div>` + infoBar();

// ---------------------------------------------------------- G2 parts ----
function list({ cat, rows, focusIdx, listFocus, dim }) {
  const r = rows.map(([logo, name, now, pct, rad], i) => {
    const f = i === focusIdx, lit = f && listFocus;
    return `<div style="height: 108px; border-radius: 22px; background: ${f ? (lit ? G.gold : G.live) : 'transparent'}; display: flex; align-items: center; gap: 18px; padding: 0 14px; ${lit ? 'box-shadow: 0 12px 34px rgba(250,211,90,0.3)' : ''}">
      ${plate(logo, 116, 82)}
      <div style="display: flex; flex-direction: column; gap: 6px; min-width: 0; flex-grow: 1">
        <span style="font-weight: 700; font-size: 25px; color: ${lit ? G.ground : '#FFFFFF'}">${name}</span>
        <span style="font-weight: 500; font-size: 20px; color: ${lit ? G.ground : G.t2}; opacity: ${lit ? 0.8 : 1}; white-space: nowrap; overflow: hidden; text-overflow: ellipsis">${now}</span>
        ${pct ? `<div style="height: 4px; border-radius: 2px; background: ${lit ? 'rgba(5,11,30,0.2)' : G.line}"><div style="width: ${pct}; height: 4px; border-radius: 2px; background: ${lit ? G.ground : G.red}"></div></div>` : ''}
      </div></div>`;
  }).join('');
  return `<div style="position: absolute; left: 56px; top: 140px; width: 560px; opacity: ${dim ? 0.35 : 1}">
      <div style="height: 60px; border-radius: 30px; background: ${G.cell}; display: inline-flex; align-items: center; gap: 12px; padding: 0 22px; margin: 0 0 14px 14px; font-weight: 700; font-size: 24px">${cat}${svg('down', G.t2, 24, 4)}</div>
      <div style="display: flex; flex-direction: column; gap: 6px">${r}</div>
    </div>`;
}
const LIST_ENG = [[L.abn, '3ABN', '3ABN TODAY BIBLE Q&amp;A', '36%'], [L.pro, '3ABN Proclaim', 'REVELATION OF JESUS CHRIST', '35%'], [L.kids, '3ABN Kids Network', 'TINY TOTS WORSHIP', '36%'], [L.hope, 'HopeChannel', 'Live now · 3 PM hour', '33%'], [L.iiw, 'It is Written TV', 'Live now · 3 PM hour', '33%'], [L.af, 'Amazing Facts', 'Live now · 3 PM hour', '33%'], [L.gn, 'Good News TV', 'Live now · 3 PM hour', '33%']];
const LIST_ESP = [[L.lat, '3ABN Latino', 'MARAVILLOSA CREACIÓN', '71%'], [L.nt, 'Nuevo Tiempo', 'Live now · 3 PM hour', '33%'], [L.llbnlat, 'LLBN Latino', 'Live now · 3 PM hour', '33%']];
// The right side: a preview, the programme, a day of cards.
function day({ media, mediaBadge, eyebrow, title, when, buttons, dayTitle, dayChips, cards, dim }) {
  const cs = cards.map(([t, title2, thumb, st, f]) => `<div style="width: 268px; flex-shrink: 0; display: flex; flex-direction: column; gap: 10px; transform: scale(${f ? 1.04 : 1}); transform-origin: left bottom">
      <div style="position: relative; height: 151px; border-radius: 18px; overflow: hidden; background: ${thumb ? '#000000' : G.cell}; box-shadow: ${f ? `0 0 0 4px ${G.gold}, 0 14px 34px rgba(0,0,0,0.6)` : 'none'}; display: flex; align-items: center; justify-content: center">
        ${thumb ? `<img src="${b(thumb)}" alt="" style="width: 100%; height: 100%; object-fit: cover; opacity: ${st === 'past' ? 0.88 : 1}">` : `<span style="${cond}; font-size: 30px; color: ${G.t3}">${t}</span>`}
        <div style="position: absolute; left: 10px; top: 10px">${st === 'live' ? LIVE : (st === 'past' ? pill('REPLAY', 'rgba(5,11,30,0.85)', '#FFFFFF') : pill('LATER', 'rgba(5,11,30,0.6)', G.t2))}</div>
      </div>
      <div style="${cond}; font-size: 22px; color: ${f ? G.gold : G.t2}">${t}</div>
      <div style="font-weight: 700; font-size: 21px; line-height: 1.2; color: ${f ? '#FFFFFF' : '#DDE3EE'}; overflow: hidden; display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical">${title2}</div>
    </div>`).join('');
  return `<div style="position: absolute; left: 672px; top: 140px; right: 0; bottom: 0; opacity: ${dim ? 0.3 : 1}">
    <div style="position: absolute; left: 0; top: 0; width: 760px; height: 428px; border-radius: 26px; overflow: hidden; background: ${media.logo ? '#FFFFFF' : '#000000'}; box-shadow: 0 30px 80px rgba(0,0,0,0.6); display: flex; align-items: center; justify-content: center">${media.logo ? `<img src="${b(media.logo)}" alt="" style="width: 560px; height: 398px; object-fit: contain">` : `<img src="${b(media.thumb)}" alt="" style="width: 100%; height: 100%; object-fit: cover">`}<div style="position: absolute; left: 20px; top: 20px">${mediaBadge}</div></div>
    <div style="position: absolute; left: 796px; top: 6px; right: 72px; display: flex; flex-direction: column; gap: 14px">
      <span style="${cond}; font-size: 26px; color: ${G.gold}">${eyebrow}</span>
      <div style="${cond}; font-size: 48px; line-height: 1.02">${title}</div>
      <div style="font-size: 23px; color: ${G.t2}">${when}</div>
      <div style="display: flex; flex-direction: column; gap: 14px; margin-top: 12px">${buttons}</div>
    </div>
    <div style="position: absolute; left: 0; top: 470px; right: 72px; display: flex; align-items: center; gap: 16px"><span style="${cond}; font-size: 30px">${dayTitle}</span>${dayChips}</div>
    <div style="position: absolute; left: 0; top: 530px; width: 1176px; display: flex; gap: 24px; overflow: hidden">${cs}</div>
  </div>`;
}
const chip = (label, icon, right) => `<span style="height: 40px; padding: 0 16px; border-radius: 20px; background: ${G.cell}; display: inline-flex; align-items: center; gap: 8px; font-weight: 700; font-size: 20px; ${right ? 'margin-left: auto' : ''}">${icon === 'back' ? svg('back', G.t2, 18, 4) : ''}${label}${icon === 'fwd' ? svg('fwd', G.t2, 18, 4) : ''}</span>`;
const TODAY3 = (focusIdx) => [['2:00 PM', 'ACTION 4 LIFE', T.action, 'past'], ['2:30 PM', 'A WOLF IN SHEEP’S CLOTHING', T.wolf, 'past'], ['3:00 PM', '3ABN TODAY BIBLE Q&amp;A', T.now3abn, 'live'], ['4:00 PM', 'KIDS CAMP KITCHEN FUN', '', 'later'], ['4:30 PM', 'TINY TOTS KITCHEN', '', 'later']].map((c, i) => c.concat([i === focusIdx]));
const g2 = {};
g2[1] = header() + list({ cat: 'English <span style="color: ' + G.t2 + '; font-weight: 600">· 24 channels</span>', rows: LIST_ENG, focusIdx: 0, listFocus: true }) +
  day({ media: { thumb: T.now3abn }, mediaBadge: LIVE, eyebrow: '3ABN · CH 1', title: '3ABN TODAY BIBLE Q&amp;A', when: '3:00 – 3:55 PM · 35 min left', buttons: btn('Watch live', true, 'play') + btn('Start over', false, 'restart'), dayTitle: 'TODAY ON 3ABN', dayChips: chip('Yesterday', 'back') + `<span style="margin-left: auto; font-size: 20px; color: ${G.t2}">37 programmes · 21 days back</span>`, cards: TODAY3(-1) });
// G2-2 · Languages: the category switcher open; the list behind already shows Español.
const CATS = [['All channels', '40'], ['English', '24'], ['Español', '6'], ['Português', '3'], ['More languages', '7'], ['3ABN family', '11'], ['LLBN family', '9'], ['Radio', '10']];
g2[2] = header() + list({ cat: 'Español <span style="color: ' + G.t2 + '; font-weight: 600">· 6 channels</span>', rows: LIST_ESP, focusIdx: 0, listFocus: false, dim: true }) +
  day({ media: { thumb: T.latNow }, mediaBadge: LIVE, eyebrow: '3ABN LATINO · CH 28', title: 'MARAVILLOSA CREACIÓN', when: '3:00 – 3:28 PM · 8 min left', buttons: btn('Watch live', true, 'play') + btn('Start over', false, 'restart'), dayTitle: 'TODAY ON 3ABN LATINO', dayChips: chip('Yesterday', 'back'), cards: [['2:00 PM', 'ANCLAS DE LA VERDAD', 'c9654d9fc723198009bbafa184d5a7d5', 'past'], ['3:00 PM', 'MARAVILLOSA CREACIÓN', T.latNow, 'live'], ['3:30 PM', 'REMEDIOS CASEROS', '', 'later'], ['4:00 PM', 'ESTRELLITAS DE JESÚS', '', 'later'], ['4:30 PM', 'JESUS 4 ASIA NOW', '', 'later']], dim: true }) +
  `<div style="position: absolute; left: 70px; top: 214px; width: 440px; padding: 12px; box-sizing: border-box; border-radius: 30px; background: ${G.panel}; box-shadow: 0 0 0 1px ${G.line}, 0 30px 80px rgba(0,0,0,0.7); display: flex; flex-direction: column; gap: 4px">${CATS.map(([l, n], i) => `<div style="height: 64px; border-radius: 32px; display: flex; align-items: center; padding: 0 22px; background: ${i === 2 ? G.gold : 'transparent'}; color: ${i === 2 ? G.ground : (i === 1 ? G.gold : '#FFFFFF')}; font-weight: ${i === 2 || i === 1 ? 700 : 600}; font-size: 25px">${l}<span style="margin-left: auto; font-size: 21px; opacity: 0.6">${n}</span></div>`).join('')}</div>`;
g2[3] = header() + list({ cat: 'Radio <span style="color: ' + G.t2 + '; font-weight: 600">· 10 stations</span>', rows: RADIOS.map(([l, n, lang]) => [l, n, 'Live radio · ' + lang, null]), focusIdx: 0, listFocus: true }) +
  day({ media: { logo: L.r1 }, mediaBadge: pill('<span style="width: 8px; height: 8px; border-radius: 4px; background: #FFFFFF"></span>ON AIR', G.red, '#FFFFFF'), eyebrow: 'RADIO · ENGLISH', title: '3ABN RADIO', when: 'Live radio · plays around the clock', buttons: btn('Listen', true, 'play') + btn('Stations in Español', false), dayTitle: 'MORE STATIONS', dayChips: `<span style="margin-left: auto; font-size: 20px; color: ${G.t2}">Radio has no schedule: each station is one live stream</span>`, cards: [] }) +
  `<div style="position: absolute; left: 672px; top: 670px; display: flex; gap: 24px">${RADIOS.slice(1).map(([l, n]) => `<div style="width: 268px; display: flex; flex-direction: column; gap: 10px"><div style="height: 151px; border-radius: 18px; background: #FFFFFF; display: flex; align-items: center; justify-content: center"><img src="${b(l)}" alt="" style="width: 200px; height: 142px; object-fit: contain"></div><div style="font-weight: 700; font-size: 21px">${n}</div></div>`).join('')}</div>`;
// G2-4 · Catch-up: yesterday on 3ABN, a replay in focus.
g2[4] = header() + list({ cat: 'English <span style="color: ' + G.t2 + '; font-weight: 600">· 24 channels</span>', rows: LIST_ENG, focusIdx: 0, listFocus: false }) +
  day({ media: { thumb: T.carter5 }, mediaBadge: pill('REPLAY · SAT 5:00 PM', 'rgba(5,11,30,0.85)', '#FFFFFF'), eyebrow: '3ABN · CH 1', title: 'THE CARTER REPORT', when: 'Saturday, Oct 4 · 5:00 – 5:29 PM · 29 min', buttons: btn('Play from start', true, 'play') + btn('More episodes', false), dayTitle: 'YESTERDAY ON 3ABN · SAT OCT 4', dayChips: chip('Fri', 'back') + chip('Today', 'fwd'), cards: [['3:00 PM', '3ABN TODAY', T.y1500, 'past'], ['4:00 PM', '3ABN TODAY', T.y1600, 'past'], ['5:00 PM', 'THE CARTER REPORT', T.carter5, 'past', true], ['5:30 PM', 'THE CARTER REPORT', T.carter530, 'past'], ['6:00 PM', 'SALVATION IN SYMBOLS AND SIGNS', T.y1800, 'past']] });
g2[5] = detail('Today on 3ABN');
g2[8] = account();
// G2-6 · Player: the channel list rises over the video on Up / Down.
g2[6] = VIDEO(T.proNow) + `<div style="position: absolute; left: 0; top: 0; width: 760px; height: 1080px; background: linear-gradient(90deg, rgba(5,11,30,0.97) 0%, rgba(5,11,30,0.92) 70%, rgba(5,11,30,0) 100%)"></div>
  <div style="position: absolute; right: 72px; top: 48px; ${cond}; font-size: 36px">3:20 PM</div>` +
  list({ cat: 'English <span style="color: ' + G.t2 + '; font-weight: 600">· 24 channels</span>', rows: LIST_ENG, focusIdx: 1, listFocus: true }) +
  `<div style="position: absolute; left: 56px; bottom: 30px; font-weight: 600; font-size: 21px; color: ${G.t2}">OK to switch · Right for today on this channel</div>`;
// G2-7 · Player info: the bar carries the channel's day as a strip.
g2[7] = VIDEO(T.kidsNow) + `<div style="position: absolute; right: 72px; top: 48px; ${cond}; font-size: 36px">3:20 PM</div>` +
  infoBar(`<div style="display: flex; gap: 14px; align-items: center"><span style="${cond}; font-size: 22px; color: ${G.t2}; margin-right: 6px">TODAY</span>${[['2:45', 'BIBLE BUZZ', 'past'], ['3:00', 'HERE I AM SEND ME', 'past'], ['3:15', 'TINY TOTS WORSHIP', 'live'], ['3:30', 'TINY TOTS FOR JESUS', 'later'], ['4:00', 'BIBLE TREASURES', 'later'], ['4:15', 'TINY TOTS WORSHIP', 'later']].map(([t, n, st]) => `<div style="height: 52px; border-radius: 26px; padding: 0 20px; display: flex; align-items: center; gap: 10px; background: ${st === 'live' ? G.live : G.cell}; font-size: 19px; font-weight: 600; color: ${st === 'later' ? G.t2 : '#FFFFFF'}">${st === 'live' ? `<span style="width: 8px; height: 8px; border-radius: 4px; background: ${G.red}"></span>` : ''}<span style="${cond}; font-size: 20px; color: ${st === 'past' ? G.gold : 'inherit'}">${t}</span>${n}</div>`).join('')}</div>`);

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
const NAMES = { 1: 'Guide', 2: 'Languages', 3: 'Radio', 4: 'Catchup', 5: 'Programme', 6: 'PlayerGuide', 7: 'PlayerInfo', 8: 'Account' };
const out = [];
for (const [set, screens] of [['G1', g1], ['G2', g2]]) {
  for (let i = 1; i <= 8; i++) {
    const f = `B${set}-${i}-${NAMES[i]}`;
    fs.writeFileSync(path.join(OUT, f + '.dc.html'), page(`${set} ${i} ${NAMES[i]}`, screens[i]));
    out.push(f);
  }
}
console.log(out.join(' '));
