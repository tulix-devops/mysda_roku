---
topic: mysdatv-design-showcase-c
summary: mySDAtv design C Showcase (FINAL) - spec, tokens, 8 screens; BUILT on branch design/showcase (Sc components, device round 1 done signed-out, signed-in flows pending), plus board deviations
platform: roku
applies-to: [mysdatv]
observed-in: [mysdatv]
date: 2026-10-25
source-task: mysdatv/docs/team/tasks/2026-10-06-three-design-directions/; built 2026-10-25 in mysdatv/docs/team/tasks/2026-10-25-showcase-build/
---

# Design C: Showcase

Spec: `D:\Roku\mysdatv\docs\design\showcase.md`. Final screens: `D:\Roku\mysdatv\docs\design\showcase\` (C1-C8, 1920x1080), sheet `sheet-C-Showcase-v3.jpg`. Index: [[mysdatv-design-systems-index]].

## Fact

**Idea.** The channel as a streaming service: lean-back and image-led. Home opens on what is on now, then rows. Every channel has its own page with live and its 21 days of recordings side by side. Catch-up is grouped by series.

**Status.** Chosen first (owner, 2026-10-06): "I like everything about Showcase." Navigation decided the same day: the floating capsule (option N2); the other options stay in `showcase/nav-options/`. The owner rejected the first capsule build, which used a 60 px globe crop of the logo: "logo at navigation is not correct" (it cut through the "SDA" letters). Screen titles were also an owner request. First system to build.

**Tokens.**
- ground `#07080C` (near-black so frame grabs and logos carry the colour); surface `#12141B`; raised `rgba(255,255,255,0.14)`
- text `#FFFFFF`; text2 `#A6ABB8`
- accent blue `#1E8BFF` (progress bars, checkmarks); live red `#F0262B` (LIVE pill, dot)
- focus fill `#FFFFFF` with `#07080C` ink

**Type.** Plus Jakarta Sans 500/600/700/800. Hero 72/800 (tracking -1.5); page title 64-76/800; row title 32/800; card title 20-23/700; meta 19-22/600; menu 27/600 (800 when selected). Programme titles are shown in Title Case because the feed sends upper case.

**Shape and focus.** Cards radius 14; logo plates 16-24; buttons fully round pills (h/2). Focus lifts the element (scale 1.06-1.08, deep shadow, caption turns white). NO border. A focused button becomes a white pill with dark ink; a focused logo card gets a hairline white ring at 40 %. Hero: blurred dimmed frame grab behind, a sharp copy at most 480x270 on the right, text over a left-to-right scrim.

**Navigation (floating capsule, left).**
- At rest: glass pill at x 32, y 250, 104 px wide, `rgba(24,26,34,0.82)`, 1 px white ring at 8 %, deep shadow. Five 72 px icon circles: Home, Channels, Radio, Catch-up, Account. Current destination is a white 18 % circle with a white glyph; the others `#A6ABB8`.
- On focus the capsule widens to 330 px with labels; the focused item is a white circle with dark ink; the page stays put and dims to 50 % behind a left fade.
- The WHOLE mySDAtv logo sits above the capsule (144x75 at 12, 40, centred on it); clock top-right; page content starts at x 184. Players hide the capsule.
- Screen titles at x 184, y 46, Plus Jakarta 46/800 with a 24/600 grey subtitle carrying counts: "Home · Sunday, Oct 5", "Channels · 40 live channels", "Channels / 3ABN", "Radio · 10 stations", "Catch-up · 21 days of every channel", "Account".

**The 8 screens.**
1. Home: hero of what is on now, then rows On now (frame grab + logo badge + progress), Channels, In your language, Radio, Catch-up by series.
2. Channel page: logo plate, LIVE line, Watch live / Start over; "Today on <channel>" (replays with grabs, the live one, later ones as logo cards), "Earlier this week".
3. All channels: Television and Languages together; chips All / Television / Languages / per language; logo grid six across.
4. Radio: carousel with a big focused station plus Listen.
5. Catch-up: Earlier today, then one row per series (3ABN Homecoming 57, The Carter Report 30 in 21 days).
6. Live player: minimal; title top-left, channel strip of logo cards on Left/Right.
7. Catch-up player: seek bar, -10 / play-pause / +10, next-episode card. No trick-play thumbnail (it would need a BIF).
8. Account: "Never miss a programme again", perks, Log in, donation QR card.

## Build status (2026-10-25): BUILT on branch `design/showcase`

Owner-approved branch from `main` @ 20d8958; `main` still has the legacy front end. Commits: `078820a` (new Sc shell, eight screens, players, data layer), `e03912d` (legacy screens and unreachable art removed), `0ab8b78` (device round 1 fixes and review findings), `2a19b20` (device round 1 report, review outcome, contact sheet). Package 3.55 MB to 0.41 MB (86 files). Task folder: `docs/team/tasks/2026-10-25-showcase-build/`.

Verified on the Roku Express (fw 15.3.4, 720p) with ECP captures: boot (206 on all three catalogues, AppLaunchComplete once at 2153 ms), all screens, hero/rows and chips/grid focus, capsule open on Left/Back, live and radio playback proven by `/query/media-player`, launch and roInput deep links, the signed-out catch-up gate. NOT yet verified: every signed-in flow (log in, check-purchase, the catch-up player with seek, resume, next episode, log out), error states when a stream fails, the Nuevo Tiempo stall, long-session memory. Those wait for the owner to type credentials on the device.

**Component map (prefix `Sc`).**
- Shell `components/sc/ScScene.*`: owns the screens, the one Video node, dialog, sign-in, clock, 12 s boot watchdog, lazy schedule queue (2 at a time, 20-min reuse, never in the boot gate), deep links (shell reset first). Built like wpa_live_roku's WpScene ([[mysdatv-wpalive-port-pattern]]); requests travel as m.global fields.
- `ScPlayer.*`: live (C6 strip), radio card, catch-up (C7). Resume position in registry `positions` keyed by recording id; end = `position >= duration - 1`.
- Screens `components/sc/screens/`: ScHome (C1), ScChannel (C2), ScChannels (C3), ScRadio (C4), ScCatchup (C5), ScAccount (C8), ScSignIn.
- Widgets `components/sc/widgets/`: ScNav (capsule), ScCard (frame / later / logo / station), ScPill, ScDialog.
- Tasks `components/sc/tasks/`: ScFeedTask (lists 8/9/10), ScScheduleTask (getdvr reduced), ScAuthTask (signIn / checkAccess / signOut).
- `source/`: ScTheme (tokens, 9-patch shapes, `_hd` copies), ScGlobals, ScTime, ScData, ScNet, ScUi, ScMetrics (generated by `tools/build-sc-metrics.ps1`). Assets by `tools/build-sc-assets.ps1`.
- Plumbing kept on the wire, so a viewer signed in on the old build stays signed in (same `AUTH/authData` record).

**Deviations from the boards** (owner has not yet looked on device):
1. Catch-up row titles join title and subtitle in one RowList label ("3ABN Homecoming · 57 recordings in the last 21 days"): a RowList label has one font.
2. Radio: no radial glow behind the carousel (flat ground). The carousel wraps, so Left never reaches the capsule; Back opens it.
3. Live strip: OK on another channel switches to it; OK on the playing one opens its page; the hint text says which.
4. The Russian chip reads "Russian": Plus Jakarta Sans has no Cyrillic glyphs (checked in the TTF cmap). Fonts are the static 500/600/700/800 instances.
5. Account: the wall of grabs uses whatever schedules are loaded; empty if none.
6. Channel page title is "Channels / <name>" even when opened from Home.
7. Focus is not the drawn "lift 1.06-1.08 only": the rest of the focused row steps back to 94 % dimmed and the focused card lifts to 104 % with a shadow, because a plain lift read as no focus on the 720p panel ([[focus-border-abandoned-for-size-and-brightness]]).
8. Hero "blur": the grab is decoded at 48x27 and drawn 1920 wide at 55 % under fades (SceneGraph has no blur).

**Open follow-ups from review:** an unbounded FIFO schedule queue with no failure cache (moving along Home rows queues a 377 KB fetch per channel passed), `AppLaunchComplete` fires on the TV feed even on a deep-link launch, dead fields (`scFocusTick`, `navOpen`, `scStartAt`, `restart.png`), and the live tag on a channel page going stale between minute ticks.

**Device-measured layout facts** (also in the portfolio): RowList reserves a label band above each row ([[rowlist-itemsize-vs-rowitemsize]]); a wrapping Label needs about 40 px per line or it drops lines (the dialog body and the Account heading were clipped); a card lifted under a hint hid the hint (give the hint room above the lifted card).

## Why it matters

Showcase is the build-first target. The nav and logo choices come with owner rejections attached, so they should not be re-proposed.

## How to apply

- Build notes from the spec: a schedule service lazy-loads `getdvr.php` for the visible channels and computes now/next and "earlier today"; group series by exact title within one channel's 21 days.
- The whole logo at 144x75 in the nav; never a crop. Content column starts at x 184 on every screen with a title at y 46; sweep every screen against that contract ([[screen-consistency-discipline]]).
- Focus is lift-plus-shadow with no border, as on Roku in general ([[focus-border-abandoned-for-size-and-brightness]]); on the device the neighbours must also step back (see the build status above).
- Next step: the owner types credentials on the device so the signed-in flows can be walked. Merging `design/showcase` and any push need the owner's explicit go-ahead.
- Respect the feed limits in [[mysdatv-feed-derived-design-rules]].

## Related

[[mysdatv-design-systems-index]], [[mysdatv-feed-derived-design-rules]], [[mysdatv-wpalive-port-pattern]], [[rowlist-itemsize-vs-rowitemsize]], [[async-gate-needs-generation-and-visible-state]], [[logo-is-only-as-big-as-its-smallest-legible-part]], [[screen-consistency-discipline]], [[focus-border-abandoned-for-size-and-brightness]]
