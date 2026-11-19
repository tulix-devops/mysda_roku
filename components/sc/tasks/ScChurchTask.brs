sub init()
    m.top.functionName = "work"
end sub

function ScChurchesApi() as string
    return "https://mysda.itulix.com/api/public/churches"
end function

sub work()
    st = m.top.stateName
    page = m.top.page
    if page < 1 then page = 1
    per = m.top.perPage
    esc = CreateObject("roUrlTransfer")
    url = ScChurchesApi() + "?page=" + page.toStr() + "&per_page=" + per.toStr()
    if st <> "" then url = url + "&state=" + esc.Escape(st)

    out = CreateObject("roSGNode", "ContentNode")
    out.addFields({ scState: st, scPage: page, scPages: 0, scTotal: 0, scGen: m.top.gen, scStates: [] })
    ok = false
    status = 0
    for attempt = 1 to 2
        res = ScHttp("GET", url, "", [["Accept", "application/json"]], 15000)
        status = res.code
        if res.code = 200
            json = ParseJson(res.body)
            res = invalid
            if type(json) = "roAssociativeArray" and type(json.churches) = "roArray" and type(json.paging) = "roAssociativeArray"
                ok = build(out, json)
            end if
        end if
        if ok then exit for
    end for
    ? "[ScChurchTask] state='"; st; "' page "; out.scPage; "/"; out.scPages; " <- "; status; " ("; out.getChildCount(); " churches)"
    m.top.result = out
    m.top.ok = ok
    m.top.done = true
end sub

' Some names carry a phone number: "Oakwood University Church (256)
' 837-1255", "Brazilian Temple SDA church (954) 739-9500 Portuguese",
' "Thompsonville SDA Church (618)627-2999". A US number is cut out and the
' spaces closed up (review C7); the rest of the name stays.
function cleanName(raw as string) as string
    if m.phoneRe = invalid
        m.phoneRe = CreateObject("roRegex", "\(?\d{3}\)?[\s.-]*\d{3}[\s.-]?\d{4}", "")
        m.spaceRe = CreateObject("roRegex", "\s+", "")
    end if
    s = m.phoneRe.ReplaceAll(raw, " ")
    s = m.spaceRe.ReplaceAll(s, " ")
    return s.Trim()
end function

' Untrusted data: trimmed; a row with no name or no link is dropped (the
' screen still checks the link's scheme and host before it makes a code).
function build(out as object, json as object) as boolean
    pg = json.paging
    out.scPage = Int(Val(ScStr(pg.page)))
    out.scPages = Int(Val(ScStr(pg.pages)))
    out.scTotal = Int(Val(ScStr(pg.total)))
    if out.scPage < 1 or out.scPages < 1 then return false
    states = []
    if type(json.states) = "roArray"
        for each s in json.states
            if type(s) = "roAssociativeArray"
                name = ScStr(s.state).Trim()
                if name <> "" then states.push({ state: name, count: Int(Val(ScStr(s.churches))) })
            end if
        end for
    end if
    out.scStates = states
    for each c in json.churches
        if type(c) = "roAssociativeArray"
            name = cleanName(ScStr(c.name))
            link = ScStr(c.youtube_url).Trim()
            if name <> "" and link <> ""
                n = out.createChild("ContentNode")
                n.title = name
                n.addFields({ scCity: ScStr(c.city).Trim(), scLink: link, scState: ScStr(c.state).Trim() })
            end if
        end if
    end for
    return true
end function
