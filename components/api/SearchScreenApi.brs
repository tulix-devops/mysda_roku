sub init()
    ' m.top.functionName = "GetLiveScreenData"
    m.top.keyword = m.top.findNode("keyword")
    m.top.observeField("keyword", "keywordUpdated")
end sub

sub keywordUpdated()
    if m.top.keyword <> invalid or m.top.keyword <> ""
        m.top.functionName = "GetVideosByKeyword"
        m.top.control = "RUN"
    end if
end sub

sub GetVideosByKeyword()
    print "SearchScreenAPI.brs - [SearchScreenAPI] Called"

    if m.top.keyword <> invalid or m.top.keyword <> ""
        accessToken = RegRead("accessToken", "AUTH")
        request = CreateObject("roUrlTransfer")
        port = CreateObject("roMessagePort")
        request.setMessagePort(port)

        request.SetCertificatesFile("common:/certs/ca-bundle.crt")
        request.AddHeader("Authorization", "Bearer " + accessToken)
        request.AddHeader("Content-Type", "application/json")
        request.RetainBodyOnError(true)
        request.SetRequest("POST")
        request.InitClientCertificates()

        baseUrl = "https://joygo.tulix.net/api/content/search"
        keyword = m.top.keyword

        data = {
            "search": keyword,
        }
        body = FormatJSON(data)
        request.SetUrl(baseUrl)

        if request.AsyncPostFromString(body)
            while true
                msg = wait(0, port)
                if type(msg) = "roUrlEvent"
                    code = msg.GetResponseCode()
                    body = msg.GetString()
                    ' m.top.responseData = invalid
                    if code = 200
                        response = ParseJson(msg.GetString())
                        m.top.responseData = msg.GetString()
                        ' print msg.GetString()
                        ' return response
                    else
                        m.top.responseData = invalid
                        ' return invalid
                    end if
                    exit while
                else if msg = invalid
                    request.AsyncCancel()
                end if
            end while
        end if
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

