# Pazlume 1.0 — release preparation, 25 October 2026

**Checkpoint scope:** the owner subsequently requested more development. [Current gameplay expansion](GAMEPLAY_EXPANSION_2026_10_25.md) supersedes this source snapshot; the evidence and packages below remain retained unchanged.

## Public identity

The public name is **Pazlume**. [Name research](NAME_RESEARCH_2026_10_25.md) records general/indexed game-store searches and direct Apple Search API checks in six storefronts. No exact public title was found in those checks. This is not global exclusivity, trademark clearance or an App Store Connect reservation.

The Home Screen display name, notification title in all six languages, Settings identity, six App Store metadata files and generated support/privacy pages use Pazlume. The original production bundle ID, save path, migrations, internal target/scheme names and service identifiers remain stable to preserve player data.

The new opaque 1024px app icon depicts a sage controller in a resale box with a return tag. The built-in generation master, exact prompt, prior icon and provenance are retained in `../../Artifacts/Pazlume-v1-2026-10-25/`. Website artwork is generated from that same packaged icon.

## Final source verification

The complete final branded app passed **271 tests: 186 unit and 85 UI**, with zero failures, skips or recorded runtime warnings. `Scripts/verify.sh` completed successfully, including the unsigned generic-device Release build. The complete result, summary, test tree and build logs are retained in `../../Artifacts/Pazlume-v1-2026-10-25/verification/`.

The separate current unsigned device archive also built successfully. Its packaged Pazlume display name and all 926 keys in six languages passed the release checker. The checker correctly rejects only the deferred public URLs and missing Apple signature.

Visual QA of the first 30 exported store images caught a German detail image taken during a native navigation transition. The game itself and its test assertions passed. The language screenshot helper now waits 0.5 seconds before capture, matching the existing main-trade helper; no shipping source changed. The focused German/French retake passed (one test, zero failures/skips/runtime warnings). The final 30-image set uses its ten settled German/French frames plus twenty captures from the broad checkpoint. All six language contact sheets were visually inspected; selected full-resolution Market, buyer, result and detail screens were also inspected. The 271-case checkpoint remains preserved rather than overwritten by this narrower artifact correction.

The current presentation also has focused red/green evidence for two accessibility-size bugs: successful repairs now reveal the next action, and small-screen market cards keep the product name/price beside a compact photograph. [The design record](DESIGN_REFRESH_2026_10_25.md) describes these fixes and retains the original failures.

The normal optimized Release simulator build also succeeded. It was installed on a fresh iPhone 18 Pro / iOS 27.2 simulator and launched in Turkish without any test-fixture flags. The actual Market and SpringBoard captures were visually inspected: product photos, names/prices, dock, public name and small app icon render clearly. `normal-release-smoke.json` records the scope; this does not replace a physical-device test.

The [current Apple screenshot specification](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications) was rechecked on 25 October: the iPhone Dynamic Island medium-display group accepts 1206 × 2622 portrait captures. The new store set uses unmodified actual iPhone 18 Pro captures at that size; no iPad set is needed for this iPhone-only build.

The reviewed images are in `StoreScreenshots/`, with a per-file hash and source-result record. `StoreScreenshots-initial/` and the original review sheets retain the rejected transition capture as diagnostic evidence. `Pazlume-AppStore-Materials.zip` collects the six store metadata files, thirty reviewed images, packaged icon, review notes and public-site ZIP. It contains no signing material, IPA or player saves.

## Submission boundaries

The owner requested finishing the game first, then handling publication together. No page deployment, account login, name reservation, signed upload or review submission has been performed in this preparation. The support email is confirmed as bilgenburak@outlook.com. Privacy/support URLs remain null until the real GitHub Pages site is deployed and checked. The new ZIP contains the prepared static six-language site only.

Next publication work requires the actual Pages URLs, Apple Developer signing/provisioning, a physical-device check and the App Store Connect record/questionnaires. The local archive is intentionally unsigned and must not be described as upload-ready. Unassisted human enjoyment, physical haptics/VoiceOver and external native-language editorial review remain unobserved.
