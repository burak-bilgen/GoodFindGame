# Pazlume 1.0 submission package

The source is prepared for an offline-first iPhone release, iOS 26+, in English, Turkish, German, French, Spanish and Italian. All 80 catalog products have a packaged photo mapping, using 56 photographs. Six client stories contain eighteen requests and award cosmetic profile titles. The career and weekly challenge use separate local saves. There are no ads, purchases, player-account registration or developer-operated backend.

GitHub Pages is the chosen hosting route; publication and Apple signing were deferred by the owner. The confirmed support email is `bilgenburak@outlook.com`. See [the ready-to-upload Pages package and steps](GITHUB_PAGES.md).

## Publisher information and signing

`Publisher.json` contains the confirmed support email; public privacy/support URLs stay null until the GitHub Pages deployment is verified. The app includes offline privacy/help screens and its contact link. Custom bundle metadata is merged from `Configuration/AppInfo.plist`; editing an arbitrary `INFOPLIST_KEY_*` build setting does not reliably package a custom key.

1. Rebuild the prepared static pages with `python3 Scripts/build_support_pages.py`, then package them with `python3 Scripts/package_github_pages.py`.
2. Publish the pages on GitHub Pages using `GITHUB_PAGES.md`; verify the actual HTTPS privacy/support pages and enter those addresses in `Publisher.json`. All six translations are static, with no trackers or embedded third-party scripts.
3. Run `python3 Scripts/configure_publisher.py` to merge the verified publisher details into `Configuration/AppInfo.plist`. Rebuild before checking the packaged app.
4. Sign in to the Apple Developer account in Xcode → Settings → Accounts. The production bundle ID remains `gameproject.bilgenworks.ProjectFlip`; the existing configured team is `Z8P38BHKU6`.
5. Rebuild a signed Release archive after applying publisher contact details. Never submit the separate `.Acceptance` hardware-test bundle.
6. Run `python3 Scripts/check_release.py --app <archive>/Products/Applications/ProjectFlip.app --check-urls`. This gate rejects missing publisher information and invalid/absent signatures.
7. Confirm current Apple account agreements, privacy answers, review contact, distribution regions, pricing, content rights and age questionnaire in App Store Connect. Upload the signed build, select the screenshots and localized metadata, and use manual release after review. No upload or public submission is performed by these scripts.

The current gameplay-expansion unsigned archive is kept in `../../Artifacts/GameplayExpansion-2026-10-25/ProjectFlip-layout-final.xcarchive` (relative to this document). The prior Pazlume-v1 archive is historical. Unsigned archive success proves device compilation and packaging, not App Store upload acceptance.

## Store materials

- `AppStore/*.json`: six complete localized descriptions, subtitles, promotional text and keywords, checked against field lengths.
- `Website/`: publishable support/privacy page sources, regenerated from the same localized policy shown in the app. Apply real publisher contact details before publishing.
- `REVIEW_NOTES.md`: reviewer access and gameplay instructions.
- The earlier branded checkpoint passed all 271 tests under `../../Artifacts/Pazlume-v1-2026-10-25/verification/`. Thirty reviewed store images are in `StoreScreenshots/` in that artifact folder; ten German/French captures use the passing screenshot-only retake. `Pazlume-AppStore-Materials.zip` collects that historical snapshot’s upload materials. The earlier `ReleaseCandidate-2026-10-24` set predates the new design. Use actual gameplay captures, with no fabricated rankings, products or offers.

## Online competition

The 1.0 release uses local Weekly Flip scores and local achievements. Online Game Center controls are hidden by default, the network monitor is inactive, and the shipping entitlements do not request Game Center. The existing adapter remains for a later verified enablement. Enabling `OnlineCompetitionEnabled` also requires restoring the Game Center entitlement, configuring App Store Connect resources and passing the signed sandbox procedure in `Docs/GAME_CENTER_SETUP.md`. Do not advertise online leaderboards in this release.

## Privacy and content questionnaire preparation

No developer-operated endpoint, analytics SDK, advertising ID collection, tracking or user-to-user messaging is present. Names, avatars, game state and settings stay on device. Apple device backups are governed by the user's Apple settings. No in-app account is created. All prices and cash are fictional, with no real-money transactions, cash-out, betting or prizes. Product art is bundled static artwork, not user-generated content or live AI output. Complete Apple's current questionnaire from these facts; do not substitute a guessed age rating.

The privacy manifest declares UserDefaults for app-owned settings and reveal/read state (`CA92.1`); no tracking or developer-collected data types are declared. The encryption declaration is `ITSAppUsesNonExemptEncryption=NO`: there is no custom cryptography or third-party network library.

## Official references checked 24 October 2026

- [App Review completeness, accurate metadata and privacy](https://developer.apple.com/app-store/review/guidelines/)
- [Common submission issues and support/privacy links](https://developer.apple.com/app-store/review/)
- [Required-reason privacy APIs](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitype)
- [App privacy declarations](https://developer.apple.com/app-store/app-privacy-details/)
- [Screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications)
- [Submitting a build for review](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-app)

## Current gameplay expansion materials

Use `../../Artifacts/GameplayExpansion-2026-10-25/Pazlume-Gameplay-Update-Materials.zip` for the updated localized descriptions/review notes, original 30 store PNGs, icon and prepared Pages package. See `START_HERE.md` and `verification.json` in that artifact directory for scope, hashes and the final archive. Current acceptance includes all 202 unit tests plus focused UI checkpoints; do not describe their overlapping totals as a new complete-suite run. The original 271-test complete-suite result applies to the preserved earlier source.
