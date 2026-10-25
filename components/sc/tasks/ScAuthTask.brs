sub init()
    m.top.functionName = "work"
end sub

sub work()
    kind = m.top.kind
    if kind = "signIn"
        res = signIn()
    else if kind = "checkAccess"
        res = checkAccess()
    else
        ScClearAuth()
        res = { ok: true, reason: "", status: 0, access: "" }
    end if
    res.kind = kind
    m.top.password = ""
    m.top.result = res
end sub

' The old build's login, unchanged on the wire: {"email","password",
' "deviceInfo":"rokuTV"}; success is body.statusCode = 200.
function signIn() as object
    body = FormatJson({ email: m.top.email, password: m.top.password, deviceInfo: "rokuTV" })
    res = ScHttp("POST", ScApiBase() + "/login", body, [["Content-Type", "application/json"], ["Accept", "application/json"]], 20000)
    out = { ok: false, reason: "error", status: res.code, access: "" }
    if res.code <= 0
        out.reason = "network"
        return out
    end if
    json = ParseJson(res.body)
    if res.code = 405 or json = invalid
        out.reason = "credentials"
        return out
    end if
    code = json.statusCode
    if code = invalid then code = 0
    if code = 200 and json.data <> invalid and json.data.accessToken <> invalid
        ScWriteAuth(json.data)
        out.ok = true
        out.reason = ""
        return out
    end if
    if res.code = 401 or res.code = 403 or res.code = 422 or res.code = 400 or code = 401
        out.reason = "credentials"
    end if
    return out
end function

' The old build's purchase check, unchanged on the wire, including both
' X-Session-Token headers it sent (session token, then access token).
function checkAccess() as object
    out = { ok: false, reason: "", status: 0, access: "error" }
    auth = ScReadAuth()
    if auth = invalid
        out.access = "unauthorized"
        return out
    end if
    headers = [["Content-Type", "application/json"], ["Accept", "application/json"], ["Authorization", "Bearer " + auth.accessToken]]
    if auth.sessionToken <> invalid and auth.sessionToken <> "" then headers.push(["X-Session-Token", auth.sessionToken])
    headers.push(["X-Session-Token", auth.accessToken])
    res = ScHttp("POST", ScApiBase() + "/payments/customer/check-purchase", FormatJson({ collectionId: invalid, productId: 15 }), headers, 20000)
    out.status = res.code
    if res.code = 200
        json = ParseJson(res.body)
        if json = invalid
            out.access = "error"
        else if (json.data <> invalid and type(json.data) = "roBoolean" and json.data = true) or (json.statusCode <> invalid and json.statusCode = 200)
            out.access = "yes"
        else
            out.access = "no"
        end if
    else if res.code = 401 or res.code = 403
        json = ParseJson(res.body)
        msg = ""
        if json <> invalid and json.message <> invalid then msg = LCase(ScStr(json.message))
        if Instr(1, msg, "cannot access") > 0 or Instr(1, msg, "not purchased") > 0
            out.access = "no"
        else
            out.access = "unauthorized"
            ScClearAuth()
        end if
    else if res.code = 404
        out.access = "no"
    end if
    out.ok = (out.access = "yes" or out.access = "no")
    return out
end function
