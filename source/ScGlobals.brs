' ============================================================================
' ScGlobals.brs - the fields every Showcase component reads off m.global.
'
' DECLARATION lives here, not in ScScene.init(): SceneGraph runs each child's
' init() BEFORE the scene's own, and reading a field the scene has not
' declared yet is a hard Type Mismatch crash
' (knowledge/dev-roku/scene-init-order-and-findnode-timing). Every component
' calls ScEnsureGlobals() first; whichever runs first declares, the rest are
' no-ops. OBSERVERS are not declared here.
'
' Requests are COUNTERS or nodes with alwaysNotify: writing the value a field
' already holds does not notify
' (knowledge/dev-roku/equal-value-field-writes-do-not-notify).
' ============================================================================

sub ScEnsureGlobals()
    if m.global = invalid then return
    if m.global.hasField("scGlobalsReady") then return

    ' -- the catalogue (ScFeedTask), ContentNode roots of channel nodes ------
    m.global.addField("catTv", "node", false)       ' Television (list 8)
    m.global.addField("catLang", "node", false)     ' Television Languages (9)
    m.global.addField("catRadio", "node", false)    ' Radios (10)
    ' Bumped once per catalogue feed that lands (or fails).
    m.global.addField("catVersion", "integer", true)

    ' -- schedules (ScScheduleTask), lazy, per channel -------------------------
    ' A ContentNode whose children are one schedule node per stream id
    ' (child id = stream). Never part of the boot gate
    ' (knowledge/dev-roku/secondary-feed-must-not-join-the-boot-gate).
    m.global.addField("schedStore", "node", false)
    ' Ask the scene to load a channel's schedule: the stream id.
    m.global.addField("schedWant", "string", true)
    ' Bumped when a schedule lands; schedLast names the stream.
    m.global.addField("schedVersion", "integer", true)
    m.global.addField("schedLast", "string", false)

    ' -- navigation requests (the scene observes) -----------------------------
    ' A capsule destination by name: home | channels | radio | catchup | account
    m.global.addField("openScreen", "string", true)
    ' Open a channel's page (a catalogue channel node).
    m.global.addField("openChannel", "node", true)
    ' Play something: a ContentNode built by ScPlayNode() (ScData.brs).
    m.global.addField("playItem", "node", true)
    ' Close the player / the channel page, one layer at a time.
    m.global.addField("closeOverlay", "integer", true)
    ' A modal: { id, title, body, buttons: ["Log in", "Not now"] }.
    m.global.addField("openDialog", "assocarray", true)
    ' The dialog's answer: { id, index } (index -1 = Back).
    m.global.addField("dialogResult", "assocarray", true)

    ' Bumped whenever focus moves between zones, AFTER the move: a card lights
    ' on its list's focusPercent, which stays 1.0 after the list has lost
    ' focus (knowledge/dev-roku/focus-source-focuspercent-vs-hand-maintained-field).
    m.global.addField("scFocusTick", "integer", true)
    ' True while the capsule holds focus (the page dims).
    m.global.addField("navOpen", "boolean", false)
    ' Bumped every 30 s by the scene: "on now", progress and "min left" move
    ' with the clock, and a screen refreshes them in place on this.
    m.global.addField("minuteTick", "integer", true)

    ' -- the viewer --------------------------------------------------------------
    ' From registry AUTH.authData (the same record the old build wrote, so a
    ' viewer signed in there stays signed in). Never the token itself.
    m.global.addField("viewerSignedIn", "boolean", false)
    m.global.addField("viewerEmail", "string", false)
    m.global.addField("viewerName", "string", false)
    ' Catch-up access from check-purchase (productId 15):
    ' "" unknown | "yes" | "no" | "error"
    m.global.addField("catchupAccess", "string", false)
    ' Bumped whenever any of the above changes.
    m.global.addField("sessionVersion", "integer", true)
    m.global.addField("openSignIn", "integer", true)
    m.global.addField("requestSignOut", "integer", true)
    ' Ask the scene to run check-purchase now (the Account screen, to say).
    m.global.addField("checkAccess", "integer", true)

    m.global.addField("scGlobalsReady", "boolean", false)
    m.global.scGlobalsReady = true
end sub

' Call AFTER focus has moved, never before.
sub ScFocusChanged()
    if m.global = invalid then return
    m.global.scFocusTick = m.global.scFocusTick + 1
end sub
