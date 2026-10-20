# Trading feel milestone — 20 October 2026

## Evidence and limits

Inspected Git history, the uncommitted inspection changes, all core SwiftUI screens,
event scheduling, negotiation, pricing, buyer settlement, persistence and tests.
Baseline unit suite: 73 tests pass. Fresh-save English/Turkish first-trade UI runs
capture the actual simulator at discovery, listing, conversation, commitment,
inspection, resale pricing, buyer offer and settlement. These are playable UI
runs with accelerated persisted events, not a substitute for human fun testing.
Direct free-form simulator interaction is unavailable because macOS Computer Use
permission is denied. No claim of human playtesting or measured retention is made.

The pending facts schema is deterministic and does not reroll the economy. Its
category-specific measurements are already more detail than the main loop needs.
Preserve them as optional reference material; do not expand or foreground them.
The Xcode project diff is mostly editor formatting. No new category/tool work.

## Ranked problems (implementation order)

1. **The first trade has no visible thread.** Buying leaves the player in the
   conversation; publishing leaves them in a form; settlement has no route back
   to the hunt. Add a concise next-action prompt and direct continuation links.
2. **Discovery has weak scan hierarchy.** Huge identical device placeholders and
   repeated seller statistics make ten listings feel like paperwork. Use compact
   collectible cards, original product silhouettes, category color, strong prices,
   seller copy and actual price-drop/watch state. Never expose hidden value/truth.
3. **Negotiation is a form, not a person.** Preserve the working deterministic
   engine; show seller voice and fatigue through dialogue/presentation, clear
   message bubbles, a pending reply, and prominent counter/agreement states.
4. **Inspection dumps a report.** Stage condition, known issues and the uncertain
   estimate; emphasize discoveries and value loss. Keep expert details optional.
   Persist inspection before presentation; cancellation must never change truth.
5. **Repair is absent.** A cost field exists but there is no player action. Add a
   small explicit repair quote for known faults, with cost and estimated recovered
   value. Offer immediate service versus selling as-is, with no new timer system.
6. **Resale obscures the bet.** Show total invested and an uncertain value estimate
   alongside the asking-price choice. Keep actual simulated attention metrics.
7. **Offers and settlement have no weight.** Promote buyer identity, offer, net
   proceeds and resulting profit/loss. Make the trade result the visual payoff;
   retain costs behind disclosure and provide the next hunt action.
8. **Events lack a coherent sensory language.** One small shared layer for major
   replies, purchases, discoveries, offers and results; optional original sound,
   system haptics, Reduce Motion-aware transitions, no feedback on every tap.
9. **Return summaries add navigation friction.** Existing notifications already
   route to objects. Let return-report events open their destination directly,
   rather than requiring a group drill-down before the relevant object.

## One-trade audit

| Moment | Intended feeling / decision | Current obstruction | Change |
| --- | --- | --- | --- |
| Fresh save / market | Curiosity; choose something to investigate | Controls and wallet dominate; no playable next step | Hunt prompt, compact cards |
| Several listings | Suspicion; compare claims, prices, sellers | Same art, repeated statistics | Distinct art, seller wording, claim caveat |
| Detail | Form a theory; risk versus price | Numeric report hierarchy | Price/claim/voice before reference details |
| Seller / offer | Read tone; ask or commit, push or accept | Input form and generic response rows | Bubbles, fatigue and counter emphasis |
| Purchase / delivery | Commitment then anticipation | Player remains on old screen | Receipt confirmation and delivery continuation |
| Inspection / finding | Reveal; revise what the item is worth | All information appears at once | Short staged reveal, defect emphasis |
| Repair / hold / as-is | Agency; invest more or stop | Repair action absent | Transparent immediate quote; optional hold by leaving |
| Publish / buyer wait | Anticipation; choose margin versus speed | Bare price field, no cost anchor | Investment context; direct live-listing link |
| Buyer / counter / sale | Tension then payoff | Offer competes with rows and messages | Offer panel, genuine metrics, visible net outcome |
| Profit / loss / return | Satisfaction or learning; another hunt | Invoice, no immediate next action | Signed net amount, explanation, market continuation |

## Acceptance boundary

Correctness, localized screenshot review and a complete UI journey are required.
Fun remains a qualitative hypothesis until the owner plays several unscripted
trades. Do not claim that automated coverage proves curiosity or retention.

## Acceptance review correction

The original clean starter disclosed its exact condition before buying and had
no fault, so inspection could not reveal a meaningful new fact. Fresh saves now
use one existing beginner-detectable port fault, an explicit untested-connections
clue and a purchase margin that supports repair or an as-is sale. This is one
introductory lesson, not a new category rule; later stock's random stream and
saved item truth remain unchanged. The initial generic repeat-trade UI was not
accepted as sufficient evidence for this first-experience requirement.

## Second visual acceptance pass — 20 October 2026

The implementation at `26874d3` already preserves the full loop, localization,
inspection pacing, repairs and result routing. Its captured screens still read
as a utility: the warm page, repeated white rectangles, small device thumbnails
and restrained receipt do not establish enough visual distinction between
browsing, risk, discovery and reward. Preserve the domain and improve presentation.

Ranked remaining problems:

1. Market chrome occupies too much of the first viewport; the hunt starts below
   a search bar, introductory panel and oversized watchlist panel.
2. Repeated horizontal rows feel like a catalog. Use collectible display cards,
   more prominent original art and multiple simultaneous opportunities.
3. Product silhouettes sit on flat pastel swatches. Give the existing original
   vectors a lit display stage and physical depth without implying hidden truth.
4. Price, claim and unknown information blend together in listing detail. Make
   the price dominant, seller evidence explicit and unresolved condition visible.
5. Generic person icons weaken seller/buyer identity. Give NPCs stable original
   portraits derived from public identity, with no fabricated traits or ratings.
6. Purchase confirmation disappears into dialogue history. Keep a commitment
   panel with the actual purchase amount and uncertainty alongside delivery.
7. Inspection and repair share ordinary information-card styling. Use numbered
   diagnostic stages, visible reveal progress and a distinct service decision.
8. Settlement is a white invoice. Put the signed result first, use a medal and
   contextual color, and retain the real costs and next-hunt action.
9. Inventory, messages, selling and away summaries retain native table styling.
   Carry the same surfaces, product displays and hierarchy through those areas.

Direction: an original after-hours trader's workbench. Ink-blue display stages,
warm paper, amber action buttons, restrained category light, tactile card edges,
compact display typography and high-contrast signed outcomes. Decorative geometry
must never encode rarity, condition or value that the player has not earned.
No new simulation scope; no architecture rewrite. Existing `26874d3` is the clean
checkpoint. The pre-existing root brief deletion is excluded from this work.
