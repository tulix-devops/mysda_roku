---
topic: mysdatv-feed-derived-design-rules
summary: What the mySDAtv feeds really carry (measured 2026-10-06) and the design rules it forces - logos 225x160 shown whole, titles only for the 3ABN family, no descriptions, thumbs only after airing, ~377 KB schedule per channel
platform: roku
applies-to: [mysdatv]
observed-in: [mysdatv]
date: 2026-10-06
source-task: mysdatv/docs/team/tasks/2026-10-06-three-design-directions/
---

# Feed facts that drive every mySDAtv design

Measured 2026-10-06 (5 Oct 2026, about 3:20 PM) against the live feeds. Full brief: `D:\Roku\mysdatv\docs\design\data-brief.md`; raw JSON in the task folder `data/`.

## Fact

**Catalogue (`api/content/{8,9,10}/list`).** 24 Television, 16 Television Languages, 10 Radios. Populated: `title`, `images.poster` = `banner` = `thumbnail` (one URL: the channel LOGO, 225x160 PNG, aspect 1.41, opaque, mostly on white; radios 450x320), `live` (always true), `product` (always Free), `sources.primary` (HLS), `dvr_url` (TV and Languages only, absent on Radios), `attributes` (internal ids; the 21 is probably DVR retention days). `description` is boilerplate ("<title> - Television Channel"). Always empty: countryId, details, audiences, seasons, episode, parentId, categories.

**Schedule/DVR (`getdvr.php?id=<stream>`, per channel).** 3ABN held 849 programmes: 21 days back to the end of TODAY (23:00 local), so upcoming slots are included; about 40 a day, 8-148 min, 35 min average. Per programme: title (UPPER CASE, 127 distinct), starttime, endtime, duration, thumb (320x180 JPEG), stream (catch-up HLS), downloadurl, downloadsize; `descr` always empty. Series repeat: 3ABN Homecoming x57, 3ABN Today x49, The Carter Report x32.

**Found while building the boards.**
- Programme titles exist for the 3ABN family only (3ABN, Proclaim, Kids, Latino). HopeChannel, Amazing Facts, It Is Written, Good News TV, Novo Tempo, LLBN Arabic and 3ABN Francais return hourly blocks titled "Program".
- Frame grabs exist only once a programme has aired; later slots return a generic grey play placeholder, and a few channels (Amazing Facts, Novo Tempo) return it for some aired hours too. Grabs are taken at the first frame, so many are network bumpers or announcement cards.
- The logo host answered 403 to a bare curl and served the same files with a user-agent. Roku sends its own; watch for it if logos fail on a device (unconfirmed on device).
- `api/content/epg/` is 404. No descriptions, genres, ratings, cast or language field; language and network can be derived from the title (Minha TV, Novo Tempo = Portuguese; Nuevo Tiempo, LLBN Latino, Vida Mejor = Spanish; LLBN channels name their language; prefixes 3ABN, LLBN, Good News, Hope). No per-viewer data on the server.
- Cost: about 377 KB per channel, about 15 MB for all 40: too heavy to parse at boot on a Roku Express.
- Security (reported, out of design scope): `getdvr.php` needs NO authentication and returns stream and download URLs, so the DVR paywall is enforced only in the app.

## Why it matters

Designs that assume synopses, per-channel "now" for all 40 channels at once, or thumbnails on future slots cannot be built. Several early boards were cut for exactly these reasons.

## How to apply

1. Logos are the channel artwork. Show them WHOLE at 1.41 on a white or light plate, never cropped to 16:9.
2. Non-3ABN channels show "Live now · 3 PM hour", never "Program". Convert titles from upper case to Title Case for display.
3. Frame grabs: show sharp at 480 px wide at most; blur behind content; always carry the channel logo as a badge; not-yet-aired slots show logo and time, never a thumbnail.
4. Text is titles and times only; no layout may depend on a synopsis.
5. Now/next is computable from the schedule feed, but only load it for the visible channels (about 5-8, cached for the session), or ask the API owner for a light now/next endpoint. Never parse all 40 at boot.
6. Radio has no schedule and no art beyond the logo; the radio player is a now-playing card. Favourites and "last watched" can only live in the registry.
7. Re-measure before a build starts: the numbers are from one day.

## Related

[[mysdatv-design-systems-index]], [[verify-field-population-before-designing]], [[generate-concepts-at-device-scale-on-real-data]], [[measure-source-art-before-designing-the-cell]]
