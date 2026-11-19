# T6 · mySDAtv Roku — DVR row in the live player, two QR codes on Log in

Branch: `design/showcase` (owner pre-approved, no new branch). Pipeline: /solo.
Part 1 first, then part 2. Flutter (T7) follows this design, so the API calls
and behaviour are written out in full below.

## What the repo and backend already give us (found, not assumed)

| Thing | Where | Notes |
|---|---|---|
| Subscription check | `POST https://sda.wchupload.tulix.net/api/payments/customer/check-purchase`, body `{"collectionId":null,"productId":15}`, headers `Authorization: Bearer <accessToken>`, `X-Session-Token: <sessionToken>`, `X-Session-Token: <accessToken>` | `components/sc/tasks/ScAuthTask.brs` `checkAccess()`. 200 + `data:true` or `statusCode:200` = yes; 401/403 with "cannot access"/"not purchased" or 404 = no; other 401/403 = session ended. Result lands in `m.global.catchupAccess` = `"" \| yes \| no \| error`. |
| Sign-in | `POST .../api/login` `{email,password,deviceInfo:"rokuTV"}` | unchanged |
| DVR list (recordings) | `GET <channel.dvr_url>` = `https://livetv.mysdatv.com/api/getdvr.php?id=<stream>`, no auth | `ScScheduleTask` already loads it per channel (21 days; items `id`, `starttime`, `endtime`, `duration`, `title`, `thumb`, `stream` = recording HLS). The client-side gate (check-purchase) is the only gate. |
| Donation page | `https://www.mysdatv.com/mysdatv-donation-page` | decoded from the shipped `images/png/donation.PNG` (tools/decodeqr.js) and linked as "Donate" on www.mysdatv.com |
| Sign-in / subscription web page | candidates: `https://apps.mysdatv.com/register` ("Create your account", states the subscription and the donation-for-a-year promotion, links to Sign in) or `https://apps.mysdatv.com/login` ("Watching Live is free. Watching DVR needs subscription.") | the old build only said "subscribe now at https://mysdatv.com"; www.mysdatv.com itself has no sign-in or subscribe link. **Owner picks (Q1).** |

## Part 1 — live player: DVR row for subscribers, other live channels otherwise

Today the live player (`ScPlayer`, mode `live`) shows a bottom strip of the
other live channels (Left/Right, OK switches). Change:

1. **Who gets which overlay** (decided in the player from `m.global`):
   - signed in AND `catchupAccess = "yes"` AND this channel has recordings
     → **Recordings row** ("Earlier on <channel>").
   - not signed in, or `no` / `error` / still unknown, or no recordings
     → **Live channels strip** (today's behaviour, unchanged).
   - signed in and access still unknown → the player asks the scene to run
     check-purchase once (`m.global.checkAccess`); the strip shows meanwhile
     and swaps to the Recordings row when "yes" lands (no dialog — the live
     picture keeps playing). The scene also runs the check once at boot
     when a stored session exists, so it is usually known before playback.
2. **Recordings row**: up to 7 cards visible, scrolling like the strip; the
   playing channel's aired programmes, **newest first**, up to 48 (about two
   days on hourly channels; 3ABN has titled ones). Card = frame grab
   (`thumb`, logo card when the channel has no real grabs), title (or
   "3 PM hour"), "Today · 2:00 PM" / "Tue · 2:00 PM". OK plays the recording
   through the existing catch-up player (seek bar, ±10, next episode =
   the next one in this list). **Back from that recording returns to the
   live channel** it was opened from, not to the page behind.
3. **Subscribers keep channel switching**: a two-word tab line above the row,
   `Recordings · Live channels`; Up/Down swaps the row (one row on screen,
   one layout). Hint line: "OK to watch · Down for live channels".
4. Radio and the catch-up player are unchanged.

Files: `components/sc/ScPlayer.{xml,brs}`, `components/sc/ScScene.brs`
(boot check, Back-to-live), `components/sc/tasks/ScScheduleTask.brs` (one
more list on the schedule node: `scRecent`, aired newest first), maybe
`source/ScData.brs` (a back-to field on the play item).

## Part 2 — two QR codes on the Log in screen

`ScSignIn` keeps the form + on-device keyboard (Roku cert 2.2/4.12 — QR never
replaces typed sign-in, KB `qr-instead-of-dpad-text-entry`). Add a right-hand
column with two codes, each ~180 px on a white plate with a caption:
- **"Donate"** → donation page URL above, caption "A donation unlocks
  catch-up for a year".
- **"Sign up / subscribe"** → the URL picked in Q1, caption "Create your
  account and subscribe on your phone".

Both encoded on the device with the existing `ScQr` encoder (the same as the
Churches screen), once, the first time the screen opens. The keyboard moves
left to the form's edge (x 184) so the column fits at x ≈ 1610–1824; the
OS "use your phone" banner over the keyboard's top-right is checked on the
device, and the column moves down if it covers a code. The bottom note
changes to point at the codes. The Account screen keeps its donation card.

Files: `components/sc/screens/ScSignIn.{xml,brs}`.

## Acceptance

- Signed out → live player shows the live channels strip (unchanged); log in
  with a subscribed account → the Recordings row; OK plays a recording; Back
  returns to live; Down/Up swaps to channels and back.
- Signed in without subscription → strip only, no dialog.
- Log in screen shows both codes, each decodes (phone-style decoder on a
  device capture) to the exact URL; typing still works; nothing under the
  OS banner.
- Sideloaded on the Roku, screenshots read, ECP media-player query proves the
  recording plays.

## Out of scope / noted

- "Start the programme on now from the top" (the on-now item's HLS may not
  exist until it ends) — not in this task.
- Roku Dashboard static analysis errors on the legacy `Keyboard` (4.12) and
  wants `getUserData` (RP 2.1) — pre-existing, a release-time follow-up.
- getdvr.php has no auth (known, reported before).

## Owner answers

- Q1 (2026-11-19): use www.mysdatv.com for the QR codes. The apps.mysdatv.com
  pages are not real. Proposed: Sign up / subscribe → `https://www.mysdatv.com/`,
  Donate → `https://www.mysdatv.com/mysdatv-donation-page`. Confirmation asked as Q2.

- Q2 (2026-11-19): "a) yes, build it" - those two URLs, the rest of the plan as written.
- NOTE (2026-11-19, after round 1): "I like it more below Horizontally. and
  also We can show it on ProfileScreen of TV versions not only on
  LoginScreen" - the codes become two cards side by side below the keyboard
  on Log in, and the same two cards replace the single donation card on
  Account (the Roku Profile screen). Shared widget ScQrCard + source/ScLinks.brs.

## Needs from the owner

- Q1: approve this plan and pick the sign-in/subscription URL.
- A subscribed test account to verify the Recordings row on the device (I
  will ask when I get there; without it I can verify only the signed-out and
  no-subscription paths and force the "yes" path in a debug build).
