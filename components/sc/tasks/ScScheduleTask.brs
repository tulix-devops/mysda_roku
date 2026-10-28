sub init()
    m.top.functionName = "work"
end sub

sub work()
    stream = m.top.stream
    out = CreateObject("roSGNode", "ContentNode")
    out.id = stream
    out.addFields({ scStream: stream, scAt: ScNowSecs(), scOk: false, scTitled: false, scNoGrabs: false })
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

    ' Walk the feed once, keeping plain AAs until the end.
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
    ' Newest first, explicitly: the feed's order differs per channel (3ABN
    ' came oldest first, Minha TV newest first, 2026-10-25/28).
    progs.SortBy("st", "r")
    if progs.count() = 0 then return

    ' Some channels never get real grabs: every thumb is the feed's shared
    ' grey "play" placeholder (Minha TV, 2026-10-28). One well-aired grab is
    ' fetched; if it is the placeholder the channel's cards show its logo.
    if grabsArePlaceholders(progs, now, stream)
        out.scNoGrabs = true
        for each p in progs
            p.thumb = ""
        end for
    end if

    ' Today, oldest first (progs is newest first).
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

' The feed's placeholder grab is one file served at every programme's own
' grab URL until (or unless) a real one exists: 6542 bytes, the same md5
' across channels (measured 2026-10-25 and 2026-10-28). Probe the newest
' programme that ended over half an hour ago.
function grabsArePlaceholders(progs as object, now as integer, stream as string) as boolean
    probe = invalid
    for each p in progs
        if p.en <= now - 1800 and p.thumb <> ""
            probe = p
            exit for
        end if
    end for
    if probe = invalid then return false
    path = "tmp:/sc_probe_" + stream + ".jpg"
    port = CreateObject("roMessagePort")
    req = CreateObject("roUrlTransfer")
    req.SetMessagePort(port)
    req.SetCertificatesFile("common:/certs/ca-bundle.crt")
    req.InitClientCertificates()
    req.SetUrl(probe.thumb)
    if not req.AsyncGetToFile(path) then return false
    msg = wait(8000, port)
    if type(msg) <> "roUrlEvent" or msg.GetResponseCode() <> 200
        req.AsyncCancel()
        return false
    end if
    fs = CreateObject("roFileSystem")
    st = fs.Stat(path)
    size = -1
    if st <> invalid and st.size <> invalid then size = st.size
    fs.Delete(path)
    return (size = 6542)
end function

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
