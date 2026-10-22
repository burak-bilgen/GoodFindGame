# Game Center / Weekly Flip delivery — 2026-10-22

## Implemented

- Explicit, optional GameKit authentication with system UI, no first-launch prompt or repeated automatic prompts. Friends/global leaderboard and achievement dashboards follow an in-game overview.
- Isolated weekly trading saves, $1,000 equivalent bankroll, common seed, UTC Monday weeks, shared engines, no career wealth transfers. Explicit finalization freezes play; automatic rollover archives local results. Only final current-week results submit; late offline results never enter the next week.
- Versioned integer TraderScore, 1,000,000 cap, portfolio ROI floor, capped distinct quality trades, transaction/period/provenance validation and cash reconciliation.
- Twelve gameplay achievements, monotonic local progress, per-account acknowledgements, safe retry on connection/foreground/network restoration. Comeback is a durable career fact, so later spending cannot erase eligibility if the companion journal was temporarily unavailable.
- EN/TR competition, achievement and metadata copy; game-like overview, score, remaining time, ranks, isolated trading, prior local finisher badges, Dynamic Type layouts, VoiceOver labels and Reduce Motion behavior. No money or economic rank prizes.
- User-approved simplification to one market. Currency changes presentation only. Localized character names and fictional neighborhoods are independent of currency. Versioned, backed-up migration preserves all actual money and agreements.

## Verification and limits

The pre-change baseline built and passed 138 unit tests. Its full UI run reported 198 passing and 3 failing tests in the result summary: an English first-trade runner termination, a large-Turkish visibility assertion, and a deterministic price-field focus failure. The first two passed in an isolated replay; the third reproduced and led to an editor scroll correction. Its final focused UI replay was not run after the user requested reduced testing.

Before shared-market simplification, all 147 unit tests passed (`/tmp/ProjectFlip-gc-models2.xcresult`). Later broad UI work exposed duplicate native confirmation-button accessibility matches in the new test harness; selection was corrected to `firstMatch`. Those intermediate failures are not represented as product acceptance.

At the user's explicit direction, the long UI run was stopped and **the full suite was not repeated**. Final validation was limited to:

- Debug build and **14 passing checks**, zero failures/skips or recorded runtime warnings (`/tmp/ProjectFlip-gc-final-targeted.xcresult`): 13 domain/integration checks across scoring, isolated challenge saves/reset/finalization, offline achievement retry, shared-market migration and recovery; one English Competition UI flow through entry, standardized bankroll, relaunch, offline finalization and frozen result.
- Release simulator build succeeded (`/tmp/ProjectFlip-gc-release.log`). No Swift compilation errors or Swift warnings. The toolchain emits its standard App Intents metadata-extraction notice because this game does not use App Intents.
- Catalog completeness: **736 keys** with EN/TR translations, translator context and matching placeholders. English and Turkish Competition screenshots, including accessibility3 Turkish, were visually reviewed; no visible text clipping in those captured layouts. Captures: `../../Artifacts/GameCenter-2026-10-22/`.

This is not a claim that the full final test suite is green. The new Turkish/Reduce Motion UI scenarios reached and captured the challenge surfaces before the intermediate harness assertion; they were not fully replayed after that correction. A physical-device VoiceOver audit and iOS 17 runtime pass remain release acceptance work.

Live Apple authentication, actual resource acceptance, score delivery, friend ranks and remote achievement completion **have not been verified**: no signing team, Apple credentials or configured App Store Connect resources were available in the repository. Follow [the setup document](GAME_CENTER_SETUP.md) for that manual owner-account step. Local failure handling is covered through the minimum GameKit service interface and fake service, not a claim of end-to-end live Game Center success.

## Next work

1. Configure and verify Game Center in the owner's signed sandbox build using GAME_CENTER_SETUP.md.
2. Perform the short physical-device accessibility and minimum-iOS acceptance pass.
3. Research and prioritize additional languages, then translate with editorial QA. See LOCALIZATION_BACKLOG.md. No additional languages were silently added; no new country markets are planned.
4. Monetization remains deferred. No ads, IAP, subscriptions or paid cosmetics were implemented.

Direct friend challenges and Activities remain prepared/deferred rather than advertised as working. The local route seam is not a registered system activity. No final-placement Top 10/100 badge is claimed from a provisional live rank.
