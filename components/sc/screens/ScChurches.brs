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
    m.reqTask = invalid
    m.reqGen = 0
    m.reqIdx = -1
    m.panelEmpty = true
    m.moving = false
    m.reqForFocus = false
    m.restTimer = m.top.findNode("restTimer")
    m.restTimer.observeField("fire", "onRest")
    ScSetTitle(m.top.findNode("title"), m.top.findNode("subtitle"), "Churches", "scan a code to watch on your phone")
    m.top.observeField("focusedChild", "onFocusChild")
    paint()
end sub

' --------------------------------------------------------------- loading --
'
' The public API pages (docs/team/tasks/2026-11-19-public-api-churches,
' owner Q3): the first call (page 1 of 50) brings every state with its
' count, so the states column draws at once, and its churches fill the
' first states. After that a state loads when focus rests on it for 0.3 s
' (state=, 100 a page), the next state down is fetched ahead, and a state
' bigger than 100 pages on as focus nears the end of what is loaded. Each
' state is kept for 30 minutes. One request at a time; pump() always serves
' what has focus NOW, so a fast scroll never queues the states it passed.

' The list loads the first time the screen is shown, not at boot
' (knowledge/dev-roku/hidden-screen-first-fetch-races-the-landing-screen).
sub onActive()
    if not m.top.active then return
    if m.data <> invalid or m.task <> invalid then return
    loadFirst()
end sub

sub loadFirst()
    m.note.text = "Loading churches" + Chr(8230)
    m.note.visible = true
    m.task = CreateObject("roSGNode", "ScChurchTask")
    m.task.stateName = ""
    m.task.page = 1
    m.task.perPage = 50
    m.task.observeField("done", "onFirst")
    m.task.control = "RUN"
end sub

sub onFirst()
    t = m.task
    m.task = invalid
    r = t.result
    if not t.ok or r = invalid or r.scStates.count() = 0
        m.note.text = "The church list didn't load. Press OK to try again."
        m.note.visible = true
        return
    end if
    m.data = CreateObject("roSGNode", "ContentNode")
    byName = {}
    for each s in r.scStates
        node = m.data.createChild("ContentNode")
        node.title = s.state
        ' scFailed: the viewer asked for this state and it failed (the
        ' column says so; OK retries). scMoreFailed: a later page failed
        ' (the rows stay; a plate at the end says so). scRetryAt: a failed
        ' PREFETCH is quietly tried again after this time (review C4).
        node.addFields({ scCount: s.count, scPage: 0, scPages: 0, scAt: 0, scFailed: false, scMoreFailed: false, scRetryAt: 0 })
        byName[LCase(s.state)] = node
    end for
    ' Seed the states page 1 holds WHOLE (it ends part-way through one).
    groups = {}
    for each c in ScChildren(r)
        key = LCase(c.scState)
        if not groups.doesExist(key) then groups[key] = []
        groups[key].push(c)
    end for
    for each key in groups
        node = byName.Lookup(key)
        if node <> invalid and groups[key].count() >= node.scCount then fillState(node, groups[key], 1, 1, true)
    end for
    m.note.visible = false
    ScSetTitle(m.top.findNode("title"), m.top.findNode("subtitle"), "Churches", r.scTotal.toStr() + " churches  ·  scan a code to watch on your phone")
    m.panel.visible = true
    m.stIdx = 0
    m.stTop = 0
    m.chIdx = 0
    m.chTop = 0
    paint()
    showChurch()
    pump()
end sub

' A state's churches from one page; page 1 replaces what was there (a
' refresh), later pages append. Deduped on name + city + link.
sub fillState(node as object, list as object, page as integer, pages as integer, replace as boolean)
    if replace then node.removeChildrenIndex(node.getChildCount(), 0)
    seen = {}
    seen.SetModeCaseSensitive()
    for each c in ScChildren(node)
        seen[c.title + "|" + c.scCity + "|" + c.scLink] = true
    end for
    for each c in list
        key = c.title + "|" + c.scCity + "|" + c.scLink
        if not seen.doesExist(key)
            seen[key] = true
            n = node.createChild("ContentNode")
            n.title = c.title
            n.addFields({ scCity: c.scCity, scLink: c.scLink, scState: node.title })
        end if
    end for
    node.scPage = page
    node.scPages = pages
    ' Fully loaded: the count is what is listed. The feed holds true
    ' duplicates (Oakwood University Church twice, the second with its
    ' phone number), which the dedupe folds into one.
    if page >= pages then node.scCount = node.getChildCount()
    node.scAt = ScNowSecs()
    node.scFailed = false
    node.scMoreFailed = false
end sub

' A church's identity across reloads.
function churchKey(c as dynamic) as string
    if c = invalid then return ""
    return c.title + "|" + c.scCity + "|" + c.scLink
end function

' Loaded within the last 30 minutes (the server itself caches 60 s).
function isFresh(node as object) as boolean
    return (node.scPage >= 1 and ScNowSecs() - node.scAt < 1800)
end function

' The one place that decides the next request: the focused state first,
' then its next page when focus nears the end, then the state below.
' A failed state or page waits for OK (never a retry loop, review C1), and
' never blocks the prefetch of the state below (C4).
sub pump()
    if m.data = invalid or m.reqTask <> invalid then return
    cur = currentState()
    if cur = invalid then return
    if not isFresh(cur) and not cur.scFailed and ScNowSecs() >= cur.scRetryAt
        requestState(m.stIdx, 1)
        return
    end if
    if isFresh(cur) and cur.scPage < cur.scPages and not cur.scMoreFailed and m.zone = "churches" and m.chIdx >= cur.getChildCount() - 8
        requestState(m.stIdx, cur.scPage + 1)
        return
    end if
    nx = m.stIdx + 1
    if nx < stateCount()
        node = m.data.getChild(nx)
        if not isFresh(node) and not node.scFailed and ScNowSecs() >= node.scRetryAt then requestState(nx, 1)
    end if
end sub

sub requestState(idx as integer, page as integer)
    node = m.data.getChild(idx)
    ' Asked for by the viewer (focused), or a prefetch (review C4).
    m.reqForFocus = (idx = m.stIdx)
    m.reqGen = m.reqGen + 1
    t = CreateObject("roSGNode", "ScChurchTask")
    t.stateName = node.title
    t.page = page
    t.perPage = 100
    t.gen = m.reqGen
    t.observeField("done", "onStateLoaded")
    m.reqTask = t
    m.reqIdx = idx
    t.control = "RUN"
    if idx = m.stIdx then paint()
end sub

sub onStateLoaded()
    t = m.reqTask
    m.reqTask = invalid
    idx = m.reqIdx
    if t = invalid or m.data = invalid or idx >= stateCount() then return
    node = m.data.getChild(idx)
    r = t.result
    page = t.page
    ' The church in focus before a reload of the state on screen (review C3).
    oldKey = ""
    if idx = m.stIdx then oldKey = churchKey(currentChurch())
    if t.ok and r <> invalid and r.scGen = m.reqGen and LCase(r.scState) = LCase(node.title)
        fillState(node, ScChildren(r), r.scPage, r.scPages, r.scPage = 1)
        node.scRetryAt = 0
        ' Still paging: the server's count is the best guide to how many.
        if r.scPage < r.scPages
            for each s in r.scStates
                if LCase(s.state) = LCase(node.title) then node.scCount = s.count
            end for
        end if
    else if page > 1
        node.scMoreFailed = true
    else if node.getChildCount() > 0
        ' A refresh that failed while the old rows are on screen: keep them
        ' and try again quietly in a minute (review-2 C4).
        node.scRetryAt = ScNowSecs() + 60
    else if m.reqForFocus or idx = m.stIdx
        node.scFailed = true
    else
        ' A prefetch nobody looked at: no error on screen; quietly again
        ' in a minute.
        node.scRetryAt = ScNowSecs() + 60
    end if
    if idx = m.stIdx
        ' Keep focus on the same church across a reload; else clamp.
        n = node.getChildCount()
        found = -1
        if oldKey <> ""
            for i = 0 to n - 1
                if churchKey(node.getChild(i)) = oldKey
                    found = i
                    exit for
                end if
            end for
        end if
        if found >= 0 then m.chIdx = found
        if m.chIdx > n - 1 then m.chIdx = n - 1
        if m.chIdx < 0 then m.chIdx = 0
        if n = 0 and m.zone = "churches" then m.zone = "states"
        paint()
        ' The panel follows whatever is now in focus: filled when it was
        ' waiting, redrawn when a reload moved or removed the church
        ' (C2, C3), left alone when the same church is still there.
        if m.panelEmpty or churchKey(currentChurch()) <> oldKey then showChurch()
    end if
    ' While the viewer is still moving through the states, the rest timer
    ' decides what to load next (review C5).
    if not m.moving then pump()
end sub

sub onRest()
    m.moving = false
    pump()
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
    ' A state not loaded yet: as many plain plates as it has churches (up
    ' to a column), the first saying why.
    ghosts = 0
    msg = ""
    if cc = 0 and st <> invalid
        ghosts = st.scCount
        if ghosts > m.chRows then ghosts = m.chRows
        if ghosts < 1 then ghosts = 1
        if st.scFailed
            msg = "Couldn't load. Press OK to try again."
        else if st.scPage >= 1
            ' Loaded, and nothing there (review C2).
            msg = "No churches listed here yet."
            ghosts = 1
        else
            msg = "Loading churches" + Chr(8230)
        end if
    end if
    ' A state with more pages: one more plate after the last row, saying
    ' what is happening there (review C1).
    more = ""
    if cc > 0 and st <> invalid and st.scPage < st.scPages
        if st.scMoreFailed
            more = "Couldn't load more. Press OK to try again."
        else
            more = "Loading more churches" + Chr(8230)
        end if
    end if
    rowsShown = cc
    if more <> "" then rowsShown = cc + 1
    m.chTop = windowTop(m.chIdx, m.chTop, m.chRows, rowsShown)
    for k = 0 to m.chRows - 1
        slot = m.chSlots[k]
        i = m.chTop + k
        slot.group.visible = (i < rowsShown or k < ghosts)
        if (cc = 0 and k < ghosts) or (more <> "" and i = cc)
            slot.bg.blendColor = m.t.cSurface2
            slot.name.color = m.t.cText3
            slot.city.text = ""
            if cc = 0
                if k = 0 then slot.name.text = msg else slot.name.text = ""
            else
                slot.name.text = more
            end if
        else if i < cc
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
    m.panelEmpty = (c = invalid)
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
    ' The cross-platform contract (api-contract.md, rule 5): only an https
    ' link on YouTube or Facebook becomes a code; anything else reads "No
    ' link for this church" (review S1; all 237 pass today).
    l = LCase(link)
    if Left(l, 8) <> "https://" then link = ""
    host = hostOf(link)
    where = ""
    if hostIs(host, "youtube.com") or host = "youtu.be"
        where = "Scan with your phone's camera to watch on YouTube"
    else if hostIs(host, "facebook.com")
        where = "Scan with your phone's camera to watch on Facebook"
    else
        link = ""
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
    ' The first call failed: OK tries again.
    if stateCount() = 0
        if key = "OK" and m.task = invalid and m.data = invalid
            if press then loadFirst()
            return true
        end if
        return false
    end if
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
            pump()
        else if key = "OK"
            ' "Couldn't load. Press OK to try again."
            st = currentState()
            if st <> invalid and st.scFailed
                st.scFailed = false
                paint()
                pump()
            end if
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
        ' A state bigger than one page: the next page as the end nears.
        pump()
    else if key = "OK"
        ' "Couldn't load more. Press OK to try again." (review C1)
        st = currentState()
        if st <> invalid and st.scMoreFailed
            st.scMoreFailed = false
            paint()
            pump()
        end if
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
    ' Load (or prefetch) only once focus rests here; until then a landing
    ' answer does not start the next request either (review C5).
    m.moving = true
    m.restTimer.control = "stop"
    m.restTimer.control = "start"
end sub
