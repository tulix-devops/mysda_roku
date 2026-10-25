sub init()
    m.top.functionName = "work"
end sub

sub work()
    kind = m.top.kind
    listId = "8"
    if kind = "lang" then listId = "9"
    if kind = "radio" then listId = "10"
    url = ScApiBase() + "/content/" + listId + "/list?limit=200"

    root = CreateObject("roSGNode", "ContentNode")
    ok = false
    status = 0
    ' One retry: a cold network at power-on drops the first request often
    ' enough to matter, and an empty catalogue strands the whole channel.
    for attempt = 1 to 2
        res = ScHttp("GET", url, "", [["Accept", "application/json"]], 15000)
        status = res.code
        if res.code = 200 or res.code = 206
            json = ParseJson(res.body)
            if json <> invalid and type(json.data) = "roArray"
                n = 0
                for each item in json.data
                    c = toChannel(item, kind, n)
                    if c <> invalid
                        root.appendChild(c)
                        n = n + 1
                    end if
                end for
                ok = (n > 0)
            end if
        end if
        if ok then exit for
    end for
    ? "[ScFeedTask] "; kind; " <- "; status; " ("; root.getChildCount(); " channels)"

    m.top.result = root
    m.top.ok = ok
    m.top.status = status
    m.top.done = true
end sub

function toChannel(item as object, kind as string, index as integer) as dynamic
    if type(item) <> "roAssociativeArray" then return invalid
    url = ""
    if item.sources <> invalid and item.sources.primary <> invalid then url = ScStr(item.sources.primary)
    if url = "" then return invalid
    logo = ""
    if item.images <> invalid
        logo = ScStr(item.images.banner)
        if logo = "" then logo = ScStr(item.images.poster)
        if logo = "" then logo = ScStr(item.images.thumbnail)
    end if
    dvr = ScStr(item.dvr_url)
    stream = ScStreamFromUrl(dvr)
    ' attributes { "": ["200", "<stream id>", "1", "21"] } carries it too.
    if stream = "" and item.attributes <> invalid
        a = item.attributes.Lookup("")
        if type(a) = "roArray" and a.count() > 1 then stream = ScStr(a[1])
    end if
    title = ScStr(item.title).Trim()

    c = CreateObject("roSGNode", "ContentNode")
    c.id = ScStr(item.id)
    c.title = title
    c.url = url
    c.streamFormat = "hls"
    c.addFields({ scLogo: logo, scDvr: dvr, scStream: stream, scKind: kind, scLang: ScLangFor(title, kind), scIndex: index })
    return c
end function
