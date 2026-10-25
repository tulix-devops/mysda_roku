# What the items carry: the data brief for the design directions

Measured 2026-10-06 against the live feeds the channel reads. The raw JSON is in `data/`.

## Catalogue: `api/content/{8,9,10}/list`

There are 24 Television channels, 16 Television Languages channels and 10 Radios. The populated fields are:

| Field | Value |
|---|---|
| `title` | Channel name. Examples: "3ABN", "LLBN Arabic", "Novo Tempo Radio". |
| `images.poster` = `banner` = `thumbnail` | One URL per channel. It is the channel logo: 225x160 PNG (aspect 1.41), opaque, mostly on white. Radios are 450x320. |
| `description` | Boilerplate, always "`<title>` - Television Channel". Useless on screen. |
| `live` | Always `true`. |
| `product` | Always "Free", price 0. |
| `sources.primary` | HLS. |
| `dvr_url` | Present on TV and Languages; absent on Radios. |
| `attributes` | Internal ids only: `["200","3abn2_live","1","21"]`. The 21 is probably the DVR retention in days. |

These fields are always empty: `countryId`, `details`, `audiences`, `seasons`, `episode`, `parentId`, and the categories.

## Schedule and DVR: `getdvr.php?id=<stream>` (per channel)

The 3ABN feed held 849 programmes:
- the window runs from 21 days back (2026-09-15) to the end of TODAY (23:00 local), so it covers upcoming programmes too;
- about 40 programmes a day, 8-148 minutes long, 35 minutes on average.

Per programme: `title`, `starttime`, `endtime`, `duration`, `thumb`, `stream`, `downloadurl` and `downloadsize`.
- `title` is UPPER CASE, with 127 distinct titles across the 849 programmes.
- `thumb` is a 320x180 JPEG frame grab of the programme itself.
- `stream` is a catch-up HLS URL.
- `descr` is always empty.

Series repeat a lot: 3ABN HOMECOMING x57, 3ABN TODAY x49, THE CARTER REPORT x32. That makes series grouping and "more episodes" rows possible.

**Costs and limits:**
- About 377 KB per channel. All 40 channels come to about 15 MB of JSON, too heavy to parse at boot on a Roku Express.
- Any design that shows "now on" for every channel at once needs one of two things:
  - **(a) lazy loading** of only the visible channels (about 5-8 at a time), cached for the session; or
  - **(b) a light backend endpoint** for now/next per channel. This is a request to the API owner.

**Security (out of design scope, reported):** `getdvr.php` answers with NO authentication and returns the stream and download URLs. The DVR paywall is enforced only in the app, not on the server.

## Not available

- No EPG endpoint: `api/content/epg/` returns 404.
- No descriptions, genres, ratings, cast or language field.
  - Language can be derived from the title for most channels: Minha TV and Novo Tempo are Portuguese; Nuevo Tiempo, LLBN Latino and Vida Mejor are Spanish; and the LLBN channels name their language (Arabic, Korean, ...).
  - The network can be derived from a title prefix: 3ABN, LLBN, Good News, Better ..., Hope.
- No per-viewer data (favourites, history) on the server. The registry can hold "last watched" and "favourites" locally.

## What follows for design

1. **Logos are the artwork for channels.** Show them WHOLE, on a white or light plate at their own 1.41 aspect. Today's 16:9 crop cuts their edges.
2. **Programme frame grabs are the only photographic imagery.** Use them for "now on", catch-up rows and heroes, always with the channel logo as a badge.
3. **Text is titles and times only.** No layout may depend on a synopsis.
4. **"Now / next" is computable** from the schedule feed, so live channels can show what is on.
5. **Radios have no schedule and no art beyond the logo.** The radio player is a now-playing card.

## Found while building the mockups (2026-10-06, later)

- **Programme titles exist for the 3ABN family only.** That is 3ABN, Proclaim, Kids and Latino (and presumably the other 3ABN feeds). Every other channel measured returns hour-long blocks titled `"Program"`: HopeChannel, Amazing Facts, It Is Written, Good News TV, Novo Tempo, LLBN Arabic and **3ABN Français**. Design rule: show "Live now · 3 PM hour", never "Program".
- **Frame grabs exist only once a programme has aired.** Today's later programmes return a generic grey "play" placeholder image. A few channels (Amazing Facts, Novo Tempo) return the placeholder for some aired hours too.
- **Grabs are taken at the programme's first frame.** Many show network bumpers or announcement cards, not the show. Every frame card carries the channel logo.
- **The logo host sometimes answers 403 to a bare curl.** It served the same files with a user-agent string. Roku sends its own user-agent; worth watching if logos fail on a device.
- **Real series depth (3ABN, aired by 3:20 PM on Oct 5):** 3ABN HOMECOMING 57 recordings, THE CARTER REPORT 30, in 21 days.
