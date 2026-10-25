' ============================================================================
' ScTime.brs - feed timestamps and the time strings the screens draw.
'
' Ported from wpa_live_roku/source/WpTime.brs. getdvr.php gives each
' programme an epoch-second `id` (its start) and "2026-10-05T15:00:00-05:00"
' times with the channel's own offset; times are SHOWN in the device's local
' time. Parsing is day-count arithmetic, not roDateTime: roDateTime is used
' only for AsSeconds() and ToLocalTime(), to learn "now" and the device's
' offset (knowledge/dev-roku/compute-dst-arithmetically-not-via-rodatetime).
'
' INTEGER arithmetic only: Integer / Integer is a Float and at ~1.8e9 epoch
' seconds it rounds to a multiple of 128 (WpTime review C3); use \ and mod.
' ============================================================================

function ScDaysFromCivil(y as integer, mo as integer, d as integer) as integer
    if mo <= 2 then y = y - 1
    era = Int(y / 400)
    yoe = y - era * 400
    mp = mo + 9
    if mo > 2 then mp = mo - 3
    doy = Int((153 * mp + 2) / 5) + d - 1
    doe = yoe * 365 + Int(yoe / 4) - Int(yoe / 100) + doy
    return era * 146097 + doe - 719468
end function

function ScCivilFromDays(z as integer) as object
    z = z + 719468
    era = Int(z / 146097)
    doe = z - era * 146097
    yoe = Int((doe - Int(doe / 1460) + Int(doe / 36524) - Int(doe / 146096)) / 365)
    y = yoe + era * 400
    doy = doe - (365 * yoe + Int(yoe / 4) - Int(yoe / 100))
    mp = Int((5 * doy + 2) / 153)
    d = doy - Int((153 * mp + 2) / 5) + 1
    mo = mp + 3
    if mp >= 10 then mo = mp - 9
    if mo <= 2 then y = y + 1
    return { y: y, m: mo, d: d }
end function

function ScNowSecs() as integer
    return CreateObject("roDateTime").AsSeconds()
end function

' local - utc, in seconds; re-read hourly so a DST change is picked up.
function ScLocalOffset() as integer
    now = ScNowSecs()
    if m.scOffsetAt <> invalid and now - m.scOffsetAt < 3600 then return m.scOffset
    dt = CreateObject("roDateTime")
    utc = dt.AsSeconds()
    dt.ToLocalTime()
    m.scOffset = dt.AsSeconds() - utc
    m.scOffsetAt = now
    return m.scOffset
end function

function ScDigits(s as string) as boolean
    if s = "" then return false
    for i = 1 to Len(s)
        c = Asc(Mid(s, i, 1))
        if c < 48 or c > 57 then return false
    end for
    return true
end function

' "2026-10-05T15:00:00-05:00" -> UTC epoch seconds, or -1.
function ScParseIso(text as dynamic) as integer
    if type(text) <> "roString" and type(text) <> "String" then return -1
    t = text.Trim()
    if Len(t) < 16 or Mid(t, 5, 1) <> "-" or Mid(t, 8, 1) <> "-" then return -1
    if not ScDigits(Mid(t, 1, 4)) or not ScDigits(Mid(t, 6, 2)) or not ScDigits(Mid(t, 9, 2)) then return -1
    if not ScDigits(Mid(t, 12, 2)) or not ScDigits(Mid(t, 15, 2)) then return -1
    y = Int(Val(Mid(t, 1, 4)))
    mo = Int(Val(Mid(t, 6, 2)))
    d = Int(Val(Mid(t, 9, 2)))
    hh = Int(Val(Mid(t, 12, 2)))
    mi = Int(Val(Mid(t, 15, 2)))
    ss = 0
    rest = Mid(t, 17)
    if Left(rest, 1) = ":" and ScDigits(Mid(rest, 2, 2))
        ss = Int(Val(Mid(rest, 2, 2)))
        rest = Mid(rest, 4)
    end if
    offset = 0
    sign = Left(rest, 1)
    if (sign = "+" or sign = "-") and Len(rest) >= 6 and ScDigits(Mid(rest, 2, 2)) and ScDigits(Mid(rest, 5, 2))
        offset = Int(Val(Mid(rest, 2, 2))) * 3600 + Int(Val(Mid(rest, 5, 2))) * 60
        if sign = "-" then offset = -offset
    end if
    return ScDaysFromCivil(y, mo, d) * 86400 + hh * 3600 + mi * 60 + ss - offset
end function

' UTC seconds -> device-local { year, month, day, dow, hour, minute, days }.
function ScLocalParts(secs as integer) as object
    lsecs = secs + ScLocalOffset()
    days = lsecs \ 86400
    secsInDay = lsecs mod 86400
    if secsInDay < 0
        days = days - 1
        secsInDay = secsInDay + 86400
    end if
    civil = ScCivilFromDays(days)
    return { year: civil.y, month: civil.m, day: civil.d, dow: (days + 4) mod 7, hour: secsInDay \ 3600, minute: (secsInDay mod 3600) \ 60, days: days }
end function

' The UTC second the device-local day `days` begins.
function ScDayStart(days as integer) as integer
    return days * 86400 - ScLocalOffset()
end function

function ScWeekday(dow as integer, short as boolean) as string
    full = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    if dow < 0 or dow > 6 then return ""
    if short then return Left(full[dow], 3)
    return full[dow]
end function

function ScMonth(month as integer) as string
    names = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    if month < 1 or month > 12 then return ""
    return names[month - 1]
end function

function ScHalf(hour as integer) as string
    if hour >= 12 then return "PM"
    return "AM"
end function

function ScH12(hour as integer) as integer
    h = hour mod 12
    if h = 0 then h = 12
    return h
end function

' "3:20" (no half)
function ScHm(p as object) as string
    mm = p.minute.toStr()
    if p.minute < 10 then mm = "0" + mm
    return ScH12(p.hour).toStr() + ":" + mm
end function

' "3:20 PM"
function ScClock(secs as integer) as string
    p = ScLocalParts(secs)
    return ScHm(p) + " " + ScHalf(p.hour)
end function

' "3:00 – 3:55 PM", or "11:30 AM – 12:30 PM" across noon.
function ScRange(startSecs as integer, endSecs as integer) as string
    a = ScLocalParts(startSecs)
    b = ScLocalParts(endSecs)
    if ScHalf(a.hour) = ScHalf(b.hour) then return ScHm(a) + " – " + ScHm(b) + " " + ScHalf(b.hour)
    return ScHm(a) + " " + ScHalf(a.hour) + " – " + ScHm(b) + " " + ScHalf(b.hour)
end function

' "3 PM hour" - what an untitled channel's block is called.
function ScHourText(secs as integer) as string
    p = ScLocalParts(secs)
    return ScH12(p.hour).toStr() + " " + ScHalf(p.hour) + " hour"
end function

' "Sunday, Oct 5"
function ScDayLong(secs as integer) as string
    p = ScLocalParts(secs)
    return ScWeekday(p.dow, false) + ", " + ScMonth(p.month) + " " + p.day.toStr()
end function

' "Sat, Oct 4"
function ScDayShort(secs as integer) as string
    p = ScLocalParts(secs)
    return ScWeekday(p.dow, true) + ", " + ScMonth(p.month) + " " + p.day.toStr()
end function

' "Today · 3:00 AM", "Yesterday · 5:30 PM", "Sat, Oct 4 · 5:30 PM"
function ScWhen(secs as integer) as string
    p = ScLocalParts(secs)
    now = ScLocalParts(ScNowSecs())
    clock = ScHm(p) + " " + ScHalf(p.hour)
    if p.days = now.days then return "Today · " + clock
    if p.days = now.days - 1 then return "Yesterday · " + clock
    return ScWeekday(p.dow, true) + ", " + ScMonth(p.month) + " " + p.day.toStr() + " · " + clock
end function

' "35 min left", "1 h 5 min left"
function ScLeft(endSecs as integer) as string
    mins = (endSecs - ScNowSecs() + 59) \ 60
    if mins < 1 then mins = 1
    if mins < 60 then return mins.toStr() + " min left"
    h = mins \ 60
    r = mins mod 60
    if r = 0 then return h.toStr() + " h left"
    return h.toStr() + " h " + r.toStr() + " min left"
end function

' "28 MIN" for a badge; "1 H 5 MIN" past the hour.
function ScDurBadge(secs as integer) as string
    mins = (secs + 30) \ 60
    if mins < 60 then return mins.toStr() + " MIN"
    r = mins mod 60
    if r = 0 then return (mins \ 60).toStr() + " H"
    return (mins \ 60).toStr() + " H " + r.toStr() + " MIN"
end function

' "12:40" or "1:02:05" for the seek bar.
function ScTimecode(secs as integer) as string
    if secs < 0 then secs = 0
    h = secs \ 3600
    mi = (secs mod 3600) \ 60
    s = secs mod 60
    ss = s.toStr()
    if s < 10 then ss = "0" + ss
    if h > 0
        mm = mi.toStr()
        if mi < 10 then mm = "0" + mm
        return h.toStr() + ":" + mm + ":" + ss
    end if
    return mi.toStr() + ":" + ss
end function

' How far through [start, end) now is, 0..1.
function ScProgress(startSecs as integer, endSecs as integer) as float
    if endSecs <= startSecs then return 0
    p = (ScNowSecs() - startSecs) / (endSecs - startSecs)
    if p < 0 then return 0
    if p > 1 then return 1
    return p
end function
