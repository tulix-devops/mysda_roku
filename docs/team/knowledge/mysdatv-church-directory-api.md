---
topic: mysdatv-church-directory-api
summary: mySDAtv church directory feed - raw JSON array {state,city,church,link}, no auth, 237 entries/39 states; server quirks; links are channel pages so Roku shows QR codes instead of playing
platform: roku
applies-to: [mysdatv]
observed-in: [mysdatv]
date: 2026-11-18
source-task: mysdatv/docs/team/tasks/2026-11-18-churches-qr/
---

# Church directory API (mysdatv)

## Fact

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

[[mysdatv-design-showcase-c]], [[mysdatv-feed-derived-design-rules]], [[on-device-qr-encoder-in-brightscript]]
