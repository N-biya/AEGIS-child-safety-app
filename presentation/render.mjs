// AEGIS deck renderer — HTML -> crisp PNG via headless Chromium.
// Usage: node render.mjs <file1.html> [file2.html ...]
//        node render.mjs all        (renders palette + every slide in slides/)
import { chromium } from 'playwright';
import { readdirSync } from 'fs';
import { resolve, dirname, basename, join } from 'path';
import { fileURLToPath, pathToFileURL } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));

function collectTargets(args) {
  if (args.length === 1 && args[0] === 'all') {
    const out = [resolve(__dirname, 'palette.html')];
    const slidesDir = resolve(__dirname, 'slides');
    for (const f of readdirSync(slidesDir).filter(f => f.endsWith('.html')).sort())
      out.push(join(slidesDir, f));
    return out;
  }
  return args.map(a => resolve(process.cwd(), a));
}

const targets = collectTargets(process.argv.slice(2));
if (!targets.length) { console.error('No targets. Pass html files or "all".'); process.exit(1); }

const browser = await chromium.launch();
const page = await browser.newPage({
  viewport: { width: 1920, height: 1080 },
  deviceScaleFactor: 2,            // 3840x2160 output — crisp at print/projector
});

for (const file of targets) {
  await page.goto(pathToFileURL(file).href, { waitUntil: 'networkidle' });
  try { await page.evaluate(() => document.fonts.ready); } catch {}
  await page.waitForTimeout(350);  // settle webfonts + blur layers
  const el = await page.$('.slide');
  const outPng = file.replace(/\.html$/, '.png');
  await (el ?? page).screenshot({ path: outPng });
  console.log('rendered ->', basename(outPng));
}

await browser.close();
