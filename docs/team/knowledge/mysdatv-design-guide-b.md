---
topic: mysdatv-design-guide-b
summary: mySDAtv design B Guide - navy/gold TV guide, B-1 pill shapes final, nav rebuilt as G1 (category spine) or G2 (channel list + day timeline), both drawn on 8 screens, owner pick PENDING
platform: roku
applies-to: [mysdatv]
observed-in: [mysdatv]
date: 2026-10-06
source-task: mysdatv/docs/team/tasks/2026-10-06-three-design-directions/
---

# Design B: Guide (G1 and G2, pick pending)

Spec: `D:\Roku\mysdatv\docs\design\guide.md`. Final screens: `D:\Roku\mysdatv\docs\design\guide\g1\` (BG1-1..8, sheet `sheet-B-G1.jpg`) and `D:\Roku\mysdatv\docs\design\guide\g2\` (BG2-1..8, sheet `sheet-B-G2.jpg`). Index: [[mysdatv-design-systems-index]].

## Fact

**Idea.** A cable-style TV guide first: channels down, time across, live preview on top. Catch-up is the same guide scrolled into the past 21 days, so there is no separate DVR world.

**Status (owner, 2026-10-06), in order.**
1. Guide liked; note: "buttons feel too cornery" (8 px radius). Three softer shape options drawn; owner: "B option shapes are good. Top navigation is really bad." B-1 became the base (assumed, since no variant was named).
2. Top tab bar dropped; eight left-side/menu navigation options drawn in `guide/nav-options/` (rail with labels, gold capsule, dock tiles, bottom dock, hero menu, menu sheet, title dropdown, edge strip). All rejected: "really bad navigation designs, we can do better".
3. Navigation restructured INTO the guide (`guide/rethink/`): G1 and G2. The owner asked for all 8 screens in both to choose. PICK BETWEEN G1 AND G2 IS PENDING; do not start building B navigation before it.

**Tokens.** ground `#050B1E`; panel `#0A1630` (earlier draft `#0B1733`); cell `#0F1E3C`, on-now `#15284D`; line `#1C2E55`; focus gold `#FAD35A` with `#050B1E` ink (focused cell/button, now-line); live `#F0262B` (LIVE pill, catch-up now-line); text2 `#A9B6CF`.

**Type.** Barlow Condensed 700 for display, tabs and times; Barlow 500-700 for body. Guide scale: 30 min = 369 px (12.3 px a minute); rows 84-98 px.

**Shapes (B-1, final).** Buttons, chips and tabs are full pills (tabs as a segmented pill bar); guide cells radius 14 with 8 px gaps; a focused primary button gets a gold ring with a gap. Rule: exactly ONE focus indicator per screen; the primary button is gold at rest and wears the ring only when it holds focus.

**Why navigation moved into the guide.** The menu options were one idea in eight shapes. Languages is a filter on the channel list, Catch-up is the same schedule earlier in time, Radio is another set of channels; only Account is a true destination. See [[guide-first-tv-nav-restructure-not-reskin]].

**G1: category spine** (`guide/g1/`). The guide's own left column is a filter list with catalogue counts: All 40 · English 24 · Español 6 · Português 3 · More languages 7 · 3ABN family 11 · LLBN family 9 · Radio 10. Focus on a category filters the guide live. Catch-up = move left in time; a "‹ TODAY" chip on the ruler plus a hint card under the spine. Search and Account are round buttons top-right.
1. Guide (English selected, focus on the live 3ABN cell). 2. Languages (focus Español, guide filters live, "+3 more Español channels"). 3. Radio (each station one long "on air now" cell, radio has no schedule). 4. Catch-up (guide scrolled back to 2:00 PM, "‹ EARLIER TODAY" chip, aired cells carry frame grabs; focus "A Wolf in Sheep's Clothing", Play from start). 5. Programme (The Carter Report, "More of The Carter Report · 30 recordings in the last 21 days"). 6. Player + guide (full-width mini guide over the picture, Left goes earlier). 7. Player info (bottom bar: logo, title, progress, Start over / Open guide). 8. Account (Log in for catch-up, perks, donation QR).

**G2: channel list with a day timeline** (`guide/g2/`). Channels down the left, each with now and progress; a category switcher ("English · 24 channels ▾") on top. Right side: big live preview, then the focused channel's whole day (replays with frame grabs, the live one, later ones by time) with a "‹ Yesterday" chip. A replay in focus becomes "Play from start" or "Back to live".
1. Guide (channel list; preview and "Today on 3ABN"). 2. Languages (switcher opens as a dropdown over the dimmed page; focus Español). 3. Radio (station list, big logo with Listen, "More stations" strip). 4. Catch-up ("Yesterday on 3ABN · Sat Oct 4", replay cards; focus The Carter Report 5:00 PM). 5. Programme (as G1, reached from "‹ Today on 3ABN"). 6. Player + guide (channel list slides over the picture; OK switches, Right shows today on that channel). 7. Player info (info bar plus a "Today" strip). 8. Account (as G1).

## Why it matters

B is the riskiest build: G1 and G2 imply different data loading. G1 needs now/next for the channels in the visible grid at once; G2 needs a whole day for one focused channel. At about 377 KB of schedule JSON per channel, the lazy-load or now/next-endpoint decision in [[mysdatv-feed-derived-design-rules]] gates both.

## How to apply

- Wait for the owner's G1/G2 pick; record it here and in [[mysdatv-design-systems-index]].
- Never reintroduce a top tab bar or a menu bolted onto the guide.
- Keep one focus indicator per screen.
- Do not use the word "Program"; non-3ABN channels show "Live now · 3 PM hour".

## Related

[[mysdatv-design-systems-index]], [[guide-first-tv-nav-restructure-not-reskin]], [[focus-and-selection-are-different-channels]], [[mysdatv-feed-derived-design-rules]]
