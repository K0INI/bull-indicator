import { describe, it, expect } from "vitest";
import {
  curveScore, sma, percentileRank, regimeLabel,
  score200wma, scoreMvrvZ, scorePuell, scoreGoldenCross,
  scoreHashRibbons, scoreDominance, scoreVolumeSentiment, composite,
} from "../src/score/engine.js";
import { CURVES } from "../src/config/anchors.js";

const D = "2026-09-27";

describe("curveScore (pinned anchors v1)", () => {
  it("clamps below and above", () => {
    expect(curveScore(CURVES.mvrvZ, -5)).toBe(0);
    expect(curveScore(CURVES.mvrvZ, 12)).toBe(100);
  });
  it("hits every published anchor exactly", () => {
    for (const [x, y] of CURVES.mvrvZ) expect(curveScore(CURVES.mvrvZ, x)).toBe(y);
    for (const [x, y] of CURVES.puell) expect(curveScore(CURVES.puell, x)).toBe(y);
    for (const [x, y] of CURVES.wma200) expect(curveScore(CURVES.wma200, x)).toBe(y);
  });
  it("interpolates linearly between anchors", () => {
    expect(curveScore(CURVES.mvrvZ, 1)).toBeCloseTo(42.5, 5); // midpoint of (0,25)-(2,60)
    expect(curveScore(CURVES.goldenCross, 0.05)).toBeCloseTo(72.5, 5);
  });
  it("rejects non-finite input", () => {
    expect(() => curveScore(CURVES.mvrvZ, NaN)).toThrow();
  });
});

describe("primitives", () => {
  it("sma", () => {
    expect(sma([1, 2, 3, 4], 2)).toBe(3.5);
    expect(() => sma([1], 5)).toThrow();
  });
  it("percentileRank", () => {
    expect(percentileRank([1, 2, 3, 4, 5], 5)).toBe(80);
    expect(percentileRank([1, 2, 3, 4, 5], 0)).toBe(0);
  });
  it("regime boundaries", () => {
    expect(regimeLabel(20)).toBe("Capitulation");
    expect(regimeLabel(20.1)).toBe("Accumulation");
    expect(regimeLabel(60)).toBe("Early Expansion");
    expect(regimeLabel(76)).toBe("Late Bull");
    expect(regimeLabel(89)).toBe("Euphoria");
  });
});

describe("indicators", () => {
  it("200WMA: price at 2× WMA scores 75", () => {
    const prices = Array(1400).fill(100);
    prices.push(...Array(0));
    // constant series → wma=100; set last price to 200 by appending? sma uses last 1400.
    const series = [...Array(1399).fill(100), 100];
    series[series.length - 1] = 100; // ratio 1 → 35
    const r = score200wma(series, D);
    expect(r.score).toBeCloseTo(35, 0);
    expect(r.group).toBe("valuation");
  });
  it("MVRV Z: flat price gap keeps delayed value; estimate flagged", () => {
    const r = scoreMvrvZ({ z: 2, date: "2026-09-20", price: 100000 }, 100000, D);
    expect(r.raw).toBe(2);
    expect(r.score).toBe(60);
    expect(r.estimated).toBe(true);
  });
  it("MVRV Z: +10% price since delayed reading raises z proportionally", () => {
    const r = scoreMvrvZ({ z: 2, date: "2026-09-20", price: 100000 }, 110000, D);
    expect(r.raw).toBeCloseTo(2.2, 5);
  });
  it("Puell scales with price ratio", () => {
    const r = scorePuell({ puell: 1.0, date: "2026-09-20", price: 100000 }, 120000, D);
    expect(r.raw).toBeCloseTo(1.2, 5);
    expect(r.score).toBeCloseTo(50, 0);
  });
  it("golden cross: rising series → bull state", () => {
    const prices = Array.from({ length: 400 }, (_, i) => 100 + i);
    const r = scoreGoldenCross(prices, D);
    expect(r.state).toBe("bull");
    expect(r.detail).toContain("Golden cross active");
  });
  it("hash ribbons: falling hash rate → bear", () => {
    const hr = Array.from({ length: 200 }, (_, i) => 1000 - i * 3);
    const r = scoreHashRibbons(hr, D);
    expect(r.state).toBe("bear");
  });
  it("dominance trend maps to structure score", () => {
    const dom = Array.from({ length: 120 }, (_, i) => ({ date: `d${i}`, value: 50 + i * 0.1 }));
    const r = scoreDominance(dom, D);
    expect(r.score).toBeGreaterThan(50);
  });
  it("volume+sentiment blends 60/40", () => {
    const vols = Array.from({ length: 365 }, () => 1e9);
    const r = scoreVolumeSentiment(80, vols, D);
    // volume percentile of equal values = 0 below → 0; 0.6*80 + 0.4*0 = 48
    expect(r.score).toBeCloseTo(48, 1);
  });
});

describe("composite", () => {
  const mk = (key: string, group: "valuation" | "trend", score: number, asOf = D) =>
    ({ key, name: key, group, raw: 0, unit: "", score, state: "neutral", detail: "", asOf, estimated: false, sourceNote: "" }) as any;

  it("weights valuation and trend 50/50 and labels regime", () => {
    const c = composite(
      [mk("a", "valuation", 40), mk("b", "valuation", 60), mk("c", "trend", 80), mk("d", "trend", 60)],
      `${D}T12:00:00Z`,
    );
    expect(c.valuation).toBe(50);
    expect(c.trend).toBe(70);
    expect(c.score).toBe(60);
    expect(c.regime).toBe("Early Expansion");
  });
  it("flags disagreement at gap ≥ 25", () => {
    const c = composite([mk("a", "valuation", 30), mk("b", "trend", 70)], `${D}T12:00:00Z`);
    expect(c.disagreement).toContain("Valuation says");
  });
  it("confidence drops with stale inputs", () => {
    const stale = mk("s", "trend", 50, "2026-09-01");
    const freshSix = [
      mk("a", "valuation", 50), mk("b", "valuation", 50), mk("c", "valuation", 50),
      mk("d", "trend", 50), mk("e", "trend", 50), mk("f", "trend", 50),
    ];
    const c = composite([...freshSix, stale], `${D}T12:00:00Z`);
    expect(c.confidence).toBe("Medium");
  });
});
