# Review: 2026-11-19-live-dvr-login-qr (T6: live-player DVR row and two QR codes on Log in)

VERDICT: APPROVE

On the dispatcher's scale this is **APPROVE WITH FIXES**. There is no HIGH finding and no acceptance criterion is shown failing. M1 to M3 should be fixed or accepted by the owner before commit. Two device checks still need the owner: a real subscribed account (and a non-subscribed one), and an eye on the TV for the OS keyboard banner.

Reviewed: the uncommitted working-tree diff on design/showcase (HEAD 9cd2eac). It covers 8 modified files, each matching its dispatch sha256: ScPlayer.brs bbca8d97…, ScPlayer.xml b12fbaf4…, ScScene.brs 2c3a45c9…, ScSignIn.brs cfeb9b6c…, ScSignIn.xml a827c32f…, ScScheduleTask.brs 95227808…, ScData.brs f8999f3e…, ScQr.brs 1f325279…. The deployed out/mysdatv.zip has sha256 e309d838…; I unzipped each of the 8 entries and hashed it, and each is byte-identical to the pinned file. `git diff | sha256sum` gave e8bf6375…. The source listing has 8 M files plus the untracked task folder. **Pin: unchanged for the reviewed files.** The source listing changed after dispatch: `components/sc/widgets/ScQrCard.{xml,brs}` appeared untracked at 21:06:41 (see Notes). Those two files are not covered by this review.

## Correctness findings

| # | Severity | File:line | Finding | Suggested fix |
|---|----------|-----------|---------|---------------|
| M1 | MED | components/sc/screens/ScSignIn.xml:64 (codes at [1602, 417]) | The criterion "nothing under the OS banner" is still unproven, and two sources disagree on where the banner is. The KB (`keyboard-node-qr-banner-forces-stacked-layout`) puts it over the top ~200 px of the *screen's* right two thirds. By that geometry the codes, at y 417 and below, are clear. This file's own header comment (line 9-11) says it covers "the top ~200 px of the keyboard's right two thirds". By that geometry it would sit at y 392 to ~592, which is beside the "Sign up & subscribe" code (y 417-639) and possibly over it. Screen captures cannot show the banner (the report says so, and 05 shows none). So nothing on file settles it. | The owner looks at the TV, or takes a phone photo, with the Keyboard focused. If the banner reaches x ≥ 1602, move the column below it, for example to the below-the-keyboard layout that ScQrCard seems to be heading for. Also correct whichever comment turns out wrong: the XML header or the KB entry. |
| M2 | MED | components/sc/ScPlayer.brs:482-489 | The focused recording card is drawn as a 5-px **white frame** (a white plate under a thumb inset by 5) with a dark `shadow14` at 0x000000CC. The app's focus rule is "NO border" (docs/design/showcase.md and app KB `mysdatv-design-showcase-c`). The owner's last two commits (fc1196d, 1fbf512) put "a white glow behind the focused card, on every card". This new row is the one card type without it, and the KB records that thin borders do not survive the 2/3 downscale (`focus-border-abandoned-for-size-and-brightness`). Screenshot 07 shows the frame. | Use ScCard's treatment on the focused recording: `glow14` tinted 0xFFFFFF66 behind the card, no white frame (thumb fills the plate), plus the size and brightness step already present. Or have the owner explicitly accept the frame for this row. |
| M3 | MED | components/sc/ScPlayer.brs:473, 509 | The unfocused card title is 18 px and the meta line is `fs - 4` = **14 px**. That is about 9 device px on the 720p dev Roku. Showcase type sets Card title 20-23 and Meta 19-22. In screenshot 07, "Today · 8:30 PM" under the side cards is barely legible. (Focused: 22/18, also under the Meta range.) | Unfocused: title 20 and meta 18 at least (focused 22/19). Re-check that the two caption lines still fit under the 135-px card within the 930 baseline. |
| L1 | LOW | components/sc/ScPlayer.brs:119 | The player asks for access only when `catchupAccess = ""`. A boot-time network failure sets `"error"`, and that value sticks. A subscriber then never sees the Recordings row for the rest of the session unless they open a recording elsewhere, which goes through the dialog gate. | Ask when the value is `""` **or** `"error"`. `startAccessCheck` is already single-flight (ScScene.brs:433), and "error" raises no dialog when `pendingPlay` is invalid. |
| L2 | LOW | components/sc/ScScene.brs:517 with ScPlayer.brs:121 | Back from a recording builds a **new** live player. `rowPicked` is false and `recIndex` is 0, so focus lands on the newest recording, not the one just watched. The viewer loses their place in the row. | Carry the watched `scRec` back. For example, set it on the ScLiveItem built in onCloseOverlay (`scRec` is already a play-item field). Then make refreshRecs/onItem start `recIndex` on it. |
| L3 | LOW | components/sc/ScPlayer.brs:754-765 | `m.rowPicked = true` is set only after the "first key only reveals the chrome" early return. A late "yes" that lands after that first key can still swap the strip for the Recordings row while the viewer is looking at it. The rule in the code comment ("never swaps under a moving hand") is therefore only partly held. | In live mode, set `m.rowPicked = true` before the chrome early return. |
| L4 | LOW | components/sc/ScScene.brs:113 (with ScAuthTask.brs:76-80) | The new boot check moves the existing silent `ScClearAuth()` from an on-demand path to every launch with a stored session. Any 401/403 whose body lacks "cannot access" / "not purchased" now signs the viewer out at boot with no message. That includes a CDN or WAF 403 that has nothing to do with the session. | At least log the boot-time cause. Better: clear the session at boot only on 401, and treat other 403s as "error". |
| L5 | LOW | components/sc/tasks/ScScheduleTask.brs:88, 170 | The per-item probe goes from 2 to 3 sequential GETs, each with an 8 s wait, on every schedule load, plus the window probe. On half-hourly channels, recordings that ended 30-120 min ago, which are the row's 3rd and 4th cards, are still not probed. They can show the grey placeholder that the report saw 32 min after an end. | Probe aired items until the first one that ended more than 2 h ago, or accept the gap. Keep an eye on Home's schedule latency on the 3960X. |
| L6 | LOW (pre-existing) | components/sc/ScPlayer.brs:713 (`readPosition`), ScScheduleTask.brs:226 | Resume positions are keyed by `scRec` = the getdvr `id`, which is the start epoch. This diff's own comment (ScPlayer.brs:798-799) notes the ids "repeat across channels". Hourly channels all start at :00, so a 3ABN recording can resume at a sister channel's saved position. The row makes these recordings one click from live. | Key positions by `scStream + "_" + scRec`, falling back to reading the old key once. |
| L7 | LOW | components/sc/screens/ScSignIn.xml:67, 71; ScPlayer.brs:429, 526 | These are plan deviations not yet signed off. The two code captions from the plan ("A donation unlocks catch-up for a year", "Create your account and subscribe on your phone") became two-word titles. The row shows 6 cards, not 7 (the report notes this). The hint "Left / Right for earlier" is half wrong, because Left goes to *later*. | Add the caption lines under the titles, or record the owner's OK. Change the hint to "Right for earlier", or "Left / Right to browse". |
| L8 | LOW | components/sc/screens/ScSignIn.xml:64 | The code column spans x 1602-1824. That is outside Roku's title-safe area (right edge 1726) and 2 px past action-safe (1822; KB `tv-safe-area-and-min-text-by-platform`). The captions sit outside title-safe. | Pull the column in, or move the codes below the keyboard. ScQrCard seems to be doing this already. |

## Security findings

| # | Severity | File:line | Finding | Suggested fix |
|---|----------|-----------|---------|---------------|
| S1 | MED (pre-existing; the diff now relies on it entirely) | components/sc/tasks/ScAuthTask.brs:67 | The new boot check and the whole Recordings row depend on the check-purchase parse. That parse maps HTTP 200 + `statusCode = 200` to **"yes" no matter what `data` holds**. If the backend sends `{statusCode:200, data:false}` to a non-subscriber, every signed-in account gets catch-up. No device run has seen any real check-purchase body (app KB `mysdatv-design-showcase-c`: "NOT yet verified: … check-purchase"), and this task's subscriber path was forced in a debug build. | Before release, capture the response bodies for one subscribed and one non-subscribed account. Then decide "yes" on `data = true` only, unless the capture shows the backend never sends `data`. |
| S2 | LOW (known, out of scope) | components/sc/tasks/ScScheduleTask.brs:19 | getdvr.php and the recording HLS URLs it returns are unauthenticated. The client-side gate is the only gate, so anyone with the URL can watch. Already reported to the backend owner; the plan marks it out of scope. | Server-side: token-sign the recording URLs. |

All other checklist items are clear for this diff:
- **Secrets:** none. I grepped the diff for key, token, secret, password, Bearer and long encoded strings and found only pre-existing `m.password = ""` context lines.
- **Transport:** both new URLs are `https://www.mysdatv.com/…`, and the diff adds no `http://`.
- **Gate:** the new path cannot reach a recording without "yes". `playRecording` (ScPlayer.brs:532) goes through `m.global.playItem`, and ScScene.onPlayItem:473 checks `catchupAccess <> "yes"` before startPlayer; the diff does not touch that check. `onCloseOverlay` builds only live items. A sign-out or "unauthorized" bumps `sessionVersion`, and `onSession` then empties the row. The debug overrides are gone: a grep for `T6-DEBUG` finds 0, and `canWatchRecordings` (ScPlayer.brs:359) holds the real condition.
- **Logging:** the new `?` lines print only timing and keyboard geometry, with no PII, tokens or stream URLs.
- **Storage:** unchanged by this diff.
- **Injection:** `scBackTo` is a catalogue node, never a URL, and the deep-link handling is unchanged. The recording URL comes from the feed, as before (S2).
- **Dependencies:** none added.
- **Not applicable on Roku:** WebView, Android manifest and cleartext config.
- **Platform claims:** no commit, no `Platform-Ready:` trailer and no `platforms.yaml` change, so there is nothing to check.

## Areas the dispatcher asked about (checked, no finding unless listed above)

- **scBackTo, startPlayer, playerReturnNav and pendingPlay.**
  - `startPlayer` now reads `navHasFocus` only when no player exists (ScScene.brs:491). Only two paths reach startPlayer while a player exists: playItem from the live row, and onCloseOverlay. Both are the intended "keep the first way home".
  - Deep links: applyPendingDeepLink calls destroyPlayer before it sets playItem, so the link gets a fresh return state and no `scBackTo`.
  - Dialogs: startPlayer still clears `pendingPlay` and closes any dialog. A late "no" or "error" with no `pendingPlay` raises no dialog (onAccessDone:455). A late "yes" during live only redraws through `sessionVersion`.
  - Catch-up end-of-list: when the newest recording ends, `findNext` returns invalid and the player bumps closeOverlay. The scene then goes back to `scBackTo` live, which does not loop because the live item has no `scBackTo`. An errored recording plus Back also returns to live.
  - Device evidence for this flow is screenshots 10-12 with ECP `is_live` false, then true.
- **Observer lifecycle.** `sessionVersion` is observed scoped in onItem (live only) and unobserved in teardown next to `schedVersion`. destroyPlayer always calls teardown first. Unobserving on a catch-up or radio player that never observed is harmless.
- **Switching channels in the strip with recordings.**
  - On OK, `m.recs = []` before refreshRecs, so no index from the old channel survives. `rowPicked` keeps the viewer in the strip, and `recIndex` goes back to 0.
  - If the new channel's schedule has not arrived, the tabs and "Up for recordings" are hidden until onSched. That is a brief change, not stale state.
  - Pooled posters are rewritten before they are shown.
- **Compile risk.** The new identifiers avoid the KB builtin and reserved family: `run`, `pos`, `box`, `step`, `rem`, `tab`, `sub` and one-letter globals. The `box` parameter already failed and was renamed `plateW`. Roku compiles every component at launch (device-log-1 shows this), and screenshot 13 is the clean pinned build running. ScQrDraw has one definition across components/ and source/.
- **Render-thread cost of the QR encode.** It runs once per app session: ScSignIn is a persistent scene child and `m.codesDrawn` is set. It starts 0.1 s after the page opens and measured 240 ms for both codes, matching the KB range of 107-294 ms. That is acceptable. A Task would be the step up if the stall is felt.
- **720p versus 1080p.**
  - The dev box is 720p, so the evidence is 720p.
  - The QR geometry stays whole-pixel: the group sits at (1602, 417) and (1602, 693), the unit is 6, the origin is 36 or 24 and the plate is 222, all multiples of 3.
  - On 1080p everything is finer, and no new layout depends on device pixels except the 4-px tab bar (2.7 device px at 720p, renders cleanly in 07 and 08).
  - The real 720p issue is M3.

## Plan coverage

- **Signed out shows the live strip, unchanged.** MET, screenshots 02 and 13 (13 is the clean pinned build): no tab line, unchanged hint.
- **Log in with a subscribed account shows the Recordings row; OK plays; Back returns to live; Down/Up swap.** MET in code and on the device with a debug build that forced access (06-12; ECP `is_live` false during the recording, then true after Back). **Owner check pending:** no real subscribed account has been tried. See also S1.
- **Signed in without a subscription shows the strip only, with no dialog.** MET in code: `canWatchRecordings` requires "yes", and onAccessDone returns before any dialog when `pendingPlay` is invalid. **Not device-verified**, since no account was available.
- **Log in shows both codes, each decodes to the exact URL, typing still works.**
  - Codes: MET. The report decodes both from capture 05 with a negative control, and I read 05: both codes are present and whole.
  - Typing: the keyboard observer is unchanged and only x moved. No typed-text capture exists (minor).
- **Nothing under the OS banner.** PENDING, see M1.
- **Sideloaded; screenshots read; ECP proves the recording plays.** MET (debug build for the recording; the clean build was sideloaded, 13).
- **Owner Q1/Q2: both codes point at www.mysdatv.com.** MET (ScSignIn.brs:98-99).

## Notes

- **Changed after dispatch, not reviewed:** `components/sc/widgets/ScQrCard.xml` and `.brs` appeared untracked at 21:06:41, after the report (21:05) and after my first pin. No pinned file references them, and they are not in out/mysdatv.zip.
  - Their header says "Two of them sit side by side, below the content, on Log in and on Account (owner, 2026-11-19: 'below, horizontally')". That suggests the reviewed right-hand column (M1, L7, L8) is already being replaced.
  - ScQrCard.xml includes only ScTheme.brs and ScQr.brs. Check that `ScFont` and `ScShape` are in its scope (KB `source-dir-not-in-component-scope`) before it is wired in, and review it as its own change.
- The report's learnings candidates are sound. I would add one: "the KB banner geometry and the app's XML comment disagree; settle it by eye" (M1).
- No waivers recorded.

Knowledge applied: keyboard-node-qr-banner-forces-stacked-layout, on-device-qr-encoder-in-brightscript, reserved-words-and-name-collisions, async-gate-needs-generation-and-visible-state, equal-value-field-writes-do-not-notify, hls-vod-never-reports-finished, focus-border-abandoned-for-size-and-brightness, tv-safe-area-and-min-text-by-platform, mysdatv-design-showcase-c (app), gating-a-shared-open-helper-misses-direct-route-pushes (summary), session-transitions-must-reach-in-flight-and-loaded-work (summary), source-dir-not-in-component-scope (summary)
Knowledge contradicted: none. The app's ScSignIn.xml comment differs from `keyboard-node-qr-banner-forces-stacked-layout` on whether the banner is anchored to the screen or the keyboard. That is unresolved, not a proven contradiction (M1).
