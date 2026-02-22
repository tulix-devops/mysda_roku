function init()


    m.searchBox = m.top.FindNode("searchBox")
    ' m.searchBox.observeField("text", "initiateSearch")
    m.progressdialog = createObject("roSGNode", "ProgressDialog")
    m.keyboard = m.top.findNode("keyboard")
    m.keyboard.observeField("text", "updateTextBox")

    m.top.observeField("focusedChild", "handleFocus")
    m.top.searchDataEntity = m.top.findNode("searchDataEntity")
    m.top.observeField("searchDataEntity", "searchDataUpdated")
    m.searchContainer = m.top.findNode("searchContainer")
    m.rowList = m.top.findNode("searchList")


    m.applyButton = m.top.findNode("applyButton")

    m.buttonPoster = m.top.findNode("submit")
    m.buttonLabel = m.top.findNode("buttonLabel")


    m.activateKeyboard = m.top.findNode("activateKeyboard")
    m.deactivateKeyboard = m.top.findNode("deactivateKeyboard")


    m.lastFocusedItem = invalid
end function


sub activateKeyboard()
    m.activateKeyboard.control = "start"
    m.searchBox.active = true
end sub

sub deactivateKeyboard()
    m.deactivateKeyboard.control = "start"
    m.searchBox.active = false
end sub

sub updateTextBox()
    ' print m.keyboard.focusedChild
    m.searchBox.text = m.keyboard.text
    m.searchBox.cursorPosition = Len(m.searchBox.text)
end sub

sub handleFocus(event as object)
    field = event.getRoSGNode()
    if m.top.hasFocus() then
        m.keyboard.visible = true
        m.keyboard.setFocus(true)
        print m.keyboard.focusedChild
        print "FocusedChild is here"
        activateKeyboard()
    end if

    ' m.top.unobserveField("focusedChild")
    ' if not m.keyboard.hasFocus() then
    '     m.keyboard.visible = true
    '     m.keyboard.setFocus(true)
    '     ' m.keyboard.setField("target", field)
    ' end if

end sub


sub initiateSearch()
    m.searchedData = createObject("roSGNode", "SearchScreenApi")
    m.searchedData.observeField("responseData", "handleResponseData")
    m.searchedData.keyword = m.searchBox.text
    if len(m.searchBox.text) <> 0
        showLoadingDialog("Loading")

    end if
    ' ShowSpinner(true)
    ' m.relatedData.control = "RUN"
end sub



sub handleResponseData()
    data = m.searchedData.responseData

    m.top.searchDataEntity = parseVodScreenEntity(data, 8)
    TopDialogClose()
end sub

sub showLoadingDialog(textToShow as string)
    m.progressdialog.busySpinner.uri = "pkg:/images/png/loader.png"
    m.progressdialog.backgroundUri = "pkg:/images/png/shapes/final_transparent_mask.png"
    m.progressdialog.width = 500

    if m.top.visible = true
        m.top.GetScene().dialog = m.progressdialog
    end if



end sub

sub TopDialogClose()
    if m.top.GetScene().dialog <> invalid then
        m.top.GetScene().dialog.close = true
    end if
end sub


sub searchDataUpdated()
    if m.top.searchDataEntity <> invalid

        m.searchContainer.visible = true
        hvc = CreateObject("roSGNode", "HomeVodContent")
        defaultFont = CreateObject("roSGNode", "Font")
        defaultFont.uri = "pkg:/images/UrbanistSemiBold.ttf"
        defaultFont.size = 42

        m.rowList.focusable = true
        m.rowList.rowLabelFont = defaultFont
        content = CreateObject("roSGNode", "ContentNode")
        ' m.rowList.numColumns = vodCat.VodEntityData.count()
        ' m.rowList.numRows = 4


        content.title = "Search keyword for " + "'" + m.searchBox.text + "'"
        for each vodData in m.top.searchDataEntity
            item = CreateObject("roSGNode", "ContentNode")
            item.title = vodData.title
            item.addfields({
                rowItemFocus: false
                data: vodData
                isLiveChannel: false
            })
            item.focusable = true
            ' item.hdPosterUrl = "https://183.bozztv.com/storage/movies/" + vodData.storageRecord["thumb"]
            if vodData.images <> invalid
                if vodData.images["banner"] <> invalid
                    item.hdPosterUrl = vodData.images["banner"]
                else item.hdPosterUrl = "pkg:/images/png/no-poster-found.png"
                end if
            end if

            content.appendChild(item)
        end for
        hvc.appendChild(content)
        ' m.rowList.content = content
        ' m.rowList.content = content

        ' m.rowList.content = CreateObject("roSGNode", "RowListContent")

        m.rowList.content = hvc
        m.searchContainer.appendChild(m.rowList)
        m.rowList.observeField("rowItemFocused", "onRowItemFocused")


    end if

    ' ShowSpinner(false)
end sub

sub activateButton()

    m.buttonLabel.color = "#000000"
    m.buttonPoster.uri = "pkg:/images/png/shapes/active_button.png"

    ' active_button
end sub


sub deactivateButton()
    m.buttonLabel.color = "0xFFFFFF"
    m.buttonPoster.uri = "pkg:/images/png/shapes/grey_rounded.png"
end sub


function onKeyEvent(key as string, press as boolean) as boolean
    searchScreen = m.global.findNode("search_screen")
    vodListRow = m.top.findNode("exampleRowList")

    print press
    print key

    print "KeyPress Above"

    if press = false and key = "right"
        if searchScreen.hasFocus()
            return true
        end if
    else if key = "back" and press = false
        if m.lastFocusedItem <> invalid
            m.rowList.setFocus(true)
            m.rowList.rowItemFocused = m.lastFocusedItem
        end if
    else if (press = false or press = true) and key = "back" then
        unFocusActiveVODRowItem()
        deactivateButton()
        deactivateKeyboard()
        m.navBar = m.global.findNode("navigation_bar")
        m.navBar.setFocus(true)
        m.navBar.navHasFocus = true
        return true
    else if key = "right" and press = true
    else if key = "down" and press = true
        if m.applyButton.hasFocus() then
            deactivateButton()
            m.rowList.setFocus(true)
        else if m.rowList.hasFocus() then
            activateKeyboard()
            m.keyboard.setFocus(true)
        end if
    else if key = "up" and press = true
        if m.rowList.hasFocus() then
            m.applyButton.setFocus(true)
            activateButton()
            return true
        end if
        deactivateKeyboard()
        m.applyButton.setFocus(true)
        activateButton()
        return true
        if m.keyboard.hasFocus() then
            print "Do we get here?"
            m.applyButton.setFocus(true)
            return true
        end if
        ' if vodListRow.hasFocus()
        '     getVodActiveRowIndex = getActiveVODRowIndex()[0]
        '     if getVodActiveRowIndex = 0
        '         unFocusActiveVODRowItem()

        '     end if
        ' end if
    else if key = "back" and press = true then
        m.navBar = m.global.findNode("navigation_bar")
        m.navBar.setFocus(true)
        m.navBar.navHasFocus = true
        return true
    else if key = "left" and press = true
        ' if vodListRow.hasFocus()
        '     getVodActiveRowIndex = getActiveVODRowIndex()[1]
        '     if getVodActiveRowIndex = 0
        '         unFocusActiveVODRowItem()
        '         m.navBar = m.global.findNode("navigation_bar")
        '         m.navBar.setFocus(true)
        '         m.navBar.navHasFocus = true
        '         m.navBar.navHasFocus = true
        '         deactivateRow()
        '     end if
        ' end if

    else if key = "OK"
        print "But we are getting HerE?"
        if m.applyButton.hasFocus() then
            initiateSearch()
            return true
        else if m.rowList.hasFocus() then
            print "we are getting here but nothing is hpapening????"
            ' detailScreen = m.global.findNode("detailScene")
            ' selectionData = getActiveVODEntity()
            selectionData = getActiveEntityDetails()
            ' detailScreen.navigatedFrom = "Search"
            m.lastFocusedItem = m.rowList.rowItemFocused
            ' detailScreen.detailScreenData = []
            ' tmpData = []
            ' tmpData.push(selectionData)
            ' detailScreen.detailScreenData = tmpData
            ' detailScreen.setFocus(true)
            ' detailScreen.visible = true
            m.isDetailScreenPushed = true
            ' m.videoPlayerScreen = m.global.findNode("videoPlayerScreen")
            ' m.videoPlayerScreen.navigatedFrom = "Search"
            m.DVRVideoPlayerScreen = m.global.findNode("videoDVRScreen")
            m.DVRVideoPlayerScreen.navigatedFrom = "Search"
            progNodeToPlay = CreateObject("roSGNode", "ContentNode")
            progNodeToPlay.url = selectionData.data.sources["primary"]
            progNodeToPlay.title = selectionData.data.title
            progNodeToPlay.description = selectionData.data.description
            progNodeToPlay.hdposterurl = selectionData.data["images"]["thumbnail"]
            ' progNodeToPlay.playStart = "00"duration
            progNodeToPlay.playDuration = selectionData.data.duration * 60
            progNodeToPlay.addFields({
                isCC: "false",
                isHD: "true",
                channelTitle: "JoyGo"
            })

            ' m.videoPlayerScreen.setFocus(true)
            ' m.videoPlayerScreen.contentProgram = progNodeToPlay
            m.DVRVideoPlayerScreen.content = progNodeToPlay
            m.DVRVideoPlayerScreen.setFocus(true)
            m.DVRVideoPlayerScreen.visible = true
            ' m.videoPlayerScreen.visible = true

            m.global.findNode("navigation_bar").visible = false
            m.global.findNode("search_screen").visible = false
        end if
        ' detailScreen = m.global.findNode("detailScene")
        ' ' selectionData = getActiveVODEntity()
        ' selectionData = getActiveEntityDetails()
        ' detailScreen.detailScreenData = []
        ' tmpData = []
        ' tmpData.push(selectionData)
        ' detailScreen.detailScreenData = tmpData
        ' detailScreen.setFocus(true)
        ' detailScreen.visible = true
        ' m.isDetailScreenPushed = true
        ' m.global.findNode("navigation_bar").visible = false
        ' m.global.findNode("home_screen").visible = false

    end if

    return false
end function



sub unFocusActiveVODRowItem()
    if m.searchContainer.visible = true and m.rowList.hasFocus()
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
    end if

end sub

' Helper function to find the index of the currently focused child
function getFocusedChildIndex(container as object) as integer
    for i = 0 to container.getChildCount() - 1
        if container.getChild(i).hasFocus()
            return i
        end if
    end for
    return -1 ' In case no child has focus
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



