# Active work and queued improvements

Updated 2026-10-22. User preferences: one shared market; localized presentation only; offline-first; avoid repeated long test runs. ADHD output mode active for this chat. Research findings are evidence/inference, not product acceptance.

## 1. Shop-led gameplay depth — in progress

- [x] Choose shop building/growth as the next gameplay direction, rather than inspection as the main new mechanic.
- [x] Implement first shop slice: limited curated window, three business directions, existing buyer archetypes, real opening/expansion costs, no automatic money/rent pressure. Integration written; focused shop/domain checks and one shop UI flow passed. Final packaging/documentation/commit pending.
- [ ] Review whether this creates enough interesting decisions in real play. A functional feature is not proof of retention. Later store space/backroom/customer continuity should extend choices rather than become passive profit multipliers.

## 2. Everyday catalog and believable listings/photos — in progress

- [x] User clarified broad ordinary-life resale, not just games/electronics or music gear.
- [x] Add 30 authored products across home appliances, furniture and everyday goods (80 total), with appropriate faults/inspection facts. Integration written; focused catalog checks passed. Existing saves are preserved.
- [x] Broaden new-game market exposure while preserving existing saves, item IDs and firm quotes.
- [x] Add 24 stable, authored seller voices instead of the small repeated listing-intent pool. Keep item truth independent; further editorial variety remains part of catalog work. Optional Apple AI pilot is separate.
- [x] Superseding user decision: one fixed image per product; cancel condition-based photo variants. Condition remains in descriptions and inspection facts.
- [x] Remove 74 alternate/wear image sets and compress retained photos. The asset catalog is approximately 3.6 MiB, down from approximately 14 MiB.
- [ ] Finish distinct, realistic product photos, especially for the new everyday goods. Current fixed-photo selection still shares some family photos; some new goods use illustrations. All 80 products do not yet have unique finished photos.
- [ ] Add genuinely varied camera angles/settings without changing model identity or leaking hidden faults. A random rotation/crop is not a substitute for different photography.
- [ ] Inspect all new art at thumbnail and detail sizes, then retain only used app assets. Generated source masters outside the app bundle are not runtime assets.

## 3. Settings and developer UI — in progress

- [x] Remove the player-visible Developer tools screen.
- [x] Consolidate currency, app-language shortcut, sound/accessibility explanation and notifications under Settings. Focused shop/settings UI verification passed; final documentation/commit pending.
- [x] Keep isolated test fixtures separate from player features and migrate old UI automation away from the deleted developer screen. The entire legacy UI suite has not been rerun.

## 4. Languages and Apple AI

- [x] Research first-wave languages, plus Japanese/Chinese/Arabic/Hindi. See LANGUAGE_PRIORITIES.md.
- [ ] Complete and edit German/French catalog translations, localization infrastructure and Game Center metadata. Work started in a scratch translation file; neither language is enabled in the app yet.
- [ ] Prioritize Japanese next, then explicit Chinese scripts/storefronts; Arabic needs RTL review. Hindi needs evidence of incremental iOS audience. No new regional economies.
- [x] Research current Apple AI / exact SDK APIs. See APPLE_AI_FEASIBILITY.md.
- [x] User authorized minimum iOS26; update all targets. Optional language model still requires Apple Intelligence-capable hardware/availability. No AI dependency/model download has been introduced.
- [ ] If implemented, keep AI output decorative and bounded: item truth, defects, money and outcomes stay deterministic and persisted. Apple's current photorealistic cloud UI is not silent offline photo generation.
- [ ] Configure live Game Center resources in the owner's Apple account and verify signed sandbox behavior. Monetization remains deferred.

## 5. Whole-app UX audit — appended last at the user's explicit request

This section is analysis and queued work only. Do not silently implement it ahead of the work above.

### Tab reselection / return to root

Finding: GameDock assigns the selected tab index even if it is already selected; it has no reselection action. RootView only has a specific market-root reset for Return to hunt.

- [ ] Define the familiar behavior: select a different tab to restore its navigation; tap the already-selected tab again to pop that tab to its root. At the root, a further tap can scroll to top. This should not require a timed double-tap gesture, which conflicts with accessibility and is easy to miss.
- [ ] Use explicit per-tab navigation paths/reselection events. Preserve unrelated tab state and active price editing safely; honor Reduce Motion and VoiceOver.

### Messages: useful ordering, not insertion order

Finding: RootView renders `snapshot.conversations` directly, without sorting. That is persisted conversation insertion order, not most recent activity or urgency. DialogueMessage has no timestamp, so sorting by last message count/ID would invent chronology. Current inbox also mixes awaiting/sold/active states without dedicated action queues.

- [ ] Add a persisted last-activity timestamp with a safe migration fallback; update it from actual messages/events. Never reorder by random IDs or message count.
- [ ] Put actionable replies/held decisions first, then recent active conversations; archive completed/closed threads. Differentiate waiting on player vs waiting on seller. Keep stable tie-breaks.
- [ ] Review buyer/seller/client conversation organization and unread state. Only show badges for real events; preserve offline/cold-notification routes.

### Inventory density and meaning

Finding: owned inventory uses 90-point thumbnail rows, but every pending shipment gets a full-width square DeviceArt and a large card; one shipment can consume most of a screen. Inventory also repeats its navigation title inside GameStageBanner with the “ON YOUR WORKBENCH” eyebrow, which does not describe all carried/in-transit/for-sale stock.

- [ ] Use compact shipment rows/cards and a consistent list/grid for stock. Reserve the large product photograph for item detail.
- [ ] Add clear state grouping/filtering: in transit, ready to inspect, ready to sell, listed, kept for collection. Show capacity and genuine next action; avoid another decorative dashboard.
- [ ] Replace the workbench/inventory wording with a coherent distinction between owned stock, a future actual workbench and shop display. A collection display and a sales window are different states.

### Page hierarchy and repeated banners

Finding: Messages, Inventory, Shop, Settings, Career, Clients and Recovery repeat their navigation title in a large banner. Competition's weekly challenge has its own identity but also needs an intentional hierarchy. The current repetition wastes vertical space and makes every screen look templated.

- [ ] Audit every root/detail/modal in a screen matrix: main purpose, unique title, necessary status, primary action, empty state, navigation, accessibility and long text. Include the new Shop/Settings surfaces in the audit.
- [ ] Keep one clear title per screen. Use a hero only where it communicates actual identity/progress; remove ornamental duplicate headings and stock taglines. Decide consistently when inline vs large native titles help.
- [ ] Review top spacing, image sizing, cards, action density and terminology together. Check normal and accessibility type in both current languages without running the whole test suite repeatedly.

### Player identity and profile

Finding: ProfileView hard-codes `TraderPortrait(identity: 0)` and uses the earned career tier as the main identity text. It has no player-selected name/avatar/title. An earned rank is currently doing the job of a personal profile, which makes the screen feel arbitrary.

- [ ] Add local editable display name and a choice of appropriate avatars; persist independently of career/competition saves and Game Center account identity.
- [ ] Separate player name, shop name, earned career rank and optional unlocked display title. Let the player select among earned titles without granting economic benefits.
- [ ] Provide a clear edit affordance and sensible first-run identity. Do not imply the current portrait/rank is user-chosen or overwrite Game Center identity.
