# German / French delivery — 2026-10-23

All 884 catalog keys now have English, Turkish, German and French translations. German/French are registered in the Xcode project and the dynamic GameText resolver; unsupported languages fall back to English. Locale variants such as fr-CA resolve the French catalog. Currency remains an independent saved preference, and translations do not change prices, stock, difficulty or the saved fictional identities.

## Editorial conventions

- Informal singular address: German **du**, French **tu**. Seller voices retain distinct attitudes; system instructions remain direct and clear.
- Stable fictional brands/models (Veltri, Nuvoro, Chapter, Focal, etc.) are preserved. Descriptive household product nouns are translated. Paused products remain translated for legacy inventory, without reactivating their listings.
- Shared fictional districts are translated (Old Town → Altstadt / Vieille Ville); individual display names have locale-appropriate equivalents while stable identity indices and client IDs stay unchanged. Historical unused real city names remain proper nouns.
- Inspection results distinguish unknown, seller-claimed and verified facts. Estimated profit is never promised. The two seller lines that implied individual photographic proof were corrected in EN/TR as well, because the game uses fixed model reference photos.
- All three existing pluralized entries include explicit German/French one/other forms. Format placeholders are unchanged; Game Center thresholds retain canonical USD units rather than silently altering requirements for a language.

The shipping source of truth is `ProjectFlip/Resources/Localizable.xcstrings`. `de-fr.tsv` is an editorial snapshot of the non-plural entries; plural variants live in the catalog. `game-center-metadata.tsv` is a copy worksheet for the owner, not an upload script or a claim that live Game Center is configured.

## Focused verification

- Catalog checker: all 884 keys complete in all four languages; translator context, manual extraction and format arguments verified.
- `/tmp/ProjectFlip-languages-23.xcresult`: 2 selected tests passed, no failures or recorded runtime warnings. One runtime test covers German/French dynamic content, localized people/places/product names, notification placeholders, locale variants and unsupported-language fallback. One UI scenario launches both languages, navigates Market → Profile → Settings and captures screenshots.
- German and French Settings screenshots inspected: localized navigation/tab labels and wrapped explanatory copy remain legible without clipped controls.
- No broad gameplay regression suite rerun: the economy and simulation were not changed.

This is a completed authored translation with focused integration checks, not native-player linguistic acceptance. Whole-app accessibility-size/VoiceOver review and remote Game Center presentation in each language have not been exhaustively verified. RTL languages are not enabled.
