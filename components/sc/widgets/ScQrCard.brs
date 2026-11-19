' ============================================================================
' ScQrCard.brs - one link, one code, made once per url.
' ============================================================================

sub init()
    m.t = ScTheme()
    card = m.top.findNode("card")
    card.uri = ScShape("r22")
    card.blendColor = "0x12141BEB"
    plate = m.top.findNode("qrPlate")
    plate.uri = ScShape("r14")
    plate.blendColor = m.t.cPlate
    k = m.top.findNode("kickerLabel")
    k.font = ScFont(m.t.fXB, 19)
    k.color = m.t.cText2
    t = m.top.findNode("titleLabel")
    t.font = ScFont(m.t.fXB, 26)
    t.color = m.t.cText
    b = m.top.findNode("bodyLabel")
    b.font = ScFont(m.t.fSemi, 20)
    b.color = m.t.cText2
    m.drawnFor = ""
    m.timer = m.top.findNode("encodeTimer")
    m.timer.observeField("fire", "encode")
end sub

sub onText()
    m.top.findNode("kickerLabel").text = UCase(m.top.kicker)
    m.top.findNode("titleLabel").text = m.top.title
    m.top.findNode("bodyLabel").text = m.top.body
end sub

' A new link clears the old code at once (never a stale code beside new
' words), then encodes once the page has drawn.
sub onUrl()
    if m.top.url = m.drawnFor then return
    g = m.top.findNode("modules")
    g.removeChildrenIndex(g.getChildCount(), 0)
    m.drawnFor = ""
    m.timer.control = "stop"
    if m.top.url <> "" then m.timer.control = "start"
end sub

sub encode()
    url = m.top.url
    if url = "" or url = m.drawnFor then return
    t0 = CreateObject("roTimespan")
    if ScQrDraw(m.top.findNode("modules"), url, 222, 2) then m.drawnFor = url
    ? "[ScQrCard] "; url; " drawn in "; t0.TotalMilliseconds(); " ms"
end sub
