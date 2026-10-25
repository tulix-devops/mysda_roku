# A · Lineup

This is the rail-and-grid build on the TV today (WPALive engine, "My red" palette), refined. Channels are logo cards shown whole, each with a "now" line and a progress bar. DVR is a channel grid, then days plus recordings.

**Status (owner, 2026-10-06):** liked overall. Two notes to revisit:
- **Background.** "We are not strictly bounded to the gradient colour we have on background": the navy-charcoal radial lamp may change.
- **Navigation.** "Navigation still feels plain": the collapsed icon rail and the open rail need more character.

![Lineup](lineup/sheet-A-Lineup.jpg)

## Tokens (built: `source/SdTheme.brs`, palette `myred`)

| Token | Value | Use |
|---|---|---|
| ground | `#0B1222`, with a lamp `#1F2A44` falling to `#141C30` | Page |
| surface | `#151E33` | Clock plate, cards |
| raised | `#212C47` | Chips |
| focus / accent | `#F0262B` | Rail focus pill (white ink), tile glow, focused title |
| selected | `#FAD35A` | Where the viewer is (rail glyph, selected chip, DVR day) |
| lockup blue | `#0981FB` | The "tv" in the rail lockup |

## Type and shape

- **Type.** Manrope (display: 54 heading, 30 clock) and Inter (body 22-29).
- **Tiles.** Rest at scale 0.92 with the picture dimmed. Focus grows the tile to 1.0 with a soft red glow, and the title turns red. There is no border.
- **Rail.** 120 px collapsed, 440 px open. The page slides by 320 and is never re-laid out.

## Screens (`lineup/`)

1. Television
2. TV Languages (rail open, language chips)
3. Radios
4. Radio playing
5. DVR channels
6. DVR recordings (days plus frame grabs)
7. Live player overlay
8. Account

## Options for the new background and navigation (2026-10-06)

All three are in `lineup/options/`.

![A options](lineup/options/sheet-A-options.jpg)

- **A-α · Ink and ember.**
  - Background: a flat ink ground, `#0A0D16`, with no gradient.
  - Rail: a solid panel with WATCH / LISTEN / ACCOUNT sections. Each glyph sits in a rounded tile that fills red on focus. A "Last watched" card sits at the bottom.
- **A-β · Brand ribbon.**
  - Background: solid navy, `#0B1530`, with a faint globe-mesh watermark.
  - Rail: a tri-colour ribbon (red, gold, blue) down the rail's edge. The focused row is a white pill with a red glyph.
- **A-γ · Dock tiles.**
  - Background: plum-black, `#0D0A12`, lit by the logo's red from below.
  - Rail: icon-over-label tiles, so the closed rail still names every destination. The focused tile is red.

## Decided: α · Ink and ember (owner, 2026-10-06)

"A lineup Alpha is good, expand that design fully with every screen." All eight screens are in `lineup/alpha/`; the first version (radial lamp, plain rail) stays in `lineup/`.

![Lineup α](lineup/alpha/sheet-A-alpha.jpg)

| Token | Value | Use |
|---|---|---|
| ink | `#0A0D16` | Page: flat, no gradient, a soft black vignette at the bottom |
| panel | `#11151F` | Rail (closed 120 / open 440), DVR day panel |
| tile | `#1A2030` | Icon tiles at rest, secondary buttons, chips |
| surface | `#141927` | Clock pill, QR card |
| section | `#6F7891` | WATCH / LISTEN / ACCOUNT labels: 17/700, tracking 2.5 |
| text2 | `#8C95AA` | Meta |
| focus | `#F0262B` | The focused icon tile, with a red glow; the primary button, with a white ring; the tile glow |
| selected | `#FAD35A` | Where you are: the tile tinted gold at 16 %, gold label and dot |

**Rail.**
- It is a solid ink panel in both states.
- **Closed (120 px):** the whole logo at 100x52, the icon tiles (56 px, radius 16), and hairline dividers between the sections.
- **Open (440 px):** the logo at 186x97, the sections with labels, and a "Last watched" card at the bottom.

**Shapes.**
- Cards have a 16 px radius; buttons 20 px; chips and pills are fully round.
- The live player's information sits on a docked ink panel (radius 32), not a gradient wash.

Screens:
1. Television
2. TV Languages (rail open)
3. Radios
4. Radio playing
5. DVR channels
6. DVR recordings (a day panel and frame grabs)
7. Live player
8. Account (rail open)
