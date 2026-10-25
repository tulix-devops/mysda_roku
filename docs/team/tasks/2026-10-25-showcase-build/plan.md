# Plan: build C · Showcase (mySDAtv Roku)

Date: 2026-10-25 · Mode: /solo (Roku) · Branch: `design/showcase` (owner-approved), from `main` @ 20d8958.

## Goal

Turn the app into the C · Showcase design (`docs/design/showcase.md`; screens C1-C8 in `docs/design/mysda-showcase/`; the board sources in `docs/design/source/C*.dc.html` give exact positions). Everything the viewer sees and how they move around changes. The data, sign-in, entitlement and playback plumbing stays.

**Constraint (owner, 2026-10-25):** the Roku device is busy in another session. This round is **code only**. Verification is static (compiler and scope check). Device review follows in a later round.

## Approach

A new shell, built the way the WPALive engine's `WpScene` is built (D:\Tulix\wpa_live_roku). It is proven on device: one scene, screens in a group, the scene owns the one Video node, dialog and sign-in overlays, a clock, a boot watchdog, and m.global request fields. The new components use the prefix **Sc**. The legacy screens stay in the repo but are no longer reachable (removing them is a later clean-up).

| Layer | New | Reused |
|---|---|---|
| Boot | `main.brs` creates `ScScene`; deep links passed through | exit via `m.global.sdExitApp` |
| Theme | `source/ScTheme.brs` (Showcase tokens), `ScGlobals.brs`, `ScTime.brs`, `ScCatalogue.brs`, `ScSchedule.brs` | `SdPaint` pattern |
| Data | `ScFeedTask`: catalogue lists 8/9/10. `ScScheduleTask`: `getdvr.php` for one channel, parsed in the Task, cached by the scene. It loads only the channels a screen shows, at most 2 at once. | the existing endpoints, headers and auth from the legacy APIs |
| Sign-in and entitlement | `ScSignIn` overlay (full Keyboard), driven by the scene | the existing login, purchase and subscription APIs and registry keys |
| Navigation | `ScNav`: floating capsule, 5 destinations; widens to 330 px with labels on focus, page dims 50 % | |
| Screens | `ScHome` (C1), `ScChannel` (C2), `ScChannels` (C3), `ScRadio` (C4), `ScCatchup` (C5), `ScAccount` (C8) | |
| Players | `ScPlayer`: live mode (C6, channel strip on Left/Right) and catch-up mode (C7, seek bar, ±10 s, next episode); radio uses live mode with a now-playing card | |
| Widgets | `ScHeader` (logo, title, subtitle, clock), `ScHero`, `ScCard` (frame / logo / later / series kinds, one focus language: lift 1.06-1.08 plus shadow, white caption), `ScButton` (pill, white when focused), `ScDialog` | |

## Plumbing facts the build relies on (context-brief.md)

- **Catalogue.** GET `https://sda.wchupload.tulix.net/api/content/{8,9,10}/list?limit=200`, with no auth.
  - The stream URL, `dvr_url` and stream id live in `data.sources.primary`, `data.dvr_url` and `attributes[""][1]`.
  - The parse moves into the Task (`ScFeedTask`), with a real error path. Today a non-200 answer leaves the screen empty forever.
- **Schedule.** GET `dvr_url` (`https://livetv.mysdatv.com/api/getdvr.php?id=<stream>`). It returns a top-level array, newest first: `id`, `starttime`, `endtime`, `duration`, `title`, `thumb`, `stream`.
  - Parse it in the Task, never on the render thread. Each body is about 377 KB.
- **Who may watch catch-up.**
  - Live and radio are free.
  - Catch-up needs `AUTH.authData` (`accessToken`, `isauth`, `expiry`) plus the check-purchase POST with `productId` 15.
  - Sign-in POSTs to `/api/login`; the result is stored as the same `AUTH.authData` JSON.
  - The resume position goes in registry section `positions`, keyed by recording id.
  - All of these are kept exactly as they are, so a viewer who is already signed in stays signed in.
- **Deep links.** Today every launch deep link shows an error scene, and runtime links do nothing. Showcase makes them real:
  - `contentId` = a catalogue id plays that channel live;
  - an unknown id lands on Home.
  - The shell resets before playing (`deep-link-while-running-must-reset-the-shell`).
- **HLS VOD may never report `finished`.** The catch-up player watches `position >= duration - 1`.

## Package budget

The package is **3.55 MB today** (`deploy.ps1 -PackageOnly`), against Roku's **4 MB** limit. The Showcase fonts and icons add about 0.2-0.3 MB. The unreachable legacy screens, about 20 components plus their art, still ship and still run `init()` at boot (`home_screen` fires a request to a dead `joygo` host). Once Showcase replaces the front end, the old grid screens are unreachable too.

**Proposed:** a final commit on this branch removes components and images nothing reachable references. It is checked by the compiler (no missing functions or components) and by the package's file list.

## Data rules (from data-brief.md, all binding)

- **Logos.** Show them whole on a white plate at 1.41; never crop them.
- **Titles.** Programme titles exist for the 3ABN family only. Other channels show "Live now · 3 PM hour", never "Program". Titles go from upper case to Title Case.
- **Frame grabs.** Use them only once a programme has aired; later slots get a logo card. Every frame card carries its logo badge.
- **Schedule load.** Lazy, cached for the session, never in the boot gate.
- **Catch-up playback.** It needs a signed-in, entitled viewer; otherwise it goes to Account / sign-in.

## Assets

- **Fonts.** Plus Jakarta Sans 500/600/700/800 TTF. It is OFL; get it from the Google Fonts repository.
- **Nav icons.** Home, Channels, Radio, Catch-up and Account, rendered from the boards' SVG paths to PNG (white, tinted in code), at 2x.
- **Shapes.** Card corner masks r14 in the ground colour, a 72 px circle, and a soft shadow; added to `tools/build-assets.ps1`.

## Acceptance criteria (this round, static)

1. `main.brs` boots `ScScene`. Every C1-C8 screen exists and is reachable through the capsule or its flow: Home → channel page → live player; Catch-up → catch-up player; Radio → listen; Account → sign-in.
2. **Compiler.** brighterscript 0.73 (`bsc`, run on a copy) reports **0 errors** on the whole project. The baseline before this work is 0.
3. **Scope check.** `node tools/check-scope.js` is clean on every new Sc component.
4. **Package.** It is scoped as today and stays under 4 MB (`tools/deploy.ps1` packaging dry-run).
5. **Design rules.** No hard-coded colour in Sc XML that the theme does not paint. One focus indicator per screen. The capsule hides in the players. The whole logo is in the header.
6. **Review.** An independent reviewer finds no HIGH issues.
7. **Report.** `report-roku.md` lists everything NOT verified on device.

## Out of scope (this round)

- Device verification and screenshots. They come next round, when the device is free.
- (Pruning unreachable legacy code and art IS in scope: owner, 2026-10-25, as the final commit.)
- Search: Showcase has no search screen.
- Backend asks (a now/next endpoint, auth on `getdvr.php`).
- The A and B systems.

## Commits

One commit per milestone on `design/showcase`: foundation, then shell and nav, then data, then screens, then players, then review fixes. No push without the owner's word.
