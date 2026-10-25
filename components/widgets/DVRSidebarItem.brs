sub init()
    SdEnsureGlobals()
    m.t = SdTheme()
    m.pill = m.top.findNode("pill")
    m.label = m.top.findNode("label")
    m.dot = m.top.findNode("dot")
    onFocusChanged()
end sub

sub updateContent()
    content = m.top.itemContent
    if content <> invalid and content.title <> invalid
        m.label.text = content.title
    else
        m.label.text = ""
    end if
end sub

' Every branch assigns every node: a list recycles its items.
sub onFocusChanged()
    inHand = (m.top.focusPercent > 0.5)
    if inHand and m.top.listHasFocus = true
        m.pill.blendColor = m.t.cNavFocus
        m.label.color = m.t.cOnNavFocus
        m.label.font = SdFont(m.t.fDisplay, 30)
        m.dot.blendColor = m.t.cClear
    else if inHand
        m.pill.blendColor = m.t.cClear
        m.label.color = m.t.cSelected
        m.label.font = SdFont(m.t.fDisplay, 30)
        m.dot.blendColor = m.t.cSelected
    else
        m.pill.blendColor = m.t.cClear
        m.label.color = m.t.cText
        m.label.font = SdFont(m.t.fSemi, 29)
        m.dot.blendColor = m.t.cClear
    end if
end sub
