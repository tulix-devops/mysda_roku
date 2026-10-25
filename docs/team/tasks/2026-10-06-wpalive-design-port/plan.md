# Plan: mySDAtv redesign on the WPALive design system

Date: 2026-10-06 · Mode: /solo (Roku) · Repo: D:\Roku\mysdatv
Design source: D:\Tulix\wpa_live_roku (final files at 968550a)

## Goal

Give mySDAtv the WPALive.TV look and feel. That means the theme tokens, the
collapsing rail, tile focus (scale plus a soft glow, no border), the top bar,
the clock and the dialog. mySDAtv's data, APIs, auth, DVR purchase check and
playback all stay as they are. Only the presentation layer changes.

## What is live today (recon)

Only a small part of the app is reachable:
- **Nav bar.** Television, TV Languages, DVR, Radios, and Login/Logout.
- **Grids.** Four cloned grid screens (`vod_screen`, `second_vod`,
  `third_vod`, `dvr_vod`). Each is a 5x4 MarkupGrid of `RowListItemComponent`.
- **DVR.** `DVROverlayScreen`, with a sidebar of `DVRSidebarItem` and an
  episode grid of `DVREpisodeItem`.
- **Login.** `LoginInfoScreen` with its promo text and QR code.
- **Player.** `VideoDVRScreen`, which auto-plays full screen.
- **Dialogs.** Keyboard, progress and back dialogs.

Everything else (`home_screen`, `live_screen`, `search_screen`,
`saved_screen`, `account_screen`, `login_screen`, `DetailsScene`,
`SeasonScreen` and the rest) is unreachable. It stays untouched.

## Acceptance criteria

1. **Theme.**
   - A single theme file, `source/SdTheme.brs`, ported from `WpTheme`, with
     the prefix `Sd`.
   - Every ground and surface colour on the redesigned surfaces is painted
     from the theme in `init()`. No palette hex literals in the XML (KB:
     `trial-palette-must-paint-from-the-theme-at-init`).
2. **Rail.**
   - The nav bar is replaced by a WPALive-style collapsing rail: 120 px
     collapsed, 440 px open.
   - Its states are focused (accent pill), selected (accent label, icon and
     dot) and idle.
   - The page slides 320 px when the rail opens and is never re-laid out.
   - It keeps the same five destinations, in the same order, with the same
     behaviour. That includes the login/logout keyboard flow and the
     logged-in label.
3. **Grids.**
   - All four grid screens get a top bar (the mySDAtv logo and a heading) and
     a live clock (today the clock is set once and never updates).
   - Tiles use the WPALive treatment: a plate with rounded art, rest scale
     0.92 with the art dimmed, and on focus scale 1.0, a soft accent glow and
     an accent title.
   - The focus glow is never clipped (MarkupGrid padding rule T2).
   - The data feed, the OK action and the hand-off to the player are
     unchanged.
4. **DVR overlay.** The sidebar and episode cards are restyled with the theme:
   - the sidebar uses accent-pill focus;
   - the episode cards use the tile treatment.
5. **Login info screen.** Restyled on the theme: the logo, body type and a
   surface plate behind the QR code.
6. **Back contract.**
   - From the content, Back opens the rail.
   - From the rail, Back exits the channel (via a dialog).
   - This fixes today's channel, where Back can never exit (a certification
     blocker).
7. **Fonts and assets.**
   - Manrope and Inter, the 9-patch shapes, glow frames tinted with the
     accent, a ground picture, and nav glyphs (TV, globe/languages, DVR,
     radio, account) are generated or copied into `images/`.
8. **Tooling.**
   - Add `tools/deploy.ps1` (curl only, explicit package scope),
     `tools/capture.ps1` and `tools/check-scope.js`, adapted from wpa with
     the `Sd` prefix.
   - Add a `.gitignore` covering `.env` and `out/`.
9. **Verified on the Roku Express (192.168.0.106).**
   - Screenshots of the rail open and closed, each grid, the DVR overlay and
     the login screen.
   - A playback start proven through ECP `/query/media-player`.

## Files expected to change

- **New:**
  - `source/SdTheme.brs`, `SdGlobals.brs`, `SdMetrics.brs` and `SdTime.brs`
    (clock only)
  - `components/widgets/SdTopBar`, `SdDialog` (if used for the exit
    confirmation), and the new rail `components/screens/SdNavRail`
  - `images/fonts/*`, `images/png/shapes/*`, `images/png/nav/*` and
    `images/png/ground/*`
  - `tools/*` and `.gitignore`
- **Edited:**
  - `components/home_scene.{xml,brs}`
  - `vod_screen`, `second_vod`, `third_vod` and `dvr_vod` (`.xml` and the
    focus/Left/Back hand-off in `.brs`)
  - `widgets/RowListItemComponent.{xml,brs}`
  - `DVROverlayScreen`, `DVRSidebarItem` and `DVREpisodeItem`
  - `LoginInfoScreen`
- **Retired:** `navigation_bar.{xml,brs}`. It is kept on disk; only its use
  in `home_scene` is removed.

## Out of scope (flagged, not done)

- **Data and API layer.** No changes to the API, auth, purchase or registry
  logic.
- **Dead screens.** Not deleted. Pruning them is a separate task.
- **Merging the four grid clones** into one component. It is tempting, but it
  is a refactor, not a redesign.
- **Store assets.** The channel icon, splash and the manifest's
  `mm_icon_focus_fhd` are a store-asset follow-up (KB:
  `manifest-icon-requirements-drift`).
- **Security findings.** The password is printed to the console, the access
  token is printed, and `.env` and `launch.json` are committed to git. These
  are reported as a separate task.
- **System dialogs.** Roku's own `KeyboardDialog` and `ProgressDialog` stay
  as they are.
- **Player chrome.** The chrome of `VideoDVRScreen` (auto-play hides it)
  only gets theme colours where it is visible.
