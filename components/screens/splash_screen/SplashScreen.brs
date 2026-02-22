sub init()
    m.timer = m.top.findNode("splashTimer")
    m.timer.control = "start"
    m.timer.observeField("fire", "onTimerFire")
end sub

sub onTimerFire()



    ' m.global.findNode("home_screen").visible = true
    ' m.global.findNode("navigation_bar").visible = true

    m.authData = RetrieveAuthData()
    m.top.visible = false
    print "is SplashScreen Initalized"
    if m.global.deeplinked = "1"
        m.global.findNode("vod_screen").visible = false
    else
        m.global.findNode("vod_screen").visible = true
        ' m.global.findNode("vod_screen").setFocus(true)
    end if
end sub






function RetrieveAuthData() as object
    section = "AUTH"
    jsonData = RegRead("authData", section)
    ' Check if the JSON data is valid
    if jsonData <> invalid and jsonData <> ""
        ' Deserialize the JSON string back into an associative array
        data = ParseJson(jsonData)
        currentTime = CreateObject("roDateTime").asSeconds()

        ' Check if the data is expired
        if currentTime <= data.expiry
            ' Data is valid
            return data
        else
            ' Data is expired
            return invalid
        end if
    else
        ' No valid data found
        return invalid
    end if
end function


function RegRead(key, section = invalid)
    if section = invalid section = "Default"
    sec = CreateObject("roRegistrySection", section)
    if sec.Exists(key) return sec.Read(key)
    ' return invalid
    return sec.Read(key)
end function