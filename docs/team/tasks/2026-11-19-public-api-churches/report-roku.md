# Report · roku · T6 phase 2: Churches on the paged public API

## STATUS

IMPLEMENTED, device-verified on the dev Roku (192.168.0.106); review pending.

## BRANCH

`design/showcase` (owner Q3). Nothing pushed.

## Summary

Churches now come from `GET https://mysda.itulix.com/api/public/churches`
(public, paged) instead of `livetv.mysdatv.com/api/getfavoritechurch.php`.
They load per state, as approved in Q3 (option b; the QR links stay fixed).
- **First call** (the first time the screen shows): `page=1&per_page=50`.
  - `states[]` draws all 42 states with their counts.
  - The churches on that page fill the states it holds WHOLE (Alabama to
    California, 5 states). It ends part-way through Canada, so Canada is not
    seeded.
  - The subtitle shows `paging.total` (237).
- **Each further state** loads once focus has rested on it for 0.3 s:
  `state=<as given>&per_page=100&page=1`.
  - While it loads, the church column shows up to 9 plain plates, the first
    reading "Loading churches…", and the QR panel stays empty.
  - When it lands, the state below is fetched ahead.
- **A state bigger than 100** loads `page+1` once focus in the church column
  is within 8 rows of the loaded end, and stops at `paging.pages`, never on
  an empty page (past the end, the API repeats the last page).
- **Requests:** one at a time. `pump()` always serves what has focus now:
  first the focused state, then its next page, then the state below. A fast
  scroll therefore never queues the states it passed.
- **Cache:** each state is kept for 30 minutes. Page 1 replaces a state's
  churches and later pages append; rows are deduped on name + city + link.
- **Failure:** after one retry inside the Task, the column says "Couldn't
  load. Press OK to try again." and OK retries. If the very first call
  fails, the screen says "The church list didn't load. Press OK to try
  again." (before this change it said "Try again later" and could not
  retry).
- **The QR panel is unchanged.** It reads the church's link (`youtube_url`)
  and keeps the scheme and host checks.

## Files changed

- `components/sc/tasks/ScChurchTask.{xml,brs}`: rewritten as one page of the
  public API.
  - In: `stateName`, `page`, `perPage`, `gen`.
  - Out: a node of churches plus `scPage`, `scPages`, `scTotal` and
    `scStates`.
  - Rows are trimmed; a row with no name or no link is dropped.
  - The old raw-array parsing and `titleCase` are gone: the API's state names
    are clean.
- `components/sc/screens/ScChurches.{xml,brs}`:
  - new: `loadFirst`, `onFirst` (states + seeding), `fillState`, `isFresh`,
    `pump`, `requestState`, `onStateLoaded`, `onRest`;
  - `restTimer` (0.3 s); placeholder plates in `paint`; the `panelEmpty`
    flag; OK to retry; `pump()` on Down and Right;
  - header comment updated.
- Task folder:
  - `plan.md` (with the Q3 answer), `api-contract.md` (shared copy in the
    notes folder), this report;
  - `screenshots/01-08`, `device-log-*.txt`;
  - `tools/` (roku-log, to-rgba, decode-qr, copied from phase 1).

## Decisions

- **The Task field is `stateName`, not `state`.** `state` is the Task node's
  own run status. The first build declared a `state` field and the Task
  never ran: no request, the screen stuck on "Loading churches…" and nothing
  in the console. Renamed, it worked at once.
- **Seed only the states page 1 holds whole.** A partly-seeded state would
  show a short list and then grow under the viewer.
- **No skeleton-row focus.** Right does nothing until the state's churches
  are in. The plan said focus could move into the skeleton at once. I kept
  it simpler: with no rows there is nothing to focus, and focus never lands
  on a placeholder.
- **A refresh after 30 minutes keeps the old rows on screen until the new
  ones land**, and leaves the QR panel alone (`panelEmpty`).

## Verification

Device: Roku at 192.168.0.106; captures are 1280x720 JPEG. I read every
screenshot.

1. **First build, the `state` field collision:** the screen stuck on
   "Loading churches…" with no `[ScChurchTask]` line in the console
   (`device-log-1/2`). Fixed by renaming the field.
2. **`01-first-paint`:** 42 states with their counts and "237 churches". The
   Alabama list (7) comes from page 1, and its QR code is drawn. Console:
   `[ScChurchTask] state='' page 1/5 <- 200 (50 churches)`.
3. **`02-canada-loading` → `03-canada-loaded`:** five fast Downs to Canada
   (partly seeded). It shows the placeholders, then 16 churches about 2 s
   later. Console (`device-log-4`): exactly two more requests, Canada and
   then the Colorado prefetch. Alberta to California were not requested
   (seeded).
4. **QR decode from `03` against the API:**
   - device `DECODED https://www.youtube.com/user/bayrobertssda/live`
   - API `https://www.youtube.com/user/bayrobertssda/live`
5. **Walk through all 42 states** (36 Downs, 0.6 s apart; `device-log-5`):
   - 38 distinct request lines, the first page plus the 37 states it did
     not hold whole (42 - 5);
   - every one `<- 200`;
   - 0 lines matching runtime error, crash or BRIGHTSCRIPT ERROR.
   - `04-last-state`: Wisconsin (4) with its QR code.
6. **`05-california-end`:** the biggest state (36) scrolls to Yucaipa, the
   last row, and the panel follows. No page-2 request (36 < 100).
7. **Debug build** (state requests sent to a wrong URL; reverted, `T6-DEBUG`
   markers 0):
   - `06-state-failed` shows "Couldn't load. Press OK to try again.";
   - after OK, `07-state-retry-loading` shows "Loading churches…".
8. **`08-clean-build-canada`:** the final clean build (out/mysdatv.zip
   sha256 f2ebf60b…).

Not device-verified:
- **Paging inside a state.** No state has more than 100 today. The code path
  is the same request with `page+1`; review it by reading.
- **The 30-minute refresh.**
- **The first-call failure message.**

**Data issue found (backend):** the API cuts some cities to their first
word, so "San Bernardino Community SDA Church" has city "San" and Santa
Clarita has "Santa". That is 19 churches, and the same truncation the old
feed had in its state names. Shown as-is; the backend should fix it.

Knowledge applied: mysdatv-church-directory-api (app),
focus-following-panel-clears-stale-content-at-once,
hidden-screen-first-fetch-races-the-landing-screen (summary),
on-device-qr-encoder-in-brightscript, verify-a-qr-from-a-device-capture-without-python,
reserved-words-and-name-collisions (summary).

## Learnings candidates

- **A Task subclass must not declare a field called `state`.** It shadows the
  Task's own status and the Task silently never runs: no error, no console
  line. Same family as `reserved-words-and-name-collisions`.
- **`mysda.itulix.com` public API quirks:**
  - a page past the end repeats the last page;
  - an invalid `per_page` silently becomes 50;
  - `state` is case-insensitive;
  - cities are truncated to the first word;
  - `image_url` and `description` are null for every church.
  This is an app-layer entry, superseding the old church API entry's
  endpoint.

## Blockers

None.

## Round 2 (after review.md)

| ID | Status | What |
|---|---|---|
| C1 MED | FIXED | A failed page 2+ sets `scMoreFailed`; `pump()` skips paging while it is set; a plate after the last row says "Couldn't load more. Press OK to try again." (or "Loading more churches…" while a next page is due); OK in the church column clears it and asks once |
| C2 MED | FIXED | Loaded with 0 rows reads "No churches listed here yet." (one plate); the panel follows (`showChurch()` when the focused key changed) |
| C3 MED | FIXED | `onStateLoaded` keeps focus on the same church (name + city + link) across a reload, clamps otherwise, and redraws the panel when the focused church changed |
| C4 LOW | FIXED | A failed PREFETCH (requested for a state not in focus) sets no error; it is retried after 60 s (`scRetryAt`). A failed state no longer blocks the prefetch below it |
| C5 LOW | FIXED | `enterState` sets `moving`; a landing answer only pumps when the viewer has rested (`onRest` clears it) |
| C6 LOW | FIXED (tested) | Paging tested on the device with a debug build (12 per page for state requests; Maryland page 2 forced to fail) |
| C7 LOW | FIXED | `cleanName` cuts a US phone number out of a church name (`\(?\d{3}\)?[\s.-]*\d{3}[\s.-]?\d{4}`), then closes up spaces; the contract states the same rule |
| C8 LOW | FIXED | `scBusy` removed |
| S1 LOW | FIXED | Roku now follows contract rule 5: only an https link on YouTube or Facebook becomes a code; anything else reads "No link for this church" (all 237 pass today) |

Found while verifying: the feed holds a TRUE duplicate. "Oakwood University
Church" and "Oakwood University Church (256) 837-1255" have the same city
and link, so after the name clean-up the dedupe folds them into one. A fully
loaded state's count is now the number listed (Alabama 6, not the server's
7). While a state is still paging, the server's count stands.

Device, round 2 (Roku 192.168.0.106; JPEGs read one by one):
- Debug build (`T6-DEBUG`, reverted, markers 0), with `device-log-6`:
  - `09-paging-florida-page2`: Florida (17) loads page 1/2 (12), then page 2/2
    (5) when focus nears the end; the last row, Winter Park, is focused.
  - `10-paging-maryland-more-failed`: Maryland 12 rows plus the
    "Couldn't load more. Press OK to try again." plate. Its page 2 was
    requested ONCE (one 404 line), so there is no loop.
  - `device-log-7`: OK made exactly one more request. The Maryland page-2
    lines total 2, because the console replays history.
  - 0 runtime errors.
- Clean build (out/mysdatv.zip sha256 292cdd12…):
  - `11-clean-first-paint`: Alabama 6, "Oakwood University Church" without
    the phone number.
  - `12-clean-canada`: the per-state load.

Still not device-verified: the 30-minute refresh (C3's path, by reading), and
the C2 empty state (no real state is empty; by reading).

## Round 3 (after review-2.md: APPROVE, LOWs only)

| ID | Status | What |
|---|---|---|
| C4 (PARTLY) | FIXED | A failed refresh of a state whose rows are on screen keeps the rows and sets `scRetryAt` (a quiet retry after 60 s), not `scFailed`; `pump()` honours `scRetryAt` for the focused state too |
| R1 | FIXED | A fresh 42-state walk on the FINAL zip, with its log: `device-log-final.txt`, screenshots 13 and 14 |
| R2 | FIXED | Contract rule 5 is now ordered: clean the names BEFORE the dedupe, and a fully loaded state's count equals its listed rows |
| R3 | BACKEND | The subtitle shows the server's 237; the states add up to 236 after the Oakwood duplicate folds. Ask the backend to remove the duplicate |

**Final device run** (out/mysdatv.zip sha256 9d252095…; `T6-DEBUG` markers 0):
- `13-final-first-paint`: Alabama 6, with "Oakwood University Church"
  cleaned.
- `14-final-last-state`: Wisconsin 4, with its QR code.
- The walk through all 42 states (41 Downs, 0.6 s apart) in
  `device-log-final.txt`, current run only: 38 requests (the first page plus
  37 states), 0 non-200, 38 distinct, 0 runtime errors.

## Final STATUS

DONE. Device-verified on the final build; reviews: review.md (APPROVE WITH
FIXES, all fixed), review-2.md (APPROVE; LOWs fixed in round 3, R3 is for
the backend).
