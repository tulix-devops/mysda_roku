' =============================================================================
' init - Called when the DVRsListingScreen component is initialized
' =============================================================================

sub init()

    ' Get the Roku device model that the application is running on
    print "SeasonScreen.brs - [init] Called "
    deviceInfo = CreateObject("roDeviceInfo")
    deviceModel = deviceInfo.getModel()


    ' Set the height of the colored part of the overhang depending upon the device
    if deviceModel = "4200X" then
        overhangHeight = 140
    else
        overhangHeight = 150
    end if

    ' Add device specific data to global variables
    m.global.addFields({ deviceModel: deviceModel, overhangHeight: overhangHeight })

    print "DVRsListingScreen.brs - [init] " m.global.deviceModel " (overhangHeight =" m.global.overhangHeight ")"

    ' Get references to child nodes
    ' m.FadingBackground = m.top.findNode("FadingBackground")
    ' m.RowList = m.top.findNode("RowList")


    ' The spinning wheel node
    m.labelCategory = m.top.findNode("dvrChannelNameLabel")

    ' Observer for when the screen becomes visible (for instance, when returning from the DetailsScreen)
    m.top.observeField("visible", "onVisibleChange")

    ' Set focus to RowList if returning from DetailsScreen
    m.top.observeField("focusedChild", "onFocusedChildChange")

    m.showImg = m.top.findNode("showImg")
    m.programTitle = m.top.findNode("programTitle")
    m.programTitle.font.size = 60
    m.programInfo = m.top.findNode("programInfo")
    m.programInfo.font.size = 50



    m.DVRDataCache = {}

    m.selectedDVRTime = ""


    ' m.arrayDVRs = m.top.findNode("arrayDVRs")


end sub


' =============================================================================
' loadNewChannelDVRsContentListing
' =============================================================================

' sub loadNewChannelDVRsContentListing()

'   print "DVRsListingScreen.brs - [loadNewChannelDVRsContentListing] Called "

'   m.LoadingIndicator.control = "start"

'   m.labelCategory.text = m.top.toLoadDVRsListing.title
'   print "---------***********---------*********"
'   print m.top.toLoadDVRsListing

'   m.top.content = invalid

'   print "DVRsListingScreen.brs - [init] Making Request for  " m.top.toLoadDVRsListing.title

'   m.readerTask = createObject("roSGNode","fetchDVRs")
'   m.readerTask.observeField("status","onStatus")
'   m.readerTask.observeField("channelDVRs","onDVRsLoaded")
'   m.readerTask.setField("uri", m.top.toLoadDVRsListing.uri)
'   m.readerTask.control = "RUN"


'   print "DVRsListingScreen.brs - [loadNewVODContentListing] Exiting"

' end sub



sub onDVRsLoaded()

    print "===================================================================================="
    print "DVRsListingScreen.brs - [onDVRsLoaded] Called"

    m.top.contentShowRowLabel = [false]
    m.top.contentShowRowCounter = [false]

    if m.top.arrayDVRs <> invalid then
        ' m.top.content = createDVRRowItem(m.top.arrayDVRs, "Categories")
        initializeCategories(m.top.arrayDVRs)
        ' initializeCategoryItems()
    end if

    ' m.top.content = createDVRRowItem(m.readerTask.channelDVRs, m.labelCategory.text)


    ' m.LoadingIndicator.control = "stop"
    print "DVRsListingScreen.brs - [onDVRsLoaded] Exiting"

end sub





' =============================================================================
' onItemFocused - Handler for focused item in RowList
' =============================================================================

sub onItemFocused()

    print "DVRsListingScreen.brs - [onItemFocused]"

    itemFocusedIndexes = m.top.itemFocused

    ' When an item gains the focus, set to a 2-element array,
    ' where element 0 contains the index of the focused row,
    ' and element 1 contains the index of the focused item
    ' in that row.

    print "---------***********---------*********"
    print m.top





    if itemFocusedIndexes.Count() = 2 then

        focusedContent = m.top.content.getChild(itemFocusedIndexes[0]).getChild(itemFocusedIndexes[1])

        ' focusedContent is assigned to an interface field so that HeroScene can provide
        ' content data to DetailsScreen when a RowList item is focused. Also, a fullscreen
        ' (blurred) image for the selected item is assigned the the screen's background.

        if focusedContent <> invalid then
            m.top.focusedContent = focusedContent
            '   m.FadingBackground.uri = focusedContent.thumbnail
            '   m.FadingBackground.background = "pkg:/images/background.png"


            m.showImg.uri = focusedContent.thumbnail


            print " =0=0=0=0==00=0=0=0=0=0==00=0=0=0=0=0==00=0=0=0=0=0==00=0\n"
            print "focusedContent\n"
            print focusedContent

            m.programTitle.text = focusedContent.title
            m.programInfo.text = focusedContent.pubdate
        end if

    end if

end sub

' =============================================================================
' onVisibleChange - Sets focus to RowList in case channel returns from DetailsScreen
' =============================================================================

sub onVisibleChange()

    print "DVRsListingScreen.brs - [onVisibleChange] and m.top.visible " m.top.visible

    if m.top.visible then
        print "DVRsListingScreen.brs - [onVisibleChange] Setting Focus on Row"
        m.rowList.setFocus(true)
    end if


end sub

' =============================================================================
' onFocusedChildChange - Set focus to RowList in case of return from DetailsScreen
'                        or the LoadingIndicator is removed, etc.
' =============================================================================

sub onFocusedChildChange()
    print "DVRsListingScreen.brs - [onFocusedChildChange]"
    if m.top.isInFocusChain() and not m.rowList.hasFocus() then m.rowList.setFocus(true)


end sub


' =============================================================================
' createDVRRowItem - Create a row of DVRs
' =============================================================================

function createDVRRowItem(dvrItemsArray as object, title as string)

    'print "DVRsListingScreen.brs - [createDVRRowItem] title = " title
    'print "DVRsListingScreen.brs - [createDVRRowItem] channelItemsArray = " channelItemsArray

    rowParentNode = createObject("RoSGNode", "ContentNode")
    totalDVRs = dvrItemsArray.count() - 1


    print dvrItemsArray
    print "Here is DVR ITEMS YAY"

    for firstItemInRow = 0 to totalDVRs step 4

        ' Create the row node
        ' Add the row items to the row
        row = createObject("RoSGNode", "ContentNode")

        for item = firstItemInRow to firstItemInRow + 3
            if dvrItemsArray[item] <> invalid then
                rowItem = createObject("RoSGNode", "ContentNode")
                ' dvrItemsArray[item].favorite  = m.top.toLoadDVRsListing.favorite
                ' dvrItemsArray[item].channelid = m.top.toLoadDVRsListing.channelid
                ' dvrItemsArray[item].iskeylive = m.top.toLoadDVRsListing.iskeylive
                ' dvrItemsArray[item].iskeydvr  = m.top.toLoadDVRsListing.iskeydvr
                addAndSetFields(rowItem, dvrItemsArray[item][0])
                row.appendChild(rowItem)
            end if
        end for

        ' Add the row to the parent node
        rowParentNode.appendChild(row)

    end for

    return rowParentNode

end function

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
                focusedItem.rowItemFocus = true
                print focusedItem
                print "CATEGORY FOCUSED ITEM"
                focusedItem.isSelected = true
                if focusedItemIndex <> 0 then
                    m.selectedDVRTime = focusedItem.catId
                    print focusedItem
                    print "what is dvr Title itself Tho"
                    initializeCategoryItems()

                else if focusedItemIndex = 0 and m.firstCategoryInitialization = true
                    m.selectedDVRTime = focusedItem.catId
                    initializeCategoryItems()
                end if

            end if

        end if
    end if
end sub


sub initializeCategories(categories as object)
    m.contentContainer = m.top.findNode("tvShowContainer")
    defaultFont = CreateObject("roSGNode", "Font")
    defaultFont.uri = "pkg:/images/UrbanistSemiBold.ttf"
    defaultFont.size = 42

    hvc = CreateObject("roSGNode", "HomeVodContent")

    m.categoryRowList = m.top.findNode("tvShowSeasonList")
    m.categoryRowList.focusable = true
    m.contentContainer.appendChild(m.categoryRowList)
    m.categoryRowList.rowLabelFont = defaultFont

    ' currentFocusedIndex = m.rowList.itemFocused
    ' m.lastFocusedItem = m.categoryRowList.itemFocused

    content = CreateObject("roSGNode", "ContentNode")
    if m.top.DVRParent <> invalid
        content.title = m.top.DVRParent.title
    else
        content.title = ""

    end if

    if categories <> invalid
        print categories[0]
        print "What do we get for Seasons"
        m.firstCategoryInitialization = true
        m.selectedDVRTime = categories[0].dvrtitle
        print m.selectedDVRTime
        print "here is Seleceted DVR Item"
        for each categoryData in categories
            print categoryData.dvrtitle
            print "Lets see Season Title"
            item = CreateObject("roSGNode", "ContentNode")
            item.title = categoryData
            print categoryData.data
            print "whats up with CategoryData"
            m.DVRDataCache[categoryData.dvrtitle] = categoryData.data
            print categoryData.dvrtitle
            print "whats up with DVR title Tho"
            item.addFields({
                rowItemFocus: false,
                data: categoryData,
                categoryName: "Season" + " " + categoryData.dvrtitle,
                catId: categoryData.dvrtitle,
                isDVR: true,
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

    initializeCategoryItems()

end sub


sub initializeCategoryItems()
    m.contentContainer = m.top.findNode("tvShowContainer")
    defaultFont = CreateObject("roSGNode", "Font")
    defaultFont.uri = "pkg:/images/UrbanistSemiBold.ttf"
    defaultFont.size = 42

    if m.rowList = invalid
        m.rowList = m.top.findNode("episodeRowList")
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

    if m.DVRDataCache[m.selectedDVRTime.ToStr()] <> invalid
        keys = []
        for each key in m.DVRDataCache[m.selectedDVRTime.ToStr()]
            keys.push(parseJson(key))
        end for
        
        ' Sort keys numerically
        keys.sort() ' Ascending order
        
        ' Iterate over sorted keys
        for each key in keys
            stringKey = key.ToStr() ' Convert back to string if needed for lookup
            dvrData = m.DVRDataCache[m.selectedDVRTime.ToStr()][stringKey]
            
            if dvrData <> invalid
                item = CreateObject("roSGNode", "ContentNode")
                item.title = ""
                item.hdPosterUrl = ""
        
                ' Check for valid thumbnail
                if dvrData.images <> invalid
                    if dvrData.images.thumbnail <> invalid
                        item.hdPosterUrl = encodeUrl(dvrData.images.thumbnail)
                    else
                        item.hdPosterUrl = "pkg:/images/png/no-poster-found.png"
                    end if
                else
                    item.hdPosterUrl = "pkg:/images/png/no-poster-found.png"
                end if
        
                ' Add other fields to the item
                item.addFields({
                    rowItemFocus: false,
                    data: dvrData,
                    isDVRItem: false,
                    isLiveChannel: false,
                    focusable: true
                })
        
                ' Append the item to the content node
                content.appendChild(item)
            end if
        end for


        ' m.rowList.itemContent = content
        m.rowList.content = content
        m.rowList.itemFocused = m.lastFocusedItem
        m.rowList.jumptoitem = m.lastFocusedItem

        m.contentContainer.appendChild(m.rowList)
    end if


end sub

function encodeUrl(url as string) as string
    ' Replace spaces with %20
    url = url.Replace(" ", "%20")
    ' Add more replacements if necessary
    ' url = url.Replace("<character>", "<encoded_value>")
    return url
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




function addAndSetFields(node as object, associativeArray as object)

    'This gets called for every content node -- commented out since it's pretty verbose
    'print "SGHelperFunctions.brs - [AddAndSetFields]"
    'print "addAndSetFields.brs - [node]" node
    'print "addAndSetFields.brs - [node]" associativeArray

    fieldsToAdd = {}
    fieldsToSet = {}

    for each field in associativeArray

        if node.hasField(field)
            fieldsToSet[field] = associativeArray[field]
        else
            fieldsToAdd[field] = associativeArray[field]
        end if

    end for

    'print "addAndSetFields.brs - [fieldsToSet]" fieldsToSet
    'print "addAndSetFields.brs - [fieldsToAdd]" fieldsToAdd

    node.setFields(fieldsToSet)
    node.addFields(fieldsToAdd)
    'print "addAndSetFields.brs - [node]" node

end function





function onKeyEvent(key as string, press as boolean) as boolean
    vodScreen = m.global.findNode("live_screen")
    vodListRow = m.top.findNode("episodeRowList")
    categoryRowList = m.top.findNode("tvShowSeasonList")
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
        ' unFocusActiveVODRowItem()
        m.navBar = m.global.findNode("navigation_bar")
        m.navBar.visible = true
        ' deactivateRow()
        m.global.findNode("saved_screen").visible = true
        m.global.findNode("saved_screen").setFocus(true)
        m.top.visible = false
        return true
    else if key = "left" and press = true


    else if key = "down" and press = true
        if categoryRowList.hasFocus()
            vodListRow.setFocus(true)
            return true
        end if
    else if key = "up" and press = true
        if vodListRow.hasFocus() and vodListRow.itemFocused <= 4 then
            categoryRowList.setFocus(true)
            return true
        end if
    else if key = "OK" and press = true
        if vodListRow.hasFocus() then
            navigateToPlayVideo()
            m.lastFocusedItem = m.rowList.itemFocused
            m.isDetailScreenPushed = true
        end if

    end if
end function




sub navigateToPlayVideo()
    ' m.videoPlayerScreen = m.global.findNode("videoPlayerScreen")
    m.DVRVideoPlayerScreen = m.global.findNode("videoDVRScreen")
    selectionData = getActiveEntityDetails()
    ' m.videoPlayerScreen.contentURL =  m.top.detailScreenData[0].storageRecord["source"]
    ' m.videoPlayerScreen.contentProgram = selectionData.data.sources["primary"]
    ' m.videoPlayerScreen.isLive = "true"

    progNodeToPlay = CreateObject("roSGNode", "ContentNode")
    progNodeToPlay.url = encodeUrl(selectionData.data.sources.primary)
    progNodeToPlay.title = m.top.DVRParent.title + " - Season " + m.selectedDVRTime + " Episode " + str(selectionData.data.episode)
    progNodeToPlay.description = selectionData.data.description
    progNodeToPlay.hdposterurl = encodeUrl(selectionData.data.images.thumbnail)
    ' progNodeToPlay.playStart = "00"duration
    ' progNodeToPlay.playDuration = selectionData.data.duration
    progNodeToPlay.addFields({
        isCC: "false",
        isHD: "true",
        channelTitle: "JoyGo"
    })

    m.DVRVideoPlayerScreen.navigatedFrom = "Seasons"
    m.DVRVideoPlayerScreen.content = progNodeToPlay
    m.DVRVideoPlayerScreen.setFocus(true)
    m.DVRVideoPlayerScreen.visible = true

    m.top.visible = false
end sub



