# Canonical economy and regional markets

V2 catalog, internal FX/profile v1. Money stores canonical USD cents. ItemDefinition stores a base value and a typed value tier; no currency symbol is simulation data. Fair value is canonical base × regional category modifier × regional supply modifier × condition × unrepaired defect factor × dated demand. Rarity is not implemented and supplies no multiplier. Repair removes a real defect once; it cannot improve beyond the clean base. Seller belief, archetype and negotiation modify prices, not the base identity. Buyer willingness is bounded by item value and personality, with no reputation price advantage.

US profile: category/supply 1.0. Turkey: electronics 1.20, cameras 1.35, retro 1.10 × supply 1.05. These are deliberately authored fictional market differences, not tax estimates or national purchasing-power claims. Display conversion is separate: internal v1 1 USD = 40 TRY, offline and immutable for a save. Currency may change from settings; market region cannot change mid-career. Device language never reprices the save. Future regional/FX tables need new versioned configurations, never a silent live-rate update.

A locale with region TR creates a Turkey save; other locales start US. Names/cities use the saved region and remain stable when language changes. Dialogues remain professionally localized in English/Turkish through one engine. Future currencies extend GameCurrency and versioned conversion metadata.

## Price identities

Clean reference bands in canonical dollars: budget 15–150; mainstream 80–400; enthusiast 200–900; premium 600–2,200; collector 100–3,000. Overlap is deliberate: type and positioning explain value, and a common collectible need not exceed every camera. Reserved rare/legendary tiers have no generated products in this milestone. All fifty catalog entries declare positioning and pass their tier bounds. Individual reference points follow product type/position, not a universal division of the old price list.

Calibration anchors are first-party seller listings, not fictional brands copying actual hardware: [B&H used monitors](https://www.bhphotovideo.com/c/used/1795304) and [MPB used older mainstream camera bodies](https://www.mpb.com/en-us/product/canon-eos-70d), checked 22 October 2026. They support the order of magnitude of ordinary used goods; these are not a live feed or a promise of real resale prices. Vista's clean base is $120; clean regional base in Turkey is $144 equivalent / ₺5,760. A high seller ask is a seller's claim, not a certified valuation.

The starter wallet is $1,000 canonical. Expert report $7.50; kits $17.50/$25/$20; base repair labor $4 plus defect-dependent service. These remain game tuning, subject to human evaluation. Estimates remain knowledge-limited and rounded outward to $5 canonical steps; price displays round to whole display units. Editors preserve cents internally to avoid silently changing a standing agreement. Appraisal is never a guaranteed sale price.

## Legacy saves

Pre-configuration saves are backed up adjacent to the original as `.pre-economy-v2.json`. Their money fields (cash, paid costs, asks, held quotes, offer/event amounts and immutable receipts) are rebased once at 20 legacy units per canonical dollar, rounded toward zero at cent precision. Item IDs, faults, knowledge, timing and ownership stay intact. The migration notice is visible in market settings. Existing quoted commitments retain their converted amount. New catalog appraisals deliberately change to the corrected reference values; the notice states that product valuations changed. Legacy unspecified market defaults to US rather than guessing its past language. New configuration is saved before normal play; later language/currency changes do not rebase again. Backup preserves exact original amounts if needed.

## Evidence

Baseline 121 units pass. The absurd-monitor regression was red at 520,000 cents against a 30,000-cent bound (`/tmp/FlipMilestone-price-red.xcresult`). Region tests exercise 10,000 actual generated listings and buyer budgets across both profiles, currency round trips, bounds, invalid condition and overflow. Existing repair tests verify no duplicate charge/repeated restoration. Prior fixed-price fixtures were rebased to meaningful values so their behavioral assertions still exercise a plausible listing; no buyer/traffic safeguards were removed to make tests pass.

Lightweight price memory is deferred until enough comparable observations exist. If added, it must show only the player's actual completed transactions for the model (range and sample count). It will never label synthetic theoretical prices as recent completed market sales. No external market feed or analytics service is added.
