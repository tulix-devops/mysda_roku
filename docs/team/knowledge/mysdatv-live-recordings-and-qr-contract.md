---
topic: mysdatv-live-recordings-and-qr-contract
summary: mySDAtv live-player Recordings row for subscribers (check-purchase productId 15, getdvr.php, Back-to-live) plus the two www.mysdatv.com QR cards on Log in and Account; the contract T7 (Flutter) must match
platform: roku
applies-to: [mysdatv]
observed-in: [mysdatv]
date: 2026-11-19
source-task: mysdatv/docs/team/tasks/2026-11-19-live-dvr-login-qr/
---

# Live player Recordings row and sign-in QR cards (mysdatv contract)

## Fact

Built and device-verified on Roku (T6); another platform (T7, Flutter) should match it.

**Who is a subscriber.** Signed in AND catch-up access = yes. Access comes from
`POST https://sda.wchupload.tulix.net/api/payments/customer/check-purchase`, body
`{"collectionId":null,"productId":15}`, headers `Authorization: Bearer <accessToken>`,
`X-Session-Token: <sessionToken>` and a second `X-Session-Token: <accessToken>`
(the app sends both, unchanged from the older check). Run once at boot when a stored
session exists, and again from the player when signed in and the answer is unknown
or "error". It never raises a dialog in the live player: unknown/error look like
"not subscribed". A late "yes" must not swap the row once the viewer has pressed
any key.

**Open question S1 (owner):** the existing parsing treats HTTP statusCode 200 as
"yes" regardless of the response data. Real bodies from a subscribed and an
unsubscribed account are needed to confirm; not yet captured. Do not copy that
parsing into T7 without checking.

**Recordings data.** `GET https://livetv.mysdatv.com/api/getdvr.php?id=<stream>`, no
auth (see [[mysdatv-feed-derived-design-rules]]). Keep aired programmes that have
their own stream, newest first, max 48 (about two days hourly; the Catch-up screen
holds the full 21 days). A grab that is the 6542-byte placeholder shows the channel
logo instead.

**Behaviour.**
- Subscribers see a Recordings row (up to 6 16:9 cards: grab, title or "3 PM hour",
  "Today · 8:00 PM") in place of the live channel strip; a tab line
  `RECORDINGS  LIVE CHANNELS` with Up/Down to swap, one row on screen at a time.
- Non-subscribers (signed out, no access, error, unknown, or no recordings) get the
  unchanged live channels strip, no tab line.
- OK plays the recording in the catch-up player; Next episode = next newer recording.
  Back or end of the last recording returns to THAT channel live, with the recording
  just watched highlighted; a second Back returns to the page the player was opened from.
- First OK on a hidden-chrome player only reveals the chrome.

**QR cards.** Two cards (code on a 222 px white plate, 2-module quiet zone, kicker,
title, body) side by side below the content on Log in and on Account/Profile
(owner: "below, horizontally"; also on TV Profile, not only Log in):
- "Sign up & subscribe" -> `https://www.mysdatv.com/`
- "Donate" -> `https://www.mysdatv.com/mysdatv-donation-page`
Encoded on the device (99-156 ms each), decoded back from device captures with a
negative control.

## Why it matters

The Flutter port has no Roku code to read for intent. Two points are easy to get
wrong: the access check is lenient (S1), and Back from a recording goes to live.

## How to apply

- Reproduce the row rules and URLs above; resolve S1 with real response bodies first.
- Roku-specific limits are not requirements: 6 cards (not 7) is a Roku sizing choice.

## Related

[[mysdatv-church-directory-api]], [[mysdatv-feed-derived-design-rules]], [[on-device-qr-encoder-in-brightscript]], [[keyboard-node-qr-banner-forces-stacked-layout]]
