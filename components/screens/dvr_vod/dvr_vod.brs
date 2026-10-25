
function init()
    print "=== dvr_vod init() called ==="
    
    m.progressdialog = createObject("roSGNode", "ProgressDialog")
    m.top.observeField("visible", "onScreenVisibilityChanged")

    m.vodDataCache = {}
    m.dataFetched = false  ' Track if we've tried to fetch data

    ' Initialize authentication variables for DVR access
    m.pendingDvrData = invalid  ' Store DVR data while checking auth/purchase

    ' Don't fetch data in init - wait until screen is visible
    ' fetchDvrData()

    m.activateRow = m.top.findNode("activateRow")
    m.deactivateRow = m.top.findNode("deactivateRow")
    m.activateItemDetails = m.top.findNode("activateItemDetails")
    m.deactivateItemDetails = m.top.findNode("deactivateItemDetails")
    m.page = 1

    m.totalItems = 0
    m.lastFocusedItem = invalid

    m.selectedCategory = 0

    m.lastFocuedCategoryItem = invalid

    m.firstCategoryInitialization = false

    m.vodAnimationInitialized = false

    m.top.observeField("showFullContent", "onShowFullContentChanged")
    m.top.signalBeacon("AppLaunchComplete")
    setTimeTitle()
    
    print "✓ dvr_vod init() completed"
end function

sub setTimeTitle()
    now = CreateObject("roDateTime")
    now.Mark()
    now.ToLocalTime()
    
    m.timeTitle = m.top.findNode("timeTitle")
    m.timeTitle.text = now.asTimeStringLoc("short")
    
    ' User email display removed - no longer showing email on screen
    m.userEmailLabel = m.top.findNode("userEmailLabel")
    if m.userEmailLabel <> invalid
        m.userEmailLabel.text = ""
    end if
end sub

sub onShowFullContentChanged()
    if m.top.showFullContent then
        print "showFullContent is TRUE - Expanding UI"
        m.descriptionLabel = m.top.findNode("descriptionLabel")
        m.descriptionLabel.visible = true
        startExpandAnimation()
    else
        print "showFullContent is FALSE - Collapsing UI"
        startCollapseAnimation()
        m.descriptionLabel = m.top.findNode("descriptionLabel")
        m.descriptionLabel.visible = false
    end if
  end sub
  
  sub startExpandAnimation()
    ' showFullContent = the rail COLLAPSED: the page slides back to its own
    ' layout (content at x 160). WPALive contract T4: the rail moves the
    ' page and never re-lays it.
    slidePage("MoveCategoryIn", 160)
end sub

sub startCollapseAnimation()
    ' The rail OPENED: the page slides right by the rail's growth (320).
    slidePage("MoveCategoryOut", 480)
end sub

' Slides vodContainer to x from WHERE IT IS, so a reversal half-way does
' not jump to an end.
sub slidePage(animId as string, x as integer)
    animation = m.top.findNode(animId)
    container = m.top.findNode("vodContainer")
    if animation = invalid or container = invalid then return
    m.top.findNode("MoveCategoryIn").control = "stop"
    m.top.findNode("MoveCategoryOut").control = "stop"
    interp = animation.getChild(0)
    interp.keyValue = [container.translation, [x, 0]]
    animation.control = "start"
end sub

sub fetchDvrData()
    print "=== fetchDvrData called ==="
    
    ' No authentication required to browse DVR content
    ' VideoPlayer will handle auth/purchase check when playing
    
    print "✓ Loading DVR content (no auth required for browsing)..."
    showLoadingDialog("Loading DVR content, please wait...")
    
    ' Load DVR list directly - VideoPlayer will handle purchase check
    m.dvrListData = createObject("roSGNode", "DvrListData")
    if m.dvrListData = invalid
        print "✗ Failed to create DvrListData node"
        m.dataFetched = false  ' Reset so user can retry
        TopDialogClose()
        return
    end if
    
    print "✓ DvrListData node created, setting up observer..."
    m.dvrListData.observeField("responseData", "handleResponseData")
    m.dvrListData.page = m.page
    m.dvrListData.control = "RUN"
    print "✓ DvrListData task started"
end sub

' Removed duplicate showAuthErrorDialog - see full implementation below in auth section

sub handleResponseData()
    print "=== handleResponseData called ==="
    data = m.dvrListData.responseData
    print "Response data type: " + type(data)
    print "Response data value length: " + data.Len().ToStr()
    
    if data = "empty" or data = "error"
        print "✗ DVR data fetch failed or empty"
        m.dataFetched = false  ' Reset so user can retry
        TopDialogClose()
        return
    end if
    
    ' Parse parent DVR VOD items (not individual recordings)
    print "About to parse VOD screen entity..."
    parsedData = parseVodScreenEntity(data, 0)
    print "Parsed data count: " + parsedData.count().ToStr()
    
    if parsedData.count() > 0
        m.top.vodDataEntity = parsedData
        print "✓ Successfully loaded " + m.top.vodDataEntity.count().ToStr() + " DVR parent items"
    else
        print "✗ No DVR items found after parsing"
        m.dataFetched = false  ' Reset so user can retry
        TopDialogClose()
    end if
end sub

sub onScreenVisibilityChanged()
    print "=== onScreenVisibilityChanged called ==="
    print "   visible: " + m.top.visible.ToStr()
    print "   dataFetched: " + m.dataFetched.ToStr()
    
    if m.top.visible = true
        ' Fetch data when screen becomes visible (only if not already fetched)
        if m.top.vodDataEntity = invalid and m.dataFetched = false
            print "   Screen visible and no data - fetching DVR data..."
            m.dataFetched = true
            fetchDvrData()
        else if m.top.vodDataEntity = invalid
            print "   Data fetch already in progress, showing dialog..."
            m.top.GetScene().dialog = m.progressdialog
        else
            print "   ✓ vodDataEntity already loaded (" + m.top.vodDataEntity.count().ToStr() + " items)"
        end if
    else if m.top.visible = false
        print "   Screen hidden, closing dialog"
        TopDialogClose()
    end if
end sub

sub showLoadingDialog(textToShow as string)
    m.progressdialog.busySpinner.uri = "pkg:/images/png/loader.png"
    m.progressdialog.backgroundUri = "pkg:/images/png/shapes/final_transparent_mask.png"
    m.progressdialog.width = 500

    if m.top.visible = true
        m.top.GetScene().dialog = m.progressdialog
    end if
end sub

sub initializeVodScreen()
    m.contentContainer = m.top.findNode("vodContainer")
    defaultFont = CreateObject("roSGNode", "Font")
    defaultFont.uri = "pkg:/images/UrbanistSemiBold.ttf"
    defaultFont.size = 42

    if m.rowList = invalid
        m.rowList = m.top.findNode("vodRowList")
        m.rowList.focusable = true
        m.contentContainer.appendChild(m.rowList)
        m.rowList.observeField("itemFocused", "onItemFocused")
    end if

    m.lastFocusedItem = m.rowList.itemFocused

    content = m.rowList.content

    if content <> invalid
        childrenToRemove = []
        for i = 0 to content.getChildCount() - 1
            childrenToRemove.push(content.getChild(i))
        end for
        content.removeChildren(childrenToRemove)
    else
        content = CreateObject("roSGNode", "ContentNode")
        content.title = "DVR"
    end if

    if m.top.vodDataEntity <> invalid
        m.vodDataCache[m.selectedCategory.ToStr()] = m.top.vodDataEntity
        for each vodData in m.top.vodDataEntity
            item = CreateObject("roSGNode", "ContentNode")
            item.title = vodData.title
            item.hdPosterUrl = ""

            print vodData.images
            print "Here is DVR DATA IMAGES"

            ' Use images.banner structure (thumb is mapped to banner)
            if vodData.images <> invalid
                if vodData.images["banner"] <> invalid
                    item.hdPosterUrl = vodData.images["banner"]
                else
                    item.hdPosterUrl = "pkg:/images/png/no-poster-found.png"
                end if
            end if
            print vodData
            print "Here is VOD DVR DATA"

            item.addFields({
                rowItemFocus: false,
                data: vodData,
                isLiveChannel: false,
                sdPadLeft: 30,
                sdPadTop: 20,
                focusable: true
            })
            m.totalItems = m.totalItems + 1
            content.appendChild(item)
        end for

        m.rowList.content = content
        m.rowList.itemFocused = m.lastFocusedItem
        m.rowList.jumptoitem = m.lastFocusedItem
    
        m.vodRowList = m.top.findNode("vodRowList")
        m.descriptionLabel = m.top.findNode("descriptionLabel")

        m.vodRowList.observeField("itemFocused", "onGridItemFocused")
    end if
end sub

sub onGridItemFocused()
    focusedIndex = m.vodRowList.itemFocused
    contentNode = m.vodRowList.content.getChild(focusedIndex)

    if contentNode <> invalid
        print contentNode
        print "Here is CONTENTNODE!!!"
        title = contentNode.title
        m.descriptionLabel.text = title + "  •  " + "on mySDAtv" 
        m.descriptionLabel.visible = true

        col = focusedIndex MOD m.vodRowList.numColumns
        row = Int(focusedIndex / m.vodRowList.numColumns)

        x = 100 + col * (400 + 15)
        y = 260 + row * (200 + 20) + 200 + 5
    else
        m.descriptionLabel.visible = false
    end if
end sub

sub onItemFocused()
    itemFocusedInfo = m.rowList.itemFocused

    if itemFocusedInfo <> invalid
        focusedItemIndex = itemFocusedInfo

        if m.prevFocusedItemIndex <> invalid
            prevFocusedItem = m.rowList.content.getChild(m.prevFocusedItemIndex)
            if prevFocusedItem <> invalid
                prevFocusedItem.rowItemFocus = false
            end if
        end if

        focusedItem = m.rowList.content.getChild(focusedItemIndex)
        if focusedItem <> invalid
            focusedItem.rowItemFocus = true

            if focusedItemIndex >= m.totalItems - 7
                ' Can add pagination logic here if needed
            end if

            m.prevFocusedItemIndex = focusedItemIndex
        end if
    end if
end sub

function getActiveEntityDetails()
    itemFocusedInfo = m.rowList.itemFocused
    print "Do We have ItemFocusedInfo?"; itemFocusedInfo

    if itemFocusedInfo <> invalid and itemFocusedInfo <> -1
        focusedItem = m.rowList.content.getChild(itemFocusedInfo)
        if focusedItem <> invalid
            return focusedItem
        end if
    end if

    return invalid
end function

sub updateVodScreen()
    print "=== updateVodScreen called ==="
    print "   vodDataEntity count: " + m.top.vodDataEntity.count().ToStr()
    
    initializeVodScreen()
    TopDialogClose()

    m.rowList.itemFocused = m.lastFocusedItem
    m.rowList.itemSelected = m.lastFocusedItem
    
    print "✓ updateVodScreen completed"
end sub

sub initializeEPGData(id)
    ' Fetch DVR recordings for the selected parent item
    showLoadingDialog("Loading DVR recordings, please wait...")
    
    selectionData = getActiveEntityDetails()
    if selectionData = invalid or selectionData.data = invalid
        print "No selection data available"
        TopDialogClose()
        return
    end if
    
    ' Get dvr_url from selected parent item
    dvrUrl = invalid
    if selectionData.data.dvr_url <> invalid
        dvrUrl = selectionData.data.dvr_url
    else if selectionData.data.sources <> invalid and selectionData.data.sources.dvr_url <> invalid
        dvrUrl = selectionData.data.sources.dvr_url
    end if
    
    if dvrUrl <> invalid and dvrUrl <> ""
        print "Fetching DVR recordings from: " + dvrUrl
        
        ' Use Task to fetch recordings (can't use roUrlTransfer on render thread)
        m.dvrRecordingsData = createObject("roSGNode", "DvrRecordingsData")
        m.dvrRecordingsData.observeField("responseData", "handleDvrRecordingsResponse")
        m.dvrRecordingsData.dvrUrl = dvrUrl
        m.dvrRecordingsData.parentData = selectionData.data
        m.dvrRecordingsData.control = "RUN"
    else
        print "No dvr_url found in selected item"
        TopDialogClose()
    end if
end sub

sub handleDvrRecordingsResponse()
    data = m.dvrRecordingsData.responseData
    
    print "🔍 DEBUG: handleDvrRecordingsResponse called"
    print "🔍 DEBUG: responseData type = "; type(data)
    
    if data = "empty" or data = "error"
        print "❌ DVR recordings fetch failed or empty"
        TopDialogClose()
        return
    end if
    
    ' Convert recordings to EPG format
    print "🔍 DEBUG: Converting DVR recordings to EPG..."
    m.top.epgDataEntity = convertDvrRecordingsToEpg(data)
    print "✓ Loaded " + m.top.epgDataEntity.count().ToStr() + " DVR recordings"
    print "🔍 DEBUG: epgDataEntity[0] = "; m.top.epgDataEntity[0]
    
    TopDialogClose()
    
    ' NEW FLOW: Check purchase before opening DVR overlay
    checkPurchaseAndOpenOverlay()
end sub

sub handleEPGResponseData()
    ' This function is no longer needed but kept for compatibility
    data = m.epgScreenData.responseData
    
    print "🔍 DEBUG: handleEPGResponseData called"
    print "🔍 DEBUG: responseData type = "; type(data)
    
    m.top.epgDataEntity = parseEPGScreenEntity(data, 0)
    print "✓ Loaded " + m.top.epgDataEntity.count().ToStr() + " EPG items"
    print "🔍 DEBUG: epgDataEntity[0] = "; m.top.epgDataEntity[0]
    print m.top.epgDataEntity
    print "Here is Epg DATA Entity"
    
    TopDialogClose()
    ' NEW FLOW: Check purchase before opening DVR overlay
    checkPurchaseAndOpenOverlay()
end sub

sub TopDialogClose()
    if m.top.GetScene().dialog <> invalid then
        m.top.GetScene().dialog.close = true
    end if
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    dvrScreen = m.global.findNode("dvr_vod")
    vodListRow = m.top.findNode("vodRowList")
    print key
    print press
    
    if press = false and key = "right"
        vodListRow.setFocus(true)
        if dvrScreen.hasFocus()
            vodListRow.setFocus(true)
        end if
    else if key = "back" and press = false
        if m.lastFocusedItem <> invalid
            vodListRow.setFocus(true)
            m.rowList.itemFocused = m.lastFocusedItem
            m.rowList.itemSelected = m.lastFocusedItem
        end if
    else if (press = false or press = true) and key = "back" then
        ' Back from the content opens the rail (WPALive Back contract); Back
        ' again from the rail asks to exit the channel.
        navScreen = m.global.findNode("navigation_bar")
        navScreen.isVisible = true
        navScreen.setFocus(true)
        return true
    else if key = "left" and press = true
        if vodListRow.hasFocus()
            navScreen = m.global.findNode("navigation_bar")
            navScreen.isVisible = true
            navScreen.setFocus(true)
            return true
        end if
    else if key = "down" and press = true
        vodListRow.setFocus(true)
        return true
    else if key = "up" and press = true
        vodListRow.setFocus(true)
        return true
    else if key = "OK" and m.top.hasFocus()
        ' The rail enters on OK by focusing this screen; the key-up lands
        ' here. Hand focus on to the grid, as the other grid screens do.
        vodListRow.setFocus(true)
        return true
    else if key = "OK" and press = true and vodListRow.hasFocus()
        selectionData = getActiveEntityDetails()
        m.lastFocusedItem = m.rowList.itemFocused
        print selectionData
        print "Here is DVR selection Data"
        
        ' Store selection data for later use
        m.pendingDvrData = selectionData
        
        ' Check authentication before showing DVR overlay
        if isUserAuthenticated() then
            ' User is authenticated - now check purchase and load DVR
            initializeEPGData(selectionData.data.id)
        else
            ' User not authenticated - show message to login
            print "User not authenticated - showing login required message"
            showLoginRequiredDialog()
        end if
    end if
end function

' NEW FUNCTION: Open DVR Overlay Screen (replaces navigateToPlayVideo)
sub openDvrOverlay()
    print "Opening DVR Overlay Screen..."
    
    selectionData = m.pendingDvrData
    if selectionData = invalid
        selectionData = getActiveEntityDetails()
    end if

    if selectionData = invalid or selectionData.data = invalid
        print "No selection data available"
        return
    end if
    
    ' Create parent content node for Live source
    parentContentNode = CreateObject("roSGNode", "ContentNode")
    parentContentNode.url = selectionData.data.sources["primary"]
    parentContentNode.title = selectionData.data.title
    parentContentNode.description = selectionData.data.description
    parentContentNode.hdposterurl = selectionData.data["images"]["banner"]
    
    ' Create or reuse DVR Overlay Screen
    if m.dvrOverlay = invalid
        print "Creating new DVR Overlay Screen..."
        m.dvrOverlay = CreateObject("roSGNode", "DVROverlayScreen")
        m.dvrOverlay.id = "dvrOverlayScreen"
        
        ' Add it to the scene (not global)
        m.top.GetScene().appendChild(m.dvrOverlay)
        
        ' Set up observers only once
        m.dvrOverlay.observeField("requestOverlayClose", "onOverlayCloseRequested")
        m.dvrOverlay.observeField("selectedDvrItem", "onDvrItemSelected")
        print "✓ DVR Overlay created and added to scene"
    else
        print "Reusing existing DVR Overlay Screen..."
    end if
    
    ' IMPORTANT: Set parentContent FIRST before content
    ' DVROverlayScreen needs parentContent to build the "LIVE" item
    m.dvrOverlay.parentContent = parentContentNode
    print "✓ Parent content set"
    
    ' Pass DVR data to overlay
    print "🔍 DEBUG: m.top.epgDataEntity = "; m.top.epgDataEntity
    if m.top.epgDataEntity <> invalid and m.top.epgDataEntity.count() > 0 then
        print "🔍 DEBUG: Converting " + m.top.epgDataEntity.count().ToStr() + " EPG items"
        convertedData = convertToSimpleArray(m.top.epgDataEntity)
        print "🔍 DEBUG: Converted data count = "; convertedData.count()
        print "🔍 DEBUG: First item = "; convertedData[0]
        
        ' Set content - this will trigger onChange and call onContentLoaded automatically
        m.dvrOverlay.content = convertedData
        print "✓ Content assigned to overlay"
    else
        print "❌ DEBUG: epgDataEntity is invalid or empty!"
        m.dvrOverlay.content = []
    end if
    
    ' Show overlay and set focus
    m.dvrOverlay.visible = true
    m.dvrOverlay.setFocus(true)
    print "✓ DVR Overlay visible and focused"
    
    ' Hide dvr_vod screen and navigation
    m.top.visible = false
    navBar = m.global.findNode("navigation_bar")
    if navBar <> invalid
        navBar.visible = false
    end if
    print "✓ DVR VOD screen hidden"
end sub

' Handle overlay close request
sub onOverlayCloseRequested()
    if m.dvrOverlay <> invalid and m.dvrOverlay.requestOverlayClose = true
        print "Closing DVR Overlay..."
        m.dvrOverlay.visible = false
        
        ' Restore dvr_vod screen
        m.top.visible = true
        
        ' Restore navigation bar
        navBar = m.global.findNode("navigation_bar")
        if navBar <> invalid
            navBar.visible = true
        end if
        
        ' Restore focus to the grid
        vodListRow = m.top.findNode("vodRowList")
        if vodListRow <> invalid
            vodListRow.setFocus(true)
        end if
        
        print "✓ DVR Overlay closed, focus restored"
    end if
end sub

' Handle DVR item selection from overlay - open video player
sub onDvrItemSelected()
    if m.dvrOverlay <> invalid and m.dvrOverlay.selectedDvrItem <> invalid
        progNodeToPlay = m.dvrOverlay.selectedDvrItem
        
        ' Open video player
        m.DVRVideoPlayerScreen = m.global.findNode("videoDVRScreen")
        m.DVRVideoPlayerScreen.content = progNodeToPlay
        m.DVRVideoPlayerScreen.parentContent = m.dvrOverlay.parentContent
        m.DVRVideoPlayerScreen.navigatedFrom = "DVRVOD"
        m.DVRVideoPlayerScreen.arrayDVRs = []  ' No DVR button needed when coming from overlay
        m.DVRVideoPlayerScreen.visible = true
        m.DVRVideoPlayerScreen.setFocus(true)
        
        ' Hide overlay and navigation bar
        m.dvrOverlay.visible = false
        navBar = m.global.findNode("navigation_bar")
        if navBar <> invalid
            navBar.visible = false
        end if
        
        print "✓ Video player opened, overlay and navigation hidden"
    end if
end sub

function convertToSimpleArray(dvrFlatArray as Object) as Object
    print "🔍 convertToSimpleArray: Input count = "; dvrFlatArray.count()
    grouped = {}

    for each entry in dvrFlatArray
        dateKey = entry.date
        if not grouped.DoesExist(dateKey)
            grouped[dateKey] = []
        end if
        
        ' Map thumbnail to hdposterurl for ContentNode compatibility
        episodeItem = {}
        for each key in entry
            episodeItem[key] = entry[key]
        end for
        
        ' Add hdposterurl field mapped from thumbnail
        if entry.thumbnail <> invalid and entry.thumbnail <> ""
            episodeItem.hdposterurl = entry.thumbnail
            print "🔍 Mapped thumbnail to hdposterurl: "; entry.thumbnail
        else
            episodeItem.hdposterurl = "pkg:/images/png/no-poster-found.png"
            print "⚠️ No thumbnail found, using default image"
        end if
        
        grouped[dateKey].Push(episodeItem)
    end for

    simpleArray = []

    for each key in grouped
        item = {
            title: key,
            episodes: grouped[key]
        }
        simpleArray.Push(item)
        print "🔍 Added group: title = "; key; " with "; grouped[key].count(); " episodes"
    end for

    print "🔍 convertToSimpleArray: Output count = "; simpleArray.count()
    m.simpleArray = simpleArray
    return simpleArray
end function

' =============================================================================
' Authentication and Purchase Check Functions for DVR Access
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

' Show simple login required dialog
sub showLoginRequiredDialog()
    loginDialog = CreateObject("roSGNode", "BackDialog")
    loginDialog.title = "Login Required"
    loginDialog.message = "You need to login to access DVR recordings. Please login from the Settings screen."
    loginDialog.buttons = ["OK"]
    loginDialog.ObserveField("buttonSelected", "onLoginRequiredDialogButton")
    
    m.top.GetScene().dialog = loginDialog
    m.loginRequiredDialog = loginDialog
end sub

' Handle login required dialog button
sub onLoginRequiredDialogButton()
    if m.top.GetScene().dialog <> invalid
        m.top.GetScene().dialog.close = true
    end if
    
    ' Clear pending data
    m.pendingDvrData = invalid
    
    ' Return focus to grid
    vodListRow = m.top.findNode("vodRowList")
    if vodListRow <> invalid
        vodListRow.setFocus(true)
    end if
end sub

' Check purchase before opening DVR overlay
sub checkPurchaseAndOpenOverlay()
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
        print "✓ User has purchased - opening DVR overlay"
        openDvrOverlay()
    else if result = "not_purchased"
        print "✗ User has not purchased product"
        showPurchaseRequiredDialog()
    else if result = "unauthorized"
        print "✗ User unauthorized - session expired"
        ' Clear expired auth data to prevent endless loop
        clearAuthData()
        ' Show simple message to login again
        showSessionExpiredMessage()
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

' Show session expired message
sub showSessionExpiredMessage()
    errorDialog = CreateObject("roSGNode", "BackDialog")
    errorDialog.title = "Session Expired"
    errorDialog.message = "Your session has expired. Please login again from the Settings screen to access DVR."
    errorDialog.buttons = ["OK"]
    errorDialog.ObserveField("buttonSelected", "onSessionExpiredMessageButton")
    
    m.top.GetScene().dialog = errorDialog
    m.sessionExpiredDialog = errorDialog
end sub

' Handle session expired message button
sub onSessionExpiredMessageButton()
    if m.top.GetScene().dialog <> invalid
        m.top.GetScene().dialog.close = true
    end if
    
    ' Clear pending data
    m.pendingDvrData = invalid
    
    ' Return focus to grid
    vodListRow = m.top.findNode("vodRowList")
    if vodListRow <> invalid
        vodListRow.setFocus(true)
    end if
end sub

' Clear authentication data from registry
sub clearAuthData()
    print "Clearing expired authentication data..."
    section = "AUTH"
    sec = CreateObject("roRegistrySection", section)
    if sec.Exists("authData")
        sec.Delete("authData")
        sec.Flush()
        print "✓ Auth data cleared"
    end if
    
    ' Update user email label to show logged out
    m.userEmailLabel = m.top.findNode("userEmailLabel")
    if m.userEmailLabel <> invalid
        m.userEmailLabel.text = ""
    end if
end sub

' Handle purchase dialog button press
sub onPurchaseDialogButton()
    if m.top.GetScene().dialog <> invalid
        m.top.GetScene().dialog.close = true
    end if
    
    ' Clear pending data
    m.pendingDvrAccess = false
    m.pendingChannelId = invalid
    m.pendingDvrData = invalid
    
    ' Return focus to grid
    vodListRow = m.top.findNode("vodRowList")
    if vodListRow <> invalid
        vodListRow.setFocus(true)
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

function RegRead(key, section = invalid)
    if section = invalid section = "Default"
    sec = CreateObject("roRegistrySection", section)
    if sec.Exists(key) return sec.Read(key)
    return sec.Read(key)
end function


