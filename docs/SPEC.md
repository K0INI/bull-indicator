# KŌINI Bull Indicator — Product Specification v1.0

**Date:** 2026-09-27 · **Owner:** Deltoshi · **Status:** Approved for build

**Name:** KŌINI Bull Indicator (formerly working title "CyclePulse") · **Tagline:** Read the cycle. · **Brand:** KOINI_Bull_Indicator_Brand_Guidelines.pdf (Edition 01 · 2026) — Noir/Panel canvas, Bull Green #3ECF8E / Bear Coral #F0506E, six-hue cycle palette, Jost + JetBrains Mono, horned-ring mark.

---

## 1. Pitch

KŌINI Bull Indicator answers one question in ten seconds: **where are we in the Bitcoin market cycle?** It combines seven battle-tested cycle indicators — the ones a serious observer currently checks across a dozen websites — into a single app with one clear verdict, a per-indicator scoreboard, and plain-English education for every metric. It is strictly informational: no wallet, no trading, no buy/sell signals. Free to use, built on free public data. The product also includes a public web dashboard at `bull.koini.io` (subdomain TBD; default GitHub Pages URL until then) so anyone can see the current score without installing the app. The native app remains the primary product; the web dashboard is the shareable surface for brand reach.

## 2. The seven indicators

| # | Indicator | Group | Bull signal | Source |
|---|-----------|-------|-------------|--------|
| 1 | 200-week moving average | Valuation | Price well above 200WMA | Computed from price history (blockchain.info) |
| 2 | MVRV Z-Score | Valuation | Low = undervalued, high = cycle top zone | BGeometrics free API (7-day delayed) + live-price head estimate |
| 3 | Puell Multiple | Valuation | <0.5 bottom zone, >4 top zone | BGeometrics free API (same treatment) |
| 4 | Golden cross (50/200 daily SMA) | Trend | 50 SMA above 200 SMA | Computed from price history |
| 5 | Hash Ribbons (30/60 SMA of hash rate) | Trend | 30 SMA above 60 SMA after capitulation | Computed from hash rate (blockchain.info) |
| 6 | Bitcoin dominance | Trend/structure | Rising early cycle; falling late cycle (alt rotation) | CoinGecko global endpoint |
| 7 | Volume + sentiment | Trend/sentiment | Volume expansion + Fear & Greed regime | CoinGecko volume + alternative.me F&G |

Stock-to-Flow and Rainbow Chart are deliberately excluded (folklore).

## 3. User stories

- As a holder, I open the app and in one glance see whether conditions look like accumulation, bull, distribution, or bear — and how confident that read is.
- As a learner, I tap any indicator and get a plain-English explanation: what it measures, why it matters, how to read it, and when it has failed historically.
- As a returning user, I see what changed since yesterday / last week (score deltas, indicator flips).
- As a skeptic, I can open the methodology page and see exactly how every score is computed — no black box.
- As a chart reader, I can view a timeline of price with each indicator's bull/bear state as colored strips underneath, over 1Y / 4Y / max.
- As a Twitter/Discord user, I click a shared link and instantly see the current Cycle Score, regime, and indicator board — no install required.

## 4. Information architecture & screens

**Tab 1 — Home (Verdict).** Brand dashboard layout: large Cycle Score numeral, regime in its band colour, 24h delta, six-band cycle bar, Valuation and Trend group scores, and a tile per indicator coloured by regime band. Data-freshness line. Persistent disclaimer footer.

**Tab 2 — Board.** One row per indicator: name, current value, state (bull/neutral/bear color), score 0–100, distance to next trigger ("50 SMA is 3.2% below 200 SMA"), sparkline. Tap → detail.

**Indicator detail (pushed from Board/Home).** Chart (value + trigger bands), current reading, score, then education sections: What it is · Why it matters · How to read it · Historical record & failure modes · Source & method (incl. the delayed-data estimate where used).

**Tab 3 — Timeline.** BTC price (log) on top; below, one horizontal strip per indicator colored bear→bull across the same time axis; composite strip at bottom. Ranges 1Y / 4Y / Max.

**Tab 4 — Settings & About.** Refresh, theme, notifications (indicator flips — informational wording), methodology page, data-source attributions, privacy policy, terms, disclaimer, support contact.

**Web Dashboard (bull.koini.io).** Single-page static site reading `latest.json` from the same GitHub Pages data feed. Shows: Cycle Score numeral + regime band color, 24h delta, Valuation vs Trend group scores, 7-indicator board (name, state color, score), confidence badge, disagreement callout, data-freshness timestamp, disclaimer footer, and a prominent "Get the full app" link to App Store + Play Store. Responsive (mobile-first). Styled to brand guidelines (Noir canvas, Bull Green / Bear Coral, Jost + JetBrains Mono, horned-ring mark). No accounts, no tracking, no cookies. Auto-updates on page load by fetching the JSON — no build step needed when data refreshes.

Every remote-data view has loading, offline (last-cached shown with stale banner), and error states.

## 5. Scoring methodology v1

Each indicator maps its raw value to a 0–100 score (0 = deep bear, 100 = euphoric bull) with fixed, published anchors:

1. **200WMA:** score from price/200WMA ratio; 1.0 → 35, historic bottoms ~0.85 → 0, 2.0 → 75, ≥3.0 → 100 (piecewise linear).
2. **MVRV Z:** −0.5 → 0, 0 → 25, 2 → 60, 5 → 85, 7 → 100.
3. **Puell:** 0.3 → 0, 0.5 → 20, 1.0 → 45, 2.0 → 70, 4.0 → 90, 6 → 100.
4. **Golden cross:** logistic on (50SMA−200SMA)/200SMA: −10% → 5, 0 → 50, +10% → 95; capped 0–100.
5. **Hash Ribbons:** ribbon spread (30/60 SMA of hash rate) mapped like #4, with recovery-after-capitulation bonus zone flagged in UI (not score).
6. **Dominance:** scored on 90-day dominance trend + absolute level (published table); labeled "structure context."
7. **Volume+Sentiment:** 60% Fear & Greed value (already 0–100), 40% 30-day volume trend percentile.

**Composite:** Valuation = mean(1,2,3); Trend = mean(4,5,6,7). Cycle Score = 0.5·Valuation + 0.5·Trend.
**Regimes (brand cycle palette):** 0–20 Capitulation (blue) · 21–40 Accumulation (cyan) · 41–60 Early Expansion (green) · 61–75 Mid Bull (yellow) · 76–88 Late Bull (orange) · 89–100 Euphoria (red).
**Confidence:** High = all 7 fresh (≤48h; delayed-source estimates count as fresh when live price is fresh); Medium = 5–6; Low = ≤4. Disagreement callout when |Valuation − Trend| ≥ 25.
**Delayed-data estimate:** BGeometrics free data lags 7 days. Realized price moves slowly, so we derive realized cap from the delayed series and combine with live price to estimate today's MVRV Z (same for Puell via issuance). The estimate is labeled "estimated (method published)" in the UI. All anchors live in one versioned config file; unit tests pin them.

## 6. Compliance memo

Educational reference app. No custody, no trading, no execution, no "buy/sell" language anywhere (UI, notifications, store listing). Every score screen carries: *"Not financial advice. Historical indicators can fail. Past cycles do not guarantee future results."* Notifications state facts ("Golden cross formed"), never instructions. Free app, no accounts, no ads, no tracking — privacy labels are the near-empty case. Attribution page credits BGeometrics, blockchain.info, CoinGecko, alternative.me. App Store category: Finance (informational) or News/Reference; Play: Finance with "no financial products offered" declarations. Age rating: 4+/Everyone with the "infrequent financial info" flag where asked.

## 7. Risks & non-goals

**Risks:** (a) a free source changes terms or format → repository layer isolates each source; pipeline alerts on fetch failure and app shows stale banner, never fake numbers. (b) Store reviewer mistakes it for a trading app → review notes + disclaimers everywhere. (c) BGeometrics free delay grows → paid add-on ($20/mo) is the instant fallback, already confirmed by their team. (d) Web dashboard used as argument by store reviewers that the app is just a website wrapper → web dashboard is intentionally minimal (score + board only); native app has push notifications, full charts, timeline view, indicator deep-dive pages, offline caching — features that justify native.

**Non-goals v1:** portfolio tracking, wallet connect, price predictions, paid signals, social features, accounts, altcoin pages, full-featured web app (the web dashboard is a score card, not a replica of the app).
