# Plan: three design directions for mySDAtv (Roku)

Date: 2026-10-06 · Mode: /solo (Roku) · Phase 1 of 2: proposal

## Goal

Propose three distinct overall designs for the channel, each with its own design system, shown screen by screen. They are grounded in the metadata the feeds actually carry (`data-brief.md`). The owner picks how to proceed. Phase 2 builds all three on three branches.

## Deliverable (phase 1)

A design canvas: https://claude.ai/artifact/6K9kvGm1nFZhpxBHEstXVm

It contains an overview board plus eight screens per direction, at 1920x1080 (the Roku design plane). Every screen uses real logos, programme titles, times and frame grabs from 5 Oct 2026 at 3:20 PM.

| Direction | Navigation | Opens on | Palette and type |
|---|---|---|---|
| A · Lineup | Rail and grids, evolved from the current build | Television | My red, Manrope + Inter |
| B · Guide | EPG-first; catch-up is the guide scrolled backwards | The guide, at now | Gold on deep navy, Barlow Condensed |
| C · Showcase | Streaming home of rows, plus channel pages | Home | Black, white and blue, Plus Jakarta Sans |

## Phase 2: to be agreed before any code

- **Branch names.** None are created until the owner approves them (iron rule).
- **Base for the branches.** The current redesign is uncommitted on `main`, and `.env`, `.vscode/launch.json` and `out/` must be untracked before anything is committed.
- **Shared foundation all three need, built once:**
  - a schedule service that lazy-loads `getdvr.php` per visible channel and computes now/next;
  - logo-whole tiles;
  - "Live now" fallbacks.
- **Backend asks:**
  - a light now/next endpoint;
  - server-side auth on `getdvr.php`.

## Out of scope for phase 1

- Code changes beyond the two review fixes (C1, C2) from the previous task.
