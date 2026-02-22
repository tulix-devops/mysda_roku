
function init()
    m.progressdialog = createObject("roSGNode", "ProgressDialog")
    m.top.observeField("visible", "onScreenVisibilityChanged")

    m.vodDataCache = {}


    ' fetchCategoryData()

    fetchVodScreenData()

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
    animation = m.top.findNode("MoveCategoryIn")
    if animation <> invalid
        
        animation.control = "start"
    end if
  end sub
  
  sub startCollapseAnimation()
    animation = m.top.findNode("MoveCategoryOut")
    if animation <> invalid
      
        animation.control = "start"
    end if
  end sub


sub fetchCategoryData()
    showLoadingDialog("Loading, please wait...")
    m.categoryData = createObject("roSGNode", "CategoriesData")
    m.categoryData.observeField("responseData", "handleCategoryResponseData")
    m.categoryData.typeID = 1
    m.categoryData.control = "RUN"
end sub


sub handleCategoryResponseData()
    data = m.categoryData.responseData
    m.top.categoryDataEntity = parseCategoryEntity(data)
    print m.top.categoryDataEntity.count()

end sub

sub fetchVodScreenData()

    showLoadingDialog("Loading, please wait...")

    m.vodScreenData = createObject("roSGNode", "VodScreenData")
    m.vodScreenData.observeField("responseData", "handleResponseData")
    m.vodScreenData.page = m.page
    m.vodScreenData.vodType = 8
    m.vodScreenData.control = "RUN"
end sub

sub handleResponseData()
    data = m.vodScreenData.responseData
    m.page = m.page + 1
    m.top.vodDataEntity = parseVodScreenEntity(data, 0)
    print m.top.vodDataEntity.count()

end sub

sub onScreenVisibilityChanged()
    if m.top.visible = true
        if m.top.vodDataEntity = invalid
            m.top.GetScene().dialog = m.progressdialog
        end if
    else if m.top.visible = false
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


sub initializeCachedVodScreenData()
    m.contentContainer = m.top.findNode("vodContainer")
    defaultFont = CreateObject("roSGNode", "Font")
    defaultFont.uri = "pkg:/images/UrbanistSemiBold.ttf"
    defaultFont.size = 42

    if m.rowList = invalid
        m.rowList = CreateObject("roSGNode", "MarkupGrid") ' Create a new RowList if not found
        m.rowList.focusable = true
        m.rowList.observeField("itemFocused", "onItemFocused")
        m.contentContainer.appendChild(m.rowList)
    end if

    ' currentFocusedIndex = m.rowList.itemFocused
    m.lastFocusedItem = m.rowList.itemFocused

    content = m.rowList.content
    print m.rowList.content
    print "MRow List CONTENT"
    if content <> invalid
        childrenToRemove = []
        for i = 0 to content.getChildCount() - 1
            childrenToRemove.push(content.getChild(i))
        end for
        content.removeChildren(childrenToRemove)
    else
        ' Create a new content node if none exists
        content = CreateObject("roSGNode", "ContentNode")
        content.title = "VOD"
    end if

    for each vodData in m.vodDataCache[m.selectedCategory.ToStr()]
        item = CreateObject("roSGNode", "ContentNode")
        item.title = vodData.title
        item.hdPosterUrl = ""

        if vodData.images <> invalid
            if vodData.images["banner"] <> invalid
                item.hdPosterUrl = vodData.images["banner"]
            else
                item.hdPosterUrl = "pkg:/images/png/no-poster-found.png"
            end if

        end if

        item.addFields({
            rowItemFocus: false,
            data: vodData,
            isLiveChannel: false,
            focusable: true
        })
        m.totalItems = m.totalItems + 1
        content.appendChild(item)
    end for


    ' m.rowList.itemContent = content
    m.rowList.content = content
    m.rowList.itemFocused = m.lastFocusedItem
    m.rowList.jumptoitem = m.lastFocusedItem

    m.contentContainer.appendChild(m.rowList)

    

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

    ' currentFocusedIndex = m.rowList.itemFocused
    m.lastFocusedItem = m.rowList.itemFocused

    content = m.rowList.content

    ' if content = invalid
    '     content = CreateObject("roSGNode", "ContentNode")
    '     content.title = "VOD"

    ' end if

    if content <> invalid
        childrenToRemove = []
        for i = 0 to content.getChildCount() - 1
            childrenToRemove.push(content.getChild(i))
        end for
        content.removeChildren(childrenToRemove)
    else
        ' Create a new content node if none exists
        content = CreateObject("roSGNode", "ContentNode")
        content.title = "VOD"
    end if

    if m.top.vodDataEntity <> invalid
        m.vodDataCache[m.selectedCategory.ToStr()] = m.top.vodDataEntity
        for each vodData in m.top.vodDataEntity
            item = CreateObject("roSGNode", "ContentNode")
            item.title = vodData.title
            item.hdPosterUrl = ""

            print vodData.images
            print "Here is VodDATA IMAGES"

            if vodData.images <> invalid
                if vodData.images["banner"] <> invalid
                    item.hdPosterUrl = vodData.images["banner"]
                else
                    item.hdPosterUrl = "pkg:/images/png/no-poster-found.png"
                end if

            end if

            item.addFields({
                rowItemFocus: false,
                data: vodData,
                isLiveChannel: false,
                focusable: true
            })
            m.totalItems = m.totalItems + 1
            content.appendChild(item)
        end for


        ' m.rowList.itemContent = content
        m.rowList.content = content
        m.rowList.itemFocused = m.lastFocusedItem
        m.rowList.jumptoitem = m.lastFocusedItem
        ' m.rowList.setFocus(true)
    
        m.vodRowList = m.top.findNode("vodRowList")
        m.descriptionLabel = m.top.findNode("descriptionLabel")

        m.vodRowList.observeField("itemFocused", "onGridItemFocused")


        m.timer = CreateObject("roSGNode", "Timer")
        m.timer.duration = 0.5
        m.timer.control = "start"
        m.timer.observeField("fire", "onFocusReady")
    end if


end sub

sub onGridItemFocused()
    focusedIndex = m.vodRowList.itemFocused
    contentNode = m.vodRowList.content.getChild(focusedIndex)

    if contentNode <> invalid
        print contentNode
        print "Here is CONTENTNODE!!!"
        ' Get description from content
        title = contentNode.title
        m.descriptionLabel.text = title + "  •  " + "on mySDAtv" 
        m.descriptionLabel.visible = true

        ' Dynamically position the label under the focused item
        ' You can calculate based on item index and spacing
        col = focusedIndex MOD m.vodRowList.numColumns
        row = Int(focusedIndex / m.vodRowList.numColumns)

        x = 100 + col * (400 + 15) ' translation.x of grid + (itemWidth + columnSpacing)
        y = 260 + row * (200 + 20) + 200 + 5 ' translation.y + (row * height) + item height + offset

        ' m.descriptionLabel.translation = [x, y]
    else
        m.descriptionLabel.visible = false
    end if
end sub

sub onFocusReady()
    m.rowList.itemFocused = 0
    m.rowList.jumpToItem = 0
    m.rowList.setFocus(true)
  end sub

sub onItemFocused()
    itemFocusedInfo = m.rowList.itemFocused

    if itemFocusedInfo <> invalid


        focusedItemIndex = itemFocusedInfo

        ' Handle the previously focused item
        if m.prevFocusedItemIndex <> invalid
            prevFocusedItem = m.rowList.content.getChild(m.prevFocusedItemIndex)
            if prevFocusedItem <> invalid
                prevFocusedItem.rowItemFocus = false ' Reset the previous focus
            end if
        end if

        ' Retrieve the currently focused item
        focusedItem = m.rowList.content.getChild(focusedItemIndex)
        if focusedItem <> invalid
            focusedItem.rowItemFocus = true ' Set the new focus

            if focusedItem.isLiveChannel = true
                m.videoPlayerScreen = m.global.findNode("vodPlayer")
                m.videoPlayerScreen.contentURL = focusedItem.data.source
                m.itemDetails = m.global.findNode("vodItemDetails")
                selectionData = getActiveEntityDetails()
                m.itemDetails.itemDetailsData = []
                tmpData = []
                tmpData.push(selectionData)
                m.itemDetails.itemDetailsData = tmpData
            else
                ' m.videoPlayerScreen = m.global.findNode("vodPlayer")
                ' m.videoPlayerScreen.contentURL = focusedItem.data.sources["trailer"]


                ' m.videoPlayerScreen.width = "1280"
                ' m.videoPlayerScreen.height = "800"
                ' m.itemDetails = m.global.findNode("vodItemDetails")
                ' selectionData = getActiveEntityDetails()
                ' m.itemDetails.itemDetailsData = []
                ' tmpData = []
                ' tmpData.push(selectionData)
                ' m.itemDetails.itemDetailsData = tmpData
            end if

            if focusedItemIndex >= m.totalItems - 7
                ' Focused item is one of the last 7 items
                ' fetchVodScreenData()
                ' You can add any specific logic you want to execute when one of the last 7 items is focused
            end if

            ' Update the previous focus indices
            m.prevFocusedItemIndex = focusedItemIndex
            ' m.prevFocusedRowIndex = lastRowIndex
        end if
    end if
end sub

sub onRowItemFocused()
    rowItemFocusedInfo = m.rowList.rowItemFocused
    print rowItemFocusedInfo
    if rowItemFocusedInfo <> invalid
        focusedRowIndex = rowItemFocusedInfo[0]
        focusedItemIndex = rowItemFocusedInfo[1]

        ' Handle the previously focused item
        if m.prevFocusedHomeRowIndex <> invalid and m.prevFocusedHomeItemIndex <> invalid
            prevFocusedRow = m.rowList.content.getChild(m.prevFocusedHomeRowIndex)
            if prevFocusedRow <> invalid
                prevFocusedItem = prevFocusedRow.getChild(m.prevFocusedHomeItemIndex)
                if prevFocusedItem <> invalid
                    prevFocusedItem.rowItemFocus = false ' Reset the previous focus
                end if
            end if
        end if

        ' Retrieve the currently focused row and item
        focusedRow = m.rowList.content.getChild(focusedRowIndex)
        if focusedRow <> invalid
            focusedItem = focusedRow.getChild(focusedItemIndex)
            if focusedItem <> invalid
                focusedItem.rowItemFocus = true ' Set the new focus
                subscription = validateSubscription()
                if focusedItem.isLiveChannel = true
                    if subscription = true
                        m.videoPlayerScreen = m.global.findNode("vodPlayer")
                        ' m.videoPlayerScreen.contentURL = focusedItem.data.storageRecord["source"]
                        m.videoPlayerScreen.contentURL = focusedItem.data.source
                    end if
                    m.itemDetails = m.global.findNode("vodItemDetails")
                    selectionData = getActiveEntityDetails()
                    m.itemDetails.itemDetailsData = []
                    tmpData = []
                    tmpData.push(selectionData)
                    m.itemDetails.itemDetailsData = tmpData
                else
                    if subscription = true
                        m.videoPlayerScreen = m.global.findNode("vodPlayer")

                        m.videoPlayerScreen.contentURL = focusedItem.data.storage["record"]["trailer"]
                        m.videoPlayerScreen.width = "1280"
                        m.videoPlayerScreen.height = "800"
                    end if
                    m.itemDetails = m.global.findNode("vodItemDetails")
                    print m.itemDetails
                    print "here is ItemDetails"
                    selectionData = getActiveEntityDetails()
                    print selectionData
                    print "Selection Data we are looking For"
                    m.itemDetails.itemDetailsData = []
                    tmpData = []
                    tmpData.push(selectionData)
                    m.itemDetails.itemDetailsData = tmpData
                end if

                print "New Focus: Row " + str(focusedRowIndex) + " Item " + str(focusedItemIndex)
            end if
        end if

        ' Update the previous focus indices
        m.prevFocusedHomeRowIndex = focusedRowIndex
        m.prevFocusedHomeItemIndex = focusedItemIndex
    end if
end sub


sub validateSubscription() as boolean
    authData = RetrieveAuthData()
    print authData
    if authData <> invalid
        if authData.subscribed = 1
            return true
        else

            return false
        end if
    else
        return false
    end if
end sub


function RetrieveAuthData() as object
    section = "AUTH"
    jsonData = RegRead("authData", section)
    ' Check if the JSON data is valid
    if jsonData <> invalid and jsonData <> ""
        ' Deserialize the JSON string back into an associative array
        data = ParseJson(jsonData)
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
    initializeVodScreen()
    TopDialogClose()


    m.rowList.itemFocused = m.lastFocusedItem
    m.rowList.itemSelected = m.lastFocusedItem
end sub

' EPG/DVR functionality removed for vod_screen









sub onCategoryItemFocused()
    rowItemFocusedInfo = m.categoryRowList.rowItemFocused
    print "Is Category Item Being Focused"
    if rowItemFocusedInfo <> invalid
        print rowItemFocusedInfo
        focusedRowIndex = rowItemFocusedInfo[0]
        focusedItemIndex = rowItemFocusedInfo[1]



        ' Retrieve the currently focused item
        focusedRow = m.categoryRowList.content.getChild(focusedRowIndex)
        if focusedRow <> invalid
            focusedItem = focusedRow.getChild(focusedItemIndex)
            if focusedItem <> invalid
                if m.lastFocusedCategoryItem <> invalid
                    m.lastFocusedCategoryItem.isSelected = false
                end if

                m.lastFocusedCategoryItem = focusedItem
                focusedItem.rowItemFocus = true ' Set the new focus
                print focusedItem
                print "CATEGORY FOCUSED ITEM"
                focusedItem.isSelected = true
                if focusedItemIndex <> 0 then
                    m.selectedCategory = focusedItem.data.id
                else if focusedItemIndex = 0 and m.firstCategoryInitialization = true
                    m.selectedCategory = focusedItem.data.id
                end if

            end if

        end if
    end if
end sub


sub TopDialogClose()
    if m.top.GetScene().dialog <> invalid then
        m.top.GetScene().dialog.close = true
    end if
end sub


sub activateRow()
 
    ' Start the translation animation
    m.activateRow.control = "start"
    m.activateItemDetails.control = "start"
end sub

sub deactivateRow() 

    m.deactivateItemDetails.control = "start"

    ' Start the translation animation
    m.deactivateRow.control = "start"
end sub



function onKeyEvent(key as string, press as boolean) as boolean
    vodScreen = m.global.findNode("vod_screen")
    vodListRow = m.top.findNode("vodRowList")
    categoryRowList = m.top.findNode("categoryRowList")
    print key
    print press
    if press = false and key = "right"
        vodListRow.setFocus(true)
        if vodScreen.hasFocus()
            vodListRow.setFocus(true)
            ' categoryRowList.setFocus(true)
            ' activateRow()
        end if
    else if key = "back" and press = false
        if m.lastFocusedItem <> invalid
            vodListRow.setFocus(true)
            m.rowList.itemFocused = m.lastFocusedItem
        end if
    else if (press = false or press = true) and key = "back" then
        vodListRow.setFocus(true)
        ' unFocusActiveVODRowItem()
        ' m.navBar = m.global.findNode("navigation_bar")
        ' m.navBar.setFocus(true)
        ' m.navBar.navHasFocus = true
        ' deactivateRow()
        ' m.videoPlayerScreen = m.global.findNode("vodPlayer")
        ' m.videoPlayerScreen.contentURL = ""
        ' m.vodAnimationInitialized = false
        return true
    else if key = "left" and press = true
        if vodListRow.hasFocus()
            navScreen = m.global.findNode("navigation_bar")
            navScreen.isVisible = true
            navScreen.setFocus(true)
            return true
        end if
        ' if m.rowList.hasFocus()
        '     if m.rowList.itemFocused mod 5 = 0 then
        '         ' Perform actions when the focused item index matches the condition
        '         unFocusActiveVODRowItem()
        '         m.navBar = m.global.findNode("navigation_bar")
        '         m.navBar.setFocus(true)
        '         m.navBar.navHasFocus = true
        '         deactivateRow()
        '         m.videoPlayerScreen = m.global.findNode("vodPlayer")
        '         m.videoPlayerScreen.contentURL = ""
        '         m.vodAnimationInitialized = false
        '     end if
        ' end if
        ' vodListRow.setFocus(true)
        ' if categoryRowList.hasFocus()
        '     if getActiveCategoryRowIndex()[1] = 0
        '         m.navBar = m.global.findNode("navigation_bar")
        '         m.navBar.setFocus(true)
        '         m.navBar.navHasFocus = true
        '         ' deactivateRow()
        '         m.videoPlayerScreen = m.global.findNode("vodPlayer")
        '         m.videoPlayerScreen.contentURL = ""
        '         m.vodAnimationInitialized = false
        '     end if

        ' end if

    else if key = "down" and press = true
        ' if categoryRowList.hasFocus()
        ' if m.vodAnimationInitialized = false
        '     activateRow()
        '     m.vodAnimationInitialized = true
        ' end if
        vodListRow.setFocus(true)
        return true
        ' end if
    else if key = "up" and press = true
        vodListRow.setFocus(true)
        return true
        if vodListRow.hasFocus() and vodListRow.itemFocused <= 5 then
            ' deactivateRow()
            ' m.vodAnimationInitialized = false
            ' categoryRowList.setFocus(true)
            vodListRow.setFocus(true)
            return true
        end if
    else if key = "OK" and m.top.hasFocus()
        vodListRow.setFocus(true)
        return true
    else if key = "OK" and vodListRow.hasFocus()
        ' m.videoPlayerScreen = m.global.findNode("vodPlayer")
        ' m.videoPlayerScreen.contentURL = ""
        ' detailScreen = m.global.findNode("detailScene")
        selectionData = getActiveEntityDetails()
        m.lastFocusedItem = m.rowList.itemFocused
        print selectionData
        ' Direct play - no DVR/EPG fetching for vod_screen
        navigateToPlayVideo()
        ' detailScreen.detailScreenData = []
        ' detailScreen.navigatedFrom = "VOD"
        ' tmpData = []
        ' tmpData.push(selectionData)
        ' detailScreen.detailScreenData = tmpData
        ' detailScreen.setFocus(true)
        ' detailScreen.visible = true
        ' m.lastFocusedItem = m.rowList.rowItemFocused
        ' m.lastFocusedItem = m.rowList.itemFocused
        ' m.isDetailScreenPushed = true

        ' m.DVRVideoPlayerScreen = m.global.findNode("videoPlayerScreen")
        ' m.DVRVideoPlayerScreen = m.global.findNode("videoDVRScreen")

        ' progNodeToPlay = CreateObject("roSGNode", "ContentNode")
        ' progNodeToPlay.url = selectionData.data.sources["primary"]
        ' progNodeToPlay.title = selectionData.data.title
        ' progNodeToPlay.description = selectionData.data.description
        ' if selectionData.data.attributes["Production Year"] <> invalid
        '     progNodeToPlay.addFields({
        '         productionyear: selectionData.data.attributes["Production Year"],
        '     })
        ' end if

        ' progNodeToPlay.hdposterurl = selectionData.data["images"]["banner"]
        ' progNodeToPlay.playStart = "00"duration
        ' progNodeToPlay.playDuration = selectionData.data.duration * 60
        ' progNodeToPlay.addFields({
        '     isCC: "false",
        '     isHD: "true",
        '     channelTitle: "MySdaTV"
        ' })

        ' m.DVRVideoPlayerScreen.navigatedFrom = "VOD"


        ' m.DVRVideoPlayerScreen.contentProgram = progNodeToPlay
        ' m.DVRVideoPlayerScreen.content = progNodeToPlay
        ' m.global.findNode("vod_screen").visible = false
        ' m.DVRVideoPlayerScreen.setFocus(true)
        ' m.DVRVideoPlayerScreen.visible = true

        
    end if
end function



sub navigateToPlayVideo()
    ' m.videoPlayerScreen = m.global.findNode("videoPlayerScreen")
    m.DVRVideoPlayerScreen = m.global.findNode("videoDVRScreen")

    selectionData = getActiveEntityDetails()
  

        progNodeToPlay = CreateObject("roSGNode", "ContentNode")
        progNodeToPlay.url = selectionData.data.sources["primary"]
        progNodeToPlay.title = selectionData.data.title
        progNodeToPlay.description = selectionData.data.description
        progNodeToPlay.hdposterurl = selectionData.data["images"]["banner"]
        progNodeToPlay.addFields({
            isCC: "false",
            isHD: "true",
            channelTitle: "mySDATV"
        })

       

        m.DVRVideoPlayerScreen.setFocus(true)
        m.DVRVideoPlayerScreen.visible = true
        m.DVRVideoPlayerScreen.navigatedFrom = "VOD"
        m.DVRVideoPlayerScreen.parentContent = progNodeToPlay
        m.DVRVideoPlayerScreen.content = progNodeToPlay
        ' No DVR functionality for vod_screen
        m.DVRVideoPlayerScreen.arrayDVRs = []




    m.global.findNode("vod_screen").visible = false
    m.global.findNode("navigation_bar").visible = false
end sub

' DVR conversion functions removed - not needed for vod_screen


function getActiveLiveRowIndex()
    rowItemFocusedInfo = m.rowList.focusedChild.rowItemFocused
    focusedRowIndex = -1
    if rowItemFocusedInfo <> invalid
        focusedRowIndex = rowItemFocusedInfo[0]
        focusedItemIndex = rowItemFocusedInfo[1]
        print "Row " + str(focusedRowIndex) + " Item " + str(focusedItemIndex) + " is focused."
    end if

    return [focusedRowIndex, focusedItemIndex]
end function

sub unFocusActiveVODRowItem()
    rowItemFocusedInfo = m.rowList.rowItemFocused
    if rowItemFocusedInfo <> invalid
        focusedRowIndex = rowItemFocusedInfo[0]
        focusedItemIndex = rowItemFocusedInfo[1]
        focusedRow = m.rowList.content.getChild(focusedRowIndex)
        if focusedRow <> invalid
            focusedItem = focusedRow.getChild(focusedItemIndex)
            if focusedItem <> invalid
                focusedItem.rowItemFocus = false
            end if
        end if
    end if
end sub

function getActiveCategoryRowIndex()
    rowItemFocusedInfo = m.categoryRowList.focusedChild.rowItemFocused
    focusedRowIndex = -1
    if rowItemFocusedInfo <> invalid
        focusedRowIndex = rowItemFocusedInfo[0]
        focusedItemIndex = rowItemFocusedInfo[1]
        print "Row " + str(focusedRowIndex) + " Item " + str(focusedItemIndex) + " is focused."
    end if

    return [focusedRowIndex, focusedItemIndex]
end function

