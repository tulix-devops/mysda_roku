sub init()
    m.top.functionName = "GetHomeScreenData"
end sub

sub GetHomeScreenData()
    print "HomeScreenAPI.brs - [GetHomeScreenData] Called"

    accessToken = RegRead("accessToken", "AUTH")
    request = CreateObject("roUrlTransfer")
    port = CreateObject("roMessagePort")
    request.setMessagePort(port)

    request.SetCertificatesFile("common:/certs/ca-bundle.crt")
    request.AddHeader("Authorization", "Bearer " + accessToken)
    request.InitClientCertificates()
    
    baseUrl = "https://joygo.tulix.net/api/content/1/featured-list"

    request.SetUrl(baseUrl)

    if request.AsyncGetToString()
        while true
            msg = wait(0, port)
            if type(msg) = "roUrlEvent"
                code = msg.GetResponseCode()
                body = msg.GetString()
                if code = 200 or code = 206
                    response = ParseJson(msg.GetString())
                    m.top.responseData = msg.GetString()
                    ' print response
                    ' return response
                else
                    ' return invalid
                end if
                exit while
            else if msg = invalid
                request.AsyncCancel()
            end if
        end while
    end if

    ' return invalid
end sub



function RegRead(key, section = invalid)
    if section = invalid section = "Default"
    sec = CreateObject("roRegistrySection", section)
    if sec.Exists(key) return sec.Read(key)
    ' return invalid
    return sec.Read(key)
end function

