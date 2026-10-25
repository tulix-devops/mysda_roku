// A · Lineup, α "Ink and ember" (owner pick, 2026-10-06), on all eight screens.
// Flat ink ground, a solid rail panel with WATCH / LISTEN / ACCOUNT sections and
// icon tiles that fill red on focus, the whole logo (never a cropped globe).
const fs = require('fs');
const path = require('path');
const OUT = path.join(__dirname, 'canvas', 'project');
const b = (id) => '/_blob/' + id;
const T = { ink: '#0A0D16', panel: '#11151F', tile: '#1A2030', surf: '#141927', sec: '#6F7891', t2: '#8C95AA', red: '#F0262B', gold: '#FAD35A', blue: '#0981FB', line: '#1E2433' };
const ICON = {
  tv: 'M8.5 12h23a3.5 3.5 0 0 1 3.5 3.5v13a3.5 3.5 0 0 1-3.5 3.5h-23A3.5 3.5 0 0 1 5 28.5v-13A3.5 3.5 0 0 1 8.5 12zM14 36h12M15 5l5 6 5-6',
  globe: 'M35 20a15 15 0 1 1-30 0 15 15 0 0 1 30 0zM27 20c0 8.3-3.1 15-7 15s-7-6.7-7-15 3.1-15 7-15 7 6.7 7 15zM5 20h30M8 12.5h24M8 27.5h24',
  dvr: 'M8 13a14 14 0 1 1-2 9M4.5 8l2.1 7.3 7-2.3M20 12v8l6 3.5',
  radio: 'M7.5 14h25a3.5 3.5 0 0 1 3.5 3.5v14a3.5 3.5 0 0 1-3.5 3.5h-25A3.5 3.5 0 0 1 4 31.5v-14A3.5 3.5 0 0 1 7.5 14zM20 24.5a5.5 5.5 0 1 1-11 0 5.5 5.5 0 0 1 11 0zM25 21h6M25 27.5h6M9 14l21-9',
  user: 'M26.5 12.5a6.5 6.5 0 1 1-13 0 6.5 6.5 0 0 1 13 0zM7 34c0-7.5 5.5-11.5 13-11.5S33 26.5 33 34',
  lock: 'M11 18h18a3 3 0 0 1 3 3v12a3 3 0 0 1-3 3H11a3 3 0 0 1-3-3V21a3 3 0 0 1 3-3zM14 18v-5a6 6 0 0 1 12 0v5',
  check: 'M9 21l7 7 15-16',
  play: 'M13 8l20 12-20 12z',
  restart: 'M8 13a14 14 0 1 1-2 9M4.5 8l2.1 7.3 7-2.3'
};
const svg = (k, c, s = 34, w = 3) => `<svg width="${s}" height="${s}" viewBox="0 0 40 40" fill="none" stroke="${c}" stroke-width="${w}" stroke-linecap="round" stroke-linejoin="round"><path d="${ICON[k]}"/></svg>`;
const NAV = [['WATCH', [['tv', 'Television'], ['globe', 'TV Languages'], ['dvr', 'DVR']]], ['LISTEN', [['radio', 'Radios']]], ['ACCOUNT', [['user', 'Login']]]];

function tileIcon(k, state, size = 56) {
  const bg = state === 'focus' ? T.red : (state === 'sel' ? 'rgba(250,211,90,0.16)' : T.tile);
  const ic = state === 'focus' ? '#FFFFFF' : (state === 'sel' ? T.gold : '#C4CAD6');
  return `<div style="width: ${size}px; height: ${size}px; border-radius: 16px; background: ${bg}; display: flex; align-items: center; justify-content: center; flex-shrink: 0; ${state === 'focus' ? 'box-shadow: 0 8px 24px rgba(240,38,43,0.45)' : ''}">${svg(k, ic)}</div>`;
}
// The OPEN rail: 440 wide, the logo, sections, rows, the last-watched card.
function railOpen(focus, selected) {
  let rows = '';
  for (const [sec, items] of NAV) {
    rows += `<div style="font-weight: 700; font-size: 17px; letter-spacing: 2.5px; color: ${T.sec}; padding: 18px 12px 6px">${sec}</div>`;
    for (const [k, label] of items) {
      const st = k === focus ? 'focus' : (k === selected ? 'sel' : '');
      rows += `<div style="height: 76px; border-radius: 20px; display: flex; align-items: center; gap: 18px; padding: 0 10px; background: ${st === 'focus' ? 'rgba(240,38,43,0.14)' : 'transparent'}">${tileIcon(k, st)}<span style="font-weight: ${st ? 700 : 600}; font-size: 28px; color: ${st === 'sel' ? T.gold : '#FFFFFF'}">${label}</span></div>`;
    }
  }
  return `<div style="position: absolute; left: 0; top: 0; width: 440px; height: 1080px; background: ${T.panel}; box-shadow: 1px 0 0 ${T.line}, 30px 0 80px rgba(0,0,0,0.5)">
    <img src="${b('ec7c10bad0117787e03b001592d65bba')}" alt="mySDAtv" style="position: absolute; left: 34px; top: 22px; width: 186px; height: 97px">
    <div style="position: absolute; left: 22px; top: 130px; width: 396px; display: flex; flex-direction: column; gap: 6px">${rows}</div>
    <div style="position: absolute; left: 22px; bottom: 30px; width: 396px; border-radius: 20px; background: ${T.tile}; padding: 16px; box-sizing: border-box; display: flex; gap: 14px; align-items: center">
      <div style="width: 84px; height: 60px; border-radius: 10px; background: #FFFFFF; display: flex; align-items: center; justify-content: center; flex-shrink: 0"><img src="${b('242bd1a56c08d0855ef8ca15fcbcd4ef')}" alt="" style="width: 76px; height: 54px; object-fit: contain"></div>
      <div style="display: flex; flex-direction: column; gap: 4px; min-width: 0"><span style="font-weight: 700; font-size: 15px; letter-spacing: 1.5px; color: ${T.red}">● LAST WATCHED</span><span style="font-weight: 600; font-size: 21px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis">3ABN TODAY BIBLE Q&amp;A</span></div>
    </div>
  </div>`;
}
// The CLOSED rail: the same panel at 120, the whole logo small, the tiles.
function railClosed(selected) {
  let rows = '';
  NAV.forEach(([, items], si) => {
    if (si > 0) rows += '<div style="width: 40px; height: 2px; border-radius: 1px; background: #232A3B; margin: 12px auto"></div>';
    for (const [k] of items) rows += tileIcon(k, k === selected ? 'sel' : '');
  });
  return `<div style="position: absolute; left: 0; top: 0; width: 120px; height: 1080px; background: ${T.panel}; box-shadow: 1px 0 0 ${T.line}">
    <img src="${b('ec7c10bad0117787e03b001592d65bba')}" alt="mySDAtv" style="position: absolute; left: 10px; top: 36px; width: 100px; height: 52px">
    <div style="position: absolute; left: 32px; top: 180px; width: 56px; display: flex; flex-direction: column; gap: 14px">${rows}</div>
  </div>`;
}
const clock = () => `<div style="position: absolute; right: 60px; top: 48px; height: 60px; border-radius: 30px; background: ${T.surf}; display: flex; align-items: center; gap: 28px; padding: 0 28px"><span style="font-family: Manrope, sans-serif; font-weight: 700; font-size: 30px">3:20 PM</span><span style="font-size: 21px; color: #B4BCCB">Sunday, Oct 5</span></div>`;
const head = (left, title, sub) => `<h1 style="position: absolute; left: ${left}px; top: 52px; margin: 0; font-family: Manrope, sans-serif; font-weight: 800; font-size: 54px; line-height: 66px">${title}</h1>
  <div style="position: absolute; left: ${left}px; top: 124px; font-size: 24px; color: ${T.t2}">${sub}</div>`;
const chips = (left, top, list) => `<div style="position: absolute; left: ${left}px; top: ${top}px; display: flex; gap: 12px; white-space: nowrap">${list.map(([l, n], i) => `<div style="height: 50px; padding: 0 22px; border-radius: 25px; display: flex; align-items: center; gap: 10px; font-weight: 600; font-size: 22px; background: ${i === 0 ? T.gold : T.tile}; color: ${i === 0 ? '#0A0D16' : '#FFFFFF'}">${l}<span style="opacity: 0.65">${n}</span></div>`).join('')}</div>`;
function grid(left, top, tiles, focusIdx, extra) {
  const t = tiles.map(([l, title, meta, pct, badge], i) => {
    const f = i === focusIdx;
    return `<div style="display: flex; flex-direction: column; gap: 12px">
        <div style="position: relative; height: 230px; border-radius: 16px; background: #FFFFFF; display: flex; align-items: center; justify-content: center; transform: scale(${f ? 1 : 0.92}); transform-origin: bottom left; opacity: ${f ? 1 : 0.86}; box-shadow: ${f ? '0 0 0 3px rgba(240,38,43,0.35), 0 0 46px 6px rgba(240,38,43,0.45)' : 'none'}">
          <img src="${b(l)}" alt="" style="width: 290px; height: 206px; object-fit: contain">
          ${badge ? `<div style="position: absolute; left: 12px; top: 12px; height: 32px; padding: 0 12px; border-radius: 16px; background: rgba(10,13,22,0.88); display: flex; align-items: center; font-weight: 700; font-size: 17px; color: ${T.gold}">${badge}</div>` : ''}
        </div>
        <div style="font-weight: 600; font-size: 27px; color: ${f ? T.red : '#FFFFFF'}; white-space: nowrap; overflow: hidden; text-overflow: ellipsis">${title}</div>
        <div style="display: flex; align-items: center; gap: 10px; font-weight: 500; font-size: 22px; color: ${T.t2}; white-space: nowrap; overflow: hidden">${pct !== null ? `<span style="width: 10px; height: 10px; border-radius: 5px; background: ${T.red}; flex-shrink: 0"></span>` : ''}<span style="overflow: hidden; text-overflow: ellipsis">${meta}</span></div>
        ${pct ? `<div style="height: 4px; border-radius: 2px; background: rgba(255,255,255,0.12)"><div style="height: 4px; border-radius: 2px; background: ${T.red}; width: ${pct}"></div></div>` : ''}
      </div>`;
  }).join('\n      ');
  return `<div style="position: absolute; left: ${left}px; top: ${top}px; width: 1700px; display: grid; grid-template-columns: repeat(5, minmax(0, 1fr)); gap: 44px 20px">${t}</div>`;
}
const btn = (label, primary, icon) => `<div style="height: 72px; padding: 0 34px; border-radius: 20px; background: ${primary ? T.red : T.tile}; display: flex; align-items: center; gap: 12px; font-weight: 700; font-size: 27px; ${primary ? 'box-shadow: 0 0 0 5px #0A0D16, 0 0 0 9px #FFFFFF, 0 10px 30px rgba(240,38,43,0.4)' : ''}">${icon ? svg(icon, '#FFFFFF', 26, 3.4) : ''}${label}</div>`;
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
<link href="https://fonts.googleapis.com/css2?family=Manrope:wght@700;800&amp;family=Inter:wght@500;600;700&amp;display=swap" rel="stylesheet">
<style>
body{margin:0}
</style>
</helmet>
<div style="width: 1920px; height: 1080px; position: relative; overflow: hidden; background: ${T.ink}; color: #FFFFFF; font-family: Inter, sans-serif">
  <div style="position: absolute; left: 0; bottom: 0; width: 1920px; height: 300px; background: linear-gradient(0deg, rgba(0,0,0,0.5), rgba(0,0,0,0))"></div>
${body}
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

const TV = [
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
const LANG = [
  ['65b299a9290c54c570d3ed32566fc0d7', 'Novo Tempo', 'Português · live now', null],
  ['b01b57a70c67310359e8c88197b9f4a7', 'Nuevo Tiempo', 'Español · live now', null],
  ['f6c61295f0443e7ad9bb2b7f1a99ddee', '3ABN Latino', 'MARAVILLOSA CREACIÓN', '71%'],
  ['1665be3f90d7999cb068ba7946955070', 'LLBN Latino', 'Español · live now', null],
  ['136b9acb47d16154b7835bc9a7d5e19a', '3ABN Français', 'Français · live now', null],
  ['42ed1061a9ed38d6e124007cc3c12fa8', '3ABN Russia Network', 'Русский · live now', null],
  ['568800af03c6d40aac53d5a56abf64df', 'LLBN Arabic', 'العربية · live now', null],
  ['341e48e88c70f0e21781d4f4b46230d7', 'LLBN Korean', '한국어 · live now', null],
  ['ecb38c2b5a360766adef64fb49bd5d7d', 'LLBN Chinese', '中文 · live now', null]
];
const RADIO = [
  ['2888c735f196e4ced270258e4bd0be07', '3ABN Radio', 'Live radio · English', null],
  ['dfe63e8c017361de0001a951b2020d2e', '3ABN Music Channel', 'Live radio · Music', null],
  ['7a52b253fa820b19ca2052f34366480f', '3ABN Australia Radio', 'Live radio · English', null],
  ['c3213fdf92f289d37c4272c832a8e8dd', '3ABN Latino Radio', 'Live radio · Español', null],
  ['5208d441840f2b0e53a315bbda40e0db', 'Novo Tempo Radio', 'Live radio · Português', null],
  ['c72a58266bbb3eeb731eaa768070d32a', 'Radio 74', 'Live radio', null]
];

// A1 · Television, rail closed, focus on the first tile.
const a1 = railClosed('tv') + head(160, 'Television', '24 channels · live now') + clock() +
  chips(160, 186, [['All', '24'], ['3ABN', '8'], ['LLBN', '3'], ['Good News', '2'], ['Better', '3'], ['More', '8']]) +
  grid(160, 270, TV, 0);
// A2 · TV Languages, rail open, focus in the rail.
const a2 = head(480, 'TV Languages', '16 channels in 9 languages') + clock() +
  chips(480, 186, [['All', '16'], ['Português', '3'], ['Español', '6'], ['Français', '1'], ['Русский', '1'], ['العربية', '1'], ['한국어', '1']]) +
  grid(480, 270, LANG, -1) + railOpen('globe', 'tv');
// A3 · Radios, rail closed.
const a3 = railClosed('radio') + head(160, 'Radios', '10 stations, live around the clock') + clock() + grid(160, 200, RADIO, 0);
// A4 · Radio playing, no rail.
const bars = [28, 46, 62, 40, 70, 52, 34, 58, 72, 44, 30, 54, 66, 38, 48, 70, 56, 32, 42, 64, 50, 36, 60, 26].map((h, i) => `<div style="width: 12px; border-radius: 6px; height: ${h}px; background: ${i < 9 ? T.red : '#232A3B'}"></div>`).join('');
const strip = RADIO.map(([l], i) => `<div style="width: 236px; height: 168px; border-radius: 16px; background: #FFFFFF; display: flex; align-items: center; justify-content: center; opacity: ${i === 0 ? 1 : 0.7}; box-shadow: ${i === 0 ? `0 0 0 4px ${T.gold}` : 'none'}"><img src="${b(l)}" alt="" style="width: 214px; height: 152px; object-fit: contain"></div>`).join('');
const a4 = `<div style="position: absolute; left: 160px; top: 150px; width: 640px; height: 454px; border-radius: 28px; background: #FFFFFF; display: flex; align-items: center; justify-content: center; box-shadow: 0 0 90px 10px rgba(240,38,43,0.22)"><img src="${b('2888c735f196e4ced270258e4bd0be07')}" alt="" style="width: 560px; height: 398px; object-fit: contain"></div>
  <div style="position: absolute; left: 880px; top: 170px; width: 900px; display: flex; flex-direction: column; gap: 22px">
    <div style="display: flex; align-items: center; gap: 14px"><div style="height: 40px; padding: 0 18px; border-radius: 20px; background: ${T.red}; display: flex; align-items: center; gap: 10px; font-weight: 700; font-size: 22px; letter-spacing: 1px"><span style="width: 10px; height: 10px; border-radius: 5px; background: #FFFFFF"></span>LIVE</div><span style="font-size: 24px; color: ${T.gold}; font-weight: 600">Radio · English</span></div>
    <h1 style="margin: 0; font-family: Manrope, sans-serif; font-weight: 800; font-size: 76px; line-height: 1.05">3ABN Radio</h1>
    <div style="display: flex; align-items: flex-end; gap: 8px; height: 72px">${bars}</div>
    <div style="display: flex; gap: 18px; margin-top: 18px">${btn('Pause', true)}${btn('All stations', false)}</div>
  </div>
  <div style="position: absolute; left: 160px; top: 720px; font-weight: 700; font-size: 17px; letter-spacing: 2.5px; color: ${T.sec}">UP / DOWN · OTHER STATIONS</div>
  <div style="position: absolute; left: 160px; top: 760px; display: flex; gap: 20px">${strip}</div>` + clock();
// A5 · DVR channels, rail closed, login notice.
const DVR = TV.slice(0, 5).map(([l, t], i) => [l, t, ['849 programmes', '640 programmes', '1,485 programmes', 'Hourly recordings', 'Hourly recordings'][i], null, '21 DAYS'])
  .concat(TV.slice(5, 8).map(([l, t]) => [l, t, 'Hourly recordings', null, '21 DAYS']))
  .concat([['65b299a9290c54c570d3ed32566fc0d7', 'Novo Tempo', 'Hourly · Português', null, '21 DAYS'], ['568800af03c6d40aac53d5a56abf64df', 'LLBN Arabic', 'Hourly · العربية', null, '21 DAYS']]);
const a5 = railClosed('dvr') + head(160, 'DVR', 'Every channel, recorded for the last 21 days') + clock() +
  `<div style="position: absolute; right: 60px; top: 132px; height: 56px; border-radius: 28px; background: ${T.surf}; display: flex; align-items: center; gap: 14px; padding: 0 22px; font-size: 21px; color: #B4BCCB">${svg('lock', T.gold, 26, 3.4)}<span><span style="color: #FFFFFF; font-weight: 600">Log in</span> to watch recordings · browsing is open</span></div>` +
  grid(160, 230, DVR, 0);
// A6 · DVR recordings for one channel, no rail.
const days = ['Today', 'Yesterday', 'Fri, Oct 3', 'Thu, Oct 2', 'Wed, Oct 1', 'Tue, Sep 30', 'Mon, Sep 29', 'Sun, Sep 28'].map((d, i) => `<div style="height: 66px; border-radius: 18px; display: flex; align-items: center; justify-content: space-between; padding: 0 22px; font-weight: ${i === 0 ? 700 : 600}; font-size: 27px; color: ${i === 0 ? T.gold : '#FFFFFF'}; background: ${i === 0 ? 'rgba(250,211,90,0.1)' : 'transparent'}">${d}${i === 0 ? `<span style="width: 10px; height: 10px; border-radius: 5px; background: ${T.gold}"></span>` : ''}</div>`).join('');
const rec = (thumb, title, time, badge, focus, badgeBg) => `<div style="display: flex; flex-direction: column; gap: 10px">
      <div style="position: relative; height: 219px; border-radius: 16px; overflow: hidden; background: ${thumb ? T.surf : '#E9ECF2'}; transform: scale(${focus ? 1 : 0.92}); transform-origin: bottom left; opacity: ${focus ? 1 : 0.86}; box-shadow: ${focus ? '0 0 0 3px rgba(240,38,43,0.35), 0 0 46px 6px rgba(240,38,43,0.45)' : 'none'}">
        ${thumb ? `<img src="${b(thumb)}" alt="" style="width: 100%; height: 100%; object-fit: cover">` : `<div style="position: absolute; inset: 0; display: flex; align-items: center; justify-content: center"><img src="${b('242bd1a56c08d0855ef8ca15fcbcd4ef')}" alt="" style="width: 150px; height: 107px; object-fit: contain; opacity: 0.5"></div>`}
        <div style="position: absolute; right: 10px; bottom: 10px; height: 32px; padding: 0 12px; border-radius: 16px; background: ${badgeBg || 'rgba(10,13,22,0.85)'}; display: flex; align-items: center; font-weight: 700; font-size: 17px">${badge}</div>
      </div>
      <div style="font-weight: 600; font-size: 25px; color: ${focus ? T.red : '#FFFFFF'}; white-space: nowrap; overflow: hidden; text-overflow: ellipsis">${title}</div>
      <div style="font-weight: 500; font-size: 21px; color: ${T.t2}">${time}</div>
    </div>`;
const a6 = `<div style="position: absolute; left: 0; top: 0; width: 440px; height: 1080px; background: ${T.panel}; box-shadow: 1px 0 0 ${T.line}">
    <img src="${b('ec7c10bad0117787e03b001592d65bba')}" alt="mySDAtv" style="position: absolute; left: 34px; top: 22px; width: 186px; height: 97px">
    <div style="position: absolute; left: 34px; top: 150px; display: flex; align-items: center; gap: 16px"><div style="width: 93px; height: 66px; border-radius: 12px; background: #FFFFFF; display: flex; align-items: center; justify-content: center"><img src="${b('242bd1a56c08d0855ef8ca15fcbcd4ef')}" alt="" style="width: 84px; height: 60px; object-fit: contain"></div><span style="font-family: Manrope, sans-serif; font-weight: 800; font-size: 36px">3ABN</span></div>
    <div style="position: absolute; left: 22px; top: 248px; font-weight: 700; font-size: 17px; letter-spacing: 2.5px; color: ${T.sec}; padding-left: 12px">RECORDED DAYS</div>
    <div style="position: absolute; left: 22px; top: 284px; width: 396px; display: flex; flex-direction: column; gap: 4px">${days}</div>
  </div>
  ${head(480, '3ABN · DVR', 'Today · Sunday, Oct 5 · 37 programmes')}${clock()}
  <div style="position: absolute; left: 480px; top: 210px; width: 1380px; display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 40px 20px">
    ${rec('917133d468c5f2657305a93b11198669', 'ACTION 4 LIFE', '2:00 – 2:28 PM', '28 MIN', true)}
    ${rec('677cf0801d486ffa412e4bf103d043d0', 'A WOLF IN SHEEP’S CLOTHING', '2:30 – 2:58 PM', '28 MIN')}
    ${rec('c4daed39c492a92a3a5a2eeb01619e11', '3ABN TODAY BIBLE Q&amp;A', 'On now · 3:00 – 3:55 PM', '● LIVE', false, T.red)}
    ${rec('', '3ABN KIDS CAMP KITCHEN FUN', 'Later · 4:00 PM', 'UP NEXT')}
    ${rec('', 'TINY TOTS KITCHEN', 'Later · 4:30 PM', 'LATER')}
    ${rec('5153cbede4e2f6dc430a26bf44642cb4', '3ABN HOMECOMING', '3:00 – 3:45 AM', '45 MIN')}
  </div>`;
// A7 · Live player: a docked ink panel instead of a gradient wash.
const a7 = `<img src="${b('c4daed39c492a92a3a5a2eeb01619e11')}" alt="" style="position: absolute; inset: 0; width: 1920px; height: 1080px; object-fit: cover; filter: blur(6px); transform: scale(1.03)">
  <div style="position: absolute; right: 60px; top: 48px; height: 60px; border-radius: 30px; background: rgba(17,21,31,0.85); display: flex; align-items: center; padding: 0 28px; font-family: Manrope, sans-serif; font-weight: 700; font-size: 30px">3:20 PM</div>
  <div style="position: absolute; left: 60px; right: 60px; bottom: 50px; height: 360px; border-radius: 32px; background: rgba(17,21,31,0.94); box-shadow: 0 0 0 1px ${T.line}, 0 30px 80px rgba(0,0,0,0.6); padding: 36px 44px; box-sizing: border-box; display: flex; flex-direction: column; gap: 16px">
    <div style="display: flex; align-items: center; gap: 16px">
      <div style="width: 112px; height: 80px; border-radius: 14px; background: #FFFFFF; display: flex; align-items: center; justify-content: center"><img src="${b('242bd1a56c08d0855ef8ca15fcbcd4ef')}" alt="" style="width: 100px; height: 71px; object-fit: contain"></div>
      <div style="height: 40px; padding: 0 18px; border-radius: 20px; background: ${T.red}; display: flex; align-items: center; gap: 10px; font-weight: 700; font-size: 22px; letter-spacing: 1px"><span style="width: 10px; height: 10px; border-radius: 5px; background: #FFFFFF"></span>LIVE</div>
      <span style="font-size: 26px; font-weight: 600; color: ${T.gold}">3ABN</span>
      <span style="margin-left: auto; font-size: 22px; color: ${T.sec}">Up / Down: change channel</span>
    </div>
    <div style="font-family: Manrope, sans-serif; font-weight: 800; font-size: 56px; line-height: 1.1">3ABN TODAY BIBLE Q&amp;A</div>
    <div style="display: flex; align-items: center; gap: 22px; font-size: 25px; color: #B4BCCB"><span>3:00 PM</span><div style="width: 900px; height: 6px; border-radius: 3px; background: rgba(255,255,255,0.16)"><div style="width: 36%; height: 6px; border-radius: 3px; background: ${T.red}"></div></div><span>3:55 PM</span><span style="margin-left: 16px"><span style="color: #FFFFFF; font-weight: 600">Next 4:00</span> 3ABN KIDS CAMP KITCHEN FUN</span></div>
    <div style="display: flex; gap: 18px; margin-top: 8px">${btn('Start over', true, 'restart')}${btn('Earlier today', false)}${btn('Channels', false)}</div>
  </div>`;
// A8 · Account, rail open with Login focused.
const perks = ['21 days of every channel, recorded', 'Watch any programme you missed', 'Start a live programme over from the top'].map((p) => `<div style="display: flex; align-items: center; gap: 18px; font-size: 28px; font-weight: 600">${tileIcon('check', 'sel', 52)}${p}</div>`).join('');
const a8 = head(480, 'DVR access', 'Live channels, languages and radio are free') + clock() +
  `<div style="position: absolute; left: 480px; top: 210px; width: 860px; display: flex; flex-direction: column; gap: 18px">${perks}
    <p style="margin: 14px 0 0; font-size: 26px; line-height: 1.6; color: #B4BCCB">Recording every channel around the clock costs real storage, so DVR is a small subscription. Subscribe at mysdatv.com, then log in here with the same email and password.</p>
  </div>
  <div style="position: absolute; left: 1416px; top: 210px; width: 404px; border-radius: 28px; background: ${T.surf}; box-shadow: 0 0 0 1px ${T.line}; padding: 30px; box-sizing: border-box; display: flex; flex-direction: column; align-items: center; gap: 18px">
    <div style="width: 300px; height: 300px; border-radius: 18px; background: #FFFFFF; display: flex; align-items: center; justify-content: center"><img src="${b('ade3e22c8d4e928c90c54e00fb911009')}" alt="Donation QR code" style="width: 276px; height: 276px; object-fit: contain"></div>
    <div style="font-weight: 700; font-size: 26px">Prefer to give?</div>
    <div style="font-size: 21px; line-height: 1.5; color: #B4BCCB; text-align: center">A tax-deductible donation unlocks DVR for a whole year. Temporary promotion.</div>
  </div>
  <div style="position: absolute; left: 480px; top: 880px; display: flex; gap: 18px">${btn('Log in', false)}${btn('How to subscribe', false)}</div>` + railOpen('user', 'tv');

const boards = [
  ['AX1-Television', 'A1 · Television', a1], ['AX2-Languages', 'A2 · TV Languages (rail open)', a2],
  ['AX3-Radios', 'A3 · Radios', a3], ['AX4-RadioPlaying', 'A4 · Radio playing', a4],
  ['AX5-DVR', 'A5 · DVR channels', a5], ['AX6-DVRRecordings', 'A6 · DVR recordings', a6],
  ['AX7-LivePlayer', 'A7 · Live player', a7], ['AX8-Account', 'A8 · Account (rail open)', a8]
];
for (const [f, t, body] of boards) fs.writeFileSync(path.join(OUT, f + '.dc.html'), page(t, body));
console.log(boards.map((x) => x[0]).join(' '));
