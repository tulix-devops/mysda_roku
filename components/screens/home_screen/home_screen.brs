function init()
    m.spinLoader = false
    m.progressdialog = createObject("roSGNode", "ProgressDialog")
    m.top.observeField("visible", "onScreenVisibilityChanged")
    ' initializeLiveChannelData()
    fetchHomeScreenData()
    m.prevFocusedHomeRowIndex = invalid
    m.prevFocusedHomeItemIndex = invalid
    m.prevFocusedLiveRowIndex = invalid
    m.prevFocusedLiveItemIndex = invalid

    m.activateRow = m.top.findNode("activateRow")
    m.deactivateRow = m.top.findNode("deactivateRow")
    m.activateItemDetails = m.top.findNode("activateItemDetails")
    m.deactivateItemDetails = m.top.findNode("deactivateItemDetails")

    m.isDetailScreenPushed = false


    m.top.nestedDetailScene = m.top.findNode("nestedDetailScene")

    m.top.mainGroup = m.top.findNode("mainGroup")

    ' m.top.nestedDetailScene.observeField("visible", "onNestedDetailSceenChanged")


    m.lastFocusedItem = invalid

end function

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


sub onScreenVisibilityChanged()
    if m.top.visible = true
        if m.top.homeScreenDataEntity = invalid
            m.top.GetScene().dialog = m.progressdialog
        else if m.isDetailScreenPushed = true then
            m.isDetailScreenPushed = false
            m.top.findNode("exampleRowList").setFocus(true)
        end if
    else if m.top.visible = false
        TopDialogClose()
    end if
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    print key
    print press
    print "Main Screen Brs OnKeyEvent"

    homeScreen = m.global.findNode("home_screen")
    vodListRow = m.top.findNode("exampleRowList")

    if press = false and key = "right"
        if homeScreen.hasFocus()
            vodListRow.setFocus(true)
            activateRow()
        end if
    else if key = "back" and press = false
        if m.lastFocusedItem <> invalid
            vodListRow.setFocus(true)
            m.rowList.rowItemFocused = m.lastFocusedItem
        end if
    else if (press = false or press = true) and key = "back" then
        unFocusActiveVODRowItem()
        m.navBar = m.global.findNode("navigation_bar")
        m.navBar.setFocus(true)
        m.navBar.navHasFocus = true
        deactivateRow()
        m.videoPlayerScreen = m.global.findNode("homePlayer")
        m.videoPlayerScreen.contentURL = ""
        return true
    else if key = "right" and press = true
    else if key = "down" and press = true

        if vodListRow.hasFocus()

        end if
    else if key = "up" and press = true
        if vodListRow.hasFocus()
            getVodActiveRowIndex = getActiveVODRowIndex()[0]
            if getVodActiveRowIndex = 0
                unFocusActiveVODRowItem()

            end if
        end if

    else if key = "left" and press = true
        if vodListRow.hasFocus()
            getVodActiveRowIndex = getActiveVODRowIndex()[1]
            if getVodActiveRowIndex = 0
                unFocusActiveVODRowItem()
                m.navBar = m.global.findNode("navigation_bar")
                m.navBar.setFocus(true)
                m.navBar.navHasFocus = true
                deactivateRow()
                m.videoPlayerScreen = m.global.findNode("homePlayer")
                m.videoPlayerScreen.contentURL = ""
            end if
        end if

    else if key = "OK"
        m.videoPlayerScreen = m.global.findNode("homePlayer")
        m.videoPlayerScreen.contentURL = ""
        ' detailScreen =
        ' detailScreen = m.global.findNode("detailScene")
        ' selectionData = getActiveVODEntity()
        selectionData = getActiveEntityDetails()
        ' detailScreen.detailScreenData = []
        ' detailScreen.navigatedFrom = "HOME"
        ' m.lastFocusedItem = m.rowList.rowItemFocused
        ' tmpData = []
        ' tmpData.push(selectionData)
        ' detailScreen.detailScreenData = tmpData
        ' detailScreen.setFocus(true)
        ' detailScreen.visible = true
        ' m.isDetailScreenPushed = true



        m.isDetailScreenPushed = true
        ' m.videoPlayerScreen = m.global.findNode("videoPlayerScreen")
        ' m.videoPlayerScreen.navigatedFrom = "HOME"
        m.DVRVideoPlayerScreen = m.global.findNode("videoDVRScreen")
        m.DVRVideoPlayerScreen.navigatedFrom = "HOME"

        progNodeToPlay = CreateObject("roSGNode", "ContentNode")
        progNodeToPlay.url = selectionData.data.sources["primary"]
        progNodeToPlay.title = selectionData.data.title
        progNodeToPlay.description = selectionData.data.description
        progNodeToPlay.hdposterurl = selectionData.data["images"]["banner"]
        ' progNodeToPlay.playStart = "00"duration
        progNodeToPlay.playDuration = selectionData.data.duration * 60
        progNodeToPlay.addFields({
            isCC: "false",
            isHD: "true",
            channelTitle: "JoyGo"
        })

        ' m.videoPlayerScreen.setFocus(true)
        ' m.videoPlayerScreen.contentProgram = progNodeToPlay
        ' m.videoPlayerScreen.visible = true
        m.DVRVideoPlayerScreen.content = progNodeToPlay
        m.DVRVideoPlayerScreen.visible = true
        m.DVRVideoPlayerScreen.setFocus(true)

        m.global.findNode("navigation_bar").visible = false
        m.global.findNode("home_screen").visible = false

    end if

    return false
end function


function associativeToArray(assocArray as object) as object
    result = CreateObject("roArray", assocArray.count(), true)
    for each key in assocArray.keys()
        result.push({ key: key, value: assocArray[key] })
    end for
    return result
end function


function getFocusedChildIndex(container as object) as integer
    for i = 0 to container.getChildCount() - 1
        if container.getChild(i).hasFocus()
            return i
        end if
    end for
    return -1 ' In case no child has focus
end function


sub fetchHomeScreenData()
    showLoadingDialog("Loading, please wait...")
    m.homeScreenData = createObject("roSGNode", "HomeScreenData")
    m.homeScreenData.observeField("responseData", "handleResponseData")
    m.homeScreenData.control = "RUN"
end sub

sub showLoadingDialog(textToShow as string)
    m.progressdialog.busySpinner.uri = "pkg:/images/png/loader.png"
    m.progressdialog.backgroundUri = "pkg:/images/png/shapes/final_transparent_mask.png"
    m.progressdialog.width = 500

    if m.top.visible = true
        m.top.GetScene().dialog = m.progressdialog
    end if



end sub


sub handleLiveChannelsUpdate()
end sub



sub TopDialogClose()
    if m.top.GetScene().dialog <> invalid then
        m.top.GetScene().dialog.close = true
    end if
end sub


sub handleResponseData()
    data = m.homeScreenData.responseData

    m.top.homeScreenDataEntity = parseHomeVodEntity(data)
end sub


sub updateHomeScreen()
    initializeHomeScreen()
    TopDialogClose()
end sub


function initializeLiveChannelData()
    m.liveChannelData = createObject("roSGNode", "LiveScreenApi")
    m.liveChannelData.observeField("responseData", "handleLiveChannelResponseData")
    m.liveChannelData.control = "RUN"

end function


sub handleLiveChannelResponseData()
    data = m.liveChannelData.responseData

    m.top.liveChannelsEntity = parseChannelEntity(data)

end sub


sub fetchLiveScreenData()
    ' m.liveContentContainer = m.top.findNode("liveListContainer")
    ' hvc = CreateObject("roSGNode", "HomeVodContent")
    ' if m.top.liveChannelsEntity <> invalid
    '     content = CreateObject("roSGNode", "ContentNode")
    '     content.title = "Live channels"
    '     for each channel in m.top.liveChannelsEntity
    '         item = CreateObject("roSGNode", "ContentNode")
    '         item.title = channel.title
    '         item.isChannel = true
    '         item.focusable = true
    '         item.addfields({
    '             rowItemFocus: false
    '             data: channel
    '         })
    '         item.hdPosterUrl = "https://183.bozztv.com/storage/movies/" + channel.storageRecord["thumb"]
    '         content.appendChild(item)
    '     end for
    '     hvc.appendChild(content)
    ' end if
    ' m.liveRowList = m.top.findNode("liveListRow")
    ' ' content = CreateObject("roSGNode", "ContentNode")
    ' m.liveRowList.focusable = true
    ' ' hvc.appendChild(content)
    ' m.liveRowList.content = hvc
    ' m.liveContentContainer.appendChild(m.liveRowList)
    ' m.liveRowList.observeField("rowItemFocused", "onLiveRowItemFocused")

end sub


sub initializeHomeScreen()
    m.contentContainer = m.top.findNode("contentContainer")
    hvc = CreateObject("roSGNode", "HomeVodContent")
    defaultFont = CreateObject("roSGNode", "Font")
    defaultFont.uri = "pkg:/images/UrbanistSemiBold.ttf"
    defaultFont.size = 42
    m.rowList = m.top.findNode("exampleRowList")
    m.rowList.focusable = true
    m.rowList.rowLabelFont = defaultFont
    ' if m.top.liveChannelsEntity <> invalid
    '     m.liveScreen = m.global.findNode("live_screen")
    '     m.liveScreen.liveChannelsEntity = m.top.liveChannelsEntity
    '     content = CreateObject("roSGNode", "ContentNode")
    '     content.title = "Live channels"
    '     for each channel in m.top.liveChannelsEntity
    '         item = CreateObject("roSGNode", "ContentNode")
    '         item.title = channel.title
    '         item.focusable = true
    '         item.addfields({
    '             rowItemFocus: false
    '             data: channel
    '             isLiveChannel: true
    '         })
    '         ' item.hdPosterUrl = channel.storage["record"]["thumb"]
    '         item.hdPosterUrl = channel.banner
    '         ' "https://183.bozztv.com/storage/movies/" + channel.storageRecord["thumb"]
    '         content.appendChild(item)
    '     end for
    '     hvc.appendChild(content)
    ' end if

    for each vodCat in m.top.homeScreenDataEntity
        content = CreateObject("roSGNode", "ContentNode")
        ' m.rowList.numColumns = vodCat.VodEntityData.count()
        ' m.rowList.numRows = 4


        content.title = vodCat.categoryName
        for each vodData in vodCat.VodEntityData
            item = CreateObject("roSGNode", "ContentNode")
            item.title = vodData.title
            item.addfields({
                rowItemFocus: false
                data: vodData
                isLiveChannel: false
            })
            item.focusable = true

            if vodData.images <> invalid
                if vodData.images["banner"] <> invalid
                    print vodData.images["banner"]
                    print "Here is Banner"
                    item.hdPosterUrl = vodData.images["banner"]
                else item.hdPosterUrl = "pkg:/images/png/no-poster-found.png"
                end if
            end if

            content.appendChild(item)
        end for
        hvc.appendChild(content)

    end for
    m.rowList.content = hvc
    m.contentContainer.appendChild(m.rowList)
    m.rowList.observeField("rowItemFocused", "onRowItemFocused")
end sub







sub onLiveRowItemFocused()
    rowItemFocusedInfo = m.liveRowList.rowItemFocused
    if rowItemFocusedInfo <> invalid
        focusedRowIndex = rowItemFocusedInfo[0]
        focusedItemIndex = rowItemFocusedInfo[1]

        ' Handle the previously focused item
        if m.prevFocusedLiveRowIndex <> invalid and m.prevFocusedLiveItemIndex <> invalid
            prevFocusedRow = m.liveRowList.content.getChild(m.prevFocusedLiveRowIndex)
            if prevFocusedRow <> invalid
                prevFocusedItem = prevFocusedRow.getChild(m.prevFocusedLiveItemIndex)
                if prevFocusedItem <> invalid
                    prevFocusedItem.rowItemFocus = false ' Reset the previous focus
                end if
            end if
        end if

        ' Retrieve the currently focused row and item
        focusedRow = m.liveRowList.content.getChild(focusedRowIndex)
        if focusedRow <> invalid
            focusedItem = focusedRow.getChild(focusedItemIndex)
            if focusedItem <> invalid
                focusedItem.rowItemFocus = true ' Set the new focus
                print "New Focus: Row " + str(focusedRowIndex) + " Item " + str(focusedItemIndex)
            end if
        end if

        ' Update the previous focus indices
        m.prevFocusedLiveRowIndex = focusedRowIndex
        m.prevFocusedLiveItemIndex = focusedItemIndex
    end if
end sub


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


function getActiveVODEntity()
    rowItemFocusedInfo = m.rowList.rowItemFocused
    if rowItemFocusedInfo <> invalid
        focusedRowIndex = rowItemFocusedInfo[0]
        focusedItemIndex = rowItemFocusedInfo[1]
        focusedRow = m.rowList.content.getChild(focusedRowIndex)
        if focusedRow <> invalid
            focusedItem = focusedRow.getChild(focusedItemIndex)
            if focusedItem <> invalid

                return focusedItem.data
            end if
        end if
    end if
end function

function getActiveEntityDetails()
    rowItemFocusedInfo = m.rowList.rowItemFocused
    if rowItemFocusedInfo <> invalid
        focusedRowIndex = rowItemFocusedInfo[0]
        focusedItemIndex = rowItemFocusedInfo[1]
        focusedRow = m.rowList.content.getChild(focusedRowIndex)
        if focusedRow <> invalid
            focusedItem = focusedRow.getChild(focusedItemIndex)
            if focusedItem <> invalid

                return focusedItem
            end if
        end if
    end if
end function


sub onRowItemFocused()
    rowItemFocusedInfo = m.rowList.rowItemFocused
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
                        m.videoPlayerScreen = m.global.findNode("homePlayer")
                        ' m.videoPlayerScreen.contentURL = focusedItem.data.storageRecord["source"]
                        m.videoPlayerScreen.contentURL = focusedItem.data.source
                        m.videoPlayerScreen.width = "1280"
                        m.videoPlayerScreen.height = "640"
                    end if

                    m.itemDetails = m.global.findNode("itemDetailLayout")
                    selectionData = getActiveEntityDetails()
                    m.itemDetails.itemDetailsData = []
                    tmpData = []
                    tmpData.push(selectionData)
                    m.itemDetails.itemDetailsData = tmpData
                else
                    if subscription = true
                        m.videoPlayerScreen = m.global.findNode("homePlayer")
                        ' m.videoPlayerScreen.contentURL = focusedItem.data.storage["record"]["trailer"]
                        m.videoPlayerScreen.contentURL = focusedItem.data.sources["trailer"]
                        m.videoPlayerScreen.width = "1280"
                        m.videoPlayerScreen.height = "640"
                    end if

                    m.itemDetails = m.global.findNode("itemDetailLayout")
                    selectionData = getActiveEntityDetails()
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


function getActiveVODRowIndex()
    rowItemFocusedInfo = m.rowList.focusedChild.rowItemFocused
    focusedRowIndex = -1
    if rowItemFocusedInfo <> invalid
        focusedRowIndex = rowItemFocusedInfo[0]
        focusedItemIndex = rowItemFocusedInfo[1]
        print "Row " + str(focusedRowIndex) + " Item " + str(focusedItemIndex) + " is focused."
    end if

    return [focusedRowIndex, focusedItemIndex]
end function




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




