' ============================================================================
' ScSignIn.brs - the form, the keyboard, and the one request to the scene.
' The password lives in m until it is handed over in submitRequest, which the
' scene copies straight into an ScAuthTask and empties; it is never printed
' and is wiped on the way out.
' ============================================================================

sub init()
    ScEnsureGlobals()
    m.t = ScTheme()
    ScPaint(m.top, [["groundFill", "color", "cGround"], ["logo", "uri", "logo"]])

    m.emailPlate    = m.top.findNode("emailPlate")
    m.emailValue    = m.top.findNode("emailValue")
    m.passwordPlate = m.top.findNode("passwordPlate")
    m.passwordValue = m.top.findNode("passwordValue")
    m.submit        = m.top.findNode("submit")
    m.message       = m.top.findNode("message")
    m.keyboard      = m.top.findNode("keyboard")

    heading = m.top.findNode("heading")
    heading.font = ScFont(m.t.fXB, 46)
    heading.color = m.t.cText
    lede = m.top.findNode("lede")
    lede.font = ScFont(m.t.fSemi, 24)
    lede.color = m.t.cText2
    for each id in ["emailCaption", "passwordCaption"]
        cap = m.top.findNode(id)
        cap.font = ScFont(m.t.fXB, 17)
        cap.color = m.t.cText2
    end for
    for each lab in [m.emailValue, m.passwordValue]
        lab.font = ScFont(m.t.fSemi, 26)
    end for
    m.message.font = ScFont(m.t.fSemi, 24)
    for each id in ["keyboardHint", "note"]
        n = m.top.findNode(id)
        n.font = ScFont(m.t.fSemi, 21)
        n.color = m.t.cText3
    end for
    m.emailPlate.uri = ScShape("r35")
    m.passwordPlate.uri = ScShape("r35")

    m.keyboard.observeField("text", "onTyped")
    m.keyboard.showTextEditBox = false

    m.joinCard = m.top.findNode("joinCard")
    m.giveCard = m.top.findNode("giveCard")
    ScQrCardsFill(m.joinCard, m.giveCard)

    m.email = ""
    m.password = ""
    ' 0 = email, 1 = password, 2 = Log in. The keyboard, when it holds
    ' focus, edits m.editing.
    m.focusIndex = 0
    m.editing = -1
    m.busy = false
    m.settingText = false
    m.top.observeField("focusedChild", "onFocusChanged")
end sub

sub onActiveChanged()
    if m.top.active
        m.email = ""
        m.password = ""
        m.focusIndex = 0
        m.editing = -1
        m.busy = false
        m.message.text = ""
        setKeyboardText("")
        secure(false)
        repaint()
        ' The codes are made once, just after the page first shows (each
        ' encode holds the render thread 0.1-0.3 s).
        ScQrCardsArm(m.joinCard, m.giveCard)
    else
        m.password = ""
        m.email = ""
        setKeyboardText("")
    end if
end sub

sub onFocusChanged()
    if m.top.hasFocus() then repaint()
end sub

sub onTyped()
    if m.settingText then return
    text = m.keyboard.text
    if text = invalid then text = ""
    if m.editing = 0
        m.email = text
    else if m.editing = 1
        m.password = text
    end if
    repaint()
end sub

sub setKeyboardText(text as string)
    m.settingText = true
    m.keyboard.text = text
    m.settingText = false
end sub

' Not `box`: Box() is a builtin (knowledge/dev-roku/reserved-words-and-name-collisions).
sub secure(on as boolean)
    editBox = m.keyboard.textEditBox
    if editBox <> invalid then editBox.secureMode = on
end sub

sub editField(index as integer)
    m.editing = index
    if index = 0
        secure(false)
        setKeyboardText(m.email)
    else
        secure(true)
        setKeyboardText(m.password)
    end if
    m.keyboard.setFocus(true)
    repaint()
end sub

sub leaveKeyboard()
    m.editing = -1
    ' Release the keyboard first: setFocus(true) on an ancestor while a child
    ' holds focus is a no-op (knowledge/dev-roku/setfocus-on-ancestor-does-not-reclaim).
    m.keyboard.setFocus(false)
    m.top.setFocus(true)
    repaint()
end sub

sub submitForm()
    if m.busy then return
    email = m.email.Trim()
    if email = "" or Instr(1, email, "@") = 0 or m.password = ""
        m.message.text = "Enter your email address and password."
        m.message.color = m.t.cText
        return
    end if
    m.busy = true
    m.message.text = "Logging in" + Chr(8230)
    m.message.color = m.t.cText2
    repaint()
    m.top.submitRequest = { email: email, password: m.password }
end sub

sub onAuthResult()
    res = m.top.result
    if type(res) <> "roAssociativeArray" or res.kind <> "signIn" then return
    m.busy = false
    if res.ok = true
        m.message.text = ""
        m.password = ""
        m.top.outcome = "signedIn"
        return
    end if
    m.message.color = m.t.cLive
    if res.reason = "credentials"
        m.message.text = "That email address and password don't match. Check them and try again."
    else if res.reason = "network"
        m.message.text = "This Roku can't reach mySDAtv. Check the connection and try again."
    else
        m.message.text = "We couldn't log you in. Try again."
    end if
    repaint()
end sub

function masked(n as integer) as string
    out = ""
    for i = 1 to n
        out = out + "•"
    end for
    return out
end function

sub repaint()
    formHasFocus = m.top.hasFocus()
    paintField(m.emailPlate, m.emailValue, 0, formHasFocus, m.email, "name@example.com", false)
    paintField(m.passwordPlate, m.passwordValue, 1, formHasFocus, m.password, "Your password", true)
    m.submit.lit = (formHasFocus and m.focusIndex = 2)
    if m.busy then m.submit.text = "Logging in" + Chr(8230) else m.submit.text = "Log in"
end sub

sub paintField(plate as object, value as object, index as integer, formHasFocus as boolean, text as string, hint as string, isSecret as boolean)
    focused = (formHasFocus and m.focusIndex = index)
    editing = (m.editing = index)
    if focused
        plate.blendColor = m.t.cFocus
    else if editing
        plate.blendColor = "0xFFFFFF40"
    else
        plate.blendColor = m.t.cRaised
    end if
    if text = ""
        value.text = hint
        if focused then value.color = "0x07080C99" else value.color = m.t.cText3
    else
        if isSecret then value.text = masked(Len(text)) else value.text = text
        if focused then value.color = m.t.cOnFocus else value.color = m.t.cText
    end if
end sub

' The form is one row - email, password, Log in - above the keyboard: Left /
' Right move along it, Down or OK drops into the keyboard.
function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false
    if m.editing >= 0
        if key = "back" or key = "up"
            leaveKeyboard()
            return true
        end if
        return true
    end if
    if key = "back"
        m.top.outcome = "closed"
        return true
    end if
    if key = "right"
        if m.focusIndex < 2 then m.focusIndex = m.focusIndex + 1
        repaint()
        return true
    end if
    if key = "left"
        if m.focusIndex > 0 then m.focusIndex = m.focusIndex - 1
        repaint()
        return true
    end if
    if key = "down"
        if m.focusIndex < 2 then editField(m.focusIndex) else editField(1)
        return true
    end if
    if key = "OK"
        if m.focusIndex = 2 then submitForm() else editField(m.focusIndex)
        return true
    end if
    return true
end function
