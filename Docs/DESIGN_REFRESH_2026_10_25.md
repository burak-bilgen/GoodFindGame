# Visual refresh — 25 October 2026

The owner requested a revision of the interface, photography, fonts and colors. This refresh follows the integrated 271-test mechanics checkpoint; that earlier result certifies its own source snapshot, not the later presentation changes.

## Implemented

- Warm charcoal surfaces, ivory text and restrained sage accents. Amber remains an attention/risk color and loss retains a separate warm red.
- SF system typography with Dynamic Type, replacing rounded heavy/black headings. Prices retain exact decision amounts and monospaced digits where useful.
- Flat panels with quiet borders; remove the background instrument grid, ornamental top bars and extruded button shadows.
- Product-first market cards with larger edge-to-edge photos and simpler titles/prices. Keep seller identity, public description and asking price readable.
- Balance/career above search; search placeholder has explicit readable contrast. The same filtering, inventory and trading behavior remains.
- Quieter outlined navigation icons and a subtle selected-tab surface. Existing 44pt controls, large-type icon-only navigation and scroll clearance remain.
- Listing-detail photo expands from 180pt to up to 320pt, with a compact 240pt cap at accessibility text sizes. The seller-photo disclosure and earned condition evidence remain separate.
- Remove presentation-based photo rotation/tint/desaturation so object framing and lighting stay consistent.
- Review all 56 packaged catalog photographs. Revise five shared families: controller, console, monitor, camera and lens. These use clearer full-object composition, warm grey surfaces and consistent soft daylight. Other appropriate model-specific photos remain.

## Artwork and evidence

[Photo provenance](ART_REFRESH_2026_10_25.json) records the revised assets, before/master/output hashes and built-in image generation prompts. The project consumes packaged JPEGs; originals, prior photos and exact prompts are retained under `../../Artifacts/DesignRefresh-2026-10-25/`.

A fixed photograph remains selected by product identity. Neither hidden defects nor cosmetic grade select a different asset. Photographs are decorative for accessibility; product identity and earned facts remain native text.

Shared static text/surface contrast measurements: ivory 14.51:1, secondary text 8.81:1, sage 10.59:1 and amber 10:1 against the panel; dark text on the primary sage action is 12.07:1. Measurements are retained in `contrast-review.json`; they do not establish physical-device accessibility acceptance.

## Repair-action continuity

The initial visual checkpoint exposed one actual large-text regression: removing a completed repair card shortened the page while preserving its old offset, leaving the sale action above the visible region. The failure hierarchy placed `createListing` at y=-15 on the Inventory screen; no navigation had occurred. `OwnedItemView` now anchors a successful repair to the next known repair, or the sale decision when none remains. Reduce Motion is honored. The original test was unchanged and passed after this fix. The initial 12-pass/1-failure bundle remains diagnostic evidence; it is not described as an all-green result.

## Verification

The initial checkpoint passed 12 cases and exposed the repair-scroll failure described above. The unchanged large Turkish repair/trade passed after the fix; the subsequent four-case iOS 27 checkpoint passed the connected trade, Turkish theme and both repair-planner journeys without runtime warnings. Market, profile, settings and repaired large-text captures were visually inspected.

A separate iPhone 16e / iOS 26 run passed the Turkish theme case but exposed a second accessibility-size problem: the square market photo pushed identity and price below the viewport and made the first card difficult to activate. Accessibility-size cards now use an 88pt photo beside the full product/category/price headline, with the description below. Standard-size cards keep their larger square photos. The original large Turkish repair/trade test passed unchanged after this fix (`minimum-compact26.xcresult`, zero runtime warnings). Diagnostic red results remain retained.

The final Pazlume-branded app passed all 271 tests (186 unit / 85 UI), with no failures/skips/runtime warnings, followed by the successful unsigned device Release build. A clean unsigned archive and normal Release simulator launch also succeeded. A screenshot-only helper settling delay then corrected one mid-transition German capture; the focused German/French retake passed. No shipping source changed after the broad checkpoint. [Pazlume readiness](PAZLUME_V1_READINESS_2026_10_25.md) records the complete result and thirty reviewed final store images.

Previous release archives/store captures remain historical artifacts. The 24 October unsigned archive does not include this design refresh. GitHub Pages publication and Apple signing remain owner-deferred.
