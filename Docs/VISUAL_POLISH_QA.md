# Visual acceptance follow-up

This pass builds on `26874d3`; it does not restart the game. The existing 79-test
simulation, integer money, saved item truth, timers, repairs, ledger, notification
routing and localization system are preserved.

## Implemented direction

An original trader's workbench: ink-blue item displays, warm paper, amber action
buttons, category lighting, stable illustrated NPC portraits and tactile edges.
The market is a two-column collectible hunt at normal text sizes and a single
column at accessibility sizes. Real price drops, watch state and freshness remain;
no visual treatment claims an item is objectively undervalued or rare.

Listing detail separates quoted seller evidence from unresolved actual condition.
The product and price lead; seller identity and optional model reference remain
available. Unknown fact tiles stack vertically at accessibility sizes.

Purchase confirmation retains the actual agreed amount and an uncertain next
step. Closed dialogue moves into expandable history so a completed bargain does
not bury its payoff. Inspection retains the persisted three-stage reveal, now
with visible progress and a text-plus-color finding treatment. Service cost,
estimated recovered value and the as-is alternative remain explicit.

Selling offers three editable asking-price suggestions around the player's
existing uncertain estimate. They change only the input; they neither publish a
listing nor expose hidden buyer budgets. Offers use stable portraits and a
separate offer panel. Settlement leads with signed profit/loss, a large result
and real ROI; the item and next-hunt action follow, with full costs still available.
Inventory, selling, messages and offline returns share the same card language.
Return counts and links are derived from the existing saved event report.

Existing event sound/haptics remain. New button/settlement motion respects Reduce
Motion, and the previous VoiceOver inspection behavior remains intact. The
portrait, display light and artwork variation depend only on public identity.

## Audit and validation

The ranked remaining problems and before-state assessment are appended to
GAMEPLAY_UX_AUDIT.md. Baseline: 79 domain tests and fresh-save first-trade UI
journeys in English and Turkish passed. Marketplace checkpoint `cd55b03` passed
both localized first-trade and watch/filter scenarios, with both languages'
actual screenshots inspected.

During follow-up screenshot review, purchase auto-scroll was found to prioritize
the last chat bubble over the commitment panel. The presentation now scrolls to
the purchase and collapses old dialogue. A later review also caught a generic “listing unavailable” fallback above the
successful purchase. Acquired items now take the committed-purchase presentation
even when the saved lifecycle has no closure reason. Both languages assert that
the contradictory fallback is absent. A new UI assertion also uses stable
identifiers for price choices because their accessible labels include localized
amounts. These are presentation/test fixes, not economy changes.

The story review also exposed an oversized resale product header: repeated art
pushed the price decision and incoming offer beneath the first viewport. Compact
product headers now give the price choices and offer the primary space. Selected
price suggestions are visible, and invested/estimated amounts retain primary text
contrast. No buyer behavior or economic data was changed.

Measured contrast for the new fixed treatments: white on ink 17.14:1; primary
button text across its amber gradient 7.90–9.62:1; payoff gain 6.59:1 and loss
5.45:1 against the brightest hero background. Category captions against warm
cards measure 4.94–5.73:1. Color is accompanied by amount signs, words and icons.

## Verification record — 21 October 2026

- 79 domain tests in 21 suites passed; no domain, simulation, persistence, timed
  action, money or balance implementation was changed in this pass.
- The broad final UI run passed all 27 scenarios with zero failures/skips,
  including five consecutive trades, both languages, real timers, reports,
  notification delivery/routes, market changes, filters and return summaries.
- After the final purchase-fallback correction, all three connected English,
  Turkish and reduced-motion dark journeys passed again. A separate return-summary
  capture run also passed.
- Debug/testing and Release builds succeed. 429 semantic localization keys pass
  completeness, translator-context and format checks in Turkish and English.
- The Release binary contains none of the checked test-launch/time-travel/cash
  control strings.
- Actual captures were reviewed for discovery, claims versus unknowns, bargaining,
  purchase commitment, inspection, repair, resale pricing, offers, signed results,
  loss learning, return summary, large Turkish text and dark/reduced-motion play.

Unmodified screens, baseline comparisons, the visual story gallery and result
summaries are stored outside the checkout in
`../../Artifacts/VisualPolish-2026-10-20/`. The dated directory reflects the start
of this overnight pass; final verification completed on 21 October.

Presentation verdict: the collectible market, unresolved-information panel,
commitment moment and prominent signed outcome now communicate the fictional
trading-game loop. The gallery makes that judgment reviewable; it is not a claim
of measured commercial conversion or player retention.

## Limits

The available runtime is iPhone 18 Pro / iOS 27.2 Simulator. iOS 17 and a physical
device are unavailable for validation here. macOS Computer Use access is denied;
UI test-driven playable journeys and their unmodified captures provide the
screen evidence. No claim is made of free-form manual play, physical haptic/audio
QA, human enjoyment or measured retention.

The existing iOS simulator filter-insertion diagnostic remains recorded in the
watch/filter runs. It predates this pass; both localized interaction checks pass.
The existing non-blocking App Intents metadata warning also remains.

The pre-existing deletion of root PROJECT_FLIP_CODEX_MASTER_BRIEF.md is excluded
from these commits. The paused feature backlog remains paused.

## Story acceptance checklist

| Beat | Decision or consequence visible in the build |
| --- | --- |
| Hunt | Compare several original items, asking prices and seller clues together |
| Suspicion | An unusually low first asking price sits beside an untested-connections clue |
| Investigation | Seller claims, unknown facts and optional reference value have separate treatments |
| Bargain | Seller tone, patience, actual delayed replies and a counter create a choice to push or commit |
| Commitment | A visible deal-closed panel retains the amount spent and directs the player to the item |
| Reveal | Exterior, finding and estimate arrive in the existing short persisted reveal sequence |
| Decision | Pay the known service cost for uncertain recovered value, sell as-is or hold |
| Anticipation | Choose an editable asking-price strategy and follow actual incoming buyer interest |
| Payoff | A signed result and ROI lead; costs remain available and consistent with the ledger |
| Learning | A loss keeps the real spending/sale comparison and an explanatory next-purchase lesson |
| Temptation | The result has a direct next-hunt action and the market shows more public clues |

This is a qualitative presentation review, not evidence of commercial conversion
or repeat-play retention. Commercial shipment also requires physical-device and
minimum-runtime validation beyond this simulator session.


## Continuing a trade from any core area — 21 October 2026

The next pass closes gaps exposed by following the same item across screens.
An already-listed inventory item now links to its actual live sale instead of
showing an inert “already listed” note. The seller conversation links to that
same sale while active, and to its settled result after resale. Completed shipment
history no longer sends a sold item back toward delivery. Inspected goods use
review language rather than repeating the initial unknown-condition prompt.

A market continuation card now surfaces a real pending/countered buyer offer,
including after the introductory trade. It shows the product, proposed amount
and the buyer's stable portrait and opens the exact live listing. The Selling
tab badge counts active listings awaiting a buyer decision. These are actionable
states, not invented unread-message counts; sold or withdrawn offers do not count.
No simulation, save schema, timers, pricing or buyer behavior changes are involved.

Two localized continuation scenarios each complete two trades. They save/relaunch
before following an offer from the market, open the second sale from inventory
and seller conversation, settle it, then reopen the historical conversation and
verify it reaches the actual result rather than delivery or missing inventory.
The existing connected English/Turkish and dark/reduced-motion journeys remain
in the affected-flow check. Captures and final results are recorded separately
from the earlier broad 27-scenario run.

Inbox summaries now follow the resale state too: active items show the live sale
or waiting buyer, and completed items show “Sold” plus the actual settled sale
amount instead of retaining the old delivery instruction. An empty inbox invites
the player to investigate a listing and returns directly to the hunt. Both
localized continuation tests exercise this entry route and the saved sold preview.

Verification: the five affected UI journeys passed, followed by both strengthened
localized continuation scenarios after the inbox changes. Debug/testing and
Release builds pass; 433 semantic keys pass Turkish/English validation. Fourteen
unmodified captures and result summaries are available in
`../../Artifacts/TradeContinuation-2026-10-21/gallery.html`. Both locales' waiting
buyer, empty inbox, settled inbox and completed conversation were visually
reviewed. Physical-device and iOS 17 runtime limits remain unchanged.
