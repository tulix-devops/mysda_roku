sub init()
    m.top.functionName = "work"
end sub

sub work()
    stream = m.top.stream
    out = CreateObject("roSGNode", "ContentNode")
    out.id = stream
    out.addFields({ scStream: stream, scAt: ScNowSecs(), scOk: false, scTitled: false })
    out.addField("scToday", "node", false)
    out.addField("scWeek", "node", false)
    out.addField("scSeries", "node", false)
    out.scToday = CreateObject("roSGNode", "ContentNode")
    out.scWeek = CreateObject("roSGNode", "ContentNode")
    out.scSeries = CreateObject("roSGNode", "ContentNode")

    res = ScHttp("GET", m.top.url, "", [["Accept", "application/json"]], 20000)
    if res.code = 200 or res.code = 206
        arr = ParseJson(res.body)
        res = invalid
        if type(arr) = "roArray" then build(out, arr, stream)
    end if
    ? "[ScScheduleTask] "; stream; " ok="; out.scOk; " today="; out.scToday.getChildCount(); " series="; out.scSeries.getChildCount()
    m.top.result = out
    m.top.done = true
end sub

sub build(out as object, arr as object, stream as string)
    now = ScNowSecs()
    today = ScLocalParts(now).days
    dayStart = ScDayStart(today)
    dayEnd = dayStart + 86400
    weekStart = dayStart - 6 * 86400

    ' The feed is newest first; walk it once, keeping plain AAs until the end.
    progs = []
    titled = false
    for each it in arr
        if type(it) = "roAssociativeArray"
            st = ScParseIso(ScStr(it.starttime))
            en = ScParseIso(ScStr(it.endtime))
            if st < 0 and it.id <> invalid then st = Int(Val(ScStr(it.id)))
            if en < 0 and st >= 0 and it.duration <> invalid then en = st + Int(Val(ScStr(it.duration)))
            if st > 0 and en > st
                t = ScCleanTitle(it.title)
                if t <> "" then titled = true
                progs.push({ title: t, st: st, en: en, thumb: ScStr(it.thumb), url: ScStr(it.stream), rec: ScStr(it.id) })
            end if
        end if
    end for
    out.scTitled = titled
    if progs.count() = 0 then return

    ' Today, oldest first (the feed is newest first).
    for i = progs.count() - 1 to 0 step -1
        p = progs[i]
        if p.en > dayStart and p.st < dayEnd then out.scToday.appendChild(toNode(p, now, stream))
    end for

    ' Earlier this week, newest first; one per title on a titled channel.
    seenWeek = {}
    for each p in progs
        if out.scWeek.getChildCount() >= 14 then exit for
        if p.st < dayStart and p.st >= weekStart and p.en <= now
            key = p.title
            if not titled then key = p.rec
            if not seenWeek.doesExist(key)
                seenWeek[key] = true
                out.scWeek.appendChild(toNode(p, now, stream))
            end if
        end if
    end for

    ' Series: exact title within this channel's window, aired only.
    if titled
        groups = {}
        order = []
        for each p in progs
            if p.title <> "" and p.en <= now
                g = groups[p.title]
                if g = invalid
                    g = { title: p.title, items: [] }
                    groups[p.title] = g
                    order.push(g)
                end if
                g.items.push(p)
            end if
        end for
        ' Most recorded first; a series needs three recordings to be a row.
        picked = []
        for each g in order
            if g.items.count() >= 3 then picked.push(g)
        end for
        picked.SortBy("title")
        sorted = sortByCount(picked)
        n = 0
        for each g in sorted
            if n >= 8 then exit for
            s = out.scSeries.createChild("ContentNode")
            s.title = g.title
            s.addFields({ scCount: g.items.count() })
            k = 0
            for each p in g.items
                if k >= 20 then exit for
                s.appendChild(toNode(p, now, stream))
                k = k + 1
            end for
            n = n + 1
        end for
    end if
    out.scOk = true
end sub

' Stable descending sort on the item count (insertion sort: at most a few
' dozen series).
function sortByCount(list as object) as object
    out = []
    for each g in list
        i = out.count()
        out.push(g)
        while i > 0 and out[i - 1].items.count() < g.items.count()
            out[i] = out[i - 1]
            i = i - 1
        end while
        out[i] = g
    end for
    return out
end function

function toNode(p as object, now as integer, stream as string) as object
    n = CreateObject("roSGNode", "ContentNode")
    n.title = p.title
    n.url = p.url
    n.streamFormat = "hls"
    thumb = ""
    ' A slot that has not started has only the feed's grey placeholder.
    if p.st <= now then thumb = p.thumb
    n.addFields({ scStart: p.st, scEnd: p.en, scThumb: thumb, scRec: p.rec, scStream: stream })
    return n
end function
