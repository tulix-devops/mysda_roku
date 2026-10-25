---
topic: mysdatv-design-systems-index
summary: Start here for any mySDAtv Roku UI work - three drawn design systems (C Showcase final, A Lineup alpha final, B Guide G1/G2 pick pending), where the specs and 1920x1080 screens live, and the rules all share
platform: roku
applies-to: [mysdatv]
observed-in: [mysdatv]
date: 2026-10-06
source-task: mysdatv/docs/team/tasks/2026-10-06-three-design-directions/
---

# mySDAtv design systems: index

Filed at the owner's explicit request (2026-10-06): "save these design solutions inside Roku knowledge for the Roku team". Each system will later be built on its own branch.

## Fact

Three complete design systems for the mySDAtv Roku channel were drawn on all 8 screens each, from the measured feed data (see [[mysdatv-feed-derived-design-rules]]), and reviewed as rendered 1920x1080 sheets over six owner rounds.

| System | Idea | Status (owner, 2026-10-06) | Entry |
|---|---|---|---|
| C Showcase | Streaming home of rows, channel pages, catch-up by series | FINAL. "I like everything about Showcase." Chosen first to build. | [[mysdatv-design-showcase-c]] |
| A Lineup | Rail plus channel grids; today's build, refined | FINAL as alpha "Ink and ember". | [[mysdatv-design-lineup-alpha-a]] |
| B Guide | TV guide first; catch-up is the guide scrolled backwards | Shapes final (B-1). Navigation: G1 and G2 both drawn; PICK PENDING. | [[mysdatv-design-guide-b]] |

Where it lives (all under `D:\Roku\mysdatv\docs\design\`):
- `README.md` is the index; `showcase.md`, `lineup.md`, `guide.md` are the specs; `data-brief.md` is the feed measurement.
- Final screens, one folder each, 1920x1080 JPEGs plus a `sheet-*` contact sheet:
  - `showcase/` (C1-C8), sheet `sheet-C-Showcase-v3.jpg`
  - `lineup/alpha/` (AX1-AX8), sheet `sheet-A-alpha.jpg`
  - `guide/g1/` (BG1-1..8) and `guide/g2/` (BG2-1..8)
- Everything else in those folders (`options/`, `nav-options/`, `rethink/`, the first-version JPEGs at the top of `lineup/` and `guide/`) is history for reference.
- Board sources: `source/*.dc.html` plus `canvas.json`. Re-render locally by copying `source/render-support.js` as `support.js`, pointing `/_blob/<id>` at local assets, and shooting headless Chrome at `--window-size=1920,1080`; asset ids are in the task folder `docs/team/tasks/2026-10-06-three-design-directions/`.

## Why it matters

The three share a colour source (the logo: "my" red `#F0262B`, "SDA" gold `#FAD35A`, "tv" blue) and the same data limits, but differ in structure. Picking up one without reading its spec re-opens decisions the owner already made (rejected: top tab bars, a globe crop of the logo, eight guide menu shapes).

## How to apply

1. Read the system's own entry first, then its `docs/design/<system>.md`, then look at the final folder screens.
2. Building: C is first. A reuses Phase 1 (the WPALive port, see [[mysdatv-wpalive-port-pattern]]) as its code base. B waits on the G1/G2 pick; do not start B navigation until the owner chooses.
3. Rules every system follows: logos whole at 1.41 on a light plate; no "Program" titles; no descriptions; frame grabs at most 480 px wide and always with the channel logo; schedule loaded lazily. Details in [[mysdatv-feed-derived-design-rules]].
4. Update the status column here and in the system entry when the owner decides (B pick, build order).

## Related

[[mysdatv-design-showcase-c]], [[mysdatv-design-lineup-alpha-a]], [[mysdatv-design-guide-b]], [[mysdatv-feed-derived-design-rules]], [[mysdatv-wpalive-port-pattern]], [[generate-concepts-at-device-scale-on-real-data]], [[guide-first-tv-nav-restructure-not-reskin]]
