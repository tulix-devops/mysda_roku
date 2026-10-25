' ============================================================================
' SdGlobals.brs - the m.global fields the redesigned components share.
'
' Declared HERE, not in the scene: SceneGraph runs a child's init() BEFORE
' its parent scene's, so a field the scene declares does not exist yet when
' a tile or the rail first reads it - a hard Type Mismatch crash
' (knowledge/dev-roku/scene-init-order-and-findnode-timing). Every component
' that reads one calls SdEnsureGlobals() first; the first caller wins.
' ============================================================================

sub SdEnsureGlobals()
    if m.global = invalid then return
    if m.global.hasField("sdGlobalsReady") then return

    ' Bumped whenever focus moves between zones (rail <-> grid, sidebar <->
    ' episodes, an overlay opening). A tile lights on its list's
    ' focusPercent, which stays at 1.0 after the list has LOST focus; this is
    ' the signal that makes every tile re-check
    ' (knowledge/dev-roku/focus-source-focuspercent-vs-hand-maintained-field).
    ' A counter with alwaysNotify: an equal-value write does not notify.
    m.global.addField("focusTick", "integer", true)

    m.global.addField("sdGlobalsReady", "boolean", false)
    m.global.sdGlobalsReady = true
end sub

' Call AFTER focus has moved, never before: the tiles read the focus chain
' when it fires.
sub SdFocusChanged()
    if m.global = invalid then return
    SdEnsureGlobals()
    m.global.focusTick = m.global.focusTick + 1
end sub
