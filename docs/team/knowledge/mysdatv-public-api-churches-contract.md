---
topic: mysdatv-public-api-churches-contract
summary: mysda.itulix.com public API (paged churches, no auth) - quirks measured 2026-11-19, what stays on the old backend, 6 undocumented spec endpoints; full contract in the T6 task folder api-contract.md
platform: roku
applies-to: [mysdatv]
observed-in: [mysdatv]
date: 2026-11-19
source-task: mysdatv/docs/team/tasks/2026-11-19-public-api-churches/
---

# mysda.itulix.com public API: churches and its quirks (mysdatv)

## Fact

Full contract (shape, ordering rules, D-pad loading plan, flat-list plan):
`docs/team/tasks/2026-11-19-public-api-churches/api-contract.md`. This entry holds
what an agent would otherwise rediscover. Probed 2026-11-19, no auth.

`GET https://mysda.itulix.com/api/public/churches?page&per_page&state` returns
`{churches[], states[], paging{page,per_page,total,pages}}`, ordered state, city, name.

- **A page past the end repeats the last page** (never empty). Stop on
  `paging.pages`; "load until empty" loops forever.
- **Invalid `per_page` silently becomes 50.** Only 12, 24, 50, 100 are honoured.
- **`state` is case-insensitive;** an unknown state gives `total 0, pages 1, []`.
- **`states[]` (all 42, with counts) is in every response,** whatever the filter,
  so the state list needs no second call.
- **Cities are cut to their first word** for 19 churches ("San", "Santa", "Bay").
  Backend data fault; shown as-is.
- **`image_url` and `description` are null for all churches.**
- **A true duplicate only matches after cleaning:** "Oakwood University Church"
  and "... (256) 837-1255" share city and link. Clean phone numbers out of names
  BEFORE the dedupe. The subtitle (server total 237) then exceeds the listed sum
  (236); a fully loaded state shows its listed row count (Alabama 6, not 7).
- **237 churches in total.** The owner expected 1000+. Verified as backend data,
  not a client filter: unknown params (status, active, all, include_hidden,
  country, limit...) change nothing, and a full walk at 12 per page gives 237
  distinct. The old feed also has 237.
- **Undocumented endpoints:** `/api/public/openapi.json` lists six GETs the docs
  page omits: `donate` (card, crypto and page URLs, "show as QR codes on TVs"),
  `channels` (no streams, so not a catalogue), `settings`, `products`, `people`,
  `faqs`. Not used: the owner kept the QR card links fixed.
- **Stays on the old backend:** login, check-purchase, the channel catalogue and
  `getdvr.php` (see [[mysdatv-live-recordings-and-qr-contract]]).

## Why it matters

The docs page alone misses the past-the-end repeat and the silent `per_page`
fallback, and the "237, not 1000" question will come back.

## How to apply

- Page by `paging.pages`, read the `per_page` that comes back, send `state`
  as given in `states[]`.
- Order: trim, clean names, drop rows without name or link, then dedupe.
- If the owner asks again about the count, point at the verification above;
  the fix is a backend import, not a client change.

## Related

[[mysdatv-church-directory-api]], [[mysdatv-live-recordings-and-qr-contract]], [[list-lookahead-recheck-on-page-land-and-last-page-stop]], [[qr-payload-needs-link-grade-validation]]
