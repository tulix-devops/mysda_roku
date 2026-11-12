' ============================================================================
' ScData.brs - reading the catalogue and the schedules, shared by the Tasks
' that build them and the screens that draw them.
'
' Feed facts (docs/design/data-brief.md, measured 2026-10-06):
'  * Logos are the only channel art: show them WHOLE on a light plate.
'  * Programme titles exist for the 3ABN family only; other channels return
'    hourly "Program" blocks, shown as "Live now · 3 PM hour", never "Program".
'  * Frame grabs exist only once a programme has started; later slots get a
'    logo card. Every frame card carries its channel's logo.
' ============================================================================

function ScStr(v as dynamic) as string
    if v = invalid then return ""
    t = type(v)
    if t = "roString" or t = "String" then return v
    if t = "roInteger" or t = "Integer" or t = "roInt" or t = "LongInteger" or t = "roLongInteger" then return v.toStr()
    if t = "roFloat" or t = "Float" or t = "roDouble" or t = "Double" then return Int(v).toStr()
    if t = "roBoolean" or t = "Boolean"
        if v then return "true"
        return "false"
    end if
    return ""
end function

' A node's children as an array (empty for invalid).
function ScChildren(node as dynamic) as object
    if node = invalid then return []
    return node.getChildren(-1, 0)
end function

' "3ABN TODAY BIBLE Q&A" -> "3ABN Today Bible Q&A". Words with a digit or an
' ampersand stay as they are (3ABN, Q&A); short joining words go lower case
' except first.
function ScTitleCase(s as string) as string
    small = { "a": 1, "an": 1, "and": 1, "at": 1, "by": 1, "for": 1, "from": 1, "in": 1, "of": 1, "on": 1, "or": 1, "the": 1, "to": 1, "with": 1 }
    keep = { "tv": "TV", "dvd": "DVD", "usa": "USA", "abn": "ABN", "llbn": "LLBN", "ii": "II", "iii": "III", "iv": "IV" }
    words = s.Trim().Split(" ")
    out = ""
    first = true
    for each w in words
        if w <> ""
            lw = LCase(w)
            hasDigit = false
            for i = 1 to Len(w)
                c = Asc(Mid(w, i, 1))
                if (c >= 48 and c <= 57) or c = 38 then hasDigit = true
            end for
            if hasDigit
                word = w
            else if keep.doesExist(lw)
                word = keep[lw]
            else if not first and small.doesExist(lw)
                word = lw
            else
                word = UCase(Left(lw, 1)) + Mid(lw, 2)
                ' Capitalise after a hyphen or an apostrophe-free slash.
                dash = Instr(1, word, "-")
                if dash > 0 and dash < Len(word) then word = Left(word, dash) + UCase(Mid(word, dash + 1, 1)) + Mid(word, dash + 2)
            end if
            if out <> "" then out = out + " "
            out = out + word
            first = false
        end if
    end for
    return out
end function

' A programme title fit to show, or "" when the feed only says "Program".
function ScCleanTitle(raw as dynamic) as string
    t = ScStr(raw).Trim()
    if t = "" then return ""
    u = UCase(t)
    if u = "PROGRAM" or u = "PROGRAMME" or u = "PROGRAMA" then return ""
    return ScTitleCase(t)
end function

' The language a channel is in, from its title (the feed has no language
' field). What matches nothing is English (all of Television, list 8).
function ScLangFor(title as string) as string
    t = LCase(title)
    if Instr(1, t, "minha") > 0 or Instr(1, t, "terceiro anjo") > 0 or Instr(1, t, "novo tempo") > 0 then return "Português"
    if Instr(1, t, "latino") > 0 or Instr(1, t, "mas tv") > 0 or Instr(1, t, "nuevo tiempo") > 0 or Instr(1, t, "vida mejor") > 0 then return "Español"
    if Instr(1, t, "franc") > 0 then return "Français"
    if Instr(1, t, "russia") > 0 then return "Russian"
    if Instr(1, t, "romanian") > 0 then return "Romanian"
    if Instr(1, t, "arabic") > 0 or Instr(1, t, "korean") > 0 or Instr(1, t, "chinese") > 0 or Instr(1, t, "south asia") > 0 then return "Asia"
    return "English"
end function

' The stream id in a getdvr URL: ...getdvr.php?id=3abn2_live
function ScStreamFromUrl(u as string) as string
    at = Instr(1, u, "id=")
    if at = 0 then return ""
    s = Mid(u, at + 3)
    amp = Instr(1, s, "&")
    if amp > 0 then s = Left(s, amp - 1)
    return s
end function

' ----------------------------------------------------------- render side --

' The three catalogue lists as one array, in catalogue order.
function ScAllChannels() as object
    out = []
    if m.global = invalid then return out
    for each root in [m.global.catTv, m.global.catLang]
        for each c in ScChildren(root)
            out.push(c)
        end for
    end for
    return out
end function

function ScChannelById(id as string) as dynamic
    if m.global = invalid then return invalid
    for each root in [m.global.catTv, m.global.catLang, m.global.catRadio]
        for each c in ScChildren(root)
            if c.id = id then return c
        end for
    end for
    return invalid
end function

function ScChannelByStream(stream as string) as dynamic
    if stream = "" or m.global = invalid then return invalid
    for each root in [m.global.catTv, m.global.catLang]
        for each c in ScChildren(root)
            if c.scStream = stream then return c
        end for
    end for
    return invalid
end function

' The loaded schedule node for a stream, or invalid.
function ScSched(stream as string) as dynamic
    if stream = "" or m.global = invalid or m.global.schedStore = invalid then return invalid
    for each s in ScChildren(m.global.schedStore)
        if s.id = stream then return s
    end for
    return invalid
end function

' Ask the scene for a channel's schedule (it loads each once per 20 min).
sub ScWantSched(channel as dynamic)
    if channel = invalid or m.global = invalid then return
    if channel.scStream = "" or channel.scDvr = "" then return
    m.global.schedWant = channel.scStream
end sub

' The programme on now in a schedule node, or invalid.
function ScOnNow(sched as dynamic) as dynamic
    if sched = invalid or sched.scToday = invalid then return invalid
    now = ScNowSecs()
    for each p in ScChildren(sched.scToday)
        if p.scStart <= now and now < p.scEnd then return p
    end for
    return invalid
end function

function ScNextAfter(sched as dynamic, prog as dynamic) as dynamic
    if sched = invalid or sched.scToday = invalid or prog = invalid then return invalid
    for each p in ScChildren(sched.scToday)
        if p.scStart >= prog.scEnd then return p
    end for
    return invalid
end function

' A programme's frame grab, or "" while it is too new to have one. For its
' first minutes the feed serves one shared grey "play" placeholder at the
' grab's own URL (same file for every channel: 6542 bytes, measured
' 2026-10-25), so a grab is used only once the programme has run 10 minutes.
function ScGrab(p as dynamic) as string
    if p = invalid then return ""
    if ScNowSecs() - p.scStart < 600 then return ""
    return p.scThumb
end function

' The picture for what is on now: its own grab once it has one, else the
' grab of the programme before it on the same channel - a real frame from
' minutes ago rather than an empty box (owner, 2026-10-28: the first row was
' "really dry" at the top of the hour, when every channel had just started).
function ScNowGrab(sched as dynamic, p as dynamic) as string
    g = ScGrab(p)
    if g <> "" or p = invalid or sched = invalid or sched.scToday = invalid then return g
    prev = invalid
    for each q in ScChildren(sched.scToday)
        if q.scStart >= p.scStart then exit for
        if q.scThumb <> "" then prev = q
    end for
    if prev = invalid then return ""
    return prev.scThumb
end function

' What a programme is called on screen: its title, else "3 PM hour".
function ScProgLabel(p as dynamic) as string
    if p = invalid then return ""
    if p.title <> "" then return p.title
    return ScHourText(p.scStart)
end function

' The "on now" line for a channel: "3ABN Today Bible Q&A · until 3:55",
' "Live now · 3 PM hour", or "Live now" before its schedule is in.
function ScOnNowLine(channel as dynamic) as string
    if channel = invalid then return ""
    p = ScOnNow(ScSched(channel.scStream))
    if p = invalid then return "Live now"
    if p.title = "" then return "Live now · " + ScHourText(p.scStart)
    return p.title + " · until " + ScClock(p.scEnd)
end function

' -------------------------------------------------------------- playback --

sub ScAddPlayFields(item as object, kind as string, rec as string)
    item.addFields({ scKind: kind, scStartAt: 0, scRec: rec })
    item.addField("scChannel", "node", false)
    item.addField("scProg", "node", false)
    item.addField("scList", "node", false)
end sub

' A play request for a channel, live (TV, Languages or Radio).
function ScLiveItem(channel as object) as object
    item = CreateObject("roSGNode", "ContentNode")
    ScAddPlayFields(item, "live", "")
    item.scChannel = channel
    if channel.scKind = "radio" then item.scKind = "radio"
    item.url = channel.url
    item.title = channel.title
    item.streamFormat = "hls"
    return item
end function

' A play request for a recording. list: a node whose children are the
' episodes to offer as "next" (newest first), or invalid.
function ScCatchupItem(prog as object, channel as dynamic, list as dynamic) as object
    item = CreateObject("roSGNode", "ContentNode")
    ScAddPlayFields(item, "catchup", prog.scRec)
    item.scChannel = channel
    item.scProg = prog
    item.scList = list
    item.url = prog.url
    item.title = ScProgLabel(prog)
    item.streamFormat = "hls"
    return item
end function

' ----------------------------------------------------------------- cards --

' One ScCard's content. kind: frame | logo | later | station | series
' f: { title, meta, thumb, logo, tag, tagLive, tagPos (tr | br), pct, w, h,
'      inside, action, ref, ref2 }
function ScCardNode(kind as string, f as object) as object
    n = CreateObject("roSGNode", "ContentNode")
    n.addFields({
        scCard: kind
        scMeta: ""
        scThumb: ""
        scLogo: ""
        scTag: ""
        scTagLive: false
        scTagPos: "tr"
        scPct: -1.0
        scW: 384
        scH: 216
        scInside: false
        scAction: ""
        scTick: 0
        scFocus: ""
    })
    ' Node fields by declaration: addFields cannot infer a type from invalid.
    n.addField("scRef", "node", false)
    n.addField("scRef2", "node", false)
    for each k in f
        v = f[k]
        if k = "title"
            n.title = v
        else if k = "meta"
            n.scMeta = v
        else if k = "thumb"
            n.scThumb = v
        else if k = "logo"
            n.scLogo = v
        else if k = "tag"
            n.scTag = v
        else if k = "tagLive"
            n.scTagLive = v
        else if k = "tagPos"
            n.scTagPos = v
        else if k = "pct"
            n.scPct = v
        else if k = "w"
            n.scW = v
        else if k = "h"
            n.scH = v
        else if k = "inside"
            n.scInside = v
        else if k = "action"
            n.scAction = v
        else if k = "ref"
            n.scRef = v
        else if k = "ref2"
            n.scRef2 = v
        end if
    end for
    return n
end function
