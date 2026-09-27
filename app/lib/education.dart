/// Plain-English education content for each indicator.
/// Sections: what, why, how to read, history & failure modes.
library;

class Education {
  final String what;
  final String why;
  final String howToRead;
  final String history;
  const Education({
    required this.what,
    required this.why,
    required this.howToRead,
    required this.history,
  });
}

const Map<String, Education> education = {
  'wma200': Education(
    what:
        'The 200-week moving average is the average Bitcoin closing price over the past 200 weeks — roughly one full four-year cycle. It smooths out all short-term noise into one slow-moving line.',
    why:
        'Historically it has acted as the floor of Bitcoin bear markets. Price touching or dipping below the 200WMA has marked major cycle bottoms (2015, 2018, 2022), while price stretching to multiples of it has marked overheated tops.',
    howToRead:
        'Look at the ratio of price to the 200WMA. Near 1.0× the market is at historical floor territory. Around 2× is a healthy bull. Above 3× the market has historically been near euphoric tops.',
    history:
        'Failure modes: the floor is not guaranteed — in 2015 and 2022 price traded below the 200WMA for weeks. As Bitcoin matures, the multiples reached at tops have been shrinking, so old top thresholds may be too high for the ETF era.',
  ),
  'mvrvZ': Education(
    what:
        'MVRV compares Bitcoin\'s market value (price × supply) to its realized value — the price at which each coin last moved on-chain, which approximates the market\'s aggregate cost basis. The Z-Score normalizes this gap by its historical volatility.',
    why:
        'It measures how far price is stretched above or below what holders actually paid. Extreme highs mean large unrealized profit (historically distribution zones); extreme lows mean widespread unrealized loss (historically accumulation zones).',
    howToRead:
        'Below 0 has marked deep-value bottoms. Around 2 is a mid-cycle level. Historically, readings above roughly 5–7 flagged cycle tops within weeks. In this app the free data source lags about a week, so today\'s value is estimated from the delayed reading plus live price — the method is published on the Methodology page.',
    history:
        'Failure modes: top thresholds have declined every cycle (2021\'s second peak topped near Z≈4, below the classic 7). Exchange-held and ETF-held coins blur realized value. Treat zones, not exact numbers, as the signal.',
  ),
  'puell': Education(
    what:
        'The Puell Multiple divides the daily USD value of newly issued bitcoin (miner block rewards) by the 365-day average of that value.',
    why:
        'It views cycles through miner revenue. When miners earn far more than the yearly norm, markets have historically been near tops; when they earn far less, near bottoms (miner capitulation).',
    howToRead:
        'Below about 0.5 has marked bottom zones. Around 1.0 is neutral. Above roughly 4 has marked overheated tops. Halvings mechanically cut issuance in half, which shifts the multiple — compare within an era, not across halvings blindly.',
    history:
        'Failure modes: each halving changes the baseline, and fee revenue (not counted in classic Puell) matters more over time. Post-2024-halving readings run structurally lower than older cycles.',
  ),
  'goldenCross': Education(
    what:
        'The golden cross is the moment the 50-day moving average crosses above the 200-day moving average. The opposite is a death cross.',
    why:
        'It is the classic, simple trend-confirmation signal: it says the intermediate trend has turned up (or down) with enough persistence to move long averages.',
    howToRead:
        'We show the percentage spread between the two averages. Positive and widening = confirmed uptrend. Negative and widening = confirmed downtrend. Crosses near zero can whipsaw.',
    history:
        'Failure modes: it is a lagging signal — crosses fire well after turns — and choppy markets produce false crosses (e.g., mid-2021). Use it for confirmation, not prediction.',
  ),
  'hashRibbons': Education(
    what:
        'Hash Ribbons compare the 30-day and 60-day moving averages of Bitcoin\'s network hash rate — the total computing power miners point at the chain.',
    why:
        'Miners are forced sellers with real-world costs. When hash rate contracts, weak miners are capitulating — historically near bottoms. When the 30-day average recovers above the 60-day, the worst has typically passed.',
    howToRead:
        'Ribbon spread below zero = miner stress. The classic "buy signal" in the original study fires when the 30d recrosses above the 60d after a capitulation; we flag that recovery moment on the chart.',
    history:
        'Failure modes: hash rate migrations (China 2021 mining ban) produced capitulation signals unrelated to price cycles. Hardware cycles and energy prices also move hash rate independently of the market.',
  ),
  'dominance': Education(
    what:
        'Bitcoin dominance is Bitcoin\'s share of total cryptocurrency market capitalization.',
    why:
        'Cycles have a rotation rhythm: capital concentrates in Bitcoin early (dominance rises), then spills into altcoins as risk appetite peaks (dominance falls). Late-cycle dominance collapse has coincided with market tops.',
    howToRead:
        'We score the 90-day trend. Rising dominance usually marks early/mid cycle; falling dominance with an overheated market suggests late-cycle alt euphoria. Dominance is structure context, not a standalone signal.',
    history:
        'Failure modes: stablecoins and new token supply distort the denominator over the years, so absolute levels are not comparable across eras — the trend matters more than the level.',
  ),
  'volSent': Education(
    what:
        'A blend of the Crypto Fear & Greed Index (60%) and where current trading volume sits versus the past year (40%).',
    why:
        'Sentiment and participation confirm or contradict price. Sustained greed with expanding volume is classic bull behavior; greed on thin volume is fragile; extreme fear has historically marked opportunity zones.',
    howToRead:
        'The Fear & Greed component is already 0–100 (extreme fear → extreme greed). The volume component is a percentile: 90 means today\'s volume is higher than 90% of days in the past year.',
    history:
        'Failure modes: sentiment can stay at extremes far longer than expected — "extreme greed" persisted for months in early 2021 and early 2024. Volume data quality varies across exchanges.',
  ),
};

const methodologyText = '''
KŌINI Bull Indicator computes one Cycle Score (0–100) from seven published indicators.

Each indicator maps its raw value to a 0–100 score through fixed, published anchor points (piecewise-linear). The anchors are versioned; this build uses anchors v1.0.0, listed on each indicator page.

Grouping: Valuation = 200WMA, MVRV Z-Score, Puell Multiple. Trend = Golden Cross, Hash Ribbons, Dominance, Volume + Sentiment.

Cycle Score = 50% × average(Valuation scores) + 50% × average(Trend scores).

Regimes: 0–20 Capitulation (deep value) · 21–40 Accumulation · 41–60 Early Expansion · 61–75 Mid Bull · 76–88 Late Bull (elevated risk) · 89–100 Euphoria (historically dangerous).

Confidence reflects data freshness: High = all seven inputs ≤48h old; Medium = 5–6; Low = fewer. A disagreement note appears when the Valuation and Trend group scores differ by 25+ points.

Delayed data: our MVRV Z-Score and Puell Multiple source (BGeometrics free tier) lags about 7 days. Because realized value and yearly issuance averages move slowly, we adjust the delayed reading with the live price (MVRV Z: z + Δprice% × max(|z|,1); Puell: value × price ratio) and label these values "estimated". If any source fails, the app shows the last good data with a stale banner — it never invents numbers.

Data: BGeometrics (bitcoin-data.com), blockchain.info, CoinGecko, alternative.me. Scores update daily around 06:00 UTC.

Not financial advice. Historical indicators can fail. Past cycles do not guarantee future results.
''';
