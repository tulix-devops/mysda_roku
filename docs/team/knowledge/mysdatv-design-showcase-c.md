---
topic: mysdatv-design-showcase-c
summary: mySDAtv design C Showcase (FINAL, build first) - near-black ground, Plus Jakarta Sans, left floating glass capsule nav, whole logo above it, a title on every screen, lift-on-focus with no border; 8 screens
platform: roku
applies-to: [mysdatv]
observed-in: [mysdatv]
date: 2026-10-06
source-task: mysdatv/docs/team/tasks/2026-10-06-three-design-directions/
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

## Why it matters

Showcase is the build-first target. The nav and logo choices come with owner rejections attached, so they should not be re-proposed.

## How to apply

- Build notes from the spec: a schedule service lazy-loads `getdvr.php` for the visible channels and computes now/next and "earlier today"; group series by exact title within one channel's 21 days.
- The whole logo at 144x75 in the nav; never a crop. Content column starts at x 184 on every screen with a title at y 46; sweep every screen against that contract ([[screen-consistency-discipline]]).
- Focus is lift-plus-shadow with no border, as on Roku in general ([[focus-border-abandoned-for-size-and-brightness]]).
- Respect the feed limits in [[mysdatv-feed-derived-design-rules]].

## Related

[[mysdatv-design-systems-index]], [[mysdatv-feed-derived-design-rules]], [[logo-is-only-as-big-as-its-smallest-legible-part]], [[screen-consistency-discipline]], [[focus-border-abandoned-for-size-and-brightness]]
