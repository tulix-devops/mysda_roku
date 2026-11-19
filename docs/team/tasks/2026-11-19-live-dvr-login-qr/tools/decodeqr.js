// Decode a QR code PNG: node decodeqr.js <png>
const nm = 'D:/Tulix/coacb_roku/node_modules/';
const { PNG } = require(nm + 'pngjs');
const jsQR = require(nm + 'jsqr');
const fs = require('fs');
const png = PNG.sync.read(fs.readFileSync(process.argv[2]));
// Flatten alpha onto white so transparent pixels read as light.
const d = png.data;
for (let i = 0; i < d.length; i += 4) {
  const a = d[i + 3] / 255;
  for (let k = 0; k < 3; k++) d[i + k] = Math.round(d[i + k] * a + 255 * (1 - a));
  d[i + 3] = 255;
}
const r = jsQR(new Uint8ClampedArray(d), png.width, png.height, { inversionAttempts: 'attemptBoth' });
console.log(r ? JSON.stringify(r.data) : 'NO QR FOUND');
