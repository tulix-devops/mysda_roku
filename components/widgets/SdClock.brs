' ============================================================================
' SdClock.brs - "7:42 PM" on the left of the plate, "Tuesday, Oct 6" on the
' right. Re-read every 20 s, so the minute turns over within 20 s of the
' wall clock without a per-second timer.
' ============================================================================

sub init()
    SdEnsureGlobals()
    m.t = SdTheme()
    SdPaint(m.top, [["clockPlate", "blendColor", "cSurface"], ["clockTime", "color", "cText"], ["clockDay", "color", "cText2"]])
    m.clockTime = m.top.findNode("clockTime")
    m.clockDay = m.top.findNode("clockDay")
    m.timer = m.top.findNode("clockTimer")
    m.timer.observeField("fire", "onClockTick")
    m.top.observeField("visible", "onClockVisible")
    onClockTick()
    if m.top.visible then m.timer.control = "start"
end sub

' The timer only runs while the clock is on screen.
sub onClockVisible()
    if m.top.visible
        onClockTick()
        m.timer.control = "start"
    else
        m.timer.control = "stop"
    end if
end sub

sub onClockTick()
    now = CreateObject("roDateTime")
    now.ToLocalTime()
    h = now.GetHours()
    mins = now.GetMinutes()
    ampm = "AM"
    if h >= 12 then ampm = "PM"
    h12 = h mod 12
    if h12 = 0 then h12 = 12
    mm = mins.toStr()
    if mins < 10 then mm = "0" + mm
    m.clockTime.text = h12.toStr() + ":" + mm + " " + ampm
    months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    m.clockDay.text = now.GetWeekday() + ", " + months[now.GetMonth() - 1] + " " + now.GetDayOfMonth().toStr()
end sub
