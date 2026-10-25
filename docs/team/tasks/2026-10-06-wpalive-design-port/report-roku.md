# Report: mySDAtv redesign on the WPALive design system (Roku)

## STATUS
DONE, with three open items: the DVR overlay has not been seen on the device (it needs a real login), the Nuevo Tiempo stream stalls, and the change is not yet reviewed or committed.

## BRANCH
main (owner's choice, 2026-10-06). Nothing is committed yet.

## Summary
mySDAtv now uses wpa_live_roku's design language. That covers:
- the collapsing 120/440 rail;
- tiles that rest at 0.92 and grow with a soft accent glow, without borders;
- the top bar, a live clock plate, and Manrope and Inter type;
- one theme table that paints every surface.

The colours are mySDAtv's own. The owner picked palette 4, "My red", from six options:
- red from "my" (#F0262B) is the focus colour;
- gold from "SDA" (#FAD35A) marks the selected destination;
- blue from "tv" appears in the rail lockup;
- the ground is navy-charcoal (#0B1222).

The first cyan build stays available as palette `sdanavy`.

All reachable surfaces are reskinned:
- the rail;
- the four grid screens (Television, TV Languages, DVR, Radios);
- the login-info preview;
- the DVR overlay (sidebar and episode cards).

The data, API, auth, purchase and playback code paths are unchanged. Back now has a way out: Back from content opens the rail, and Back from the rail asks to exit. Before this change Back could never leave the channel.

Knowledge applied:
- port-between-engine-twins-by-prefix-normalised-diff
- verify-on-device-not-in-the-compiler
- scope-the-channel-package-explicitly
- trial-palette-must-paint-from-the-theme-at-init
- markupgrid-clips-at-content-box (summary)
- list-owned-focus-fields-not-parent-walk (summary)
- ninepatch-borders-draw-at-device-pixels (summary)
- rounded-corners-on-images (summary)
- scene-init-order-and-findnode-timing (summary)
- key-event-fires-on-both-down-and-up-edges (summary)
- node-free-deploy-and-capture-harness (summary)
- sideload-zip-needs-forward-slash-entries (summary)
- poster-recycled-item-loadstatus-traps (summary)

## Files changed
- **New source files.**
  - `source/SdTheme.brs` holds the palettes, `SdPaint`, `SdFont`, the tone and initials helpers, `SdRing` and `SdTextW`.
  - `source/SdGlobals.brs` holds `focusTick`.
  - `source/SdMetrics.brs` is a copy of `WpMetrics`, generated from the same TTFs.
- **New widgets.**
  - `components/widgets/SdTile` is a port of `WpTile` that reads `title` / `hdPosterUrl` as they are.
  - `SdClock` is a self-updating clock plate.
  - `SdTopBar` holds the logo and heading.
- **Rail.** `components/screens/navigation_bar.{xml,brs}` has its drawing replaced by the WPALive rail. Its node id, its `isVisible`/`selectedIndex`/`userLoggedIn` contract, and the whole login/logout flow are kept; the old row builders are now stubs that call `repaint()`. It also gains Back→exit confirmation and the left edge fade.
- **Grid screens.** `vod_screen`, `second_vod`, `third_vod` and `dvr_vod` each get:
  - a new `.xml` with one shared layout (5×330×195 tiles, grid offset −30/−20, last column spacing 60, top bar, clock; the legacy ids are kept);
  - in `.brs`, `sdPadLeft/Top` added to the content nodes;
  - a `slidePage` that animates from the current position (0.18/0.22 s, outCubic);
  - Back opens the rail.
- **Login preview.** `LoginInfoScreen.{xml,brs}` is laid out for the open rail: Inter body, the QR on a surface card, and an OK hint.
- **DVR overlay.**
  - `DVROverlayScreen.{xml,brs}` gets the ground, logo and clock, with the heading taken from `parentTitle`.
  - `DVRSidebarItem` becomes rail-style pill rows.
  - `DVREpisodeItem` keeps its title/poster/time derivation and hosts an `SdTile`.
- **Scene.** `home_scene.{xml,brs}` paints the ground from the theme (a flat fill under the picture).
- **Entry.** `source/main.brs` observes the global `sdExitApp` and returns on it.
- **Images.**
  - Copied from the engine: `images/fonts/*` (Manrope and Inter); `images/png/shapes/*` (pills, fades, flat_white, ramp_diag, and generated corners and glow); `images/png/nav/*`.
  - Generated: `images/png/ground/*` and `images/png/brand/*` (wordmark_top cut from `mysdatv_logo.png`, the globe mark).
- **Tools.** The following are ported from wpa:
  - `tools/deploy.ps1` (curl only, explicit package scope);
  - `tools/capture.ps1` and `_curlauth.ps1`;
  - `tools/check-scope.js` (Sd prefix, relative script URIs, filter by component);
  - `tools/build-assets.ps1` (glyphs, glows per accent, grounds, corners, logo and mark).
- **Repo hygiene.** `.gitignore` covers `.env` and `out/`. Both are still tracked in git, and untracking them needs owner approval. `.env` itself was changed locally: ROKU_DEV_TARGET went from .108, which no longer answers, to .106.

## Decisions
1. **Keep the `navigation_bar` contract and redraw it.** About 40 call sites set `isVisible` and focus by node id. Replacing the component would have meant touching all of them.
2. **Keep mySDAtv's own rail behaviour.** Moving Up or Down switches the visible screen immediately, as it did before; WPALive switches only on OK. OK and Right both enter the destination; before, OK did nothing on rows 0–3.
3. **Lay out once for the collapsed rail.** Content starts at x 160 and the open rail slides the page by 320 (contract T4). The old code moved the page between 180 and 450, which overflowed 1920 at 450.
4. **Each screen carries its own clock.** It is a self-updating widget rather than a scene clock, because the DVR overlay is appended over the scene.
5. **Separate focus from place.** The red palette uses `cSelected` (gold) for "where I am", so it never shares a colour with focus (red). In the cyan palette both are cyan.
6. **Leave dead screens alone.** `RowListItemComponent` and the legacy dialogs are untouched. The unreachable screens still use them.
7. **Exit goes through `m.global.sdExitApp`, not the scene's `exitApp`.** On the device, `main` never received the scene-field observer event (see Learnings).

## Verification
All runs were on a Roku Express at 192.168.0.106, firmware 15.3.4, 720p panel. Screenshots are in `screenshots/`.
- **Before state:** `before-01`, `before-02`.
- **Round 1 (cyan):** the rail closed and open, TV Languages, DVR and the login preview (`r1-*`).
- **Round 2 (cyan):**
  - Exit dialog, Cancel back to the rail, grid focus moves with fixed-focus scroll.
  - Playback of 3ABN Canada: ECP reported `state="play"`, live HLS at 1.53 Mbps, position advancing (`ecp-media-player-tv.xml`).
  - Back from the player restored the same focused tile; Back from the grid opened the rail (`r2-*`).
- **Round 3 ("My red"):** Television, rail open, login preview, TV Languages grid (`r3-*`).
  - Exit now returns to the Roku home screen: `/query/active-app` reported "Roku Dynamic Menu" after Back→Exit.
  - "Good News Mas TV" played: `state="play"` at 3.25 Mbps.
- **Static checks:**
  - `node tools/check-scope.js` on the 13 changed components: clean.
  - The whole repo shows 51 findings, all in untouched legacy files.
  - The package is 231 files, ~3.3 MB; deploy.ps1 asserts no .git, .env, docs, out or tools entries.
- **NOT verified on the device:**
  - The DVR overlay (DVROverlayScreen, DVRSidebarItem, DVREpisodeItem). It opens only after a real login plus the purchase check, and credentials are the owner's to type.
  - Login/logout success and failure dialogs. Their logic is unchanged; only the rail repaint changed.

## Learnings candidates
1. **A scene field never reached `main`.** On fw 15.3.4, `homeScene.observeField("exitApp", m.port)` in main.brs never delivered an `roSGNodeEvent`. Debug prints confirmed this: the dialog handler set `scene.exitApp = true` (false→true printed) and the main loop logged no message at all. The same pattern on an `m.global` field (`m.global.observeField("sdExitApp", m.port)`) closed the channel on the first try. Worth checking whether this generalises; it may be specific to this channel, for example the scene being created after the port was set on the screen.
2. **Port a design system onto a legacy app by keeping its contract.** Keep the legacy node ids, fields and handlers (`navigation_bar`, `vodRowList`, `showFullContent`, `descriptionLabel`) and replace only the drawing. Legacy fields still written by code but no longer shown go into an invisible Group. The four 840-line clones needed only XML swaps plus small, mechanical `.brs` edits.
3. **A wrapper item can reuse the one tile.** `DVREpisodeItem` hosts `SdTile` and forwards `focusPercent` and `gridHasFocus` (as `hostLit`), so the item can keep its own content derivation while the focus language stays identical.
4. **Pick the palette from swatches first.** Six palettes as mini mockups, built from the logo colours, got an owner decision in one round. The theme-table refactor made the switch a one-word change plus one glow asset.

## Blockers
None. Open items:
- DVR overlay device check (needs a login).
- Nuevo Tiempo stream stalls at `open`/`startup`. The play path is unchanged, so this is probably the stream itself, but it is unconfirmed on the old build.
- `.env` and `out/` are tracked in git, and `.env` holds the dev password. Untracking them needs owner approval.
- The legacy grey `Dialog` (exit, login and logout confirmations) is not restyled. That is a follow-up: an `SdDialog` port of `WpDialog`.
- Store icon and splash still use the old 540x405 art (manifest).

## Review outcome (review.md, 2026-10-06)

The verdict was REQUEST_CHANGES. There were no HIGH findings; the blocker was criterion 9 (no DVR overlay capture).

- **C1, fixed.** `dvr_vod.brs` now hands the rail's OK key-up on to its grid, as the other three grid screens do. Verified on the device: `screenshots/r4-01-dvr-ok-from-rail.jpg` shows the grid focused with tile 1 lit after OK on the DVR row.
- **C2, fixed in code, not yet seen on the device.** In `SdTile`, re-binding the same uri now settles the fallback from the current `loadStatus`. The symptom mostly shows in the DVR overlay, which needs a login.
- **C3 / criterion 9, still open.** The DVR overlay device pass needs the owner to log in.
- **S1, open, needs owner approval.** `.env`, `.vscode/launch.json` and `out/` are tracked in git. Untrack them before any commit, and rotate the dev password.
- **LOW findings left as follow-ups:**
  - the third row of the overlay grid runs off-screen;
  - Up/Down on the rail no longer wraps;
  - `toggleNavVisibility` fires twice;
  - stale XML hex values remain (they are painted over in init);
  - the clock's visibility guard;
  - `-Password` on the command line;
  - an email address printed to the console.

The reviewer advises against filing learnings candidate 1 (exitApp) as a firmware fact until there is a minimal repro.
