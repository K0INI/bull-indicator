/**
 * Bull Indicator daily refresh. Fetch → score → emit static JSON for the app.
 * Fails loudly on any bad input; never writes partial/guessed data.
 */
import { mkdirSync, writeFileSync, readFileSync, existsSync } from "node:fs";
import { join } from "node:path";
import {
  fetchChart, fetchBgeometrics, fetchCoinGecko, fetchFearGreed, priceOnDate,
  type ChartSeries,
} from "./fetch/sources.js";
import {
  score200wma, scoreMvrvZ, scorePuell, scoreGoldenCross, scoreHashRibbons,
  scoreDominance, scoreVolumeSentiment, composite, sma,
  type IndicatorResult, type SeriesPoint,
} from "./score/engine.js";

const OUT = process.env.OUT_DIR ?? join(process.cwd(), "..", "data");
const nowIso = new Date().toISOString();
const today = nowIso.slice(0, 10);

function loadState<T>(file: string, fallback: T): T {
  const p = join(OUT, file);
  if (!existsSync(p)) return fallback;
  return JSON.parse(readFileSync(p, "utf8")) as T;
}

async function main() {
  console.log("Bull Indicator refresh", nowIso);

  // ---- fetch (parallel) ----
  const [price, hash, mvrvD, puellD, gecko, fng] = await Promise.all([
    fetchChart("market-price", "all"),
    fetchChart("hash-rate", "3years"),
    fetchBgeometrics("mvrv-zscore"),
    fetchBgeometrics("puell-multiple"),
    fetchCoinGecko(),
    fetchFearGreed(),
  ]);
  console.log(
    `sources ok: price ${price.values.length}d, hash ${hash.values.length}d, ` +
    `mvrvZ ${mvrvD.value}@${mvrvD.date}, puell ${puellD.value}@${puellD.date}, ` +
    `live $${gecko.price}, dom ${gecko.dominance}%, F&G ${fng.value}`,
  );

  // append live price so SMAs include today
  const prices = [...price.values];
  if (price.dates[price.dates.length - 1] !== today) prices.push(gecko.price);
  else prices[prices.length - 1] = gecko.price;

  // ---- accumulated state (dominance + volume dailies) ----
  type Hist = { dominance: SeriesPoint[]; volume: SeriesPoint[] };
  const hist = loadState<Hist>("state.json", { dominance: [], volume: [] });
  const push = (arr: SeriesPoint[], value: number) => {
    if (arr.length && arr[arr.length - 1].date === today) arr[arr.length - 1].value = value;
    else arr.push({ date: today, value });
    while (arr.length > 1500) arr.shift();
  };
  push(hist.dominance, gecko.dominance);
  push(hist.volume, gecko.volume24h);
  // seed volume history from blockchain.info on first runs so percentile is meaningful
  if (hist.volume.length < 90) {
    const tv = await fetchChart("trade-volume", "1year");
    hist.volume = tv.dates.map((d, i) => ({ date: d, value: tv.values[i] }));
    push(hist.volume, gecko.volume24h);
  }

  // ---- score ----
  const indicators: IndicatorResult[] = [
    score200wma(prices, today),
    scoreMvrvZ({ z: mvrvD.value, date: mvrvD.date, price: priceOnDate(price, mvrvD.date) }, gecko.price, today),
    scorePuell({ puell: puellD.value, date: puellD.date, price: priceOnDate(price, puellD.date) }, gecko.price, today),
    scoreGoldenCross(prices, today),
    scoreHashRibbons(hash.values, today),
    scoreDominance(hist.dominance, today),
    scoreVolumeSentiment(fng.value, hist.volume.map((p) => p.value), today),
  ];
  const comp = composite(indicators, nowIso);
  console.log(`Cycle Score ${comp.score} — ${comp.regime} (V ${comp.valuation} / T ${comp.trend}, ${comp.confidence})`);

  // ---- history of composite + per-indicator scores ----
  type HistoryRow = { date: string; score: number; valuation: number; trend: number; [k: string]: number | string };
  const history = loadState<HistoryRow[]>("history.json", []);
  const row: HistoryRow = { date: today, score: comp.score, valuation: comp.valuation, trend: comp.trend };
  for (const i of indicators) row[i.key] = i.score;
  const last = history[history.length - 1];
  if (last && last.date === today) history[history.length - 1] = row;
  else history.push(row);

  // sparkline series for the app (weekly price for 4y, daily for 1y)
  const priceSeries = price.dates.map((d, i) => ({ date: d, value: price.values[i] }));
  const charts = {
    price1y: priceSeries.slice(-365),
    price4y: priceSeries.slice(-1461).filter((_, i) => i % 7 === 0),
    hashRibbon: hash.dates.slice(-365).map((d, i) => {
      const idx = hash.values.length - 365 + i;
      return idx >= 60
        ? { date: d, s30: sma(hash.values.slice(0, idx + 1), 30), s60: sma(hash.values.slice(0, idx + 1), 60) }
        : null;
    }).filter(Boolean),
    fearGreed: fng.history.slice(-365),
  };

  // ---- emit ----
  const latest = {
    generatedAt: nowIso,
    disclaimer: "Not financial advice. Historical indicators can fail. Past cycles do not guarantee future results.",
    composite: comp,
    indicators,
    deltas: {
      d1: history.length >= 2 ? comp.score - history[history.length - 2].score : null,
      d7: history.length >= 8 ? comp.score - history[history.length - 8].score : null,
    },
    attribution: [
      "MVRV Z-Score & Puell Multiple: BGeometrics (bitcoin-data.com), delayed free data with published live-price adjustment",
      "Price & hash rate: blockchain.info public charts API",
      "Dominance & volume: CoinGecko public API",
      "Fear & Greed Index: alternative.me",
    ],
  };

  mkdirSync(OUT, { recursive: true });
  writeFileSync(join(OUT, "latest.json"), JSON.stringify(latest, null, 1));
  writeFileSync(join(OUT, "history.json"), JSON.stringify(history));
  writeFileSync(join(OUT, "state.json"), JSON.stringify(hist));
  writeFileSync(join(OUT, "charts.json"), JSON.stringify(charts));
  console.log(`wrote ${OUT}/latest.json, history.json (${history.length} rows), charts.json`);
}

main().catch((e) => {
  console.error("REFRESH FAILED — no data emitted:", e);
  process.exit(1);
});
