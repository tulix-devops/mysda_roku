sub init()
    m.top.functionName = "AttemptToLogin"
    m.top.email = m.top.findNode("email")
    m.top.password = m.top.findNode("password")

    ' m.store = CreateObject("roSGNode", "ChannelStore")
    ' info = CreateObject("roSGNode", "ContentNode")
    ' info.addFields({ context: "signin" })
    ' m.store.requestedUserDataInfo = info
    ' m.store.requestedUserData = "email"
    ' m.store.command = "getUserData"
    ' m.store.observefield("userData", "OnEmail")

end sub



sub AttemptToLogin()
    print "LoginScreenAPI.brs - [LoginScreenAPI] Called"

    print "login attempt Started"
    data = {
        "email": m.top.email,
        "password": m.top.password,
        "deviceInfo": "rokuTV",
    }
    print data
    print "attempt Login Data"

    body = FormatJSON(data)
    port = CreateObject("roMessagePort")
    request = CreateObject("roUrlTransfer")
    request.SetMessagePort(port)
    request.SetCertificatesFile("common:/certs/ca-bundle.crt")
    request.RetainBodyOnError(true)
    request.AddHeader("Content-Type", "application/json")
    request.AddHeader("Accept", "application/json")
    request.SetRequest("POST")
    request.SetUrl("https://sda.wchupload.tulix.net/api/login")
    requestSent = request.AsyncPostFromString(FormatJSON(data))
    if (requestSent)
        msg = wait(0, port)
        if (type(msg) = "roUrlEvent")
            statusCode = msg.GetResponseCode()
            print statusCode
            headers = msg.GetResponseHeaders()
            etag = headers["Etag"]
            body = msg.GetString()
            if statusCode = 405
                m.top.responseData = "405"
                return
            end if
            
            parsedBody = ParseJSON(body)
            print parsedBody 
            print "What is the ParsedBody"
            if parsedBody = invalid
                m.top.responseData = "405"
                return
            endif

            statusCode = parsedBody.statusCode
            if(statusCode = 200)
                responseData = ParseJSON(body).data
                accessToken = responseData.accessToken
                customerData = responseData.customer
                
                print responseData
                print "BODY"
                print customerData
                print "CUSTOMER DATA"
                
                ' Extract customer info
                customerEmail = ""
                customerName = ""
                customerLastname = ""
                customerId = 0
                sessionToken = ""
                
                if customerData <> invalid then
                    if customerData.email <> invalid then customerEmail = customerData.email
                    if customerData.name <> invalid then customerName = customerData.name
                    if customerData.lastname <> invalid then customerLastname = customerData.lastname
                    if customerData.id <> invalid then customerId = customerData.id
                end if
                
                ' Check for sessionToken in response
                if responseData.sessionToken <> invalid then
                    sessionToken = responseData.sessionToken
                    print "SessionToken found: " + sessionToken
                end if
                
                ' Save auth data with customer info and sessionToken
                SaveAuthData(accessToken, false, true, customerEmail, customerName, customerLastname, customerId, sessionToken)
               
                m.top.responseData = "Success"
            else m.top.responseData = "Error"
            end if

            json = ParseJSON(body)
            print json
        end if
    end if

end sub


sub OnEmail()
    if m.store.userData <> invalid
        email = m.store.userData.email
        print email
        print "Email I want to Check please."
    end if
end sub



function SaveAuthData(accessToken as string, subscribed as boolean, isauth as boolean, customerEmail = "" as string, customerName = "" as string, customerLastname = "" as string, customerId = 0 as integer, sessionToken = "" as string)
    section = "AUTH"
    sec = CreateObject("roRegistrySection", section)
    if subscribed
        subscribedValue = 1
    else
        subscribedValue = 0
    end if

    if isauth
        isAuthValue = 1
    else
        isAuthValue = 0
    end if

    currentTime = CreateObject("roDateTime").asSeconds()
    expiryTime = currentTime + 10 * 24 * 60 * 60

    data = {
        accessToken: accessToken,
        subscribed: subscribedValue,
        expiry: expiryTime,
        isauth: isAuthValue,
        customerEmail: customerEmail,
        customerName: customerName,
        customerLastname: customerLastname,
        customerId: customerId,
        sessionToken: sessionToken
    }
    jsonData = FormatJson(data)
    sec.Write("authData", jsonData)
    sec.Flush()
    
    print "Saved customer data - Email: " + customerEmail + ", Name: " + customerName
    if sessionToken <> "" then
        print "SessionToken saved"
    end if
end function


function RetrieveAuthData() as object
    section = "AUTH"
    jsonData = RegRead("authData", section)
    if jsonData <> invalid and jsonData <> ""
        data = ParseJson(jsonData)
        currentTime = CreateObject("roDateTime").asSeconds()
        if currentTime <= data.expiry
            return data
        else
            return invalid
        end if
    else
        return invalid
    end if
end function






function RegWrite(key, val, section = invalid)
    if section = invalid section = "Default"
    sec = CreateObject("roRegistrySection", section)
    sec.Write(key, val)
    sec.Flush() 'commit it
end function


function RegRead(key, section = invalid)
    if section = invalid section = "Default"
    sec = CreateObject("roRegistrySection", section)
    if sec.Exists(key) return sec.Read(key)
    ' return invalid
    return sec.Read(key)
end function

function RegDelete(key, section = invalid)
    if section = invalid section = "Default"
    sec = CreateObject("roRegistrySection", section)
    sec.Delete(key)
    sec.Flush()
end function

