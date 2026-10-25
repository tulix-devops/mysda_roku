sub init()
    m.tile = m.top.findNode("tile")
end sub

' The grid's focus, passed through: SdTile lights on focusPercent gated by
' whether its list holds focus.
sub onFocusChanged()
    m.tile.focusPercent = m.top.focusPercent
    m.tile.hostLit = (m.top.gridHasFocus = true)
end sub

sub updateContent()
    content = m.top.itemContent
    if content = invalid then return

    ' Poster - check multiple sources
    posterUrl = ""
    if content.hdposterurl <> invalid and content.hdposterurl <> ""
        posterUrl = content.hdposterurl
    else if content.data <> invalid
        if type(content.data) = "roSGNode" and content.data.hdposterurl <> invalid and content.data.hdposterurl <> ""
            posterUrl = content.data.hdposterurl
        else if type(content.data) = "roAssociativeArray" and content.data.hdposterurl <> invalid and content.data.hdposterurl <> ""
            posterUrl = content.data.hdposterurl
        else if type(content.data) = "roAssociativeArray" and content.data.thumbnail <> invalid and content.data.thumbnail <> ""
            posterUrl = content.data.thumbnail
        end if
    end if

    ' Title - check multiple sources
    titleText = ""
    if content.title <> invalid and content.title <> ""
        titleText = content.title
    else if content.description <> invalid and content.description <> ""
        titleText = content.description
    else if content.data <> invalid
        if type(content.data) = "roAssociativeArray" and content.data.name <> invalid and content.data.name <> ""
            ' The program name only: data.name carries " • <time>" after it.
            fullName = content.data.name
            if fullName.Instr("•") > -1
                titleText = fullName.Left(fullName.Instr("•")).Trim()
            else
                titleText = fullName
            end if
        else if type(content.data) = "roSGNode"
            if content.data.title <> invalid and content.data.title <> ""
                titleText = content.data.title
            else if content.data.description <> invalid and content.data.description <> ""
                titleText = content.data.description
            end if
        end if
    end if

    ' Time - "01:00 AM - 02:00 AM"
    meta = ""
    if content.data <> invalid
        if content.data.start <> invalid and content.data.end <> invalid
            startTime = extractTimeFromISO(content.data.start)
            endTime = extractTimeFromISO(content.data.end)
            if startTime <> "" and endTime <> ""
                meta = startTime + " - " + endTime
            else
                meta = content.data.start + "  -  " + content.data.end
            end if
        else if content.data.start <> invalid
            meta = extractTimeFromISO(content.data.start)
            if meta = "" then meta = content.data.start
        end if
    end if

    ' A fresh node per item: the tile reads only these.
    node = CreateObject("roSGNode", "ContentNode")
    node.title = titleText
    node.addFields({
        sdArt: posterUrl,
        sdMeta: meta,
        sdTileW: 390,
        sdTileH: 219,
        sdPadLeft: 30,
        sdPadTop: 20
    })
    m.tile.itemContent = node
end sub

' Extract and format time from ISO timestamp
' Input: "2025-10-13T01:00:00-05:00"
' Output: "1:00 AM"
function extractTimeFromISO(isoTimestamp as String) as String
    if isoTimestamp = invalid or isoTimestamp = ""
        return ""
    end if

    parts = isoTimestamp.Split("T")
    if parts.count() < 2
        return ""
    end if

    timePart = parts[1]
    timeComponents = timePart.Split(":")
    if timeComponents.count() < 2
        return ""
    end if

    hour = val(timeComponents[0])
    minute = timeComponents[1]

    ampm = "AM"
    if hour >= 12
        ampm = "PM"
        if hour > 12
            hour = hour - 12
        end if
    else if hour = 0
        hour = 12
    end if

    return hour.ToStr() + ":" + minute + " " + ampm
end function
