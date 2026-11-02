# mySDAtv "C · Showcase": adoption guide for Android TV and Android mobile (Flutter)

Written 2026-11-03 by the Roku session, at the request of the Flutter session (D:\Tulix\mysda).

The Roku build is on branch `design/showcase` of D:\Roku\mysdatv, at commit d17be26. Everything below is what actually ships and was verified on a Roku Express (720p panel, firmware 15.3.4).

**Where this guide departs from the original boards, the owner decided it on the device.** Those owner rounds ran 2026-10-28 to 10-29. Follow this guide, not the boards, on those points.

All coordinates are on a **1920×1080 design plane**. Scale them for Android TV, where Flutter's logical 960×540 means everything ÷ 2. For mobile, re-lay the layout (see §10).

---

## 1. Design direction: where it is recorded

| What | Path |
|---|---|
| Spec (tokens, type, focus, screens) | `D:\Roku\mysdatv\docs\design\showcase.md` |
| The 8 approved boards, as JPEG | `D:\Roku\mysdatv\docs\design\mysda-showcase\C1-Home.jpg` … `C8-Account.jpg`, and `sheet-C-Showcase-v3.jpg` |
| Board sources (exact px, HTML) | `D:\Roku\mysdatv\docs\design\source\C1-Home.dc.html` … `C8-Account.dc.html`; `N2a/N2b-Capsule*.dc.html` for the nav |
| Feed facts that shape the design | `D:\Roku\mysdatv\docs\design\data-brief.md` and `docs\team\knowledge\mysdatv-feed-derived-design-rules.md` |
| App knowledge entry | `D:\Roku\mysdatv\docs\team\knowledge\mysdatv-design-showcase-c.md` |
| Device screenshots (current build) | `D:\Roku\mysdatv\docs\team\tasks\2026-10-25-showcase-build\screenshots\`: newest are r10-*, r9-*, r7-*; contact sheet `sheet-device-round1.jpg` |
| The build's report and review | the same task folder: `report-roku.md`, `review.md` |

**The idea.** The channel as a streaming service. It is lean-back and image-led: Home opens on what is on now, then rows. Every channel has its own page, where live and its 21 days of recordings sit side by side. Catch-up is grouped by series.

**Navigation.** A floating "capsule" on the left. The **whole** logo sits above it, and every screen names itself with a title.

---

## 2. Colour tokens

The source is `source/ScTheme.brs`. Values are RGBA.

| Token | Value | Use |
|---|---|---|
| ground | `#07080C` | Page background. Near-black, so frame grabs and logos carry the colour. |
| surface | `#12141B` | Card plate behind a frame grab; dialog panel |
| surface2 | `#1B1E27` | A "later" (not-yet-aired) slot's plate |
| raised | `#FFFFFF` at 14 % (`0x24`) | Secondary buttons, chips at rest |
| track | `#FFFFFF` at 20 % | Progress track |
| capsule | `rgba(24,26,34,0.82)` | Nav capsule fill |
| capsuleRing | `#FFFFFF` at 8 % | 1 px ring round the capsule |
| navSel | `#FFFFFF` at 18 % | The current destination's circle in the nav |
| tag | `#07080C` at 80 % | Tag pill over a picture (REPLAY, 28 MIN) |
| text | `#FFFFFF` | Titles, the focused caption |
| text1 | `#DADDE5` | A caption at rest (row not focused) |
| text2 | `#A6ABB8` | Meta, captions in a focused row but not focused, nav at rest |
| text3 | `#6E7383` | Hints, placeholders |
| accent | `#1E8BFF` | Progress fill, check marks (the logo's "tv" blue) |
| live | `#F0262B` | LIVE / ON NOW pill and dot (the logo's "my" red) |
| focus | `#FFFFFF` fill with `#07080C` ink | The focused button or nav item |
| shadow | black, peak alpha 0.70–0.80, about 36 px blur, offset y +14…+30 | Lifted card, focused pill, capsule, hero preview |

### Gradients and scrims

- **Hero scrim.** The ground at 20 % over the whole hero. A bottom fade to the ground over 660 px. A left fade, ground 85 % → 0, over 1200 px.
- **Left page fade.** Ground 70 % → 0 over 220 px, always on. Cards scrolled past slide under it and under the capsule.
- **Nav open.** A full-screen ground layer animates 0 → 50 %, plus a left fade 85 % → 0 over 900 px.
- **Channel "tone" cards** (owner, 2026-10-28: "the colour on a background, as we have on other Roku apps").
  - A diagonal gradient (135°) in the channel's own brand hue: top-left `hsl(h, 62 %, 36 %)` → bottom-right `hsl(h+12, 70 %, 13 %)`.
  - The hue h comes from the logo; see §6 and §9 for the table.
  - Fallback hue, when the logo has no clear colour: `h = fold(title chars, h = (31*h + charCode) mod 360)`, the same hash the WPALive and GreaterLove apps use.

---

## 3. Typography

**Plus Jakarta Sans.** Static TTFs at 500 / 600 / 700 / 800, under OFL. The files are in `D:\Roku\mysdatv\images\fonts\PlusJakartaSans-{Medium,SemiBold,Bold,ExtraBold}.ttf` with `OFL-PlusJakartaSans.txt`. On Flutter, bundle them, or use `google_fonts` with family "Plus Jakarta Sans". **No Cyrillic glyphs:** the Russian chip reads "Russian".

| Role | Size / weight (on 1920 plane) |
|---|---|
| Screen title | 46 / 800, at x 184, y 46; subtitle 24 / 600 text2, 18 px after it |
| Hero title (Home) | 72 / 800 |
| Channel page name | 72 / 800 |
| Radio station name | 64 / 800 |
| Catch-up player title | 60 / 800; live player title 46 / 800 |
| Account heading | 76 / 800, 2 lines |
| Row title | 32 / 800 |
| Card title (frame cards) | 23 / 700; meta 19 / 600 text2 |
| Card title (logo cards) | 19 / 600, centred |
| Hero meta (time, "35 min left") | 24 / 600 text2 |
| Buttons | 26 / 700 (25 on the channel page and Radio) |
| Chips | 22 / 700 |
| Nav labels | 27 / 700 (one weight for every state) |
| Tags | 15 / 800, tracking +1 |
| Clock (top-right) | 27 / 600 text2 |

**Rule (owner, 2026-10-28).** Focus NEVER changes a text's weight or scales its glyphs. "Watch live" looked stretched when the focused pill scaled 1.06 and switched to ExtraBold. Text is drawn 1:1 in one face; focus changes only colours, the plate and the shadow.

Programme titles arrive in UPPER CASE; show them in Title Case:
- Words with a digit or `&` stay as they are (3ABN, Q&A).
- TV, LLBN, USA stay upper case.
- Small joining words go lower case except first.
- Show `"Program"` as "" (see §8).

---

## 4. Screens and layout

There is no search and no EPG grid in Showcase; the guide is Direction B, not built. The splash is the manifest image only (§7).

### Nav: the floating capsule (all browse screens; hidden in players and sign-in)

- **Position and items.** x 32, y 250, 104 wide, radius 52. Five 72 px circles, 12 px apart, 16 px padding: **Home, Channels, Radio, Catch-up, Account**.
- **Glyphs.** 36 px, stroked on a 40-unit grid at stroke 3. PNGs are in `images/png/sc/nav_*.png`; the SVG paths are in `C1-Home.dc.html`.
- **At rest.** The current destination sits on a navSel circle (white 18 %) with a white glyph; the others are text2 glyphs with no circle.
- **Open (focus in the nav).**
  - The capsule widens 104 → **330**, 0.24 s out-cubic; closing takes 0.18 s.
  - Labels fade in at x 90.
  - The **focused** item is a white circle with a dark glyph; the current item keeps its 18 % circle.
  - The page does not move: it dims (§2).
- **Above the capsule:** the whole mySDAtv logo, 144×75 at (12, 40). It must never be cropped; the owner rejected a globe-only crop.
- **Top-right:** the clock.

### Home (C1)

- **Hero, top 0–594.**
  - **Backdrop.** The on-now frame grab, blurred. On Roku it is decoded at 48×27 and drawn 1920×640 at 55 %.
  - **Info block** at (184, 184):
    - ● ON NOW pill (live red, height 36) plus the channel name (24 / 700 text1);
    - title 72 / 800;
    - time row: "3:00 – 3:55 PM", a 260×6 progress bar, "35 min left";
    - buttons at +206: **Watch live** (play glyph), **Start over**, **<Channel> channel**.
  - **Sharp preview** on the right: 480×270, radius 18, at x 1344, y 170. It carries the logo badge (84×60 white plate) bottom-left.
    - With no grab, it shows the channel's tone with the logo panel instead (§6).
  - **The hero follows focus.** It changes to the channel of the card focused in On now / Channels / In your language.
- **Rows** (row label 32 / 800 at y 598; cards below):
  1. **On now:** frame cards 384×216 (first 10 TV channels);
  2. **Channels:** tone logo cards 240×170;
  3. **In your language:** tone logo cards 240×170;
  4. **Radio:** tone logo cards 240×170;
  5. **Catch-up by series:** frame cards 340×191 (3ABN's series, "57 recordings · latest …").
- **Focus zones:** hero buttons ↔ rows (Up / Down).

### Channel page (C2), opened from a channel card or "X channel"

- **Backdrop.** The blurred on-now grab, 1920×520 at 45 %.
- **Logo plate** 360×256, radius 22, at (184, 130).
- **Text to its right:**
  - name 72 / 800 at x 588;
  - "● LIVE" (red, 25 / 800) plus "Programme · until 3:55 PM";
  - "Television · English · 21 days of recordings" (22 / 600 text2).
- **Buttons:** Watch live, Start over.
- **"Today on <channel>"** (340×191 cards), in time order and opening on the live one:
  - REPLAY tag: aired, shows its grab;
  - ● LIVE tag (red): on now;
  - LATER tag: dark plate, logo at 55 %.
- **"Earlier this week."** Caption inside the card over a bottom fade, newest first, one card per title.
- **Title:** "Channels / <name>".

### Channels (C3)

- **Chips** at y 150: All 40, Television 24, Languages 16, Português 3, Español 6, Français 1, Russian 1, Romanian 1, Asia 4. Moving along the chips filters the grid at once.
- **Grid:** 6 columns of tone logo cards 252×179, gaps 24 / 30, captions centred.
- **Chip states:**
  - the selected chip is a white pill with dark ink;
  - it grows 4 px with a shadow only while the chips hold focus;
  - the others are raised 14 %.

### Radio (C4)

- **Carousel**, centred at y 460: middle 600×426, neighbours 380×270, outer 254×180, 40 px apart.
  - Brightness 1.0 / 0.6 / 0.35.
  - Seven slots at positions −3…+3 glide one position per Left / Right, 0.32 s out-cubic. Stations wrap.
- **Below:** "● LIVE RADIO · <LANGUAGE|MUSIC>" (20 / 800 red, tracking 2), the name 64 / 800, a **Listen** pill (white), and the hint "Left / Right for the other 9 stations".
- OK plays.

### Catch-up (C5)

- **"Earlier today · every channel, newest first,"** then one row per series: "3ABN Homecoming · 57 recordings in the last 21 days".
- **Cards** 318×179: grab, logo badge top-left, duration tag "28 MIN" bottom-right, one caption line "Today · 3:00 AM".

### Live player (C6)

- **Full-screen video.** Top-left: ● LIVE, channel 46 / 800, "Programme · until 3:55 PM" or "Live now · 3 PM hour". Clock top-right.
- **Channel strip** bottom, 80 px from the edge:
  - logo cards 200×142, at 72 % brightness;
  - the highlighted one is 288×204 with a shadow and caption "Watching · live" or that channel's programme.
- **Keys:** Left / Right move; OK switches channel, or on the one playing opens its channel page.
- **Hint:** "Left / Right to switch · OK for the channel page".

### Catch-up player (C7)

- **Text above the bar:** logo badge plus "3ABN · Sat, Oct 4 · 5:00 PM · recording"; title 60 / 800.
- **Seek bar** 8 px, accent fill, 26 px white knob, times either side.
- **Controls:** −10 (76 circle) / play-pause (92 circle) / +10 (76).
- **Next episode card** right: 420 wide, thumb 160×90, "NEXT EPISODE".
- **Keys:** Left / Right move between controls; OK presses. Rewind / Fast-forward are ±10 s. Play toggles.
- **Resume** from a stored position over 30 s. **End** at position ≥ duration − 1, then the next episode.

### Radio player

The station's tone / plate card, centred, with the name. Left / Right change station.

### Account (C8)

- **Signed out.** "Never miss a programme again", the body text, three ✓ perks (accent blue checks), then **Log in** / **Not now**.
- **Signed in.** "You're logged in", the email, the catch-up status, then **Watch catch-up** / **Log out**.
- **Always.** A "Give instead" card (560×244, surface 92 %) with the donation QR 200×200.
- **Background.** A 3×3 wall of today's grabs, rotated −8° at 32 %, faded out to the left.

### Sign-in (full screen)

- **Layout:** Email and Password fields in one row (72 high, radius 35), the **Log in** pill, and the full system keyboard below.
- **Focus:** a focused field is a white plate with dark ink.
- **Messages:**
  - "Logging in…";
  - "That email address and password don't match…";
  - "This Roku can't reach mySDAtv…".

### Dialogs

A panel 860 wide, radius 22, surface colour, over the ground at 78 %. Title 40 / 800, body 24 / 600 text2, up to three pills.
- **Exit:** "Leave mySDAtv?" with Exit / Cancel.
- **Catch-up gate:** "Log in to watch recordings" with Log in / Not now.
- **No subscription:** "Catch-up isn't on this account yet" with Account / Not now.

---

## 5. Focus model

- **Exactly ONE focus indicator per screen.**
- **Buttons and pills.**
  - Rest: white 14 %, white ink.
  - Focused: a white fill with dark ink, the plate grows **4 px** round the text, and a soft shadow.
  - **Never** scale the text.
- **Cards.** Every card keeps its size. In the row or grid that holds focus:
  - **The focused card** is at full brightness, lifted **+5 %** (anchored bottom-left; logo cards bottom-centre), with a shadow (about 36 px blur, +16 y) and a white caption.
  - **The other cards** step down to **58 % brightness** with a text2 caption.
  - **Rows that do not hold focus** show at full brightness with a text1 caption.
  - Both the lift and the dimming follow the list's scroll position (focusPercent), so they glide.
  - **No border and no ring.** The owner rejected the hairline ring ("weird lines at the edges").
- **Dimming technique (important).** Darken every layer's colour, for example a ColorFilter or modulate per layer.
  - **Not** opacity on a group: each child fades apart and draws grey frames round logos.
  - **Not** a dark overlay: its anti-aliased edge darkens the card's edge only half, which leaves a light seam.
  - Both were seen on device and rejected (2026-10-28/29).
- **Leaving room for the lift.** Give 12 px of headroom above each card so a lifted card's top corners are never clipped by its row.
- **The banner follows focus.** Home's hero changes to the focused channel card's channel (On now, Channels, In your language). Series and radio cards leave it as is.
- **Navigation rules.**
  - **Left** at a page's left edge opens the nav.
  - **Back** from a page opens the nav.
  - **Back** in the nav on any screen but Home goes Home; Back in the nav on Home asks "Leave mySDAtv?".
  - **Back** from the channel page returns to the screen that opened it.
  - **Right or OK** in the nav enters the chosen destination. Up / Down in the nav only move the highlight; the page does not change until OK.
  - **Down / Up** move between a screen's zones (hero buttons ↔ rows, chips ↔ grid). Up from the first row returns to the buttons.
- **Players.** The chrome hides after 5 s. The first key while it is hidden only shows it, except Back, which closes.

---

## 6. Card specs

| Card | Size (art) | Radius | Content |
|---|---|---|---|
| On now (frame) | 384×216 (16:9) | 14 | Grab; logo badge 72×51 white plate radius 7 at (12, 12); progress 5 px accent at the bottom; title 23 / 700, meta "3ABN Proclaim · until 3:57" or "Live now · 3 PM hour" |
| Today / series (frame) | 340×191 | 14 | Grab; tag top-right (REPLAY / ● LIVE / LATER) |
| Catch-up (frame) | 318×179 | 14 | Grab; badge; duration tag bottom-right |
| Channel / language / radio (tone logo) | 240×170 (1.41); grid 252×179 | 14 | Gradient in the brand hue; logo panel 62 % of width at 1.41, centred (see below); caption centred under |
| Hero preview | 480×270 | 18 | Grab, or tone + logo panel |
| Radio carousel | 600×426 / 380×270 / 254×180 | 22 | White plate, logo at 88 % |
| Channel page logo | 360×256 | 22 | Logo edge to edge |

Gaps are 24 px between cards in a row. Row height is the card plus caption (about 76 px for frame cards, about 46 for logo cards) plus a 96 px gap that holds the next row's 43 px label band.

**Logos (data rule).** Logos are 225×160 PNGs, mostly on white. Show them **whole**, never cropped to 16:9.

**The logo panel on a tone card.** It is a rounded plate painted **the logo's own border colour**: white for logos on white, near-black for SUM TV, and so on. The logo sits 6 px inside it, fitted (contain), with the logo's own aspect.
- Plate and logo edge match, so there is no seam and no rim.
- **Never** draw a dark logo on a white plate: it reads as a white outline.
- **Never** paint corner masks of one colour over a gradient: they notch it.

**No-picture fallbacks:**
- **A channel with no frame grab yet** (a programme's first minutes, up to 20+ min): show the **previous** programme's grab. If there is none, show the logo full-strength on a white plate in the middle of a dark card.
- **A slot not yet aired:** dark plate (surface2), logo at 55 %, LATER tag.
- **There are no monograms in Showcase.** A logo always exists in the feed, and the tone colour is the brand hue or the title hash.

---

## 7. Splash and animations

- **Splash.** The manifest splash image (the logo on black). The app enters as soon as the TV catalogue lands, with a watchdog at 12 s. There is no animated splash.
  - Measured on device: `AppLaunchComplete` at about 2.2 s.
- **Animation timings:**

  | What | Duration | Easing / notes |
  |---|---|---|
  | Nav open / close | 0.24 s / 0.18 s | out-cubic; width, label fade, page dim |
  | Radio carousel glide | 0.32 s | out-cubic; translation, scale, colour |
  | Card lift / dim | follows the list's own focus animation | no extra timer |
  | Player chrome hide | after 5 s | |
  | Clock / "min left" refresh | every 30 s | |
  | Schedule refresh | reused for 20 min | |

---

## 8. Data and API

**Same backend as the Flutter app.** `packages/commons/lib/http/api_list.dart` uses `_url = 'https://sda.wchupload.tulix.net/api'`, and the Roku uses the same host.

| Purpose | Request | Notes |
|---|---|---|
| Catalogue | `GET {api}/content/8/list?limit=200` (TV, 24), `/9/` (Languages, 16), `/10/` (Radio, 10) | Returns **206**. The stream URL is `sources.primary` (HLS); the logo is `images.banner`; there is `dvr_url` (not on radios), and the stream id is the `id=` query of `dvr_url`. `description` is boilerplate: don't show it. |
| Schedule / recordings | `GET {dvr_url}` = `https://livetv.mysdatv.com/api/getdvr.php?id=<stream>` | About 377 KB per channel and 21 days. Items: `id` (start epoch), `starttime`/`endtime` (ISO with offset), `duration`, `title` (UPPER), `thumb` (320×180), `stream` (catch-up HLS). **The order differs per channel:** sort by start yourself. **No auth** (a security finding, reported). |
| Sign-in | `POST {api}/login` `{"email","password","deviceInfo":"rokuTV"}` | Success is `body.statusCode == 200`; `data.accessToken`, `data.sessionToken`, `data.customer{email,name,lastname,id}`. |
| Catch-up access | `POST {api}/payments/customer/check-purchase` `{"collectionId":null,"productId":15}` | Headers: `Authorization: Bearer <accessToken>`, `X-Session-Token: <sessionToken>` and `X-Session-Token: <accessToken>` (the legacy sent both). Results: 200 with `data:true` or `statusCode:200` means yes; 401/403 with "cannot access"/"not purchased" means no, otherwise the session has expired; 404 means no. |

**Who may watch what.** Live and radio are free. A recording needs a signed-in viewer with check-purchase "yes".

**Feed rules the UI depends on:**
- **Titles.** Only the 3ABN family publishes programme titles. Other channels return hourly `"Program"` blocks, so show "Live now · 3 PM hour", never "Program".
- **Grabs.** A grab exists only once a programme has run for a while; it is still the placeholder 22 min in.
  - Until then, **and for some channels always** (Minha TV), the grab URL serves one shared grey "play" placeholder: **6542 bytes**, the same file for every channel.
  - The Roku probes it by size: it checks the current and previous programme per schedule load, plus one well-aired grab per channel. If that one is the placeholder, the channel "has no grabs" and the logo is used.
- **Gaps.** Close gaps of 10 min or less between programmes onto the earlier one (3ABN runs 11:00–11:28:30, then 11:30). Otherwise "on now" is empty for a minute.
- **Language.** There is no language field: derive it from the title.
  - Português: Minha, Terceiro Anjo, Novo Tempo.
  - Español: Latino, Mas TV, Nuevo Tiempo, Vida Mejor.
  - Français: franc…
  - Russian: Russia.
  - Romanian: Romanian.
  - Asia: Arabic, Korean, Chinese, South Asian.
  - Everything else is English.

**Caching on Roku.**
- The catalogue is read once per launch.
- Schedules are lazy: only the channels on screen, at most 2 at a time, reused for 20 min, never blocking startup. Each one is parsed off the UI thread and reduced to:
  - today;
  - 6 days of the week, one per title;
  - the top 8 series (3 or more recordings), 20 episodes each.
- The resume position is stored by recording id.

---

## 9. Assets to copy

All are under `D:\Roku\mysdatv\images\`.

- **Fonts:** `fonts/PlusJakartaSans-{Medium,SemiBold,Bold,ExtraBold}.ttf` and `fonts/OFL-PlusJakartaSans.txt`.
- **Logo lockup (whole, never crop):** `png/sc/logo_144.png` (144×75). The full-resolution source is `png/mysdatv_logo.png`.
- **Nav glyphs** (white, tint in code, 36 px): `png/sc/nav_home.png`, `nav_channels.png`, `nav_radio.png`, `nav_catchup.png`, `nav_account.png`.
  - On Flutter, redraw them as vectors from the SVG paths in `docs/design/source/C1-Home.dc.html`.
- **Other glyphs:** `png/sc/play.png`, `pause.png`, `check.png`, `restart.png`.
- **Donation QR:** `png/donation.PNG`.
- **Not needed on Flutter:** the 9-patch shapes (`png/sc/r*.9.png`, `caps*`, `shadow14*`) are Roku workarounds. Flutter's `BorderRadius`, `BoxShadow` and `LinearGradient` replace them.
- **Brand colour table:**
  - `D:\Roku\mysdatv\source\ScBrand.brs` holds `[hue, logoOnWhite, logoBorderColour]` per catalogue id, for 50 channels.
  - The generator is `tools/build-sc-brand.ps1`. It samples each logo's dominant saturated hue, whether its outer ring is white, and the mean border colour.
  - Port the table to a Dart map, or compute it at runtime with `palette_generator`, but keep the same rules.

---

## 10. Do differently, and pitfalls

1. **Dim by colour, never by opacity or overlay** (§5). Flutter's `Opacity` on a card `Stack` produces the same grey-frame effect over white logos; use a `ColorFiltered` modulate on the whole card instead.
2. **Never scale or re-weight focused text** (§3). Flutter's `AnimatedScale` on a button scales the glyphs; grow the container instead.
3. **Leave headroom for lifted cards.** A `ListView` clips its children; pad 12 px top, or use `clipBehavior: Clip.none`.
4. **Logos:** contain, never cover; put them on a plate in their own border colour; no white rims.
5. **The feed order of getdvr differs per channel:** sort it. Close gaps of 10 min or less.
6. **Placeholder grabs:** treat a 6542-byte grab as "no picture". Fall back to the previous programme's grab, then to the logo.
7. **Only 3ABN titles are real:** never show "Program".
8. **Do not parse all 40 schedules at start.** About 15 MB: load lazily for what is on screen.
9. **For mobile, keep the system and re-flow the layout:**
   - the capsule becomes a bottom bar with the same five destinations;
   - the hero becomes full width, 16:9, with the title under it;
   - rows stay horizontal;
   - the Channels grid goes 2–3 columns;
   - Radio becomes a horizontal pager.

   Tokens, type ramp (scaled about × 0.6), cards and the tone design stay the same.
10. **Unbuilt on Roku, decide fresh:** search, an EPG grid (Direction B), favourites / last watched.
11. **Not yet device-verified on Roku:** the signed-in flows (log in, catch-up playback, resume, next episode, log out). They need the owner's credentials. The code follows the legacy wire format exactly.
