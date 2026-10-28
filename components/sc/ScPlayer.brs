' ============================================================================
' ScPlayer.brs - live (C6), radio, and catch-up (C7) on one Video node.
' ============================================================================

sub init()
    ScEnsureGlobals()
    m.t = ScTheme()
    m.video = m.top.findNode("video")
    m.chrome = m.top.findNode("chrome")
    m.status = m.top.findNode("status")
    m.hideTimer = m.top.findNode("hideTimer")
    m.hideTimer.observeField("fire", "hideChrome")
    m.tick = m.top.findNode("tick")
    m.tick.observeField("fire", "onTick")

    ScPaint(m.top, [["black", "color", "cVideo"], ["bottomFade", "blendColor", "cScrim"], ["radioGround", "color", "cGround"]])
    m.top.findNode("topFade").blendColor = "0x000000FF"
    lab(m.top.findNode("liveKicker"), m.t.fXB, 20, m.t.cLive)
    lab(m.top.findNode("liveTitle"), m.t.fXB, 46, m.t.cText)
    lab(m.top.findNode("liveNow"), m.t.fSemi, 22, m.t.cText1)
    lab(m.top.findNode("clock"), m.t.fBold, 30, m.t.cText)
    lab(m.top.findNode("stripHint"), m.t.fBold, 22, m.t.cText2)
    lab(m.top.findNode("radioKicker"), m.t.fXB, 20, m.t.cLive)
    lab(m.top.findNode("radioName"), m.t.fXB, 64, m.t.cText)
    lab(m.top.findNode("radioHint"), m.t.fSemi, 21, m.t.cText2)
    lab(m.top.findNode("vodLine"), m.t.fBold, 22, m.t.cText1)
    lab(m.top.findNode("vodTitle"), m.t.fXB, 60, m.t.cText)
    lab(m.top.findNode("posText"), m.t.fBold, 24, m.t.cText)
    lab(m.top.findNode("durText"), m.t.fBold, 24, m.t.cText2)
    lab(m.top.findNode("nextKicker"), m.t.fXB, 16, m.t.cText2)
    lab(m.top.findNode("nextTitle"), m.t.fBold, 20, m.t.cText)
    lab(m.top.findNode("nextWhen"), m.t.fSemi, 17, m.t.cText2)
    lab(m.status, m.t.fBold, 30, m.t.cText)
    rp = m.top.findNode("radioPlate")
    rp.uri = ScShape("r22")
    rp.blendColor = m.t.cPlate
    bp = m.top.findNode("vodBadgePlate")
    bp.uri = ScShape("r7")
    bp.blendColor = m.t.cPlate
    m.barTrack = m.top.findNode("barTrack")
    m.barFill = m.top.findNode("barFill")
    m.knob = m.top.findNode("knob")
    m.barTrack.uri = ScShape("r2")
    m.barTrack.blendColor = "0xFFFFFF38"
    m.barFill.uri = ScShape("r2")
    m.barFill.blendColor = m.t.cAccent
    m.knob.uri = ScGlyph("circle26")
    np = m.top.findNode("nextPlate")
    np.uri = ScShape("r14")
    np.blendColor = "0x12141BD9"
    nc = m.top.findNode("nextCaps")
    nc.uri = ScShape("caps14")
    nc.blendColor = "0x12141BFF"

    buildControls()
    m.stripPool = []
    m.mode = ""
    m.errored = false
    m.ended = false
    m.resumeAt = 0
    m.ctl = 1
    m.video.observeField("state", "onState")
    m.video.notificationInterval = 1
    m.video.observeField("position", "onPosition")
end sub

sub lab(node as object, face as string, size as integer, color as string)
    node.font = ScFont(face, size)
    node.color = color
end sub

' ------------------------------------------------------------------ setup --

sub onItem()
    item = m.top.item
    if item = invalid then return
    m.mode = item.scKind
    m.channel = item.scChannel
    m.prog = item.scProg
    m.list = item.scList
    isLive = (m.mode = "live")
    isRadio = (m.mode = "radio")
    isVod = (m.mode = "catchup")

    m.top.findNode("radioCard").visible = isRadio
    m.top.findNode("liveTop").visible = isLive
    m.top.findNode("stripHint").visible = isLive
    m.top.findNode("strip").visible = isLive
    m.top.findNode("topFade").visible = isLive
    m.top.findNode("vod").visible = isVod
    m.top.findNode("bottomFade").visible = not isRadio
    m.top.findNode("clock").visible = isLive

    if isLive
        m.stripChannels = ScChildren(m.global.catTv)
        if m.channel <> invalid and m.channel.scKind = "lang" then m.stripChannels = ScChildren(m.global.catLang)
        m.playingIndex = 0
        for i = 0 to m.stripChannels.count() - 1
            if m.channel <> invalid and m.stripChannels[i].isSameNode(m.channel) then m.playingIndex = i
        end for
        m.stripIndex = m.playingIndex
        ScWantSched(m.channel)
        m.global.observeFieldScoped("schedVersion", "onSched")
        drawLiveTop()
        drawStrip()
    else if isRadio
        m.stations = ScChildren(m.global.catRadio)
        m.stationIndex = 0
        for i = 0 to m.stations.count() - 1
            if m.channel <> invalid and m.stations[i].isSameNode(m.channel) then m.stationIndex = i
        end for
        drawRadio()
    else if isVod
        m.dur = m.prog.scEnd - m.prog.scStart
        m.resumeAt = readPosition(m.prog.scRec)
        m.next = findNext()
        drawVod()
    end if
    playUrl(item.url, item.title, not isVod)
    showChrome()
    m.tick.control = "start"
end sub

sub playUrl(url as string, title as string, isLive as boolean)
    c = CreateObject("roSGNode", "ContentNode")
    c.url = url
    c.title = title
    c.streamFormat = "hls"
    c.live = isLive
    m.errored = false
    m.ended = false
    ' Position events from the stream being replaced are ignored until this
    ' one plays (review C10).
    m.armed = false
    m.status.text = "Loading" + Chr(8230)
    m.status.visible = true
    m.video.content = c
    m.video.control = "play"
end sub

' The one called by the scene before it removes this node: stop first, or
' the decoder stays held and the next Video cannot start.
sub teardown()
    savePosition()
    m.tick.control = "stop"
    m.hideTimer.control = "stop"
    m.video.unobserveField("state")
    m.video.unobserveField("position")
    m.global.unobserveFieldScoped("schedVersion")
    m.video.control = "stop"
end sub

' ----------------------------------------------------------------- video --

sub onState()
    st = m.video.state
    ' A failed stream moves itself on to "finished" a moment later; keep the
    ' error on screen (knowledge/dev-roku/video-node-moves-error-to-finished-on-its-own).
    if m.errored then return
    if st = "playing"
        m.armed = true
        m.status.visible = false
        if m.resumeAt > 0
            m.video.seek = m.resumeAt
            m.resumeAt = 0
        end if
    else if st = "buffering"
        m.status.text = "Loading" + Chr(8230)
        m.status.visible = true
    else if st = "error"
        m.errored = true
        ? "[ScPlayer] error "; m.video.errorCode; " "; m.video.errorMsg
        m.status.text = "This stream isn't available right now. Press Back to return."
        m.status.visible = true
        showChrome()
    else if st = "finished"
        if m.mode = "catchup" then onEnded()
    end if
    if m.mode = "catchup" then paintControls()
end sub

sub onPosition()
    if m.mode <> "catchup" or m.armed <> true then return
    d = duration()
    if d > 0 and m.video.position >= d - 1 then onEnded()
    drawBar()
end sub

function duration() as integer
    d = Int(m.video.duration)
    if d <= 0 then d = m.dur
    return d
end function

sub onEnded()
    if m.ended then return
    m.ended = true
    writePosition(m.prog.scRec, 0)
    if m.next <> invalid
        playNext()
    else
        m.global.closeOverlay = m.global.closeOverlay + 1
    end if
end sub

' ---------------------------------------------------------------- chrome --

sub showChrome()
    m.chrome.visible = true
    m.hideTimer.control = "stop"
    if not m.errored and m.mode <> "radio" then m.hideTimer.control = "start"
end sub

sub hideChrome()
    if m.errored then return
    ' A paused recording keeps its controls up.
    if m.mode = "catchup" and m.video.state = "paused" then return
    m.chrome.visible = false
end sub

sub onTick()
    m.top.findNode("clock").text = ScClock(ScNowSecs())
end sub

sub onSched()
    if m.mode <> "live" then return
    drawLiveTop()
    drawStrip()
end sub

' ------------------------------------------------------------------- live --

sub drawLiveTop()
    ch = m.channel
    if ch = invalid then return
    m.top.findNode("liveTitle").text = ch.title
    p = ScOnNow(ScSched(ch.scStream))
    line = "Live now"
    if p <> invalid
        if p.title = "" then line = "Live now · " + ScHourText(p.scStart) else line = p.title + " · until " + ScClock(p.scEnd)
    end if
    m.top.findNode("liveNow").text = line
end sub

' Up to seven logo cards, the highlighted one big (288x204) and white-
' captioned, bottom-aligned 80 px above the edge.
sub drawStrip()
    strip = m.top.findNode("strip")
    n = m.stripChannels.count()
    if n = 0 then return
    shown = 7
    if n < shown then shown = n
    first = m.stripIndex - 3
    if first > n - shown then first = n - shown
    if first < 0 then first = 0
    while m.stripPool.count() < shown
        g = strip.createChild("Group")
        sh = g.createChild("Poster")
        sh.uri = ScShape("shadow14")
        sh.blendColor = "0x000000CC"
        plate = g.createChild("Poster")
        plate.uri = ScShape("r14")
        plate.blendColor = m.t.cPlate
        logo = g.createChild("Poster")
        logo.loadDisplayMode = "scaleToFit"
        logo.loadWidth = 450
        logo.loadHeight = 320
        ' Dim under one veil, never Group opacity (grey frames round logos).
        veil = g.createChild("Poster")
        veil.uri = ScShape("r14")
        veil.blendColor = m.t.cGround
        veil.opacity = 0.3
        cap = g.createChild("Label")
        cap.wrap = false
        cap.ellipsisText = "..."
        m.stripPool.push({ group: g, shadow: sh, plate: plate, logo: logo, veil: veil, cap: cap })
    end while
    x = 0
    for i = 0 to m.stripPool.count() - 1
        it = m.stripPool[i]
        k = first + i
        if i >= shown or k >= n
            it.group.visible = false
        else
            ch = m.stripChannels[k]
            on = (k = m.stripIndex)
            if on
                w = 288 : h = 204 : fs = 22
            else
                w = 200 : h = 142 : fs = 18
            end if
            it.group.visible = true
            it.group.translation = [x, 1000 - h - 40]
            it.veil.visible = not on
            it.veil.width = w
            it.veil.height = h
            it.plate.width = w
            it.plate.height = h
            it.shadow.visible = on
            it.shadow.translation = [-36, -36 + 26]
            it.shadow.width = w + 72
            it.shadow.height = h + 72
            it.logo.width = Int(w * 0.9)
            it.logo.height = Int(h * 0.9)
            it.logo.translation = [Int(w * 0.05), Int(h * 0.05)]
            if it.logo.uri <> ch.scLogo then it.logo.uri = ch.scLogo
            it.cap.font = ScFont(m.t.fBold, fs)
            if on then it.cap.color = m.t.cText else it.cap.color = m.t.cText2
            it.cap.translation = [0, h + 8]
            it.cap.width = w
            it.cap.height = 30
            if k = m.playingIndex
                it.cap.text = "Watching · live"
            else
                p = ScOnNow(ScSched(ch.scStream))
                if p <> invalid and p.title <> "" then it.cap.text = p.title else it.cap.text = "Live now"
            end if
            x = x + w + 22
        end if
    end for
    if m.stripIndex = m.playingIndex
        m.top.findNode("stripHint").text = "Left / Right to switch · OK for the channel page"
    else
        m.top.findNode("stripHint").text = "OK to watch " + m.stripChannels[m.stripIndex].title
    end if
end sub

' ------------------------------------------------------------------ radio --

sub drawRadio()
    if m.stations.count() = 0 then return
    st = m.stations[m.stationIndex]
    m.channel = st
    m.top.findNode("radioLogo").uri = st.scLogo
    m.top.findNode("radioName").text = st.title
    m.top.findNode("radioKicker").text = "● LIVE RADIO · " + UCase(st.scLang)
end sub

' ---------------------------------------------------------------- catch-up --

sub buildControls()
    g = m.top.findNode("controls")
    ' -10, play/pause, +10, centred under the bar, 60 px above the edge.
    sizes = [76, 92, 76]
    total = 76 + 92 + 76 + 2 * 28
    x = Int((1920 - total) / 2)
    m.ctlNodes = []
    for i = 0 to 2
        d = sizes[i]
        grp = g.createChild("Group")
        grp.translation = [x, 1080 - 60 - 84 - Int(d / 2)]
        c = grp.createChild("Poster")
        c.uri = ScGlyph("circle" + d.toStr())
        c.width = d
        c.height = d
        if i = 1
            icon = grp.createChild("Poster")
            icon.width = 34
            icon.height = 34
            icon.translation = [Int((d - 34) / 2), Int((d - 34) / 2)]
            m.playIcon = icon
            labelNode = invalid
        else
            labelNode = grp.createChild("Label")
            labelNode.width = d
            labelNode.height = d
            labelNode.horizAlign = "center"
            labelNode.vertAlign = "center"
            labelNode.font = ScFont(m.t.fXB, 20)
            if i = 0 then labelNode.text = "−10" else labelNode.text = "+10"
        end if
        m.ctlNodes.push({ circle: c, label: labelNode })
        x = x + d + 28
    end for
end sub

' The highlighted control is white with dark ink; the others white 14 %.
' The next-episode card lights the same way (index 3).
sub paintControls()
    playing = (m.video.state = "playing" or m.video.state = "buffering")
    if playing then m.playIcon.uri = ScGlyph("pause") else m.playIcon.uri = ScGlyph("play")
    for i = 0 to 2
        it = m.ctlNodes[i]
        on = (i = m.ctl)
        if on then it.circle.blendColor = m.t.cFocus else it.circle.blendColor = m.t.cRaised
        if it.label <> invalid
            if on then it.label.color = m.t.cOnFocus else it.label.color = m.t.cText
        else
            if on then m.playIcon.blendColor = m.t.cOnFocus else m.playIcon.blendColor = m.t.cText
        end if
    end for
    plate = m.top.findNode("nextPlate")
    if m.ctl = 3 then plate.blendColor = m.t.cFocus else plate.blendColor = "0x12141BD9"
    nt = m.top.findNode("nextTitle")
    nk = m.top.findNode("nextKicker")
    nw = m.top.findNode("nextWhen")
    if m.ctl = 3
        nt.color = m.t.cOnFocus
        nk.color = "0x07080CB3"
        nw.color = "0x07080CB3"
        m.top.findNode("nextCaps").blendColor = m.t.cFocus
    else
        nt.color = m.t.cText
        nk.color = m.t.cText2
        nw.color = m.t.cText2
        m.top.findNode("nextCaps").blendColor = "0x12141BFF"
    end if
end sub

sub drawVod()
    p = m.prog
    ch = m.channel
    chName = ""
    logo = ""
    if ch <> invalid
        chName = ch.title
        logo = ch.scLogo
    end if
    m.top.findNode("vodBadgeLogo").uri = logo
    m.top.findNode("vodLine").text = chName + " · " + ScDayShort(p.scStart) + " · " + ScClock(p.scStart) + " · recording"
    m.top.findNode("vodTitle").text = ScProgLabel(p)
    card = m.top.findNode("nextCard")
    card.visible = (m.next <> invalid)
    if m.next <> invalid
        m.top.findNode("nextThumb").uri = m.next.scThumb
        m.top.findNode("nextTitle").text = ScProgLabel(m.next)
        m.top.findNode("nextWhen").text = ScDayShort(m.next.scStart) + " · " + ScClock(m.next.scStart)
    end if
    if m.ctl = 3 and m.next = invalid then m.ctl = 1
    drawBar()
    paintControls()
end sub

sub drawBar()
    d = duration()
    at = Int(m.video.position)
    if m.resumeAt > 0 then at = m.resumeAt
    m.top.findNode("posText").text = ScTimecode(at)
    m.top.findNode("durText").text = ScTimecode(d)
    f = 0.0
    if d > 0 then f = at / d
    if f > 1 then f = 1
    if f < 0 then f = 0
    w = Int(1460 * f)
    m.barFill.width = w
    m.knob.translation = [230 + w - 13, 887]
end sub

' The episode that comes after this one, from the list it was opened from
' (any order; programme nodes or cards carrying one in scRef): the earliest
' on the same channel that starts after this one ends and has aired.
function findNext() as dynamic
    if m.list = invalid or m.prog = invalid then return invalid
    best = invalid
    now = ScNowSecs()
    for each c in ScChildren(m.list)
        p = c
        if c.hasField("scCard") then p = c.scRef
        if p <> invalid and p.hasField("scStart")
            if p.scStream = m.prog.scStream and p.scStart >= m.prog.scEnd - 60 and p.scEnd <= now and p.url <> ""
                if best = invalid or p.scStart < best.scStart then best = p
            end if
        end if
    end for
    return best
end function

sub playNext()
    p = m.next
    if p = invalid then return
    savePosition()
    m.prog = p
    m.dur = p.scEnd - p.scStart
    m.resumeAt = readPosition(p.scRec)
    m.next = findNext()
    drawVod()
    playUrl(p.url, ScProgLabel(p), false)
    showChrome()
end sub

sub seekBy(delta as integer)
    d = duration()
    at = Int(m.video.position) + delta
    if at < 0 then at = 0
    if d > 0 and at > d - 2 then at = d - 2
    m.video.seek = at
    drawBar()
end sub

sub togglePause()
    if m.video.state = "paused"
        m.video.control = "resume"
    else
        m.video.control = "pause"
    end if
end sub

' -------------------------------------------------------------- positions --

' Registry "positions", keyed by recording id: the same store the old player
' resumed from.
function readPosition(rec as string) as integer
    if rec = "" then return 0
    sec = CreateObject("roRegistrySection", "positions")
    if not sec.Exists(rec) then return 0
    v = Int(Val(sec.Read(rec)))
    if v < 30 then return 0
    return v
end function

sub writePosition(rec as string, at as integer)
    if rec = "" then return
    sec = CreateObject("roRegistrySection", "positions")
    if at <= 0
        sec.Delete(rec)
    else
        sec.Write(rec, at.toStr())
    end if
    sec.Flush()
end sub

' Keep the place only in the middle of a recording.
sub savePosition()
    if m.mode <> "catchup" or m.prog = invalid then return
    at = Int(m.video.position)
    d = duration()
    if at > 30 and (d <= 0 or at < d - 60)
        writePosition(m.prog.scRec, at)
    else if d > 0 and at >= d - 60
        writePosition(m.prog.scRec, 0)
    end if
end sub

' ------------------------------------------------------------------- keys --

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return true
    if key = "back"
        m.global.closeOverlay = m.global.closeOverlay + 1
        return true
    end if
    ' The first key while the chrome is down only brings it up.
    if not m.chrome.visible and m.mode <> "radio"
        showChrome()
        if m.mode = "catchup" and (key = "play" or key = "rewind" or key = "fastforward")
            ' Transport keys still act: the viewer pressed them on purpose.
        else
            return true
        end if
    end if
    showChrome()

    if m.mode = "live"
        n = m.stripChannels.count()
        if key = "left" and m.stripIndex > 0
            m.stripIndex = m.stripIndex - 1
            drawStrip()
        else if key = "right" and m.stripIndex < n - 1
            m.stripIndex = m.stripIndex + 1
            drawStrip()
        else if key = "OK"
            if m.stripIndex = m.playingIndex
                m.global.openChannel = m.channel
            else
                m.playingIndex = m.stripIndex
                m.channel = m.stripChannels[m.playingIndex]
                ScWantSched(m.channel)
                drawLiveTop()
                drawStrip()
                playUrl(m.channel.url, m.channel.title, true)
            end if
        end if
        return true
    end if

    if m.mode = "radio"
        n = m.stations.count()
        if n > 0 and (key = "left" or key = "right")
            if key = "left" then m.stationIndex = (m.stationIndex - 1 + n) mod n else m.stationIndex = (m.stationIndex + 1) mod n
            drawRadio()
            playUrl(m.channel.url, m.channel.title, true)
        end if
        return true
    end if

    if m.mode = "catchup"
        last = 2
        if m.next <> invalid then last = 3
        if key = "left" and m.ctl > 0
            m.ctl = m.ctl - 1
        else if key = "right" and m.ctl < last
            m.ctl = m.ctl + 1
        else if key = "OK"
            if m.ctl = 0 then seekBy(-10)
            if m.ctl = 1 then togglePause()
            if m.ctl = 2 then seekBy(10)
            if m.ctl = 3 then playNext()
        else if key = "play"
            togglePause()
        else if key = "rewind" or key = "replay"
            seekBy(-10)
        else if key = "fastforward"
            seekBy(10)
        end if
        paintControls()
        return true
    end if
    return true
end function
