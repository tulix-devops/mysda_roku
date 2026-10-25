' ============================================================================
' ScCatchup.brs - C5. One focus zone: the rows.
' ============================================================================

sub init()
    ScEnsureGlobals()
    m.t = ScTheme()
    m.rows = m.top.findNode("rows")
    m.note = m.top.findNode("note")
    m.note.font = ScFont(m.t.fSemi, 24)
    m.note.color = m.t.cText2
    ScSetTitle(m.top.findNode("title"), m.top.findNode("subtitle"), "Catch-up", "21 days of every channel")
    ScInitRowList(m.rows, 214)
    m.rows.observeField("rowItemSelected", "onCardSelected")
    m.top.observeField("focusedChild", "onFocusChild")
    m.global.observeField("schedVersion", "onSched")
    m.global.observeField("catVersion", "onSched")
    m.dirty = true
    m.asked = false
end sub

sub onActive()
    if not m.top.active then return
    askSchedules()
    if m.dirty then rebuild()
end sub

' The 3ABN family's schedules (the channels with real titles), Television
' first, at most six.
sub askSchedules()
    n = 0
    for each ch in ScAllChannels()
        if n >= 6 then exit for
        if Left(UCase(ch.title), 4) = "3ABN"
            ScWantSched(ch)
            n = n + 1
        end if
    end for
    m.asked = true
end sub

sub onSched()
    ' Rebuilding a list the viewer is not looking at would only cost; it is
    ' rebuilt when the screen next shows.
    m.dirty = true
    if m.top.active and m.top.visible then rebuild()
end sub

sub rebuild()
    m.dirty = false
    if m.top.active and not m.asked then askSchedules()
    now = ScNowSecs()
    dayStart = ScDayStart(ScLocalParts(now).days)

    ' Earlier today: every loaded channel's aired programmes, newest first.
    earlier = []
    seriesAll = []
    for each sched in ScChildren(m.global.schedStore)
        ch = ScChannelByStream(sched.scStream)
        if ch <> invalid
            for each p in ScChildren(sched.scToday)
                if p.scEnd <= now and p.scStart >= dayStart and p.scThumb <> ""
                    earlier.push({ p: p, ch: ch })
                end if
            end for
            for each s in ScChildren(sched.scSeries)
                seriesAll.push({ s: s, ch: ch })
            end for
        end if
    end for
    sortedEarlier = sortNewest(earlier)

    earlierCards = []
    for each e in sortedEarlier
        if earlierCards.count() >= 20 then exit for
        label = e.p.title
        if label = "" then label = e.ch.title + " · " + ScHourText(e.p.scStart) else label = label + " · " + ScClock(e.p.scStart)
        n = ScRecordingCard(e.p, e.ch, 318, 179, ScDurBadge(e.p.scEnd - e.p.scStart), "")
        n.title = label
        n.scTagPos = "br"
        earlierCards.push(n)
    end for

    rows = [{ title: "Earlier today · every channel, newest first", items: earlierCards, w: 318, h: 219, gap: 90 }]
    ' Series: most recorded first, across the loaded channels.
    seriesSorted = sortSeries(seriesAll)
    k = 0
    for each e in seriesSorted
        if k >= 8 then exit for
        cards = []
        for each p in ScChildren(e.s)
            n = ScRecordingCard(p, e.ch, 318, 179, ScDurBadge(p.scEnd - p.scStart), "")
            n.title = ScWhen(p.scStart)
            n.scTagPos = "br"
            n.scAction = "episode"
            n.scRef2 = e.ch
            cards.push(n)
        end for
        rows.push({ title: e.s.title + " · " + e.s.scCount.toStr() + " recordings in the last 21 days", items: cards, w: 318, h: 219, gap: 90, series: e.s })
        k = k + 1
    end for
    ScApplyRows(m.rows, rows)

    has = (m.rows.content <> invalid and m.rows.content.getChildCount() > 0 and m.rows.visible)
    m.note.visible = not has
    if not has then m.note.text = "Loading recordings" + Chr(8230)
end sub

function sortNewest(list as object) as object
    out = []
    for each e in list
        i = out.count()
        out.push(e)
        while i > 0 and out[i - 1].p.scStart < e.p.scStart
            out[i] = out[i - 1]
            i = i - 1
        end while
        out[i] = e
    end for
    return out
end function

function sortSeries(list as object) as object
    out = []
    for each e in list
        i = out.count()
        out.push(e)
        while i > 0 and out[i - 1].s.scCount < e.s.scCount
            out[i] = out[i - 1]
            i = i - 1
        end while
        out[i] = e
    end for
    return out
end function

sub onFocusChild()
    if m.top.hasFocus() and m.rows.visible then m.rows.setFocus(true)
end sub

' A series card plays that episode, with the series as the "next" list.
sub onCardSelected()
    card = ScSelectedCard(m.rows)
    if card = invalid then return
    if card.scAction = "episode"
        p = card.scRef
        series = invalid
        if p <> invalid then series = p.getParent()
        if p <> invalid then m.global.playItem = ScCatchupItem(p, card.scRef2, series)
        return
    end if
    ScActivate(card)
end sub
