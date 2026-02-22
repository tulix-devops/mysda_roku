sub init()
    m.itemposter = m.top.findNode("poster")
    m.posterOverlay = m.top.findNode("posterOverlay")
    m.posterOverlayGroup = m.top.findNode("posterOverlayGroup")
    m.vodText = m.top.findNode("vodText")
    m.containerGroup = m.top.findNode("containerGroup")
    m.backgroundOverlay = m.top.findNode("backgroundRect")
    m.name = m.top.findNode("name")
end sub

sub OnContentSet() ' invoked when item metadata retrieved
    content = m.top.itemContent
    ' m.top.itemContent
    content.observeField("keyPressed", "onKeyPressed")
    if content <> invalid
        if content.isLiveChannel <> invalid
            if content.isLiveChannel = true
                m.itemposter.width = 320
                m.itemposter.height = 190
                m.itemposter.loadWidth = 320
                m.itemposter.loadHeight = 190
            else 
                m.itemposter.width = 320
                m.itemposter.height = 190
                m.itemposter.loadWidth = 320
                m.itemposter.loadHeight = 190
            end if
        end if

        if content.isDVRItem <> invalid and content.isDVRItem = true
            print content
            print "Here is content we are Looking inside of Live Parent"
            if content.isLiveParent = true then
                ' m.itemposter.width = 420
                ' m.itemposter.height = 320
                ' m.itemposter.loadWidth = 420
                ' m.itemposter.loadHeight = 320
                ' m.backgroundOverlay.width = 420
                ' m.backgroundOverlay.height = 100
                m.itemposter.width = 320
                m.itemposter.height = 190
                m.itemposter.loadWidth = 320
                m.itemposter.loadHeight = 190
                m.vodText.width = 420
                
                m.vodText.text = content.data.title
            else
                m.itemposter.width = 320
                m.itemposter.height = 190
                m.itemposter.loadWidth = 320
                m.itemposter.loadHeight = 190
                ' m.itemposter.width = 420
                ' m.itemposter.height = 320
                ' m.itemposter.loadWidth = 420
                ' m.itemposter.loadHeight = 320
                ' m.backgroundOverlay.width = 420
                ' m.backgroundOverlay.height = 100
                m.vodText.width = 420
                setDVRtitle(content)
            end if 
    
            
        else
            ' m.backgroundOverlay.width = 0
            m.vodText.width = 320

        end if

        ' if content.rowItemFocus = true
        '     m.posterOverlayGroup.opacity = 1
        ' else
        '     m.posterOverlayGroup.opacity = 0
        ' end if
        ' setVodText(content)
        m.top.FindNode("poster").loadDisplayMode = "noscale"
        m.top.FindNode("poster").uri = content.hdPosterUrl
    end if
end sub

' sub setDVRtitle(content)
'     if content.data.start <> invalid and content.data.end <> invalid
'         title = content.data.start + " - " + content.data.end
'         if len(title) > 27
'             title = left(title, 24) + "...."
'         end if
'         m.vodText.text = title
'     else m.vodText.text = ""
'     end if
'     print content.data
'     print "WHAT IS THE NAME OF THIS DATA?"
'     m.name.text = content.data.name
' end sub

sub setDVRtitle(content)
    if content = invalid or content.data = invalid
        m.vodText.text = ""
        return
    end if

    if content.data.start <> invalid and content.data.end <> invalid
        title = content.data.start + " - " + content.data.end
        m.vodText.text = truncateText(title, 27)
    else
        m.vodText.text = ""
    end if

    if content.data.name <> invalid
        m.name.text = content.data.name
    else
        m.name.text = ""
    end if
end sub


' sub setVodText(content)
'     if content.data.title <> invalid
'         title = content.data.title
'         if len(title) > 27
'             title = left(title, 24) + "...."
'         end if
'         m.vodText.text = title
'     else m.vodText.text = ""
'     end if

'     if content.isLiveChannel <> invalid
'         if content.isLiveChannel = true
'             translationCoordinates = [0, 320]
'             m.containerGroup.translation = translationCoordinates
'         else
'             translationCoordinates = [0, 300]
'             m.containerGroup.translation = translationCoordinates
'         end if
'     end if
' end sub
sub setVodText(content)
    if content = invalid or content.data = invalid
        m.vodText.text = ""
        return
    end if

    if content.data.title <> invalid
        m.vodText.text = truncateText(content.data.title, 27)
    else
        m.vodText.text = ""
    end if

    ' Optional: adjust text positioning based on content type
    if content.isLiveChannel <> invalid and content.isLiveChannel = true
        m.containerGroup.translation = [0, 300]
    else
        m.containerGroup.translation = [0, 300]
    end if
end sub


function truncateText(text as String, maxLength as Integer) as String
    if text <> invalid and len(text) > maxLength
        return left(text, maxLength - 4) + "...."
    else
        return text
    end if
end function



