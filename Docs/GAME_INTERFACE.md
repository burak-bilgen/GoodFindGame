# Night-market theme and animation pass

22 October 2026. The owner requested a game-like visual direction, a cohesive
animation pass and removal of leftover white/system-app surfaces across all routes.
This completes the final authorized implementation item; human visual/gameplay
acceptance remains open. No new gameplay or progression system was added.

## Shared appearance

GameTheme applies the dark appearance and tint at the window boundary, including
native controls, sheets and keyboard presentation. GameStyle owns panel, border,
button, field and background styles. Named accent/category/launch colors are the
shared palette. GameList and GameForm preserve native interaction while using
the same panel colors. GameBackdrop supplies the static instrument grid.

Deep petrol blue replaces warm paper. Mint marks interaction, amber marks primary
actions and money context, coral marks losses and category accents retain meaning
through accompanying text/icons. Category/accent text contrast against the lighter
panel endpoint ranges from 4.94:1 to 9.01:1. Contrast calculations are retained in
the evidence directory. Native launch appearance is Dark; the compiled launch
storyboard uses the same named background as GameStyle.ink.

The custom five-button dock keeps the existing TabView navigation stacks and
notification routing. Its buyer badge counts actual waiting offers. It occupies
its own layout space so purchase actions remain visible above it; it hides while
the keyboard is shown. Accessible tab labels and selected traits remain available.
The marketplace cash layout stays on one line at large text sizes. Full square
product photos and complete wrapping product titles are preserved.

Reviewed surfaces: marketplace/search/filters, listing and seller information,
seller conversations, purchase confirmation, messages, inventory/shipping, basic
and expert reports, item facts, repair decisions, resale pricing, live offers,
profit/loss/receipts, trade history, profile, tools/knowledge, market trends,
notification settings, return summaries, notification destination sheets and
unavailable destinations. DEBUG tools use the same palette and remain DEBUG-only.

## Motion

- Decorative marketplace radar rotates independently of stock; it predicts no deal.
- Panels, menu rows and new message bubbles fade in without moving tap targets.
- Buttons compress with a spring; dock selection slides and tab icons bounce.
- Status stamps bounce on actual state changes; existing numeric cash/price/result
  transitions remain in place.
- Pending replies, shipping and inspections have moving indicator lights. These
  indicate pending work, never fabricated completion percentages or buyer counts.
- The earned inspection reveal uses the scanner before its final evidence icon.
- Profit/loss panels have brief, noninteractive amber/mint or coral particles.
  No invented coins, XP, bonuses or extra money accompany the particles.

Custom animation honors GameReduceMotion: radar/lights become static, springs,
bounces and bursts stop, and report evidence appears immediately. Timeline drawing
pauses when the scene is inactive. No control position changes during entry fades.
Native navigation continues to honor the platform's accessibility preferences.

The owner also requested dollars for English. Shared Money formatting now uses
USD ($) for English and TRY (₺) for Turkish, including signed results and notifications.
Saved integer amounts and agreements do not change when switching languages.

## Verification

Debug and Release simulator builds pass. Across the full two-shard run and targeted
follow-ups, all **121 unit tests and 55 distinct UI tests** have passing outcomes,
zero skips and zero recorded runtime warnings. The SwiftUI invalid-frame warning
is absent. All 540 EN/TR keys validate; the original main brief is unchanged.

The initial full run identified two test assumptions that offscreen content implied
another navigation level. Both were updated to scroll the appropriate root list;
their large-text and concurrent-production journeys passed on retry. A concurrent
unit probe interrupted the Turkish repair/loss test; its isolated retry passed.
Do not describe the initial full bundles as single green runs. verification.json
checks the complete distinct-test set and records the successful follow-up for
each affected case. The final units include USD/TRY/signed formatting checks.

The last launch/appearance follow-up passes English first trade plus EN/TR surface
tours, including full-height destination sheets. A screenshot helper samples the
screen margins to detect accidental bright backgrounds outside product photography.
Forty-five review captures and a 43-second simulator motion clip are retained.

Evidence: ../../Artifacts/GameInterface-2026-10-22/. Authoritative files:
verification.json, final-followup.xcresult, launch-final.xcresult,
release-launch-final.log, source-proof.json, review.html and game-motion.mp4.
The preceding behavior correction is separately recorded in FAIR_TRADING.md.

Remaining validation: unscripted human fairness/pace/enjoyment and visual taste;
physical-device motion performance, haptics/audio and iOS 17 runtime. Simulator
success does not establish these. Progression, Game Center, monetization,
collections, client requests and analytics remain paused.
