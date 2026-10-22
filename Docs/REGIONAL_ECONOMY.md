# Shared economy and localized currency

Updated by user direction, 2026-10-22: **one market for every language**, with localized presentation and selectable display currency. Previous TR/US market separation has been retired. The historical filename is kept so existing links continue to work.

## One source of value

`Money.minorUnits` is canonical USD cents. Every language and currency uses the same catalog, supply, pricing, risk, fee, career gates and trading mechanics. Market trends may still vary over time and between category/model scopes; locale never causes that variation. `MarketConfiguration.multiplier(for:)` is 10000 for all categories. Fixed fictional FX is 1 USD = 40 TRY, entirely offline. Currency conversion is used only when displaying or parsing entered prices.

A $1,000 bankroll displays as ₺40,000 in TRY, with the same buying power. English defaults to USD and Turkish to TRY for a new career; the saved display selection can be changed in Profile → Currency & language. Changing language does not overwrite an explicit saved currency preference. The app language follows the iPhone's per-app language setting.

`MarketRegion` and its serialized `unitedStates` tag remain only for compatibility with existing saves; they no longer select a country economy or appear in the UI. `.turkey` is an internal compatibility spelling for the same shared market with TRY presentation. New languages require translation and, where justified, currency-format support—not new regional price profiles.

## Shared fictional world

Seller/buyer identity indices remain stable. `people.name.<index>` and `people.city.<index>` provide localized presentation independent of currency or legacy region. English and Turkish have natural character names and corresponding fictional neighborhoods: Old Town / Eski Çarşı, Riverside / Dereboyu, and so on. They are not real-country markets. Product identities, model truths, character continuity, saved relationships and all economic effects remain stable when language changes.

## Existing saves

Version-1 configurations migrate to version 2 at repository load. A complete `pre-shared-market-v3.json` backup is written once before the change. All cash, paid costs, inventory, quotes, offers, timers and receipts remain byte-for-byte equivalent as domain values. The previous display currency is preserved. An in-game notice explains the shared market for prior Turkish-profile saves.

Previously generated regional listings and explicit commitments retain their historical amounts until normal market turnover. Future listings and uncommitted price estimates use shared rules. We do not rewrite a past transaction or silently take cash away to impose a new price profile. The earlier legacy-credit 20:1 migration is still supported for much older saves and retains its own separate backup and notice.

## Weekly competition

Weekly Flip uses the same shared pricing engines, a fixed bankroll and a common weekly seed. It resets expertise and keeps its own inventory, timers and receipts in a separate repository. Display currency follows the player's saved preference without changing TraderScore. Score is an integer measure of normalized performance, never localized money. See [Game Center setup](GAME_CENTER_SETUP.md).

## Verification

Shared-market tests assert identical generated listings/player state in USD and TRY; conversion/parser tests retain canonical round trips. Migration tests preserve old money and active agreements, verify the backup and prove idempotence. The 10,000-listing price/buyer-budget sweeps and longer trading simulations still run in both currency configurations. UI tests cover both languages, currency switching, shared-market copy and persisted display preferences.
