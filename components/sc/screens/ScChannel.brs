' ============================================================================
' ScChannel.brs - C2. Two focus zones: the buttons and the rows.
' ============================================================================

sub init()
    ScEnsureGlobals()
    m.t = ScTheme()
    ScPaint(m.top, [["fadeBottom", "blendColor", "cScrim"]])
    m.backdrop = m.top.findNode("backdrop")
    m.plate = m.top.findNode("plate")
    m.logo = m.top.findNode("logo")
    m.nameLabel = m.top.findNode("name")
    m.liveLine = m.top.findNode("liveLine")
    m.metaLabel = m.top.findNode("meta")
    m.buttonsGroup = m.top.findNode("buttons")
    m.rows = m.top.findNode("rows")
    m.note = m.top.findNode("note")

    m.plate.uri = ScShape("r22")
    caps = m.top.findNode("logoCaps")
    caps.uri = ScShape("caps18")
    caps.blendColor = m.t.cGround
    m.plate.blendColor = m.t.cPlate
    sh = m.top.findNode("plateShadow")
    sh.uri = ScShape("shadow14")
    sh.blendColor = "0x000000B0"
    sh.translation = [184 - 36, 130 - 36 + 30]
    sh.width = 360 + 72
    sh.height = 256 + 72
    m.nameLabel.font = ScFont(m.t.fXB, 72)
    m.nameLabel.color = m.t.cText
    m.liveLine.font = ScFont(m.t.fSemi, 25)
    m.liveLine.color = m.t.cText1
    liveTag = m.top.findNode("liveTag")
    liveTag.font = ScFont(m.t.fXB, 25)
    liveTag.color = m.t.cLive
    tagW = ScTextW("● LIVE", 25, "xb")
    liveTag.width = tagW + 4
    m.liveLine.translation = [588 + tagW + 14, 222]
    m.metaLabel.font = ScFont(m.t.fSemi, 22)
    m.metaLabel.color = m.t.cText2
    m.note.font = ScFont(m.t.fSemi, 24)
    m.note.color = m.t.cText2

    m.pills = []
    m.actions = []
    m.btnIndex = 0
    m.zone = "buttons"
    m.placed = false

    ScInitRowList(m.rows, 470)
    m.rows.observeField("rowItemSelected", "onCardSelected")
    m.top.observeField("focusedChild", "onFocusChild")
    m.global.observeField("schedVersion", "onSched")
    m.global.observeField("minuteTick", "onMinute")
end sub

sub onChannel()
    ch = m.top.channel
    if ch = invalid then return
    m.zone = "buttons"
    m.btnIndex = 0
    m.placed = false
    m.logo.uri = ch.scLogo
    m.nameLabel.text = ch.title
    kind = "Television"
    if ch.scKind = "lang" then kind = "Languages"
    m.metaLabel.text = kind + " · " + ch.scLang + " · 21 days of recordings"
    ScSetTitle(m.top.findNode("title"), m.top.findNode("subtitle"), "Channels", "/ " + ch.title)
    m.rows.content = invalid
    m.rows.visible = false
    ScWantSched(ch)
    draw()
end sub

sub onSched()
    ch = m.top.channel
    if ch = invalid or m.global.schedLast <> ch.scStream then return
    draw()
end sub

sub onMinute()
    if m.top.visible then drawTop()
end sub

sub draw()
    drawTop()
    drawRows()
end sub

sub drawTop()
    ch = m.top.channel
    if ch = invalid then return
    sched = ScSched(ch.scStream)
    p = ScOnNow(sched)
    if p = invalid
        m.liveLine.text = ""
    else if p.title = ""
        m.liveLine.text = "Live now · " + ScHourText(p.scStart)
    else
        m.liveLine.text = p.title + " · until " + ScClock(p.scEnd)
    end if
    thumb = ""
    if p <> invalid then thumb = ScNowGrab(sched, p)
    m.backdrop.visible = (thumb <> "")
    if thumb <> "" and m.backdrop.uri <> thumb then m.backdrop.uri = thumb

    labels = ["Watch live"]
    icons = ["play"]
    actions = ["live"]
    if p <> invalid and p.url <> ""
        labels.push("Start over")
        icons.push("")
        actions.push("startover")
    end if
    if m.actions.count() <> actions.count()
        m.buttonsGroup.removeChildrenIndex(m.buttonsGroup.getChildCount(), 0)
        m.pills = []
        x = 0
        for i = 0 to labels.count() - 1
            pill = m.buttonsGroup.createChild("ScPill")
            pill.h = 70
            pill.fontSize = 25
            pill.icon = icons[i]
            pill.text = labels[i]
            pill.translation = [x, 0]
            x = x + pill.w + 26
            m.pills.push(pill)
        end for
        m.actions = actions
        if m.btnIndex > m.pills.count() - 1 then m.btnIndex = 0
    end if
    paintPills()
end sub

sub drawRows()
    ch = m.top.channel
    if ch = invalid then return
    sched = ScSched(ch.scStream)
    if sched = invalid
        m.note.text = "Loading today's schedule" + Chr(8230)
        m.note.visible = true
        return
    end if
    m.note.visible = false
    now = ScNowSecs()
    today = []
    liveAt = 0
    for each p in ScChildren(sched.scToday)
        if p.scEnd <= now
            n = ScRecordingCard(p, ch, 340, 191, "REPLAY", ScRange(p.scStart, p.scEnd))
        else if p.scStart <= now
            n = ScRecordingCard(p, ch, 340, 191, "● LIVE", ScRange(p.scStart, p.scEnd))
            n.scTagLive = true
            n.scThumb = ScNowGrab(sched, p)
            n.scAction = "live"
            n.scRef = ch
            liveAt = today.count()
        else
            n = ScCardNode("later", { w: 340, h: 191, logo: ch.scLogo, title: ScProgLabel(p), meta: ScRange(p.scStart, p.scEnd), tag: "LATER", action: "live", ref: ch })
        end if
        today.push(n)
    end for
    week = []
    for each p in ScChildren(sched.scWeek)
        n = ScRecordingCard(p, ch, 340, 191, "", ScWhen(p.scStart))
        n.scInside = true
        week.push(n)
    end for
    ScApplyRows(m.rows, [
        { title: "Today on " + ch.title, items: today, w: 340, h: 267, gap: 96 },
        { title: "Earlier this week", items: week, w: 340, h: 191, gap: 96 }
    ])
    ' Open the day on what is on now, not on 6 AM.
    if not m.placed and today.count() > 0
        m.rows.jumpToRowItem = [0, liveAt]
        m.placed = true
    end if
end sub

' ---------------------------------------------------------------- focus --

sub onFocusChild()
    if m.top.hasFocus()
        if m.zone = "rows" and m.rows.visible
            m.rows.setFocus(true)
        else
            m.zone = "buttons"
        end if
    end if
    paintPills()
end sub

sub paintPills()
    lit = m.top.hasFocus() and m.zone = "buttons"
    for i = 0 to m.pills.count() - 1
        m.pills[i].lit = (lit and i = m.btnIndex)
    end for
end sub

sub onCardSelected()
    ScActivate(ScSelectedCard(m.rows))
end sub

sub pressButton()
    ch = m.top.channel
    if ch = invalid or m.btnIndex >= m.actions.count() then return
    a = m.actions[m.btnIndex]
    if a = "live"
        m.global.playItem = ScLiveItem(ch)
    else if a = "startover"
        sched = ScSched(ch.scStream)
        p = ScOnNow(sched)
        if p <> invalid then m.global.playItem = ScCatchupItem(p, ch, sched.scToday)
    end if
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false
    if m.zone = "buttons" and m.top.hasFocus()
        if key = "left"
            if m.btnIndex > 0
                m.btnIndex = m.btnIndex - 1
                paintPills()
                return true
            end if
            return false
        end if
        if key = "right"
            if m.btnIndex < m.pills.count() - 1
                m.btnIndex = m.btnIndex + 1
                paintPills()
            end if
            return true
        end if
        if key = "down"
            if m.rows.visible
                m.zone = "rows"
                m.rows.setFocus(true)
                paintPills()
                ScFocusChanged()
            end if
            return true
        end if
        if key = "OK"
            pressButton()
            return true
        end if
        return false
    end if
    if key = "up" and m.zone = "rows"
        m.zone = "buttons"
        m.rows.setFocus(false)
        m.top.setFocus(true)
        paintPills()
        ScFocusChanged()
        return true
    end if
    return false
end function
