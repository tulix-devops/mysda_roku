sub init()
    m.top.functionName = "GetDvrListData"
end sub

sub GetDvrListData()
    print "=== DvrListApi.brs - [GetDvrListData] Called ==="

    page = m.top.page
    print "   Page: " + page.ToStr()
    
    accessToken = RegRead("accessToken", "AUTH")
    
    
    ' Fetch the parent DVR VOD items
    request = CreateObject("roUrlTransfer")
    port = CreateObject("roMessagePort")
    request.setMessagePort(port)
    request.SetCertificatesFile("common:/certs/ca-bundle.crt")
    
    if accessToken <> invalid and accessToken <> ""
        ' request.AddHeader("Authorization", "Bearer " + accessToken)
        print "   (Authorization header commented out)"
    end if
    
    request.AddHeader("Accept", "application/json")
    request.InitClientCertificates()
    
    url = "https://sda.wchupload.tulix.net/api/content/dvrlist"
    print "   Fetching DVR list from: " + url
    request.SetUrl(url)
    print "   Sending async request..."
    
    if request.AsyncGetToString()
        print "   ✓ Request initiated successfully"
        while true
            msg = wait(0, port)
            if type(msg) = "roUrlEvent"
                code = msg.GetResponseCode()
                body = msg.GetString()
                print "   Response code: " + code.ToStr()
                print "   Response body length: " + body.Len().ToStr()
                
                if code = 200 or code = 206
                    response = ParseJson(body)
                    if response <> invalid and response.data <> invalid
                        print "   Response parsed successfully"
                        print "   Data count: " + response.data.count().ToStr()
                        
                        if response.data.count() = 0
                            print "   ✗ No DVR items in response"
                            m.top.responseData = "empty"
                        else
                            ' Return the parent VOD items directly
                            m.top.responseData = body
                            print "   ✓ Successfully fetched " + response.data.count().ToStr() + " DVR parent items"
                        end if
                    else
                        print "   ✗ Invalid response or no data"
                        m.top.responseData = "empty"
                    end if
                else
                    print "   ✗ Error fetching DVR list: " + code.ToStr()
                    print "   Error body: " + body
                    m.top.responseData = "error"
                end if
                exit while
            else if msg = invalid
                print "   ✗ Message invalid, cancelling request"
                request.AsyncCancel()
            end if
        end while
    else
        print "   ✗ Failed to initiate async request"
        m.top.responseData = "error"
    end if
end sub

function RegRead(key, section = invalid)
    if section = invalid section = "Default"
    sec = CreateObject("roRegistrySection", section)
    if sec.Exists(key) return sec.Read(key)
    return sec.Read(key)
end function

