sub init()
    m.top.functionName = "GetDvrRecordings"
end sub

sub GetDvrRecordings()
    print "DvrRecordingsApi.brs - [GetDvrRecordings] Called"

    dvrUrl = m.top.dvrUrl
    
    if dvrUrl = invalid or dvrUrl = ""
        print "No DVR URL provided or empty URL"
        m.top.responseData = "error"
        return
    end if
    
    request = CreateObject("roUrlTransfer")
    port = CreateObject("roMessagePort")
    request.setMessagePort(port)
    request.SetCertificatesFile("common:/certs/ca-bundle.crt")
    request.AddHeader("Accept", "application/json")
    request.InitClientCertificates()
    request.SetUrl(dvrUrl)
    
    print "Fetching DVR recordings from: " + dvrUrl
    
    if request.AsyncGetToString()
        while true
            msg = wait(0, port)
            if type(msg) = "roUrlEvent"
                code = msg.GetResponseCode()
                body = msg.GetString()
                if code = 200 or code = 206
                    recordings = ParseJson(body)
                    if recordings <> invalid and recordings.count() > 0
                        ' Return recordings with parent data
                        result = {
                            recordings: recordings,
                            dvrItem: m.top.parentData
                        }
                        m.top.responseData = FormatJson(result)
                        print "Successfully fetched " + recordings.count().ToStr() + " recordings"
                    else
                        print "No recordings found"
                        m.top.responseData = "empty"
                    end if
                else
                    print "Error fetching DVR recordings: " + code.ToStr()
                    m.top.responseData = "error"
                end if
                exit while
            else if msg = invalid
                request.AsyncCancel()
                m.top.responseData = "error"
            end if
        end while
    end if
end sub

