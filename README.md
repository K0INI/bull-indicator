# KŌINI Bull Indicator

Read the cycle. Bitcoin market-cycle indicators in one glance. Informational only — no wallet, no trading, no advice.

- `pipeline/` — TypeScript data refresh: fetches public sources, computes 7 indicators + composite Cycle Score, emits static JSON (runs daily via GitHub Actions, published on GitHub Pages).
- `app/` — Flutter app (iOS + Android). Platform folders are generated in CI (`flutter create` + `tools/patch-platforms.sh`).
- `site/` — privacy / terms / support pages (GitHub Pages).
- `store/` — store listing copy and compliance answers.
- `docs/` — spec, build plan.

**Disclaimer:** Not financial advice. Historical indicators can fail. Past cycles do not guarantee future results.
