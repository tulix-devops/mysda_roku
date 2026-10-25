---
topic: mysdatv-design-lineup-alpha-a
summary: mySDAtv design A Lineup alpha "Ink and ember" (FINAL) - flat ink ground, solid sectioned rail (WATCH/LISTEN/ACCOUNT) with red-filled focus tiles and gold "you are here", Manrope+Inter; extends the Phase 1 build; 8 screens
platform: roku
applies-to: [mysdatv]
observed-in: [mysdatv]
date: 2026-10-06
source-task: mysdatv/docs/team/tasks/2026-10-06-three-design-directions/
---

# Design A: Lineup, alpha "Ink and ember"

Spec: `D:\Roku\mysdatv\docs\design\lineup.md`, section "Decided: alpha". Final screens: `D:\Roku\mysdatv\docs\design\lineup\alpha\` (AX1-AX8), sheet `sheet-A-alpha.jpg`. Index: [[mysdatv-design-systems-index]].

## Fact

**Idea.** The rail-and-grid build on the TV today (WPALive engine, "My red" palette), refined. Channels are logo cards shown whole, each with a "now" line and a progress bar. DVR is a channel grid, then days plus recordings.

**Status.** First draft liked with two owner notes: "we are not strictly bounded to the gradient colour we have on background" and "navigation still feels plain". Three options were drawn in `lineup/options/` (alpha Ink and ember, beta Brand ribbon with a red/gold/blue edge ribbon and a globe-mesh watermark, gamma Dock tiles on plum-black). DECIDED alpha (owner, 2026-10-06): "A lineup Alpha is good, expand that design fully with every screen." The first version (radial lamp, plain rail) stays in `lineup/` as history.

**Tokens (alpha).**
- ink `#0A0D16` page: FLAT, no gradient, soft black vignette at the bottom
- panel `#11151F` (rail, DVR day panel); tile `#1A2030` (icon tiles at rest, secondary buttons, chips); surface `#141927` (clock pill, QR card)
- section label `#6F7891`, 17/700, tracking 2.5; text2 `#8C95AA`
- focus `#F0262B`: the focused icon tile with a red glow, the primary button (with a white ring), the tile glow
- selected `#FAD35A`: where you are (tile tinted gold at 16 %, gold label and dot). Lockup blue `#0981FB` is the "tv" in the logo.

**Type.** Manrope (display: 54 heading, 30 clock) and Inter (body 22-29).

**Shape and focus.** Cards radius 16, buttons 20, chips and pills fully round. Tiles rest at scale 0.92 with the picture dimmed; focus grows them to 1.0 with a soft red glow and the title turns red; no border. The live player's info sits on a docked ink panel (radius 32), not a gradient wash.

**Navigation (rail).** A solid ink panel in both states, 120 px closed and 440 px open; the page slides by 320 and is never re-laid out.
- Closed: whole logo at 100x52, 56 px icon tiles (radius 16), hairline dividers between sections.
- Open: logo at 186x97, sections WATCH / LISTEN / ACCOUNT with labels, and a "Last watched" card at the bottom.
- Focus is a red-filled tile; "selected" is gold. Focus and selection are separate channels ([[focus-and-selection-are-different-channels]]).

**The 8 screens.** 1 Television; 2 TV Languages (rail open, language chips); 3 Radios; 4 Radio playing; 5 DVR channels; 6 DVR recordings (a day panel and frame grabs); 7 Live player; 8 Account (rail open).

## Why it matters

A is the lowest-risk path: it evolves the shipped Phase 1 code (`source/SdTheme.brs`, palette `myred`, `SdTile`, the 120/440 rail), so the build is a retheme plus the new rail sections, not a rewrite. See [[mysdatv-wpalive-port-pattern]].

## How to apply

- Change tokens through the theme table and repaint at init ([[trial-palette-must-paint-from-the-theme-at-init]]); the ground becomes the flat `#0A0D16` instead of the radial lamp.
- Keep the "Last watched" card local: the server has no per-viewer data, the registry can hold it ([[mysdatv-feed-derived-design-rules]]).
- Logo tiles show the whole 225x160 logo at 1.41; never the 16:9 crop the Phase 1 grid used.

## Related

[[mysdatv-design-systems-index]], [[mysdatv-wpalive-port-pattern]], [[focus-and-selection-are-different-channels]], [[trial-palette-must-paint-from-the-theme-at-init]], [[mysdatv-feed-derived-design-rules]]
