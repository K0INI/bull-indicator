/**
 * Fetchers — one function per external source. Every function validates shape
 * and throws on anything unexpected: the pipeline NEVER emits guessed numbers.
 * Runtime is GitHub Actions (unrestricted egress).
 */

const UA = { "User-Agent": "KOINI-Bull-Indicator/1.0 (informational app; contact support@koini.io)" };

async function getJson(url: string, tries = 3): Promise<any> {
  let lastErr: unknown;
  for (let i = 0; i < tries; i++) {
    try {
      const res = await fetch(url, { headers: { accept: "application/json", ...UA } });
      if (res.status === 429) {
        await new Promise((r) => setTimeout(r, 15000 * (i + 1)));
        continue;
      }
      if (!res.ok) throw new Error(`${url} → HTTP ${res.status}`);
      return await res.json();
    } catch (e) {
      lastErr = e;
      await new Promise((r) => setTimeout(r, 3000 * (i + 1)));
    }
  }
  throw new Error(`fetch failed after ${tries} tries: ${url} (${String(lastErr)})`);
}

const num = (v: unknown, ctx: string): number => {
  const n = typeof v === "string" ? parseFloat(v) : (v as number);
  if (!Number.isFinite(n)) throw new Error(`invalid number for ${ctx}: ${v}`);
  return n;
};

export interface ChartSeries { dates: string[]; values: number[] }

/** blockchain.info charts API → daily series. chart: market-price | hash-rate */
export async function fetchChart(chart: string, timespan = "all"): Promise<ChartSeries> {
  const j = await getJson(
    `https://api.blockchain.info/charts/${chart}?timespan=${timespan}&format=json&sampled=false`,
  );
  if (j.status !== "ok" || !Array.isArray(j.values) || j.values.length < 100)
    throw new Error(`blockchain.info ${chart}: bad payload`);
  const dates: string[] = [];
  const values: number[] = [];
  for (const p of j.values) {
    dates.push(new Date(num(p.x, "ts") * 1000).toISOString().slice(0, 10));
    values.push(num(p.y, chart));
  }
  return { dates, values };
}

/** BGeometrics free API — delayed ~7 days on free tier. */
export async function fetchBgeometrics(metric: "mvrv-zscore" | "puell-multiple"): Promise<{
  value: number; date: string;
}> {
  const j = await getJson(`https://bitcoin-data.com/v1/${metric}/last`);
  const key = metric === "mvrv-zscore" ? "mvrvZscore" : "puellMultiple";
  const value = num(j[key] ?? j.value, metric);
  const date = String(j.d ?? j.date ?? "");
  if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) throw new Error(`bgeometrics ${metric}: bad date ${date}`);
  return { value, date };
}

/** CoinGecko: live BTC price + 24h volume + dominance. Free public API. */
export async function fetchCoinGecko(): Promise<{
  price: number; volume24h: number; dominance: number;
}> {
  const g = await getJson("https://api.coingecko.com/api/v3/global");
  const dominance = num(g?.data?.market_cap_percentage?.btc, "dominance");
  const s = await getJson(
    "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd&include_24hr_vol=true",
  );
  return {
    price: num(s?.bitcoin?.usd, "price"),
    volume24h: num(s?.bitcoin?.usd_24h_vol, "volume"),
    dominance,
  };
}

/** alternative.me Fear & Greed (0–100). */
export async function fetchFearGreed(): Promise<{ value: number; history: { date: string; value: number }[] }> {
  const j = await getJson("https://api.alternative.me/fng/?limit=400");
  if (!Array.isArray(j.data) || j.data.length === 0) throw new Error("fng: bad payload");
  const history = j.data
    .map((d: any) => ({
      date: new Date(num(d.timestamp, "fng ts") * 1000).toISOString().slice(0, 10),
      value: num(d.value, "fng"),
    }))
    .reverse();
  return { value: history[history.length - 1].value, history };
}

/** Price on a specific past date from a full daily series (for delayed-data adjustment). */
export function priceOnDate(series: ChartSeries, date: string): number {
  const idx = series.dates.lastIndexOf(date);
  if (idx >= 0) return series.values[idx];
  // fall back to nearest earlier date within 5 days
  for (let back = 1; back <= 5; back++) {
    const d = new Date(date + "T00:00:00Z");
    d.setUTCDate(d.getUTCDate() - back);
    const i = series.dates.lastIndexOf(d.toISOString().slice(0, 10));
    if (i >= 0) return series.values[i];
  }
  throw new Error(`no price found near ${date}`);
}
