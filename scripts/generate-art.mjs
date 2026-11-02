// Optional asset regeneration, Node >=22.13. No npm packages or network access.
import { readFileSync, writeFileSync } from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
import { deflateSync } from 'node:zlib';
const source = new URL('../Reference/ArtGenerator.ts', import.meta.url);
const js = stripTypeScriptTypes(readFileSync(source, 'utf8'));
const { createArtJob, ART_PRESETS } = await import('data:text/javascript;base64,' + Buffer.from(js).toString('base64'));
function crc32(data) {
  let crc = 0xffffffff;
  for (const byte of data) {
    crc ^= byte;
    for (let bit = 0; bit < 8; bit++) crc = (crc >>> 1) ^ ((crc & 1) ? 0xedb88320 : 0);
  }
  return (crc ^ 0xffffffff) >>> 0;
}
function chunk(type, data) {
  const name = Buffer.from(type);
  const length = Buffer.alloc(4); length.writeUInt32BE(data.length);
  const crc = Buffer.alloc(4); crc.writeUInt32BE(crc32(Buffer.concat([name, data])));
  return Buffer.concat([length, name, data, crc]);
}
for (const [preset, seed] of [['aurora', 3], ['ember', 11]]) {
  const job = createArtJob(546, 444, ART_PRESETS[preset], seed);
  while (!job.step(16)) { /* offline generation; no runtime rendering loop */ }
  const header = Buffer.alloc(13);
  header.writeUInt32BE(job.width, 0); header.writeUInt32BE(job.height, 4);
  header[8] = 8; header[9] = 6;
  const rows = Buffer.alloc((job.width * 4 + 1) * job.height);
  for (let y = 0; y < job.height; y++) {
    rows[y * (job.width * 4 + 1)] = 0;
    rows.set(job.pixels.subarray(y * job.width * 4, (y + 1) * job.width * 4), y * (job.width * 4 + 1) + 1);
  }
  const png = Buffer.concat([Buffer.from([137,80,78,71,13,10,26,10]), chunk('IHDR', header),
    chunk('IDAT', deflateSync(rows)), chunk('IEND', Buffer.alloc(0))]);
  writeFileSync(new URL(`../Sources/GlassFinder/Resources/${preset}.png`, import.meta.url), png);
  console.log(`Generated ${preset}.png (${job.width}×${job.height}, seed ${seed})`);
}
