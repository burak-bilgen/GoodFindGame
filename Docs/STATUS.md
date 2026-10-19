# Milestones

Task 1 complete: self-contained Git project, iOS 17+ portrait iPhone, localized five-tab shell, unit/UI test targets and localization completeness check.

Section 47 is the exact First 72 Hours backlog. Auctions are stretch only after all required MVP systems, tests, localization and polish are healthy; otherwise V1.1. The supplemental engineering/localization requirements override conflicting passages in the original brief.

Next: Task 2 — seed domain model. Do not introduce Phase B features before the vertical slice is playable and evaluated.

Validation: simulator build and tests passed on iPhone 18 Pro (iOS 27.2), including English/Turkish shell navigation and bundled translation checks. Built plist confirms iOS 17 minimum, iPhone only and portrait. Localization catalog check passed. No Swift compiler warnings; Xcode emits an App Intents metadata warning for targets without App Intents.

Task 2 complete: exact integer Money with overflow checks, typed IDs, serializable domain models and ten original gaming/electronics definitions. Seed validation, stable hidden-truth serialization and TR/EN currency formatting tests pass. Global display uses neutral credits (¤); Turkish uses ₺ without changing economic amounts. Simulator service recovery and a nonparallel retry resolved the initial test-runner connection failure. Next: Task 3 deterministic listing generator.

Task 3 complete: injectable seeded RNG and deterministic listing/pricing generation with separate public claims and hidden truth. An approachable first listing introduces the loop; later listings include risk. Seven unit tests pass, including a 1,000-listing sweep containing both underpriced and overpriced inventory, reproducibility and trend/defect pricing. Next: Task 4 marketplace feed.

Task 4 complete: persistent market snapshots, category/newest controls, listing navigation and original geometric art. Atomic saves publish only after disk success; unreadable saves are preserved. Eight unit tests and both localized UI tests pass, including NPC name rendering after visual QA found and corrected dynamic-key interpolation. Next: Task 5 listing detail.

Task 5 complete: listing art, public condition/description, seller ratings/trade counts/localized locations and a persistent conversation CTA. Added pluralized trade counts and defensive content-key lookup. Eight unit tests and both full localized feed→detail→conversation UI checks pass. Next: Task 6 negotiation behavior and history.

Task 6 complete: numeric offers, exact localized amount parsing, deterministic acceptance/rejection/counters, halfway and acceptance actions, question-driven clues, negotiation fatigue, walk-away and persisted semantic dialogue variants. Additive decoding preserves earlier saves. Eleven unit tests and both TR/EN UI routes pass; no Swift compiler errors/warnings. Immediate replies are the current vertical-slice behavior; delayed resolution remains Phase B. Next: Task 7 purchase/inventory.

Task 7 complete: agreed purchases debit cash and add inventory in one saved transition. Capacity/funds and duplicate guards preserve item truth. Thirteen unit tests and both localized purchase→inventory→relaunch flows pass. UI tests use dedicated temporary saves. Next: Task 8 inspections.

Task 8 complete: free limited basic inspection, paid full inspection, stable defect reveals and visible valuation estimates/failure states. Model reference values support informed initial buying decisions. Fourteen unit tests pass; TR/EN UI purchase→inspection→relaunch flows pass. Final display-error handling also rebuilt and unit-tested. Next: Task 9 player resale listings.

Task 9 complete: inspected inventory can be listed at an exact localized asking price; duplicate active listings are prevented and initial views/favorites are generated from price competitiveness. Fifteen unit tests pass and both UI flows publish a resale listing and preserve inventory across relaunch. Next: Task 10 NPC buyer offers and settlement.
