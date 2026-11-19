// Decodes the QR code in a Churches screen capture, so a device capture can
// be checked against the church's link (task 2026-11-18-churches-qr).
//
//   powershell -File to-rgba.ps1 <capture.jpg> <out.rgba>   (writes w,h header)
//   node decode-qr.js <out.rgba> [jsqr module dir]
//
// The .rgba file: 8-byte header (uint32 LE width, height) + RGBA bytes.
const fs = require('fs');
const path = require('path');
const file = process.argv[2];
const jsqrDir = process.argv[3] || 'D:/Tulix/coacb_roku/node_modules/jsqr';
const jsQR = require(path.resolve(jsqrDir));
const buf = fs.readFileSync(file);
const w = buf.readUInt32LE(0);
const h = buf.readUInt32LE(4);
const px = new Uint8ClampedArray(buf.buffer, buf.byteOffset + 8, w * h * 4);
const code = jsQR(px, w, h);
console.log(code ? 'DECODED ' + code.data : 'NO CODE FOUND');
