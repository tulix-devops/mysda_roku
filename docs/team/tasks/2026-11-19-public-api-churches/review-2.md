# Review 2: 2026-11-19-public-api-churches (Roku: Churches on the paged public API, round 2)

VERDICT: APPROVE

(No HIGH or MED findings, and every acceptance item is MET. In the dispatcher's terms this is APPROVE. Four LOW items are listed for follow-up: C4 is PARTLY fixed, and R1-R3 are new. None of them blocks a commit.)

Reviewed: uncommitted working-tree diff on `design/showcase` at HEAD b2846ac. `git diff | sha256sum` = e4dbe193d203f3b89bccc4946120173e59708f557067247b96f8659a6f08dfe7. The four files match the dispatch pin:
- ScChurchTask.xml ca4b137c…
- ScChurchTask.brs 08dcda5a…
- ScChurches.xml db3a5e03…
- ScChurches.brs a3ca8fd1…

out/mysdatv.zip is 292cdd12…. Its four copies of these files hash the same as the working tree (read with `unzip -p`, nothing extracted), and it has 0 `T6-DEBUG` markers. The source listing has 5 entries: the 4 modified files plus the untracked task folder. I took the pin at the start and again before writing, and it was unchanged.

## Earlier findings (round 1)

| ID | Status | Evidence |
|----|--------|----------|
| C1 MED | FIXED | **Class: every path where a failure can re-request itself.**<br>- Page 2+ failure: `onStateLoaded` sets `scMoreFailed` (ScChurches.brs:317-318). The paging branch of `pump` is gated on `not cur.scMoreFailed` (:269). Only OK in the church column clears it (:705-712), and only `fillState` otherwise (:243).<br>- Focused page-1 failure: `scFailed` (:319-320). The first branch skips it (:265), and the paging branch needs `isFresh`, which a never-loaded or stale state fails.<br>- Prefetch failure: `scRetryAt = now + 60` (:324), checked at :276, so at most one attempt a minute, and only when an event pumps.<br>- A failed state no longer blocks the prefetch below it: there is no early return any more.<br>- Every `pump()` call site (onFirst :214, onStateLoaded :350, onRest :355, Right/OK :683, OK retry :690/:711, Down in the churches :704) goes through the same gates.<br>- Device: in device-log-6 the forced Maryland page 2 appears ONCE (`page 2/0 <- 404`, :63). device-log-7 adds exactly one line after OK (:31 is the replay, :32 the new request). Screenshot `10` shows the "Couldn't load more. Press OK to try again." plate. I read it at full size. |
| C2 MED | FIXED | **Class: every loaded-but-empty case.**<br>- paint: when `cc = 0` and `scPage >= 1` and not failed, one plate reads "No churches listed here yet." (:437-440). This covers an unknown state, all rows dropped, and an empty refresh.<br>- The failed case keeps its own message (:435).<br>- When a reload leaves 0 rows, `currentChurch()` is invalid, so its key differs from the old one (or `panelEmpty` is set) and `showChurch()` hides the panel (:346, :499-501). The zone drops back to states (:341).<br>- Read only; no real state is empty, as the report says.<br>- Edge (Notes): a page 1 whose rows are ALL dropped, in a state with more pages, still shows "No churches", because paging needs the churches zone. |
| C3 MED | FIXED | **Class: every place rows are replaced.** `fillState(..., replace = true)` has two callers:<br>- `onFirst` seeding (:203). That is the first paint: `chIdx` is reset and `showChurch()` follows (:208-213).<br>- `onStateLoaded` with `r.scPage = 1` (:309).<br>The second one now:<br>- saves the focused key before the reload (:306-307);<br>- finds the same name + city + link and moves `chIdx` to it (:328-338);<br>- clamps otherwise (:339-340);<br>- calls `showChurch()` whenever the focused key changed (:346).<br>A changed link, name or city changes the key, so the panel can no longer keep a code beside another church (KB `focus-following-panel-clears-stale-content-at-once`). A >100 state refreshed from row 150 lands at row 99 with the panel redrawn for row 99, which is consistent, and the landing pump then asks for page 2 again. Read only (30-minute path). |
| C4 LOW | PARTLY | **Fixed:** a failed PREFETCH (`reqForFocus` false and not focused) no longer sets `scFailed`. It sets `scRetryAt` (:321-325). When focus rests on such a state, the first branch of pump ignores `scRetryAt` and asks at once (:265), so the viewer never sees an error for a request they did not make. A failed state no longer blocks the prefetch below (:273-277).<br>**Still open:** the other half of C4, a failed 30-minute REFRESH of the focused state while its rows are still shown. That sets `scFailed` (:319-320) and nothing ever retries it:<br>- `pump` skips it (:265);<br>- paint shows no message, because `cc > 0`;<br>- OK in the states column goes into the churches (:680 runs before the retry branch at :684);<br>- OK in the churches only clears `scMoreFailed`.<br>So the stale rows stay for the rest of the session, with no sign and no way to retry. Also, a focused request that fails after the viewer has moved on still marks that state failed; coming back shows "Couldn't load. Press OK" with no automatic attempt. That is plan-compliant. See the current-findings table for the fix. |
| C5 LOW | FIXED | `enterState` sets `m.moving = true` and restarts `restTimer` (:727-729). A landing pumps only `if not m.moving` (:350), and `onRest` clears the flag and pumps (:353-356).<br>**Can it stick true?** `restTimer` is started only at :729 and stopped only at :728, immediately followed by a start. grep: no other `restTimer` or `moving` writes in components/ or source/. The Timer fires whether or not the screen has focus, so Left into the capsule mid-move still clears the flag 0.3 s later. A rest that fires while a request is in flight returns early in pump, and the landing then pumps because `moving` is false by then. No request is lost and nothing sticks. |
| C6 LOW | FIXED (evidence on an earlier build, see R1) | Debug build at 12 per page, device-log-6:<br>- Florida `page 1/2 (12)`, then `page 2/2 (5)`, and no page 3: it stops at `pages`;<br>- Maryland page 2 forced to 404 once;<br>- 0 lines matching "rror".<br>Screenshot `09` (I read it) shows Winter Park, the last row, focused with the panel following and no more-plate. Florida stands in for California's 3 pages; the chain from page 2 to page 3 is the same landing pump. |
| C7 LOW | FIXED | `cleanName` (ScChurchTask.brs:44-52). I ran the same pattern on all 237 live names (fetched 3 x `per_page=100` and piped through node, no files):<br>- exactly 3 change: Oakwood → "Oakwood University Church"; Brazilian Temple → "… SDA church Portuguese"; Thompsonville → "Thompsonville SDA Church";<br>- 0 names emptied;<br>- 0 names keep any digit.<br>**Escaping:** the literal has no `"` inside. BrightScript has no escape sequences, so the backslashes reach PCRE as written. KB `brightscript-string-literals-have-no-escapes` bites only on `\"`.<br>**Can it empty a name?** Only one that is nothing but a phone number. The `name <> ""` check comes after the clean (:74-76), so such a row would be dropped, not shown blank.<br>The contract's rule 5 has the same pattern. Screenshot `11` (final build) shows "Oakwood University Church" once, and `12` shows "Centre Il est écrit" intact after the clean-up. |
| C8 LOW | FIXED | grep `scBusy` across components/ and source/: 0 hits. |
| S1 LOW | FIXED | showChurch blanks any link that is not `https://` (:515-516). The host must be `youtube.com` or a subdomain, exactly `youtu.be`, or `facebook.com` or a subdomain; anything else sets `link = ""` and the panel reads "No link for this church" with no hint (:519-536).<br>Probes of `hostOf` by reading:<br>- `youtube.com@evil.example` → evil.example (last `@`);<br>- `evil.example\@youtube.com` → evil.example (stops at `\`);<br>- `youtube.com.evil.example` fails `hostIs`;<br>- `HTTPS://…` passes, because the check is on the lower-cased copy.<br>Live: 0 of 237 links fail the gate. This matches contract rule 5. |

## Correctness findings

| # | Severity | File:line | Finding | Suggested fix |
|---|----------|-----------|---------|---------------|
| C4 | LOW (carried, PARTLY) | components/sc/screens/ScChurches.brs:319-320, 265, 680-691 | **A failed refresh of the focused state, with its rows on screen, is never retried and has no retry path.** See the table above. | When the failed state still has rows, set `scRetryAt = now + 60` instead of `scFailed`, so the stale rows stay and a quiet retry follows. Gate the first branch of pump on `ScNowSecs() >= cur.scRetryAt` for that case. |
| R1 | LOW | report-roku.md "Round 2", screenshots 09/10, device-log-6/7 | **The paging and C1 evidence comes from a build older than the pinned code.** Screenshots 09 and 10 show Alabama **7**, but the pinned code seeds Alabama at 6 (dedupe plus count-equals-rows; screenshot 11 shows 6). So the paging, more-plate and no-loop evidence predates the round-2 count and dedupe change, and perhaps `cleanName`.<br>The pinned build (292cdd12…) has only two screens of evidence (11, 12) and no console capture. Round 2 rewrote `pump`, `onStateLoaded` and paint, but the 42-state walk with 0 errors (device-log-5) and the paging run were both on earlier builds. KB `evidence-must-postdate-the-fix-it-verifies`.<br>The logic I read agrees with the debug captures, so this is about evidence, not a known bug. | Before the commit, on the pinned zip: walk all 42 states once, enter California to Yucaipa and back, and attach that console (expect 38 request lines, all 200, 0 errors). Better still, re-run the 12-per-page debug build from the final source. |
| R2 | LOW | docs/team/tasks/2026-11-19-public-api-churches/api-contract.md, §2 rule 5 | **The contract does not carry two behaviours that ports will get wrong.**<br>(a) Order: rule 5 lists the dedupe BEFORE the phone clean-up. The live feed has a true duplicate that only matches AFTER cleaning (Oakwood, Huntsville, same link; confirmed live, the one key that repeats after the clean). A port that dedupes first shows Oakwood twice.<br>(b) Counts: Roku now replaces a fully loaded state's count with the number listed (Alabama 7 → 6, ScChurches.brs:237-240) and keeps the server count while paging (:311-316). The contract only says "Show `count` skeleton rows", so T4, T5 and T7 will show 7. | Rule 5: "clean the name first, then dedupe on the cleaned name + city + link (the live feed holds one duplicate that only matches after cleaning)". Add a line under Loading: "a state's count is `states[]` until every page is in, then the number of rows listed". |
| R3 | LOW | components/sc/screens/ScChurches.brs:206 (with :240) | **The subtitle total no longer agrees with the list.** The subtitle shows `paging.total` (237), but once Alabama is seeded the per-state counts add up to 236, because the dedupe folds the duplicate. Viewers are unlikely to add the counts up, but it is the same number shown two ways. | Either leave it (the backend should remove the duplicate; give the report's data issue a line for the backend owner), or subtract the duplicates the dedupe dropped from the total. I recommend the backend fix. |

## Security findings

| # | Severity | File:line | Finding | Suggested fix |
|---|----------|-----------|---------|---------------|
| (none) | | | | |

Security checklist, all items (Roku: the Android-only items are N/A):
- **Hardcoded secrets:** none. I grepped the added lines of the diff (374) for key, token, secret, password and Bearer. The only hits are dictionary keys (`key = …`, `oldKey`). No base64 blobs. The endpoint is public.
- **Transport:** only `https://mysda.itulix.com` (ScChurchTask.brs:6), through ScHttp with its CA bundle (unchanged). There is no `http://` endpoint in the diff.
- **Injection via dynamic URLs:** the state name goes through `roUrlTransfer.Escape` (ScChurchTask.brs:16). Page and per_page are integers. Nothing reaches a player or WebView. QR payloads are now https plus allowed hosts only (S1).
- **Untrusted text:** names are trimmed and cleaned. The regex works on name text only and cannot touch links. Labels render plain text with an ellipsis, and the counts are integers.
- **Logging:** `[ScChurchTask]` prints the state, page/pages, HTTP status and row count. No PII, no tokens, no URLs with auth.
- **WebView, manifest exports, SharedPreferences/keystore, cleartext config:** N/A (Roku/BrightScript).
- **Dependencies:** none added.
- **Platform claims:** nothing is committed, there is no `Platform-Ready:` trailer and `platforms.yaml` is untouched. N/A.

## The dispatcher's checks: what holds

- **The roRegex in cleanName:** escaping, what it strips, and that it cannot empty a name: see C7 above. One firmware question was not tested: whether PCRE on the Roku runs in UTF-8 mode. If it did not, `\s` could in theory match a 0xA0 or 0x85 byte inside a multi-byte character (à, Å). No live name contains such a byte, and screenshot 12 shows "écrit" intact. Notes only.
- **Count equals rows:**
  - Seeded states: `fillState(…, 1, 1, true)` gives `page >= pages`, so the count is the deduped rows. The seeding check compares the raw page-1 rows with the raw `states[]` count (:203), so Alabama (7 raw) is still seeded and then shows 6.
  - Paging states: the server count stands while `r.scPage < r.scPages` (:312-316). The last page sets rows (:240); duplicates across pages are folded before counting.
  - Past-end quirk: the answer's own `page = pages` ends it.
  - Refresh of a paged state: back to the server count until it is complete again. Holds (contract: R2; subtitle: R3).
- **The moving flag:** cannot stick (C5 above).
- **reqForFocus when focus changes mid-request:** it is set at request time (:283). The failure branch tests `reqForFocus or idx = m.stIdx` (:319). Outcomes:
  - focused, then left: the state is marked failed, and OK is needed on return (plan-compliant);
  - prefetch that became focused: failed, and the viewer sees the error for a request issued while they sat on it (fair);
  - prefetch never focused: a quiet retry after 60 s.
  - Paging failures branch on `page > 1` first, so they never hit `scFailed`.
- **More-plate and windowTop:**
  - `rowsShown = cc + 1` when there is more (:455-457).
  - With 9 slots, `windowTop` puts the plate in slot 8 when focus is on the last row: top = cc − 8, and the clamp `count − rows` gives the same value. Screenshot 10 confirms it.
  - Focus cannot land on the plate: Down is gated on `m.chIdx < churchCount() - 1` (:699), and the plate is never a church.
  - Down on the last row does nothing and returns true.
  - Whenever the plate is visible in the churches zone, chIdx ≥ cc − 7, so the paging check (≥ cc − 8) has already fired.
- **OK in both zones:**
  - States zone with rows: enter the churches (:680).
  - States zone, no rows and failed: clear, paint, pump (:684-691).
  - States zone, no rows and loading or empty: nothing.
  - Churches zone: retries only `scMoreFailed` (:705-712).
  - First call failed (`stateCount() = 0`): `loadFirst` on the press. The release falls through as unhandled, and ScScene ignores releases (ScScene.brs:571), so it is harmless.
  - Every other release is swallowed (:672).
- **Compile and runtime:**
  - The zip matches the source.
  - No name collisions: `cleanName`, `build`, `churchKey`, `isFresh`, `pump`, `requestState`, `onRest`, `fillState` and `windowTop` are not defined anywhere else.
  - The new AA and node reads are node fields declared in `addFields`, so there is no missing-key `= true` trap (KB `missing-aa-key-compared-with-boolean-is-a-type-mismatch`).
  - `m.phoneRe = invalid` on an absent key is invalid = invalid, which is safe.
  - `roRegex.ReplaceAll` exists. The `for i = 0 to n - 1` loop with n = 0 runs zero times.
  - Pinned-build runtime evidence is thin (R1).

## Plan coverage

(The plan has no numbered acceptance list. As in round 1, these are its strategy steps and its Roku plan, with the owner's Q3 answer.)

- **Q3 (b):** paged API, QR links unchanged, `design/showcase`. **MET** (ScLinks.brs is not in the diff).
- **Strategy 1:** first call `page=1&per_page=50`, states from `states[]`, page-1 seeding. **MET** (screenshot 11: 42 states, "237 churches", Alabama seeded with no extra request).
- **Strategy 2:** a 0.3 s rest loads the state, with skeleton rows and the panel cleared. **MET.** The declared deviation stands: focus does not move into the skeleton. Screenshot 12 shows the clean build.
- **Strategy 3:** one request in flight, newest focus wins, prefetch of the next state. **MET**, and improved by C5: a landing no longer pumps mid-scroll.
- **Strategy 4:** paging inside a state, stopping at `pages`. **MET**, device-tested in the debug build (C6). See R1 for the build caveat.
- **Strategy 5:** per-state cache with a 30-minute refresh. **MET**: C3 is fixed. A refresh failure with rows is not retried (C4, LOW).
- **Strategy 6:** retry once, then "Couldn't load. Press OK to try again" in that column. **MET** for both page 1 and later pages (round-1 screenshots 06/07, round-2 screenshot 10 and device-log-7).
- **Strategy 7:** trim, drop rows with no name or link, link-grade check, dedupe. **MET**, with the phone clean-up (C7) and the contract-grade link gate (S1).
- **Verification step 4:** **MET** across rounds 1 and 2, with R1 on which build the round-2 captures came from.

## Notes

- **Edge, not a finding:** a state whose page 1 has ALL its rows dropped (no name or link) but has more pages shows "No churches listed here yet." and never fetches page 2, because paging needs the churches zone, which needs rows. It cannot happen without 100 consecutive bad rows.
- **Cosmetic:** if a page-N request was deferred behind a prefetch and the viewer pressed Left before it landed, the plate keeps reading "Loading more churches…" while nothing is requested, until Right pumps again. Both conditions are needed, so this is very narrow.
- **Data, backend:** cities are still cut to their first word ("Bay", "Silver", "Winter", "St."), visible in screenshots 09, 10 and 12. The feed also holds the Oakwood duplicate (R3). Both are for the backend owner.
- I fetched the public API read-only (3 GETs) and piped the answers through node in memory. Nothing in the repo was written apart from this file.
- **Learnings candidates for the orchestrator:**
  1. "When a name clean-up can make two rows equal, clean before deduping, and say so in the contract: the order is a rule, not an implementation detail."
  2. "A capture set taken before a late count change shows itself in a seeded number: check a seeded value against the final build before accepting paging captures" (R1 was found by Alabama 7 versus 6).

Knowledge applied: review-findings-name-instances-the-fix-must-cover-the-class, brightscript-string-literals-have-no-escapes, list-lookahead-recheck-on-page-land-and-last-page-stop, missing-aa-key-compared-with-boolean-is-a-type-mismatch, key-event-fires-on-both-down-and-up-edges, focus-following-panel-clears-stale-content-at-once, evidence-must-postdate-the-fix-it-verifies, reserved-words-and-name-collisions (summary), node-fields-read-back-as-double (summary)
Knowledge contradicted: none
