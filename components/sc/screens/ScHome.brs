' ============================================================================
' ScHome.brs - C1. Two focus zones: the hero's buttons and the rows.
' ============================================================================

sub init()
    ScEnsureGlobals()
    m.t = ScTheme()
    ScPaint(m.top, [["veil", "color", "cGround"], ["fadeBottom", "blendColor", "cScrim"], ["fadeLeft", "blendColor", "cScrim"], ["heroTrack", "color", "cTrack"], ["heroFill", "color", "cAccent"]])

    m.backdrop = m.top.findNode("backdrop")
    m.previewImage = m.top.findNode("previewImage")
    m.previewLogo = m.top.findNode("previewLogo")
    m.previewPlate = m.top.findNode("previewPlate")
    m.previewCaps = m.top.findNode("previewCaps")
    m.previewBadge = m.top.findNode("previewBadge")
    m.heroChannel = m.top.findNode("heroChannel")
    m.heroTitle = m.top.findNode("heroTitle")
    m.heroTime = m.top.findNode("heroTime")
    m.heroTrack = m.top.findNode("heroTrack")
    m.heroFill = m.top.findNode("heroFill")
    m.heroLeft = m.top.findNode("heroLeft")
    m.onNowPlate = m.top.findNode("onNowPlate")
    m.onNowText = m.top.findNode("onNowText")
    m.buttonsGroup = m.top.findNode("buttons")
    m.rows = m.top.findNode("rows")
    m.empty = m.top.findNode("empty")

    shadow = m.top.findNode("previewShadow")
    shadow.uri = ScShape("shadow14")
    shadow.blendColor = "0x000000C0"
    shadow.translation = [-36, -36 + 30]
    shadow.width = 480 + 72
    shadow.height = 270 + 72
    m.previewPlate.uri = ScShape("r14")
    m.previewCaps.uri = ScShape("caps18")
    m.previewCaps.blendColor = m.t.cGround
    lp = m.top.findNode("previewLogoPlate")
    lp.uri = ScShape("r14")
    lp.blendColor = m.t.cPlate
    m.top.findNode("previewLogoCaps").uri = ScShape("caps14")
    badgePlate = m.top.findNode("previewBadgePlate")
    badgePlate.uri = ScShape("r7")
    badgePlate.blendColor = m.t.cPlate

    m.onNowPlate.uri = ScShape("r17")
    m.onNowPlate.blendColor = m.t.cLive
    m.top.findNode("onNowDot").visible = false
    m.onNowText.text = "● ON NOW"
    m.onNowText.translation = [14, 0]
    m.onNowText.font = ScFont(m.t.fXB, 18)
    m.onNowText.color = m.t.cText
    pw = ScTextW("● ON NOW", 18, "xb") + 30
    m.onNowText.width = pw
    m.onNowPlate.width = pw + 4
    m.heroChannel.translation = [pw + 18, 0]
    m.heroChannel.width = 600
    m.heroChannel.font = ScFont(m.t.fBold, 24)
    m.heroChannel.color = m.t.cText1
    m.heroTitle.font = ScFont(m.t.fXB, 72)
    m.heroTitle.color = m.t.cText
    m.heroTime.font = ScFont(m.t.fSemi, 24)
    m.heroTime.color = m.t.cText2
    m.heroLeft.font = ScFont(m.t.fSemi, 24)
    m.heroLeft.color = m.t.cText2
    m.empty.font = ScFont(m.t.fSemi, 27)
    m.empty.color = m.t.cText2

    ScSetTitle(m.top.findNode("title"), m.top.findNode("subtitle"), "Home", ScDayLong(ScNowSecs()))

    m.pills = []
    m.actions = []
    m.btnIndex = 0
    m.zone = "hero"
    m.heroCh = invalid
    m.seriesShown = false
    m.btnKey = ""

    ScInitRowList(m.rows, 598)
    m.rows.observeField("rowItemSelected", "onCardSelected")
    m.rows.observeField("rowItemFocused", "onCardFocused")
    m.top.observeField("focusedChild", "onFocusChild")

    m.global.observeField("catVersion", "rebuild")
    m.global.observeField("schedVersion", "onSched")
    m.global.observeField("minuteTick", "onMinute")
    rebuild()
end sub

sub onActive()
    if m.top.active then onMinute()
end sub

' ---------------------------------------------------------------- focus --

' The scene focuses this Group; a Group does not pass focus on.
sub onFocusChild()
    if m.top.hasFocus()
        if m.zone = "rows" and m.rows.visible
            m.rows.setFocus(true)
        else
            m.zone = "hero"
        end if
    end if
    paintPills()
end sub

sub paintPills()
    lit = m.top.hasFocus() and m.zone = "hero"
    for i = 0 to m.pills.count() - 1
        m.pills[i].lit = (lit and i = m.btnIndex)
    end for
end sub

' --------------------------------------------------------------- content --

function featured() as dynamic
    tv = m.global.catTv
    if tv = invalid or tv.getChildCount() = 0 then return invalid
    return tv.getChild(0)
end function

' The series row is the featured channel's (3ABN): exact title, its 21 days.
function seriesRowItems() as object
    out = []
    ch = featured()
    if ch = invalid then return out
    sched = ScSched(ch.scStream)
    if sched = invalid or sched.scSeries = invalid then return out
    for each s in ScChildren(sched.scSeries)
        latest = s.getChild(0)
        if latest <> invalid
            n = ScCardNode("frame", { w: 340, h: 191, thumb: latest.scThumb, logo: ch.scLogo, title: s.title, meta: s.scCount.toStr() + " recordings · latest " + ScWhen(latest.scStart), tag: ScDurBadge(latest.scEnd - latest.scStart), action: "series", ref: s, ref2: ch })
            out.push(n)
        end if
    end for
    return out
end function

sub rebuild()
    tv = ScChildren(m.global.catTv)
    lang = ScChildren(m.global.catLang)
    radio = ScChildren(m.global.catRadio)

    onNow = []
    i = 0
    for each ch in tv
        if i >= 10 then exit for
        onNow.push(ScOnNowCard(ch))
        i = i + 1
    end for
    channels = []
    for each ch in tv
        channels.push(ScLogoCard(ch, "channel", 240, 170))
    end for
    langs = []
    for each ch in lang
        langs.push(ScLogoCard(ch, "channel", 240, 170))
    end for
    radios = []
    for each ch in radio
        radios.push(ScLogoCard(ch, "radio", 240, 170))
    end for
    series = seriesRowItems()
    m.seriesShown = (series.count() > 0)

    ScApplyRows(m.rows, [
        { title: "On now", items: onNow, w: 384, h: 292, gap: 96 },
        { title: "Channels", items: channels, w: 240, h: 216, gap: 96 },
        { title: "In your language", items: langs, w: 240, h: 216, gap: 96 },
        { title: "Radio", items: radios, w: 240, h: 216, gap: 96 },
        { title: "Catch-up by series", items: series, w: 340, h: 267, gap: 96 }
    ])

    hasRows = (tv.count() + lang.count() + radio.count() > 0)
    m.empty.visible = (not hasRows and m.global.catVersion >= 3)
    m.empty.text = "mySDAtv isn't reachable right now. Check the connection, then open the channel again."

    if m.heroCh = invalid then m.heroCh = featured()
    ' Schedules for what is in view: the featured channel and the first
    ' cards of On now (more as focus moves along the row).
    if m.heroCh <> invalid then ScWantSched(m.heroCh)
    wantOnNow(0)
    showHero()
end sub

sub wantOnNow(fromIndex as integer)
    tv = m.global.catTv
    if tv = invalid then return
    for i = fromIndex to fromIndex + 3
        ch = tv.getChild(i)
        if ch <> invalid then ScWantSched(ch)
    end for
end sub

sub onSched()
    stream = m.global.schedLast
    ' The series row appears when the featured channel's schedule lands.
    f = featured()
    if f <> invalid and stream = f.scStream and not m.seriesShown
        rebuild()
        return
    end if
    refreshOnNow()
    if m.heroCh <> invalid and stream = m.heroCh.scStream then showHero()
end sub

sub onMinute()
    if not m.top.visible then return
    m.top.findNode("subtitle").text = ScDayLong(ScNowSecs())
    refreshOnNow()
    showHero()
end sub

sub refreshOnNow()
    root = m.rows.content
    if root = invalid then return
    row = root.getChild(0)
    if row = invalid then return
    for each card in ScChildren(row)
        if card.scRef <> invalid then ScFillOnNow(card, card.scRef)
    end for
end sub

' ------------------------------------------------------------------ hero --

sub showHero()
    ch = m.heroCh
    m.top.findNode("hero").visible = (ch <> invalid)
    if ch = invalid then return
    p = ScOnNow(ScSched(ch.scStream))
    m.heroChannel.text = ch.title
    if p <> invalid and p.title <> ""
        m.heroTitle.text = p.title
    else
        m.heroTitle.text = ch.title
    end if
    hasTime = (p <> invalid)
    m.heroTime.visible = hasTime
    m.heroTrack.visible = hasTime
    m.heroFill.visible = hasTime
    m.heroLeft.visible = hasTime
    if hasTime
        if p.title = "" then m.heroTime.text = "Live now · " + ScHourText(p.scStart) else m.heroTime.text = ScRange(p.scStart, p.scEnd)
        tw = ScTextW(m.heroTime.text, 24, "semi")
        m.heroTime.width = tw + 8
        m.heroTrack.translation = [tw + 18, 151]
        m.heroFill.translation = [tw + 18, 151]
        m.heroFill.width = Int(260 * ScProgress(p.scStart, p.scEnd))
        m.heroLeft.translation = [tw + 18 + 260 + 18, 136]
        m.heroLeft.width = 300
        m.heroLeft.text = ScLeft(p.scEnd)
    end if

    thumb = ""
    if p <> invalid then thumb = ScNowGrab(ScSched(ch.scStream), p)
    m.backdrop.visible = (thumb <> "")
    if thumb <> "" and m.backdrop.uri <> thumb then m.backdrop.uri = thumb
    if thumb <> ""
        m.previewPlate.blendColor = m.t.cSurface
        if m.previewImage.uri <> thumb then m.previewImage.uri = thumb
        m.previewImage.visible = true
        m.previewLogo.visible = false
        m.previewCaps.visible = true
        m.top.findNode("previewRamp").visible = false
        m.top.findNode("previewLogoPlate").visible = false
        m.top.findNode("previewLogoCaps").visible = false
        m.previewBadge.visible = true
        m.top.findNode("previewBadgeLogo").uri = ch.scLogo
    else
        ' No grab yet: the channel's tone with its logo whole in the middle -
        ' on a white plate when the logo sits on white, edge to edge with
        ' rounded corners when not (no white rim; owner, 2026-10-28).
        t = ScToneFor(ch)
        m.previewPlate.blendColor = t.b
        ramp = m.top.findNode("previewRamp")
        ramp.blendColor = t.a
        ramp.visible = true
        m.previewImage.visible = false
        lp = m.top.findNode("previewLogoPlate")
        lc = m.top.findNode("previewLogoCaps")
        lp.visible = t.white
        lc.visible = not t.white
        lc.blendColor = t.mid
        if t.white
            m.previewLogo.width = 268
            m.previewLogo.height = 190
            m.previewLogo.translation = [106, 40]
        else
            m.previewLogo.width = 298
            m.previewLogo.height = 211
            m.previewLogo.translation = [91, 30]
        end if
        m.previewLogo.uri = ch.scLogo
        m.previewLogo.visible = true
        m.previewCaps.visible = true
        m.previewBadge.visible = false
    end if
    buildButtons(ch, p)
end sub

sub buildButtons(ch as object, p as dynamic)
    labels = ["Watch live"]
    icons = ["play"]
    actions = ["live"]
    if p <> invalid and p.url <> ""
        labels.push("Start over")
        icons.push("")
        actions.push("startover")
    end if
    labels.push(ch.title + " channel")
    icons.push("")
    actions.push("channel")

    key = ""
    for each l in labels
        key = key + l + "|"
    end for
    if key = m.btnKey then return
    m.btnKey = key
    m.buttonsGroup.removeChildrenIndex(m.buttonsGroup.getChildCount(), 0)
    m.pills = []
    m.actions = actions
    x = 0
    for i = 0 to labels.count() - 1
        pill = m.buttonsGroup.createChild("ScPill")
        pill.icon = icons[i]
        pill.text = labels[i]
        pill.translation = [x, 0]
        ' Room for the focused pill's 1.06 lift.
        x = x + pill.w + 26
        m.pills.push(pill)
    end for
    if m.btnIndex > m.pills.count() - 1 then m.btnIndex = 0
    paintPills()
end sub

sub pressButton()
    ch = m.heroCh
    if ch = invalid or m.btnIndex >= m.actions.count() then return
    a = m.actions[m.btnIndex]
    if a = "live"
        m.global.playItem = ScLiveItem(ch)
    else if a = "startover"
        sched = ScSched(ch.scStream)
        p = ScOnNow(sched)
        if p <> invalid then m.global.playItem = ScCatchupItem(p, ch, sched.scToday)
    else if a = "channel"
        m.global.openChannel = ch
    end if
end sub

' ----------------------------------------------------------------- rows --

' The hero follows a channel card in focus (On now, Channels, languages).
sub onCardFocused()
    if not m.rows.hasFocus() then return
    at = m.rows.rowItemFocused
    if at <> invalid and at.count() = 2 and at[0] = 0 then wantOnNow(at[1])
    card = ScFocusedCard(m.rows)
    if card = invalid then return
    ref = card.scRef
    if ref <> invalid and (card.scAction = "live" or card.scAction = "channel") and ref.scKind <> "radio"
        if m.heroCh = invalid or not m.heroCh.isSameNode(ref)
            m.heroCh = ref
            ScWantSched(ref)
            showHero()
        end if
    end if
end sub

sub onCardSelected()
    card = ScSelectedCard(m.rows)
    if card = invalid then return
    if card.scAction = "series"
        s = card.scRef
        if s = invalid then return
        latest = s.getChild(0)
        if latest <> invalid then m.global.playItem = ScCatchupItem(latest, card.scRef2, s)
        return
    end if
    ScActivate(card)
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false
    if m.zone = "hero" and m.top.hasFocus()
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
                onCardFocused()
            end if
            return true
        end if
        if key = "OK"
            pressButton()
            return true
        end if
        return false
    end if
    ' The rows did not take Up: it was their first row.
    if key = "up" and m.zone = "rows"
        m.zone = "hero"
        ' Release the list first: setFocus on an ancestor of the focused
        ' node is a no-op (knowledge/dev-roku/setfocus-on-ancestor-does-not-reclaim).
        m.rows.setFocus(false)
        m.top.setFocus(true)
        paintPills()
        ScFocusChanged()
        return true
    end if
    return false
end function
