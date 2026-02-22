' =============================================================================
' init - Initializes the Details screen, sets all observers and configures buttons for Details screen
' =============================================================================

function init()

    print "VideoDVRScreen.brs - [init]"

    m.buttons = m.top.findNode("Buttons")
    m.videoPlayer = m.top.findNode("VideoPlayer")
    m.poster = m.top.findNode("Poster")
    m.description = m.top.findNode("Description")
    m.detailsOverhang = m.top.findNode("detailsOverhang")
    m.overhangBackground = m.top.findNode("overhangBackground")
    ' m.overhangBackground.height = m.global.overhangHeight
    m.overhangBackground.height = 140
    m.backgroundPanelSet = m.top.findNode("backgroundPanelSet")
    m.hudRectangle = m.top.findNode("HUDRectangle")
    m.backgroundPanel = m.top.findNode("backgroundPanel")
    m.fadeInBackgroundGroup = m.top.findNode("fadeInBackgroundGroup")
    m.fadeOutBackgroundGroup = m.top.findNode("fadeOutBackgroundGroup")


    m.overhangBackground.color = "#f16667"
    m.hudRectangle.color = "#f16667"

    ' m.top.observeField("visible", "onVisibleChange")


    m.dialogErrStream = CreateObject("roSGNode", "BackDialog")
    m.dialogErrStream.title = "Stream Error"
    m.dialogErrStream.message = "Streaming is not available!"
    m.dialogErrStream.buttons = ["OK"]
    m.dialogErrStream.ObserveField("buttonSelected", "On_dialogErrStream_buttonSelected")

    ' Initialize authentication variables
    m.authEmail = ""
    m.authPassword = ""
    m.pendingDvrAccess = false

end function

sub On_dialogErrStream_buttonSelected()
    print "VideoDVRScreen.brs - [On_dialogErrStream_buttonSelected()] Called"
    MainSceneNode = m.top.getScene()
    MainSceneNode.dialog.close = true
    print "VideoDVRScreen.brs - [On_dialogErrStream_buttonSelected()] Exiting"
end sub

' =============================================================================
' onVisibleChange
' =============================================================================

sub onVisibleChange()

    ' If entering Details screen, set the focus to the first button


    if m.top.visible then

        print "VideoDVRScreen.brs - [onVisibleChange] Set up VideoDVRScreen"

        ' Focus first button

        m.buttons.jumpToItem = 0
        m.buttons.setFocus(true)

        ' Set the color of the button (focused)

        m.buttons.focusBitmapBlendColor = m.global.keyColorTint

        ' Set the color of the Overhang and the H.U.D. area at the bottom to the global keyColor

        ' m.overhangBackground.color = m.global.keyColor
        ' m.hudRectangle.color = m.global.keyColor

        ' Start the animation of the background images

        ' m.fadeInBackgroundGroup.control = "start"
        ' m.backgroundPanel.visible = true

        if m.global.deeplinked = "1"

            showPlayer()

            '	m.global.deeplinked="0"

        end if

        ' Else exiting DetailsScreen

    else

        print "DetailsScreen.brs - [onVisibleChange] Tear down DetailsScreen"

        ' Begin to fade out the DetailsScreen

        ' m.fadeOutBackgroundGroup.control = "start"

        ' Stop the animation of the background images

        ' m.backgroundPanel.visible = false

        ' Make sure the Video component is not playing a video and is not visible

        m.videoPlayer.visible = false
        m.videoPlayer.control = "stop"

    end if

end sub



sub startDelayedFunction()
    timer = createObject("roSGNode", "Timer")
    timer.duration = 2 ' in seconds
    timer.repeat = false

    ' Observe when it fires
    timer.observeField("fire", "onTimerFired")

    ' Add to the scene (must be attached to fire)
    m.top.appendChild(timer)

    ' Start it
    timer.control = "start"
end sub

sub onTimerFired()
    print "✅ Timer fired!"
    dvrButton = m.top.findNode("dvrButton")
    dvrButton.visible = false
    if dvrButton.hasFocus()
        m.videoPlayer.setFocus(true)
    end if
end sub




' =============================================================================
' onKeyEvent - Called when a key on the remote is pressed
' =============================================================================

function onKeyEvent(key as string, isPressed as boolean) as boolean

    print "VideoDVRScreen.brs - [onKeyEvent] key = "; key; ", isPressed = "; isPressed

    isKeyEventHandled = false
    dvrButton = m.top.findNode("dvrButton")
    ' There doesn't seem to be a way to disable the "Options" in the Overhang in "HeroScene",
    ' so if the options button is pressed, set the flag that the key has been handled so that
    ' it doesn't propagate to "HeroScene"

    if key = "options" then
        print "VideoDVRScreen Options"
        isKeyEventHandled = true
        
        ' If the buttons are hidden (because the user navigated to the "DataPanel" screen), and if the
        ' "left" or "back" button was pressed, then the user is returning to the "Details" screen.
    
    else if dvrButton.visible = false and ((key = "up" or key = "left" or key = "right") and isPressed = false) and m.top.arrayDVRs <> invalid and m.top.arrayDVRs.count() > 0 then
        dvrButton.visible = true

        startDelayedFunction()
        
        ' When backgroundPanel gains focus, the backgroundPanel will slide into view, but
        ' the buttons must then have focus restored so that they are usable (it seem that there
        ' must be a delay before changing the focus to the buttons to ensure that the slide
        ' transition to backgroundPanel actually takes place)

        ' m.backgroundPanel.setFocus(true)
        ' sleep(2000)
        ' dvrButton.visible = false
        ' dvrButton.setFocus(true)

        ' Stop the background animation in the dataPanel
        isKeyEventHandled = true
        return true
    else if isPressed = true and key = "up" then
            if dvrButton.visible = true
                dvrButton.setFocus(true)
            end if
            
            isKeyEventHandled = true
    else if isPressed = false and key = "OK" then
        if dvrButton.hasFocus() then
            ' Check authentication before showing DVR overlay
            if isUserAuthenticated() then
                ' User is authenticated - now check purchase
                checkPurchaseAndShowOverlay()
            else
                ' User not authenticated - show login dialog
                m.pendingDvrAccess = true
                showAuthDialog()
            end if
            isKeyEventHandled = true
        end if
        isKeyEventHandled = true
    else if isPressed = true and key = "back" then
        if m.top.navigatedFrom = "VOD" then
            m.top.visible = false
            m.videoPlayer.control = "stop"
            m.overlay = invalid
            m.global.findNode("vod_screen").setFocus(true)
            m.global.findNode("vod_screen").visible = true
            m.global.findNode("navigation_bar").visible = true
            m.top.arrayDVRs = []
            isKeyEventHandled = true
            return isKeyEventHandled
        else if m.top.navigatedFrom = "2VOD" then
            m.top.visible = false
            m.videoPlayer.control = "stop"
            m.overlay = invalid
            m.global.findNode("second_vod").setFocus(true)
            m.global.findNode("second_vod").visible = true
            m.global.findNode("navigation_bar").visible = true
            m.top.arrayDVRs = []
            isKeyEventHandled = true
            return isKeyEventHandled
        else if m.top.navigatedFrom = "3VOD" then
            m.top.visible = false
            m.videoPlayer.control = "stop"
            m.overlay = invalid
            m.global.findNode("third_vod").setFocus(true)
            m.global.findNode("third_vod").visible = true
            m.global.findNode("navigation_bar").visible = true
            m.top.arrayDVRs = []
            isKeyEventHandled = true
            return isKeyEventHandled
        else if m.top.navigatedFrom = "DVRVOD" then
            ' Going back to DVR Overlay (not dvr_vod screen)
            m.top.visible = false
            m.videoPlayer.control = "stop"
            m.overlay = invalid
            m.top.arrayDVRs = []
            
            ' Find and show the DVR Overlay
            dvrOverlay = m.top.GetScene().findNode("dvrOverlayScreen")
            if dvrOverlay <> invalid
                dvrOverlay.visible = true
                dvrOverlay.setFocus(true)
                print "✓ Returned to DVR Overlay from video player"
            else
                ' Fallback: If overlay not found, go back to dvr_vod screen
                print "⚠️ DVR Overlay not found, returning to dvr_vod screen"
                m.global.findNode("dvr_vod").visible = true
                m.global.findNode("dvr_vod").setFocus(true)
                m.global.findNode("navigation_bar").visible = true
            end if
            
            isKeyEventHandled = true
            return isKeyEventHandled    
        end if
        isKeyEventHandled = true
        return isKeyEventHandled
    end if
    isKeyEventHandled = true
    return isKeyEventHandled

end function

'=============================================================================
' onItemSelected - Button press handler
'=============================================================================
sub onItemSelected()

    print "DetailsScreen.brs - [onItemSelected] button = " m.top.itemSelected

    itm = m.buttons.content.getChild(m.top.itemSelected) ''''(m.top.itemSelected)

    print "DetailsScreen.brs - [onItemSelected] button = " itm

    ' Play button
    if itm.id = "1" then
        ' m.backgroundPanel.visible = false
        m.videoPlayer.visible = true
        m.videoPlayer.setFocus(true)
        m.videoPlayer.control = "play"
        m.videoPlayer.observeField("state", "onVideoPlayerStateChange")

    else if itm.id = "2" then

        ' m.backgroundPanel.visible = false
        m.videoPlayer.visible = true
        m.videoPlayer.setFocus(true)
        m.videoPlayer.control = "play"
        if (m.top.seekPosition > 0)
            m.videoPlayer.seek = m.top.seekPosition
        end if
        m.videoPlayer.observeField("state", "onVideoPlayerStateChange")

    else if itm.id = "3" then

    else if itm.id = "4" then

    end if
end sub



sub showLoadingDialog(textToShow as string)

    print "DetailsScreen.brs - [showLoadingDialog()] Called"
    progressdialog = createObject("roSGNode", "ProgressDialog")
    progressdialog.title = textToShow

    MainSceneNode = m.top.getScene()
    MainSceneNode.dialog = progressdialog


    print "DetailsScreen.brs - [showLoadingDialog()] Exiting"
end sub





' =============================================================================
' onVideoVisibleChange - Set focus to buttons and stop video if returning to Details from Playback
' =============================================================================

sub onVideoVisibleChange()

    print "DetailsScreen.brs - [onVideoVisibleChange]"

    if m.videoPlayer.visible = false and m.top.visible = true

        ' Make sure the buttons have the focus

        m.buttons.setFocus(true)

        ' Make sure the Video component is not playing a video

        m.videoPlayer.control = "stop"

        ' Re-start the background image animation

        ' m.backgroundPanel.visible = true

    end if

end sub

' =============================================================================
' onVideoPlayerStateChange - Event handler for Video player message
' =============================================================================

sub onVideoPlayerStateChange()

    print "VideoDVRScreen.brs - [onVideoPlayerStateChange] " m.videoPlayer.state
    
    print "VideoDVRScreen.brs  - [onVideoPlayerStateChange] " m.videoPlayer.content
    if m.videoPlayer.state = "error" then
        print m.videoPlayer.errorMsg
        print "Here is Error message"
        m.videoPlayer.visible = false
        MainSceneNode = m.top.getScene()
        MainSceneNode.dialog = m.dialogErrStream
        m.top.visible = false
        m.videoPlayer.control = "stop"

    else if m.videoPlayer.state = "playing"


    else if m.videoPlayer.state = "finished"
        m.videoPlayer.visible = false
        if m.top.navigatedFrom = "VOD" then
            m.top.visible = false
            m.videoPlayer.control = "stop"
            m.global.findNode("vod_screen").setFocus(true)
            m.global.findNode("vod_screen").visible = true
            m.global.findNode("navigation_bar").visible = true
            m.top.arrayDVRs = []
            m.overlay = invalid
        else if m.top.navigatedFrom = "2VOD" then
            m.top.visible = false
            m.videoPlayer.control = "stop"
            m.global.findNode("second_vod").setFocus(true)
            m.global.findNode("second_vod").visible = true
            m.global.findNode("navigation_bar").visible = true
            m.top.arrayDVRs = []
            m.overlay = invalid
        else if m.top.navigatedFrom = "3VOD" then
            m.top.visible = false
            m.videoPlayer.control = "stop"
            m.global.findNode("third_vod").setFocus(true)
            m.global.findNode("third_vod").visible = true
            m.global.findNode("navigation_bar").visible = true
            m.top.arrayDVRs = []
            m.overlay = invalid
        else if m.top.navigatedFrom = "DVRVOD" then
            ' Video finished - return to DVR Overlay
            m.top.visible = false
            m.videoPlayer.control = "stop"
            m.top.arrayDVRs = []
            m.overlay = invalid
            
            ' Find and show the DVR Overlay
            dvrOverlay = m.top.GetScene().findNode("dvrOverlayScreen")
            if dvrOverlay <> invalid
                dvrOverlay.visible = true
                dvrOverlay.setFocus(true)
                print "✓ Video finished, returned to DVR Overlay"
            else
                ' Fallback: If overlay not found, go back to dvr_vod screen
                print "⚠️ DVR Overlay not found, returning to dvr_vod screen"
                m.global.findNode("dvr_vod").visible = true
                m.global.findNode("dvr_vod").setFocus(true)
                m.global.findNode("navigation_bar").visible = true
            end if
        end if


        ' if m.top.content.isdvr = "1"
        '     epid = m.top.content.id
        '     sec = CreateObject("roRegistrySection", "positions")
        '     sec.Write(epid, Str(0))
        '     sec.Flush()

        '     if m.buttons.content.getChildCount() > 1 then
        '         m.buttons.content.removeChildIndex(1)
        '     end if

        ' end if

    else if m.videoPlayer.state = "stopped"

        epid = m.top.content.id
        print "Episode: ";epid;" Position: ";m.videoPlayer.position


        if m.top.content.isdvr = "1"

            oldposf = m.videoPlayer.position
            print "Writing episode position for "; epid;" ";oldposf;" ";m.videoPlayer.position
            sec = CreateObject("roRegistrySection", "positions")
            sec.Write(epid, Str(oldposf))
            sec.Flush()

            if oldposf > 30
                minutes = oldposf \ 60
                seconds = oldposf mod 60
                ttl = "  Resume ("
                if minutes > 60 then
                    hh = minutes \ 60
                    minutes = minutes \ 60
                    ttl = ttl + hh.toStr() + "h "
                end if

                if minutes > 0 then
                    ttl = ttl + minutes.toStr() + "m "
                end if

                if seconds > 0 then
                    ttl = ttl + seconds.toStr() + "s"
                end if

                ttl = ttl + ")  "
                contentNode = createObject("roSGNode", "ContentNode")

                if m.buttons.content.getChildCount() > 1 then
                    m.buttons.content.removeChildIndex(1)
                    print "m.videoPlayer.position"
                end if

                contentNode.title = ttl
                contentNode.id = 2
                m.buttons.content.appendChild(contentNode)
                m.top.seekPosition = oldposf
            end if
        end if
    end if

end sub

sub onParentContentChanged()
   
end sub


' =============================================================================
' onContentChange
' =============================================================================

sub onContentChange()

    print "VideoDVRScreen.brs - [onContentChange]"

    ' Set the Overhang title to the name of the selected media (if available)
    if m.top.content.channel <> invalid and Len(m.top.content.channel) > 0 then
        m.detailsOverhang.title = m.top.content.channel
    else if m.top.content.title <> invalid and Len(m.top.content.title) > 0 then
        ' m.detailsOverhang.title = m.top.content.title
    else
        m.detailsOverhang = "Exploration"
    end if


    epid = m.top.content.id
    registry = getRegistry()
    if m.top.content.isdvr <> invalid and m.top.content.isdvr = "1" then
        print "Reading position for episode ";epid
        sec = CreateObject("roRegistrySection", "positions")
        if (sec.Exists(epid))
            oldpos = sec.Read(epid)
        else
            oldpos = invalid
        end if
        print "Oldpos: ";oldpos

        if oldpos <> invalid

            result = []
            result.push({ id: "1", title: "  Play " })
            m.buttons.content = contentList2SimpleNode(result)

            oldposf = oldpos.toFloat()
            if oldposf > 30
                minutes = oldposf \ 60
                seconds = oldposf mod 60
                ttl = "  Resume ("

                if minutes > 60 then
                    hh = minutes \ 60
                    minutes = minutes \ 60
                    ttl = ttl + hh.toStr() + "h "
                end if

                if minutes > 0 then
                    ttl = ttl + minutes.toStr() + "m "
                end if

                if seconds > 0 then
                    ttl = ttl + seconds.toStr() + "s"
                end if
                ttl = ttl + ")  "

                contentNode = createObject("roSGNode", "ContentNode")
                contentNode.id = "2"
                contentNode.title = ttl
                m.buttons.content.appendChild(contentNode)
                m.top.seekPosition = oldposf
            end if

        else
            result = []
            result.push({ id: "1", title: "  Play  " })
            m.buttons.content = contentList2SimpleNode(result)
        end if

    else
        result = []
        result.push({ id: "1", title: "  Play  " })
        m.buttons.content = contentList2SimpleNode(result)
        m.buttons.jumpToItem = 1
        m.buttons.setFocus(true)

    end if


    ' Initialize the Description component that present information about the selected media item
    ' m.description.content = m.top.content
    ' m.description.Description.width = "1120"

    ' Assign the selected media content to the Video component
    print "CONTENT CHANGED"
    m.videoPlayer.content = m.top.content
    
    if m.top.navigatedFrom = "3VOD" then
        m.top.findNode("centeredPoster").visible = true
    else 
        m.top.findNode("centeredPoster").visible = false
    end if

    print "=========================================="
    print "📺 VIDEO PLAYER SETUP:"
    print "   Content isdvr field: "; m.top.content.isdvr
    print "   Content ID: "; m.top.content.id
    
    if m.top.content.isdvr = "0"
        m.videoPlayer.enableTrickPlay = false
        print "   ❌ Trick Play DISABLED (Live Stream)"
    else
        m.videoPlayer.enableTrickPlay = true
        print "   ✅ Trick Play ENABLED (DVR/VOD)"
    end if
    
    print "   Current enableTrickPlay value: "; m.videoPlayer.enableTrickPlay
    print "=========================================="

    print "Episode: ";epid;" Position: ";m.videoPlayer.position

    ' Auto-play content (both DVR recordings and live streams)
    print "   🎯 Auto-playing content"
    showPlayer()
end sub

' =============================================================================
' contentList2SimpleNode - Helper function convert AA to Node
' =============================================================================

function contentList2SimpleNode(contentList as object, nodeType = "ContentNode" as string) as object

    print "VideoDVRScreen.brs - [contentList2SimpleNode]"

    result = createObject("roSGNode", nodeType)

    if result <> invalid

        for each itemAA in contentList
            item = createObject("roSGNode", nodeType)
            item.setFields(itemAA)
            result.appendChild(item)
        end for

    end if

    return result

end function


sub showPlayer()

    print "VideoDVRScreen.brs - [showPlayer] "
    print "   🎬 Starting playback..."
    print "   enableTrickPlay: "; m.videoPlayer.enableTrickPlay
    print "   Content URL: "; m.videoPlayer.content.url

    ' m.backgroundPanel.visible = false

    m.videoPlayer.visible = true
    m.videoPlayer.setFocus(true)
    m.videoPlayer.control = "play"

    m.videoPlayer.TrickPlayBar.filledBarBlendColor = "#f16667"

    print "   TrickPlayBar filledBarBlendColor set"
    print "   bufferingBar: "; m.videoPlayer.bufferingBar

    m.videoPlayer.observeField("state", "onVideoPlayerStateChange")

    print "   ✅ Player started"

end sub



sub showDvrOverlay()
    print "Showing DVR Overlay..."

    if m.overlay <> invalid
        m.overlay.visible = true
        m.overlay.setFocus(true)
        return
    end if
    print m.top.arrayDVRs
    print "Overlay DVR Array"
    print Type(m.top.arrayDVRs)

    m.overlay = CreateObject("roSGNode", "DVROverlayScreen")
    convertedData = convertArrayDVRsToContent(m.top.arrayDVRs)
    print m.top.parentContent
    print "Hello ParentContent From VIDEODVR?"
    m.overlay.parentContent = m.top.parentContent
    m.overlay.content = convertedData
    overlayContainer = m.top.findNode("overlayContainer")
    overlayContainer.appendChild(m.overlay)
    m.overlay.observeField("requestOverlayClose", "onOverlayCloseRequested")
    m.overlay.observeField("selectedDvrItem", "onOverlaySelectedDVR")
    m.overlay.setFocus(true)
end sub

sub onOverlayCloseRequested()
    if m.overlay.requestOverlayClose <> invalid then
        if m.overlay.requestOverlayClose = true then
            hideDvrOverlay()
        end if
    end if
    print "🔽 Closing overlay via child request"
    
end sub

sub onOverlaySelectedDVR()
    print m.top.content.url
    print m.overlay.selectedDvrItem.url
    print "Overlay URL and Content URL"
    print m.overlay.selectedDvrItem
    if m.top.content <> invalid and m.overlay.selectedDvrItem <> invalid then
        if m.top.content.url <> invalid and m.overlay.selectedDvrItem.url <> invalid then
            if m.top.content.url <> m.overlay.selectedDvrItem.url then
                print m.top.content.url
                print m.overlay.selectedDvrItem.url
                print "Overlay URL and Content URL"
                print m.overlay.selectedDvrItem
                m.top.content = m.overlay.selectedDvrItem
            end if
        end if
    end if
end sub


sub hideDvrOverlay()
    if m.overlay <> invalid
        m.overlay.visible = false
        m.videoPlayer.setFocus(true)
    end if
end sub

function convertArrayDVRsToContent(arrayDVRs as object) as object
    result = []
    
    for each categoryData in arrayDVRs
        section = {
            title: categoryData.dvrtitle
            episodes: []  ' this will hold an array of AAs for episodes
        }

        for each episodeData in categoryData.data
            section.episodes.push({
                title: episodeData.title
                description: episodeData.description
                duration: episodeData.duration
                date: episodeData.start
                hdposterurl: episodeData.thumbnail
                url: episodeData.link
                isLiveParent: false
                isDVR: true
                isLiveChannel: false
                data: episodeData
            })
        end for

        result.push(section)
    end for

    return result
end function

' =============================================================================
' Authentication Functions for DVR Access
' =============================================================================

' Check if user is authenticated
function isUserAuthenticated() as boolean
    authData = RetrieveAuthData()
    if authData <> invalid and authData.accessToken <> invalid
        print "✓ User is authenticated"
        return true
    else
        print "✗ User is NOT authenticated"
        return false
    end if
end function

' Show authentication dialog to get username/email
sub showAuthDialog()
    print "Showing authentication dialog..."
    
    ' Create username/email keyboard dialog
    usernameDialog = CreateObject("roSGNode", "KeyboardDialog")
    usernameDialog.title = "Login Required for DVR Access"
    usernameDialog.text = ""
    usernameDialog.buttons = ["Next", "Cancel"]
    usernameDialog.ObserveField("buttonSelected", "onUsernameDialogButton")
    usernameDialog.ObserveField("wasClosed", "onAuthDialogClosed")
    
    m.top.GetScene().dialog = usernameDialog
    m.usernameDialog = usernameDialog
end sub

' Handle username dialog button press
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
        m.pendingDvrAccess = false
        m.videoPlayer.setFocus(true)
    end if
end sub

' Show password dialog
sub showPasswordDialog()
    print "Showing password dialog..."
    
    passwordDialog = CreateObject("roSGNode", "KeyboardDialog")
    passwordDialog.title = "Enter Password"
    passwordDialog.text = ""
    passwordDialog.secure = true
    passwordDialog.buttons = ["Login", "Cancel"]
    passwordDialog.ObserveField("buttonSelected", "onPasswordDialogButton")
    passwordDialog.ObserveField("wasClosed", "onAuthDialogClosed")
    
    m.top.GetScene().dialog = passwordDialog
    m.passwordDialog = passwordDialog
end sub

' Handle password dialog button press
sub onPasswordDialogButton()
    if m.passwordDialog.buttonSelected = 0
        ' Login button - attempt login
        m.authPassword = m.passwordDialog.text
        if m.authPassword.Len() > 0
            m.passwordDialog.close = true
            attemptLogin()
        else
            m.passwordDialog.message = "Please enter your password"
        end if
    else
        ' Cancel button
        m.passwordDialog.close = true
        m.pendingDvrAccess = false
        m.authEmail = ""
        m.videoPlayer.setFocus(true)
    end if
end sub

' Handle dialog closed event
sub onAuthDialogClosed()
    m.videoPlayer.setFocus(true)
end sub

' Attempt login with entered credentials
sub attemptLogin()
    print "Attempting login with email: " + m.authEmail
    
    ' Show loading dialog
    progressDialog = CreateObject("roSGNode", "ProgressDialog")
    progressDialog.title = "Authenticating..."
    m.top.GetScene().dialog = progressDialog
    
    ' Create and run login API task
    m.loginApi = CreateObject("roSGNode", "LoginScreenApi")
    m.loginApi.observeField("responseData", "handleAuthLogin")
    m.loginApi.email = m.authEmail
    m.loginApi.password = m.authPassword
    m.loginApi.control = "RUN"
end sub

' Handle login response
sub handleAuthLogin()
    data = m.loginApi.responseData
    
    ' Close progress dialog
    if m.top.GetScene().dialog <> invalid
        m.top.GetScene().dialog.close = true
    end if
    
    if data = "Success"
        print "✓ Login successful!"
        
        ' Clear credentials
        m.authEmail = ""
        m.authPassword = ""
        
        ' If DVR access was pending, check purchase before showing overlay
        if m.pendingDvrAccess
            m.pendingDvrAccess = false
            checkPurchaseAndShowOverlay()
        end if
    else if data = "405"
        print "✗ Login failed - incorrect credentials"
        showAuthErrorDialog("Incorrect email or password")
    else
        print "✗ Login failed - error occurred"
        showAuthErrorDialog("Authentication error occurred")
    end if
end sub

' Show authentication error dialog
sub showAuthErrorDialog(errorMessage as string)
    errorDialog = CreateObject("roSGNode", "BackDialog")
    errorDialog.title = "Authentication Failed"
    errorDialog.message = errorMessage
    errorDialog.buttons = ["Retry", "Cancel"]
    errorDialog.ObserveField("buttonSelected", "onAuthErrorDialogButton")
    
    m.top.GetScene().dialog = errorDialog
    m.authErrorDialog = errorDialog
end sub

' Check purchase before showing DVR overlay
sub checkPurchaseAndShowOverlay()
    print "Checking purchase for DVR overlay access..."
    
    ' Show loading dialog
    progressDialog = CreateObject("roSGNode", "ProgressDialog")
    progressDialog.title = "Checking DVR access..."
    m.top.GetScene().dialog = progressDialog
    
    ' Create and run purchase check API task
    m.purchaseCheckApi = CreateObject("roSGNode", "CheckPurchaseApi")
    m.purchaseCheckApi.observeField("responseData", "handlePurchaseCheckResponse")
    m.purchaseCheckApi.control = "RUN"
end sub

' Handle purchase check response
sub handlePurchaseCheckResponse()
    result = m.purchaseCheckApi.responseData
    
    ' Close progress dialog
    if m.top.GetScene().dialog <> invalid
        m.top.GetScene().dialog.close = true
    end if
    
    print "Purchase check result: " + result
    
    if result = "purchased"
        print "✓ User has purchased - showing DVR overlay"
        showDvrOverlay()
    else if result = "not_purchased"
        print "✗ User has not purchased product"
        showPurchaseRequiredDialog()
    else if result = "unauthorized"
        print "✗ User unauthorized"
        showPurchaseErrorDialog("Session expired. Please login again")
    else
        print "✗ Error checking purchase"
        showPurchaseErrorDialog("Unable to verify DVR access. Please try again")
    end if
end sub

' Show purchase required dialog
sub showPurchaseRequiredDialog()
    errorDialog = CreateObject("roSGNode", "BackDialog")
    errorDialog.title = "Purchase Required"
    errorDialog.message = "You need to purchase a subscription to access DVR recordings."
    errorDialog.buttons = ["OK"]
    errorDialog.ObserveField("buttonSelected", "onPurchaseDialogButton")
    
    m.top.GetScene().dialog = errorDialog
    m.purchaseDialog = errorDialog
end sub

' Show purchase error dialog
sub showPurchaseErrorDialog(errorMessage as string)
    errorDialog = CreateObject("roSGNode", "BackDialog")
    errorDialog.title = "DVR Access Error"
    errorDialog.message = errorMessage
    errorDialog.buttons = ["OK"]
    errorDialog.ObserveField("buttonSelected", "onPurchaseDialogButton")
    
    m.top.GetScene().dialog = errorDialog
    m.purchaseDialog = errorDialog
end sub

' Handle purchase dialog button press
sub onPurchaseDialogButton()
    if m.top.GetScene().dialog <> invalid
        m.top.GetScene().dialog.close = true
    end if
    
    ' Return focus to video player
    m.videoPlayer.setFocus(true)
end sub

' Handle auth error dialog button
sub onAuthErrorDialogButton()
    if m.authErrorDialog.buttonSelected = 0
        ' Retry - show auth dialog again
        m.authErrorDialog.close = true
        m.authEmail = ""
        m.authPassword = ""
        showAuthDialog()
    else
        ' Cancel
        m.authErrorDialog.close = true
        m.pendingDvrAccess = false
        m.authEmail = ""
        m.authPassword = ""
        m.videoPlayer.setFocus(true)
    end if
end sub

' Retrieve authentication data from registry
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

' Read from registry
function RegRead(key, section = invalid)
    if section = invalid then section = "Default"
    sec = CreateObject("roRegistrySection", section)
    if sec.Exists(key) then return sec.Read(key)
    return ""
end function










