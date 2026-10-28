' ============================================================================
' ScRadio.brs - C4, the carousel. One focus: the carousel; Listen is drawn
' white as the action OK takes (the board's own reading), not a second stop.
'
' SLIDING, NOT SWAPPING (owner, 2026-10-28: "horizontal scrolling can have a
' good smooth animation"). Seven slots sit at positions -3..+3 round the
' middle; a move glides every slot one position over (place, size, opacity)
' in 0.32 s. The slot leaving at one edge is already invisible there (+-3 has
' opacity 0) and re-enters at the other edge with the next station. Each slot
' is authored at the middle's full 600x426 and SCALED to its position, so a
' station's logo decodes once at one size and never reloads mid-glide
' (knowledge/dev-roku/backdrop-poster-uri-swap-is-black-until-loaded).
' A press during a glide finishes it at once and starts the next.
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

    ' Position p = -3..+3: centre x, scale, opacity. The middle is 600x426;
    ' its neighbours 380x270 at 0.6 and 254x180 at 0.35, 40 px apart (board).
    m.W = 600
    m.H = 426
    m.cx = { "-3": 960 - 1160, "-2": 960 - 887, "-1": 960 - 530, "0": 960, "1": 960 + 530, "2": 960 + 887, "3": 960 + 1160 }
    m.sc = { "-3": 0.30, "-2": 0.4233, "-1": 0.6333, "0": 1.0, "1": 0.6333, "2": 0.4233, "3": 0.30 }
    m.op = { "-3": 0.0, "-2": 0.35, "-1": 0.6, "0": 1.0, "1": 0.6, "2": 0.35, "3": 0.0 }

    m.anim = m.top.createChild("Animation")
    m.anim.duration = 0.32
    m.anim.repeat = false
    m.anim.easeFunction = "outCubic"
    m.anim.observeField("state", "onAnimState")

    m.slots = []
    for i = 0 to 6
        g = m.slotsGroup.createChild("Group")
        g.id = "slot" + i.toStr()
        g.scaleRotateCenter = [m.W / 2, m.H / 2]
        sh = g.createChild("Poster")
        sh.uri = ScShape("shadow14")
        sh.blendColor = "0x000000CC"
        sh.translation = [-36, -36 + 40]
        sh.width = m.W + 72
        sh.height = m.H + 72
        plate = g.createChild("Poster")
        plate.uri = ScShape("r22")
        plate.blendColor = m.t.cPlate
        plate.width = m.W
        plate.height = m.H
        logo = g.createChild("Poster")
        logo.loadDisplayMode = "scaleToFit"
        logo.loadWidth = 450
        logo.loadHeight = 320
        logo.width = Int(m.W * 0.88)
        logo.height = Int(m.H * 0.88)
        logo.translation = [Int(m.W * 0.06), Int(m.H * 0.06)]
        tr = m.anim.createChild("Vector2DFieldInterpolator")
        tr.key = [0.0, 1.0]
        tr.fieldToInterp = g.id + ".translation"
        scl = m.anim.createChild("Vector2DFieldInterpolator")
        scl.key = [0.0, 1.0]
        scl.fieldToInterp = g.id + ".scale"
        opa = m.anim.createChild("FloatFieldInterpolator")
        opa.key = [0.0, 1.0]
        opa.fieldToInterp = g.id + ".opacity"
        ' pos: where it is (or is going); k: the station it shows.
        m.slots.push({ group: g, shadow: sh, logo: logo, tr: tr, scl: scl, opa: opa, pos: i - 3, k: 0 })
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

function posKey(p as integer) as string
    return p.toStr()
end function

function wrapIndex(k as integer) as integer
    n = m.stations.count()
    if n = 0 then return 0
    k = k mod n
    if k < 0 then k = k + n
    return k
end function

' Put a slot at a position at once (no glide).
sub place(slot as object, p as integer)
    slot.pos = p
    g = slot.group
    s = m.sc[posKey(p)]
    g.translation = [m.cx[posKey(p)] - m.W / 2, 460 - m.H / 2]
    g.scale = [s, s]
    g.opacity = m.op[posKey(p)]
    slot.shadow.visible = (p = 0)
end sub

sub bind(slot as object, k as integer)
    slot.k = k
    uri = m.stations[k].scLogo
    if slot.logo.uri <> uri then slot.logo.uri = uri
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
    m.anim.control = "stop"
    for each slot in m.slots
        place(slot, slot.pos)
        bind(slot, wrapIndex(m.index + slot.pos))
        ' Fewer than five stations: the outer slots stay empty.
        slot.group.visible = (n >= 5) or (Abs(slot.pos) <= Int((n - 1) / 2))
    end for
    m.hint.text = "Left / Right for the other " + (n - 1).toStr() + " stations"
    drawText()
end sub

sub drawText()
    st = m.stations[m.index]
    m.nameLabel.text = st.title
    m.kicker.text = "● LIVE RADIO · " + UCase(st.scLang)
    if Instr(1, LCase(st.title), "music") > 0 then m.kicker.text = "● LIVE RADIO · MUSIC"
end sub

' dir +1: the next station comes to the middle and everything glides left.
sub move(dir as integer)
    n = m.stations.count()
    if n = 0 then return
    ' A press mid-glide: finish it now, then start this one.
    if m.anim.state = "running"
        m.anim.control = "stop"
        for each slot in m.slots
            place(slot, slot.pos)
        end for
    end if
    m.index = wrapIndex(m.index + dir)
    for each slot in m.slots
        p = slot.pos - dir
        if p < -3 or p > 3
            ' Off one edge (already invisible there): re-enter at the other.
            p = -3 * Sgn(p)
            place(slot, p)
            bind(slot, wrapIndex(m.index + p))
            slot.tr.keyValue = [slot.group.translation, slot.group.translation]
            slot.scl.keyValue = [slot.group.scale, slot.group.scale]
            slot.opa.keyValue = [slot.group.opacity, slot.group.opacity]
        else
            s = m.sc[posKey(p)]
            slot.tr.keyValue = [slot.group.translation, [m.cx[posKey(p)] - m.W / 2, 460 - m.H / 2]]
            slot.scl.keyValue = [slot.group.scale, [s, s]]
            slot.opa.keyValue = [slot.group.opacity, m.op[posKey(p)]]
            slot.pos = p
            ' The shadow belongs to the middle only; it follows on arrival.
            slot.shadow.visible = false
        end if
        slot.group.visible = (n >= 5) or (Abs(slot.pos) <= Int((n - 1) / 2))
    end for
    drawText()
    m.anim.control = "start"
end sub

sub onAnimState()
    if m.anim.state = "stopped"
        for each slot in m.slots
            slot.shadow.visible = (slot.pos = 0)
        end for
    end if
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false
    n = m.stations.count()
    if n = 0 then return false
    if key = "left"
        move(-1)
        return true
    end if
    if key = "right"
        move(1)
        return true
    end if
    if key = "OK" or key = "play"
        m.global.playItem = ScLiveItem(m.stations[m.index])
        return true
    end if
    return false
end function
