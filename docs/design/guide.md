# B · Guide

This is a cable-style TV guide first: channels down, time across, a live preview on top. Catch-up is the same guide scrolled into the past 21 days, so there is no separate DVR world.

**Status (owner, 2026-10-06):** liked. One note to revisit:
- **Buttons.** "Buttons feel too cornery": the 8 px radius on buttons, cells and chips reads hard. Redesign the shape language (rounder buttons and pills; check the guide cells).

![Guide](guide/sheet-B-Guide.jpg)

## Tokens

| Token | Value | Use |
|---|---|---|
| ground | `#050B1E` | Page |
| panel | `#0B1733` | Channel column, panels |
| cell | `#10203F`; `#16294F` when on now | Programme cells |
| line | `#1C2E55` | Hairlines, tracks |
| focus | `#FAD35A` with `#050B1E` ink | Focused cell, button and tab underline; the now-line |
| live | `#F0262B` | LIVE pill; the catch-up now-line |
| text2 | `#A9B6CF` | Meta |

## Type and shape

- **Type.** Barlow Condensed 700 for display, tabs and times. Barlow 500-700 for body.
- **Radius (to be redesigned).** Today it is 8 px on cells, buttons and chips, and 12-16 px on panels.
- **Guide scale.** 30 minutes = 369 px (12.3 px a minute). Rows are 84-98 px.

## Screens (`guide/`)

1. Guide (launch)
2. Languages guide
3. Radio
4. Catch-up (the guide backwards, with day strip)
5. Programme detail (series row)
6. Player mini guide
7. Player info bar
8. Account

## Softer shape options (2026-10-06)

All three are in `guide/options/`.

![B options](guide/options/sheet-B-options.jpg)

- **B-1 · Pill controls, soft cells.**
  - Buttons, tabs and chips are full capsules; the tabs become a segmented pill bar.
  - Guide cells have a 14 px radius and 8 px gaps.
  - The focused button gets a gold ring with a gap.
- **B-2 · Soft 16 px.**
  - One 16 px radius for buttons and 12 px for cells.
  - The underline tabs are kept.
- **B-3 · Capsule everything.**
  - Programme cells are capsules too (42 px radius), with 10 px gaps.
  - The tab bar is a floating capsule.

## Shapes decided; navigation options (owner, 2026-10-06)

"B option shapes are good. Top navigation is really bad."
- **Shapes.** The base is now **B-1**: pill buttons and chips, 14 px guide cells with 8 px gaps, and a focused primary button with a gold ring and gap. (B-1 was assumed, since the owner did not name a variant.)
- **Navigation.** The top tab bar is dropped. Three left-side options are in `guide/nav-options/`:

![Guide nav options](guide/nav-options/sheet-B-nav-options.jpg)

- **Nav 1 · Rail with labels.** A 280 px navy panel with the whole logo and condensed upper-case labels. The selected item is gold with a dot.
- **Nav 2 · Gold capsule.** Showcase's floating capsule in the guide's navy and gold. The guide gets the most width.
- **Nav 3 · Dock tiles.** A 150 px column of icon-over-label tiles, so every destination stays named.

In all three, the screen names itself in the header: "TV GUIDE · Today · 24 channels".

### Five more navigation options (owner asked, 2026-10-06)

![Guide nav options 2](guide/nav-options/sheet-B-nav-options-2.jpg)

- **Nav 4 · Bottom dock.** A floating capsule bar centred at the bottom: icon and label pills, with Guide filled gold. No side or top bar; the guide shows 4 rows.
- **Nav 5 · Hero menu.** A big condensed text menu in the top-left, cable-box style. The preview and the programme sit to its right, and the guide runs the full width.
- **Nav 6 · Menu sheet.** At rest there is only a MENU pill. Pressed, a 520 px sheet slides in with a sub-line per destination ("16 channels, 9 languages"). The page dims behind it.
- **Nav 7 · Title dropdown.** The screen title is the menu ("TV GUIDE ▾"). It drops a list of destinations with sub-lines.
- **Nav 8 · Edge strip.** A 72 px strip of icons only, with the active one marked by a gold bar. The most screen goes to the guide.

## Navigation rethought (owner, 2026-10-06: "really bad navigation designs, we can do better")

The eight menu options above were one idea in eight shapes: a menu bolted onto a guide. The structure was the real problem. Languages is a filter on the channel list, Catch-up is the same schedule earlier in time, and Radio is another set of channels. Only Account is a true destination. So navigation moves INTO the guide:

![Guide rethink](guide/rethink/sheet-B-guide-rethink.jpg)

- **G1 · Category spine.**
  - The guide's own left column is a filter list: All 40 · English 24 · Español 6 · Português 3 · More languages 7 · 3ABN family 11 · LLBN family 9 · Radio 10. The counts come from the catalogue.
  - Focus on a category filters the guide live (shown on Español).
  - Catch-up is reached by moving left in time; a "‹ TODAY" chip sits on the time ruler, with a hint card under the spine.
  - Search and Account are round buttons top-right.
- **G2 · Channel list with a day timeline.**
  - Channels go down the left, each with now and progress. A category switcher ("English · 24 channels ▾") sits on top.
  - The right side has a big live preview, then the focused channel's whole day: replays with frame grabs, the live one, and later ones by time, with a "‹ Yesterday" chip.
  - A replay in focus becomes "Play from start" or "Back to live".

**Rule kept:** exactly ONE focus indicator per screen. The primary button is gold at rest but gets the ring only when it holds focus.

## All screens in both navigations (owner, 2026-10-06)

The owner asked for every screen in both G1 and G2, to choose between them. The shapes are B-1 in both. Each folder holds 8 screens plus a `sheet-*` contact sheet; the sources are `source/BG1-*.dc.html`, `source/BG2-*.dc.html` and `source/gen-b-full.js`.

### G1 · Category spine (`guide/g1/`)

![G1 all screens](guide/g1/sheet-B-G1.jpg)

1. **Guide.** English is selected in the spine; focus is on the live 3ABN cell.
2. **Languages.** Focus is on Español in the spine, and the guide filters live to its channels, with "+3 more Español channels".
3. **Radio.** Spine on Radio; each station is one long "on air now" cell, since radio has no schedule.
4. **Catch-up.** The guide scrolled back to 2:00 PM with an "‹ EARLIER TODAY" chip. Aired cells carry frame grabs; focus is on "A Wolf in Sheep's Clothing" (Play from start).
5. **Programme.** The Carter Report, with "More of The Carter Report · 30 recordings in the last 21 days".
6. **Player + guide.** A full-width mini guide over the picture; Left goes earlier.
7. **Player info.** The bottom info bar: logo, title, progress, Start over / Open guide.
8. **Account.** Log in for catch-up, the perks, and the donation QR.

### G2 · Channel list with a day timeline (`guide/g2/`)

![G2 all screens](guide/g2/sheet-B-G2.jpg)

1. **Guide.** The channel list on the left, the preview and "Today on 3ABN" on the right.
2. **Languages.** The category switcher opens as a dropdown over the dimmed page; focus is on Español.
3. **Radio.** The station list, a big station logo with Listen, and a "More stations" strip.
4. **Catch-up.** "Yesterday on 3ABN · Sat Oct 4": replay cards with frame grabs; focus is on The Carter Report at 5:00 PM.
5. **Programme.** As in G1, reached from the day timeline ("‹ Today on 3ABN").
6. **Player + guide.** The channel list slides over the picture; OK switches, Right shows today on that channel.
7. **Player info.** The info bar plus a "Today" strip of the channel's programmes.
8. **Account.** As in G1.

**Open:** the owner picks G1 or G2.
