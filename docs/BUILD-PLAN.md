# KŌINI Bull Indicator — Build & Release Plan v1.0

**Guiding rule:** Claude executes everything; Deltoshi acts only where technically unavoidable (logins, payments, store approvals). Those steps are batched and pre-filled.

## Architecture (zero-cost)

```
GitHub Actions (daily cron, 06:00 UTC)
  └─ /pipeline (TypeScript): fetch sources → compute 7 indicators + composite
       → validate (no fake numbers; fail loud) → write data/latest.json + data/history.json
       → commit history to main → deploy site + data via GitHub Pages (free CDN)
Flutter app (iOS + Android)
  └─ fetches the static JSON (one URL, cached, ETag)
  └─ live overlays fetched on-device: price (CoinGecko), Fear & Greed (alternative.me)
  └─ local notifications on indicator flips (no push server)
Web dashboard (bull.koini.io)
  └─ site/dashboard/index.html: static HTML/CSS/JS, reads data/latest.json
  └─ hosted on same GitHub Pages as data + legal pages
  └─ auto-updates on every data pipeline run (no separate deploy)
```

No servers, no databases, no secrets in the client, no accounts. Monthly cost: **$0** (developer accounts already paid).

## Monorepo layout

```
bull-indicator/
  pipeline/        TypeScript: fetchers (one module per source), score engine, JSON emitter, tests
  app/             Flutter: lib/{models,data,logic,ui}, unit + widget tests
  docs/            SPEC.md, BUILD-PLAN.md, METHODOLOGY.md
  site/            privacy.html, terms.html, support.html, dashboard/index.html (GitHub Pages)
  .github/workflows/  data-refresh.yml, app-build.yml
  store/           listing copy, review notes, screenshot plan, data-safety answers
```

## Milestones

- **M1 — Pipeline & score engine** (build now): fetchers with retries + schema validation, score math with pinned unit tests, JSON artifacts, CI cron. Exit: green run producing real numbers.
- **M2 — Flutter app** (build now): all four tabs + detail pages, offline/error states, disclaimers, tests, app icons, Android release config, iOS project config. Exit: `flutter analyze` + tests green; Android AAB builds in CI.
- **M2.5 — Web dashboard** (build now): single `index.html` in `site/dashboard/`, brand-styled, reads `latest.json`, shows score + regime + board + app store links + disclaimer. Mobile-responsive. No JS framework — vanilla HTML/CSS/JS only. Exit: page loads on GitHub Pages and displays real data from the pipeline.
- **M3 — Release kit** (build now): store copy, privacy/terms/support pages live on Pages, data-safety + privacy-label answer sheets, review notes.
- **M4 — Store submission** (his-click steps, batched below).

## The only steps that land on Deltoshi

1. **GitHub:** approve pushing the repo to his GitHub account (or one `gh auth login` if no token is available in-session).
2. **Payments:** none required. (Optional later: BGeometrics $20/mo add-on if we ever want real-time MVRV.)
3. **Play Console (~10 min):** create app entry → I pre-fill every field via browser where possible; he clicks Confirm/Pay-nothing steps and uploads happen via CI or my browser session.
4. **App Store Connect (~10 min):** same pattern; iOS binary comes from a free CI macOS runner (GitHub Actions) with signing configured once — he approves the certificate creation in his Apple account.
5. **DNS:** point `bull.koini.io` CNAME to `k0ini.github.io` (one DNS record, ~2 min). Or we use the default GitHub Pages URL until a subdomain is ready.
6. **Two review submissions:** final "Submit for review" clicks (Apple/Google policy requires the account holder; I prepare everything and open the exact pages).

Store review timelines (Apple ~24–48h, Google first-app reviews up to 7+ days, plus Google's 12-tester/14-day closed-testing requirement for new personal accounts — his account predates that requirement only if it's an org/older account; if the 14-day rule applies we start closed testing immediately and production follows automatically) are outside anyone's control; "fully executed" = submitted + tracked to live, with me monitoring and reporting.

## Quality bar

Pinned unit tests for every score anchor; golden tests for Home and Board; `flutter analyze` clean; pipeline fails loudly rather than emitting stale/fake data; stale-data banner in app; accessibility labels on gauge and rows; all strings in one localization file. Web dashboard tested with Lighthouse (performance ≥ 95, accessibility ≥ 95); degrades gracefully with JavaScript disabled (shows an 'enable JavaScript' message).
