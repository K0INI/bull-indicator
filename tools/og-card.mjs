// Generates the social share card (1200x630) from the current cycle reading.
// Usage: node tools/og-card.mjs <output.png> [repoRoot]
import { readFileSync } from "node:fs";

const pw = (await import("playwright")).default;
const { chromium } = pw;

const OUT = process.argv[2] || "og-card.png";
const ROOT = process.argv[3] || process.cwd();

const d = JSON.parse(readFileSync(`${ROOT}/data/latest.json`, "utf8"));
const c = d.composite;
const score = Math.round(c.score);
const val = Math.round(c.valuation);
const trend = Math.round(c.trend);
const regime = c.regime;
const conf = c.confidence;

const BANDS = [[20, "#3B82F6"], [40, "#22D3EE"], [60, "#3ECF8E"], [75, "#FBBF24"], [88, "#F97316"], [100, "#EF4444"]];
const band = (s) => { for (const [t, col] of BANDS) if (s <= t) return col; return "#EF4444"; };
const col = band(c.score), valCol = band(c.valuation), trendCol = band(c.trend);
const pin = Math.max(0, Math.min(100, c.score));

const dataURI = (path, mime) => `data:${mime};base64,${readFileSync(path).toString("base64")}`;
const ttf = (fam, wt, file) => `@font-face{font-family:"${fam}";font-weight:${wt};src:url(${dataURI(`${ROOT}/site/fonts/${file}`, "font/ttf")}) format("truetype")}`;
const lockup = dataURI(`${ROOT}/site/lockup-white.png`, "image/png");

const html = `<!doctype html><html><head><meta charset="utf-8"><style>
${ttf("Jost", 200, "Jost_200ExtraLight.ttf")}
${ttf("Jost", 300, "Jost_300Light.ttf")}
${ttf("Jost", 500, "Jost_500Medium.ttf")}
${ttf("JetBrains Mono", 400, "JetBrainsMono_400Regular.ttf")}
:root{--noir:#0A0B0D;--snow:#FAFAF7;--haze:#C3CCD8;--dim:#8E98AB;--line:#232A40;--mono:"JetBrains Mono",monospace}
*{margin:0;box-sizing:border-box}
body{width:1200px;height:630px;background:var(--noir);color:var(--snow);font-family:Jost,sans-serif;font-weight:300;overflow:hidden;position:relative}
.glow{position:absolute;width:820px;height:820px;left:-160px;top:-260px;border-radius:50%;background:radial-gradient(circle, ${col}26 0%, ${col}00 62%)}
.pad{position:relative;padding:56px 64px;height:100%;display:flex;flex-direction:column}
.head{display:flex;align-items:center;justify-content:space-between}
.head img{height:50px}
.url{font-family:var(--mono);font-size:19px;color:var(--dim);letter-spacing:.02em}
.hook{margin-top:30px;font-size:33px;color:var(--haze);font-weight:300}
.hero{display:flex;align-items:center;gap:44px;margin-top:14px}
.score{font-weight:200;font-size:210px;line-height:.86;letter-spacing:-.03em;font-variant-numeric:tabular-nums;color:${col}}
.meta{display:flex;flex-direction:column;gap:6px}
.lab{font-family:var(--mono);font-size:19px;letter-spacing:.22em;color:var(--dim)}
.regime{font-weight:500;font-size:62px;line-height:1;color:${col}}
.pill{margin-top:8px;align-self:flex-start;font-family:var(--mono);font-size:15px;letter-spacing:.1em;text-transform:uppercase;color:${col};border:1px solid ${col};border-radius:8px;padding:6px 12px}
.spacer{flex:1}
.bar{position:relative;height:20px;margin-bottom:10px}
.bands{position:absolute;inset:0;display:flex;border-radius:4px;overflow:hidden}
.bands i{height:100%;opacity:.9}
.pin{position:absolute;top:-6px;bottom:-6px;width:6px;margin-left:-3px;border-radius:3px;background:var(--snow);box-shadow:0 0 0 3px var(--noir)}
.blab{display:flex;justify-content:space-between;font-family:var(--mono);font-size:14px;color:var(--dim)}
.foot{display:flex;align-items:center;justify-content:space-between;margin-top:26px}
.chips{display:flex;gap:14px}
.chip{font-family:var(--mono);font-size:20px;color:var(--haze);background:#0f1526;border:1px solid var(--line);border-radius:12px;padding:12px 18px}
.chip b{font-weight:400}
.tag{font-size:23px;color:#3ECF8E}
</style></head><body>
<div class="glow"></div>
<div class="pad">
<div class="head"><img src="${lockup}" alt="KOINI Bull Indicator"><div class="url">bull.koini.io</div></div>
<div class="hook">Where is Bitcoin in its market cycle?</div>
<div class="hero">
<div class="score">${score}</div>
<div class="meta">
<div class="lab">CYCLE SCORE</div>
<div class="regime">${regime}</div>
<div class="pill">${conf} confidence</div>
</div>
</div>
<div class="spacer"></div>
<div class="bar">
<div class="bands"><i style="flex:20;background:#3B82F6"></i><i style="flex:20;background:#22D3EE"></i><i style="flex:20;background:#3ECF8E"></i><i style="flex:15;background:#FBBF24"></i><i style="flex:13;background:#F97316"></i><i style="flex:12;background:#EF4444"></i></div>
<div class="pin" style="left:${pin}%"></div>
</div>
<div class="blab"><span>Capitulation</span><span>Early expansion</span><span>Euphoria</span></div>
<div class="foot">
<div class="chips"><div class="chip">VALUATION <b style="color:${valCol}">${val}</b></div><div class="chip">TREND <b style="color:${trendCol}">${trend}</b></div></div>
<div class="tag">Read the cycle.</div>
</div>
</div>
</body></html>`;

const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 1200, height: 630 }, deviceScaleFactor: 2 });
await page.setContent(html, { waitUntil: "networkidle" });
await page.waitForTimeout(300);
await page.screenshot({ path: OUT, clip: { x: 0, y: 0, width: 1200, height: 630 } });
await browser.close();
console.log("wrote", OUT, "-", score, regime);
