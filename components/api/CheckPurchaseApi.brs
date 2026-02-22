sub init()
    m.top.functionName = "CheckPurchase"
end sub

sub CheckPurchase()
    print "CheckPurchaseApi.brs - [CheckPurchase] Called"
    
    ' Get auth data for token and sessionToken
    authData = RetrieveAuthData()
    
    if authData = invalid or authData.accessToken = invalid or authData.accessToken = ""
        print "No valid auth token found"
        m.top.responseData = "unauthorized"
        return
    end if
    
    accessToken = authData.accessToken
    
    ' Get sessionToken if available
    sessionToken = ""
    if authData.sessionToken <> invalid and authData.sessionToken <> ""
        sessionToken = authData.sessionToken
    end if
    
    ' Prepare request data - only productId is used
    data = {
        "collectionId": invalid,
        "productId": 15,
    }
    
    body = FormatJSON(data)
    
    print "=== Purchase Check Request ==="
    print "URL: https://sda.wchupload.tulix.net/api/payments/customer/check-purchase"
    print "Body: " + body
    print "Access Token: " + Left(accessToken, 20) + "..."
    print "Access Token: " + accessToken + "..."
    if sessionToken <> ""
        print "Session Token: " + Left(sessionToken, 20) + "..."
    else
        print "Session Token: Not available"
    end if
    print "=============================="
    
    port = CreateObject("roMessagePort")
    request = CreateObject("roUrlTransfer")
    request.SetMessagePort(port)
    request.SetCertificatesFile("common:/certs/ca-bundle.crt")
    request.RetainBodyOnError(true)
    request.AddHeader("Content-Type", "application/json")
    request.AddHeader("Accept", "application/json")
    request.AddHeader("Authorization", "Bearer " + accessToken)
    
    ' Add sessionToken header if available
    if sessionToken <> ""
        request.AddHeader("X-Session-Token", sessionToken)
    end if

    request.AddHeader("X-Session-Token", accessToken)
    
    request.SetRequest("POST")
    request.SetUrl("https://sda.wchupload.tulix.net/api/payments/customer/check-purchase")
    
    requestSent = request.AsyncPostFromString(body)
    if (requestSent)
        msg = wait(0, port)
        if (type(msg) = "roUrlEvent")
            statusCode = msg.GetResponseCode()
            responseBody = msg.GetString()
            
            print "=== Purchase Check Response ==="
            print "Status Code: " + statusCode.ToStr()
            print "Response Body: " + responseBody
            print "==============================="
            
            if statusCode = 200
                parsedBody = ParseJSON(responseBody)
                print parsedBody
                print "Purchase check response parsed"
                
                if parsedBody <> invalid
                    ' Check if user has purchased
                    ' Assuming response has a field indicating purchase status
                    if parsedBody.data <> invalid and parsedBody.data = true
                        m.top.responseData = "purchased"
                        print "✓ User has purchased product"
                    else if parsedBody.statusCode <> invalid and parsedBody.statusCode = 200
                        m.top.responseData = "purchased"
                        print "✓ User has purchased product"
                    else
                        m.top.responseData = "not_purchased"
                        print "✗ User has not purchased product"
                    end if
                else
                    m.top.responseData = "error"
                end if
            else if statusCode = 401 or statusCode = 403
                ' Parse response to determine if it's expired session or not purchased
                parsedError = ParseJSON(responseBody)
                if parsedError <> invalid and parsedError.message <> invalid
                    errorMessage = parsedError.message
                    print "Error message: " + errorMessage
                    
                    ' Check if message indicates lack of purchase/access vs expired token
                    if Instr(1, errorMessage, "cannot access") > 0 or Instr(1, errorMessage, "not purchased") > 0
                        m.top.responseData = "not_purchased"
                        print "✗ User has not purchased - no access to content"
                    else
                        ' Assume token is invalid/expired
                        m.top.responseData = "unauthorized"
                        print "✗ Session expired or unauthorized"
                    end if
                else
                    ' Default to unauthorized if we can't parse
                    m.top.responseData = "unauthorized"
                    print "✗ Unauthorized"
                end if
            else if statusCode = 404
                m.top.responseData = "not_purchased"
                print "✗ Product not purchased"
            else if statusCode = 422
                ' Unprocessable Entity - validation error
                print "✗ Validation error (422) - Request format may be incorrect"
                print "Error response: " + responseBody
                parsedError = ParseJSON(responseBody)
                if parsedError <> invalid then
                    print parsedError
                end if
                m.top.responseData = "error"
            else
                m.top.responseData = "error"
                print "✗ Error checking purchase - Status: " + statusCode.ToStr()
                print "Error response: " + responseBody
            end if
        end if
    else
        m.top.responseData = "error"
        print "✗ Failed to send request"
    end if
end sub

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

function RegRead(key, section = invalid)
    if section = invalid section = "Default"
    sec = CreateObject("roRegistrySection", section)
    if sec.Exists(key) return sec.Read(key)
    return sec.Read(key)
end function

