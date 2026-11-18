# Report: Roku, Churches with QR links

## STATUS
DONE (prototype). Device-verified for the signed-out walk; two independent reviews APPROVE (review.md, review-2.md); round 3 below closes review-2's S1, N1 and N3.

## BRANCH
`design/showcase` (owner-approved 2026-11-18). Not pushed.

## Summary
A sixth capsule destination, "Churches": the SDA church directory the mysda
Android apps show as their "YT" tab, without a player. The states are on the
left (title case, with counts), the focused state's churches are in the middle
(name, city), and a panel on the right shows the focused church's link as a
QR code on a white plate, with the name, "City, State", what the code opens
(YouTube / Facebook / a link) and the link as text. The code is generated ON
the device by a new BrightScript encoder (byte mode, level M, versions 1-10)
and drawn as one Rectangle per run of dark modules. There is no QR web service
and no new dependency. The data contract came from the mysda session on
2026-11-18: a raw JSON array of {state, city, church, link}, grouped by state
in first-seen order.

## Files changed
- New `source/ScQr.brs`: the QR encoder.
- New `components/sc/screens/ScChurches.{xml,brs}`: the screen.
- New `components/sc/tasks/ScChurchTask.{xml,brs}`: the fetch, parse and group.
- `components/sc/widgets/ScNav.{brs,xml}`: six items, with the count derived from
  `m.names` (the hard-coded 4/5 are gone).
- `components/sc/ScScene.{xml,brs}`: the `churches` screen and its name.
- `tools/build-sc-assets.ps1` + new `images/png/sc/nav_churches.png`: the
  chapel glyph.
- Task tools (copied here, not scratch): `tools/to-rgba.ps1`,
  `tools/decode-qr.js` (decodes a capture's QR with jsQR from
  D:/Tulix/coacb_roku/node_modules).

## Decisions
1. **On-device QR, not a web service** (owner's pick). Mask by penalty rules 1, 2
   and 4. Rule 3 (finder look-alikes) is left out: any mask decodes, and the
   penalty only ranks them.
2. **The panel follows focus** (owner approved the layout). Words update at once. A code made before is drawn at once (round 2); a new one follows the rule below.
   The old code is cleared straight away and the new one drawn 0.25 s after
   focus settles, so a code never sits beside another church's name. Codes are
   cached per link.
3. **Module size is a multiple of 3 plane px** (whole pixels at 720p). The quiet
   zone is 4 modules, the area at most 513 px on a 540 plate.
4. **The list loads the first time the screen is shown**, not at boot
   (hidden-screen-first-fetch-races-the-landing-screen).
5. **Columns are fixed row slots over a window**, not a list widget, so the rows are
   the Showcase's own pills and plates. One row of look-ahead is kept in view.
6. **The data's quirks are kept** except title case. Truncated states ("New",
   "North", "South", "French") come from the server. One link is two URLs run
   together (Miami Temple, Florida). The code carries exactly what the server
   sends.

## Verification
- `node tools/check-scope.js`: scope check clean.
- brighterscript 0.73 (copy in scratch, rootDir relative): 0 errors. A planted
  `x = = 1` in ScQr.brs was caught (1 of 1 plants, BS1081), so the clean result
  counts.
- QR decode of device captures with jsQR. Decoded text vs the endpoint's link:
  - 02 Birmingham First SDA Church: `https://www.youtube.com/channel/UCGtqeJV-eeG2o5IzrHKcmmg`, exact.
  - 03 Miami Temple (125 bytes, the longest; version 8): exact, including the
    doubled URL.
  - 04 Bethesda Temple (Facebook): `https://www.facebook.com/omahabethesdatemple/live_videos/`, exact.
  - Plant: a crop of the church list with no code gave NO CODE FOUND (the
    decoder does not invent a result).
  - Not checked: a phone camera scan (owner to try), and versions 9-10 (no link
    in the data needs them).

## Device verification
Roku Express 3960X, 192.168.0.106, sideloaded 2026-11-19. Captures in
`screenshots/`:
- 01: the capsule with the Churches item (chapel glyph).
- 02: Churches loaded, "237 churches", Alabama with 7 churches, and the code for the first.
- 03: Florida (state 10), church 12 of 17. Both columns scrolled; the long link decodes.
- 04: Nebraska (state 27); the Facebook hint and link.
- 05: Left from the states opens the capsule over the dimmed page.
- 06: Back from the capsule goes Home (as on the other screens).

Console: `[ScChurchTask] <- 200 (39 states)`, no errors, no debugger.
Not walked: the failure note (endpoint down) and the "too long" note (no link
exceeds version 10).

## Learnings candidates
- PowerShell variables are case-blind: a `-Out` parameter and a `$out` buffer are
  the same variable, and the script fails with "Unable to index into an object of
  type System.String" on every pixel (cost a 120 s timeout here).
- A QR encoder fits in about 420 lines of BrightScript. XOR is `(a or b) and not (a and b)`
  (`and`, `or` and `not` are bitwise on integers), and `run` and `pos` are reserved
  names. Drawing one Rectangle per dark run keeps the code crisp at any scale,
  where a Poster of a generated bitmap would be resampled.
- A device capture can be checked for a QR's payload on a machine with no Python:
  raw RGBA from System.Drawing, then jsQR in Node (a sibling repo's
  node_modules).

## Blockers
None for the prototype. Open for the owner:
- Should the truncated state names be fixed on the server?
- Should the doubled Miami Temple link be fixed on the server?
- Is a phone scan good from the sofa?

Knowledge applied: hidden-screen-first-fetch-races-the-landing-screen (summary), key-event-fires-on-both-down-and-up-edges (summary), skeleton-replacing-a-modal-loader-four-traps (summary; a loading note only, no skeleton in this prototype)

## Round 2: the loader (owner) and the review's findings (review.md, APPROVE)
- **Owner, 2026-11-19, loader:** while a new code is made, the plate shows a
  pulsing ghost (three finder squares where a code's corners land, plus
  "Creating code..."). A cached code is drawn at once with no loader. Seen on
  the device with the timer stretched to 5 s for the capture (07, 08), then
  restored to 0.25 s.
- **C1 (MED), the cost on the render thread, measured on the 3960X:**
  - Encode 107-175 ms for typical links, 294 ms for the 125-byte v8 link.
  - Draw 24-60 ms (217-600 Rectangles).
  - A cached code is about 35 ms (draw only).
  - Encoding only runs after focus has settled for 0.25 s, so a stall is at most
    about 0.3 s after a pause. Kept on the render thread for the prototype;
    moving ScQrMatrix into a Task is the follow-up if it feels sticky.
  - The timing print was removed after measuring.
- **C2:** the cache is case-sensitive (SetModeCaseSensitive).
- **C3:** the cache holds runs [x, y, len], not matrices, and at most 24 links (FIFO).
- **C4:** the panel is at [1257, 159] and the code's offset is a multiple of 3,
  so the comment's whole-pixel claim now holds.
- **C5:** not changed. All links are ASCII today; a non-ASCII link would need an
  ECI header (recorded as a limit).
- **C6:** the name is bottom-aligned in its two-line box, so a one-line name
  sits on "City, State" (10).
- **C7:** recorded. The list's loading state is a text note, not a skeleton. The
  QR panel's loader is the pulsing ghost.
- **S1:** only an http(s) link becomes a code. The YouTube / Facebook hint goes
  by the link's host (`hostIs`: the domain or a subdomain), not by a word
  anywhere in it.
- **Device after the fixes:**
  - 09: Miami, v8, decodes exactly.
  - 10: Birmingham First, decodes exactly.
- **Console:** `[ScChurchTask] <- 200 (39 states)`, no errors.
- **Mid-round:** a loop variable named `run` (reserved) failed the device compile
  ("Builtin function call expected"). Neither check-scope nor this
  brighterscript run flags reserved names, so the device is the check. Renamed
  to `seg`.

## Round 3: review-2 (APPROVE) follow-ups
- **S1:** hostOf now works in a browser's order. The authority ends at the first `/`, `\`, `?` or
  `#`, the user part ends at its LAST `@`, then the port goes. Ported to Node and compared with
  `new URL().hostname` on 11 cases, including the review's
  `youtube.com:443@evil.example` and `evil.example\.youtube.com`: 0 differences.
- **N1:** showChurch stops the timer and clears qrPending first on every path. onQrTimer
  draws only a non-empty qrPending.
- **N3:** the comments and Decision 2 now describe the cached path.
- **Checks:** check-scope clean; bsc 0 errors.
- **Device:** re-sideloaded; 11 decodes `https://www.facebook.com/omahabethesdatemple/live_videos/`
  exactly; hint "watch on Facebook"; console clean.
- **Still open, the owner's call:**
  - C1/N2: the encode (107-294 ms) runs on the render thread, so the ghost's pulse freezes
    while it runs. The fix is a Task.
  - C5: non-ASCII links would need an ECI header.
  - C7: the failure / "too long" / "No link" notes were not walked on the device.