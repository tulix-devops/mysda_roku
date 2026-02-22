sub init()
    print "🔍 DVROverlayScreen.brs - [init()] CALLED"
    m.sidebar = m.top.findNode("dvrSidebar")
    m.episodes = m.top.findNode("dvrEpisodes")
    m.top.observeField("visible", "onVisibilityChanged")
    setTimeTitle()
end sub


sub setTimeTitle()
        now = CreateObject("roDateTime")
        now.Mark()
        now.ToLocalTime()
        
        m.timeTitle = m.top.findNode("timeTitle")
        m.timeTitle.text = now.asTimeStringLoc("short")
end sub


sub onContentLoaded()
    print "🔍 DVROverlayScreen.brs - [onContentLoaded] CALLED"
    print "🔍 DEBUG: m.top.content type = "; type(m.top.content)
    print "🔍 DEBUG: m.top.content count = "; m.top.content.count()
    print "🔍 DEBUG: m.top.content[0] = "; m.top.content[0]

    m.sidebar = m.top.findNode("dvrSidebar")
    m.episodes = m.top.findNode("dvrEpisodes")

    sidebarNode = createObject("roSGNode", "ContentNode")
    m.sidebarData = []


    

    ' Bubble sort or insertion sort (BrightScript doesn't support array.sort)


    dvrArray = m.top.content
    if dvrArray <> invalid and dvrArray.count() > 0
        ' sortedArray = sortDvrArrayByDateDescending(dvrArray)
        ' for each category in dvrArray
        sortedArray = dvrArray

        for i = 0 to sortedArray.count() - 2
            for j = i + 1 to sortedArray.count() - 1
                itemA = sortedArray[i]
                itemB = sortedArray[j]
        
                if type(itemA) = "roAssociativeArray" and type(itemB) = "roAssociativeArray"
                    if itemA.doesExist("title") and itemB.doesExist("title")
                        dateA = parseDateFromTitle(itemA.title)
                        dateB = parseDateFromTitle(itemB.title)
        
                        if dateA <> invalid and dateB <> invalid
                            if dateA.asSeconds() < dateB.asSeconds() then
                                temp = sortedArray[i]
                                sortedArray[i] = sortedArray[j]
                                sortedArray[j] = temp
                            end if
                        end if
                    end if
                end if
            end for
        end for

        ' First, add all sorted DVR items
        for i = 0 to sortedArray.count() - 1
            category = sortedArray[i]  ' ✅ Fixed: Use sortedArray instead of dvrArray

            if type(category) = "roAssociativeArray"
              
                ' Get title field
                rawTitle = ""
                if category.doesExist("title") and category.title <> invalid
                    rawTitle = category.title
                else
                    print "⚠️ Warning: Category has no title field"; category
                end if
                
                ' Convert date format from "Month Day Year" to "Day-Month-Year"
                if rawTitle <> "" and type(rawTitle) = "roString"
                    formattedTitle = formatDateTitle(rawTitle)
                else
                    formattedTitle = "Unknown Date"
                end if
              
                sidebarItem = {
                    title: formattedTitle,
                    episodes: category.episodes
                }
                m.sidebarData.push(sidebarItem)

                nodeItem = createObject("roSGNode", "ContentNode")
                nodeItem.title = formattedTitle
                nodeItem.addFields({
                    data: category.episodes ' ✅ Store episodes here for later
                })
                sidebarNode.appendChild(nodeItem)
            else
                print "❌ Skipping invalid category item: "; category
            end if
        end for
        
        ' Insert "Live" item at position 1 (after first DVR date)
        pContent = m.top.parentContent
        if pContent <> invalid and sidebarNode.getChildCount() > 0
            parentLiveItem = {
                title: "LIVE" + " " + pContent.title
                episodes: pContent
            }
            
            ' Insert at position 1 in m.sidebarData
            if m.sidebarData.count() > 0
                tempArray = []
                tempArray.push(m.sidebarData[0])  ' First item (index 0)
                tempArray.push(parentLiveItem)    ' Live item at position 1
                for j = 1 to m.sidebarData.count() - 1
                    tempArray.push(m.sidebarData[j])
                end for
                m.sidebarData = tempArray
            end if
            
            ' Insert in ContentNode at position 1
            liveNodeItem = createObject("roSGNode", "ContentNode")
            liveNodeItem.title = "Live"
            liveNodeItem.addFields({
                data: pContent
            })
            
            ' Insert the Live node at position 1
            sidebarNode.insertChild(liveNodeItem, 1)
        end if
    
        ' parentLiveItem = {
        '     title: "LIVE" + " " + m.top.parentContent.title
        '     episodes: m.top.parentContent
        ' }
        ' m.sidebarData.push(parentLiveItem)
        ' nodeItem = createObject("roSGNode", "ContentNode")
        ' nodeItem.title = "Live"
        ' nodeItem.addFields({
        '     data: m.top.parentContent
        ' })
        ' sidebarNode.appendChild(nodeItem)
        

        m.sidebar.content = sidebarNode
        ' m.sidebar.observeField("itemFocused", "onSideBarItemFocused")

        loadEpisodesForIndex(0)
        m.sidebar.observeField("itemFocused", "onSideBarItemFocused")
        m.sidebar.observeField("itemSelected", "onSideBarItemSelected")

        m.sidebar.setFocus(true)
    end if
end sub

' =============================================================================
' Extracts sidebar content from passed DVR ContentNode
' =============================================================================
function extractSidebarContent(dvrRootNode as object) as object
    print dvrRootNode
    print "Here is DVRRootNode"
    resultNode = createObject("roSGNode", "ContentNode")
    for i = 0 to dvrRootNode.getChildCount() - 1
        categoryNode = dvrRootNode.getChild(i)
        item = createObject("roSGNode", "ContentNode")
        item.title = categoryNode.categoryName
        item.addFields({
            index: i,
            data: categoryNode.data,
            isLiveParent: categoryNode.isLiveParent
        })
        resultNode.appendChild(item)
    end for
    return resultNode
end function

' =============================================================================
' Called when a sidebar category is selected
' =============================================================================


' =============================================================================
' Load episodes from sidebar content selection
' =============================================================================
sub loadEpisodesForIndex(index as integer)
    print "---- Loading Episodes for Sidebar Index: " + index.toStr()

    ' contentNode = m.episodes.content

   

    resultNode = createObject("roSGNode", "ContentNode")

    ' Safety: Ensure sidebar and content exist
    if m.sidebar = invalid or m.sidebar.content = invalid or index >= m.sidebar.content.getChildCount()
        print "⚠️ Sidebar content is missing or index out of bounds"
        return
    end if

    categoryItem = m.sidebar.content.getChild(index)
    print categoryItem

    print "Here is Live category Item"

    m.episodeTitle = m.top.findNode("episodeTitle")
    m.episodeTitle.text = categoryItem.title + ": " + "on mySDAtv channel"
    print categoryItem.title + ": " + "on mySDAtv channel"

    if categoryItem = invalid
        print "⚠️ No categoryItem found at index"
        return
    end if

    print ">>> categoryItem full dump:"
    print categoryItem.getFields()
    episodeArray = categoryItem.data
    print "▶️ TYPE OF categoryItem.data = " + type(episodeArray)

    ' Normalize if it's a single AA (not an array)
    if type(episodeArray) = "roAssociativeArray" or type(episodeArray) = "roSGNode"
        print "ℹ️ Normalizing single AA to array"
        episodeArray = [episodeArray]
    end if

    ' Proceed if it's a valid array
    if type(episodeArray) = "roArray"
        for each episodeAA in episodeArray
            if type(episodeAA) = "roAssociativeArray" or type(episodeAA) = "roSGNode"
                episodeNode = createObject("roSGNode", "ContentNode")
                episodeNode.setFields(episodeAA)
    
                print "🔍 Episode Data Check:"
                print "   Type of episodeAA: "; type(episodeAA)
                if type(episodeAA) = "roSGNode"
                    print "   SGNode fields: "
                    fields = episodeAA.getFields()
                    for each key in fields
                        print "      - "; key; ": "; fields[key]
                    end for
                end if
                
                ' Check if this is a DVR recording or Live parent
                ' DVR recordings have a "link" field, Live parent has "url" field
                isDvrRecording = false
                
                ' Check for link (DVR) or url (Live) field in both AA and SGNode
                if type(episodeAA) = "roAssociativeArray" or type(episodeAA) = "roSGNode"
                    hasLink = false
                    hasUrl = false
                    
                    if type(episodeAA) = "roAssociativeArray"
                        hasLink = (episodeAA.link <> invalid and episodeAA.link <> "")
                        hasUrl = (episodeAA.url <> invalid and episodeAA.url <> "")
                    else if type(episodeAA) = "roSGNode"
                        linkField = episodeAA.getField("link")
                        urlField = episodeAA.getField("url")
                        hasLink = (linkField <> invalid and linkField <> "")
                        hasUrl = (urlField <> invalid and urlField <> "")
                    end if
                    
                    if hasLink
                        isDvrRecording = true
                        print "   ✅ Detected DVR recording (has 'link' field)"
                    else if hasUrl
                        isDvrRecording = false
                        print "   ✅ Detected Live parent (has 'url' field)"
                    end if
                end if
                
                if isDvrRecording
                    ' This is a DVR recording - store the episode data itself
                    episodeNode.addFields({ 
                        data: episodeAA,
                        isParentContent: false
                    })
                    print "   → Set as DVR recording (isParentContent: false)"
                else
                    ' This is the Live parent content
                    episodeNode.addFields({
                        data: episodeAA,
                        isParentContent: true
                    })
                    print "   → Set as Live parent (isParentContent: true)"
                end if
    
                resultNode.appendChild(episodeNode)
            else
                print "⚠️ Skipping episode entry, not a valid AA: "; episodeAA
            end if
        end for
    else
        print episodeArray
        print "❌ categoryItem.data is not a valid array"
    end if
    ' Apply the episode list to the right-side MarkupGrid
    m.episodes.content = resultNode
    m.episodes.jumpToItem = 0
    m.episodes.observeField("itemFocused", "onEpisodeItemFocused")
    m.episodes.observeField("itemSelected", "onEpisodeItemSelected")
    
    print "✓ Loaded " + resultNode.getChildCount().ToStr() + " episodes into 3x3 grid"
    
end sub


sub setEpisodetitle()
 
end sub

sub onSideBarItemFocused()
    ' print "Are we getting Here?"
    selectedIndex = m.sidebar.itemFocused
    print selectedIndex
    print "onSideBarItemFocused SelectedIndex"
    loadEpisodesForIndex(selectedIndex)
end sub

sub onSideBarItemSelected()
    m.episodes.setFocus(true)
end sub

sub onEpisodeItemFocused()
    ' Track focused episode item in the grid
    focusedIndex = m.episodes.itemFocused
    print "Episode item focused: " + focusedIndex.ToStr()
end sub

sub onEpisodeItemSelected()
    selectedIndex = m.episodes.itemSelected
    selectedItem = m.episodes.content.getChild(selectedIndex)

    if selectedItem <> invalid
        episodeData = selectedItem.getFields()

        ' 🔔 Send a signal to parent screen
        print selectedItem
        print "Hello SelectedItem?"
        print m.top.parentContent
        print "PARENT CONTENT HERE WE ARE"

        progNodeToPlay = CreateObject("roSGNode", "ContentNode")

        if selectedItem.isParentContent
            ' This is the live channel
            progNodeToPlay.url = m.top.parentContent.url
            progNodeToPlay.title = selectedItem.title
            progNodeToPlay.description = selectedItem.description
            progNodeToPlay.hdposterurl = selectedItem.hdposterurl
            progNodeToPlay.addFields({
                isCC: "false",
                isHD: "false",
                channelTitle: "MySdaTV",
                isdvr: "0"
            })
        else
            ' This is a DVR recording
            progNodeToPlay.url = selectedItem.data.link
            progNodeToPlay.title = m.top.parentContent.title + " DVR " + selectedItem.data.start + " - " + selectedItem.data.end
            progNodeToPlay.description = selectedItem.data.description
            progNodeToPlay.hdposterurl = selectedItem.data.thumbnail
            progNodeToPlay.addFields({
                isCC: "false",
                isHD: "false",
                channelTitle: "MySdaTV",
                isdvr: "1",
                id: selectedItem.data.id.ToStr()
            })
        end if

        print "========================================"
        print "📺 Playing DVR Item:"
        print "   URL: "; progNodeToPlay.url
        print "   Title: "; progNodeToPlay.title
        print "   isDVR: "; progNodeToPlay.isdvr
        print "   ID: "; progNodeToPlay.id
        print "========================================"
        
        m.top.requestOverlayClose = true
        m.top.selectedDvrItem = progNodeToPlay
    end if
end sub


sub onParentContentChanged()
    print m.top.parentContent
    print "Here is ParentContent"
    m.parentTitle = m.top.findNode("parentTitle")
    m.parentTitle.text = "mySDAtv" + "  •  " +  m.top.parentContent.title +  "  •  " + "channel DVR"
end sub



sub onKeyEvent(key as String, press as Boolean) as Boolean
    if press = false 
        return true
    end if
    if press then
        if key = "left" then
            if m.episodes.hasFocus() then
                ' Check if we're on the leftmost column (column 0)
                focusedIndex = m.episodes.itemFocused
                column = focusedIndex mod 3  ' 3 columns in the grid
                
                if column = 0 then
                    ' On leftmost column, go back to sidebar
                    m.sidebar.setFocus(true)
                    return true
                else
                    ' Let the grid handle left navigation internally
                    return false
                end if
            end if
            print "👈 Left key pressed"
          
            return true
        else if key ="back" then
            if m.episodes.hasFocus() then
                m.sidebar.setFocus(true)
                return true
            else if m.sidebar.hasFocus() then
                    m.top.requestOverlayClose = true
                ' playerScreen = m.top.findNode("VideoDVRScreen") 
                ' if playerScreen <> invalid
                '     m.top.visible = false
                '     playerScreen.setFocus(true)
                '     return true
                ' end if
                return true
            end if
        else if key ="up" or key ="down" or key ="right" then
            ' Let the grid handle up/down/right navigation
            return false
        end if
    end if
    return false
end sub

sub onVisibilityChanged()
    if m.top.visible = true
        m.top.requestOverlayClose = false
        sidebar = m.top.findNode("dvrSidebar")
        if sidebar <> invalid
            sidebar.setFocus(true)
        end if
    else
    end if
end sub




' Convert date format to "Weekday, Mon DD" (e.g., "Friday, Oct 17")
' Supports: "Month Day Year" (e.g., "January 15 2025") -> "Wednesday, Jan 15"
'           "YYYY-MM-DD" (e.g., "2025-10-13") -> "Monday, Oct 13"
function formatDateTitle(title as String) as String
    ' Use the existing parser to get a DateTime object
    dateObj = parseDateFromTitle(title)
    
    if dateObj = invalid
        ' If we couldn't parse it, return the original title
        return title
    end if
    
    ' Get weekday name
    weekdays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    weekdayIndex = dateObj.GetDayOfWeek()
    weekdayName = weekdays[weekdayIndex]
    
    ' Get abbreviated month name
    monthsAbbrev = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    monthIndex = dateObj.GetMonth() - 1  ' GetMonth() returns 1-12, array is 0-indexed
    monthName = monthsAbbrev[monthIndex]
    
    ' Get day of month
    day = dateObj.GetDayOfMonth().ToStr()
    
    ' Format as "Weekday, Mon DD"
    return weekdayName + ", " + monthName + " " + day
end function


function parseDateFromTitle(title as String) as Object
    months = {
        "January": 1, "February": 2, "March": 3, "April": 4,
        "May": 5, "June": 6, "July": 7, "August": 8,
        "September": 9, "October": 10, "November": 11, "December": 12
    }

    ' Check if it's "YYYY-MM-DD" format first (length 10 with 2 dashes)
    if title.len() = 10
        parts = title.split("-")
        if parts.count() = 3 and parts[0].len() = 4 and parts[1].len() = 2 and parts[2].len() = 2
            year = val(parts[0])
            month = val(parts[1])
            day = val(parts[2])
            return parseDateFromMonthDayYear(month, day, year)
        end if
    end if

    ' Try "Month Day Year" format
    parts = title.split(" ")
    if parts.count() = 3 and months.doesExist(parts[0])
        month = months[parts[0]]
        day = val(parts[1])
        year = val(parts[2])
        return parseDateFromMonthDayYear(month, day, year)
    ' Fall back to "Month Day" format (assumes current year)
    else if parts.count() = 2 and months.doesExist(parts[0])
        month = months[parts[0]]
        day = val(parts[1])
        year = CreateObject("roDateTime").GetYear()
        return parseDateFromMonthDayYear(month, day, year)
    end if

    return invalid
end function


function parseDateFromMonthDayYear(month as Integer, day as Integer, year as Integer) as Object
    dateStr = str(year) + "-" + zeroPad(month) + "-" + zeroPad(day) + "T00:00:00Z"

    dateObj = CreateObject("roDateTime")
    dateObj.FromISO8601String(dateStr)

    return dateObj
end function


function zeroPad(value as Integer) as String
    if value < 10
        return "0" + str(value)
    else
        return str(value)
    end if
end function





