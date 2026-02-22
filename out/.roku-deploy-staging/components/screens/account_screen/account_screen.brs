function init()
    ' initializeComedyMovies()

    m.logoutGroup = m.top.findNode("logoutGroup")

    m.loginGroup = m.top.findNode("loginGroup")

    ' m.top.accountStatus = false

    m.top.ObserveField("accountStatus", "authorizationStatusChanged")
    m.top.ObserveField("visible", "VisibilityChanged")

    m.confirmationButtons = CreateObject("roSGNode", "BackDialog")
    m.confirmationButtons.title = "Log Out"
    m.confirmationButtons.message = "Are you sure you want to log out?"
    m.confirmationButtons.ObserveField("buttonSelected", "onConfirmationButtonSelected")


    m.loggedOutSuccessfully = CreateObject("roSGNode", "BackDialog")
    m.loggedOutSuccessfully.title = "Log Out"
    m.loggedOutSuccessfully.message = "You logged out successfully!"
    m.loggedOutSuccessfully.ObserveField("buttonSelected", "onLoggedOutSuccessfulySelected")

    ' validateAccountStatus()

    m.loginGroup.visible = false
    m.logoutGroup.visible = true

end function

function VisibilityChanged()
    if m.top.visible = true then
        print("hello Visibility Changed")
        validateAccountStatus()
    end if
end function

function authorizationStatusChanged()
    ' print "OLA AMIGOS"
    ' if m.top.accountStatus = true then
    '     ' activateLogoutButton()
    '     ' deactivateLoginButton()
    '     m.loginGroup.visible = false
    '     m.logoutGroup.visible = true
    ' else
    '     ' activateLoginButton()
    '     ' deactivateLogoutButton()
    '     print "LOGIN BUTTON MUST BE VISIBLE????"
    '     m.loginGroup.visible = true
    '     m.logoutGroup.visible = false
    ' end if
end function

sub onLoggedOutSuccessfulySelected()
    TopDialogClose()
end sub

sub onConfirmationButtonSelected()
    print m.confirmationButtons.buttonSelected
    print "Here is what hapens when you click on it"

    if m.confirmationButtons.buttonSelected = 1 then
        TopDialogClose()
        activateLogoutButton()
    else
        ClearAuthData()
        showLoggedOutSuccessfullyDialog()

    end if
end sub

sub showLoggedOutSuccessfullyDialog()
    m.top.accountStatus = false
    ' activateLoginButton()
    ' deactivateLogoutButton()
    arrayButtons = []
    arrayButtons.Push("Close")

    m.loggedOutSuccessfully.buttons = arrayButtons
    m.loggedOutSuccessfully.optionsDialog = true
    m.top.GetScene().dialog = m.loggedOutSuccessfully
    m.top.GetScene().dialog.setFocus(true)
    m.loggedOutSuccessfully.observeField("buttonSelected", "onDialogButtonSelected")



end sub


sub onDialogButtonSelected(event as object)
    m.top.visible = false
    m.global.findNode("navigation_bar").visible = false
    m.global.findNode("login_screen").visible = true
    m.global.findNode("login_screen").setFocus(true)
    m.top.GetScene().dialog = invalid
end sub



sub showConfirmationDialog()
    arrayButtons = []
    arrayButtons.Push("Yes")
    arrayButtons.Push("No")

    m.confirmationButtons.buttons = arrayButtons
    m.confirmationButtons.optionsDialog = true
    m.top.GetScene().dialog = m.confirmationButtons
    m.top.GetScene().dialog.setFocus(true)
end sub

sub TopDialogClose()
    if m.top.GetScene().dialog <> invalid then
        m.top.GetScene().dialog.close = true
    end if
end sub


function ClearAuthData()
    section = "AUTH"
    sec = CreateObject("roRegistrySection", section)

    ' Clear the auth data
    sec.Delete("authData")
    sec.Flush()

    print "Auth data cleared successfully."
end function

sub validateAccountStatus()
    authData = RetrieveAuthData()

    print "OLA AMIGOS"
    print authData
    if authData <> invalid
        if authData.accessToken <> invalid
            print authData.accessToken
            print "Here is the Access TOKEN!!!"
            m.top.accountStatus = true
            ' m.loginGroup.visible = false
            ' m.logoutGroup.visible = true
        else
            m.top.accountStatus = false
            ' m.loginGroup.visible = true
            ' m.logoutGroup.visible = false
        end if
    else
        print "AUTHDATA iS INVALID"
        m.top.accountStatus = false
        authorizationStatusChanged()
        ' m.loginGroup.visible = true
        ' m.logoutGroup.visible = false
    end if
end sub


function RetrieveAuthData() as object
    section = "AUTH"
    jsonData = RegRead("authData", section)
    print jsonData
    print "Here is JSON DATA??????"
    ' Check if the JSON data is valid
    if jsonData <> invalid and jsonData <> ""
        ' Deserialize the JSON string back into an associative array
        data = ParseJson(jsonData)
        print data
        print "we are Here?"
        currentTime = CreateObject("roDateTime").asSeconds()

        ' Check if the data is expired
        if currentTime <= data.expiry
            ' Data is valid
            return data
        else
            ' Data is expired
            return invalid
        end if
    else
        ' No valid data found
        return invalid
    end if
end function


function RegRead(key, section = invalid)
    if section = invalid section = "Default"
    sec = CreateObject("roRegistrySection", section)
    if sec.Exists(key) return sec.Read(key)
    ' return invalid
    return sec.Read(key)
end function


function onKeyEvent(key as string, press as boolean) as boolean
    ' if not press then return false end if
    print press
    print key
    print "Hello KeyPress"
    if press = false and key = "right"
        if m.top.hasFocus() then
            activateLogoutButton()
            return true
        end if
        return true
    else if press = false and key = "OK" then
        ' m.navBar = m.global.findNode("navigation_bar")
        ' m.navBar.setFocus(true)
        ' m.navBar.navHasFocus = true
        ' deactivateLogoutButton()
        ' deactivateLoginButton()
        return true

    else if (press = false or press = true) and key = "back" then
        m.navBar = m.global.findNode("navigation_bar")
        m.navBar.setFocus(true)
        m.navBar.navHasFocus = true
        deactivateLogoutButton()
        deactivateLoginButton()
        return true
    else if (press = false) and key = "back" then

        return true
    end if

    if press = true and key = "OK" then
        ' homeScreen = m.global.findNode("account_screen")
        ' if homeScreen <> invalid and homeScreen.hasFocus()
        '     activateLogoutButton()
        ' end if

        if m.logoutGroup.hasFocus() then
            showConfirmationDialog()
            return true
        end if

        ' if m.loginGroup.hasFocus() then
        '     ' showConfirmationDialog()
        '     navigateToLoginPage()
        '     return true
        ' end if

        ' m.moviesContainer.getChild(0).getChild(0).visible = true
    else if key = "left" and press = true
        m.navBar = m.global.findNode("navigation_bar")
        m.navBar.setFocus(true)
        m.navBar.navHasFocus = true
        deactivateLogoutButton()
        deactivateLoginButton()
        return true


    end if


    return false ' Return true if the key event was handled

    return false
end function

function navigateToLoginPage()
    m.global.findNode("navigation_bar").visible = false
    m.top.visible = false
    m.loginScreen = m.global.findNode("login_screen")
    m.loginScreen.visible = true
    m.loginScreen.focusable = true
    m.loginScreen.isNavigatedFromAccountTab = true
    m.loginScreen.setFocus(true)
end function


function activateLogoutButton()
    m.logoutGroup.setFocus(true)
    m.logoutIcon = m.top.findNode("logoutIcon")
    m.logoutIcon.uri = "pkg:/images/png/logout_active.png"
    m.logoutText = m.top.findNode("logoutText")
    m.logoutText.color = "#fe4a65"
end function


function deactivateLogoutButton()
    m.logoutIcon = m.top.findNode("logoutIcon")
    m.logoutIcon.uri = "pkg:/images/png/logout.png"
    m.logoutText = m.top.findNode("logoutText")
    m.logoutText.color = "0xFFFFFF"
end function



function activateLoginButton()
    m.loginGroup.setFocus(true)
    m.loginIcon = m.top.findNode("loginIcon")
    m.loginIcon.uri = "pkg:/images/png/login_active.png"
    m.loginText = m.top.findNode("loginText")
    m.loginText.color = "#fe4a65"
end function


function deactivateLoginButton()
    m.loginIcon = m.top.findNode("loginIcon")
    m.loginIcon.uri = "pkg:/images/png/login.png"
    m.loginText = m.top.findNode("loginText")
    m.loginText.color = "0xFFFFFF"
end function
