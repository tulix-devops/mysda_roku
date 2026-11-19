# Review 2: 2026-11-19-live-dvr-login-qr (T6 round 2: DVR row fixes, QR cards below on Log in and Account)

VERDICT: APPROVE

On the dispatcher's scale: **APPROVE WITH FIXES.** No HIGH finding, and every acceptance criterion is met or waits only on the owner. Round 1's three MED design findings are resolved. Four small LOW fixes are worth doing before commit: N1, N2, the L8 remainder and the L7 sign-off. S1 (pre-existing, MED) still needs real check-purchase bodies before release.

Reviewed: the uncommitted working tree on design/showcase (HEAD 9cd2eac).
- `git diff | sha256sum` = 04be16cf…, covering 10 modified files.
- Three untracked sources: ScQrCard.brs 80e5a649…, ScQrCard.xml 721404b6…, ScLinks.brs 02e13f3b….
- All 13 sources match the dispatch pin byte for byte. Two examples: ScPlayer.brs 236922c9…, ScSignIn.xml 7f2244f8….
- The deployed out/mysdatv.zip is 9595ac3f…. I extracted each of the 13 entries (`unzip -p`) and hashed it, and each is identical to its working-tree file.
- The source listing has 14 entries: 10 M, 3 untracked sources and the untracked task folder.

**Pin: unchanged.** I took it at the start and again just before writing.

## Earlier findings (round 1)

| ID | Status | Evidence |
|----|--------|----------|
| M1 | SUPERSEDED | The codes moved out of the column right of the keyboard. They are now two cards at y 801-1023 (ScSignIn.xml:63-64). The keyboard is at (160, 372), and the console gives h 380, so it ends at y 752. Its hint sits at 760-792.<br>Under both banner readings, nothing app-drawn is in the banner's area: (a) the KB reading, top ~200 px of the screen; (b) the XML comment's reading, top ~200 px of the keyboard, y 372-572, which is over keys only.<br>Screenshot 16 (keyboard focused) shows the full card row. The banner itself is still unseen (captures cannot show it), and the ScSignIn.xml:9-11 comment still disagrees with the KB. See Notes. |
| M2 | FIXED | I extracted `sub drawStrip()` from HEAD and from the working tree and diffed the two bodies. They differ only on the hint lines (78 lines; the hint gets "· Up for recordings"). The strip's `shadow14` at 0x000000CC is in both: HEAD:259-260, now :291-292. So the strip is back to its original, and the mis-applied first attempt is gone.<br>The recordings row (ScPlayer.brs:446-448, 485-488) now uses `glow14` 0xFFFFFF66 with ScCard's exact geometry: g = 30, offset +6 (ScCard.brs:121-124). There is no white frame: the focused grab sits on a 3-px `cSurface` plate.<br>Class check: `glow14` is used only in ScCard and the rec row, and the rec row is the only new card type.<br>Screenshot 17 shows the glow and no frame. Screenshot 19 shows the strip still on its dark shadow. |
| M3 | FIXED | ScPlayer.brs:466-469 sets the focused card to 23/20 and the others to 20/19, inside Card title 20-23 and Meta 19-22 (showcase.md:43-44). The label heights (32 and 28) fit, and 17 renders both lines.<br>Class check on new text: the ScQrCard kicker is 18 px, under the Meta floor. That is new finding N2. |
| S1 | NOT (pre-existing, owner) | `components/sc/tasks/ScAuthTask.brs` is not in the diff. `statusCode:200` still maps to "yes" whatever `data` holds. No real subscribed or unsubscribed body has been captured. This is still a current MED, needed before release. |
| S2 | NOT (known, out of scope) | getdvr.php and the recording HLS are still unauthenticated. This is a backend matter, recorded in the plan. |
| L1 | FIXED | ScPlayer.brs:120-121 asks when access is `""` or `"error"`. `startAccessCheck` is still single-flight (ScScene.brs:433). The re-ask runs only in onItem, so an "error" answer cannot loop through onSession.<br>Class check: ScAccount.brs:39 still asks only on `""`. With "error" it shows "checked the first time you play a recording", and playing goes through onPlayItem:473, which re-checks. That is acceptable. |
| L2 | FIXED | ScScene.brs:515-520 carries `scProg.scRec` onto the new live item, and onItem stores it as `m.recKeep` (ScPlayer.brs:125). `refreshRecs` (:372-397) handles each case:<br>- **Schedule cached:** the first call matches at once.<br>- **Schedule loads later:** `m.recs` is still empty, so `recKeep` is used again on onSched and matched then.<br>- **Once matched:** `recKeep` is cleared.<br>- **Recording dropped out of the 48:** the keep loses to the current highlight on later reloads, so it is harmless.<br>- **Across channels:** a strip channel switch clears both `m.recs` and `m.recKeep` (:810-812). The match only ever runs against `m.channel`'s own list. That list is the scBackTo channel, where ids (start epochs) are unique, so the scRec collisions across channels (L6) cannot hit this.<br>- **Types:** `scRec` is a string on both sides (ScData.brs:215, ScScheduleTask.brs:49, :226), so the comparison cannot type-mismatch.<br>Device: 18 shows Asi Conventions highlighted after Back. As disclosed, 18 came from the pre-M2-fix build. |
| L3 | FIXED | ScPlayer.brs:765 sets `rowPicked = true` in live mode before the reveal-only early return (:767-774). Back returns earlier and never reaches it, which is correct. |
| L4 | ACCEPTED (by dev) | The silent sign-out on any unexpected 401/403 at boot is unchanged. The owner has not signed off. LOW. |
| L5 | ACCEPTED (by dev) | The probe is still 3 per item, with a 2 h window. Screenshots 17 and 18 show the 8:15 card very pale grey; I cannot tell from a capture whether that is a placeholder. LOW. |
| L6 | NOT (pre-existing, declared out of scope) | `readPosition` and `writePosition` are still keyed by bare `scRec` (ScPlayer.brs:138, 695, 749). LOW. |
| L7 | PARTLY | The hint is fixed: "Left / Right to choose …" (:543). The plan's caption meaning is now on the cards (ScLinks.brs:20-25).<br>The row still shows 6 cards against the plan's "up to 7", and nothing on file shows the owner's OK. The report marks it "FIXED / owner". LOW. |
| L8 | PARTLY | The QR cards are fixed: x 186-1422, inside action-safe, with the card text ending at about y 971. But two things remain.<br>- The report claims "row ends at y 1023, inside title-safe". That is wrong: Roku FHD title-safe ends at y 972, and 1023 is the **action**-safe bottom (KB `tv-safe-area-and-min-text-by-platform`).<br>- Same class, new instance: the Log in note (ScSignIn.xml:65-66) spans x 1458-1824. That is 2 px past action-safe (1822), and its text reaches about 1815 in 15 and 16, outside title-safe (1726). |

## Correctness findings

| # | Severity | File:line | Finding | Suggested fix |
|---|----------|-----------|---------|---------------|
| L8r | LOW | components/sc/screens/ScSignIn.xml:65-66 | The Log in note's box is x 1458-1824. That is past action-safe (1822), and its two text lines reach about x 1815, outside title-safe (1726). This is the same class as round-1 L8. | Width 260 (ends at 1718), or move the note under the cards' row end. Also correct the report's "inside title-safe" claim: the card row is action-safe at the bottom (1023 > 972); its graphics are fine there. |
| N1 | LOW | components/sc/screens/ScAccount.brs:52 | The status for "no" still says "…Subscribe at mysdatv.com, or give instead." "Give instead" was the title of the card this diff removed; the card is now "Donate to mySDAtv". (ScScene.brs:460 "scan the donation code on the Account screen" is still true.) | For example: "…Scan a code below to subscribe or donate." |
| N2 | LOW | components/sc/widgets/ScQrCard.brs:14 | The kicker is 18 px XB, under the Showcase Meta floor of 19. At 720p the word spaces collapse: 14 and 15 read "SCANTO SIGNUP" and "SCANTO GIVE". The dev notes that "NEXT EPISODE" does the same app-wide, but this is a new surface showing a misreadable word. | Use 19-20 px, or Title case (no `UCase`), or widen the gaps. Re-capture 15 to check. |
| L7r | LOW | components/sc/ScPlayer.brs:428-429 | 6 cards against the plan's "up to 7", with no owner OK recorded. This is the remainder of L7. | Record the owner's OK in plan.md, or show 7. |

The other areas the dispatcher named are clear:

**Leftover references.** I grepped `components/` and `source/` for givePlate, qrPlate, giveTitle, giveBody, joinPlate, codeTimer, drawCodes, `m.codes`, codesDrawn and `"give"`. None of them refer to removed nodes anymore. `qrPlate` remains only as ScChurches' and ScQrCard's own nodes. The only donation.PNG hits are comments; the asset is still in the zip (12 KB, unused).

**ScQrCard lifecycle.**
- **Init order:** a child's init runs before the parent's (KB `scene-init-order-and-findnode-timing`), so `m.timer` exists before the parent's init. `url` is set only on activation.
- **Re-arm on every Account and Log in activation:** it writes equal values, which do not notify (KB `equal-value-field-writes-do-not-notify`), and `onUrl` also guards with `m.drawnFor`. No re-encode.
- **Stale code:** a new url removes the modules first (ScQrCard.brs:35-42). The words are fixed and set once, so a stale code never sits beside new words (KB `focus-following-panel-clears-stale-content-at-once`).
- **Encodes per session:** four, two per screen, each pair firing together, about 255 ms (log 4: 99 + 156 ms). This is within the KB range.

**Script scope.**
- ScQrCard includes ScTheme (ScFont, ScShape), ScMetrics and ScQr (ScQrDraw, ScQrMatrix and the rest). ScTheme's dependencies all resolve inside ScTheme and ScMetrics.
- ScPlayer's `ScTextW` comes from ScTheme plus ScMetrics, both included.
- ScLinks is included where it is called: ScSignIn and ScAccount.
- There are no duplicate definitions: ScQrDraw, ScSiteUrl, ScDonateUrl and ScQrCards* are each defined once.
- No new identifier is reserved or builtin: `join` and `give` are parameters, `on` is a variable.
- Log 4 shows a clean compile, and the cards draw.

**720p whole pixels.**
- The cards sit at (186, 801) and (822, 801), which become 124, 534 and 548 device px.
- The card is 600x222 (400x148 device px).
- ScQrDraw gives a 6-px unit with origin 36 (v2, 25 modules) or 12 (v4, 33 modules). All of these are multiples of 3.

**Layout.**
- **Account:** the perks end at y 684. The buttons run 702-776, or 698-780 when lit. The cards start at 801. Screenshot 14 shows no overlap.
- **Log in:** the message is at 318-360. The keyboard's focused key top is at about y 383 (16: 255 px at 720p), so the gap is about 23 px. The hint (760-792) clears the keyboard bottom (752), and the cards follow at 801.
- **Focus:** the cards are not focusable, and the key handlers are unchanged.

**Compile risk.** The code adds no new builtin-name collisions. Every hunk is in the deployed zip, and that zip compiled and ran: log 4 and screenshots 14-20.

## Security findings

| # | Severity | File:line | Finding | Suggested fix |
|---|----------|-----------|---------|---------------|
| S1 | MED (pre-existing, carried) | components/sc/tasks/ScAuthTask.brs:67 | As round 1: "yes" on `statusCode 200` whatever `data` holds. The Recordings row depends on it. | Capture a subscribed and an unsubscribed body, then decide on `data = true`. |
| S2 | LOW (known, out of scope) | components/sc/tasks/ScScheduleTask.brs:19 | getdvr.php and the recording URLs are unauthenticated. | Server-side signed URLs. |

Checklist for the new code:
- **Secrets:** none. I grepped the diff and the 3 new files for key, token, secret, password, Bearer and base64 runs; the only hits were key-handling code. The task `tools/` scripts hold only the LAN device IP.
- **Transport:** the only URLs are the two `https://www.mysdatv.com/…` constants (ScLinks.brs:10, 15), and the diff adds no `http://`.
- **Logging:** ScQrCard.brs:49 prints the public URL and a timing, with no PII or tokens. The round-1 keyboard-geometry print is gone. The device logs and the report hold no emails or tokens.
- **Injection:** the QR payloads are compile-time constants. `scBackTo` is a catalogue node, not a URL.
- **Gate:** the catch-up gate is intact. ScScene.onPlayItem:473 is unchanged; `canWatchRecordings` is the real condition; `T6-DEBUG` markers: 0.
- **Storage and dependencies:** unchanged.
- **Not applicable on Roku:** WebView, Android manifest and cleartext config.
- **Platform claims:** none. No commit, no `Platform-Ready:` trailer and no platforms.yaml change.

## Plan coverage

- **Signed out shows the live strip, unchanged:** MET. Screenshot 20 is the clean pinned build, with no tab line and the original hint.
- **Subscribed: the Recordings row; OK plays; Back to live; Down/Up swap:** MET on a debug build that forced access. Screenshots 17-19 cover the round-2 look. The report gives ECP `is_live` false during the recording (duration 3035302 ms), and 18 shows Back to live. **Owner check pending:** a real subscribed account (and S1).
- **Signed in without a subscription shows the strip only, no dialog:** MET in code. `canWatchRecordings` needs "yes", and onAccessDone returns before any dialog when `pendingPlay` is invalid. Not device-verified.
- **Log in shows both codes; each decodes to the exact URL; typing works:** MET.
  - **Decode:** the dev's jsQR decodes from 14 and 16 give `https://www.mysdatv.com/` and `…/mysdatv-donation-page`, with a negative control. I did not re-run them.
  - **What I checked:** both codes are whole, sharp and inside their quiet zones in 14-16. Their module counts (25 and 33) match v2-M for 24 bytes and v4-M for 45 bytes.
  - **Typing:** the keyboard logic is unchanged; only its y moved.
- **Nothing under the OS banner:** MET by geometry under both readings (M1). An eye on the TV is still welcome.
- **Owner NOTE: codes below and horizontal, and on the Profile/Account screen too:** MET (14, 15). The single donation card is replaced by the same two cards.
- **Sideloaded; screenshots read; ECP proves playback:** MET. The zip is identical to the pinned sources, and I read 14-20 at full size.

## Notes

- **Unresolved docs.** ScSignIn.xml:9-11 still says the banner covers "the top ~200 px of the keyboard's right two thirds", while the KB `keyboard-node-qr-banner-forces-stacked-layout` says the screen's.
  - The codes no longer depend on which is right.
  - But under the KB's reading, the pre-existing Password field and Log in pill (y 196-302, x ≥ 836) would sit under the banner.
  - The owner's eye on the TV settles both. Then correct whichever text is wrong (a `/learn` candidate).
- **Evidence note.** Screenshot 18, the L2 evidence, was taken on the build where the glow was mistakenly on the strip. I checked the L2 code by reading it, and it is not affected by the M2 move.
- **Recording-row captions sit below title-safe.** They are at y about 998, under title-safe (972) and inside action-safe. The pre-existing strip's captions sit at the same baseline (19: about 981), so this is the C6 layout, not new.
- **The live strip still has the dark shadow.** It does not have the owner's "white glow on every card" (fc1196d). This is pre-existing. The dispatcher asked that the strip stay original, and it does.
- **Dead asset.** images/png/donation.PNG is now unused but still ships, 12 KB. That is harmless; drop it in a cleanup.
- **Duplicate encodes.** The two screens encode the same two codes separately, four encodes per session. A shared cache is possible but not needed at about 255 ms per page.
- **Docs to follow up.** docs/design/showcase.md:66 still lists "the donation QR card" for Account.
- **Scratch files.** For the M2 check I wrote the two extracted `drawStrip` bodies to the session scratchpad and diffed them. Nothing in the repo was touched.
- No waivers recorded.

Knowledge applied: review-findings-name-instances-the-fix-must-cover-the-class, focus-following-panel-clears-stale-content-at-once, source-dir-not-in-component-scope, keyboard-node-qr-banner-forces-stacked-layout, tv-safe-area-and-min-text-by-platform, mysdatv-design-showcase-c (app), equal-value-field-writes-do-not-notify (summary), scene-init-order-and-findnode-timing (summary), reserved-words-and-name-collisions (summary), on-device-qr-encoder-in-brightscript (summary), focus-border-abandoned-for-size-and-brightness (summary)
Knowledge contradicted: none. The banner-anchor disagreement between the KB and ScSignIn.xml:9-11 is still unresolved, not proven either way.
