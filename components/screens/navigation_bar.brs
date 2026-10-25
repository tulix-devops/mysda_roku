' ============================================================================
' navigation_bar.brs - the left rail (redesign 2026-10-06, on wpa_live_roku's
' WpNavRail). Five destinations, the account row after a gap:
'
'   0 Television     vod_screen      3 Radios         third_vod
'   1 TV Languages   second_vod      4 Login/Logout   loginInfoScreen preview
'   2 DVR            dvr_vod
'
' Moving Up/Down SHOWS the destination at once (mySDAtv's own behaviour,
' kept); Right or OK goes into it; on the account row they start the
' login / logout flow. Back from the rail asks to exit the channel - before
' the redesign Back could never leave it (certification).
'
' Visual states (WPALive section 14):
'   focused    accent pill, cOnNavFocus ink       (open rail, the row in hand)
'   selected   cSelected label, glyph and dot     (the "SDA" gold in "myred")
'   idle       white label, glyph dimmed
' Collapsed: glyphs only, the selected one in cSelected.
'
' The login/logout flow below the rail code is unchanged; its calls to the
' old per-row builders (updateLiveRow ... updateLogout) now just repaint.
' ============================================================================

sub init()
    ' First line: a child's init runs BEFORE the scene's.
    SdEnsureGlobals()
    m.top.focusable = true
    m.t = SdTheme()
    SdPaint(m.top, [["railPanel", "color", "cRail"], ["railEdge", "color", "cHairline"], ["railTitleMy", "color", "cBrandRed"], ["railTitleSda", "color", "cBrandGold"], ["railTitleTv", "color", "cBrandBlue"], ["railMark", "uri", "gMark60"], ["leftEdgeFade", "uri", "gGroundFade"], ["leftEdgeFade", "blendColor", "gFadeTint"]])

    m.itemsContainer = m.top.findNode("itemsContainer")
    m.iconsContainer = m.top.findNode("iconsContainer")
    m.railPanel  = m.top.findNode("railPanel")
    m.railRight  = m.top.findNode("railRight")
    m.fadeLayer  = m.top.findNode("fadeLayer")
    m.railAnim   = m.top.findNode("railAnim")
    m.panelWInterp   = m.top.findNode("panelWInterp")
    m.panelOpInterp  = m.top.findNode("panelOpInterp")
    m.rightPosInterp = m.top.findNode("rightPosInterp")
    m.rightOpInterp  = m.top.findNode("rightOpInterp")
    m.fadeOpInterp   = m.top.findNode("fadeOpInterp")

    ' Initialize login variables
    m.authEmail = ""
    m.authPassword = ""

    m.menuItems = ["live", "archive", "dvr", "radios", "logout"]
    m.selectedIndex = 0

    ' Check if user is actually logged in
    authData = RetrieveAuthData()
    if authData <> invalid and authData.isauth = 1 then
        m.isLoggedIn = true
    else
        m.isLoggedIn = false
    end if

    ' Geometry, the engine's: 66 px rows 4 apart, glyph at x 40 in both
    ' states (24 margin + 16 pad), a 30 px gap before the account row.
    m.railWidth      = m.t.railW
    m.railCollapsedW = m.t.railCollapsedW
    m.rowHeight  = 66
    m.rowGap     = 4
    m.rowMarginH = 24
    m.rowPadH    = 16
    m.rowPadR    = 24
    m.iconSize   = 40
    m.iconGap    = 18
    m.dotSize    = 12
    m.groupGap   = 30
    m.items = [
        { label: "Television",   icon: "tv" },
        { label: "TV Languages", icon: "languages" },
        { label: "DVR",          icon: "dvr" },
        { label: "Radios",       icon: "radio" },
        { label: "Login",        icon: "account", gapBefore: true }
    ]
    buildRows()

    ' The XML is authored collapsed; nothing to animate on boot.
    m.collapsed = true

    m.top.observeField("isVisible", "toggleNavVisibility")
    m.top.observeField("selectedIndex", "updateSelection")
    ' Focus entering or leaving the rail: repaint, and tell the tiles to
    ' re-check whether their grid still holds focus.
    m.top.observeField("focusedChild", "onNavFocusChanged")
    repaint()
end sub

sub buildRows()
    m.rows = []
    y = 0
    for each item in m.items
        if item.gapBefore = true then y = y + m.groupGap * 2
        m.rows.push(buildRow(item, y))
        y = y + m.rowHeight + m.rowGap
    end for
end sub

function buildRow(item as object, y as integer) as object
    pillW = m.railWidth - m.rowMarginH * 2

    row = m.itemsContainer.createChild("Group")
    row.translation = [m.rowMarginH, y]

    ' Rectangle has no corner radius: the pill is a 9-patch tinted per state.
    pill = row.createChild("Poster")
    pill.uri = "pkg:/images/png/shapes/pill_r9.9.png"
    pill.width = pillW
    pill.height = m.rowHeight
    pill.blendColor = m.t.cClear

    ' White glyph, tinted per state; in its own layer because it stays when
    ' the rest of the row fades.
    icon = m.iconsContainer.createChild("Poster")
    icon.uri = "pkg:/images/png/nav/" + item.icon + ".png"
    icon.width = m.iconSize
    icon.height = m.iconSize
    icon.loadWidth = m.iconSize
    icon.loadHeight = m.iconSize
    icon.translation = [m.rowMarginH + m.rowPadH, y + Int((m.rowHeight - m.iconSize) / 2)]

    dot = row.createChild("Poster")
    dot.uri = "pkg:/images/png/shapes/pill_r6.9.png"
    dot.width = m.dotSize
    dot.height = m.dotSize
    dot.blendColor = m.t.cClear
    dot.translation = [pillW - m.rowPadR - m.dotSize, Int((m.rowHeight - m.dotSize) / 2)]

    labelX = m.rowPadH + m.iconSize + m.iconGap
    label = row.createChild("Label")
    label.translation = [labelX, 0]
    label.width = pillW - labelX - m.rowPadR - m.dotSize - m.iconGap
    label.height = m.rowHeight
    label.vertAlign = "center"
    label.horizAlign = "left"
    label.ellipsisText = "..."
    label.text = item.label
    label.color = m.t.cText

    return { pill: pill, icon: icon, dot: dot, label: label }
end function

sub repaint()
    if m.rows = invalid or m.rows.count() = 0 then return
    hasFocus = m.top.isInFocusChain()

    ' The account row says what OK will do.
    if m.isLoggedIn = true
        m.rows[4].label.text = "Logout"
    else
        m.rows[4].label.text = "Login"
    end if

    for i = 0 to m.rows.count() - 1
        row = m.rows[i]
        isSelected = (i = m.selectedIndex)
        isFocused = hasFocus and isSelected

        if isSelected
            row.label.font = SdFont(m.t.fDisplay, 30)
        else
            row.label.font = SdFont(m.t.fSemi, 29)
        end if

        if isFocused
            row.pill.blendColor = m.t.cNavFocus
            row.label.color = m.t.cOnNavFocus
            row.icon.blendColor = m.t.cOnNavFocus
            row.dot.blendColor = m.t.cClear
        else if isSelected
            row.pill.blendColor = m.t.cClear
            row.label.color = m.t.cSelected
            row.icon.blendColor = m.t.cSelected
            row.dot.blendColor = m.t.cSelected
        else
            row.pill.blendColor = m.t.cClear
            row.label.color = m.t.cText
            row.icon.blendColor = m.t.cIconIdle
            row.dot.blendColor = m.t.cClear
        end if
    end for
end sub

sub onNavFocusChanged()
    repaint()
    SdFocusChanged()
end sub

sub toggleNavVisibility(event as object)
    expanded = (event.getData() = true)
    if expanded then
        disableFullContentMode()
    else
        enableFullContentMode()
    end if
    setCollapsed(not expanded)
    repaint()
end sub

' Opening: the panel widens first and the words arrive once there is room;
' closing: the words go first and the panel follows.
sub setCollapsed(collapsed as boolean)
    if m.collapsed = collapsed then return
    m.collapsed = collapsed

    panelW = m.railPanel.width
    panelOp = m.railPanel.opacity
    rightX = m.railRight.translation[0]
    rightOp = m.railRight.opacity
    fadeOp = m.fadeLayer.opacity

    m.railAnim.control = "stop"
    if collapsed
        w = m.railCollapsedW + 0.0
        m.railAnim.duration = 0.18
        m.panelOpInterp.key = [0.0, 0.6, 1.0]
        m.panelOpInterp.keyValue = [panelOp, panelOp, 0.0]
        m.rightOpInterp.keyValue = [rightOp, 0.0]
        m.fadeOpInterp.key = [0.0, 0.35, 1.0]
        m.fadeOpInterp.keyValue = [fadeOp, 0.0, 0.0]
    else
        w = m.railWidth + 0.0
        m.railAnim.duration = 0.22
        m.panelOpInterp.key = [0.0, 0.3, 1.0]
        m.panelOpInterp.keyValue = [panelOp, 1.0, 1.0]
        m.rightOpInterp.keyValue = [rightOp, 1.0]
        m.fadeOpInterp.key = [0.0, 0.4, 1.0]
        m.fadeOpInterp.keyValue = [fadeOp, fadeOp, 1.0]
    end if
    m.panelWInterp.keyValue = [panelW, w]
    m.rightPosInterp.keyValue = [[rightX, 0.0], [w, 0.0]]
    m.railAnim.control = "start"
end sub

sub updateSelection()
    m.global.findNode("vod_screen").visible = false
    m.global.findNode("second_vod").visible = false
    m.global.findNode("third_vod").visible = false
    m.global.findNode("dvr_vod").visible = false

    ' Hide LoginInfoScreen by default
    homeScene = m.top.getScene()
    loginInfoScreen = invalid
    if homeScene <> invalid then
        loginInfoScreen = homeScene.findNode("loginInfoScreen")
        if loginInfoScreen <> invalid then
            loginInfoScreen.visible = false
        end if
    end if

    if m.selectedIndex = 0
        m.global.findNode("vod_screen").visible = true
    else if m.selectedIndex = 1
        m.global.findNode("second_vod").visible = true
    else if m.selectedIndex = 2
        m.global.findNode("dvr_vod").visible = true
    else if m.selectedIndex = 3
        m.global.findNode("third_vod").visible = true
    else if m.selectedIndex = 4
        ' Login/Logout: the LoginInfoScreen previews while the row is in hand.
        if loginInfoScreen <> invalid then
            loginInfoScreen.visible = true
        end if
    end if
    repaint()
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false

    if key = "up"
        if m.selectedIndex > 0
            m.selectedIndex = m.selectedIndex - 1
            updateSelection()
        end if
        return true
    else if key = "down"
        if m.selectedIndex < m.menuItems.count() - 1
            m.selectedIndex = m.selectedIndex + 1
            updateSelection()
        end if
        return true
    else if key = "OK" or key = "right"
        enterSelected()
        return true
    else if key = "back"
        showExitConfirmation()
        return true
    end if
    ' The rail is one column: Left, and every other key, stays here.
    return true
end function

' Into the destination in hand: its grid, or the login / logout flow.
sub enterSelected()
    if m.selectedIndex = 4 then
        if m.isLoggedIn = true then
            showLogoutConfirmation()
        else
            performLogin()
        end if
        return
    end if
    screens = ["vod_screen", "second_vod", "dvr_vod", "third_vod"]
    m.global.findNode(screens[m.selectedIndex]).setFocus(true)
    m.top.isVisible = false
end sub

sub enableFullContentMode()
    for each id in ["vod_screen", "second_vod", "third_vod", "dvr_vod"]
        node = m.global.findNode(id)
        if node <> invalid then node.showFullContent = true
    end for
end sub

sub disableFullContentMode()
    for each id in ["vod_screen", "second_vod", "third_vod", "dvr_vod"]
        node = m.global.findNode(id)
        if node <> invalid then node.showFullContent = false
    end for
end sub

' Back from the rail: leave the channel, after a yes. m.global.sdExitApp
' is observed by main.brs, which returns from main and closes the channel.
sub showExitConfirmation()
    exitDialog = CreateObject("roSGNode", "BackDialog")
    exitDialog.title = "Exit mySDAtv"
    exitDialog.message = "Do you want to exit mySDAtv?"
    exitDialog.buttons = ["Exit", "Cancel"]
    exitDialog.ObserveField("buttonSelected", "onExitDialogButton")
    m.top.GetScene().dialog = exitDialog
    m.exitDialog = exitDialog
end sub

sub onExitDialogButton()
    buttonIndex = m.exitDialog.buttonSelected
    if m.top.GetScene().dialog <> invalid
        m.top.GetScene().dialog.close = true
    end if
    if buttonIndex = 0 then
        m.global.sdExitApp = true
    else
        m.top.setFocus(true)
    end if
end sub

' The old per-row builders, still called by the login / logout flow below:
' the rail draws every row in one pass now.
sub updateLiveRow(isNavExpanded as Boolean)
    repaint()
end sub

sub updateTelevisionLanguages(isNavExpanded as Boolean)
    repaint()
end sub

sub updateRadios(isNavExpanded as Boolean)
    repaint()
end sub

sub updateDvr(isNavExpanded as Boolean)
    repaint()
end sub

sub updateLogout(isNavExpanded as Boolean)
    repaint()
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