# Trading-feel milestone

This milestone continues the existing game. It adds no categories, tools,
measurements, progression, auctions, Game Center or monetization.

## What changed

- Marketplace: compact scan-friendly cards; original vector still lifes for
  controllers, screens, audio gear, drives, cameras, lenses and retro objects;
  stable product palettes; explicit seller condition claims, actual freshness,
  bookmarks and price drops. No objective bargain badge or fabricated interest.
- First trade: a fresh save has one existing, novice-detectable port fault, a
  specific untested-connections clue and enough margin for either repair or an
  as-is sale. Only this introduction is curated. The generator consumes the same
  random stream for later stock, and existing saves are never regenerated.
- Journey: delivered purchases lead straight to the item; a published listing
  opens its live sale; the result returns to a fresh marketplace stack. The first
  marketplace continuation points to the player's actual unfinished trade.
- Negotiation: seller voice, qualitative bargaining fatigue, message bubbles,
  short reply feedback, editable lower-offer suggestions, clear counters and
  commitment. Existing deterministic behavior and persisted timers remain.
- Inspection: a short staged condition/fault/estimate reveal. Its space is
  reserved from the start so links never move under a tap. Reduce Motion and
  VoiceOver show the complete result immediately. An unread expert report also
  reveals on return; original measurements remain secondary reference material.
- Repair: one immediate paid service per known fault. The quote shows cost and
  estimated value recovered; the player can sell as-is or leave the item held.
  Some quotes are economical, others cost more than the value recovered. Service
  cost is anchored to the item; demand only changes the potential resale return,
  so a market event cannot change the amount charged under a tap. No new
  timer framework or repair minigame. Original evidence remains unchanged;
  repaired faults stop reducing estimates and actual buyer valuations. Costs
  persist into the settled trade and repeat service is rejected.
- Selling: acquisition/inspection/repair investment beside the uncertain
  estimate and editable asking price. Real simulated views/favorites stay under
  disclosure. Incoming offers show identity, amount, deadline and net result
  before acceptance. No invented buyer rating.
- Settlement: signed localized profit/loss, ROI, purchase-to-sale comparison,
  evidence-based learning copy and a direct next-hunt action. The receipt retains
  the complete cost breakdown under disclosure.
- Feel: shared warm-paper surfaces, rounded display typography, category color,
  success/loss treatments, short meaningful transitions and system haptics.
  Original synthesized sound cues are available in Profile, off by default, and
  use the ambient audio category to respect silent mode. No feedback on every tap.
- Returns: existing typed notification destinations are preserved. Away events
  now open the relevant item/conversation/sale directly from their named row.

## Visual rules

Page inset 16 pt; compact group spacing 8–12 pt; main group spacing 16–20 pt.
Surface radius 20 pt, artwork and primary actions 16 pt. Product art is decorative;
category names, condition claims and defect text also convey state without color.
Category caption colors measure at least 4.62:1 against the intended warm-paper
background and 8.52:1 against the intended dark-card sample. Monospaced digits
are used for prices/countdowns, not every statistic. All new
player-facing copy uses semantic String Catalog keys, natural Turkish/English,
translator notes and locale-aware numbers/currency/percentages. Fictional product
names remain globally consistent.

## Verification record

Baseline checkpoint: `3949234`. Baseline build, 73 domain tests and fresh-save
English/Turkish first trades passed before broad UI edits. Ranked audit:
GAMEPLAY_UX_AUDIT.md. Marketplace checkpoint: `9bbe668`.

The domain suite currently passes 79 tests in 21 suites, including both first-
trade choices, immutable original evidence, repair/settlement reconciliation,
stable service quotes and preservation of an existing clean starter.

The connected UI journey uses actual accelerated first-trade timers: fresh save,
listing, seller question, lower offer, counter acceptance, purchase, delivery,
inspection, resale pricing, publication, buyer counter, sale, payoff and next
listing. The repair/loss journey buys a different existing listing, asks about its
fault, reveals it through expert inspection, repairs, relaunches to check the
service persisted, then deliberately sells cheaply to exercise loss feedback.
Older category reports, feed/watch/filter behavior, history, notification routes,
offline catch-up and large Turkish text remain in regression coverage.

A regression recording caught a real inspection layout race: expanding revealed
content could move the report link while a tap was landing and open the resale
form. Reserving reveal layout fixed the camera reopen test. A separate test-only
identifier issue came from applying accessibility identifiers to containers;
those identifiers were removed so child controls remain individually reachable.

Final verification:

- Broad regression run: **79 domain tests + 27 UI scenarios, 106 passed, zero
  failures/skips**. This includes actual local notification delivery/tap routing,
  five consecutive trades, both locales, report persistence, filters and returns.
- Final affected-flow follow-ups: repaired introductory trades in Turkish and
  English dark/reduced-motion presentation passed after the last visual/copy
  changes. The 79 domain tests also passed again. A strengthened five-trade run
  separately expanded and verified acquisition, inspection, repair and total-cost
  rows on all five receipts; it passed.
- Debug build/tests, a separate staged-checkpoint build-for-testing and the final
  Release build succeeded. No Swift compiler warnings; Xcode emits its existing
  non-blocking App Intents metadata warning because no App Intents dependency exists.
- Localization check: **405 semantic keys**, complete Turkish/English units,
  translator notes, matching format arguments and manual extraction. Release
  binary inspection found no test-launch or developer time-travel/cash controls.
- Actual screens were inspected in both locales, including the first port fault,
  the repair quote, the corrected repaired state, both profit/loss treatments,
  expanded costs, large Turkish text and the next hunt in dark mode.

Receipt QA also confirmed native LabeledContent exposes each cost label and its
value as one accessibility row, such as “Total cost, ¤1,678.08”. Tests now match
those actual rows rather than expecting a separate static label.

| Commit | Checkpoint |
| --- | --- |
| `3949234` | Preserve the healthy uncommitted inspection work and baseline trading flow |
| `a98b2e8` | Record the ranked gameplay/UX audit before broad changes |
| `9bbe668` | Marketplace identity, original item art and first-trade continuation |
| `c743caf` | Seller conversations, personality presentation and event feedback |
| `55ae5b9` | Discoverable introductory fault, stable service quotes and original evidence |
| `8aebd5b` | Inspection reveals, safe action positions and coherent journey navigation |
| `bd33cbb` | Buyer offers, net payoff, full cost disclosure and contextual return rows |

Selected unmodified simulator captures and machine-readable result summaries are
saved outside the Git checkout in `../../Artifacts/TradingFeel-2026-10-20/`.
The full regression summary records 106 passed checks; the additional focused
journey and receipt summaries are preserved beside the screen gallery.

## Qualitative screen review

| Intended beat | Observable support in the playable build |
| --- | --- |
| Curiosity | Item silhouettes, two-level price hierarchy and next listings visible together; no deal rating |
| Suspicion | The low introductory price is paired with an untested-connections clue |
| Tension | Actual delayed replies, seller fatigue, counters and visible quote deadlines |
| Anticipation | Delivery continuation and an unread, staged inspection reveal |
| Agency | A known fault, an explicit service quote and an as-is sale remain separate choices |
| Satisfaction | Signed settlement, ROI, success feedback and the next-hunt action share the result screen |
| Learning | The discovered fault, original report, repaired state and settled costs remain explainable |
| Another hunt | The result returns directly to active stock with clear public clues rather than an accounting screen |

This review supports the design direction; it does not substitute for measured
human enjoyment or retention.

## Practical limits

Simulator: iPhone 18 Pro / iOS 27.2. The deployment target remains iOS 17; that
runtime and physical-device haptics/audio have not been verified in this session.
Direct free-form simulator control was denied by macOS permissions. Playable UI
runs, their screenshots and failure recordings were inspected instead. No claim
of physical-device verification, human enjoyment or measured retention is made.

The product question remains qualitative: after a profitable trade, and after an
understandable loss, does a human choose to open another listing? Passing the
regressions establishes a coherent, working journey; human repeat-trade sessions
can further validate that feeling before resuming the paused backlog.
