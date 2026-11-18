sub init()
    ScEnsureGlobals()
    m.t = ScTheme()
    m.names = ["home", "channels", "radio", "catchup", "churches", "account"]
    m.labels = ["Home", "Channels", "Radio", "Catch-up", "Churches", "Account"]
    m.glyphs = ["nav_home", "nav_channels", "nav_radio", "nav_catchup", "nav_churches", "nav_account"]
    m.focusIndex = 0
    m.closedW = 104
    m.openW = 330

    m.shadow = m.top.findNode("shadow")
    m.ring = m.top.findNode("ring")
    m.plate = m.top.findNode("plate")
    m.labelsGroup = m.top.findNode("labels")
    m.anim = m.top.findNode("openAnim")
    m.plateW = m.top.findNode("plateW")
    m.ringW = m.top.findNode("ringW")
    m.shadowW = m.top.findNode("shadowW")
    m.labelsFade = m.top.findNode("labelsFade")
    itemsGroup = m.top.findNode("items")

    m.count = m.names.count()
    m.h = 16 * 2 + m.count * 72 + (m.count - 1) * 12
    b = 36
    m.shadow.uri = ScShape("shadow14")
    m.shadow.blendColor = "0x00000099"
    m.shadow.translation = [-b, -b + 30]
    m.shadow.height = m.h + 2 * b
    m.ring.uri = ScShape("r51")
    m.ring.blendColor = m.t.cCapsuleRing
    m.ring.height = m.h + 2
    m.plate.uri = ScShape("r51")
    m.plate.blendColor = m.t.cCapsule
    m.plate.height = m.h
    setWidth(m.closedW)
    m.labelsGroup.opacity = 0

    m.rows = []
    for i = 0 to m.count - 1
        row = itemsGroup.createChild("Group")
        row.translation = [0, i * 84]
        circle = row.createChild("Poster")
        circle.uri = ScShape("r35")
        circle.width = 72
        circle.height = 72
        glyph = row.createChild("Poster")
        glyph.uri = ScGlyph(m.glyphs[i])
        glyph.width = 36
        glyph.height = 36
        glyph.translation = [18, 18]
        ' The labels live in one Group so a single interpolator fades them.
        label = m.labelsGroup.createChild("Label")
        label.text = m.labels[i]
        label.translation = [90, i * 84]
        label.width = 200
        label.height = 72
        label.vertAlign = "center"
        label.font = ScFont(m.t.fBold, 27)
        m.rows.push({ circle: circle, glyph: glyph, label: label })
    end for
    m.isOpen = false
    m.top.observeField("focusedChild", "onFocusedChild")
    paint()
end sub

sub setWidth(w as float)
    m.plate.width = w
    m.ring.width = w + 2
    m.shadow.width = w + 72
end sub

function indexOf(name as string) as integer
    for i = 0 to m.names.count() - 1
        if m.names[i] = name then return i
    end for
    return 0
end function

' The destination changed under an open capsule (Back goes Home): its focus
' follows (review C13).
sub onSelected()
    if m.top.navHasFocus then m.focusIndex = indexOf(m.top.selected)
    paint()
end sub

sub onNavFocus()
    if m.top.navHasFocus
        ' Focus opens on the destination on display.
        m.focusIndex = indexOf(m.top.selected)
        m.top.setFocus(true)
    end if
    animateOpen(m.top.navHasFocus)
    paint()
end sub

' The capsule widens 104 -> 330 and its labels fade in; it closes the same
' way, a little faster (owner, 2026-10-28: "it opens up really dry"). The
' animation always starts from where the capsule IS, so a quick open-close
' reverses smoothly instead of jumping.
sub animateOpen(open as boolean)
    if open = m.isOpen then return
    m.isOpen = open
    target = m.closedW
    fade = 0.0
    m.anim.duration = 0.18
    if open
        target = m.openW
        fade = 1.0
        m.anim.duration = 0.24
    end if
    m.anim.control = "stop"
    w = m.plate.width
    m.plateW.keyValue = [w, target]
    m.ringW.keyValue = [w + 2, target + 2]
    m.shadowW.keyValue = [w + 72, target + 72]
    m.labelsFade.keyValue = [m.labelsGroup.opacity, fade]
    m.anim.control = "start"
end sub

sub onFocusedChild()
    ' Focus can leave without navHasFocus being cleared (a dialog over the
    ' page); the capsule closes with it.
    if not m.top.isInFocusChain() and m.top.navHasFocus then m.top.navHasFocus = false
end sub

sub paint()
    open = m.top.navHasFocus
    sel = indexOf(m.top.selected)
    for i = 0 to m.count - 1
        r = m.rows[i]
        focused = open and i = m.focusIndex
        current = (i = sel)
        if focused
            r.circle.visible = true
            r.circle.blendColor = m.t.cFocus
            r.glyph.blendColor = m.t.cOnFocus
        else if current
            r.circle.visible = true
            r.circle.blendColor = m.t.cNavSel
            r.glyph.blendColor = m.t.cText
        else
            r.circle.visible = false
            r.glyph.blendColor = m.t.cText2
        end if
        ' One face for every label: focus is colour, never a heavier weight.
        if focused or current then r.label.color = m.t.cText else r.label.color = m.t.cText2
    end for
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not m.top.navHasFocus then return false
    ' Both edges of one press arrive (knowledge/dev-roku/key-event-fires-on-
    ' both-down-and-up-edges): act on the press, swallow the release of the
    ' keys we own.
    if key = "up" or key = "down"
        if press
            if key = "up" and m.focusIndex > 0 then m.focusIndex = m.focusIndex - 1
            if key = "down" and m.focusIndex < m.count - 1 then m.focusIndex = m.focusIndex + 1
            paint()
        end if
        return true
    end if
    if key = "OK" or key = "right"
        if press
            m.top.selected = m.names[m.focusIndex]
            m.top.choose = m.names[m.focusIndex]
        end if
        return true
    end if
    return false
end function
