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

    lab(m.top.findNode("tabRec"), m.t.fXB, 20, m.t.cText2)
    lab(m.top.findNode("tabLive"), m.t.fXB, 20, m.t.cText2)
    tb = m.top.findNode("tabBar")
    tb.uri = ScShape("r2")
    tb.blendColor = m.t.cAccent

    buildControls()
    m.stripPool = []
    m.recPool = []
    m.recs = []
    m.recIndex = 0
    m.recList = invalid
    m.row = "live"
    m.rowPicked = false
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
        m.global.observeFieldScoped("sessionVersion", "onSession")
        ' Signed in but catch-up not known (or the last check failed): ask
        ' once per player. The strip shows meanwhile; the answer arrives as
        ' sessionVersion (no dialog) (review L1).
        access = m.global.catchupAccess
        if m.global.viewerSignedIn and (access = "" or access = "error") then m.global.checkAccess = m.global.checkAccess + 1
        m.row = "live"
        m.rowPicked = false
        ' Back from a recording: highlight the one just watched (review L2).
        m.recKeep = item.scRec
        refreshRecs()
        drawLiveTop()
        drawRows()
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
    m.global.unobserveFieldScoped("sessionVersion")
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
    refreshRecs()
    drawLiveTop()
    drawRows()
end sub

' Sign-in, sign-out or the catch-up answer changed.
sub onSession()
    if m.mode <> "live" then return
    refreshRecs()
    drawRows()
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
        cap = g.createChild("Label")
        cap.wrap = false
        cap.ellipsisText = "..."
        m.stripPool.push({ group: g, shadow: sh, plate: plate, logo: logo, cap: cap })
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
            ' Dim by darkening the plate and logo together (ScScaleColor): never
            ' Group opacity (grey frames) nor a veil (a light seam at the edge).
            shade = "0xFFFFFFFF"
            if not on then shade = ScScaleColor("0xFFFFFFFF", 0.72)
            it.plate.blendColor = shade
            it.logo.blendColor = shade
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
        hint = "Left / Right to switch · OK for the channel page"
    else
        hint = "OK to watch " + m.stripChannels[m.stripIndex].title
    end if
    if m.recs.count() > 0 then hint = hint + " · Up for recordings"
    m.top.findNode("stripHint").text = hint
end sub

' --------------------------------------------------------- recordings row --

' Catch-up is on this account: signed in and check-purchase said yes.
function canWatchRecordings() as boolean
    return (m.global.viewerSignedIn = true and m.global.catchupAccess = "yes")
end function

' The playing channel's recordings (schedule node scRecent, newest first),
' or none when the viewer has no catch-up. Keeps the highlighted recording
' across a reload; shows the Recordings row unless the viewer has already
' used the strip (it never swaps under a moving hand).
sub refreshRecs()
    keep = ""
    if m.recIndex < m.recs.count() then keep = m.recs[m.recIndex].scRec
    if keep = "" and m.recKeep <> invalid then keep = m.recKeep
    m.recs = []
    m.recList = invalid
    if m.channel <> invalid and canWatchRecordings()
        sched = ScSched(m.channel.scStream)
        if sched <> invalid and sched.hasField("scRecent") and sched.scRecent <> invalid
            m.recList = sched.scRecent
            m.recs = ScChildren(sched.scRecent)
        end if
    end if
    m.recIndex = 0
    for i = 0 to m.recs.count() - 1
        if keep <> "" and m.recs[i].scRec = keep
            m.recIndex = i
            m.recKeep = ""
        end if
    end for
    if m.recs.count() = 0
        m.row = "live"
    else if not m.rowPicked
        m.row = "rec"
    end if
end sub

sub drawRows()
    hasRecs = (m.recs.count() > 0)
    m.top.findNode("tabs").visible = hasRecs
    m.top.findNode("strip").visible = (m.row = "live")
    m.top.findNode("recRow").visible = (m.row = "rec")
    if hasRecs then drawTabs()
    if m.row = "rec" then drawRecRow() else drawStrip()
end sub

' "RECORDINGS   LIVE CHANNELS": the shown row white over an accent bar.
sub drawTabs()
    a = m.top.findNode("tabRec")
    b = m.top.findNode("tabLive")
    wa = ScTextW(a.text, 20, "xb")
    wb = ScTextW(b.text, 20, "xb")
    a.width = wa + 4
    b.width = wb + 4
    b.translation = [wa + 40, 0]
    bar = m.top.findNode("tabBar")
    if m.row = "rec"
        a.color = m.t.cText
        b.color = m.t.cText2
        bar.translation = [0, 38]
        bar.width = wa
    else
        a.color = m.t.cText2
        b.color = m.t.cText
        bar.translation = [wa + 40, 38]
        bar.width = wb
    end if
end sub

' Up to six recording cards, the highlighted one big (336x189) with the
' app's focus - a soft white glow behind it, no border (owner, 2026-11-12,
' "on every card") - and the rest 240x135, darkened. Bottom-aligned 150 px
' above the edge, title and when under each, at sizes that hold at 720p
' (review M2, M3).
sub drawRecRow()
    row = m.top.findNode("recRow")
    n = m.recs.count()
    if n = 0 then return
    shown = 6
    if n < shown then shown = n
    first = m.recIndex - 2
    if first > n - shown then first = n - shown
    if first < 0 then first = 0
    while m.recPool.count() < shown
        g = row.createChild("Group")
        sh = g.createChild("Poster")
        sh.uri = ScShape("glow14")
        sh.blendColor = "0xFFFFFF66"
        plate = g.createChild("Poster")
        plate.uri = ScShape("r14")
        thumb = g.createChild("Poster")
        thumb.loadDisplayMode = "scaleToZoom"
        thumb.loadWidth = 320
        thumb.loadHeight = 180
        logo = g.createChild("Poster")
        logo.loadDisplayMode = "scaleToFit"
        logo.loadWidth = 450
        logo.loadHeight = 320
        cap = g.createChild("Label")
        cap.wrap = false
        cap.ellipsisText = "..."
        cap.height = 32
        meta = g.createChild("Label")
        meta.wrap = false
        meta.ellipsisText = "..."
        meta.height = 28
        m.recPool.push({ group: g, shadow: sh, plate: plate, thumb: thumb, logo: logo, cap: cap, meta: meta })
    end while
    chLogo = ""
    if m.channel <> invalid then chLogo = m.channel.scLogo
    x = 0
    for i = 0 to m.recPool.count() - 1
        it = m.recPool[i]
        k = first + i
        if i >= shown or k >= n
            it.group.visible = false
        else
            p = m.recs[k]
            on = (k = m.recIndex)
            if on
                w = 336 : h = 189 : fs = 23 : ms = 20
            else
                w = 240 : h = 135 : fs = 20 : ms = 19
            end if
            it.group.visible = true
            it.group.translation = [x, 930 - h]
            shade = "0xFFFFFFFF"
            if not on then shade = ScScaleColor("0xFFFFFFFF", 0.72)
            hasThumb = (p.scThumb <> "")
            ' A grab sits on a dark plate 3 px bigger (round corners over the
            ' video); a logo card (no grab yet) on the white plate.
            if hasThumb
                it.plate.blendColor = m.t.cSurface
            else
                it.plate.blendColor = shade
            end if
            it.plate.width = w
            it.plate.height = h
            it.shadow.visible = on
            it.shadow.translation = [-30, -30 + 6]
            it.shadow.width = w + 60
            it.shadow.height = h + 60
            it.thumb.visible = hasThumb
            it.logo.visible = not hasThumb
            if hasThumb
                it.thumb.translation = [3, 3]
                it.thumb.width = w - 6
                it.thumb.height = h - 6
                it.thumb.blendColor = shade
                if it.thumb.uri <> p.scThumb then it.thumb.uri = p.scThumb
            else
                it.logo.width = Int(w * 0.8)
                it.logo.height = Int(h * 0.8)
                it.logo.translation = [Int(w * 0.1), Int(h * 0.1)]
                it.logo.blendColor = shade
                if it.logo.uri <> chLogo then it.logo.uri = chLogo
            end if
            it.cap.font = ScFont(m.t.fBold, fs)
            it.meta.font = ScFont(m.t.fSemi, ms)
            if on
                it.cap.color = m.t.cText
                it.meta.color = m.t.cText1
            else
                it.cap.color = m.t.cText2
                it.meta.color = m.t.cText3
            end if
            it.cap.translation = [0, h + 8]
            it.cap.width = w
            it.cap.text = ScProgLabel(p)
            it.meta.translation = [0, h + 40]
            it.meta.width = w
            it.meta.text = ScWhen(p.scStart)
            x = x + w + 22
        end if
    end for
    m.top.findNode("stripHint").text = "Left / Right to choose · OK to watch this recording · Down for live channels"
end sub

' OK on a recording: the catch-up player, through the scene's gate; Back
' from it comes back to this channel live.
sub playRecording()
    if m.recIndex >= m.recs.count() then return
    p = m.recs[m.recIndex]
    item = ScCatchupItem(p, m.channel, m.recList)
    item.scBackTo = m.channel
    m.global.playItem = item
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
    ' Any key, even the one that only brings the chrome back, means the
    ' viewer is here: a late catch-up answer no longer swaps the row (L3).
    if m.mode = "live" then m.rowPicked = true
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
        if m.recs.count() > 0 and (key = "up" or key = "down")
            if key = "down" then m.row = "live" else m.row = "rec"
            drawRows()
            return true
        end if
        if m.row = "rec"
            nr = m.recs.count()
            if key = "left" and m.recIndex > 0
                m.recIndex = m.recIndex - 1
                drawRecRow()
            else if key = "right" and m.recIndex < nr - 1
                m.recIndex = m.recIndex + 1
                drawRecRow()
            else if key = "OK"
                playRecording()
            end if
            return true
        end if
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
                ' Another channel's recordings: nothing to keep (recording
                ' ids are start times and repeat across channels).
                m.recs = []
                m.recKeep = ""
                refreshRecs()
                drawLiveTop()
                drawRows()
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
