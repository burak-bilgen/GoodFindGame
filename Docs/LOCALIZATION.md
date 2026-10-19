# Localization authoring and QA

English (`en`) and Turkish (`tr`) are required launch languages. Use stable language-independent semantic keys in `Localizable.xcstrings`, translated units and translator comments. Dialogue variants share intent, not literal sentence structure. The root glossary defines approved terms.

Keep names, locations and dialogue in locale content packs; product brands stay consistent. Locale must not affect simulation outcomes. Avoid arbitrary sentence fragments. Use complete format strings and locale-aware numbers, currency, time, percentages and plural rules. Do not implement German/Japanese content during MVP; allow expansion without engine changes.

Before each content milestone run `python3 Scripts/check_localization.py`. Runtime localization tests check bundled strings and UI tests launch both languages. Before release, check every main flow in both languages, long German-like expansion using Xcode pseudolanguage, largest accessibility text sizes, plural counts (0/1/many), numbers/currency and notification content. Production must not display missing keys. Review marketplace writing independently in both languages and localize App Store/Game Center metadata separately.

Task 1 has no dynamic quantities, money or notifications yet. Add targeted formatting/plural/notification tests when those systems enter their scheduled phase. A custom pseudo-localization mode is optional; Xcode's pseudolanguage launch option is sufficient for initial layout QA.
