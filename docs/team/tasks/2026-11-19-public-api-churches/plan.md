# T6 phase 2: the new public API (mysda.itulix.com) on Roku, then every TV app

Owner NOTE (2026-11-19): "Docs arrived, https://mysda.itulix.com/docs. Use
Roku Session first to understand what needs to be changed, and after that we
have to update following LG samsung apps as well + tvOS as well, keep in mind
this api must have Churches as well but with Pagination which needs to be
considered and we have to think how to load them."

This file is analysis only; no code is written yet. The cross-platform
contract that T5 (Flutter LG/Samsung), T4 (tvOS) and T7 (Flutter mobile and
TV) follow is in `api-contract.md`, next to this file.

## What the new API is (read from the docs, then probed live on 2026-11-19)

The base is `https://mysda.itulix.com`. Every endpoint is public: no key, no
sign-in, JSON. There are four endpoints:

| Endpoint | What | Probed |
|---|---|---|
| `GET /api/public/churches?page&per_page&state` | Churches streaming the Sabbath service, ordered by state, city, then name | 237 churches, 42 states; `max-age=60`; CORS `*` |
| `GET /api/public/films?page&per_page` | Films marked "Show in apps", each with an HLS url | **0 films today** |
| `GET /api/public/content` | Website content: channels (name, category, logo, **no streams**), products, people, FAQs, settings with `links.*` | 50 channels (24 + 16 + 10, the same counts as our catalogue); `no-cache` |
| `POST /api/public/contact` | Contact form, rate-limited | not useful on a TV |

The docs say plainly that live streams, the programme guide, sign-in and
purchases are **not** in this API yet; "the apps use their existing backend".

## (a) What changes in the Roku app, endpoint by endpoint

| Roku calls today | New API | Change |
|---|---|---|
| `GET livetv.mysdatv.com/api/getfavoritechurch.php` (raw array `{state, city, church, link}`, all 237 at once; `ScChurchTask`) | `GET /api/public/churches` (paged; `{name, state, city, description, youtube_url, image_url}` plus `states[]` and `paging`) | **MIGRATE.** Rewrite `ScChurchTask` to page, and change `ScChurches` to load one state at a time (strategy below). Field renames: church→name, link→youtube_url. State names arrive clean: the old feed's truncated `NEW`, `NORTH`, `FRENCH` are gone, so the titleCase fix-up goes too. |
| Hard-coded QR links in `source/ScLinks.brs` (`www.mysdatv.com/`, `www.mysdatv.com/mysdatv-donation-page`) | `GET /api/public/content` → `settings.links.donate` = a Stripe donate link, `links.crypto` = every.org, `links.app` = `https://apps.mysdatv.com/` | **OWNER DECIDES (Q3).** Recommended: the Donate code takes `links.donate` from the API, so the operator can change it without an app release, and falls back to today's page; the sign-up code stays `www.mysdatv.com/` as the owner chose. |
| Catalogue: `GET sda.wchupload.tulix.net/api/content/{8,9,10}/list` (streams, dvr_url) | `content.channels[]` has names, categories and logos but no stream or dvr_url | **NO CHANGE.** The new list cannot play anything. |
| Schedule / DVR: `getdvr.php?id=<stream>` | not in the API | **NO CHANGE** |
| Sign-in `POST /api/login`, subscription `POST /api/payments/customer/check-purchase` (productId 15) | not in the API | **NO CHANGE**; open item S1 from phase 1 still stands |
| (none) | `GET /api/public/films` | **NOT NOW.** The list is empty. When films appear, a "Films" row on Home or Catch-up would play `hls_url` directly. That is a later task, but the contract lists the call. |
| (none) | `POST /api/public/contact` | **NONE.** Not on TV: it needs typing four fields. |

So on Roku the work is: Churches (task, screen, loading), and possibly the QR
links (content settings). Everything else stays on the existing backend.

## Churches: how to load with pagination (Roku, and the TV apps)

Facts that shape it (probed):
- **Stop on `paging.pages`, never on an empty page.** `page` past the end
  returns the LAST page again (`page=999&per_page=100` gave page 3 with 37
  churches).
- **Read `paging.per_page` back.** Only 12, 24, 50 and 100 are allowed; any
  other value silently becomes 50.
- **`states[]` comes with every response, whatever the filter.** It holds
  all 42 states and their counts, so the first call alone can draw the whole
  states column with counts.
- The `state` filter is case-insensitive in practice (the docs say exact);
  an unknown state gives `total: 0`. Send the value exactly as `states[]`
  gives it.
- The biggest state is California, with 36 churches. At `per_page=100`
  every state is ONE request today; paging inside a state is still coded,
  for when a state passes 100.
- `image_url` and `description` are null for all 237 today. Two names
  repeat (Palm Springs, Maranatha: different cities). Three names carry
  phone numbers, so keep the existing clean-up. 236 links are YouTube and
  1 is Facebook.

**Recommended strategy (A): load by state, the way the Roku screen already reads.**
1. **Open the Churches screen:** one call, `?page=1&per_page=50`.
   - Draw the states column at once from `states[]`, with counts.
   - Seed the cache with the first page (Alabama…California): the first
     state's churches are on screen with no second call.
2. **Focus rests on a state for 0.3 s and it is not cached:**
   `?state=<as given>&per_page=100&page=1`.
   - Meanwhile the church column shows `count` skeleton rows, so focus can
     move into it at once.
   - The QR panel is cleared and never shows a stale code (KB
     `focus-following-panel-clears-stale-content-at-once`).
3. **When it lands:** one request in flight at a time; the newest focus wins
   and a late answer for another state is dropped. Then prefetch the NEXT
   state (the likely Down).
4. **Paging inside a state** (when a state has more than 100): fetch
   `page+1` when focus in the church column is within 8 rows of the loaded
   end, until `page = pages`.
5. **Cache:** per state, for the session, refreshed after 30 minutes (the
   server caches 60 s). Keep the states list with it.
6. **Errors:** retry once. If it still fails, that column says "Couldn't
   load. Press OK to try again"; the rest of the screen keeps working.
7. **Clean each item:** trim; drop a row with no name or no link; keep the
   link-grade check before encoding a QR; dedupe on name + city + link
   across pages.

Cost: the first paint costs 1 request (about 9 KB). Each further state is
1 request (1-4 KB), so the whole directory is at most 43 small requests,
spread over the browse.

**Alternative (B): fetch every page up front** (3 × `per_page=100`, about
25 KB, then group locally). It is the simplest, and today it is what the
screen effectively does. It ignores paging as soon as the directory grows,
so it is not recommended; but it is one line if the owner prefers it.

**Search:** the API has no text search, only `state`. Recommended: no search
box on TV. Ask the backend for `q=` if a flat "all churches" search is wanted
(mobile).

## Implementation plan (Roku), once Q3 is approved

1. `ScChurchTask`: modes `first` (page 1 + states) and `state` (one state,
   one page); fields `state`, `page`, `perPage`; result = churches node + states
   + paging; a `gen` counter so stale answers are dropped.
2. `ScChurches`:
   - The states column from `states[]`.
   - Per-state cache, the 0.3 s rest timer, skeleton rows, the next-state
     prefetch, and paging inside a state.
   - The QR panel is unchanged: it reads `youtube_url`.
3. QR links (if Q3 says so): an `ScContentTask` reads `settings.links` once
   per session. `ScLinks` uses it, with fallbacks; the cards keep "clear,
   then encode".
4. Device verification on the Roku:
   - first paint, focus across states fast (no stale list or QR), the
     largest state (California, 36), and every state;
   - the network log shows one request per state;
   - a forced failure (a bad host) shows the retry line;
   - decode QR codes from captures.
5. Independent review, report, knowledge (the contract goes to the app KB),
   then DONE. T5, T4 and T7 port it from `api-contract.md`.

## Branch

Phase 1 was approved on `design/showcase` only. The Churches screen, the QR
cards and the live player all live on that branch, which is not merged to
`main` (main still has the legacy screens). **Recommended:** keep working on
`design/showcase`; the alternative is a new branch from it,
`solo/2026-11-19-public-api-churches`.

## Out of scope

- Films (empty today).
- Contact.
- Moving the catalogue, guide, sign-in or purchase off the existing
  backend: the API does not cover them.
- The Flutter, tvOS and LG/Samsung code: T5, T4 and T7 own it, following
  `api-contract.md`.

## Owner answer

- Q3 (2026-11-19): "b) approve, but keep both QR links fixed as now (no
  content call)". Churches moves to the paged API and loads per state; the
  QR links stay as in `source/ScLinks.brs`; branch `design/showcase`.
