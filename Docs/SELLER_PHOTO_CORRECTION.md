# Seller photography and readable product names

22 October 2026. Human feedback identified uniform staged desk photographs,
arbitrary invented names, clipped marketplace titles and side bands around photos.
The owner subsequently queued a comprehensive game-style visual redesign last;
that redesign has not started. The ordered work queue is in STATUS.md.

## Changes

- Replace all 56 original condition photos with distinct seller settings across
  14 product families: sofa, camera bag, bedspread, TV cabinet, armchair, office
  shelf, camera case, bookshelf, travel pouch, floor, felt-lined chest, blanket,
  shipping box and utility shelf.
- Add alternate environments for controllers, cameras and handhelds: 17 settings,
  68 packaged condition photographs, 9,481,744 JPEG bytes. This is family-level
  art; the 50 catalog models do not have 50 unique physical body designs.
- Select alternate scenes from public item identity. Reopening a listing,
  purchasing and inspecting it retain the same environment. Hidden condition,
  defects and inspection outcomes cannot choose a background. Cosmetic grades
  still follow seller claims or earned evidence as before.
- Render the full square photograph in square frames throughout market cards,
  item detail, shipping, inspection, inventory and transaction thumbnails. Remove
  the blurred side extensions. Neither cropping the product nor letterboxing is
  needed. Tall detail photos intentionally take more scrolling room.
- Use short fictional model names plus the actual product type in English and
  Turkish, such as Arc Wireless Controller / Arc Kablosuz Kontrolcü and Luma 3
  Camera / Luma 3 Fotoğraf Makinesi. All 50 definitions have translated display
  names, including notifications, history, trends and developer state screens.
  Card titles wrap to their full height. Both visible and legacy names remain
  searchable. Original definition IDs, seed metadata, saved truth, prices and
  existing agreements are unchanged.

## Runtime warning correction

The first two photo/layout runs each passed 117 unit and seven UI cases but
recorded eight audio-thread warnings. Those runs are not healthy checkpoints.
The simulator had sound enabled, exposing synchronous AVAudioSession setup and
AVAudioPlayer preparation in GameFeel on the main thread. Move session setup,
sample synthesis and playback to one dedicated serial queue, configuring the
ambient session once. Haptic calls remain on the main actor. The English first
trade test explicitly enables sound using process-local preferences, so this path
is covered even on a fresh simulator. The xcresult runtime-warning validator is
the regression signal; it rejected both pre-fix result bundles.

## Verification and limits

Final Debug test build and Release simulator build pass. All 117 unit tests and
seven focused UI journeys pass: EN/TR first trades, EN/TR category browsing,
large Turkish text/developer tools, English camera inspection and Turkish retro
inspection. Zero failures, skips or recorded runtime warnings; the SwiftUI invalid
frame warning is absent. The complete 53-case UI suite was not rerun here. The
normal Release build installs and launches with the existing simulator save.

Final validation is recorded in ../../Artifacts/SellerPhotoCorrection-2026-10-22/.
checkpoint.xcresult is the authoritative post-audio-fix run; release-final.log
is the final Release simulator build. Earlier visual-final/square-final bundles
retain the red runtime-warning evidence. Source atlases, generation prompts,
hashes, photo catalog and UI screenshots are retained beside these results.
SELLER_PHOTO_CORRECTION_PROMPTS.json records the exact committed art provenance.

Both EN/TR catalogs validate 539 keys. The main brief's SHA-256 remains
3c25a9763af35e494c9c6d340f4784ef59759f85133bcb46dd351d7487aeb582.
The app icon remains the previously committed generated icon.

This correction changes presentation and audio execution only. The human report
that repeat trading feels too random/frustrating is still open; do not describe
it as resolved by these automated checks. Physical-device sound, haptics and
performance remain unverified. Largest accessibility text makes the existing
market cash header wrap awkwardly; include that in the queued interface redesign.
No progression, retention systems, monetization or analytics infrastructure added.
