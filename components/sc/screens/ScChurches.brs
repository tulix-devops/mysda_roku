' ============================================================================
' ScChurches.brs - states | churches | QR panel. Two focus zones ("states",
' "churches"); each column is a fixed set of row slots refilled from a
' window over its list (no list widget: the rows are the Showcase's own
' pills and plates).
' ============================================================================

sub init()
    ScEnsureGlobals()
    m.t = ScTheme()
    m.statesGroup = m.top.findNode("states")
    m.churchGroup = m.top.findNode("churches")
    m.panel = m.top.findNode("panel")
    m.qrModules = m.top.findNode("qrModules")
    m.qrNote = m.top.findNode("qrNote")
    m.nameLabel = m.top.findNode("name")
    m.placeLabel = m.top.findNode("place")
    m.hintLabel = m.top.findNode("hint")
    m.linkLabel = m.top.findNode("link")
    m.note = m.top.findNode("note")
    m.qrTimer = m.top.findNode("qrTimer")
    m.qrTimer.observeField("fire", "onQrTimer")

    plate = m.top.findNode("qrPlate")
    plate.uri = ScShape("r22")
    plate.blendColor = m.t.cPlate
    sh = m.top.findNode("qrShadow")
    sh.uri = ScShape("shadow14")
    sh.blendColor = "0x000000B0"
    sh.translation = [-36, -36 + 24]
    sh.width = 540 + 72
    sh.height = 540 + 72
    m.qrNote.font = ScFont(m.t.fSemi, 24)
    m.qrNote.color = m.t.cText3
    m.qrLoader = m.top.findNode("qrLoader")
    m.loaderPulse = m.top.findNode("loaderPulse")
    lt = m.top.findNode("qrLoaderText")
    lt.font = ScFont(m.t.fSemi, 24)
    lt.color = m.t.cText3
    lt.text = "Creating code" + Chr(8230)
    ' The ghost: three finder squares where a code's corners land.
    for each at in [[70, 70], [400, 70], [70, 400]]
        for each ring in [[0, 70, "0xC9CDD6FF"], [10, 50, "0xFFFFFFFF"], [20, 30, "0xC9CDD6FF"]]
            r = m.qrLoader.createChild("Rectangle")
            r.translation = [at[0] + ring[0], at[1] + ring[0]]
            r.width = ring[1]
            r.height = ring[1]
            r.color = ring[2]
        end for
    end for
    m.nameLabel.font = ScFont(m.t.fXB, 34)
    m.nameLabel.color = m.t.cText
    m.placeLabel.font = ScFont(m.t.fSemi, 24)
    m.placeLabel.color = m.t.cText1
    m.hintLabel.font = ScFont(m.t.fSemi, 22)
    m.hintLabel.color = m.t.cText2
    m.linkLabel.font = ScFont(m.t.fMed, 19)
    m.linkLabel.color = m.t.cText3
    m.note.font = ScFont(m.t.fSemi, 26)
    m.note.color = m.t.cText2

    ' Row slots. States: 14 pills of 52 on a 60 pitch. Churches: 9 plates
    ' of 84 on a 96 pitch.
    m.stRows = 14
    m.stSlots = []
    for k = 0 to m.stRows - 1
        g = m.statesGroup.createChild("Group")
        g.translation = [0, k * 60]
        bg = g.createChild("Poster")
        bg.uri = ScPillFor(52)
        bg.width = 330
        bg.height = 52
        name = g.createChild("Label")
        name.translation = [24, 0]
        name.width = 230
        name.height = 52
        name.vertAlign = "center"
        name.font = ScFont(m.t.fBold, 24)
        name.wrap = false
        name.ellipsisText = "..."
        cnt = g.createChild("Label")
        cnt.translation = [250, 0]
        cnt.width = 56
        cnt.height = 52
        cnt.vertAlign = "center"
        cnt.horizAlign = "right"
        cnt.font = ScFont(m.t.fSemi, 20)
        m.stSlots.push({ group: g, bg: bg, name: name, count: cnt })
    end for
    m.chRows = 9
    m.chSlots = []
    for k = 0 to m.chRows - 1
        g = m.churchGroup.createChild("Group")
        g.translation = [0, k * 96]
        bg = g.createChild("Poster")
        bg.uri = ScShape("r14")
        bg.width = 660
        bg.height = 84
        name = g.createChild("Label")
        name.translation = [26, 10]
        name.width = 608
        name.height = 36
        name.vertAlign = "center"
        name.font = ScFont(m.t.fBold, 26)
        name.wrap = false
        name.ellipsisText = "..."
        city = g.createChild("Label")
        city.translation = [26, 46]
        city.width = 608
        city.height = 28
        city.vertAlign = "center"
        city.font = ScFont(m.t.fSemi, 20)
        city.wrap = false
        city.ellipsisText = "..."
        m.chSlots.push({ group: g, bg: bg, name: name, city: city })
    end for

    m.data = invalid
    m.task = invalid
    m.zone = "states"
    m.stIdx = 0
    m.stTop = 0
    m.chIdx = 0
    m.chTop = 0
    m.qrCache = {}
    m.qrCache.SetModeCaseSensitive()
    m.qrOrder = []
    m.qrPending = ""
    m.qrFor = ""
    ScSetTitle(m.top.findNode("title"), m.top.findNode("subtitle"), "Churches", "scan a code to watch on your phone")
    m.top.observeField("focusedChild", "onFocusChild")
    paint()
end sub

' The list loads the first time the screen is shown, not at boot
' (knowledge/dev-roku/hidden-screen-first-fetch-races-the-landing-screen).
sub onActive()
    if not m.top.active then return
    if m.data <> invalid or m.task <> invalid then return
    m.note.text = "Loading churches" + Chr(8230)
    m.note.visible = true
    m.task = CreateObject("roSGNode", "ScChurchTask")
    m.task.observeField("done", "onLoaded")
    m.task.control = "RUN"
end sub

sub onLoaded()
    t = m.task
    m.task = invalid
    if not t.ok or t.result = invalid or t.result.getChildCount() = 0
        m.note.text = "The church list didn't load. Try again later."
        m.note.visible = true
        return
    end if
    m.data = t.result
    m.note.visible = false
    n = 0
    for i = 0 to m.data.getChildCount() - 1
        n = n + m.data.getChild(i).getChildCount()
    end for
    ScSetTitle(m.top.findNode("title"), m.top.findNode("subtitle"), "Churches", n.toStr() + " churches  ·  scan a code to watch on your phone")
    m.panel.visible = true
    m.stIdx = 0
    m.stTop = 0
    m.chIdx = 0
    m.chTop = 0
    paint()
    showChurch()
end sub

sub onFocusChild()
    paint()
end sub

' ---------------------------------------------------------------- paint --

function stateCount() as integer
    if m.data = invalid then return 0
    return m.data.getChildCount()
end function

function currentState() as dynamic
    if stateCount() = 0 then return invalid
    return m.data.getChild(m.stIdx)
end function

function churchCount() as integer
    s = currentState()
    if s = invalid then return 0
    return s.getChildCount()
end function

function currentChurch() as dynamic
    s = currentState()
    if s = invalid or s.getChildCount() = 0 then return invalid
    return s.getChild(m.chIdx)
end function

' The window over a list keeps one row of what comes next in view.
function windowTop(idx as integer, top as integer, rows as integer, count as integer) as integer
    if idx < top + 1 then top = idx - 1
    if idx > top + rows - 2 then top = idx - rows + 2
    if top > count - rows then top = count - rows
    if top < 0 then top = 0
    return top
end function

sub paint()
    hasFocus = m.top.hasFocus()
    sc = stateCount()
    m.stTop = windowTop(m.stIdx, m.stTop, m.stRows, sc)
    for k = 0 to m.stRows - 1
        slot = m.stSlots[k]
        i = m.stTop + k
        slot.group.visible = (i < sc)
        if i < sc
            s = m.data.getChild(i)
            slot.name.text = s.title
            slot.count.text = s.scCount.toStr()
            if i = m.stIdx and hasFocus and m.zone = "states"
                slot.bg.visible = true
                slot.bg.blendColor = m.t.cFocus
                slot.name.color = m.t.cOnFocus
                slot.count.color = m.t.cOnFocus
            else if i = m.stIdx
                slot.bg.visible = true
                slot.bg.blendColor = m.t.cNavSel
                slot.name.color = m.t.cText
                slot.count.color = m.t.cText1
            else
                slot.bg.visible = false
                slot.name.color = m.t.cText2
                slot.count.color = m.t.cText3
            end if
        end if
    end for

    cc = churchCount()
    st = currentState()
    m.chTop = windowTop(m.chIdx, m.chTop, m.chRows, cc)
    for k = 0 to m.chRows - 1
        slot = m.chSlots[k]
        i = m.chTop + k
        slot.group.visible = (i < cc)
        if i < cc
            c = st.getChild(i)
            slot.name.text = c.title
            slot.city.text = c.scCity
            if i = m.chIdx and hasFocus and m.zone = "churches"
                slot.bg.blendColor = m.t.cFocus
                slot.name.color = m.t.cOnFocus
                slot.city.color = m.t.cOnFocus
            else
                slot.bg.blendColor = m.t.cSurface
                slot.name.color = m.t.cText1
                slot.city.color = m.t.cText2
            end if
        end if
    end for
end sub

' The panel's words change at once and the old code is cleared straight
' away, so a code never sits beside another church's name. A code made
' before is drawn at once; a new one is made once focus has settled for
' 0.25 s, the loader showing until then.
sub showChurch()
    c = currentChurch()
    m.qrTimer.control = "stop"
    m.qrPending = ""
    m.qrModules.removeChildrenIndex(m.qrModules.getChildCount(), 0)
    m.qrFor = ""
    if c = invalid
        m.panel.visible = false
        return
    end if
    m.panel.visible = true
    m.nameLabel.text = c.title
    place = c.scCity
    if place <> "" then place = place + ", "
    m.placeLabel.text = place + c.scState
    link = c.scLink
    ' Only a web link becomes a code, and the hint goes by the link's HOST,
    ' never by a word anywhere in it (review S1: "phish.example/?youtube.com"
    ' must not read "watch on YouTube").
    l = LCase(link)
    if Left(l, 8) <> "https://" and Left(l, 7) <> "http://" then link = ""
    host = hostOf(link)
    where = ""
    if hostIs(host, "youtube.com") or host = "youtu.be"
        where = "Scan with your phone's camera to watch on YouTube"
    else if hostIs(host, "facebook.com")
        where = "Scan with your phone's camera to watch on Facebook"
    else if link <> ""
        where = "Scan with your phone's camera to open the link"
    end if
    m.hintLabel.text = where
    shown = link
    for each pre in ["https://", "http://", "www."]
        if Left(LCase(shown), Len(pre)) = pre then shown = Mid(shown, Len(pre) + 1)
    end for
    m.linkLabel.text = shown
    if link = ""
        showLoader(false)
        m.qrNote.text = "No link for this church"
        m.qrNote.visible = true
        return
    end if
    m.qrNote.visible = false
    m.qrPending = link
    if m.qrCache.DoesExist(link)
        drawQr(link)
        return
    end if
    showLoader(true)
    m.qrTimer.control = "start"
end sub

sub showLoader(on as boolean)
    if on = m.qrLoader.visible then return
    m.qrLoader.visible = on
    if on
        m.loaderPulse.control = "start"
    else
        m.loaderPulse.control = "stop"
    end if
end sub

' qrPending is only ever the focused church's own link (showChurch clears
' it first; review-2 N1).
sub onQrTimer()
    m.qrTimer.control = "stop"
    if m.qrPending = "" or currentChurch() = invalid then return
    drawQr(m.qrPending)
end sub

' "https://user@www.youtube.com:443/c/x?y" -> "www.youtube.com"; "" for no
' link. In a browser's order: the authority ends at the first / \ ? or #
' (browsers read \ as /), then the user part ends at its LAST @, then the
' port goes (review-2: "youtube.com:443@evil.example", "evil.example\.youtube.com").
function hostOf(link as string) as string
    l = LCase(link)
    p = Instr(1, l, "://")
    if p = 0 then return ""
    rest = Mid(l, p + 3)
    for each stopAt in ["/", "\", "?", "#"]
        e = Instr(1, rest, stopAt)
        if e > 0 then rest = Left(rest, e - 1)
    end for
    a = Instr(1, rest, "@")
    while a > 0
        rest = Mid(rest, a + 1)
        a = Instr(1, rest, "@")
    end while
    e = Instr(1, rest, ":")
    if e > 0 then rest = Left(rest, e - 1)
    return rest
end function

' The host is the domain or one of its subdomains.
function hostIs(host as string, domain as string) as boolean
    if host = domain then return true
    return Right(host, Len(domain) + 1) = "." + domain
end function

' The code as one Rectangle per run of dark modules in a row, with a
' 4-module quiet zone. Module size, the code's offset in the plate and the
' panel's own position are all multiples of 3 plane px, so the code lands on
' whole pixels on a 720p screen too (2/3 scale).
' The cache holds each link's runs ([x, y, length]), not its matrix, up to
' 24 links; its keys are case-sensitive (YouTube channel ids are; review
' C2, C3).
sub drawQr(link as string)
    if m.qrFor = link or link = "" then return
    q = m.qrCache.Lookup(link)
    if q = invalid
        mx = ScQrMatrix(link)
        if mx = invalid
            showLoader(false)
            m.qrNote.text = "This link is too long for a code"
            m.qrNote.visible = true
            return
        end if
        q = runsOf(mx)
        if m.qrOrder.count() >= 24 then m.qrCache.Delete(m.qrOrder.shift())
        m.qrCache[link] = q
        m.qrOrder.push(link)
    end if
    g = m.qrModules
    g.removeChildrenIndex(g.getChildCount(), 0)
    n = q.size + 8
    unit = (513 \ n) \ 3 * 3
    if unit < 3 then unit = 3
    origin = (540 - n * unit) \ 2 \ 3 * 3 + 4 * unit
    ink = "0x000000FF"
    for each seg in q.runs
        r = g.createChild("Rectangle")
        r.color = ink
        r.translation = [origin + seg[0] * unit, origin + seg[1] * unit]
        r.width = seg[2] * unit
        r.height = unit
    end for
    m.qrFor = link
    showLoader(false)
end sub

function runsOf(mx as object) as object
    runs = []
    for y = 0 to mx.size - 1
        row = mx.dark[y]
        x = 0
        while x < mx.size
            if row[x]
                x0 = x
                while x < mx.size and row[x]
                    x = x + 1
                end while
                runs.push([x0, y, x - x0])
            else
                x = x + 1
            end if
        end while
    end for
    return { size: mx.size, runs: runs }
end function

' ------------------------------------------------------------------ keys --

function onKeyEvent(key as string, press as boolean) as boolean
    if stateCount() = 0 then return false
    owned = (key = "up" or key = "down" or key = "right" or key = "OK")
    if key = "left" and m.zone = "churches" then owned = true
    if not owned then return false
    ' Both edges of one press arrive (knowledge/dev-roku/key-event-fires-on-
    ' both-down-and-up-edges): act on the press, swallow the release.
    if not press then return true
    if m.zone = "states"
        if key = "up" and m.stIdx > 0
            m.stIdx = m.stIdx - 1
            enterState()
        else if key = "down" and m.stIdx < stateCount() - 1
            m.stIdx = m.stIdx + 1
            enterState()
        else if (key = "right" or key = "OK") and churchCount() > 0
            m.zone = "churches"
            paint()
        end if
        return true
    end if
    if key = "up" and m.chIdx > 0
        m.chIdx = m.chIdx - 1
        paint()
        showChurch()
    else if key = "down" and m.chIdx < churchCount() - 1
        m.chIdx = m.chIdx + 1
        paint()
        showChurch()
    else if key = "left"
        m.zone = "states"
        paint()
    end if
    return true
end function

sub enterState()
    m.chIdx = 0
    m.chTop = 0
    paint()
    showChurch()
end sub
