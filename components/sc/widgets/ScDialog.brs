sub init()
    ScEnsureGlobals()
    m.t = ScTheme()
    m.top.findNode("dim").color = "0x07080CC8"
    m.shadow = m.top.findNode("shadow")
    m.panel = m.top.findNode("panel")
    m.titleLabel = m.top.findNode("title")
    m.bodyLabel = m.top.findNode("body")
    m.buttonsGroup = m.top.findNode("buttons")
    m.panelGroup = m.top.findNode("panelGroup")
    m.shadow.uri = ScShape("shadow14")
    m.shadow.blendColor = "0x000000C0"
    m.panel.uri = ScShape("r22")
    m.panel.blendColor = m.t.cSurface
    m.titleLabel.font = ScFont(m.t.fXB, 40)
    m.titleLabel.color = m.t.cText
    m.bodyLabel.font = ScFont(m.t.fSemi, 24)
    m.bodyLabel.color = m.t.cText2
    m.pills = []
    m.index = 0
end sub

sub onSpec()
    spec = m.top.spec
    if spec = invalid then return
    w = 860
    pad = 56
    inner = w - 2 * pad
    m.titleLabel.width = inner
    m.titleLabel.translation = [pad, pad]
    m.titleLabel.text = ScDlgStr(spec.title)
    ' Two title lines at most; the body follows the title's real height.
    titleH = 52
    if ScTextW(m.titleLabel.text, 40, "xb") > inner then titleH = 104
    m.titleLabel.height = titleH
    body = ScDlgStr(spec.body)
    m.bodyLabel.width = inner
    m.bodyLabel.translation = [pad, pad + titleH + 14]
    m.bodyLabel.text = body
    bodyLines = 0
    if body <> "" then bodyLines = Int(ScTextW(body, 24, "semi") / inner) + 1
    if bodyLines > 4 then bodyLines = 4
    bodyH = bodyLines * 34
    m.bodyLabel.height = bodyH
    m.bodyLabel.visible = (body <> "")

    m.buttonsGroup.removeChildrenIndex(m.buttonsGroup.getChildCount(), 0)
    m.pills = []
    labels = spec.buttons
    if type(labels) <> "roArray" or labels.count() = 0 then labels = ["OK"]
    x = 0
    for each text in labels
        p = m.buttonsGroup.createChild("ScPill")
        p.text = text
        p.translation = [x, 0]
        x = x + p.w + 18
        m.pills.push(p)
    end for
    by = pad + titleH + 14 + bodyH + 34
    m.buttonsGroup.translation = [pad, by]
    h = by + 72 + pad
    m.panel.width = w
    m.panel.height = h
    b = 36
    m.shadow.translation = [-b, -b + 24]
    m.shadow.width = w + 2 * b
    m.shadow.height = h + 2 * b
    m.panelGroup.translation = [Int((1920 - w) / 2), Int((1080 - h) / 2)]
    m.index = 0
    paint()
end sub

function ScDlgStr(v as dynamic) as string
    if v = invalid then return ""
    return v
end function

sub paint()
    for i = 0 to m.pills.count() - 1
        m.pills[i].lit = (i = m.index)
    end for
end sub

sub answer(index as integer)
    spec = m.top.spec
    id = ""
    if spec <> invalid and spec.id <> invalid then id = spec.id
    m.global.dialogResult = { id: id, index: index }
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return true
    if key = "left"
        if m.index > 0 then m.index = m.index - 1
        paint()
    else if key = "right"
        if m.index < m.pills.count() - 1 then m.index = m.index + 1
        paint()
    else if key = "OK"
        answer(m.index)
    else if key = "back"
        answer(-1)
    end if
    ' Modal: nothing under it hears a key.
    return true
end function
