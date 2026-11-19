# mySDAtv API contract: every app (Roku, Flutter LG/Samsung/Android TV/mobile, tvOS)

Written by T6 (Roku) on 2026-11-19 from https://mysda.itulix.com/docs plus
live probes. Roku implements it first; T5 (Flutter LG/Samsung), T4 (tvOS) and
T7 (Flutter mobile/TV DVR + QR) follow it. Phase 1 (the live recordings row
and the QR cards) is specified in
`D:/Roku/mysdatv/docs/team/knowledge/mysdatv-live-recordings-and-qr-contract.md`;
this file adds the new public API and does not repeat phase 1.

## 1. Which backend serves what

| Need | Call | Backend |
|---|---|---|
| Channel catalogue (streams, `dvr_url`) | `GET https://sda.wchupload.tulix.net/api/content/{8,9,10}/list?limit=200` (8 TV, 9 Languages, 10 Radio) | existing |
| Schedule / recordings | `GET <channel.dvr_url>` = `https://livetv.mysdatv.com/api/getdvr.php?id=<stream>` | existing, no auth |
| Sign-in | `POST https://sda.wchupload.tulix.net/api/login` `{email,password,deviceInfo}` | existing |
| Catch-up access | `POST .../api/payments/customer/check-purchase` `{"collectionId":null,"productId":15}` + Bearer and X-Session-Token headers | existing |
| **Churches** | `GET https://mysda.itulix.com/api/public/churches` | **NEW**; replaces `livetv.mysdatv.com/api/getfavoritechurch.php` |
| **Website links** (donate, app, crypto) | `GET https://mysda.itulix.com/api/public/content` → `settings.links` | **NEW** (use depends on Q3) |
| **Films** | `GET https://mysda.itulix.com/api/public/films` | **NEW**; empty today, not built yet |
| Contact | `POST https://mysda.itulix.com/api/public/contact` | NEW; not for TV |

The new API needs no auth headers. Errors share one shape:
`{"error":{"code","message","detail"}}`, with these codes:
- `VALIDATION_ERROR` 400
- `INVALID_JSON` 400
- `RATE_LIMITED` 429
- `INTERNAL_ERROR` 500

## 2. Churches

```
GET https://mysda.itulix.com/api/public/churches?page=<1..>&per_page=<12|24|50|100>&state=<from states[]>
200 {
  "churches": [ { "name": str, "state": str|null, "city": str|null,
                  "description": str|null, "youtube_url": str|null,
                  "image_url": absolute-url|null } ],
  "states":   [ { "state": str|null, "churches": int } ],   // ALL states, whatever the filter
  "paging":   { "page": int, "per_page": int, "total": int, "pages": int }
}
```
Order: state, city, name. Server cache 60 s.

**Rules every client keeps (probed 2026-11-19):**
1. **Stop at `paging.pages`.** A page past the end returns the last page
   again, never an empty one, so "load until empty" loops forever showing
   duplicates.
2. **Use the `per_page` that comes back.** Only 12, 24, 50 and 100 are
   honoured; anything else becomes 50 with no error.
3. **Send `state` exactly as `states[].state` gives it.** The server ignores
   case, but do not rely on it. An unknown state gives
   `total: 0, pages: 1, churches: []`.
4. **`states[]` is in every response.** Draw the state filter from the
   first call; it needs no second request.
5. **Treat the data as untrusted, in this order:**
   1. Trim everything.
   2. Clean names: names can carry phone numbers ("Oakwood University
      Church (256) 837-1255"). Cut a US number out (Roku:
      `\(?\d{3}\)?[\s.-]*\d{3}[\s.-]?\d{4}` → space, then collapse spaces).
      It changes exactly 3 of the 237 today.
   3. Drop rows with no name or no link.
   4. Dedupe on name + city + link, AFTER step 2. The feed holds a true
      duplicate: "Oakwood University Church" and the same church with its
      phone number, same city, same link. They only match once cleaned.
      Two other names repeat in different cities and are not duplicates.
   5. Check a link before encoding it as a QR code or opening it: https,
      and the host must be youtube.com, youtu.be or facebook.com. Anything
      else reads "No link for this church". Today 236 are YouTube and 1 is
      Facebook.
   6. Once a state is fully loaded (`page = pages`), show its count as the
      number of rows listed (Alabama 6, not the server's 7). While it is
      still paging, show the server's `states[].churches`.
6. `image_url` and `description` are null for all 237 today. Design for
   null: no empty picture boxes, use a placeholder (the state initial or a
   church glyph).
7. Today: 237 churches, 42 states (US states, Canadian provinces, French
   regions). The biggest state is California, with 36.

**Loading on a TV, D-pad: state first** (Roku, LG/Samsung, Android TV, tvOS)
- **Open:** `?page=1&per_page=50`.
  - States column from `states[]`, with counts.
  - The first page fills the first states, so the first state needs no
    second call.
- **Focus rests 0.3 s on an uncached state:** `?state=X&per_page=100&page=1`.
  - Show `count` skeleton rows right away.
  - Clear the detail/QR panel.
  - The newest focus wins: drop an answer for a state no longer focused.
  - One request in flight at a time.
- **When a state lands:** prefetch the next state down.
- **A state with more than 100:** fetch `page+1` when focus is within 8 rows
  of the loaded end, until `page = pages`.
- **Cache:** per state for the session; refresh after 30 minutes.
- **Failure:** retry once, then an inline "Couldn't load. Press OK to try
  again" in that column only.

**Loading a flat list or grid** (mobile, or an "All churches" grid on TV)
- `per_page` 24 on a TV grid (4–6 across), 50 on mobile.
- Fetch the next page when the focused or visible item is within 2 rows
  (TV) or one screen (mobile) of the loaded end.
- One request in flight; dedupe; stop at `pages`.
- Pull-to-refresh, or changing the state chip, resets to page 1.
- State chips filter on the server (`state=`), from `states[]`.
- **No text search:** the API has none, and filtering only the loaded pages
  would mislead. Ask the backend for `q=` if search is wanted.

**What a church does when chosen**
- TV: show its link as a QR code. These are YouTube channel pages, not
  videos (see `mysdatv-church-directory-api`).
- Mobile: open the link in the browser or the YouTube app.

## 3. Website links (`/api/public/content`)

```
GET https://mysda.itulix.com/api/public/content      (no-cache, ~25 KB)
settings.links = { "app": "https://apps.mysdatv.com/",
                   "donate": "https://donate.stripe.com/…",
                   "crypto": "https://www.every.org/mysdatv?donateTo=mysdatv#/donate/crypto" }
settings also: email, salesEmail, phone(+Href), phoneUS(+Href)
channels[]: name, meta, category (television|languages|radio), logo_url (RELATIVE: /assets/img/channels/<stream>-web.png)
```
This list has no stream or dvr_url, so it does NOT replace the catalogue.

**QR card URLs.** The owner chose to keep them FIXED in Q3 (option b, 2026-11-19), so there is no content call. The proposal below was not taken:
- Donate = `settings.links.donate` from this call (read once per session),
  falling back to `https://www.mysdatv.com/mysdatv-donation-page`.
- Sign up = `https://www.mysdatv.com/`. This was the owner's earlier pick;
  `links.app` points to apps.mysdatv.com, which the owner said is not the
  page to use.

## 4. Films (not built yet)

```
GET https://mysda.itulix.com/api/public/films?page&per_page(12|24|50|100)
films[]: slug, title, description|null, year|null, genre|null, poster_url|null, duration_s|null, hls_url, page_url
paging: same rules as churches
```
Empty today (`total: 0`). When it has items, it would make a "Films" row
whose `hls_url` plays directly. That needs its own task and owner decision.

## 5. Unchanged on every platform

- Sign-in, check-purchase, catalogue and getdvr.php stay where they are.
- The open phase-1 item S1 is unchanged: check-purchase treats
  `statusCode 200` as subscribed whatever `data` says. Capture real
  responses before release.

## 6. Endpoints in the OpenAPI spec but not on the docs page (found 2026-11-19)

`https://mysda.itulix.com/api/public/openapi.json` lists six more GET
endpoints, all public (no token):

| Endpoint | Returns | Use |
|---|---|---|
| `/api/public/donate` | `{ card_url (Stripe), crypto_url (every.org), page_url (https://mysda.itulix.com/donate) }`; the spec says "Show them as QR codes on TVs" | Not now: the owner kept the QR links fixed (Q3 b). It would be the source if that changes |
| `/api/public/channels?page&per_page&category` | channels `{slug, name, meta, category, logo_url (absolute)}`, no streams | Not a catalogue replacement (no streams) |
| `/api/public/settings` | phones, emails, `links.*` (the same as `content.settings`) | Not needed |
| `/api/public/products`, `/people`, `/faqs` | website content | Not needed in the apps |

**Church count check (owner asked whether it should be 1000+):**
- The API reports `total: 237` with no parameters and at `per_page=100`.
- A full walk at 12 per page gives 237 distinct churches.
- Unknown filters (status, active, all, include_hidden, country, type,
  published, show_in_apps, limit) change nothing.
- The spec has only `page`, `per_page` and `state`.
- The old feed has 237 too.
So the backend holds 237. If 1000+ is expected, the data import is
incomplete, which is a backend question.
