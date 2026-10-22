# Localization authoring and QA

English (`en`) and Turkish (`tr`) are required launch languages. Use stable language-independent semantic keys in `Localizable.xcstrings`, translated units and translator comments. Dialogue variants share intent, not literal sentence structure. The root glossary defines approved terms.

Keep names, locations and dialogue in locale content packs; product brands stay consistent. Locale must not affect simulation outcomes. Avoid arbitrary sentence fragments. Use complete format strings and locale-aware numbers, currency, time, percentages and plural rules. Do not implement German/Japanese content during MVP; allow expansion without engine changes.

Before each content milestone run `python3 Scripts/check_localization.py`. Runtime localization tests check bundled strings and UI tests launch both languages. Before release, check every main flow in both languages, long German-like expansion using Xcode pseudolanguage, largest accessibility text sizes, plural counts (0/1/many), numbers/currency and notification content. Production must not display missing keys. Review marketplace writing independently in both languages and localize App Store/Game Center metadata separately.

Catalog entries use manual extraction. GameText resolves seller voices, findings and result intents dynamically, so Xcode cannot infer their usage from static Text calls. Keep extractionState set to manual; the localization check rejects missing/stale automatic entries as well as missing translations, translator context and mismatched format arguments.

The trading-feel UI runs exercise Turkish and English marketplace claims, seller questions/counters, discovery, repair, buyer counters and profit/loss. DEBUG-only launch flags cover accessibility text, dark appearance and the same reduced-motion paths used by the platform preference. Release always honors the platform preference. Xcode's pseudolanguage launch option remains available for expansion checks; no additional launch languages are implemented.

The owner requested USD ($) for English and TRY (₺) for Turkish on 22 October
2026. Money.formatted is the shared currency-display path for screens, ledgers
and notifications. This changes formatting only; saved integer values and pricing
do not depend on language, and switching locales performs no exchange conversion.
