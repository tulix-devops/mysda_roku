sub init()
    ScEnsureGlobals()
    m.t = ScTheme()
    m.names = ["home", "channels", "radio", "catchup", "account"]
    m.labels = ["Home", "Channels", "Radio", "Catch-up", "Account"]
    m.glyphs = ["nav_home", "nav_channels", "nav_radio", "nav_catchup", "nav_account"]
    m.focusIndex = 0

    m.shadow = m.top.findNode("shadow")
    m.ring = m.top.findNode("ring")
    m.plate = m.top.findNode("plate")
    itemsGroup = m.top.findNode("items")

    m.h = 16 * 2 + 5 * 72 + 4 * 12
    m.shadow.uri = ScShape("shadow14")
    m.shadow.blendColor = "0x00000099"
    m.ring.uri = ScShape("r51")
    m.ring.blendColor = m.t.cCapsuleRing
    m.plate.uri = ScShape("r51")
    m.plate.blendColor = m.t.cCapsule

    m.rows = []
    for i = 0 to 4
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
        label = row.createChild("Label")
        label.text = m.labels[i]
        label.translation = [90, 0]
        label.width = 200
        label.height = 72
        label.vertAlign = "center"
        m.rows.push({ circle: circle, glyph: glyph, label: label })
    end for
    m.top.observeField("focusedChild", "onFocusedChild")
    paint()
end sub

function indexOf(name as string) as integer
    for i = 0 to m.names.count() - 1
        if m.names[i] = name then return i
    end for
    return 0
end function

sub onNavFocus()
    if m.top.navHasFocus
        ' Focus opens on the destination on display.
        m.focusIndex = indexOf(m.top.selected)
        m.top.setFocus(true)
    end if
    paint()
end sub

sub onFocusedChild()
    ' Focus can leave without navHasFocus being cleared (a dialog over the
    ' page); the capsule closes with it.
    if not m.top.isInFocusChain() and m.top.navHasFocus then m.top.navHasFocus = false
end sub

sub paint()
    open = m.top.navHasFocus
    w = 104
    if open then w = 330
    m.plate.width = w
    m.plate.height = m.h
    m.ring.width = w + 2
    m.ring.height = m.h + 2
    b = 36
    m.shadow.translation = [-b, -b + 30]
    m.shadow.width = w + 2 * b
    m.shadow.height = m.h + 2 * b

    sel = indexOf(m.top.selected)
    for i = 0 to 4
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
        r.label.visible = open
        if focused or current
            r.label.font = ScFont(m.t.fXB, 27)
            r.label.color = m.t.cText
        else
            r.label.font = ScFont(m.t.fSemi, 27)
            r.label.color = m.t.cText2
        end if
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
            if key = "down" and m.focusIndex < 4 then m.focusIndex = m.focusIndex + 1
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
