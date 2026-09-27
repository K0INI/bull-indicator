# KŌINI Bull Indicator — Store Listings & Compliance Kit

## Identity
- Store name: **KŌINI Bull Indicator** (20 chars) · Home-screen label: **Bull Indicator**
- Tagline: **Read the cycle.**
- Android package / iOS bundle ID: **com.koini.bullindicator**
- Category: Finance (informational). Age rating: Everyone / 4+.
- Support: support@koini.io · Privacy/Terms/Support URLs: on the app's GitHub Pages site.
- Price: Free. No ads. No in-app purchases. No accounts.

## Apple App Store

**Subtitle (30 chars):** `Bitcoin cycle indicators`

**Promotional text:** Seven classic Bitcoin market-cycle indicators, one transparent score. Educational context — never trading advice.

**Description:**
Read the cycle. KŌINI Bull Indicator combines seven widely followed indicators into one clear, transparent picture — so you don't have to check ten websites.

ONE SCORE, FULLY EXPLAINED
• Cycle Score (0–100) with six regimes, from Capitulation to Euphoria
• Split Valuation vs Trend views showing when they disagree
• Confidence badge based on data freshness
• Every formula published on the Methodology page — no black box

SEVEN INDICATORS
• 200-Week Moving Average
• MVRV Z-Score
• Puell Multiple
• Golden Cross (50/200 SMA)
• Hash Ribbons
• Bitcoin Dominance
• Volume + Fear & Greed sentiment

LEARN AS YOU GO
Every indicator has a plain-English page: what it is, why it matters, how to read it, and — importantly — when it has failed historically.

TIMELINE VIEW
See each indicator's bull/bear state as colored strips under the Bitcoin price across 1Y, 4Y, or all history.

HONEST BY DESIGN
KŌINI Bull Indicator is educational market context only. It holds no funds, executes no trades, and never tells you to buy or sell. Not financial advice. Historical indicators can fail. Past cycles do not guarantee future results.

**Keywords (100 chars):** `bitcoin,cycle,bull,indicator,mvrv,halving,bear,onchain,dominance,fear greed,btc,koini`

**App Privacy (nutrition label):** Data Not Collected — the app collects no data of any type. (No accounts, no analytics, no identifiers, no tracking.)

**Review notes:** KŌINI Bull Indicator is a read-only informational/educational reference. It has no wallet, exchange, trading, custody, or payment functionality of any kind, and no user accounts. All market data is public. Every scoring screen carries a persistent "not financial advice" disclaimer, and indicator pages document historical failure modes. Data sources are attributed in Settings → Data sources.

## Google Play

**Short description (80 chars):** `Bitcoin market-cycle indicators with one transparent score. Educational only.`

**Full description:** (same as Apple description above)

**Data safety form answers:**
- Does your app collect or share any of the required user data types? **No**
- Is all of the user data collected by your app encrypted in transit? N/A (nothing collected; app uses HTTPS)
- Do you provide a way for users to request deletion? N/A (nothing collected)

**App content declarations:**
- Financial features: **None of the above** (no trading, no personal loans, no crypto exchange/wallet — informational content only)
- Ads: No · Target audience: 18+ recommended (finance content) or Everyone; select "News/educational content about cryptocurrency, no transactions"
- Government app: No · COVID: No

**Play review notes:** Informational/educational reference only. No wallet, exchange, trading, or custody features. No accounts. Persistent not-financial-advice disclaimer on every scoring screen.

## Screenshot plan (both stores)
1. Home — gauge at a mid score with regime label + "One transparent Cycle Score" caption
2. Board — seven indicator rows + "Seven classic indicators, one place"
3. Detail (MVRV) — education sections + "Learn what each signal really means"
4. Timeline — strips view + "See every cycle at a glance"
5. Methodology — formula page + "No black box — every formula published"
Device sizes: iPhone 6.7" + 6.1", iPad 12.9" (optional), Android phone + 7" tablet. Noir canvas per brand guidelines (Jost type, Bull Green accent, cycle palette), real data. Lockup: supplied KŌINI Bull Indicator artwork, never redrawn.

## Rollout
1. Push repo → CI green (tests, AAB, unsigned IPA).
2. Play Console: create app → upload AAB to **Internal testing** → promote to Production (new personal accounts must first run a 14-day/12-tester closed test; org accounts skip this).
3. App Store Connect: create app → CI uploads build via TestFlight → submit for review.
4. Monitor reviews; respond to any reviewer questions with the notes above.
