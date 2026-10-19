Good. Your interpretation is correct.

Resolve the two document inconsistencies as follows:

1. “First 72 Hours — Exact Codex Backlog” is Section 47. Treat the Section 46 reference in the final directive as a numbering mistake.

2. Auctions are NOT part of the required MVP. They are a stretch goal only if the core loop, offline event system, progression, Game Center integration, monetization, testing, localization, and polish are already healthy and there is remaining time. Otherwise defer auctions to V1.1.

Before implementation, also adopt the following engineering and localization rules as project requirements.

## Git / Commit Discipline

Use Git continuously throughout development.

Create small, meaningful, atomic commits after completed milestones instead of one large commit at the end.

A commit must never knowingly leave the project in a broken state.

Before every milestone commit:

- build the app,
- run the relevant tests,
- fix compile errors,
- fix test failures caused by the change,
- fix warnings introduced by the change when reasonably possible,
- verify the primary flow affected by the change,
- review the diff for accidental files, debug code, secrets, generated junk, or unrelated modifications.

Prefer commit messages such as:

- `feat: add marketplace listing generator`
- `feat: implement seller negotiation`
- `test: cover deterministic pricing`
- `fix: preserve hidden defects across reload`
- `refactor: centralize game balance configuration`
- `l10n: add Turkish marketplace dialogue`

Do not create commits containing unrelated changes.

Do not rewrite or destroy Git history unnecessarily.

Do not commit API keys, signing credentials, secrets, personal developer configuration, build output, or other sensitive/local artifacts.

At the end of each meaningful task, report the commit hash and a concise summary.

## Engineering Quality

Do not knowingly leave temporary hacks that silently become architecture.

Prefer simple, explicit and testable code over clever abstractions.

Do not invent Apple APIs or assume framework behavior. When using GameKit, StoreKit, UserNotifications, SwiftData or other Apple frameworks, use APIs supported by the deployment target.

Keep simulation/domain logic independent from SwiftUI views wherever practical.

Important game logic must be deterministic and unit-testable.

Currency must never use floating-point arithmetic.

Random generation must not change because a SwiftUI view recomputed.

Persisted hidden information must remain stable across launches.

Do not suppress errors merely to make the project compile.

Do not use force unwraps unless an invariant makes them genuinely safe and the reason is clear.

Do not silently swallow persistence, StoreKit, Game Center or notification failures.

Use structured logging appropriately in DEBUG builds.

## Localization Is a Core Architecture Requirement

Localization is NOT something to add near the end of the project.

Implement localization correctly from Task 1.

Minimum launch languages:

- Turkish — `tr`
- English — primarily natural US/global English

Every user-facing string must be localizable from the beginning.

Use Apple's modern localization workflow, preferably String Catalogs (`.xcstrings`) where appropriate.

There must be no scattered hardcoded user-facing Turkish or English strings in SwiftUI views, domain logic or generated dialogue.

This includes:

- navigation labels,
- buttons,
- errors,
- onboarding,
- notifications,
- seller messages,
- buyer messages,
- inspection results,
- repair messages,
- achievements,
- Game Center text,
- market events,
- client requests,
- collection descriptions,
- accessibility labels,
- empty states,
- transaction summaries,
- tutorial copy.

## Translation Quality

Do NOT treat localization as literal machine translation.

The Turkish and English versions should both read as if originally written in that language.

Marketplace dialogue is especially important.

For example, Turkish marketplace dialogue can naturally use expressions such as:

- “Son ne olur?”
- “Bugün alırsam ne olur?”
- “Kutusu faturası var mı?”
- “Pazarlık payı var mı?”
- “Takas düşünür müsün?”

English should NOT literally translate those sentences word-for-word.

It should use natural marketplace language appropriate to an English-speaking user, for example concepts such as:

- “What’s your lowest?”
- “Would you take $120?”
- “I can pick it up today.”
- “Does it come with the original box?”
- “Any issues I should know about?”

Write dialogue independently for each locale while preserving the NPC’s intent and personality.

Localization should preserve:

- personality,
- humor,
- politeness,
- aggressiveness,
- bargaining style,
- urgency,
- ambiguity,
- scam/suspicion clues.

A dishonest Turkish seller and a dishonest English-speaking seller should feel culturally natural in their respective languages, not like translated copies of one another.

## Localization Content Architecture

Do not create thousands of fully hardcoded conversations.

Use composable localized dialogue templates driven by:

- seller archetype,
- buyer archetype,
- negotiation state,
- urgency,
- honesty,
- category,
- known defects,
- player offer,
- locale.

However, avoid robotic template repetition.

Support multiple variants for common intents.

Example semantic intent:

`seller.counter.tooLow`

should have several natural variants per locale instead of one sentence repeated forever.

Keep semantic keys stable and language-independent.

Maintain a localization glossary/document for important terminology so wording remains consistent.

Examples:

- asking price
- market value
- estimated value
- inspection
- hidden defect
- repair
- offer
- counteroffer
- reputation
- collection
- market trend
- realized profit

Add translator/context notes for ambiguous strings.

## Formatting

Never construct localized sentences by concatenating arbitrary string fragments.

Use locale-aware:

- currency,
- percentages,
- dates,
- relative time,
- numbers,
- pluralization.

Layouts must tolerate longer localized text.

Do not assume English/Turkish string lengths.

Accessibility labels must also be localized.

## Localization QA

Add development support for detecting localization problems.

At minimum:

- identify missing translations,
- avoid untranslated localization keys appearing in production,
- test Turkish and English UI,
- check important screens with long text,
- check pluralization,
- check currency/number formatting,
- verify notification text in both languages.

If practical, add a DEBUG pseudo-localization mode to expose layout assumptions.

Before App Store submission, perform a complete localization QA pass.

The desired quality level is commercial game localization, not placeholder translation.

## International Market Strategy

Architect the game so additional locales can be added without changing game logic.

Launch priority:

### Tier 1 — Required for V1

**Turkey / Turkish**

Turkey is our home-market cultural advantage. Dialogue, bargaining behavior and marketplace flavor should feel exceptionally natural here.

**United States / English**

English is not merely a fallback translation. Treat English as a first-class product language.

US/global English needs its own natural marketplace writing and App Store metadata.

The United States is strategically important because it remains the largest mobile-game consumer-spending market, so do not design the game's humor, economy presentation or terminology in a way that only makes sense to Turkish players.

### Tier 2 — Prepare architecture, localize after initial validation

**Germany / German**

Potentially strong fit for a marketplace/trading concept. Keep UI and content architecture ready for German text expansion.

**Japan / Japanese**

Japan is one of the world's largest mobile-game spending markets and can become strategically important if the game validates.

However, Japanese must NOT be shipped as cheap automated translation. It requires proper cultural localization of dialogue, marketplace behavior, tone, UI terminology and App Store copy.

Do not add Japanese merely to increase the locale count.

### Tier 3 — Future expansion

Potential candidates depending on metrics:

- Spanish
- Brazilian Portuguese
- French
- Korean

Do not spend the one-month MVP schedule translating all of these now.

The architecture should support them; actual localization should follow product validation.

## Cultural Neutrality of Core Systems

Do not make game mechanics depend on Turkish-specific concepts.

The underlying concepts should be universal:

- buying,
- selling,
- negotiating,
- shipping,
- inspecting,
- repairing,
- collecting,
- market speculation,
- auctions,
- reputation.

Country-specific flavor belongs in localized content/configuration layers.

This will let us adapt dialogue, names, money display, city names, cultural references and market-event copy without rewriting the simulation engine.

## Fictional Names and Locales

Seller/buyer name pools should be locale-aware.

Do not show every global player Turkish NPC names.

Create data-driven name pools per supported locale.

Likewise, generated descriptions and marketplace slang should come from locale-appropriate content packs.

Fictional product brands, however, should ideally remain globally recognizable and consistent between locales.

## App Store Localization

Eventually prepare professionally localized:

- app name/subtitle if the brand strategy allows it,
- description,
- promotional text,
- keywords,
- screenshots,
- screenshot captions,
- Game Center leaderboard names,
- achievement titles/descriptions,
- challenge/activity metadata.

Do not translate App Store metadata literally. Write it for conversion in each market.

## Game Center

Continue following the Game Center requirements from the master brief.

Game Center must remain optional and must never block core gameplay.

The initial implementation should eventually include:

- Game Center authentication,
- achievements,
- one recurring weekly leaderboard,
- Weekly Market Challenge,
- score sanity validation,
- Competition entry point.

Competitive rewards remain prestige/cosmetic because the v1 economy is client-side/offline.

Do not implement Game Center during the First 72 Hours vertical slice.

## Execution

Now begin implementation from Section 47, Task 1.

Work sequentially through the backlog.

Do not skip ahead.

Do not expand scope simply because an additional feature seems interesting.

For every task:

1. implement it completely,
2. maintain Turkish and English localization,
3. add/update relevant tests,
4. build the project,
5. run the relevant test suite,
6. fix errors and regressions introduced by your work,
7. review the resulting diff,
8. make an atomic Git commit when the task reaches a healthy milestone,
9. report what changed and the commit hash,
10. continue to the next task unless blocked by a genuine technical issue.

Use sensible engineering defaults instead of repeatedly asking questions when the master document already provides enough direction.

If a product decision is genuinely ambiguous and materially affects architecture, stop and explain the alternatives rather than silently inventing a new product direction.

Do not optimize for writing the most code.

Optimize for a polished, stable, maintainable and genuinely enjoyable game.

Start now with Task 1 — Project skeleton.