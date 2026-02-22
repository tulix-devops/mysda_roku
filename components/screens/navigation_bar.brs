sub init()
    ' Make navigation bar focusable so it can receive key events
    m.top.focusable = true
    
    m.navGroup = m.top.findNode("navGroup")
    m.selector = m.top.findNode("selector")
    m.expandAnimation = m.top.findNode("expandAnimation")
    m.collapseAnimation = m.top.findNode("collapseAnimation")

    ' Initialize login variables
    m.authEmail = ""
    m.authPassword = ""

    m.menuItems = ["live", "archive", "dvr", "radios", "logout"]
    m.selectedIndex = 0
    
    ' Check if user is actually logged in
    authData = RetrieveAuthData()
    if authData <> invalid and authData.isauth = 1 then
        m.isLoggedIn = true
        print "User is logged in - showing Logout"
    else
        m.isLoggedIn = false
        print "User is not logged in - showing Login"
    end if
    
    m.top.observeField("userLoggedIn", "onUserLoggedIn")
    ' m.top.findNode("liveActive").visible = true
    ' m.top.findNode("liveInactive").visible = false
    ' m.top.findNode("live").color = "0x007199"
    
    ' m.top.findNode("televisionIconActive").opacity  = 1
    ' m.top.findNode("televisionIconActive").scale = 1
    ' m.top.findNode("televisionIconInactive").opacity = 0
    ' m.top.findNode("televisionIconInactive").scale = 0
    ' m.top.findNode("live").opacity = 0
    ' m.top.findNode("live").scale = 0
    m.top.observeField("isVisible", "toggleNavVisibility")
    m.top.observeField("selectedIndex", "updateSelection")
    updateLiveRow(false)
    updateTelevisionLanguages(false)
    updateRadios(false)
    updateDvr(false)
    updateLogout(false)

end sub

sub toggleNavVisibility(event as object)
    if event.getData() = true then
        disableFullContentMode()
        m.expandAnimation.control = "start"
    else
        enableFullContentMode()
        m.collapseAnimation.control = "start"
    end if
  
    updateLiveRow(event.getData())
    updateTelevisionLanguages(event.getData())
    updateRadios(event.getData())
    updateDvr(event.getData())
    updateLogout(event.getData())
end sub

sub updateSelection()


    m.global.findNode("vod_screen").visible = false
    m.global.findNode("second_vod").visible = false
    m.global.findNode("third_vod").visible = false
    m.global.findNode("dvr_vod").visible = false
    
    ' Hide LoginInfoScreen by default
    homeScene = m.top.getScene()
    if homeScene <> invalid then
        loginInfoScreen = homeScene.findNode("loginInfoScreen")
        if loginInfoScreen <> invalid then
            loginInfoScreen.visible = false
        end if
    end if

    if m.selectedIndex = 0
        m.global.findNode("vod_screen").visible = true
        updateLiveRow(true)
        updateTelevisionLanguages(true)
        updateRadios(true)
        updateDvr(true)
        updateLogout(true)
    else if m.selectedIndex = 1
        m.global.findNode("second_vod").visible = true
        updateLiveRow(true)
        updateTelevisionLanguages(true)
        updateRadios(true)
        updateDvr(true)
        updateLogout(true)
    else if m.selectedIndex = 2
        m.global.findNode("dvr_vod").visible = true
        updateLiveRow(true)
        updateTelevisionLanguages(true)
        updateRadios(true)
        updateDvr(true)
        updateLogout(true)
    else if m.selectedIndex = 3
        m.global.findNode("third_vod").visible = true
        updateLiveRow(true)
        updateTelevisionLanguages(true)
        updateRadios(true)
        updateDvr(true)
        updateLogout(true)
    else if m.selectedIndex = 4
        ' Login/Logout selected
        ' Show LoginInfoScreen when hovering over Login/Logout button
        if homeScene <> invalid and loginInfoScreen <> invalid then
            loginInfoScreen.visible = true
        end if
        
        updateLiveRow(true)
        updateTelevisionLanguages(true)
        updateRadios(true)
        updateDvr(true)
        updateLogout(true)
    end if
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    print "NavigationScreen.brs - [onKeyEvent] key = "; key; ", isPressed = "; press
    print "   hasFocus = "; m.top.hasFocus(); ", focusable = "; m.top.focusable

    if press
        if key = "up"
            m.selectedIndex = (m.selectedIndex - 1 + m.menuItems.count()) mod m.menuItems.count()
            updateSelection()
        else if key = "down"
            m.selectedIndex = (m.selectedIndex + 1) mod m.menuItems.count()
            updateSelection()
        else if key = "OK"
            ' Handle OK button press
            if m.selectedIndex = 4 then
                ' Check if user is logged in or out
                if m.isLoggedIn = true then
                    ' Show logout confirmation dialog
                    showLogoutConfirmation()
                else
                    ' Show login screen
                    performLogin()
                end if
                return true
            end if
        else if key = "right" or key = "back" then

            if m.selectedIndex = 0 then
                m.global.findNode("vod_screen").setFocus(true)
                m.top.isVisible = false
            else if m.selectedIndex = 1 then
                m.top.isVisible = false
                m.global.findNode("second_vod").setFocus(true)
            else if m.selectedIndex = 2 then
                m.top.isVisible = false
                m.global.findNode("dvr_vod").setFocus(true)
            else if m.selectedIndex = 3 then
                m.top.isVisible = false
                m.global.findNode("third_vod").setFocus(true)
            else if m.selectedIndex = 4 then
                ' Check if user is logged in or out
                if m.isLoggedIn = true then
                    ' Show logout confirmation dialog
                    showLogoutConfirmation()
                else
                    ' Show login screen
                    performLogin()
                end if
                return true
            end if

            ' liveVideoPlayer = m.global.findNode("LiveVideoPlayer")
            ' liveVideoPlayer.setFocus(true)
            return true

        end if
        return true
    end if
    return false
end function


sub enableFullContentMode()
    VodScreen = m.global.findNode("vod_screen") ' Find VodScreen node
    SecondVodScreen = m.global.findNode("second_vod")
    ThirdVodScreen = m.global.findNode("third_vod")
    DvrVodScreen = m.global.findNode("dvr_vod")
    if VodScreen <> invalid then
        print "Setting showFullContent to TRUE in VodScreen"
        VodScreen.showFullContent = true ' Directly set it to TRUE
        SecondVodScreen.showFullContent = true
        ThirdVodScreen.showFullContent = true
        DvrVodScreen.showFullContent = true
    else
        print "Error: VodScreen not found!"
    end if
end sub

sub disableFullContentMode()
    
    VodScreen = m.global.findNode("vod_screen") ' Find VodScreen node
    SecondVodScreen = m.global.findNode("second_vod")
    ThirdVodScreen = m.global.findNode("third_vod")
    DvrVodScreen = m.global.findNode("dvr_vod")
    if VodScreen <> invalid then
        print "Setting showFullContent to TRUE in VodScreen"
        VodScreen.showFullContent = false 
        SecondVodScreen.showFullContent = false
        ThirdVodScreen.showFullContent = false
        DvrVodScreen.showFullContent = false
    else
        print "Error: VodScreen not found!"
    end if
end sub

' sub exitApplication()
'     mainScene = m.top.getScene() ' Get reference to MainScene

'     if mainScene <> invalid
'         print "Exiting Application via NavigationScreen"
'         print "Setting exitApp to TRUE"

'         mainScene.exitApp = true ' Trigger exit

'         print "exitApp is now: "; mainScene.exitApp ' Debug: Print the value
'     else
'         print "Error: MainScene reference not found!"
'     end if
' end sub


sub openOptionsDialog()
    heroScene = m.top.getScene() ' Get the parent HeroScene

    if heroScene = invalid then
        print "❌ ERROR: HeroScene is INVALID!"
        return
    end if

    print "✅ HeroScene FOUND! Attempting to call showOptionsDialog()..."

    ' Call function using callFunc()
    result = heroScene.callFunc("showOptionsDialog")

    if result = invalid then
        print "❌ ERROR: showOptionsDialog() function call failed!"
    else
        print "✅ showOptionsDialog() executed successfully!"
    end if
end sub



sub updateLiveRow(isNavExpanded as Boolean)
    liveRow = m.top.findNode("liveRow")
    childCount = liveRow.getChildCount()
    for i = childCount - 1 to 0 step -1
        liveRow.removeChildIndex(i)
    end for
    
    labelColor = "0x888888"
    if m.selectedIndex = 0
        labelColor = "0xFFFFFF"
    end if

    if isNavExpanded
        if m.selectedIndex = 0 then 
            activeIcon = createObject("roSGNode", "Poster")
            activeIcon.uri = "pkg:/images/png/television_active_optimized.png"
            activeIcon.width = 100
            activeIcon.height = 100
            activeIcon.loadDisplayMode = "scaleToZoom"
            liveRow.appendChild(activeIcon)
        else
            inactiveIcon = createObject("roSGNode", "Poster")
            inactiveIcon.uri = "pkg:/images/png/television_inactive_optimized.png"
            inactiveIcon.width = 100
            inactiveIcon.height = 100
            inactiveIcon.loadDisplayMode = "scaleToZoom"
            liveRow.appendChild(inactiveIcon)
        end if

        labelWrapper = createObject("roSGNode", "Group")
        labelWrapper.translation = [0, 40]
        label = createObject("roSGNode", "Label")
        label.text = "Television"
        label.height = 48
        label.font = "font:SmallBoldSystemFont"
        label.color = labelColor
        
        labelWrapper.appendChild(label)
        liveRow.appendChild(labelWrapper)

        ' m.top.findNode("shiftLiveRow").control = "start"
    else
        if m.selectedIndex = 0 then 
            activeIcon = createObject("roSGNode", "Poster")
            activeIcon.uri = "pkg:/images/png/television_active_optimized.png"
            activeIcon.width = 100
            activeIcon.height = 100
            activeIcon.loadDisplayMode = "scaleToZoom"
            liveRow.appendChild(activeIcon)
        else
            inactiveIcon = createObject("roSGNode", "Poster")
            inactiveIcon.uri = "pkg:/images/png/television_inactive_optimized.png"
            inactiveIcon.width = 100
            inactiveIcon.height = 100
            inactiveIcon.loadDisplayMode = "scaleToZoom"
            liveRow.appendChild(inactiveIcon)
        end if
        ' m.top.findNode("shiftLiveRow").reverse = true
        ' m.top.findNode("shiftLiveRow").control = "start"
  
        
    end if
end sub



sub updateTelevisionLanguages(isNavExpanded as Boolean)
    televisionLanguageRow = m.top.findNode("archiveRow")
    childCount = televisionLanguageRow.getChildCount()
    for i = childCount - 1 to 0 step -1
        televisionLanguageRow.removeChildIndex(i)
    end for

    labelColor = "0x888888"
    if m.selectedIndex = 1
        labelColor = "0xFFFFFF"
    end if

    if isNavExpanded
        if m.selectedIndex = 1 then 
            activeIcon = createObject("roSGNode", "Poster")
            activeIcon.uri = "pkg:/images/png/television_language_optimized.png"
            activeIcon.width = 100
            activeIcon.height = 100
            activeIcon.loadDisplayMode = "scaleToZoom"
            televisionLanguageRow.appendChild(activeIcon)
        else
            inactiveIcon = createObject("roSGNode", "Poster")
            inactiveIcon.uri = "pkg:/images/png/television_languages_inactive.png"
            inactiveIcon.width = 100
            inactiveIcon.height = 100
            inactiveIcon.loadDisplayMode = "scaleToZoom"
            televisionLanguageRow.appendChild(inactiveIcon)
        end if
        labelWrapper = createObject("roSGNode", "Group")
        labelWrapper.translation = [0, 40]
        label = createObject("roSGNode", "Label")
        label.text = "Television Languages"
        label.height = 48
        label.font = "font:SmallBoldSystemFont"
        label.color = labelColor
        labelWrapper.appendChild(label)
        televisionLanguageRow.appendChild(labelWrapper)
    else
        if m.selectedIndex = 1 then 
            activeIcon = createObject("roSGNode", "Poster")
            activeIcon.uri = "pkg:/images/png/television_language_optimized.png"
            activeIcon.width = 100
            activeIcon.height = 100
            activeIcon.loadDisplayMode = "scaleToZoom"
            televisionLanguageRow.appendChild(activeIcon)
        else
            inactiveIcon = createObject("roSGNode", "Poster")
            inactiveIcon.uri = "pkg:/images/png/television_languages_inactive.png"
            inactiveIcon.width = 100
            inactiveIcon.height = 100
            inactiveIcon.loadDisplayMode = "scaleToZoom"
            televisionLanguageRow.appendChild(inactiveIcon)
        end if
  
        
    end if
end sub


sub updateRadios(isNavExpanded as Boolean)
    radiosRow = m.top.findNode("exitRow")
    childCount = radiosRow.getChildCount()
    for i = childCount - 1 to 0 step -1
        radiosRow.removeChildIndex(i)
    end for

    labelColor = "0x888888"
    if m.selectedIndex = 3
        labelColor = "0xFFFFFF"
    end if

    if isNavExpanded
        if m.selectedIndex = 3 then 
            activeIcon = createObject("roSGNode", "Poster")
            activeIcon.uri = "pkg:/images/png/radio_active_optimized.png"
            activeIcon.width = 100
            activeIcon.height = 100
            activeIcon.loadDisplayMode = "scaleToZoom"
            radiosRow.appendChild(activeIcon)
        else
            inactiveIcon = createObject("roSGNode", "Poster")
            inactiveIcon.uri = "pkg:/images/png/radio_inactive_optimized.png"
            inactiveIcon.width = 100
            inactiveIcon.height = 100
            inactiveIcon.loadDisplayMode = "scaleToZoom"
            radiosRow.appendChild(inactiveIcon)
        end if
        labelWrapper = createObject("roSGNode", "Group")
        labelWrapper.translation = [0, 40]
        label = createObject("roSGNode", "Label")
        label.text = "Radios"
        label.height = 48
        label.font = "font:SmallBoldSystemFont"
        label.color = labelColor
        labelWrapper.appendChild(label)
        radiosRow.appendChild(labelWrapper)
    else
        if m.selectedIndex = 3 then 
            activeIcon = createObject("roSGNode", "Poster")
            activeIcon.uri = "pkg:/images/png/radio_active_optimized.png"
            activeIcon.width = 100
            activeIcon.height = 100
            activeIcon.loadDisplayMode = "scaleToZoom"
            radiosRow.appendChild(activeIcon)
        else
            inactiveIcon = createObject("roSGNode", "Poster")
            inactiveIcon.uri = "pkg:/images/png/radio_inactive_optimized.png"
            inactiveIcon.width = 100
            inactiveIcon.height = 100
            inactiveIcon.loadDisplayMode = "scaleToZoom"
            radiosRow.appendChild(inactiveIcon)
        end if
  
        
    end if
end sub

sub updateDvr(isNavExpanded as Boolean)
    dvrRow = m.top.findNode("dvrRow")
    childCount = dvrRow.getChildCount()
    for i = childCount - 1 to 0 step -1
        dvrRow.removeChildIndex(i)
    end for

    labelColor = "0x888888"
    if m.selectedIndex = 2
        labelColor = "0xFFFFFF"
    end if

    if isNavExpanded
        if m.selectedIndex = 2 then 
            activeIcon = createObject("roSGNode", "Poster")
            activeIcon.uri = "pkg:/images/png/television_active_optimized.png"
            activeIcon.width = 100
            activeIcon.height = 100
            activeIcon.loadDisplayMode = "scaleToZoom"
            dvrRow.appendChild(activeIcon)
        else
            inactiveIcon = createObject("roSGNode", "Poster")
            inactiveIcon.uri = "pkg:/images/png/television_inactive_optimized.png"
            inactiveIcon.width = 100
            inactiveIcon.height = 100
            inactiveIcon.loadDisplayMode = "scaleToZoom"
            dvrRow.appendChild(inactiveIcon)
        end if
        labelWrapper = createObject("roSGNode", "Group")
        labelWrapper.translation = [0, 40]
        label = createObject("roSGNode", "Label")
        label.text = "DVR"
        label.height = 48
        label.font = "font:SmallBoldSystemFont"
        label.color = labelColor
        labelWrapper.appendChild(label)
        dvrRow.appendChild(labelWrapper)
    else
        if m.selectedIndex = 2 then 
            activeIcon = createObject("roSGNode", "Poster")
            activeIcon.uri = "pkg:/images/png/television_active_optimized.png"
            activeIcon.width = 100
            activeIcon.height = 100
            activeIcon.loadDisplayMode = "scaleToZoom"
            dvrRow.appendChild(activeIcon)
        else
            inactiveIcon = createObject("roSGNode", "Poster")
            inactiveIcon.uri = "pkg:/images/png/television_inactive_optimized.png"
            inactiveIcon.width = 100
            inactiveIcon.height = 100
            inactiveIcon.loadDisplayMode = "scaleToZoom"
            dvrRow.appendChild(inactiveIcon)
        end if
    end if
end sub

sub updateLogout(isNavExpanded as Boolean)
    logoutRow = m.top.findNode("logoutRow")
    childCount = logoutRow.getChildCount()
    for i = childCount - 1 to 0 step -1
        logoutRow.removeChildIndex(i)
    end for

    ' Set color based on selection - white when focused, gray when not
    labelColor = "0x888888"
    if m.selectedIndex = 4
        labelColor = "0xFFFFFF"
    end if

    ' Show text label only (no icon)
    ' Change text based on login state
    labelText = "Logout"
    if m.isLoggedIn = false then
        labelText = "Login"
    end if
    
    label = createObject("roSGNode", "Label")
    label.text = labelText
    label.height = 48
    label.font = "font:SmallBoldSystemFont"
    label.color = labelColor
    label.translation = [20, 0]
    logoutRow.appendChild(label)
end sub

sub performLogout()
    print "Performing logout..."
    
    ' Clear auth data from registry
    RegDelete("authData", "AUTH")
    print "Auth data cleared from storage"
    
    ' Update login state
    m.isLoggedIn = false
    
    ' Hide all VOD screens
    homeScene = m.top.getScene()
    if homeScene <> invalid
        vodScreen = homeScene.findNode("vod_screen")
        secondVod = homeScene.findNode("second_vod")
        thirdVod = homeScene.findNode("third_vod")
        dvrVod = homeScene.findNode("dvr_vod")
        
        if vodScreen <> invalid then vodScreen.visible = false
        if secondVod <> invalid then secondVod.visible = false
        if thirdVod <> invalid then thirdVod.visible = false
        if dvrVod <> invalid then dvrVod.visible = false
    end if
    
    ' Show success dialog at scene level
    showLogoutSuccessDialog()
end sub

sub showLogoutSuccessDialog()
    print "Showing logout success dialog..."
    
    ' Create logout success dialog at scene level
    logoutSuccessDialog = CreateObject("roSGNode", "BackDialog")
    logoutSuccessDialog.title = "Success"
    logoutSuccessDialog.message = "You have been logged out successfully."
    logoutSuccessDialog.buttons = ["OK"]
    logoutSuccessDialog.ObserveField("buttonSelected", "onLogoutSuccessDialogButton")
    
    m.top.GetScene().dialog = logoutSuccessDialog
    m.logoutSuccessDialog = logoutSuccessDialog
end sub

function RegDelete(key, section = invalid)
    if section = invalid section = "Default"
    sec = CreateObject("roRegistrySection", section)
    sec.Delete(key)
    sec.Flush()
end function

function RegRead(key, section = invalid)
    if section = invalid section = "Default"
    sec = CreateObject("roRegistrySection", section)
    if sec.Exists(key) return sec.Read(key)
    return sec.Read(key)
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

sub showLogoutConfirmation()
    print "Showing logout confirmation dialog..."
    
    ' Create logout confirmation dialog at scene level
    logoutConfirmDialog = CreateObject("roSGNode", "BackDialog")
    logoutConfirmDialog.title = "Logout"
    logoutConfirmDialog.message = "Do you really want to logout?"
    logoutConfirmDialog.buttons = ["Yes", "No"]
    logoutConfirmDialog.ObserveField("buttonSelected", "onLogoutConfirmDialogButton")
    
    m.top.GetScene().dialog = logoutConfirmDialog
    m.logoutConfirmDialog = logoutConfirmDialog
end sub

sub onLogoutConfirmDialogButton()
    buttonIndex = m.logoutConfirmDialog.buttonSelected
    
    ' Close the dialog
    if m.top.GetScene().dialog <> invalid
        m.top.GetScene().dialog.close = true
    end if
    
    ' Button 0 = Yes, Button 1 = No
    if buttonIndex = 0 then
        ' User confirmed logout
        performLogout()
    else
        ' User cancelled, ensure navigation is visible and return focus
        if m.top.isVisible = false then
            m.top.isVisible = true
        end if
        
        ' Ensure navigation has focus and is focusable
        m.top.focusable = true
        m.top.setFocus(true)
        print "Logout cancelled - returning to navigation"
    end if
end sub

sub onLogoutSuccessDialogButton()
    print "=== onLogoutSuccessDialogButton - closing dialog and restoring focus ==="
    
    ' Close the dialog
    if m.top.GetScene().dialog <> invalid
        m.top.GetScene().dialog.close = true
    end if
    
    ' Make sure navigation is visible and expanded
    if m.top.isVisible = false then
        m.top.isVisible = true
    end if
    
    ' Force update of the current selection to refresh the logout/login label
    m.selectedIndex = 4 ' Keep on logout/login option
    m.top.selectedIndex = 4
    
    ' Update login state flag so label changes
    m.isLoggedIn = false
    
    ' Update UI elements (this rebuilds the logout/login label)
    updateLiveRow(true)
    updateTelevisionLanguages(true)
    updateRadios(true)
    updateDvr(true)
    updateLogout(true)
    
    ' Force focus back to navigation
    print "   Setting focus to navigation bar..."
    print "   Before: hasFocus = "; m.top.hasFocus(); ", focusable = "; m.top.focusable
    
    m.top.focusable = true
    m.top.setFocus(true)
    
    print "   After: hasFocus = "; m.top.hasFocus(); ", focusable = "; m.top.focusable
    print "✓ Logout complete - label changed to Login, focus restored to navigation"
end sub

sub performLogin()
    print "Starting keyboard login..."
    
    ' Since LoginInfoScreen is already shown on hover,
    ' directly start the keyboard login flow when user presses OK
    showEmailDialog()
end sub

sub startKeyboardLogin()
    ' This function can be called externally (e.g., from LoginInfoScreen)
    ' to start the keyboard-based login flow
    print "Starting keyboard login flow..."
    showEmailDialog()
end sub

sub showEmailDialog()
    print "Showing email dialog..."
    
    ' Create username/email keyboard dialog
    usernameDialog = CreateObject("roSGNode", "KeyboardDialog")
    usernameDialog.title = "Login"
    usernameDialog.text = ""
    usernameDialog.buttons = ["Next", "Cancel"]
    usernameDialog.ObserveField("buttonSelected", "onUsernameDialogButton")
    
    m.top.GetScene().dialog = usernameDialog
    m.usernameDialog = usernameDialog
end sub

sub onUsernameDialogButton()
    if m.usernameDialog.buttonSelected = 0
        ' Next button - save email and show password dialog
        m.authEmail = m.usernameDialog.text
        if m.authEmail.Len() > 0
            m.usernameDialog.close = true
            showPasswordDialog()
        else
            m.usernameDialog.message = "Please enter your email"
        end if
    else
        ' Cancel button
        m.usernameDialog.close = true
        m.top.isVisible = true
        m.top.focusable = true
        m.top.setFocus(true)
        print "Login cancelled - returning to navigation"
    end if
end sub

sub showPasswordDialog()
    print "Showing password dialog..."
    
    passwordDialog = CreateObject("roSGNode", "KeyboardDialog")
    passwordDialog.title = "Enter Password"
    passwordDialog.text = ""
    passwordDialog.secure = true
    passwordDialog.buttons = ["Login", "Cancel"]
    passwordDialog.ObserveField("buttonSelected", "onPasswordDialogButton")
    
    m.top.GetScene().dialog = passwordDialog
    m.passwordDialog = passwordDialog
end sub

sub onPasswordDialogButton()
    if m.passwordDialog.buttonSelected = 0
        ' Login button - attempt login
        m.authPassword = m.passwordDialog.text
        if m.authPassword.Len() > 0
            m.passwordDialog.close = true
            attemptNavLogin()
        else
            m.passwordDialog.message = "Please enter your password"
        end if
    else
        ' Cancel button
        m.passwordDialog.close = true
        m.authEmail = ""
        m.top.isVisible = true
        m.top.focusable = true
        m.top.setFocus(true)
        print "Login cancelled - returning to navigation"
    end if
end sub

sub attemptNavLogin()
    print "Attempting login with email: " + m.authEmail
    
    ' Show loading dialog
    progressDialog = CreateObject("roSGNode", "ProgressDialog")
    progressDialog.title = "Authenticating..."
    m.top.GetScene().dialog = progressDialog
    
    ' Create and run login API task
    m.loginApi = CreateObject("roSGNode", "LoginScreenApi")
    m.loginApi.observeField("responseData", "handleNavLoginResponse")
    m.loginApi.email = m.authEmail
    m.loginApi.password = m.authPassword
    m.loginApi.control = "RUN"
end sub

sub handleNavLoginResponse()
    data = m.loginApi.responseData
    
    ' Close progress dialog
    if m.top.GetScene().dialog <> invalid
        m.top.GetScene().dialog.close = true
    end if
    
    if data = "Success"
        print "✓ Login successful from navigation!"
        
        ' Clear credentials
        m.authEmail = ""
        m.authPassword = ""
        
        ' Update login state
        m.isLoggedIn = true
        
        ' Update navigation display
        m.top.isVisible = true
        m.selectedIndex = 4
        m.top.selectedIndex = 4
        updateSelection()
        
        ' Show success message
        showLoginSuccessDialog()
    else if data = "405"
        print "✗ Login failed - incorrect credentials"
        showAuthErrorDialog("Incorrect email or password")
    else
        print "✗ Login failed - error occurred"
        showAuthErrorDialog("Authentication error occurred")
    end if
end sub

sub showLoginSuccessDialog()
    successDialog = CreateObject("roSGNode", "BackDialog")
    successDialog.title = "Success"
    successDialog.message = "You have been logged in successfully!"
    successDialog.buttons = ["OK"]
    successDialog.ObserveField("buttonSelected", "onLoginSuccessDialogButton")
    m.top.GetScene().dialog = successDialog
    m.loginSuccessDialog = successDialog
end sub

sub onLoginSuccessDialogButton()
    if m.top.GetScene().dialog <> invalid
        m.top.GetScene().dialog.close = true
    end if
    
    ' Return focus to navigation
    m.top.isVisible = true
    m.top.focusable = true
    
    ' Update UI to ensure login/logout label is correct
    updateSelection()
    
    ' Set focus AFTER UI update is complete
    m.top.setFocus(true)
    print "Login success dialog closed - returning to navigation"
end sub

sub showAuthErrorDialog(errorMessage as string)
    errorDialog = CreateObject("roSGNode", "BackDialog")
    errorDialog.title = "Authentication Failed"
    errorDialog.message = errorMessage
    errorDialog.buttons = ["Retry", "Cancel"]
    errorDialog.ObserveField("buttonSelected", "onAuthErrorDialogButton")
    m.top.GetScene().dialog = errorDialog
    m.authErrorDialog = errorDialog
end sub

sub onAuthErrorDialogButton()
    buttonIndex = m.authErrorDialog.buttonSelected
    
    if m.top.GetScene().dialog <> invalid
        m.top.GetScene().dialog.close = true
    end if
    
    if buttonIndex = 0
        ' Retry - show email dialog again
        m.authEmail = ""
        m.authPassword = ""
        showEmailDialog()
    else
        ' Cancel - return to navigation
        m.authEmail = ""
        m.authPassword = ""
        m.top.isVisible = true
        m.top.focusable = true
        m.top.setFocus(true)
        print "Login error - user cancelled"
    end if
end sub

sub onUserLoggedIn()
    ' Called when user successfully logs in
    loggedIn = m.top.userLoggedIn
    if loggedIn = true then
        m.isLoggedIn = true
        updateLogout(m.top.isVisible)
        print "User logged in - label changed to Logout"
    end if
end sub