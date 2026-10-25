# Review: 2026-10-25-showcase-build

VERDICT: REQUEST_CHANGES

Diff reviewed: `git diff 20d8958..e03912d -- source components tools manifest` (078820a build, e03912d prune), read in full for every `Sc*` file. Legacy was compared at `20d8958` (LoginScreenApi, CheckPurchaseApi, VideoDVRScreen positions, VodEntityHelper). WpHome/WpDetail in `D:\Tulix\wpa_live_roku` were used as the device-proven reference.

Re-run by the reviewer (offline):
- `node tools/check-scope.js`: "scope check: clean", exit 0.
- `tools/deploy.ps1 -PackageOnly`: "packaged 86 files, 408,642 bytes". This matches the report.
- A cmap check of the shipped Plus Jakarta TTFs (ExtraBold, Bold, SemiBold) found every non-ASCII glyph the UI draws: ● • · – − … ê ñ ç.
- bsc was not re-run (not permitted for this review). The 0-diagnostics claim rests on the dev report.

The verdict is REQUEST_CHANGES for two reasons:
- One acceptance-criterion sub-clause is not met: AC5, a hard-coded colour in Sc XML. The fix is one line.
- Several MEDIUM runtime issues should be fixed before the device round, because each one would otherwise cost a device iteration to find.

There are no HIGH findings.

## Correctness findings

| # | Severity | File:line | Finding | Suggested fix |
|---|----------|-----------|---------|---------------|
| C1 | MED | components/sc/screens/ScCatchup.brs:137 (onFocusChild), :49-105 (rebuild) | **Focus dead-end on the first visit to Catch-up.** When no schedule is loaded yet, `rows` is invisible, so the ScCatchup Group itself keeps focus. The Group has no `onKeyEvent`. When the schedules land, `rebuild()` makes the rows visible but never hands focus to them. OK, Down and Right then do nothing, and only Left or Back (which open the capsule) recover. This is the likely path on a cold visit, because the 3ABN schedules are requested only on first activation (up to 6 × 377 KB). | At the end of `rebuild()`: `if m.top.hasFocus() and m.rows.visible then m.rows.setFocus(true) : ScFocusChanged()`. Or add an `onKeyEvent` that forwards Down/OK to the rows once they are visible. |
| C2 | MED | components/sc/ScScene.brs:303-306 | **"Try again" on the accessError dialog leaves focus on a hidden dialog.** `closeDialog()` hides ScDialog, then `startAccessCheck()` returns without `restoreFocus()`. For the whole request (up to 20 s), every key goes to the invisible modal (ScDialog swallows all keys) and nothing is on screen. A stray OK re-answers "Try again". | Keep the dialog visible with a "Checking…" body until the answer arrives, or call `restoreFocus()` before `return`. |
| C3 | MED | components/sc/ScScene.brs:410-444, :506-527, :56-58 (ScScene.xml) | **The access-check result acts on stale intent, and can land under the player.** While a check is in flight, nothing on screen shows it, `m.pendingPlay` stays set, and the viewer can keep browsing. Two cases: (a) A deep link that arrives during the check resets the shell but not `m.pendingPlay`, so a later `yes` replaces the deep-linked live channel with the old recording. (b) If the viewer starts a live player meanwhile, a `no`, `unauthorized` or `error` answer opens ScDialog. `playerHost` is declared after `dialog` and `signin` (z-order, knowledge/dev-roku/xml-declaration-order-is-z-order), so the dialog is invisible under the video but takes focus. | Set `m.pendingPlay = invalid` in `applyPendingDeepLink` and in `startPlayer`/`onOpenScreen` for a different item. Add a generation counter on the access request and ignore answers from an older generation. Show a brief "Checking your subscription…" state. Declare `playerHost` before `dialog` (or move the dialog and sign-in above it) so a modal always paints over video. |
| C4 | MED | components/sc/tasks/ScAuthTask.brs:65 (and :35, :41) | **Unguarded `json.statusCode = 200` can crash the Task thread.** If a 200 check-purchase body has no `statusCode` (for example `{"data": false}`), the comparison is `invalid = 200`. That is the runtime Type Mismatch shape in knowledge/dev-roku/missing-aa-key-compared-with-boolean-is-a-type-mismatch. The legacy CheckPurchaseApi.brs:87 guarded exactly this line (`parsedBody.statusCode <> invalid and …`), so on :65 it is a regression. The same shape appears in signIn at :35 and :41; legacy LoginScreenApi.brs:62-63 had the same unguarded compare. A Task that dies leaves `m.authTask` or `m.accessTask` set forever: sign-in, sign-out and the gate are stuck until relaunch, or the channel crashes. A non-AA JSON body (an array) also crashes on `.statusCode`. | Read through a typed local: `sc = invalid : if type(json) = "roAssociativeArray" then sc = json.statusCode`, then `(type(sc) = "roInteger" or type(sc) = "Integer" or type(sc) = "roInt") and sc = 200`. Apply the same to `json.data.accessToken` (check `type(json.data) = "roAssociativeArray"`). |
| C5 | MED | components/sc/screens/ScSignIn.xml:22; components/sc/ScScene.xml:28; components/sc/widgets/ScDialog.xml:12 | **Assocarray interface fields have no `alwaysNotify`.** If SceneGraph treats an identical AA write as "no change" (knowledge/dev-roku/equal-value-field-writes-do-not-notify), these paths break: (a) a second identical sign-in failure (same reason and status) never reaches `onAuthResult`, so `m.busy` stays true, the button reads "Logging in…" and `submitForm` refuses retries; (b) the same deep link sent twice (a certification pattern) is ignored; (c) re-opening the same dialog keeps the previous button index. ScGlobals' own header states the rule that request fields are counters or alwaysNotify; these three fields are exempt from it. | Add `alwaysNotify="true"` to `ScSignIn.result`, `ScScene.deepLink` and `ScDialog.spec`. |
| C6 | MED | source/ScUi.brs:33-49 | **RowList `vertFocusAnimationStyle` is left at its default.** The RowList default is `fixedFocusWrap`. Home (hero ← Up from the first row, ScHome.brs Up branch) and the Channel page (buttons ← Up) depend on the list NOT consuming Up on row 0. If the list wraps, the hero and the channel buttons become unreachable. The device-proven WpDetail sets `vertFocusAnimationStyle="fixedFocus"` explicitly for the same zone hand-off. Device-unverified either way. | In `ScInitRowList`: `list.vertFocusAnimationStyle = "fixedFocus"`. On device, check Up from the first row on Home, Channel and Catch-up (Catch-up has more rows than `numRows` 6). |
| C7 | LOW | components/sc/ScPlayer.xml:36 | `<Rectangle id="black" … color="0x000000FF">` is the only colour literal in Sc XML, and the theme does not paint it. This is what fails AC5 by its letter (see Plan coverage). | Add `["black", "color", "cShadow"]` to the player's `ScPaint` list, or drop the attribute and paint it in init. |
| C8 | LOW | components/sc/screens/ScHome.brs:331, :338; components/sc/ScScene.brs:117-143 | **The schedule queue is FIFO and unbounded.** Moving along Home's Channels or languages rows enqueues one 377 KB fetch+parse per channel passed. The channel now in focus waits behind every stale one, so the hero for the focused card fills late on an Express. A failed fetch is not remembered, so every focus on that channel re-queues it (up to a 20 s timeout each, holding one of the 2 slots). | Make the queue LIFO, or drop queued streams that are no longer wanted, and cap it (for example 4). Cache a failure (a `scOk=false` node with `scAt`) so retries wait a few minutes. |
| C9 | LOW | components/sc/ScPlayer.brs:442-456; source/ScUi.brs:181-182 | **"Next episode" can be another channel or another title.** For cards opened through `ScActivate` (Catch-up "Earlier today", which mixes channels, and Channel "Earlier this week", one card per title), the next list is the RowList row of cards. `findNext` picks the earliest aired programme after this one ends, with no check on stream or title. | In `findNext`, require `p.scStream = m.prog.scStream`. On a titled channel, also require `p.title = m.prog.title`. |
| C10 | LOW | components/sc/ScPlayer.brs:124-136, :178-183 | After `playNext()`, a `position` notification from the previous stream that arrives after `m.ended` was reset can satisfy `position >= duration - 1` against the next episode's shorter `m.dur`. That skips an episode. | Gate `onPosition` end detection on a per-content "has reached playing" flag that is set in `onState` and cleared in `playUrl`. |
| C11 | LOW | components/sc/screens/ScHome.brs:172 | The empty-catalogue message says "the channel will try again when you come back", but nothing retries: `startFeeds()` runs once, in scene init. The plan's "real error path" is only half there. | Re-run the failed ScFeedTask on Home re-activation (or on a timer), or change the text. |
| C12 | LOW | components/sc/ScScene.brs:104-111 | `AppLaunchComplete` fires when the TV feed lands, even on a deep-link launch. Roku's guidance for deep-link launches is to signal when playback starts. | When a launch deep link is pending, signal after the player's first `playing` state (a one-shot global the player bumps). |
| C13 | LOW | components/sc/ScScene.brs:552-554; components/sc/widgets/ScNav.brs:93 | Back on the capsule from a non-Home destination calls `showScreen("home", false)`. The capsule's `focusIndex` stays on the old item, so the white focus circle is on (say) Catch-up while the "current" circle moves to Home. | Set `m.nav.focusIndex` to Home in that branch (expose a field, or re-trigger `onNavFocus`). |
| C14 | LOW | source/ScGlobals.brs:52-57; source/ScData.brs:189; components/sc/widgets/ScCard.xml:29-30; images/png/sc/restart.png | Dead code and assets: `scFocusTick` is bumped but never observed (the header comment says cards light on it; they correctly use the list-owned booleans instead). `navOpen`, `scStartAt`, ScCard `width`/`height` and the "station" card kind are unused, and `restart.png` ships unused. | Remove them, or fix the stale comment. |
| C15 | LOW | components/sc/screens/ScChannel.brs:124-126 | On a channel page left open, the "● LIVE" card in "Today on …" does not move when the programme ends: `onMinute` redraws only the top. | Call `drawRows()` on `minuteTick` when the on-now programme has changed. |

## Security findings

| # | Severity | File:line | Finding | Suggested fix |
|---|----------|-----------|---------|---------------|
| S1 | LOW | components/sc/ScScene.brs:357-370; components/sc/screens/ScSignIn.brs (submitForm, onAuthResult, onActiveChanged) | **The password path is clean.** It runs ScSignIn `m.password` → `submitRequest` AA → scene copies it into `ScAuthTask.password` and empties `submitRequest` → the Task blanks its own field after the request. The Keyboard text is wiped when sign-in closes. The password is never printed (the legacy LoginScreenApi.brs:27 printed the whole credential AA, so this is an improvement). One residual: on a *failed* attempt, `m.password` and the Keyboard text stay in memory until the form closes. This is needed for the retry and is acceptable. | None required. Optionally clear the Keyboard text when leaving the password field. |
| S2 | LOW | components/sc/tasks/ScAuthTask.brs:56-58 | Bearer and X-Session-Token are sent only over `https://sda.wchupload.tulix.net`. The token is not logged anywhere (the legacy CheckPurchaseApi.brs:36-37 printed the full access token; that code is now removed). The token sits in registry `AUTH/authData` in plain JSON. This is unchanged from legacy, kept for compatibility, and Roku has no keystore. | None. |
| S3 | N/A, checked | — | **Hardcoded secrets.** Grepped for key, token, secret, password, Bearer and base64 in source, components, tools and manifest: none. `.env` and `.vscode/launch.json` are not tracked. | — |
| S4 | N/A, checked | — | **Transport.** Every app endpoint is `https://`. The only `http://` is in tools/capture.ps1 and deploy.ps1, which talk to the dev device over the LAN (ECP and plugin_install); they do not ship (the package excludes `tools/`). | — |
| S5 | N/A, checked | — | **Logging.** The `?` lines print kind, status, counts, channel titles and Video errorCode/errorMsg. No tokens, emails or credentials. The stream URLs in the feed carry no auth parameters. | — |
| S6 | N/A, checked | main.brs:47-51; ScScene.brs:506-527 | **Injection via deep link.** `contentId` is matched only against catalogue ids, so no URL from the link reaches the Video node. `mediaType` is ignored. | — |
| S7 | N/A | — | Android manifest, WebView, cleartext config, `badCertificateCallback`: not applicable to Roku. The certificate file is `common:/certs/ca-bundle.crt` (system CA). | — |
| S8 | N/A, checked | — | **Dependencies.** No packages were added. The fonts are OFL Plus Jakarta Sans static TTFs, and the licence ships with them. | — |
| S9 | N/A, checked | — | **Platform claims.** No `Platform-Ready:` trailer and no `platforms.yaml`. The report says PARTIAL / not device-verified, which is consistent. | — |
| Note | — | — | The catch-up paywall is still client-side only (`getdvr.php` and the HLS recordings are open). This is pre-existing and listed as a backend ask; it is out of scope. | — |

## Plan coverage

1. **Boot and reachability: MET (static).**
   - `main.brs` creates `ScScene`.
   - C1 Home is the boot screen.
   - C2 is reached through `openChannel` from Home's Channels and Languages rows, the hero's "<channel> channel" button, the Channels grid, and OK on the playing card in the live strip.
   - C3, C4, C5 and C8 are reached through the capsule.
   - C6 is reached from Watch live and from On now, Channel or "later" cards.
   - C7 is reached from Catch-up, Channel replays, Home series and Start over, through the gate.
   - Radio Listen plays in radio mode.
   - Account → Log in → ScSignIn.
2. **Compiler 0 errors: MET per the dev's evidence.** Not re-run by the reviewer (bsc on a copy is outside this review's permitted commands).
3. **Scope check: MET.** Re-run: "scope check: clean".
4. **Package under 4 MB: MET.** Re-run: 86 files, 408,642 bytes.
5. **Design rules: NOT MET, on one sub-clause.**
   - **Colours:** NOT MET. ScPlayer.xml:36 has an unpainted `color="0x000000FF"` (C7). A one-line fix.
   - **One focus indicator per screen:** MET by code reading.
     - Pills light only while their zone holds focus.
     - Cards lift only while gated on `gridHasFocus` or `rowListHasFocus && rowHasFocus`.
     - Selected chips are white without lift.
     - The capsule's current item is a selection mark, not a focus mark.
     - Minor: Radio's always-white Listen pill stays white (dimmed) while the capsule is open.
   - **Capsule hidden in players:** MET. `startPlayer` → `showChrome(false)`, which also hides it under sign-in.
   - **Whole logo in the header:** MET. `logo_144.png` is the full lockup (inspected) at 144x75 at (12,40).
6. **Independent review, no HIGH: MET.** No HIGH findings.
7. **Report lists what was not verified on device: MET.** It covers look, focus, video, sign-in and gate, schedules, deep links and the 720p 9-patches.

**Item 3 of the brief: compatibility with legacy plumbing. MET.**
- **Login:** same URL and body (`email`, `password`, `deviceInfo: "rokuTV"`); success is `body.statusCode = 200`.
- **AUTH/authData:**
  - Same keys: `accessToken`, `subscribed` 0, `expiry` now+10 d, `isauth` 1, the four customer fields and `sessionToken`.
  - A legacy record is read by the same rules: `now > expiry` gives invalid, and `accessToken` is required.
- **check-purchase:**
  - Same URL, body and headers, including both `X-Session-Token` headers.
  - The status mapping matches legacy, except the unguarded compare (C4).
- **Resume positions:**
  - Section `positions`.
  - The key is the recording `id` as `toStr()`; legacy used `data.id.ToStr()` from the same getdvr `id`.
  - Legacy values written as `Str(float)` (with a leading space) parse through `Int(Val())`.
  - The >30 s threshold matches.

**Item 5 of the brief: the prune (e03912d). MET.**
- **What remains:** 16 Sc components. Every XML child tag and every `createChild`/`CreateObject` name resolves to a remaining component or a built-in node.
- **Package paths:**
  - Every `pkg:/` path in source and components exists: fonts, `sc/*` including each `ScShape`/`ScGlyph` and `circle`+size name, `shapes/fade_{top,bottom,right}`, `donation.PNG`.
  - Both manifest images exist.
- **Tools:**
  - `deploy.ps1` now requires `components/sc/ScScene.xml` and `source/ScTheme.brs`.
  - `build-sc-assets.ps1` and `build-sc-metrics.ps1` read only `images/png/mysdatv_logo.png` and the Plus Jakarta TTFs, which remain.
  - `tools/build-assets.ps1` was removed. The fade PNGs it never generated (they were engine copies) remain committed.
- **Nothing still needed was removed.** The manifest's missing `mm_icon_focus_fhd` is pre-existing; see Notes.

## Notes

- **No device run.** Every focus, layout and playback claim above is from reading the code. The device round should prove the following, in addition to the report's own list:
  - C1 and C6 (Up from row 0 on Home, Channel and Catch-up);
  - the `rowLabelOffset` sign (`[[400, -58]]`; WpHome's `[[640, -18]]` is device-proven with the same sign);
  - the Keyboard OK key-up edge after `editField` (ported from device-verified WpSignIn).
- **Things checked and found correct** (worth keeping as-is):
  - **Key-up edges.**
    - Every handler that moves focus acts on press.
    - ScNav, ScDialog and ScPlayer swallow the release.
    - Screens return false on release.
    - The scene returns false on release.
    - No release edge lands on a handler that acts on it.
  - **setFocus on an ancestor.** Avoided with `setFocus(false)` on the list first: ScHome Up, ScChannel Up, ScChannels Up, ScSignIn leaveKeyboard.
  - **Observers.** No accumulation:
    - ScCard uses scoped observe/unobserve on the recycled node;
    - ScPlayer uses scoped observers on m.global and removes them in `teardown`;
    - the screens observe m.global once, in init.
  - **ContentNode built-in fields.** No misuse: no `contentType` string; node-typed fields are declared with `addField(..., "node")` rather than `addFields` with invalid.
  - **RowList sizing.** Both `itemSize` and `rowItemSize` are set, `focusXOffset` is an array, and the sizing arrays are never empty.
  - **MarkupGrid.** Uses `itemSpacing` plus `columnSpacings`, with the last-column pad.
  - **Tasks.** Each Task parses off the render thread; nodes are built in the Task and handed over through a node field.
  - **callFunc.** `teardown` is declared in `<interface>` and is called with no argument.
  - **Video.** One Video node at a time: the player is created on demand and stopped in `teardown` before `removeChild`.
  - **Video end and error states.** Both are handled: end is `position >= duration - 1`, and an error is held against the error→finished move.
  - **Deep-link reset.** Player, dialog and sign-in are reset before playing (apart from C3a).
  - **AppLaunchComplete** is signalled once.
- **Pre-existing, not in this diff.** The manifest has no `mm_icon_focus_fhd`, and the splash and icon are the old 540x405 art (knowledge/dev-roku/manifest-icon-requirements-drift). Both matter for store submission, not for this round.
- **Product decisions** the owner may want to confirm on device:
  - `catchupAccess = "yes"` is cached for the session until sign-in or sign-out (legacy checked on every tile).
  - Account's "Watch catch-up" button shows even when access is `no`.
- **Learnings candidates** for the orchestrator:
  1. **A modal "Try again" that keeps waiting must keep the modal visible, or move focus.** Hiding the dialog and returning leaves focus on an invisible modal-swallowing node (C2).
  2. **An async gate needs a request generation.** A late answer must be dropped once the viewer, a deep link or a sign-out has moved on (C3). This is the Roku form of shared-api-auth `rotating-refresh-tokens-need-session-generations`.
  3. **In a shell where the player is created on demand, declare the player host BEFORE the modal layers.** Otherwise any modal raised during playback is invisible but focused (C3b).
  4. **Set RowList `vertFocusAnimationStyle` explicitly** whenever "Up off row 0" is a zone hand-off (C6).

Knowledge applied:
- **Opened:** missing-aa-key-compared-with-boolean-is-a-type-mismatch, equal-value-field-writes-do-not-notify, key-event-fires-on-both-down-and-up-edges (partially read).
- **Summary only:**
  - setfocus-on-ancestor-does-not-reclaim, scene-singleton-observers-accumulate-per-screen, contentnode-builtin-field-types-are-fixed, callfunc-needs-interface-declaration;
  - deep-link-while-running-must-reset-the-shell, rowlist-itemsize-vs-rowitemsize, rowlist-fixedfocus-hides-items-before-focus, rowlist-rowitemfocused-fires-on-content-set;
  - list-owned-focus-fields-not-parent-walk, focus-source-focuspercent-vs-hand-maintained-field, markupgrid-clips-at-content-box, markupgrid-itemspacing-only;
  - hls-vod-never-reports-finished, video-node-moves-error-to-finished-on-its-own, offscreen-screen-steals-focus, secondary-feed-must-not-join-the-boot-gate;
  - dead-asset-sweep-must-model-concatenated-paths, scope-the-channel-package-explicitly, xml-declaration-order-is-z-order, manifest-icon-requirements-drift;
  - rotating-refresh-tokens-need-session-generations, session-gate-invalidates-item-level-public-rules.

Knowledge contradicted: none


## Outcome (dev, 2026-10-25, commit 0ab8b78)
**Fixed:**
- C1 (rows take focus when they land);
- C2 (Try again returns focus to the page);
- C3 (pendingPlay cleared by a new play, deep link or screen; playerHost declared before the modals);
- C4 (statusCode guarded);
- C5 (alwaysNotify on spec / result / deepLink);
- C6 (explicit `vertFocusAnimationStyle="fixedFocus"`; Up from row 0 to the hero verified on the device);
- C7 (player black from the theme, `cVideo`);
- C9 (next episode on the same channel);
- C10 (position events ignored until the new stream plays);
- C11 (wording);
- C13 (capsule focus follows the destination).

**Left as follow-ups:**
- C8: an unbounded schedule queue and no failure cache.
- C12: on a deep-link launch, `AppLaunchComplete` fires before playback starts.
- C14: dead fields.
- C15: the live tag can go stale between minute ticks.

Static after the fixes: check-scope clean; brighterscript 0 diagnostics. The device walk is in report-roku.md.
