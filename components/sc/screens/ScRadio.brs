' ============================================================================
' ScRadio.brs - C4. One focus: the carousel. Listen is drawn white as the
' action OK takes (the board's own reading), and is not a second stop.
' ============================================================================

sub init()
    ScEnsureGlobals()
    m.t = ScTheme()
    m.slotsGroup = m.top.findNode("slots")
    m.kicker = m.top.findNode("kicker")
    m.nameLabel = m.top.findNode("name")
    m.hint = m.top.findNode("hint")
    m.empty = m.top.findNode("empty")
    m.kicker.font = ScFont(m.t.fXB, 20)
    m.kicker.color = m.t.cLive
    m.nameLabel.font = ScFont(m.t.fXB, 64)
    m.nameLabel.color = m.t.cText
    m.hint.font = ScFont(m.t.fSemi, 21)
    m.hint.color = m.t.cText2
    m.empty.font = ScFont(m.t.fSemi, 27)
    m.empty.color = m.t.cText2

    ' Slot -2 .. +2 around the middle: width, height, opacity.
    m.specs = [[254, 180, 0.35], [380, 270, 0.6], [600, 426, 1.0], [380, 270, 0.6], [254, 180, 0.35]]
    gap = 40
    ' The middle slot is centred on x 960; the rest are laid out from it.
    xs = [0, 0, 960 - 300, 0, 0]
    xs[1] = xs[2] - gap - 380
    xs[0] = xs[1] - gap - 254
    xs[3] = xs[2] + 600 + gap
    xs[4] = xs[3] + 380 + gap
    m.slots = []
    for i = 0 to 4
        sp = m.specs[i]
        g = m.slotsGroup.createChild("Group")
        g.translation = [xs[i], 460 - Int(sp[1] / 2)]
        g.opacity = sp[2]
        if i = 2
            sh = g.createChild("Poster")
            sh.uri = ScShape("shadow14")
            sh.blendColor = "0x000000CC"
            sh.translation = [-36, -36 + 40]
            sh.width = sp[0] + 72
            sh.height = sp[1] + 72
        end if
        plate = g.createChild("Poster")
        plate.uri = ScShape("r22")
        plate.blendColor = m.t.cPlate
        plate.width = sp[0]
        plate.height = sp[1]
        logo = g.createChild("Poster")
        logo.loadDisplayMode = "scaleToFit"
        logo.loadWidth = 450
        logo.loadHeight = 320
        logo.width = Int(sp[0] * 0.88)
        logo.height = Int(sp[1] * 0.88)
        logo.translation = [Int(sp[0] * 0.06), Int(sp[1] * 0.06)]
        m.slots.push({ group: g, logo: logo })
    end for

    m.listen = m.top.findNode("listenRow").createChild("ScPill")
    m.listen.h = 70
    m.listen.fontSize = 25
    m.listen.icon = "play"
    m.listen.text = "Listen"
    m.listen.selected = true
    m.listen.translation = [Int((1920 - m.listen.w) / 2), 0]

    m.index = 0
    m.stations = []
    m.global.observeField("catVersion", "rebuild")
    rebuild()
end sub

sub onActive()
end sub

sub rebuild()
    m.stations = ScChildren(m.global.catRadio)
    n = m.stations.count()
    ScSetTitle(m.top.findNode("title"), m.top.findNode("subtitle"), "Radio", n.toStr() + " stations")
    has = (n > 0)
    m.slotsGroup.visible = has
    m.kicker.visible = has
    m.nameLabel.visible = has
    m.listen.visible = has
    m.hint.visible = has
    m.empty.visible = not has and m.global.catVersion >= 3
    m.empty.text = "The radio stations aren't reachable right now."
    if not has then return
    ' Prefetch every logo at the slots' load size.
    pf = m.top.findNode("prefetch")
    pf.removeChildrenIndex(pf.getChildCount(), 0)
    for each st in m.stations
        p = pf.createChild("Poster")
        p.loadWidth = 450
        p.loadHeight = 320
        p.width = 45
        p.height = 32
        p.uri = st.scLogo
    end for
    if m.index > n - 1 then m.index = 0
    m.hint.text = "Left / Right for the other " + (n - 1).toStr() + " stations"
    draw()
end sub

sub draw()
    n = m.stations.count()
    if n = 0 then return
    for i = 0 to 4
        k = (m.index + i - 2) mod n
        if k < 0 then k = k + n
        slot = m.slots[i]
        ' Fewer than five stations: the outer slots stay empty.
        show = (n >= 5) or (Abs(i - 2) <= Int((n - 1) / 2))
        slot.group.visible = show
        uri = m.stations[k].scLogo
        if show and slot.logo.uri <> uri then slot.logo.uri = uri
    end for
    st = m.stations[m.index]
    m.nameLabel.text = st.title
    m.kicker.text = "● LIVE RADIO · " + UCase(st.scLang)
    if Instr(1, LCase(st.title), "music") > 0 then m.kicker.text = "● LIVE RADIO · MUSIC"
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false
    n = m.stations.count()
    if n = 0 then return false
    if key = "left"
        m.index = (m.index - 1 + n) mod n
        draw()
        return true
    end if
    if key = "right"
        m.index = (m.index + 1) mod n
        draw()
        return true
    end if
    if key = "OK" or key = "play"
        m.global.playItem = ScLiveItem(m.stations[m.index])
        return true
    end if
    return false
end function
