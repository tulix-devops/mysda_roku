---
topic: mysdatv-wpalive-port-pattern
summary: How mySDAtv Phase 1 ported the WPALive design onto the legacy app - keep node ids/fields/handlers and redraw only, invisible Group for dead fields, wrapper item hosting SdTile, exit via m.global.sdExitApp (unreproduced)
platform: roku
applies-to: [mysdatv]
observed-in: [mysdatv]
date: 2026-10-06
source-task: mysdatv/docs/team/tasks/2026-10-06-wpalive-design-port/
---

# Phase 1 port pattern: WPALive design on mySDAtv's legacy code

Phase 1 (2026-10-06, on main, device Roku Express fw 15.3.4, 720p) is the code base design A extends ([[mysdatv-design-lineup-alpha-a]]). Report and review: `docs/team/tasks/2026-10-06-wpalive-design-port/`.

## Fact

- **Keep the legacy contract, replace only the drawing.** `navigation_bar` has about 40 call sites that set `isVisible` and focus by node id, so its node id, `isVisible`/`selectedIndex`/`userLoggedIn` contract and login/logout flow were kept; the old row builders became stubs that call `repaint()`. The four 840-line grid clones (`vod_screen`, `second_vod`, `third_vod`, `dvr_vod`) kept their ids (`vodRowList`, `showFullContent`, `descriptionLabel`) and needed only XML swaps plus small mechanical `.brs` edits. Legacy fields still written by code but no longer shown go into an invisible Group.
- **Wrapper item reuses the one tile.** `DVREpisodeItem` hosts the shared `SdTile` (port of `WpTile`, reads `title`/`hdPosterUrl` as they are) and forwards `focusPercent` and `gridHasFocus` (as `hostLit`), so the item keeps its own title/poster/time derivation while the focus language stays identical.
- **Theme table paints every surface at init** (`source/SdTheme.brs`: palettes, `SdPaint`, `SdFont`). The palette was picked from six swatch mock-ups in one owner round; "My red" (focus red `#F0262B`, selected gold `#FAD35A`, ground `#0B1222`) won; the first cyan build stays as palette `sdanavy`. See [[trial-palette-must-paint-from-the-theme-at-init]].
- **Layout once for the collapsed rail.** Content starts at x 160; the open rail slides the page by 320 (the old code moved it 180 to 450 and overflowed 1920).
- **Back contract.** Back from content opens the rail; Back from the rail opens an exit confirmation; before this, Back could never leave the channel. Exit goes through `m.global.sdExitApp` (main observes the global). In one device test the scene-field observer `homeScene.observeField("exitApp", m.port)` never delivered an event while the same pattern on an `m.global` field worked first time. The reviewer's ruling: do NOT treat this as a firmware fact; HEAD never had that observer and the failing variant was a temporary edit that cannot be inspected. Keep it as an app-specific workaround, and re-test with a minimal repro before generalising.
- **Review findings worth remembering** (verdict REQUEST_CHANGES; no HIGH): the DVR rail OK key-up stranded focus (fixed, see [[key-event-fires-on-both-down-and-up-edges]]); SdTile same-uri re-bind left the fallback visible (fixed, see [[poster-recycled-item-loadstatus-traps]] trap 4); the DVR overlay (`DVROverlayScreen`, `DVRSidebarItem`, `DVREpisodeItem`) was never seen on the device because it needs a real login; `.env`, `.vscode/launch.json` and `out/` are tracked in git and `.env` holds the dev password (untrack only with owner approval).

## Why it matters

Redrawing behind the old contract kept a 40-call-site app working while changing every pixel. Replacing the components would have touched all call sites.

## How to apply

1. Porting a design onto a legacy Roku screen: grep for every `findNode`/field/handler that code uses, keep those names, swap the drawing, park unshown-but-written fields in an invisible Group.
2. A list item that must keep its own content logic should wrap the shared tile and forward `focusPercent` / `gridHasFocus`.
3. Deploy with the ported `tools/deploy.ps1` (curl only, explicit package scope; asserts no .git, .env, docs, out, tools). Check scope with `node tools/check-scope.js` (Sd prefix, relative script URIs).
4. Verify on the device, not in the compiler. Before the next phase, finish the open items: DVR overlay device pass after a login, Nuevo Tiempo stalling at `open`/`startup` (probably the stream, unconfirmed on the old build), restyle the legacy grey Dialog as `SdDialog`, store icon and splash still old 540x405 art with splash_color `#000000` against the `#0B1222` ground.

## Related

[[mysdatv-design-systems-index]], [[mysdatv-design-lineup-alpha-a]], [[port-between-engine-twins-by-prefix-normalised-diff]], [[verify-on-device-not-in-the-compiler]], [[scope-the-channel-package-explicitly]], [[key-event-fires-on-both-down-and-up-edges]], [[poster-recycled-item-loadstatus-traps]]
