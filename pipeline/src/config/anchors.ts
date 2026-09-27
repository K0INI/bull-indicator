/**
 * Scoring anchors v1 — the published, versioned mapping from raw indicator
 * values to 0–100 scores (0 = deep bear, 100 = euphoric bull).
 * Any change here bumps ANCHORS_VERSION and must update unit tests + METHODOLOGY.md.
 */
export const ANCHORS_VERSION = "1.0.0";

/** Piecewise-linear map: sorted [rawValue, score] points, clamped at ends. */
export type Curve = ReadonlyArray<readonly [number, number]>;

export const CURVES = {
  /** price / 200WMA ratio */
  wma200: [
    [0.85, 0],
    [1.0, 35],
    [2.0, 75],
    [3.0, 100],
  ] as Curve,

  /** MVRV Z-Score */
  mvrvZ: [
    [-0.5, 0],
    [0, 25],
    [2, 60],
    [5, 85],
    [7, 100],
  ] as Curve,

  /** Puell Multiple */
  puell: [
    [0.3, 0],
    [0.5, 20],
    [1.0, 45],
    [2.0, 70],
    [4.0, 90],
    [6.0, 100],
  ] as Curve,

  /** (50SMA − 200SMA) / 200SMA, as a fraction (−0.10 → −10%) */
  goldenCross: [
    [-0.10, 5],
    [0, 50],
    [0.10, 95],
  ] as Curve,

  /** (30SMA − 60SMA) / 60SMA of hash rate, as a fraction */
  hashRibbons: [
    [-0.10, 5],
    [0, 50],
    [0.10, 95],
  ] as Curve,

  /** 90-day dominance change in percentage points, structure context */
  dominanceTrend: [
    [-8, 15],
    [0, 50],
    [8, 85],
  ] as Curve,
} as const;

/** Volume+sentiment blend weights */
export const VOL_SENT = { fearGreedWeight: 0.6, volumeTrendWeight: 0.4 } as const;

/** Composite weights */
export const COMPOSITE = { valuation: 0.5, trend: 0.5 } as const;

export const REGIMES = [
  { max: 20, label: "Capitulation" },
  { max: 40, label: "Accumulation" },
  { max: 60, label: "Early Expansion" },
  { max: 75, label: "Mid Bull" },
  { max: 88, label: "Late Bull" },
  { max: 100, label: "Euphoria" },
] as const;

/** Freshness: an input older than this many hours is stale for confidence purposes. */
export const FRESH_HOURS = 48;
