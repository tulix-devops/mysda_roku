---
topic: mysdatv-church-directory-api
summary: SUPERSEDED endpoint (getfavoritechurch.php raw array, 39 states) - churches now come from the paged public API; still holds why links show as QR codes, not playback
platform: roku
applies-to: [mysdatv]
observed-in: [mysdatv]
date: 2026-11-19
source-task: mysdatv/docs/team/tasks/2026-11-18-churches-qr/; superseded 2026-11-19 by mysdatv/docs/team/tasks/2026-11-19-public-api-churches/
---

# Church directory API (mysdatv)

**Superseded 2026-11-19.** The app no longer calls `getfavoritechurch.php`; the
Churches screen uses the paged `mysda.itulix.com` public API. See
[[mysdatv-public-api-churches-contract]] for the current contract and quirks. The
old-endpoint notes below are kept as history; the QR-not-playback decision (last
bullet) still stands. The new API fixes the truncated state names (42 clean
states) but truncates CITY names instead.

## Fact (old endpoint, 2026-11-18)

- `GET https://livetv.mysdatv.com/api/getfavoritechurch.php`, no auth. Returns a
  RAW JSON array (no envelope) of `{state, city, church, link}`.
- On 2026-11-18: 237 entries, 39 states.
- Server quirks: truncated state names (`NEW`, `NORTH`, `SOUTH`, `FRENCH`), one
  doubled link (Miami Temple), phone numbers inside church names. Clean on the
  client; do not assume well-formed values.
- The links are YouTube CHANNEL pages, not videos. Playing one on Roku would need
  the YouTube channel deep link plus a video lookup (Data API key and quota), so
  the Churches screen shows each link as a QR code instead.

## Why it matters

Someone will ask "why not just play the church?" The answer, with the rejected
alternative, is here.

## How to apply

- Treat the array as untrusted: validate each link before encoding
  ([[qr-payload-needs-link-grade-validation]]).
- Group by `state` after normalising the truncated ones.

## Related

[[mysdatv-public-api-churches-contract]], [[mysdatv-design-showcase-c]], [[mysdatv-feed-derived-design-rules]], [[on-device-qr-encoder-in-brightscript]]
