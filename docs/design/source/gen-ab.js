// A (Lineup) background + navigation options, B (Guide) shape-language options.
// Owner, 2026-10-06: A "not bound to the gradient… navigation still feels plain";
// B "buttons feel too cornery".
const fs = require('fs');
const path = require('path');
const OUT = path.join(__dirname, 'canvas', 'project');
const b = (id) => '/_blob/' + id;
const ICON = {
  tv: 'M8.5 12h23a3.5 3.5 0 0 1 3.5 3.5v13a3.5 3.5 0 0 1-3.5 3.5h-23A3.5 3.5 0 0 1 5 28.5v-13A3.5 3.5 0 0 1 8.5 12zM14 36h12M15 5l5 6 5-6',
  globe: 'M35 20a15 15 0 1 1-30 0 15 15 0 0 1 30 0zM27 20c0 8.3-3.1 15-7 15s-7-6.7-7-15 3.1-15 7-15 7 6.7 7 15zM5 20h30M8 12.5h24M8 27.5h24',
  dvr: 'M8 13a14 14 0 1 1-2 9M4.5 8l2.1 7.3 7-2.3M20 12v8l6 3.5',
  radio: 'M7.5 14h25a3.5 3.5 0 0 1 3.5 3.5v14a3.5 3.5 0 0 1-3.5 3.5h-25A3.5 3.5 0 0 1 4 31.5v-14A3.5 3.5 0 0 1 7.5 14zM20 24.5a5.5 5.5 0 1 1-11 0 5.5 5.5 0 0 1 11 0zM25 21h6M25 27.5h6M9 14l21-9',
  user: 'M26.5 12.5a6.5 6.5 0 1 1-13 0 6.5 6.5 0 0 1 13 0zM7 34c0-7.5 5.5-11.5 13-11.5S33 26.5 33 34'
};
const svg = (d, c, s = 40, w = 3) => `<svg width="${s}" height="${s}" viewBox="0 0 40 40" fill="none" stroke="${c}" stroke-width="${w}" stroke-linecap="round" stroke-linejoin="round"><path d="${d}"/></svg>`;
const page = (title, fonts, body) => `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>${title}</title>
<script src="./support.js"></script>
</head>
<body>
<x-dc>
<helmet>
<link href="https://fonts.googleapis.com/css2?${fonts}&amp;display=swap" rel="stylesheet">
<style>
body{margin:0}
</style>
</helmet>
${body}
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

// ---------------------------------------------------------------- A -----
const AF = 'family=Manrope:wght@700;800&amp;family=Inter:wght@500;600;700';
const TILES = [
  ['242bd1a56c08d0855ef8ca15fcbcd4ef', '3ABN', '3ABN TODAY BIBLE Q&amp;A', '36%'],
  ['e40d84f762578caed15688344a03391c', '3ABN Proclaim', 'REVELATION OF JESUS CHRIST', '35%'],
  ['3cd27ca3e7d58e9a1aa8273e9c19caa4', '3ABN Kids Network', 'TINY TOTS WORSHIP', '36%'],
  ['8a4ae2c264a612734dc50b5aabb7da57', 'HopeChannel', 'Live now · 3-4 PM', '33%'],
  ['e2f268b5a36bee5d8c269ca003c3de9e', 'It is Written TV', 'Live now · 3-4 PM', '33%'],
  ['6ec2f978278a61060737b8b22d12c18e', 'Amazing Facts', 'Live now · 3-4 PM', '33%'],
  ['163b3b93da32b56730990408244fbfaa', 'Good News TV', 'Live now · 3-4 PM', '33%'],
  ['53ee2f0dc851bf2f516b0ec5f1913e5a', 'Mission TV', 'Live now · 3-4 PM', '33%'],
  ['501848ecd4f1f5a9f0595e8a81d8ee24', 'Better Life TV', 'Live now · 3-4 PM', '33%'],
  ['9376ee23051be9567615604d253e34b5', 'LLBN His Light', 'Live now · 3-4 PM', '33%']
];
function aGrid(left, focusIdx, accent, plate, cap2) {
  const t = TILES.map(([l, title, now, pct], i) => {
    const f = i === focusIdx;
    return `<div style="display: flex; flex-direction: column; gap: 12px">
        <div style="height: 230px; border-radius: 16px; background: ${plate}; display: flex; align-items: center; justify-content: center; transform: scale(${f ? 1 : 0.92}); transform-origin: bottom left; opacity: ${f ? 1 : 0.86}; box-shadow: ${f ? `0 0 0 3px ${accent}55, 0 0 46px 6px ${accent}70` : 'none'}">
          <img src="${b(l)}" alt="" style="width: 290px; height: 206px; object-fit: contain">
        </div>
        <div style="font-weight: 600; font-size: 27px; color: ${f ? accent : '#FFFFFF'}; white-space: nowrap; overflow: hidden; text-overflow: ellipsis">${title}</div>
        <div style="display: flex; align-items: center; gap: 10px; font-weight: 500; font-size: 22px; color: ${cap2}; white-space: nowrap; overflow: hidden"><span style="width: 10px; height: 10px; border-radius: 5px; background: #F0262B; flex-shrink: 0"></span><span style="overflow: hidden; text-overflow: ellipsis">${now}</span></div>
        <div style="height: 4px; border-radius: 2px; background: rgba(255,255,255,0.14)"><div style="height: 4px; border-radius: 2px; background: #F0262B; width: ${pct}"></div></div>
      </div>`;
  }).join('\n      ');
  return `<div style="position: absolute; left: ${left}px; top: 280px; width: 1700px; display: grid; grid-template-columns: repeat(5, minmax(0, 1fr)); gap: 46px 20px">
      ${t}
    </div>`;
}
const head = (left, clockBg, sub) => `
  <h1 style="position: absolute; left: ${left}px; top: 150px; margin: 0; font-family: Manrope, sans-serif; font-weight: 800; font-size: 54px; line-height: 66px">Television</h1>
  <div style="position: absolute; left: ${left + 330}px; top: 168px; font-size: 24px; line-height: 36px; color: ${sub}">24 channels · live now</div>
  <img src="${b('ec7c10bad0117787e03b001592d65bba')}" alt="mySDAtv" style="position: absolute; left: ${left}px; top: 30px; width: 207px; height: 108px">
  <div style="position: absolute; right: 60px; top: 48px; width: 420px; height: 60px; border-radius: 30px; background: ${clockBg}; display: flex; align-items: center; justify-content: space-between; padding: 0 28px; box-sizing: border-box"><span style="font-family: Manrope, sans-serif; font-weight: 700; font-size: 30px">3:20 PM</span><span style="font-size: 21px; color: #B4BCCB">Sunday, Oct 5</span></div>`;

// A-α · Ink and ember: a flat ink ground (no gradient), a solid rail panel with
// sections, glyphs in rounded tiles that fill red when focused, a "now on" card.
function aAlpha() {
  const row = (k, label, state) => {
    const focus = state === 'focus', sel = state === 'sel';
    const tile = focus ? '#F0262B' : (sel ? 'rgba(250,211,90,0.16)' : '#1A2030');
    const ic = focus ? '#FFFFFF' : (sel ? '#FAD35A' : '#C4CAD6');
    return `<div style="height: 76px; border-radius: 20px; display: flex; align-items: center; gap: 18px; padding: 0 10px; background: ${focus ? 'rgba(240,38,43,0.14)' : 'transparent'}">
        <div style="width: 56px; height: 56px; border-radius: 16px; background: ${tile}; display: flex; align-items: center; justify-content: center; ${focus ? 'box-shadow: 0 8px 24px rgba(240,38,43,0.45)' : ''}">${svg(ICON[k], ic, 34)}</div>
        <span style="font-weight: ${focus || sel ? 700 : 600}; font-size: 28px; color: ${sel ? '#FAD35A' : '#FFFFFF'}">${label}</span></div>`;
  };
  const sec = (t) => `<div style="font-weight: 700; font-size: 17px; letter-spacing: 2.5px; color: #6F7891; padding: 18px 12px 6px">${t}</div>`;
  return `<div style="width: 1920px; height: 1080px; position: relative; overflow: hidden; background: #0A0D16; color: #FFFFFF; font-family: Inter, sans-serif">
  <div style="position: absolute; left: 0; bottom: 0; width: 1920px; height: 300px; background: linear-gradient(0deg, rgba(0,0,0,0.5), rgba(0,0,0,0))"></div>
  ${head(480, '#141927', '#8C95AA')}
  ${aGrid(480, -1, '#F0262B', '#FFFFFF', '#8C95AA')}
  <div style="position: absolute; left: 0; top: 0; width: 440px; height: 1080px; background: #11151F; box-shadow: 1px 0 0 #1E2433, 30px 0 80px rgba(0,0,0,0.5)">
    <div style="position: absolute; left: 30px; top: 36px; display: flex; align-items: center; gap: 18px"><img src="${b('626310db1af1e2cf0f2088632ef8c777')}" alt="" style="width: 60px; height: 60px"><span style="font-family: Manrope, sans-serif; font-weight: 800; font-size: 36px"><span style="color: #F0262B">my</span><span style="color: #FAD35A">SDA</span><span style="color: #0981FB">tv</span></span></div>
    <div style="position: absolute; left: 22px; top: 140px; width: 396px; display: flex; flex-direction: column; gap: 6px">
      ${sec('WATCH')}${row('tv', 'Television', 'focus')}${row('globe', 'TV Languages')}${row('dvr', 'DVR')}
      ${sec('LISTEN')}${row('radio', 'Radios')}
      ${sec('ACCOUNT')}${row('user', 'Login')}
    </div>
    <div style="position: absolute; left: 22px; bottom: 30px; width: 396px; border-radius: 20px; background: #1A2030; padding: 16px; box-sizing: border-box; display: flex; gap: 14px; align-items: center">
      <div style="width: 84px; height: 60px; border-radius: 10px; background: #FFFFFF; display: flex; align-items: center; justify-content: center; flex-shrink: 0"><img src="${b('242bd1a56c08d0855ef8ca15fcbcd4ef')}" alt="" style="width: 76px; height: 54px; object-fit: contain"></div>
      <div style="display: flex; flex-direction: column; gap: 4px; min-width: 0"><span style="font-weight: 700; font-size: 15px; letter-spacing: 1.5px; color: #F0262B">● LAST WATCHED</span><span style="font-weight: 600; font-size: 21px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis">3ABN TODAY BIBLE Q&amp;A</span></div>
    </div>
  </div>
</div>`;
}

// A-β · Brand ribbon: a solid navy ground with a faint globe-mesh watermark, a
// tri-colour ribbon (red / gold / blue) down the rail's edge, a pill rail.
function aBeta() {
  const row = (k, label, state) => {
    const focus = state === 'focus', sel = state === 'sel';
    return `<div style="position: relative; height: 72px; border-radius: 36px; display: flex; align-items: center; gap: 18px; padding: 0 22px; background: ${focus ? '#FFFFFF' : 'transparent'}; color: ${focus ? '#0B1222' : (sel ? '#FAD35A' : '#E4E8F0')}; font-weight: ${focus || sel ? 800 : 600}; font-size: 29px">${svg(ICON[k], focus ? '#F0262B' : (sel ? '#FAD35A' : '#C4CAD6'), 36)}${label}${sel ? '<span style="margin-left: auto; width: 10px; height: 10px; border-radius: 5px; background: #FAD35A"></span>' : ''}</div>`;
  };
  const mesh = Array.from({ length: 7 }, (_, i) => `<ellipse cx="300" cy="300" rx="${40 + i * 40}" ry="290" fill="none" stroke="#16264A" stroke-width="2"/>`).join('') +
    Array.from({ length: 7 }, (_, i) => `<line x1="10" y1="${60 + i * 80}" x2="590" y2="${60 + i * 80}" stroke="#16264A" stroke-width="2"/>`).join('');
  return `<div style="width: 1920px; height: 1080px; position: relative; overflow: hidden; background: #0B1530; color: #FFFFFF; font-family: Inter, sans-serif">
  <svg style="position: absolute; right: -160px; top: -140px; opacity: 0.9" width="900" height="900" viewBox="0 0 600 600"><circle cx="300" cy="300" r="290" fill="none" stroke="#16264A" stroke-width="3"/>${mesh}</svg>
  ${head(480, '#13224A', '#9AA7C4')}
  ${aGrid(480, -1, '#F0262B', '#FFFFFF', '#9AA7C4')}
  <div style="position: absolute; left: 0; top: 0; width: 440px; height: 1080px; background: #0E1A3B">
    <div style="position: absolute; right: 0; top: 0; width: 6px; height: 1080px; display: flex; flex-direction: column"><div style="flex: 1; background: #F0262B"></div><div style="flex: 1; background: #FAD35A"></div><div style="flex: 1; background: #0981FB"></div></div>
    <img src="${b('ec7c10bad0117787e03b001592d65bba')}" alt="mySDAtv" style="position: absolute; left: 40px; top: 32px; width: 207px; height: 108px">
    <div style="position: absolute; left: 24px; top: 190px; width: 386px; display: flex; flex-direction: column; gap: 8px">
      ${row('tv', 'Television', 'focus')}${row('globe', 'TV Languages')}${row('dvr', 'DVR')}${row('radio', 'Radios')}
      <div style="height: 1px; background: #1E2E58; margin: 18px 20px"></div>
      ${row('user', 'Login')}
    </div>
    <div style="position: absolute; left: 44px; bottom: 44px; font-weight: 600; font-size: 21px; color: #7D8BAE">40 channels · 10 radios</div>
  </div>
</div>`;
}

// A-γ · Dock tiles: icon-over-label tiles, so the closed rail still names every
// destination; a deep plum-black ground lit by the logo's red from below.
function aGamma() {
  const tile = (k, label, state) => {
    const focus = state === 'focus', sel = state === 'sel';
    return `<div style="width: 112px; height: 104px; border-radius: 24px; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 8px; background: ${focus ? '#F0262B' : (sel ? 'rgba(255,255,255,0.08)' : 'transparent')}; ${focus ? 'box-shadow: 0 12px 30px rgba(240,38,43,0.5)' : ''}">
        ${svg(ICON[k], focus ? '#FFFFFF' : (sel ? '#FAD35A' : '#B7BCCB'), 38)}
        <span style="font-weight: 700; font-size: 17px; color: ${focus ? '#FFFFFF' : (sel ? '#FAD35A' : '#B7BCCB')}">${label}</span>
        ${sel ? '<span style="position: absolute; margin-top: 96px; width: 28px; height: 4px; border-radius: 2px; background: #FAD35A"></span>' : ''}
      </div>`;
  };
  return `<div style="width: 1920px; height: 1080px; position: relative; overflow: hidden; background: #0D0A12; color: #FFFFFF; font-family: Inter, sans-serif">
  <div style="position: absolute; left: 400px; top: 700px; width: 1600px; height: 900px; border-radius: 50%; background: radial-gradient(closest-side, rgba(240,38,43,0.22), rgba(240,38,43,0))"></div>
  ${head(200, '#1A1520', '#A39AAE')}
  ${aGrid(200, 0, '#F0262B', '#FFFFFF', '#A39AAE')}
  <div style="position: absolute; left: 20px; top: 0; width: 136px; height: 1080px">
    <img src="${b('626310db1af1e2cf0f2088632ef8c777')}" alt="" style="position: absolute; left: 38px; top: 40px; width: 60px; height: 60px">
    <div style="position: absolute; left: 12px; top: 200px; display: flex; flex-direction: column; gap: 10px">
      ${tile('tv', 'TV', 'sel')}${tile('globe', 'Languages')}${tile('dvr', 'DVR')}${tile('radio', 'Radios')}
      <div style="height: 30px"></div>
      ${tile('user', 'Login')}
    </div>
  </div>
</div>`;
}

// ---------------------------------------------------------------- B -----
const BF = 'family=Barlow+Condensed:wght@600;700&amp;family=Barlow:wght@500;600;700';
// One guide screen, parameterised by the shape language.
function guide(S) {
  const X0 = 316, PPM = 12.3, NOW = 20;
  const m = (hm) => { const [h, mm] = hm.split(':').map(Number); return (h - 15) * 60 + mm; };
  const cell = (s, e, title, focus, generic) => {
    const a = m(s), bb = Math.min(m(e), 120), live = a <= NOW && bb > NOW;
    const time = generic ? (s.startsWith('15') ? '3:00' : '4:00') + ' · live programming' : '';
    return `<div style="position: absolute; top: 0; left: ${X0 + a * PPM}px; width: ${Math.max(0, (bb - a) * PPM - S.gap)}px; height: 84px; border-radius: ${S.cell}px; overflow: hidden; background: ${focus ? '#FAD35A' : (live ? '#16294F' : '#10203F')}; color: ${focus ? '#050B1E' : '#FFFFFF'}; box-sizing: border-box; padding: 10px ${S.cellPad}px; display: flex; flex-direction: column; justify-content: center; gap: 2px; ${focus ? 'box-shadow: 0 10px 30px rgba(250,211,90,0.35)' : ''}">
            <div style="font-weight: 700; font-size: 23px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis">${title}</div>${time ? `<div style="font-weight: 500; font-size: 19px; opacity: 0.8">${time}</div>` : ''}</div>`;
  };
  const row = (logo, name, cells) => `<div style="position: relative; height: 84px">
        <div style="position: absolute; left: 0; top: 0; width: ${300 - S.gap}px; height: 84px; border-radius: ${S.cell}px; background: #0B1733; display: flex; align-items: center; gap: 14px; padding: 0 ${S.cellPad - 4}px; box-sizing: border-box">
          <div style="width: 100px; height: 66px; border-radius: ${Math.min(S.cell, 14)}px; background: #FFFFFF; display: flex; align-items: center; justify-content: center; flex-shrink: 0"><img src="${b(logo)}" alt="" style="width: 92px; height: 60px; object-fit: contain"></div>
          <span style="font-weight: 600; font-size: 22px">${name}</span></div>
        ${cells.join('')}</div>`;
  const hr = (n) => [cell('15:00', '16:00', n, false, true), cell('16:00', '17:00', n, false, true)];
  const rows = [
    row('242bd1a56c08d0855ef8ca15fcbcd4ef', '3ABN', [cell('15:00', '16:00', '3ABN TODAY BIBLE Q&amp;A', true), cell('16:00', '16:30', 'KIDS CAMP KITCHEN FUN'), cell('16:30', '16:45', 'TINY TOTS KITCHEN'), cell('16:45', '17:00', 'TINY TOTS WORSHIP')]),
    row('e40d84f762578caed15688344a03391c', '3ABN Proclaim', [cell('15:00', '16:00', 'REVELATION OF JESUS CHRIST'), cell('16:00', '16:30', 'WHITE HORSE MEDIA'), cell('16:30', '17:00', 'WHITE HORSE MEDIA')]),
    row('3cd27ca3e7d58e9a1aa8273e9c19caa4', '3ABN Kids', [cell('15:00', '15:15', 'HERE I AM SEND ME'), cell('15:15', '15:30', 'TINY TOTS WORSHIP'), cell('15:30', '16:00', 'TINY TOTS FOR JESUS'), cell('16:00', '16:15', 'BIBLE TREASURES'), cell('16:15', '16:30', 'TINY TOTS WORSHIP'), cell('16:30', '16:45', 'BIBLE GEMS'), cell('16:45', '17:00', 'FIT CLUB')]),
    row('8a4ae2c264a612734dc50b5aabb7da57', 'HopeChannel', hr('HopeChannel')),
    row('e2f268b5a36bee5d8c269ca003c3de9e', 'It is Written TV', hr('It is Written TV'))
  ].join('\n      ');
  const tabs = ['GUIDE', 'LANGUAGES', 'RADIO', 'CATCH-UP', 'ACCOUNT'].map((t, i) => S.tabsAsPills
    ? `<div style="height: 56px; padding: 0 26px; border-radius: 28px; display: flex; align-items: center; font-family: 'Barlow Condensed', sans-serif; font-weight: 700; font-size: 30px; letter-spacing: 1px; background: ${i === 0 ? '#FAD35A' : 'transparent'}; color: ${i === 0 ? '#050B1E' : '#A9B6CF'}">${t}</div>`
    : `<div style="font-family: 'Barlow Condensed', sans-serif; font-weight: 700; font-size: 34px; letter-spacing: 1px; color: ${i === 0 ? '#FFFFFF' : '#A9B6CF'}; padding: 8px 0; border-bottom: 4px solid ${i === 0 ? '#FAD35A' : 'transparent'}">${t}</div>`).join('');
  const tabWrap = S.tabsAsPills
    ? `<div style="display: flex; gap: 6px; padding: 8px; border-radius: 36px; background: #0B1733; box-shadow: 0 0 0 1px #1C2E55">${tabs}</div>`
    : `<div style="display: flex; gap: 44px">${tabs}</div>`;
  const btn = (label, primary, icon) => `<div style="height: 64px; padding: 0 30px; border-radius: ${S.btn}px; background: ${primary ? '#FAD35A' : '#10203F'}; color: ${primary ? '#050B1E' : '#FFFFFF'}; display: flex; align-items: center; gap: 12px; font-weight: 700; font-size: 26px; ${primary ? 'box-shadow: 0 0 0 5px #050B1E, 0 0 0 9px #FAD35A' : ''}">${icon || ''}${label}</div>`;
  const playIc = '<svg width="20" height="20" viewBox="0 0 24 24"><path d="M6 3l15 9-15 9z" fill="#050B1E"/></svg>';
  const restartIc = svg(ICON.dvr, '#FFFFFF', 24, 4);
  return `<div style="width: 1920px; height: 1080px; position: relative; overflow: hidden; background: #050B1E; color: #FFFFFF; font-family: Barlow, sans-serif">
  <div style="position: absolute; left: 0; top: 0; width: 1920px; height: 104px; display: flex; align-items: center; padding: 0 64px; box-sizing: border-box; gap: 48px; ${S.tabsAsPills ? '' : 'border-bottom: 1px solid #1C2E55'}">
    <img src="${b('ec7c10bad0117787e03b001592d65bba')}" alt="mySDAtv" style="width: 150px; height: 78px">
    ${tabWrap}
    <div style="margin-left: auto; font-family: 'Barlow Condensed', sans-serif; font-weight: 700; font-size: 34px">3:20 PM <span style="color: #A9B6CF; font-weight: 600">SUN OCT 5</span></div>
  </div>
  <div style="position: absolute; left: 64px; top: 136px; width: 640px; height: 360px; border-radius: ${S.panel}px; overflow: hidden; background: #000000">
    <img src="${b('c4daed39c492a92a3a5a2eeb01619e11')}" alt="" style="width: 100%; height: 100%; object-fit: cover">
    <div style="position: absolute; left: 16px; top: 16px; height: 34px; padding: 0 14px; border-radius: 17px; background: #F0262B; display: flex; align-items: center; gap: 8px; font-weight: 700; font-size: 19px"><span style="width: 8px; height: 8px; border-radius: 4px; background: #FFFFFF"></span>LIVE PREVIEW</div>
  </div>
  <div style="position: absolute; left: 744px; top: 140px; width: 1112px; display: flex; flex-direction: column; gap: 14px">
    <div style="display: flex; align-items: center; gap: 16px">
      <div style="width: 98px; height: 70px; border-radius: ${Math.min(S.cell, 14)}px; background: #FFFFFF; display: flex; align-items: center; justify-content: center"><img src="${b('242bd1a56c08d0855ef8ca15fcbcd4ef')}" alt="" style="width: 88px; height: 62px; object-fit: contain"></div>
      <span style="font-family: 'Barlow Condensed', sans-serif; font-weight: 700; font-size: 30px; color: #FAD35A">3ABN · CH 1</span>
    </div>
    <h1 style="margin: 0; font-family: 'Barlow Condensed', sans-serif; font-weight: 700; font-size: 66px; line-height: 1">3ABN TODAY BIBLE Q&amp;A</h1>
    <div style="display: flex; align-items: center; gap: 18px; font-size: 26px; color: #A9B6CF"><span>3:00 – 3:55 PM</span><div style="width: 360px; height: 6px; border-radius: 3px; background: #1C2E55"><div style="width: 36%; height: 6px; border-radius: 3px; background: #FAD35A"></div></div><span>35 min left</span></div>
    <div style="font-size: 25px; color: #A9B6CF"><span style="color: #FFFFFF; font-weight: 600">Next 4:00 PM</span> · 3ABN KIDS CAMP KITCHEN FUN</div>
    <div style="display: flex; gap: 22px; margin-top: 14px">${btn('Watch live', true, playIc)}${btn('Start over', false, restartIc)}${btn('Catch-up', false)}</div>
  </div>
  <div style="position: absolute; left: 380px; top: 540px; width: 1476px; height: 40px; font-family: 'Barlow Condensed', sans-serif; font-weight: 700; font-size: 26px; color: #A9B6CF">
    <span style="position: absolute; left: 0">3:00 PM</span><span style="position: absolute; left: 369px">3:30</span><span style="position: absolute; left: 738px">4:00 PM</span><span style="position: absolute; left: 1107px">4:30</span>
  </div>
  <div style="position: absolute; left: 64px; top: 590px; width: 1792px; display: flex; flex-direction: column; gap: ${S.gap}px">
      ${rows}
  </div>
  <div style="position: absolute; left: ${64 + X0 + NOW * PPM - 2}px; top: 580px; width: 4px; height: ${5 * 84 + 4 * S.gap + 20}px; background: #FAD35A; border-radius: 2px"></div>
  <div style="position: absolute; left: ${64 + X0 + NOW * PPM - 30}px; top: 548px; height: 32px; padding: 0 12px; border-radius: 16px; background: #FAD35A; color: #050B1E; font-family: 'Barlow Condensed', sans-serif; font-weight: 700; font-size: 22px; display: flex; align-items: center">3:20</div>
</div>`;
}
const B = {
  // Pill: every control a full capsule, cells softened to 14.
  pill: { btn: 32, cell: 14, cellPad: 16, panel: 20, gap: 8, tabsAsPills: true },
  // Soft: one 16 px radius for buttons, 12 for cells, the underline tabs kept.
  soft: { btn: 16, cell: 12, cellPad: 14, panel: 16, gap: 6, tabsAsPills: false },
  // Capsule: cells as capsules too, wider gaps, the tab bar a floating capsule.
  capsule: { btn: 32, cell: 42, cellPad: 26, panel: 28, gap: 10, tabsAsPills: true }
};

const boards = [
  ['A-Alpha-InkEmber', 'A-α · Ink and ember (rail open)', page('A alpha', AF, aAlpha())],
  ['A-Beta-BrandRibbon', 'A-β · Brand ribbon (rail open)', page('A beta', AF, aBeta())],
  ['A-Gamma-DockTiles', 'A-γ · Dock tiles (rail at rest)', page('A gamma', AF, aGamma())],
  ['B-Pill', 'B · Pill shapes', page('B pill', BF, guide(B.pill))],
  ['B-Soft', 'B · Soft 16 px', page('B soft', BF, guide(B.soft))],
  ['B-Capsule', 'B · Capsule cells', page('B capsule', BF, guide(B.capsule))]
];
for (const [f, , html] of boards) fs.writeFileSync(path.join(OUT, f + '.dc.html'), html);
console.log(boards.map((x) => x[0] + ' | ' + x[1]).join('\n'));
