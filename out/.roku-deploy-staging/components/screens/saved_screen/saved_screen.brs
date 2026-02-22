
function init()
    m.noreMoreData = 0
    m.progressdialog = createObject("roSGNode", "ProgressDialog")
    m.top.observeField("visible", "onScreenVisibilityChanged")
    m.vodDataCache = {}

    fetchCategoryData()

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

end function



sub fetchCategoryData()
    showLoadingDialog("Loading, please wait...")
    m.categoryData = createObject("roSGNode", "CategoriesData")
    m.categoryData.observeField("responseData", "handleCategoryResponseData")
    m.categoryData.typeID = 2
    m.categoryData.control = "RUN"
end sub


sub handleCategoryResponseData()
    data = m.categoryData.responseData
    m.top.categoryDataEntity = parseCategoryEntity(data)
    print m.top.categoryDataEntity.count()

end sub


sub handleResponseData()
    data = m.vodScreenData.responseData
    m.page = m.page + 1
    if data = "empty"
        m.noreMoreData = 1
        TopDialogClose()
    else
        m.top.vodDataEntity = parseVodScreenEntity(data, 0)
    end if

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
                if vodData.images["thumbnail"] <> invalid
                    item.hdPosterUrl = vodData.images["thumbnail"]
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

    end if


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
                m.videoPlayerScreen = m.global.findNode("tvShowPlayer")
                m.videoPlayerScreen.contentURL = focusedItem.data.source
                m.itemDetails = m.global.findNode("tvShowItemDetails")
                selectionData = getActiveEntityDetails()
                m.itemDetails.itemDetailsData = []
                tmpData = []
                tmpData.push(selectionData)
                m.itemDetails.itemDetailsData = tmpData
            else
                m.videoPlayerScreen = m.global.findNode("tvShowPlayer")
                m.videoPlayerScreen.contentURL = focusedItem.data.sources["trailer"]
                m.videoPlayerScreen.width = "1280"
                m.videoPlayerScreen.height = "800"
                m.itemDetails = m.global.findNode("tvShowItemDetails")
                selectionData = getActiveEntityDetails()
                m.itemDetails.itemDetailsData = []
                tmpData = []
                tmpData.push(selectionData)
                m.itemDetails.itemDetailsData = tmpData
            end if

            print "New Focus: Item " + str(focusedItemIndex)
            print focusedItemIndex
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
    print "Hello Row Item Focused info is Here"
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
                        m.videoPlayerScreen = m.global.findNode("tvShowPlayer")
                        ' m.videoPlayerScreen.contentURL = focusedItem.data.storageRecord["source"]
                        m.videoPlayerScreen.contentURL = focusedItem.data.source
                    end if
                    m.itemDetails = m.global.findNode("tvShowItemDetails")
                    selectionData = getActiveEntityDetails()
                    m.itemDetails.itemDetailsData = []
                    tmpData = []
                    tmpData.push(selectionData)
                    m.itemDetails.itemDetailsData = tmpData
                else
                    if subscription = true
                        m.videoPlayerScreen = m.global.findNode("tvShowPlayer")

                        m.videoPlayerScreen.contentURL = focusedItem.data.storage["record"]["trailer"]
                        m.videoPlayerScreen.width = "1280"
                        m.videoPlayerScreen.height = "800"
                    end if
                    m.itemDetails = m.global.findNode("tvShowItemDetails")
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

function getActiveEntityDetails()
    itemFocusedInfo = m.rowList.itemFocused
    if itemFocusedInfo <> invalid
        focusedItemIndex = itemFocusedInfo
        focusedItem = m.rowList.content.getChild(focusedItemIndex)
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
    vodScreen = m.global.findNode("saved_screen")
    vodListRow = m.top.findNode("vodRowList")
    categoryRowList = m.top.findNode("categoryRowList")
    print key
    print press
    print "What Happened in VOD SCREEN"
    if press = false and key = "right"
        if vodScreen.hasFocus()
            ' vodListRow.setFocus(true)
            categoryRowList.setFocus(true)
            ' activateRow()
        end if
    else if key = "back" and press = false
        if m.lastFocusedItem <> invalid
            vodListRow.setFocus(true)
            m.rowList.itemFocused = m.lastFocusedItem
            m.rowList.itemSelected = m.lastFocusedItem
        end if
    else if (press = false or press = true) and key = "back" then
        unFocusActiveVODRowItem()
        m.navBar = m.global.findNode("navigation_bar")
        m.navBar.setFocus(true)
        m.navBar.navHasFocus = true
        deactivateRow()
        m.videoPlayerScreen = m.global.findNode("tvShowPlayer")
        m.videoPlayerScreen.contentURL = ""
        m.vodAnimationInitialized = false
        return true
    else if key = "left" and press = true
        if m.rowList.hasFocus()
            if m.rowList.itemFocused mod 5 = 0 then
                ' Perform actions when the focused item index matches the condition
                unFocusActiveVODRowItem()
                m.navBar = m.global.findNode("navigation_bar")
                m.navBar.setFocus(true)
                m.navBar.navHasFocus = true
                deactivateRow()
                m.videoPlayerScreen = m.global.findNode("tvShowPlayer")
                m.videoPlayerScreen.contentURL = ""
                m.vodAnimationInitialized = false
            end if
        end if
        if categoryRowList.hasFocus()
            if getActiveCategoryRowIndex()[1] = 0
                m.navBar = m.global.findNode("navigation_bar")
                m.navBar.setFocus(true)
                m.navBar.navHasFocus = true
                ' deactivateRow()
                m.videoPlayerScreen = m.global.findNode("tvShowPlayer")
                m.videoPlayerScreen.contentURL = ""
                m.vodAnimationInitialized = false
            end if

        end if
    else if key = "down" and press = true
        if categoryRowList.hasFocus()
            if m.vodAnimationInitialized = false
                activateRow()
                m.vodAnimationInitialized = true
            end if
            vodListRow.setFocus(true)
            return true
        end if
    else if key = "up" and press = true
        if vodListRow.hasFocus() and vodListRow.itemFocused <= 5 then
            deactivateRow()
            m.vodAnimationInitialized = false
            categoryRowList.setFocus(true)
            return true
        end if
    else if key = "OK" and vodListRow.hasFocus()
        m.videoPlayerScreen = m.global.findNode("tvShowPlayer")
        m.videoPlayerScreen.contentURL = ""
        ' detailScreen =
        ' detailScreen = m.global.findNode("detailScene")
        m.lastFocusedItem = m.rowList.itemFocused
        m.isDetailScreenPushed = true

        ' ' selectionData = getActiveVODEntity()
        ' selectionData = getActiveEntityDetails()
        ' ' detailScreen.navigatedFrom = "TVSHOW"
        navigateToPlayVideo()
        ' ' m.lastFocusedItem = m.rowList.rowItemFocused
        ' m.lastFocusedItem = m.rowList.itemFocused
        ' m.isDetailScreenPushed = true
        ' print m.global.detailEntity
        ' m.global.findNode("navigation_bar").visible = false
        ' m.global.findNode("saved_screen").visible = false
    end if
end function


sub navigateToPlayVideo()
    ' m.videoPlayerScreen = m.global.findNode("videoPlayerScreen")
    ' m.DVRVideoPlayerScreen = m.global.findNode("videoDVRScreen")
    m.SeasonScreen = m.global.findNode("SeasonScreen")
    selectionData = getActiveEntityDetails()
    ' m.videoPlayerScreen.contentURL =  m.top.detailScreenData[0].storageRecord["source"]



    progNodeToPlay = CreateObject("roSGNode", "ContentNode")
    progNodeToPlay.url = selectionData.data.sources["primary"]
    progNodeToPlay.title = selectionData.data.title
    progNodeToPlay.description = selectionData.data.description
    progNodeToPlay.hdposterurl = selectionData.data["images"]["thumbnail"]
    progNodeToPlay.addFields({
        isCC: "false",
        isHD: "true",
        channelTitle: "JoyGo"
    })

    m.SeasonScreen.DVRParent = progNodeToPlay
    m.SeasonScreen.arrayDVRs = convertToSimpleArray(selectionData.data.seasons)
    m.SeasonScreen.setFocus(true)
    m.SeasonScreen.visible = true



    ' m.videoPlayerScreen.contentProgram = progNodeToPlay







    ' m.videoPlayerScreen.setFocus(true)
    ' m.videoPlayerScreen.contentProgramData = m.top.detailScreenData

    ' m.global.findNode("detailScene").visible = false
    ' m.videoPlayerScreen.visible = true

    m.global.findNode("navigation_bar").visible = false
    m.global.findNode("saved_screen").visible = false
end sub

function convertToSimpleArray(dvrData as object)
    ' Initialize an empty array to store the simple array values
    simpleArray = []

    ' Iterate over the keys in the roAssociativeArray
    for each key in dvrData
        ' Get the value corresponding to the key (which is an array of DVR data)
        dayDVRs = dvrData[key]

        ' Create an associative array to hold the day's DVRs and the title
        item = {
            dvrTitle: key, ' Add the title corresponding to the key
            data: dayDVRs ' Store the DVR data
        }

        ' Push the object to the simple array
        simpleArray.Push(item)
    end for

    ' Now simpleArray contains the DVR arrays for each day along with their titles
    m.simpleArray = simpleArray
    return m.simpleArray
end function

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


sub updateVodCategoryScreen()
    initializeCategories()

end sub



sub initializeCategories()
    m.contentContainer = m.top.findNode("vodContainer")
    defaultFont = CreateObject("roSGNode", "Font")
    defaultFont.uri = "pkg:/images/UrbanistSemiBold.ttf"
    defaultFont.size = 42

    hvc = CreateObject("roSGNode", "HomeVodContent")

    m.categoryRowList = m.top.findNode("categoryRowList")
    m.categoryRowList.focusable = true
    m.contentContainer.appendChild(m.categoryRowList)
    m.categoryRowList.rowLabelFont = defaultFont

    ' currentFocusedIndex = m.rowList.itemFocused
    ' m.lastFocusedItem = m.categoryRowList.itemFocused

    content = CreateObject("roSGNode", "ContentNode")
    content.title = "Categories"



    if m.top.categoryDataEntity <> invalid
        fetchVodScreenData(m.top.categoryDataEntity[0].id)
        m.firstCategoryInitialization = true
        for each categoryData in m.top.categoryDataEntity
            item = CreateObject("roSGNode", "ContentNode")
            item.title = categoryData.title
            print categoryData.name


            item.addFields({
                rowItemFocus: false,
                data: categoryData,
                isLiveChannel: false,
                focusable: true
                isSelected: false,
            })
            ' m.totalItems = m.totalItems + 1
            content.appendChild(item)
        end for

        hvc.appendChild(content)
        ' m.rowList.itemContent = content
        m.categoryRowList.content = hvc
        m.contentContainer.appendChild(m.categoryRowList)
        m.categoryRowList.observeField("rowItemFocused", "onCategoryItemFocused")

        ' m.categoryRowList.itemFocused = m.lastFocusedItem
        ' m.categoryRowList.jumptoitem = m.lastFocusedItem

    end if

end sub



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
                    fetchVodScreenData(focusedItem.data.id)
                else if focusedItemIndex = 0 and m.firstCategoryInitialization = true
                    m.selectedCategory = focusedItem.data.id
                    fetchVodScreenData(focusedItem.data.id)
                end if

            end if

        end if
    end if
end sub



sub fetchVodScreenData(categoryId as integer)

    m.selectedCategory = categoryId

    print categoryId
    print m.vodDataCache
    print "Here is VOD DATA CACHE"
    if m.vodDataCache.doesExist(categoryId.ToStr()) then
        initializeCachedVodScreenData()
        return
    end if


    showLoadingDialog("Loading, please wait...")

    m.vodScreenData = createObject("roSGNode", "VodScreenData")
    m.vodScreenData.observeField("responseData", "handleResponseData")
    m.vodScreenData.page = m.page
    m.vodScreenData.vodType = 3
    m.vodScreenData.categoryType = categoryId
    m.vodScreenData.control = "RUN"
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
            if vodData.images["thumbnail"] <> invalid
                item.hdPosterUrl = encodeUrl(vodData.images["thumbnail"])
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

function encodeUrl(url as string) as string
    ' Replace spaces with %20
    url = url.Replace(" ", "%20")
    ' Add more replacements if necessary
    ' url = url.Replace("<character>", "<encoded_value>")
    return url
end function

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


