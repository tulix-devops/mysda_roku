# report-learn: three-design-directions

## STATUS
COMPLETED: the design phase is done. Three design systems are drawn on all 8 screens each; C and A are final, and B waits on the owner's pick of G1 or G2.

## Summary
The owner asked for three different overall designs for the mySDAtv Roku channel, screen by screen, grounded in the metadata the feeds really carry. Each will later be built on its own branch.
- **Built from real data.** The live feeds were measured first (`data-brief.md`). The boards use real logos, titles, times and frame grabs from 5 Oct 2026, 3:20 PM.
- **Reviewed as rendered sheets.** The boards were rendered to 1920x1080 JPEGs with headless Chrome and reviewed as contact sheets. There were six owner rounds.
- **Outcome:**
  - C Showcase final (left floating capsule, whole logo, screen titles);
  - A Lineup final as α "Ink and ember";
  - B Guide shapes final (B-1). After 8 rejected menu-style navigations, the navigation was restructured into G1 (category spine) and G2 (channel list plus day timeline). Both are drawn; the pick is pending.
- **Where it lives:** `docs/design/` (README index, `showcase.md`, `lineup.md`, `guide.md`, JPEGs, board sources in `source/`).

**Owner request for the knowledge base (2026-10-06):** "save these design solutions inside Roku knowledge for the Roku team". So the three design systems themselves MUST be filed as app-layer entries (`D:\Roku\mysdatv\docs\team\knowledge\`). Each entry carries the system's idea, tokens, type, shape and focus language, navigation, the 8 screens, its status, and a pointer to `docs/design/<system>.md` and its final screenshot folder. One more app entry covers the feed facts that drive the designs. The transferable lessons below go to the portfolio layer if they pass the bar.

## Learnings candidates

### App layer (mysdatv): the design solutions (owner-requested, file all)

- **The design systems index.** Three systems:
  - **C Showcase.** The final screens are `docs/design/showcase/` C1-C8 (sheet `sheet-C-Showcase-v3.jpg`). The spec is `docs/design/showcase.md`.
  - **A Lineup α.** The final screens are `docs/design/lineup/alpha/` AX1-AX8. The spec is `lineup.md`, section "Decided: α".
  - **B Guide.** The screens are `docs/design/guide/g1/` and `g2/`, BG1-1..8 and BG2-1..8. The spec is `guide.md`.
  - Evidence: the README "Final screens" table and the owner's quotes in each spec.
- **C Showcase spec.** Ground `#07080C`; accent blue `#1E8BFF`; live red `#F0262B`; Plus Jakarta Sans 500-800.
  - **Navigation.** A left floating glass capsule at x 32, y 250, 104 px wide with five 72 px icon circles. It widens to 330 px with labels on focus, while the page dims to 50 %.
  - **Logo and titles.** The WHOLE logo sits above it at 144x75; the owner rejected a globe crop. Every screen has a title at x 184, y 46, Plus Jakarta 46/800.
  - **Focus.** It lifts (scale 1.06-1.08, a shadow) with no border.
  - **Screens.** Home, Channel page, All channels, Radio, Catch-up by series, Live player, Catch-up player, Account.
- **A Lineup α spec.** A flat ink `#0A0D16` ground with no gradient.
  - **Rail.** A solid panel with WATCH / LISTEN / ACCOUNT sections. Icon tiles fill red `#F0262B` on focus; gold `#FAD35A` means "selected"; a "Last watched" card sits at the bottom.
  - **Type and tiles.** Manrope + Inter. Logo tiles are shown whole with now line and progress.
  - **Screens.** Television, Languages, Radios, Radio playing, DVR channels, DVR recordings, Live player, Account.
  - Phase 1 (the WPALive port, "My red" palette in `source/SdTheme.brs`) is the code base it extends.
- **B Guide spec.** Ground `#050B1E`; panel `#0A1630`; cell `#0F1E3C` (on-now `#15284D`); gold focus `#FAD35A`; Barlow + Barlow Condensed.
  - **Shapes (B-1).** Pill buttons and chips; 14 px cells with 8 px gaps; the primary button gets a gold ring only when focused.
  - **G1 category spine.** The guide's left column is a filter list with counts from the catalogue: All 40 · English 24 · Español 6 · Português 3 · More languages 7 · 3ABN family 11 · LLBN family 9 · Radio 10. Catch-up is reached by moving left in time, with a "‹ TODAY" chip.
  - **G2 channel list.** A channel list with now and progress, plus a category dropdown. The right side shows a preview, then the focused channel's day of replays, live and later, with a "‹ Yesterday" chip.
  - **Status.** The pick between G1 and G2 is pending.
- **Design rules from the feeds** (`data-brief.md`):
  - Logos are 225x160 on white; show them whole at 1.41, never cropped to 16:9.
  - Only the 3ABN family has programme titles; others return hourly "Program", so show "Live now · 3 PM hour".
  - Frame grabs (320x180) exist only after airing, and are often bumpers; every frame card carries the channel logo.
  - No descriptions anywhere.
  - `getdvr.php` is about 377 KB per channel: lazy-load the visible channels, or ask for a now/next endpoint.
  - `getdvr.php` has no server-side auth (a security finding, reported).
  - The logo host returns 403 to a bare curl without a user-agent.
  - Evidence: the measured JSON in `data/`.
- **The Phase 1 port pattern** (from `../2026-10-06-wpalive-design-port/report-roku.md`; read that file, including its reviewer note).
  - **Keep the legacy contract.** Keep the legacy node ids, fields and handlers and replace only the drawing. Fields that are written but no longer shown go into an invisible Group.
  - **Wrapper item.** A wrapper item (`DVREpisodeItem`) hosts the shared `SdTile` and forwards focusPercent / gridHasFocus.
  - **Exit.** Exit goes via `m.global.sdExitApp`, because the scene `exitApp` observer never reached main on fw 15.3.4. The reviewer said not to file this as a firmware fact without a minimal repro, so keep it app-layer and app-specific.

### Portfolio candidates (transferable)

- **EPG navigation: restructure, don't reskin.**
  - On a guide-first TV app, eight menu shapes bolted onto the guide were all rejected by the owner: top tabs, label rail, gold capsule, dock tiles, bottom dock, hero menu, menu sheet, title dropdown, edge strip ("really bad navigation designs, we can do better").
  - What worked was mapping each destination to the guide's own axes. Languages and networks are FILTERS on the channel column. Catch-up is the same schedule EARLIER in time (move left). Radio is another channel set. Only Account is a real destination; it becomes a round button top-right.
  - Evidence: the owner's rejection of `guide/nav-options/` (8 boards), then G1/G2 accepted for a full 8-screen build.
  - Bit us in: B Guide navigation rounds 1-3.
- **Exactly one focus indicator per screen.**
  - A primary button that wears a "focus" ring at rest, next to the really focused cell, reads as two focuses. Give the ring only to the holder of focus; the primary can stay gold-filled at rest.
  - Evidence: caught in the B board review and fixed across all boards.
  - Bit us in: the B Guide boards.
- **Never crop the brand logo to a mark for navigation.**
  - A globe crop of the mySDAtv logo cut through the letters; the owner rejected it ("logo at navigation is not correct"). The fix is to place the whole wordmark above the floating nav.
  - Check against the existing [[logo-is-only-as-big-as-its-smallest-legible-part]] and merge if it is the same lesson.
- **A floating left nav leaves the top-left empty: give every screen a title.**
  - The owner asked for this to fill the gap and orient the viewer. A title at the content's left edge (x 184, y 46), with a grey subtitle carrying counts, e.g. "Channels · 40 live channels".
- **Windows tooling: the System.Drawing JPEG quality parameter.**
  - In PowerShell 5.1, `New-Object System.Drawing.Imaging.EncoderParameter ([Encoder]::Quality),[long]88` makes `Image.Save(path, codec, params)` throw "Parameter is not valid" and leave a 0-byte file.
  - `[System.Drawing.Imaging.EncoderParameter]::new([System.Drawing.Imaging.Encoder]::Quality, [long]88)` works.
  - Evidence: 18 empty JPEGs on the first save, all good on the retry (2026-10-06).
- **Windows tooling: headless Chrome screenshots.**
  - Looping `chrome --headless --screenshot` from Git Bash reported files written that never appeared.
  - `Start-Process -FilePath chrome -ArgumentList ...,"--screenshot=`"$out`"",$url -Wait` from PowerShell, one board per call, was reliable: 23 boards rendered.
  - Check the existing tooling entries first.

## Knowledge applied
- [[generate-concepts-at-device-scale-on-real-data]] (boards at 1920x1080 on real feed data)
- [[verify-field-population-before-designing]] (data brief before any design)
- [[logo-is-only-as-big-as-its-smallest-legible-part]]
- [[trial-palette-must-paint-from-the-theme-at-init]] (Phase 1 palette switch)

## Knowledge contradicted
none
