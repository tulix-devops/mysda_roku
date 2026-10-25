' ============================================================================
' ScNet.brs - HTTP and the stored session, for Task threads only.
'
' Endpoints are the ones the build already used (context-brief.md, 2026-10-25):
'   catalogue     GET  https://sda.wchupload.tulix.net/api/content/{8,9,10}/list?limit=200
'   schedule      GET  <dvr_url> = https://livetv.mysdatv.com/api/getdvr.php?id=<stream>
'   sign-in       POST https://sda.wchupload.tulix.net/api/login
'   catch-up      POST https://sda.wchupload.tulix.net/api/payments/customer/check-purchase
' The session is registry AUTH/authData, the SAME JSON record the old build
' wrote (LoginScreenApi.SaveAuthData), so a viewer already signed in stays
' signed in across the redesign.
' ============================================================================

function ScApiBase() as string
    return "https://sda.wchupload.tulix.net/api"
end function

' One request, waited on with a timeout. Returns { code, body }: code is the
' HTTP status, 0 on a timeout, negative for a libcurl error
' (knowledge/dev-roku/negative-response-code-is-a-libcurl-error-not-http-status).
function ScHttp(method as string, url as string, body as string, headers as object, timeoutMs as integer) as object
    port = CreateObject("roMessagePort")
    req = CreateObject("roUrlTransfer")
    req.SetMessagePort(port)
    req.SetCertificatesFile("common:/certs/ca-bundle.crt")
    req.InitClientCertificates()
    req.RetainBodyOnError(true)
    req.EnableEncodings(true)
    req.SetUrl(url)
    for each h in headers
        req.AddHeader(h[0], h[1])
    end for
    sent = false
    if method = "GET"
        sent = req.AsyncGetToString()
    else
        req.SetRequest(method)
        sent = req.AsyncPostFromString(body)
    end if
    if not sent then return { code: -1, body: "" }
    msg = wait(timeoutMs, port)
    if type(msg) = "roUrlEvent"
        return { code: msg.GetResponseCode(), body: msg.GetString() }
    end if
    req.AsyncCancel()
    return { code: 0, body: "" }
end function

' ------------------------------------------------------------- session --

function ScReadAuth() as dynamic
    sec = CreateObject("roRegistrySection", "AUTH")
    if not sec.Exists("authData") then return invalid
    raw = sec.Read("authData")
    if raw = invalid or raw = "" then return invalid
    data = ParseJson(raw)
    if data = invalid or data.expiry = invalid then return invalid
    if CreateObject("roDateTime").AsSeconds() > data.expiry then return invalid
    if data.accessToken = invalid or data.accessToken = "" then return invalid
    return data
end function

' The same record LoginScreenApi.SaveAuthData wrote: 10-day expiry,
' subscribed 0 (the build never learned it), isauth 1.
sub ScWriteAuth(d as object)
    customer = d.customer
    email = ""
    name = ""
    lastname = ""
    cid = 0
    if customer <> invalid
        if customer.email <> invalid then email = customer.email
        if customer.name <> invalid then name = customer.name
        if customer.lastname <> invalid then lastname = customer.lastname
        if customer.id <> invalid then cid = customer.id
    end if
    session = ""
    if d.sessionToken <> invalid then session = d.sessionToken
    rec = {
        accessToken: d.accessToken,
        subscribed: 0,
        expiry: CreateObject("roDateTime").AsSeconds() + 10 * 24 * 60 * 60,
        isauth: 1,
        customerEmail: email,
        customerName: name,
        customerLastname: lastname,
        customerId: cid,
        sessionToken: session
    }
    sec = CreateObject("roRegistrySection", "AUTH")
    sec.Write("authData", FormatJson(rec))
    sec.Flush()
end sub

sub ScClearAuth()
    sec = CreateObject("roRegistrySection", "AUTH")
    sec.Delete("authData")
    sec.Flush()
end sub
