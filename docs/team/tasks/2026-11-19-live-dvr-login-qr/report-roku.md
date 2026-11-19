# Report · roku · T6 live-player DVR row + Log in QR codes

## STATUS

IMPLEMENTED, device-verified on the dev Roku (192.168.0.106). The subscriber
path was verified with a temporary debug build, because no subscribed account
was available to type in. That build forced `canWatchRecordings()` to true and
skipped the scene's catch-up gate; both patches are reverted, and the grep for
`T6-DEBUG` in source/ and components/ returns 0. A real-account check still
needs the owner (see Blockers).

## BRANCH

`design/showcase` (owner pre-approved; no new branch). Nothing pushed.

## Summary

**Part 1. The live player shows a DVR list to subscribers and other live channels to everyone else.**
- Subscriber = signed in AND `m.global.catchupAccess = "yes"`. That value comes
  from `POST https://sda.wchupload.tulix.net/api/payments/customer/check-purchase`
  with body `{"collectionId":null,"productId":15}`. The headers are
  `Authorization: Bearer <accessToken>`, `X-Session-Token: <sessionToken>` and
  `X-Session-Token: <accessToken>`, the same as before.
  - The scene now runs this check once at boot whenever a stored session exists.
  - The player asks for it (`m.global.checkAccess`) when the viewer is signed in
    and the answer is still unknown.
  - The answer arrives on `sessionVersion` and never raises a dialog.
- The DVR list comes from `GET <channel.dvr_url>` =
  `https://livetv.mysdatv.com/api/getdvr.php?id=<stream>` (no auth), which the
  app already loads per channel in `ScScheduleTask`. A new list on the schedule
  node, `scRecent`, holds every aired programme that has its own stream, newest
  first, up to 48.
- With access, the overlay shows a **Recordings** row in place of the channel
  strip:
  - Up to 6 cards. The focused card is 336x189 on a white frame. Each card
    shows its frame grab, or the channel logo when the grab is not real yet.
    Under it: the title (or "3 PM hour") and "Today · 8:00 PM".
  - OK plays the recording in the existing catch-up player. Next episode = the
    next newer recording.
  - Back, or the end of the last recording, returns to **that channel live**
    (`scBackTo` on the play item, handled in `ScScene.onCloseOverlay`).
  - A tab line, `RECORDINGS  LIVE CHANNELS`, sits above the row, with an accent
    bar under the row on screen. Down shows Live channels and Up shows
    Recordings. Only one row is on screen at a time.
  - The row never swaps under the viewer: once they press a key in the player,
    a late "yes" does not switch rows (`m.rowPicked`).
- Without access (signed out, no subscription, error, unknown, or no
  recordings): today's live channels strip, unchanged and with no tab line.

**Part 2. Two QR codes on the Log in screen.**
- The codes sit in a column right of the keyboard (x 1602, y 417; plates
  222x222; 2-module quiet zone; 6-px modules). The keyboard moves from x 258 to
  x 160.
  - "Sign up & subscribe" → `https://www.mysdatv.com/`
  - "Donate" → `https://www.mysdatv.com/mysdatv-donation-page`
  - The owner chose both pages in Q1/Q2. The donation URL is also what the old
    `images/png/donation.PNG` encodes.
- The codes are encoded on the device with the existing `ScQr` encoder, once,
  0.1 s after the page first opens: 240 ms for both, measured. The new shared
  `ScQrDraw()` in `source/ScQr.brs` draws them.
- The bottom note now reads "No account or subscription yet? Scan a code with
  your phone's camera." Typed sign-in is unchanged.

**Pre-existing bug fixed on the way (it emptied the new row):** `ScScheduleTask`
decided a channel "has no real grabs" by probing the newest programme that
ended at least 30 minutes earlier. On 3ABN at 9:00 PM that programme's grab was
still the 6542-byte placeholder 32 minutes after it ended, while the 8:00 grab
was real (8737 bytes). The whole channel was therefore flagged, and every
card, on Home too, fell back to the logo.
- The probe now uses the newest programme that ended at least 2 hours ago.
- The per-item probe now covers on-now plus the two programmes before it (was 2).

## Files changed

- `components/sc/ScPlayer.xml`: `tabs` group (two labels + accent bar),
  `recRow` group, header comment.
- `components/sc/ScPlayer.brs`: `canWatchRecordings`, `refreshRecs`,
  `drawRows`, `drawTabs`, `drawRecRow`, `playRecording`, `onSession`; live-mode
  keys (Up/Down, Left/Right/OK on the row); strip hint adds "· Up for
  recordings"; session observer added and removed in `teardown`.
- `components/sc/ScScene.brs`: access check at boot (`finishBoot`);
  `startPlayer` keeps the first player's way home when one player replaces
  another; `onCloseOverlay` goes back to `scBackTo` live.
- `components/sc/tasks/ScScheduleTask.brs`: `scRecent` list; placeholder probe
  window (30 min → 2 h) and per-item probe count (2 → 3).
- `source/ScData.brs`: `scBackTo` node field on every play item.
- `source/ScQr.brs`: `ScQrDraw(group, text, plateW, quiet)`.
- `components/sc/screens/ScSignIn.{xml,brs}`: codes column, `codeTimer`,
  `drawCodes`, keyboard x 160, hint widths 1380, new note.
- Task folder:
  - `plan.md`, this report
  - `screenshots/01-13`
  - `device-log-1..3.txt`
  - `tools/decodeqr.js` (decodes the shipped donation PNG)
  - `tools/roku-log.ps1` (console reader on 8085)
  - `tools/to-rgba.ps1` + `tools/decode-qr.js` (copied from the churches task;
    decode device captures)

## Decisions

- **One row on screen at a time, Up/Down to swap.** A subscriber keeps channel
  switching, and the layout never changes height.
- **No dialog in the live player.** Access arrives quietly. The strip is a
  complete experience on its own, so "unknown" and "error" simply look like
  "not subscribed".
- **48 recordings, newest first.** That is about two days on an hourly channel.
  The Catch-up screen remains the place for the full 21 days.
- **Back from a recording returns to live**, because the viewer came from live.
  The Back after that still returns to the page the live player was opened
  from: `m.playerReturnNav` is kept across the swap (screenshot 12 shows Home
  with Watch live focused).
- **QR codes are made on the device, not baked as PNGs.** Both look the same,
  and either URL can be changed in one line.
- **`ScQrDraw` is a new shared helper.** ScChurches keeps its own cached
  `runsOf` drawing; I did not refactor it (no drive-by changes).

## Verification

Device: Roku at 192.168.0.106; captures are 1280x720 JPEG from `/pkgs/dev.jpg`.
I read every screenshot.

1. First install: **compile error** `Builtin function call expected` at
   `ScQr.brs(449/451)`. The parameter was named `box`, and `Box()` is a builtin
   (KB `reserved-words-and-name-collisions`). Renamed it to `plateW`.
   Logged in `device-log-1.txt`.
2. `02-live-signed-out`, and `13-clean-build-live-signed-out` on the final
   clean build: the live channels strip, no tab line, hint unchanged.
3. `04-signin-form-focus`, `05-signin-keyboard-focus`: both codes are right of
   the keys and aligned with their top row. The console prints
   `codes drawn in 240 ms; keyboard x= 160 w= 1416 h= 380`, so the keyboard
   ends at 1576 and the column starts at 1602.
4. QR decode from the device capture `05` (System.Drawing crop → jsQR):
   - `join: DECODED https://www.mysdatv.com/`
   - `give: DECODED https://www.mysdatv.com/mysdatv-donation-page`
   - negative control (crop over the keys): `NO CODE FOUND`
5. Debug build (access forced):
   - `06`: the Recordings row on 3ABN with real grabs; the two newest show
     the logo because their grabs are still placeholders.
   - `07`: focus on Well News.
   - `08`: Down shows LIVE CHANNELS, with "Up for recordings" in the hint.
   - `09`: Up returns to RECORDINGS with the same card focused; the file is
     byte-identical to 07.
6. `10-recording-playing` + ECP `/query/media-player` after OK:
   `state="play"`, `is_live` false, duration 814814 ms, position advancing,
   container hls. Before that press, the same query showed `is_live` true:
   the first OK only revealed the hidden chrome, as designed.
7. `11-back-to-live`: Back gives 3ABN live with the Recordings row; ECP shows
   `is_live` true. `12-back-to-home`: a second Back lands on Home with
   Watch live focused.
8. The Bash/PowerShell screenshot-integrity check covers PNGs only:
   "0 PNGs: 0 ok, 0 fail; 13 other files not checked". The JPEGs were read
   one by one.

Not verified:
- **A real subscribed account.** Needs the owner's sign-in on the device.
- **Roku's OS "use your phone" banner over a focused Keyboard.** It does not
  appear in dev screenshots (`05` shows none), so whether it reaches the code
  column needs an eye on the TV.

Knowledge applied: keyboard-node-qr-banner-forces-stacked-layout,
on-device-qr-encoder-in-brightscript, qr-instead-of-dpad-text-entry,
roku-static-analysis-rules-for-sign-in-channels,
verify-a-qr-from-a-device-capture-without-python,
reserved-words-and-name-collisions (summary, after the compile error),
roku-media-player-query-proves-playback (summary)

## Learnings candidates

- **Placeholder-grab detection needs a long window.** One "ended ≥30 min ago"
  probe flagged 3ABN as having no grabs, because a grab can still be the
  6542-byte placeholder 32 minutes after its programme ended. App-level fact;
  update `mysdatv-feed-derived-design-rules` or the church API note.
- **`box` as a parameter name fails the device compile** ("Builtin function
  call expected"), the same family as `run`. Add it to
  `reserved-words-and-name-collisions` if it is not listed.
- **A dev screenshot does not show Roku's OS keyboard QR banner**, so a capture
  cannot prove the area is clear.
- **For T7 (Flutter):** the full API and behaviour contract is in Summary
  above.

## Blockers

None for the code. Owner sign-off on the device needs:
- a subscribed account signed in on the Roku, to see the real "yes" path;
- an eye on the TV for the OS keyboard banner versus the code column.

## Out of scope / follow-ups

- Roku Dashboard static analysis errors on the legacy `Keyboard` (4.12) and on
  missing `getUserData` (RP 2.1). This is pre-existing and needs fixing before
  store submission.
- "Start the programme on now from the top" for subscribers.

## Round 2 (after review.md and the owner's note)

Owner NOTE (2026-11-19): "I like it more below Horizontally. and also We can
show it on ProfileScreen of TV versions not only on LoginScreen".

**QR rework**
- New widget `components/sc/widgets/ScQrCard.{xml,brs}`: a 600x222 dark card
  with the code on a 222 white plate on the left and kicker, title and body on
  the right.
  - A new url clears the old code at once, then encodes 0.1 s later.
  - It logs the encode time.
- New `source/ScLinks.brs` holds both URLs and the card words, shared by the
  two screens:
  - `ScSiteUrl()` = `https://www.mysdatv.com/`
  - `ScDonateUrl()` = `https://www.mysdatv.com/mysdatv-donation-page`
- **Log in** (`ScSignIn`):
  - The right-hand column, its plates, labels, timer and `drawCodes` are
    gone.
  - The keyboard moves to y 372, and its hint to y 760.
  - Two cards sit at (186, 801) and (822, 801), and the "No account..." note
    sits right of them at x 1458. The row ends at y 1023, inside title-safe.
  - `ScQr.brs` is no longer in ScSignIn's scope.
- **Account / Profile** (`ScAccount`):
  - The "Give instead" card, which used the baked donation.PNG, is replaced
    by the same two cards at the same place.
  - The buttons move from y 716 to y 702.
  - The codes are made the first time the page shows.
  - `images/png/donation.PNG` is now unused but kept, since deleting an asset
    was not asked for.

**Review fixes**
| ID | Status | What |
|---|---|---|
| M1 | superseded | The codes now sit below the keyboard, outside both readings of the banner's position; an eye on the TV is still welcome |
| M2 | FIXED | Recording focus is the app's glow14 white glow (0xFFFFFF66, 30 px), with no white frame. Grabs sit on a 3-px dark plate. The live strip keeps its original shadow. My first edit hit the strip's identical block by mistake; I caught it on the device (pixel samples) and moved it to the row |
| M3 | FIXED | Focused card 23 / 20 px, others 20 / 19 px (were 22/18 and 18/14) |
| S1 | OPEN, owner | Pre-existing check-purchase parsing; needs real response bodies from a subscribed and an unsubscribed account |
| L1 | FIXED | The player asks again when access is "error" |
| L2 | FIXED | Back from a recording highlights it: live item `scRec` = the recording's id, kept by `refreshRecs` until found, cleared on a channel switch |
| L3 | FIXED | Any live-mode key, including the reveal key, sets `rowPicked` |
| L4 | accepted | Boot check signs out on an unexpected 401/403; this is the same rule the old check used, now run earlier |
| L5 | accepted | One extra probe request per schedule load |
| L6 | out of scope | Pre-existing resume-key collision |
| L7 | FIXED / owner | Hint reads "Left / Right to choose"; QR captions are now fuller cards; 6 cards (the row's wider cards) |
| L8 | superseded | Row is inside title-safe |

**Device, round 2** (Roku 192.168.0.106; screenshots 14-20, all read)
- `14-account-qr-row`: two cards under the buttons.
- `15/16-signin-qr-row(-keyboard-focus)`: cards under the keyboard and its
  hint, with the note to their right.
- Console: `[ScQrCard] https://www.mysdatv.com/ drawn in 99 ms`;
  `.../mysdatv-donation-page drawn in 156 ms`.
- Decodes from the device captures (jsQR):
  - 14 join → `https://www.mysdatv.com/`
  - 14 give → `https://www.mysdatv.com/mysdatv-donation-page`
  - 14 control → NO CODE FOUND
  - 16: the same three results.
- Fixed after first look: the kicker was 16 px and the donation body was
  truncated. Now the kicker is 18 px, the body box 84 px, and the donation
  text shortened.
- Debug build (access forced, reverted; `T6-DEBUG` markers: 0):
  - `17`: glow behind the focused card. Pixel samples 7 px left of it read
    58/58/56, against 3/4/6 on plain video.
  - `18`: Back from "Asi Conventions" lands on live with Asi Conventions
    focused. That capture came from the build where the glow was still on
    the strip; the L2 code has not changed since.
  - `19`: the Live channels row keeps its look.
  - Recording playback, ECP: `is_live` false, duration 3035302 ms.
- `20`: the clean build, signed out: the strip, no tab line.

Known look: small caps kickers render with tight word spacing on this 720p
box ("SCANTO SIGNUP"). The existing "NEXT EPISODE" kicker in screenshot 10
does the same, so it is app-wide and not new here.

## Round 3 (after review-2.md)

| ID | Status | What |
|---|---|---|
| L8r | FIXED | Log in note narrowed to 264 px wide, so it runs x 1458-1722, inside title-safe (1726). Correction to Round 2: the card row ends at y 1023, the ACTION-safe bottom, not inside title-safe (972). Moving it up would collide with the keyboard, so it stays: the owner placed it "below", and the codes' text sits inside action-safe |
| N1 | FIXED | Account no-subscription status now reads "Catch-up isn't on this account yet: subscribe or donate with a code below." (it named the removed "Give instead" card) |
| N2 | FIXED | Kicker 19 px (Meta minimum), label 28 px tall. The 720p word-spacing look ("SCANTO SIGNUP") is the font at that size; "NEXT EPISODE" has it too |
| L7r | OWNER | 6 recording cards instead of the plan's 7: the cards are 16:9 frames, wider than the strip's logo cards. Asked in the DONE message |

These were small text and layout changes with no security surface. I walked
the reviewer.md security checklist myself (no secrets, no new URLs, no new
input, https only, no PII in logs): clean.

Device, final build (out/mysdatv.zip sha256 2848ced4...):
- `21-account-final`: join → `https://www.mysdatv.com/`, give →
  `https://www.mysdatv.com/mysdatv-donation-page`, control NO CODE FOUND.
- `22-signin-final`: the same three results. The note wraps to three lines
  inside title-safe.

## Final STATUS

DONE on the device for everything except the two owner checks:
1. A real subscribed account, and a real unsubscribed one. This proves the
   live "yes" path and lets us capture the check-purchase bodies for S1.
2. An eye on the TV for Roku's keyboard banner.

platforms.yaml is not written: the repo has none, and the subscriber path
has not been seen with a real account, so `roku` is not declared verified
by this task.

Reviews: review.md (APPROVE WITH FIXES), review-2.md (APPROVE WITH FIXES:
LOWs only, fixed above).
