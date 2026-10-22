# Localization expansion — queued after Game Center

User direction, 2026-10-22: research additional languages that fit this trading game, then translate with professional editorial quality. Do not add country-specific markets for new languages. A consistent fictional world and shared economy are sufficient; language must not alter trading opportunities.

- [ ] Research and rank a small first wave of languages using current primary evidence: iOS game audiences, simulation/management interest, reachable audience, localization cost, typography and ongoing QA. Separate evidence from assumptions; language popularity alone does not establish demand for this particular game.
- [ ] Record the recommended launch order with sources and reasons before translating the full catalog.
- [ ] Translate all gameplay, onboarding, errors, achievements, leaderboard metadata and notification copy as coherent game writing. Preserve meaning, humor, mechanics, terminology and placeholder behavior; avoid literal translation.
- [ ] Audit fictional people and places. Define when to preserve a character's identity, transliterate, or translate a fictional place name; keep a consistent world across languages. Do not create separate real-country economies or seller populations just to support a locale.
- [x] User explicitly chose one shared market. Removed regional price/supply differences, added a backed-up versioned migration that preserves all money and commitments, and localized shared fictional names/places. See REGIONAL_ECONOMY.md and SharedMarketTests.
- [ ] Expand the localization checker and runtime tests to the approved languages. Verify currency presentation independently of language and gameplay balance.
- [ ] Review layouts, Dynamic Type, VoiceOver, pluralization, number formatting, notification truncation and Game Center metadata in every added language. Keep RTL languages behind explicit layout QA, not a translation-only toggle.
- [ ] Document translation review limitations honestly. A fluent agent draft does not replace native-player acceptance.

Current milestone still completes Game Center / Weekly Flip / achievements in Turkish and English. Monetization remains deferred.
