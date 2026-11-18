# Plan: Churches destination with QR links (Roku, Showcase)

## Goal
A "Churches" destination in the Showcase capsule nav: the SDA church
directory the Android app shows as its "YT" tab (D:\Tulix\mysda,
origin/feat/local-download-box, `lib/src/ui/pages/churches/churches_page.dart`),
but instead of playing YouTube, each church's link is shown as a QR code to
scan with a phone. Owner, 2026-11-18: a quick prototype, "let's see how it
will go".

## Data
`GET https://livetv.mysdatv.com/api/getfavoritechurch.php`: a raw JSON
array (no envelope) of `{state, city, church, link}`; 237 entries on
2026-11-18, 39 states. Links: 225 YouTube channel / c / user / playlist /
handle URLs, 1 Facebook page; longest 125 bytes. Quirks, from the server:
some states are cut ("NEW", "NORTH", "SOUTH", "FRENCH"); a few names carry
a phone number; entries can repeat with different names.

## Screen (C-style, 1920x1080 plane)
- Title "Churches" + subtitle "<n> churches · scan to watch on your phone".
- Left: the states, a vertical list (state name + count), in title case.
- Middle: the churches of the focused state, a vertical list (name, city).
- Right: a panel for the focused church: its QR code large on a white
  plate, the name, "City, State", "Scan with your phone's camera to watch
  on YouTube" (or "on Facebook"), and the link as text. It follows focus
  (debounced), so no OK is needed; OK does nothing extra.
- Focus: the Showcase rules (lift/brightness, no hairline rings).
- Up/Down move in a list; Right goes states -> churches; Left goes back;
  Left from the states opens the nav; Back as on the other screens.
- Loading: a pulsing skeleton like the channel page; failure: a note.

## QR code
Generated ON the device (a BrightScript QR encoder: byte mode, ECC M,
versions 1-10, mask chosen by the standard penalty), drawn as crisp
rectangles (one per horizontal run of dark modules) with a 4-module quiet
zone. No third-party QR service, no new package dependency.

## Acceptance criteria
1. "Churches" appears in the nav (between Catch-up and Account) and opens
   the screen; the other destinations are unchanged.
2. The list loads from the endpoint; every state and its churches are
   reachable with the D-pad; Back/Left behave as on the other screens.
3. The panel's QR for the focused church decodes (phone scan or a decoder
   run over a capture) to exactly that church's link.
4. No crash on the device console during the walk.

## Files expected
- new `components/sc/screens/ScChurches.{xml,brs}`
- new `source/ScQr.brs` (encoder)
- `components/sc/ScScene.*` (destination), `components/sc/widgets/ScNav.*`
  (item), `components/sc/tasks/ScFeedTask.brs` or a new task (fetch)
- `tools/build-sc-assets.ps1` + `images/png/sc/nav_churches.png` (glyph)

## Out of scope
Playing YouTube on the Roku; search; editing the data's quirks beyond
title case; Android/mobile changes.
