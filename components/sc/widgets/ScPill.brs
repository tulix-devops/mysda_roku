' ============================================================================
' ScPill.brs - the Showcase button.
'
' FOCUS NEVER TOUCHES THE TEXT (owner, 2026-10-28: "Watch Live text is
' stretched on the button when focused"). The first build lifted the whole
' pill 1.06 and swapped Bold for ExtraBold: the scale resampled the glyphs and
' the heavier face widened them, so the word looked stretched. Now the label
' is drawn 1:1 in the same face in every state; focus is the plate turning
' white (dark ink) and growing 4 px round the text, with a soft shadow
' (knowledge/dev-roku/counter-scale-text-inside-a-scaled-focus-group is the
' same lesson: never scale a Group that holds text).
' ============================================================================

sub init()
    m.t = ScTheme()
    m.shadow = m.top.findNode("shadow")
    m.plate = m.top.findNode("plate")
    m.glyph = m.top.findNode("glyph")
    m.label = m.top.findNode("label")
    m.shadow.uri = ScShape("shadow14")
    m.grow = 4
    layout()
end sub

sub layout()
    h = m.top.h
    size = m.top.fontSize
    text = m.top.text
    hasIcon = (m.top.icon <> "")
    padL = Int(h * 0.48)
    padR = padL
    iconW = 0
    if hasIcon
        iconW = Int(size * 0.85) + 12
        padL = Int(h * 0.44)
    end if
    tw = ScTextW(text, size, "bold")
    w = padL + iconW + tw + padR
    if w < m.top.minW then w = m.top.minW
    m.top.w = w
    m.w = w
    m.h = h

    m.plate.uri = ScPillFor(h + 2 * m.grow)
    gs = Int(size * 0.85)
    m.glyph.width = gs
    m.glyph.height = gs
    m.glyph.translation = [padL, Int((h - gs) / 2)]
    m.glyph.visible = hasIcon
    if hasIcon then m.glyph.uri = ScGlyph(m.top.icon)
    m.label.translation = [padL + iconW, 0]
    m.label.width = tw + 8
    m.label.height = h
    m.label.text = text
    ' One face in every state, so nothing changes width or weight.
    m.label.font = ScFont(m.t.fBold, size)
    b = 36
    m.shadow.translation = [-b, -b + 14]
    m.shadow.width = w + 2 * b
    m.shadow.height = h + 2 * b
    paint()
end sub

sub paint()
    lit = m.top.lit
    sel = m.top.selected
    ' The plate grows round the text when lit; the text does not move.
    g = 0
    if lit then g = m.grow
    m.plate.translation = [-g, -g]
    m.plate.width = m.w + 2 * g
    m.plate.height = m.h + 2 * g
    if lit or sel
        m.plate.blendColor = m.t.cFocus
        m.label.color = m.t.cOnFocus
        m.glyph.blendColor = m.t.cOnFocus
    else
        m.plate.blendColor = m.t.cRaised
        m.label.color = m.t.cText
        m.glyph.blendColor = m.t.cText
    end if
    m.shadow.visible = lit
    if lit then m.shadow.blendColor = "0x000000B0"
end sub
