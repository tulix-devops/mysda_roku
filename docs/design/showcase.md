# C · Showcase

The channel as a streaming service. It is lean-back and image-led: Home opens on what is on now, then rows. Every channel has its own page, where live and its 21 days of recordings sit side by side. Catch-up is grouped by series.

**Status:** chosen first (owner, 2026-10-06): "I like everything about Showcase."

**Navigation: decided (owner, 2026-10-06).** It is the **floating capsule** (option N2), on the left side; the other options are in `showcase/nav-options/`.
- **At rest.** A glass pill at x 32, y 250, 104 px wide: `rgba(24,26,34,0.82)`, a 1 px white ring at 8 %, a deep shadow. It holds five 72 px icon circles: Home, Channels, Radio, Catch-up, Account. The current destination sits on a white 18 % circle with a white glyph; the others are `#A6ABB8`.
- **Focus in the rail.** The capsule widens to 330 px with labels. The focused item is a white circle with dark ink. The page stays put and dims to 50 % behind a left fade.
- **Around it.** The **whole** mySDAtv logo sits above the capsule (144x75 at 12, 40, centred on it), with the clock top-right. Page content starts at x 184.
  - The first build used a 60 px globe crop. The owner rejected it on 2026-10-06 ("logo at navigation is not correct"): it cut through the "SDA" letters. Never crop the logo.
- **Screen titles (owner, 2026-10-06).** Every screen names itself at the content's left edge (x 184, y 46): Plus Jakarta 46/800, with a 24/600 grey subtitle. For example: "Home · Sunday, Oct 5", "Channels · 40 live channels", "Channels / 3ABN", "Radio · 10 stations", "Catch-up · 21 days of every channel", "Account".
- **Players.** The capsule is hidden.

![Showcase, current](showcase/sheet-C-Showcase-v3.jpg)

With the globe mark and no titles: ![Showcase with the capsule](showcase/sheet-C-Showcase-capsule.jpg)

The first version, with the top menu: ![Showcase, top menu](showcase/sheet-C-Showcase.jpg)

## Tokens

| Token | Value | Use |
|---|---|---|
| ground | `#07080C` | Page; near-black, so frame grabs and logos carry the colour |
| surface | `#12141B` | Cards, panels |
| raised | `rgba(255,255,255,0.14)` | Secondary buttons, chips at rest |
| text | `#FFFFFF` | Titles; the focused caption |
| text2 | `#A6ABB8` | Meta, captions at rest, menu at rest |
| accent | `#1E8BFF` | Progress bars, checkmarks (the logo's "tv" blue family) |
| live | `#F0262B` | LIVE pill, live dot (the logo's "my" red) |
| focus fill | `#FFFFFF` with `#07080C` ink | The focused button |

## Type

Plus Jakarta Sans, at weights 500 / 600 / 700 / 800:

| Use | Size and weight |
|---|---|
| Hero title | 72 / 800, tracking -1.5 |
| Page title | 64-76 / 800 |
| Row title | 32 / 800 |
| Card title | 20-23 / 700 |
| Meta | 19-22 / 600 |
| Menu | 27 / 600, and 800 when selected |

Programme titles are shown in Title Case; the feed sends them in upper case.

## Shape and focus

- **Radii.** Cards are 14 px, the big logo plates 16-24 px, and buttons are fully round pills (`h / 2`).
- **Focus.** The focused element lifts: scale 1.06-1.08, a deep shadow, and its caption turns white. There is no border.
  - A focused button becomes a white pill with dark ink.
  - A focused logo card gets a hairline white ring at 40 %.
- **Hero.** A blurred, dimmed frame grab sits behind, with a sharp copy of at most 480x270 on the right. The text sits over a left-to-right scrim.

## Screens (`showcase/`)

1. **Home.** A hero of what is on now, then rows: On now (frame grab plus logo badge plus progress), Channels, In your language, Radio, Catch-up by series.
2. **Channel page.** Logo plate, LIVE line, Watch live / Start over. Then "Today on <channel>" (replays with grabs, the live one, later ones as logo cards) and "Earlier this week".
3. **All channels.** Television and Languages together, with chips: All / Television / Languages / per language. Logo grid six across.
4. **Radio.** A carousel with a big focused station, plus Listen.
5. **Catch-up.** Rows: Earlier today, then one row per series (3ABN Homecoming 57, The Carter Report 30, in 21 days).
6. **Live player.** Minimal: title top-left, a channel strip of logo cards on Left/Right.
7. **Catch-up player.** Seek bar, -10 / play-pause / +10, a next-episode card. There is no trick-play thumbnail (it would need a BIF).
8. **Account.** "Never miss a programme again", the perks, Log in, and the donation QR card.

## Build notes

- **Schedule service.** It lazy-loads `getdvr.php` for the visible channels and computes now/next and "earlier today".
- **Series grouping.** Group by exact title within one channel's 21 days.
