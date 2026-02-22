sub init()
    m.top.functionName = "GetCategoriesData"
end sub



sub GetCategoriesData()
    print "CategoriesApi.brs - [CategoriesApi] Called"
    ' if m.top.typeID <> invalid or m.top.typeID <> ""
    '     baseUrl = "https://joygo.tulix.net/api/category/"

        
    '     finalUrl = baseUrl + m.top.typeID + "/list"

    '     authToken = m.top.authToken

    '     request = CreateObject("roUrlTransfer")
    '     port = CreateObject("roMessagePort")
    '     request.setMessagePort(port)

    '     request.SetCertificatesFile("common:/certs/ca-bundle.crt")
    '     ' , "Bearer " + authToken
    '     ' request.AddHeader("Authorization", "Bearer")
    '     request.InitClientCertificates()

    '     request.SetUrl(finalUrl)

    '     if request.AsyncGetToString()
    '         while true
    '             msg = wait(0, port)
    '             if type(msg) = "roUrlEvent"
    '                 code = msg.GetResponseCode()
    '                 body = msg.GetString()
    '                 print code
    '                 print "Here is Code let me see"
    '                 if code = 200
    '                     response = ParseJson(msg.GetString())
    '                     print msg.GetString()
    '                     m.top.responseData = msg.GetString()
                     
    '                 else
    '                     print msg.GetString()
    '                     print "here is actual error"
    '                     m.top.responseData = "Error"
    '                 end if
    '                 exit while
    '             else if msg = invalid
    '                 request.AsyncCancel()
    '             end if
    '         end while
    '     end if
    ' end if




    ' return invalid
end sub



function RegRead(key, section = invalid)
    if section = invalid section = "Default"
    sec = CreateObject("roRegistrySection", section)
    if sec.Exists(key) return sec.Read(key)
    ' return invalid
    return sec.Read(key)
end function

