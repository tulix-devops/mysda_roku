sub init()
    m.top.functionName = "work"
end sub

sub work()
    url = "https://livetv.mysdatv.com/api/getfavoritechurch.php"
    root = CreateObject("roSGNode", "ContentNode")
    ok = false
    status = 0
    for attempt = 1 to 2
        res = ScHttp("GET", url, "", [["Accept", "application/json"]], 15000)
        status = res.code
        if res.code = 200
            json = ParseJson(res.body)
            list = invalid
            if type(json) = "roArray"
                list = json
            else if type(json) = "roAssociativeArray" and type(json.data) = "roArray"
                list = json.data
            end if
            if list <> invalid
                byState = {}
                n = 0
                for each item in list
                    if type(item) = "roAssociativeArray"
                        st = ScStr(item.state).Trim()
                        name = ScStr(item.church).Trim()
                        if st <> "" and name <> ""
                            node = byState.Lookup(st)
                            if node = invalid
                                node = root.createChild("ContentNode")
                                node.title = titleCase(st)
                                node.addFields({ scCount: 0 })
                                byState[st] = node
                            end if
                            c = node.createChild("ContentNode")
                            c.title = name
                            c.addFields({ scCity: ScStr(item.city).Trim(), scLink: ScStr(item.link).Trim(), scState: node.title })
                            node.scCount = node.scCount + 1
                            n = n + 1
                        end if
                    end if
                end for
                ok = (n > 0)
            end if
        end if
        if ok then exit for
    end for
    ? "[ScChurchTask] <- "; status; " ("; root.getChildCount(); " states)"
    m.top.result = root
    m.top.ok = ok
    m.top.done = true
end sub

' "NORTH CAROLINA" -> "North Carolina"; two letters stay as they are (DC).
function titleCase(s as string) as string
    if Len(s) <= 2 then return s
    out = ""
    up = true
    for i = 1 to Len(s)
        ch = Mid(s, i, 1)
        if up then out = out + UCase(ch) else out = out + LCase(ch)
        up = (ch = " " or ch = "-")
    end for
    return out
end function
