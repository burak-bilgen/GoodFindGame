# Public game name research — 25 October 2026

## Recommendation

**Pazlume** is the recommended public name. It has seven ASCII letters, fits comfortably on the Home Screen and leaves App Store title space for a localized description. Suggested pronunciation is “paz-loom”; Turkish readers can say “paz-lum.” The intended association is **pazar + a soft glow / an overlooked object becoming valuable again**. This is an invented brand rationale, not a claimed dictionary etymology. It suits the cozy but strategic secondhand trading, inspection, repair and resale loop better than the generic working title Project Flip.

The evidence supports the narrower statement **“no exact public use found in the checked game/app sources and general indexed web searches on this date.”** It does not establish global exclusivity, trademark clearance, domain availability or App Store name reservation.

Use Pazlume publicly while retaining internal bundle identifiers, save directories, migration identifiers and Xcode target names. This research does not authorize publishing or alter any account.

## First-party App Store checks

Apple's public Search API was queried directly with `entity=software&limit=200` in US, Turkey, Germany, France, Spain and Italy. Apple documents country-scoped search, software entities and returned `trackName` values in its [Search API documentation](https://performance-partners.apple.com/search-api). Searches can be fuzzy; a nonzero `resultCount` is not itself a title collision. We compared every returned title case-insensitively against the candidate. There were no request errors.

| Candidate | Country | Returned apps | Exact title matches | Direct source |
| --- | --- | ---: | ---: | --- |
| Pazlume | US | 11 | 0 | [Apple JSON](https://itunes.apple.com/search?term=Pazlume&country=us&entity=software&limit=200) |
| Pazlume | TR | 0 | 0 | [Apple JSON](https://itunes.apple.com/search?term=Pazlume&country=tr&entity=software&limit=200) |
| Pazlume | DE | 0 | 0 | [Apple JSON](https://itunes.apple.com/search?term=Pazlume&country=de&entity=software&limit=200) |
| Pazlume | FR | 0 | 0 | [Apple JSON](https://itunes.apple.com/search?term=Pazlume&country=fr&entity=software&limit=200) |
| Pazlume | ES | 0 | 0 | [Apple JSON](https://itunes.apple.com/search?term=Pazlume&country=es&entity=software&limit=200) |
| Pazlume | IT | 0 | 0 | [Apple JSON](https://itunes.apple.com/search?term=Pazlume&country=it&entity=software&limit=200) |
| Paznook | US | 13 | 0 | [Apple JSON](https://itunes.apple.com/search?term=Paznook&country=us&entity=software&limit=200) |
| Paznook | TR | 0 | 0 | [Apple JSON](https://itunes.apple.com/search?term=Paznook&country=tr&entity=software&limit=200) |
| Paznook | DE | 0 | 0 | [Apple JSON](https://itunes.apple.com/search?term=Paznook&country=de&entity=software&limit=200) |
| Paznook | FR | 0 | 0 | [Apple JSON](https://itunes.apple.com/search?term=Paznook&country=fr&entity=software&limit=200) |
| Paznook | ES | 0 | 0 | [Apple JSON](https://itunes.apple.com/search?term=Paznook&country=es&entity=software&limit=200) |
| Paznook | IT | 0 | 0 | [Apple JSON](https://itunes.apple.com/search?term=Paznook&country=it&entity=software&limit=200) |
| Tinkrove | US | 0 | 0 | [Apple JSON](https://itunes.apple.com/search?term=Tinkrove&country=us&entity=software&limit=200) |
| Tinkrove | TR | 0 | 0 | [Apple JSON](https://itunes.apple.com/search?term=Tinkrove&country=tr&entity=software&limit=200) |
| Tinkrove | DE | 0 | 0 | [Apple JSON](https://itunes.apple.com/search?term=Tinkrove&country=de&entity=software&limit=200) |
| Tinkrove | FR | 0 | 0 | [Apple JSON](https://itunes.apple.com/search?term=Tinkrove&country=fr&entity=software&limit=200) |
| Tinkrove | ES | 0 | 0 | [Apple JSON](https://itunes.apple.com/search?term=Tinkrove&country=es&entity=software&limit=200) |
| Tinkrove | IT | 0 | 0 | [Apple JSON](https://itunes.apple.com/search?term=Tinkrove&country=it&entity=software&limit=200) |

Pazlume's 11 US results were unrelated titles, not an app called Pazlume. The titles returned were: RADIO PAZ 830 AM; antrapuse.lt - Rimtos Pažintys; Public Art La Paz; Pazarama İş Ortağım; pazutto: Ad-Free Logic Puzzles; Ministério Paz e Vida; Iglesia Vida y Paz; Pazzazz Music; Vitória e Paz; SOP: Rotina e Fluxo do Dia; PAZARIM. Turkey and all four continental European storefront requests returned `resultCount: 0`.

## Indexed web and game-store search log

Exact quoted queries were run through the available web search service. These are observations of that service's response on the research date, not first-party store inventories. A store-site search checks only indexed public pages. No direct authenticated App Store Connect reservation was attempted.

| Exact query | Observed response |
| --- | --- |
| `"Pazlume"` | Empty search results |
| `"Pazlume" site:apps.apple.com` | Empty search results |
| `"Pazlume" site:play.google.com` | Empty search results |
| `"Pazlume" site:store.steampowered.com` | Empty search results |
| `"Pazlume" trademark` | Empty search results; not a trademark database search |
| `"Paznook"` | Empty search results |
| `"Paznook" (site:apps.apple.com OR site:play.google.com OR site:store.steampowered.com)` | Empty search results |
| `"Tinkrove"` | Lithuanian text/OCR matches, not a game/app brand found |
| `"Tinkrove" (site:apps.apple.com OR site:play.google.com OR site:store.steampowered.com)` | Empty search results |
| `"Pazvori"` | Empty search results; exploratory only, no direct API check |
| `"Pazvori" (site:apps.apple.com OR site:play.google.com OR site:store.steampowered.com)` | Empty search results; exploratory only |

To reproduce the store queries directly, use [Apple's public app search](https://apps.apple.com/us/search?term=Pazlume), [Google Play's app search](https://play.google.com/store/search?q=Pazlume&c=apps) and [Steam's store search](https://store.steampowered.com/search/?term=Pazlume). Those links are reproduction endpoints, not assertions that their interactive result pages were inspected in this run; the App Store's first-party evidence above comes from its JSON API.

## Fallbacks

1. **Paznook** — also seven ASCII letters; pazar plus a cozy trading corner. No general exact web result and no exact App Store title among the six API checks. It is weaker than Pazlume because “nook” is a familiar word/name in entertainment and does not evoke restored value as clearly. US API returned 13 fuzzy results, none exactly Paznook; the other five storefronts returned zero.
2. **Tinkrove** — tinker plus trove; a strong repair-and-discovery association, with zero software results in all six API checks. It is weaker than Pazlume because exact web search finds Lithuanian text/OCR occurrences and the consonant cluster is less easy to pronounce internationally. This is a fallback with known text matches, not a claim of an unused word.

## Eliminated candidates and observed collisions

- **DealWisp** is an existing commercial software product. The owner's [product page](https://treevoxa.com/products/) lists DealWisp as a branded offers/business-page product, and its [pricing page](https://treevoxa.com/pricing/) sells DealWisp plans. Reject.
- **Flivora** is already used by an Android TV application on its [Google Play listing](https://play.google.com/store/apps/details?id=com.flivora.app) and by a [digital services business](https://flivora.com/). Reject.
- **Hagglow** occurs as an actual surname in the [Kalgoorlie Cemetery Board's public records](https://www.kalgoorliebouldercemetery.com.au/search/browse.php?np=44&s=7500) and in a [Western Australian government gazette](https://www.legislation.wa.gov.au/legislation/statutes.nsf/RedirectURL?OpenAgent=&query=gg1970_104.pdf). Reject under the user's strict preference for a newly coined name.
- **Pazmori** occurs as text in an [official North Macedonian education programme PDF](https://www.bro.gov.mk/wp-content/uploads/2018/02/Nastavna_programa-Biologija-VIII_odd-alb.pdf). Not selected.
- **Trovumo** returned unrelated Italian text/OCR matches rather than a clean empty general search. Not selected.

Earlier parent-agent screening also discarded Kervilo, Trovelet, Lotlark and Pazwick. Those earlier observations are not independently reverified here and are not used as evidence that Pazlume is available.

## Limits and release handoff

The public searches cannot see unpublished or reserved app names, unindexed services, all countries, every social handle or common-law marks. USPTO, EUIPO, WIPO and TÜRKPATENT registry clearance has not been performed; a generic web query containing “trademark” does not replace it. No domain or social handle was purchased, no name was reserved, and no external account state was changed. Native-speaker pronunciation/meaning review is not established by this search.

For today's local launch preparation, **Pazlume is the strongest checked candidate**. A later authenticated App Store Connect name acceptance and any desired legal clearance remain separate checks. The developer must not describe it as guaranteed unique or legally cleared.
