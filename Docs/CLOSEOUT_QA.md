# Shop, catalog and UX closeout — 2026-10-23

The implemented scope and deliberate deferrals are in ACTIVE_BACKLOG.md.

## Verification

- Earlier shop/catalog integration: 14 targeted unit checks passed; one Turkish shop opening/persistence/settings UI scenario passed before the final UX additions.
- Final UX app Debug build succeeded. The first final test attempt could not compile a new test because a throwing load was nested incorrectly in `#require`; fixed by loading before the assertion. This was a test-source issue, not an app crash.
- Final focused run `/tmp/ProjectFlip-closeout-23.xcresult`: 10 unit checks and the Turkish shop/profile/settings/tab-reselection UI scenario passed. One calendar-migration test failed at two outdated assertions that incorrectly substituted active feed categories for historical catalog categories. The calendar correctly retains all definitions for legacy saves.
- Corrected only those test expectations; `/tmp/ProjectFlip-catalog-closeout-23.xcresult`: all 5 ContentTests passed. Across these two runs, all 11 selected unit checks and the 1 selected UI scenario passed. No recorded runtime warnings in either result. The passing UI scenario was not rerun.
- Final incremental Release simulator build succeeded (`/tmp/ProjectFlip-release-final-23.log`). Packaged Localizable.strings resources are English and Turkish only. Profile screenshot inspected with persisted name/avatar and no duplicate profile title.
- Localization completeness: 884 English/Turkish keys pass the catalog check. All partial German/French entries were removed from shipping resources and preserved in the 361-row draft, preventing accidental partial language exposure.
- No broad suite rerun, per the owner's request to minimize testing cost.

## Screen audit

| Surface | Change / disposition |
| --- | --- |
| Market | Preserves established buying flow; filters exclude categories with no photographed stock. |
| Messages | Actionable buyer offers, active/archive switch, unread state and real activity ordering. |
| Inventory | Compact 72pt thumbnails including shipments; stock filter and used capacity. |
| Shop | Named storefront remains meaningful; duplicate generic banner removed. |
| Profile | Editable personal identity, avatar and earned optional title. |
| Settings | Currency, system language shortcut, sound, notification settings and save/version information. No developer screen. |
| Career / Clients / Sales / Recovery | Removed duplicate title banners; existing decision and economic flows retained. |
| Inspection | One reference photo; condition and discovered defects explained by findings, not photo switching. |
| Competition | Distinct weekly identity retained; external signed Game Center acceptance still pending. |

Tab reselection uses root recreation, not a timed double-tap recognizer. It resets the selected root's local filters while preserving other tabs. Four existing avatar variations are offered; this is not an avatar-upload feature.

## Art

Built-in image generation was used earlier in the session. Generation was stopped on the owner's instruction. `PHOTO_SOURCES.json` records selected source and packaged output paths. Final files are in `ProjectFlip/Resources/Assets.xcassets/Product-model-*.imageset/photo.jpg`.

Prompt set: one square candid phone photograph of the named ordinary household product, plausible construction, entire object visible, incidental home background, uneven natural daylight and mild camera grain; no studio/CGI appearance, people, logos, watermark or collage. Subjects: drip coffee maker, canister vacuum, kettle, toaster, pedestal fan, blender, steam iron, sewing machine, air fryer, espresso machine, round side table, two-seat sofa. Views varied between overhead, side and three-quarter angles. Existing dining-chair and controller photos are also retained. JPEG packaging scales to at most 768px, quality 0.74, without artwork edits.

Packaged asset catalog: approximately 5.6 MiB after the additional household photos (the earlier 3.6 MiB figure predates them).
