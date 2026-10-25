sub init()
    m.t = ScTheme()
    m.body = m.top.findNode("body")
    m.shadow = m.top.findNode("shadow")
    m.plate = m.top.findNode("plate")
    m.glyph = m.top.findNode("glyph")
    m.label = m.top.findNode("label")
    m.shadow.uri = ScShape("shadow14")
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
    ' Measure the wider (ExtraBold) face so the pill does not change width
    ' when it lights.
    tw = ScTextW(text, size, "xb")
    w = padL + iconW + tw + padR
    if w < m.top.minW then w = m.top.minW
    m.top.w = w

    m.plate.uri = ScPillFor(h)
    m.plate.width = w
    m.plate.height = h
    gs = Int(size * 0.85)
    m.glyph.width = gs
    m.glyph.height = gs
    m.glyph.translation = [padL, Int((h - gs) / 2)]
    m.glyph.visible = hasIcon
    if hasIcon then m.glyph.uri = ScGlyph(m.top.icon)
    m.label.translation = [padL + iconW, 0]
    m.label.width = tw + 6
    m.label.height = h
    m.label.text = text
    ' The shadow sits under the pill grown by its 36-px blur, nudged down.
    b = 36
    m.shadow.translation = [-b, -b + 14]
    m.shadow.width = w + 2 * b
    m.shadow.height = h + 2 * b
    m.body.scaleRotateCenter = [0, h / 2]
    paint()
end sub

sub paint()
    size = m.top.fontSize
    if m.top.lit
        m.plate.blendColor = m.t.cFocus
        m.label.color = m.t.cOnFocus
        m.glyph.blendColor = m.t.cOnFocus
        m.label.font = ScFont(m.t.fXB, size)
        m.body.scale = [1.06, 1.06]
        m.shadow.blendColor = "0x000000B0"
        m.shadow.visible = true
    else if m.top.selected
        m.plate.blendColor = m.t.cFocus
        m.label.color = m.t.cOnFocus
        m.glyph.blendColor = m.t.cOnFocus
        m.label.font = ScFont(m.t.fBold, size)
        m.body.scale = [1.0, 1.0]
        m.shadow.visible = false
    else
        m.plate.blendColor = m.t.cRaised
        m.label.color = m.t.cText
        m.glyph.blendColor = m.t.cText
        m.label.font = ScFont(m.t.fBold, size)
        m.body.scale = [1.0, 1.0]
        m.shadow.visible = false
    end if
end sub
