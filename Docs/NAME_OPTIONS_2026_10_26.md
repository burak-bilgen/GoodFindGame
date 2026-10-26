# Game name options — 26 October 2026

**Decision:** the owner rejected the invented shortlist and selected **Good Find: Buy, Fix & Sell**, with **A Secondhand Trading Simulation Game** as its descriptive line and `good-find` as the requested GitHub repository name. This decision applies to the GitHub identity/README. The existing app display name, bundle identity and save paths have not been changed. The collision checks below describe earlier rejected options; they do not establish clearance or availability for Good Find.

## Earlier exploration (superseded)

The owner requested alternatives to Pazlume before choosing a new name. No alternative has been applied. Existing bundle identifiers, save paths, source folders and account settings remain unchanged.

## Shortlist

These are invented naming associations, not claimed dictionary etymologies. They fit the existing buy → inspect → repair → resell loop and can retain the current box/controller icon.

| Option | Suggested pronunciation | Intended association | Character |
| --- | --- | --- | --- |
| **Flipvero** | flip-ve-ro | flip / resale + uncovering the item’s real state | Clearest global connection to the resale loop; retains continuity with ProjectFlip without being a generic simulator title. |
| **Relofto** | re-lof-to | “re-” / second life + a cozy loft full of finds | My first choice for a short, easily spoken cozy name with room for all product categories. Less explicit about trading; a subtitle can explain it. |
| **Barglume** | bar-glum | bargain + overlooked objects finding their glow | Strongest connection to negotiation and the warm visual direction. English speakers may say “barg-loom”; Turkish pronunciation is less immediate than Relofto. |
| **Paznivo** | paz-ni-vo | pazar + a new stage in a trader’s career | A Turkish market cue with an international-looking ending; energetic rather than strongly cozy. |
| **Trovnook** | trov-nuk | trove + nook / a corner for discoveries | Strong treasure-hunting atmosphere. The “vn” junction is less natural to say and spell. |

**Recommendation:** Flipvero for a more explicit trading-game identity; Relofto for the warmer, quieter brand. Possible descriptive subtitle for any choice: **Buy, Repair & Resell**. The name itself remains a human choice; this note is not authorization to rename or publish.

## First-party App Store checks

Queried Apple’s public Search API directly with `entity=software&limit=200` for US and Turkey on 26 October 2026. Checked returned `trackName` values case-insensitively for each candidate; no returned title even contained the complete shortlist candidate. Counts below include fuzzy/unrelated results. They are not the number of exact matches. Apple explains country-scoped software search in its [Search API documentation](https://performance-partners.apple.com/search-api).

| Option | US returned apps / exact matches | TR returned apps / exact matches | First-party results |
| --- | ---: | ---: | --- |
| Flipvero | 115 / 0 | 0 / 0 | [US JSON](https://itunes.apple.com/search?term=Flipvero&country=us&entity=software&limit=200), [TR JSON](https://itunes.apple.com/search?term=Flipvero&country=tr&entity=software&limit=200) |
| Relofto | 3 / 0 | 0 / 0 | [US JSON](https://itunes.apple.com/search?term=Relofto&country=us&entity=software&limit=200), [TR JSON](https://itunes.apple.com/search?term=Relofto&country=tr&entity=software&limit=200) |
| Barglume | 0 / 0 | 0 / 0 | [US JSON](https://itunes.apple.com/search?term=Barglume&country=us&entity=software&limit=200), [TR JSON](https://itunes.apple.com/search?term=Barglume&country=tr&entity=software&limit=200) |
| Paznivo | 142 / 0 | 0 / 0 | [US JSON](https://itunes.apple.com/search?term=Paznivo&country=us&entity=software&limit=200), [TR JSON](https://itunes.apple.com/search?term=Paznivo&country=tr&entity=software&limit=200) |
| Trovnook | 181 / 0 | 0 / 0 | [US JSON](https://itunes.apple.com/search?term=Trovnook&country=us&entity=software&limit=200), [TR JSON](https://itunes.apple.com/search?term=Trovnook&country=tr&entity=software&limit=200) |

There were no request errors. These queries cover the returned public search results in two countries, not every app or reserved unpublished name.

## Indexed-web checks

Executed exact quoted queries for each shortlist candidate, followed by the candidate with `game app`. Also ran each candidate against the domain group `site:apps.apple.com OR site:play.google.com OR site:store.steampowered.com OR site:itch.io`. The store-domain group returned no indexed matches for any of the five.

No identifiable game, app or commercial brand using a shortlist name surfaced in the checked indexed results. Relofto did appear incidentally in an automatically generated anagram list; that is not a discovered named product. No indexed use was returned for the exact Flipvero, Paznivo, Barglume or Trovnook queries in this pass. Search absence is an observation about this limited pass, not proof that nobody uses a name.

## Other candidates screened out

- **Kepiro:** no returned Apple title contained the candidate (US 29 fuzzy results; TR 0), but it is an existing surname with substantial indexed use, including the first-party [Imperial College alumni profile](https://www.imperial.ac.uk/Stories/alumni-awards-2026-ibolya/). Pronounceable, but a poor fit for the owner’s preference for a clean new identity.
- **Flipwick:** the first-party [Spark & Anvil RiddlePals page](https://sparkanvil.org/play/riddlepals/) uses Flipwick as a character name. Not a clean original-name recommendation.
- **Trovilo:** a first-party [Trovilo site](https://trovilo.co/) already advertises a financial app under that name. Reject for an app name.
- **Revendle:** no matching returned Apple title (US 0 results; TR 0), but a manufacturer’s [Tiger’s Eye catalogue](https://oyaz.co/wp-content/uploads/2025/07/TIGERS-EYE_compressed.pdf) uses `REVENDLE-10`. Other exact text results included apparent OCR/typing artifacts. Do not describe it as unused.
- **Hagglow:** no matching returned Apple title (US 5 fuzzy results; TR 0), but existing surname use is visible in primary published records, including the [National Library of New Zealand archive](https://paperspast.natlib.govt.nz/newspapers/TS19350215.2.45?items_per_page=100&page=12&query=david+kerr&snippet=true). We can produce cleaner alternatives.
- **Haggora:** first-party developer [David Sajosi](https://www.sajosi.com/) already lists Haggora as a voice-negotiation project, a particularly close thematic overlap. Reject.
- **Flipmora:** first-party [Pixmora’s album viewer](https://www.pixmora.in/view.php?file=Mohini_Shailendra_20251231_PixmoraPhotography.pdf) displays Flipmora. Reject as a clean unused-name recommendation.

## Limits

This is a practical collision screen, not trademark clearance, a domain/social-handle check, global exclusivity or App Store name reservation. No domain was purchased, account changed, repository renamed or store entry created. After a name is chosen, apply it consistently to the public app name, localized metadata, README and publisher pages while preserving the production bundle/save identity unless a separate migration is deliberately requested.
