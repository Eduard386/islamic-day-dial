#!/usr/bin/env node
/**
 * Generates favicon from user's sunset image.
 * Makes dark background transparent, crops to visible content,
 * then updates both the PNG file and the inlined favicon HTML.
 */
import { createHash } from 'crypto';
import sharp from 'sharp';
import { readFile, writeFile } from 'fs/promises';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __dirname = dirname(fileURLToPath(import.meta.url));
const PUBLIC = join(__dirname, '../public');
const srcPath = join(PUBLIC, 'sunset-source.png');
const outPath = join(PUBLIC, 'favicon.png');
const htmlPath = join(__dirname, '../index.html');

const img = await sharp(srcPath);
const { data, info } = await img
  .raw()
  .ensureAlpha()
  .toBuffer({ resolveWithObject: true });

const threshold = 40; // pixels darker than this become transparent
let minX = info.width;
let minY = info.height;
let maxX = -1;
let maxY = -1;

for (let i = 0; i < data.length; i += 4) {
  const r = data[i];
  const g = data[i + 1];
  const b = data[i + 2];

  if (r < threshold && g < threshold && b < threshold) {
    data[i + 3] = 0; // transparent
    continue;
  }

  const pixelIndex = i / 4;
  const x = pixelIndex % info.width;
  const y = Math.floor(pixelIndex / info.width);
  minX = Math.min(minX, x);
  minY = Math.min(minY, y);
  maxX = Math.max(maxX, x);
  maxY = Math.max(maxY, y);
}

if (maxX < 0 || maxY < 0) {
  throw new Error('No visible icon content found in source image.');
}

// Slight trim of reflection + `contain` inside an inner box so the tab chip doesn’t clip edges.
const cropPadding = 2;
const contentW = maxX - minX + 1;
const contentH = maxY - minY + 1;
const trimBottomRatio = 0.28;
const trimmedH = Math.max(
  24,
  Math.floor(contentH * (1 - trimBottomRatio)),
);
const effectiveMaxY = Math.min(maxY, minY + trimmedH - 1);

const left = Math.max(0, minX - cropPadding);
const top = Math.max(0, minY - cropPadding);
const width = Math.min(info.width - left, contentW + cropPadding * 2);
const height = Math.min(
  info.height - top,
  effectiveMaxY - minY + 1 + cropPadding * 2,
);

const transparentSource = sharp(Buffer.from(data), {
  raw: { width: info.width, height: info.height, channels: 4 },
});

// 64×64 canvas: as large as possible, bottom-aligned so the horizon/sun base sits on the lower edge.
const OUT = 64;
const SIDE_SAFE = 1; // px left/right
const TOP_SAFE = 1; // thin air above rays
const BOTTOM_SAFE = 0; // 0 = lowest pixels flush with canvas bottom (try 1 if a browser clips)

const innerW = OUT - 2 * SIDE_SAFE;
const innerH = OUT - TOP_SAFE - BOTTOM_SAFE;

const scaled = await transparentSource
  .extract({ left, top, width, height })
  .resize(innerW, innerH, {
    fit: 'contain',
    background: { r: 0, g: 0, b: 0, alpha: 0 },
  })
  .png()
  .toBuffer();

const meta = await sharp(scaled).metadata();
const w = meta.width ?? innerW;
const h = meta.height ?? innerH;

const dstLeft = Math.round((OUT - w) / 2);
let dstTop = OUT - h - BOTTOM_SAFE;
if (dstTop < TOP_SAFE) {
  dstTop = TOP_SAFE;
}

await sharp({
  create: {
    width: OUT,
    height: OUT,
    channels: 4,
    background: { r: 0, g: 0, b: 0, alpha: 0 },
  },
})
  .composite([
    {
      input: scaled,
      left: dstLeft,
      top: dstTop,
    },
  ])
  .png()
  .toFile(outPath);

const pngBuf = await readFile(outPath);
const v = createHash('sha256').update(pngBuf).digest('hex').slice(0, 12);
const html = await readFile(htmlPath, 'utf8');
const updatedHtml = html.replace(
  /href="favicon\.png\?v=[^"]+"/g,
  `href="favicon.png?v=${v}"`,
);

await writeFile(htmlPath, updatedHtml);

console.log('Favicon saved to', outPath, '| index.html ?v=', v);
