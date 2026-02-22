sub init()
    m.top.functionName = "GetEpgScreenData"
end sub

sub GetEpgScreenData()
    print "EPGScreenData.brs - [GetEpgScreenData] Called"

    epgId = m.top.epgId
    request = CreateObject("roUrlTransfer")
    port = CreateObject("roMessagePort")
    request.setMessagePort(port)

    request.SetCertificatesFile("common:/certs/ca-bundle.crt")
    ' request.AddHeader("Authorization", "Bearer " + accessToken)
    request.InitClientCertificates()
    ' baseUrl = "https://mysdatv.tulix.net/api/content/epg/"
    baseUrl = "https://sda.wchupload.tulix.net/api/content/epg/"
    ' url = baseUrl + vodType.ToStr() + "/" + categoryType.ToStr() + "/list"
    url = baseUrl + epgId.ToStr()
    print url
    print "Here is URL "
    request.SetUrl(url)
    if request.AsyncGetToString()
        while true
            msg = wait(0, port)
            if type(msg) = "roUrlEvent"
                code = msg.GetResponseCode()
                body = msg.GetString()
                if code = 200 or code = 206
                    response = ParseJson(msg.GetString())
                    if response.data.count() = 0
                        m.top.responseData = "empty"
                    else
                        m.top.responseData = msg.GetString()

                    end if

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

