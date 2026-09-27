import {
  ANCHORS_VERSION,
  COMPOSITE,
  CURVES,
  FRESH_HOURS,
  REGIMES,
  VOL_SENT,
  type Curve,
} from "../config/anchors.js";

// ---------- primitives ----------

/** Piecewise-linear interpolation over sorted [x, score] anchor points, clamped. */
export function curveScore(curve: Curve, x: number): number {
  if (!Number.isFinite(x)) throw new Error(`curveScore: non-finite input ${x}`);
  if (x <= curve[0][0]) return curve[0][1];
  const last = curve[curve.length - 1];
  if (x >= last[0]) return last[1];
  for (let i = 1; i < curve.length; i++) {
    const [x1, y1] = curve[i - 1];
    const [x2, y2] = curve[i];
    if (x <= x2) return y1 + ((x - x1) / (x2 - x1)) * (y2 - y1);
  }
  return last[1];
}

export function sma(values: number[], window: number): number {
  if (values.length < window) throw new Error(`sma: need ${window} values, got ${values.length}`);
  const slice = values.slice(-window);
  return slice.reduce((a, b) => a + b, 0) / window;
}

/** Percentile rank (0–100) of the last value within the series. */
export function percentileRank(series: number[], value: number): number {
  if (series.length === 0) throw new Error("percentileRank: empty series");
  const below = series.filter((v) => v < value).length;
  return (below / series.length) * 100;
}

export function regimeLabel(score: number): string {
  for (const r of REGIMES) if (score <= r.max) return r.label;
  return REGIMES[REGIMES.length - 1].label;
}

// ---------- indicator inputs/outputs ----------

export interface SeriesPoint { date: string; value: number }

export interface IndicatorResult {
  key: string;
  name: string;
  group: "valuation" | "trend";
  raw: number;
  unit: string;
  score: number;           // 0–100
  state: "bear" | "neutral" | "bull";
  detail: string;          // human line, e.g. distance to trigger
  asOf: string;            // ISO date of underlying data
  estimated: boolean;      // true when head value is our documented estimate
  sourceNote: string;
}

const state = (s: number): IndicatorResult["state"] => (s < 40 ? "bear" : s <= 60 ? "neutral" : "bull");
const r2 = (n: number) => Math.round(n * 100) / 100;

// ---------- the seven indicators ----------

/** 1. Price vs 200-week MA. prices = full daily close history (oldest→newest). */
export function score200wma(prices: number[], asOf: string): IndicatorResult {
  const wma = sma(prices, 1400); // 200 weeks × 7 days
  const price = prices[prices.length - 1];
  const ratio = price / wma;
  const score = curveScore(CURVES.wma200, ratio);
  return {
    key: "wma200", name: "200-Week Moving Average", group: "valuation",
    raw: r2(ratio), unit: "× 200WMA", score: r2(score), state: state(score),
    detail: `Price is ${r2((ratio - 1) * 100)}% ${ratio >= 1 ? "above" : "below"} the 200WMA ($${Math.round(wma).toLocaleString()})`,
    asOf, estimated: false, sourceNote: "Computed from blockchain.info daily price history",
  };
}

/** 2. MVRV Z-Score. Delayed series from BGeometrics + live-price head estimate. */
export function scoreMvrvZ(
  delayed: { z: number; date: string; price: number },
  livePrice: number,
  asOf: string,
): IndicatorResult {
  // Realized cap and the volatility denominator move slowly; over the ~7-day gap
  // the Z-score responds ≈ linearly to price. Sensitivity floor of 1 keeps the
  // adjustment sane near z=0. Documented estimate, labeled in the UI.
  const priceDelta = livePrice / delayed.price - 1;
  const z = delayed.z + priceDelta * Math.max(Math.abs(delayed.z), 1);
  const score = curveScore(CURVES.mvrvZ, z);
  return {
    key: "mvrvZ", name: "MVRV Z-Score", group: "valuation",
    raw: r2(z), unit: "z", score: r2(score), state: state(score),
    detail: `Z ${r2(z)} (delayed reading ${r2(delayed.z)} on ${delayed.date}, adjusted for live price)`,
    asOf, estimated: true, sourceNote: "BGeometrics free API (7-day delayed) + published live-price adjustment",
  };
}

/** 3. Puell Multiple, same delayed treatment (issuance value is stable over days). */
export function scorePuell(
  delayed: { puell: number; date: string; price: number },
  livePrice: number,
  asOf: string,
): IndicatorResult {
  const p = delayed.puell * (livePrice / delayed.price); // issuance USD scales with price; 365MA ~constant over 7d
  const score = curveScore(CURVES.puell, p);
  return {
    key: "puell", name: "Puell Multiple", group: "valuation",
    raw: r2(p), unit: "×", score: r2(score), state: state(score),
    detail: `Puell ${r2(p)} (delayed ${r2(delayed.puell)} on ${delayed.date}, price-adjusted)`,
    asOf, estimated: true, sourceNote: "BGeometrics free API (7-day delayed) + published live-price adjustment",
  };
}

/** 4. Golden cross: 50 vs 200 daily SMA. */
export function scoreGoldenCross(prices: number[], asOf: string): IndicatorResult {
  const s50 = sma(prices, 50);
  const s200 = sma(prices, 200);
  const spread = (s50 - s200) / s200;
  const score = curveScore(CURVES.goldenCross, spread);
  const cross = s50 >= s200 ? "Golden cross active" : "Death cross active";
  return {
    key: "goldenCross", name: "Golden Cross (50/200 SMA)", group: "trend",
    raw: r2(spread * 100), unit: "% spread", score: r2(score), state: state(score),
    detail: `${cross}: 50-day SMA is ${r2(Math.abs(spread) * 100)}% ${spread >= 0 ? "above" : "below"} the 200-day`,
    asOf, estimated: false, sourceNote: "Computed from blockchain.info daily price history",
  };
}

/** 5. Hash Ribbons: 30 vs 60 SMA of hash rate. */
export function scoreHashRibbons(hashrate: number[], asOf: string): IndicatorResult {
  const s30 = sma(hashrate, 30);
  const s60 = sma(hashrate, 60);
  const spread = (s30 - s60) / s60;
  const score = curveScore(CURVES.hashRibbons, spread);
  return {
    key: "hashRibbons", name: "Hash Ribbons (30/60 SMA)", group: "trend",
    raw: r2(spread * 100), unit: "% spread", score: r2(score), state: state(score),
    detail: `30-day hash-rate SMA is ${r2(Math.abs(spread) * 100)}% ${spread >= 0 ? "above" : "below"} the 60-day`,
    asOf, estimated: false, sourceNote: "Computed from blockchain.info hash-rate series",
  };
}

/** 6. Bitcoin dominance: level + 90-day trend, structure context. */
export function scoreDominance(domSeries: SeriesPoint[], asOf: string): IndicatorResult {
  if (domSeries.length < 1) throw new Error("dominance: no data");
  const cur = domSeries[domSeries.length - 1].value;
  // History accumulates one point per daily run; the trend window grows to 90 days.
  const days = Math.min(90, domSeries.length - 1);
  const back = domSeries[domSeries.length - 1 - days].value;
  const change = cur - back;
  const score = curveScore(CURVES.dominanceTrend, change);
  return {
    key: "dominance", name: "Bitcoin Dominance", group: "trend",
    raw: r2(cur), unit: "%", score: r2(score), state: state(score),
    detail: `${r2(cur)}% dominance, ${change >= 0 ? "+" : ""}${r2(change)} pts over ${days} day${days === 1 ? "" : "s"}${days < 90 ? " (history building)" : ""}`,
    asOf, estimated: false, sourceNote: "CoinGecko global market data (history accumulated by pipeline)",
  };
}

/** 7. Volume + sentiment blend. */
export function scoreVolumeSentiment(
  fearGreed: number,
  volumeSeries: number[],
  asOf: string,
): IndicatorResult {
  const v30 = sma(volumeSeries, Math.min(30, volumeSeries.length));
  const cur = volumeSeries[volumeSeries.length - 1];
  const volPct = percentileRank(volumeSeries.slice(-365), cur);
  const score = VOL_SENT.fearGreedWeight * fearGreed + VOL_SENT.volumeTrendWeight * volPct;
  return {
    key: "volSent", name: "Volume + Sentiment", group: "trend",
    raw: r2(fearGreed), unit: "F&G", score: r2(score), state: state(score),
    detail: `Fear & Greed ${Math.round(fearGreed)}, volume at ${Math.round(volPct)}th percentile of past year (30d avg $${Math.round(v30 / 1e9)}B)`,
    asOf, estimated: false, sourceNote: "alternative.me Fear & Greed + CoinGecko volume",
  };
}

// ---------- composite ----------

export interface Composite {
  score: number;
  regime: string;
  valuation: number;
  trend: number;
  confidence: "High" | "Medium" | "Low";
  disagreement: string | null;
  anchorsVersion: string;
}

export function composite(indicators: IndicatorResult[], nowIso: string): Composite {
  const val = indicators.filter((i) => i.group === "valuation");
  const tr = indicators.filter((i) => i.group === "trend");
  if (val.length === 0 || tr.length === 0) throw new Error("composite: missing a group");
  const mean = (xs: IndicatorResult[]) => xs.reduce((a, b) => a + b.score, 0) / xs.length;
  const valuation = mean(val);
  const trend = mean(tr);
  const score = COMPOSITE.valuation * valuation + COMPOSITE.trend * trend;

  const now = new Date(nowIso).getTime();
  const fresh = indicators.filter(
    (i) => now - new Date(i.asOf).getTime() <= FRESH_HOURS * 3600 * 1000,
  ).length;
  const confidence = fresh >= 7 ? "High" : fresh >= 5 ? "Medium" : "Low";

  const gap = Math.abs(valuation - trend);
  const disagreement =
    gap >= 25
      ? `Valuation says ${regimeLabel(valuation)} while Trend says ${regimeLabel(trend)}`
      : null;

  return {
    score: r2(score), regime: regimeLabel(score),
    valuation: r2(valuation), trend: r2(trend),
    confidence, disagreement, anchorsVersion: ANCHORS_VERSION,
  };
}
