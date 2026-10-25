sub init()
    m.headingLabel = m.top.findNode("headingLabel")
end sub

sub onHeadingSet()
    if m.headingLabel = invalid then return
    text = m.top.heading
    m.headingLabel.text = text
    m.headingLabel.visible = (text <> "")
end sub
