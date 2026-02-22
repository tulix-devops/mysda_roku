sub init()
    m.top.observeField("focused", "onFocused")
    m.thumb = m.top.findNode("thumb")
    m.title = m.top.findNode("title")
    m.meta = m.top.findNode("meta")
  end sub
  
  sub updateContent()
    content = m.top.itemContent
    print "=========================================="
    print "DVREpisodeItem.brs - [updateContent] CALLED"
    print "=========================================="
    print "📦 Content Type: "; type(content)
    
    if content <> invalid
      print "📋 All Content Fields:"
      print content.getFields()
      print ""
      
      print "🔍 Individual Field Values:"
      print "  - title: '"; content.title; "' (type: "; type(content.title); ")"
      print "  - description: '"; content.description; "' (type: "; type(content.description); ")"
      print "  - hdposterurl: '"; content.hdposterurl; "' (type: "; type(content.hdposterurl); ")"
      print "  - url: '"; content.url; "' (type: "; type(content.url); ")"
      print "  - data: "; content.data; " (type: "; type(content.data); ")"
      print "  - isParentContent: "; content.isParentContent; " (type: "; type(content.isParentContent); ")"
      
      if content.data <> invalid and type(content.data) = "roSGNode"
          print "  📊 Content.data is SGNode with fields:"
          dataFields = content.data.getFields()
          for each key in dataFields
              print "     - "; key; ": '"; dataFields[key]; "'"
          end for
      end if
      print ""
      
      ' Set poster - check multiple sources
      posterUrl = ""
      if content.hdposterurl <> invalid and content.hdposterurl <> ""
        posterUrl = content.hdposterurl
        print "✓ Poster from content.hdposterurl: "; posterUrl
      else if content.data <> invalid
        if type(content.data) = "roSGNode" and content.data.hdposterurl <> invalid and content.data.hdposterurl <> ""
          posterUrl = content.data.hdposterurl
          print "✓ Poster from content.data.hdposterurl (SGNode): "; posterUrl
        else if type(content.data) = "roAssociativeArray" and content.data.hdposterurl <> invalid and content.data.hdposterurl <> ""
          posterUrl = content.data.hdposterurl
          print "✓ Poster from content.data.hdposterurl (AA): "; posterUrl
        else if type(content.data) = "roAssociativeArray" and content.data.thumbnail <> invalid and content.data.thumbnail <> ""
          posterUrl = content.data.thumbnail
          print "✓ Poster from content.data.thumbnail: "; posterUrl
        end if
      end if
      
      if posterUrl <> ""
        m.thumb.uri = posterUrl
      else
        m.thumb.uri = ""
        print "⚠️ No poster URL found in any location"
      end if
  
      ' Set title - check multiple sources
      titleText = ""
      if content.title <> invalid and content.title <> ""
        titleText = content.title
        print "✓ Title from content.title: "; content.title
      else if content.description <> invalid and content.description <> ""
        titleText = content.description
        print "✓ Title from content.description: "; content.description
      else if content.data <> invalid
        ' Check if data has a name field (for DVR recordings)
        if type(content.data) = "roAssociativeArray" and content.data.name <> invalid and content.data.name <> ""
          ' Extract program name from data.name (remove time portion after "•")
          fullName = content.data.name
          if fullName.Instr("•") > -1
            ' Split at "•" and take the first part (program name only)
            titleText = fullName.Left(fullName.Instr("•")).Trim()
            print "✓ Title extracted from data.name (AA): "; titleText
          else
            ' No bullet separator, use full name
            titleText = fullName
            print "✓ Title from full data.name (AA): "; titleText
          end if
        ' Check if data is SGNode with title field (for Live parent)
        else if type(content.data) = "roSGNode"
          if content.data.title <> invalid and content.data.title <> ""
            titleText = content.data.title
            print "✓ Title from content.data.title (SGNode): "; titleText
          else if content.data.description <> invalid and content.data.description <> ""
            titleText = content.data.description
            print "✓ Title from content.data.description (SGNode): "; titleText
          end if
        end if
      end if
      
      if titleText = ""
        print "⚠️ No title found in any location"
      end if
      
      m.title.text = titleText
      print "🏷️ FINAL TITLE SET: '"; titleText; "' (length: "; titleText.Len(); ")"
      print "🏷️ Title label visible: "; m.title.visible
      print "🏷️ Title label color: "; m.title.color
  
      ' Set time metadata
      meta = ""
      if content.data <> invalid
        print "📊 Data object type: "; type(content.data)
        if type(content.data) = "roAssociativeArray" or type(content.data) = "roSGNode"
          print "📊 Data fields:"
          if type(content.data) = "roSGNode"
            print content.data.getFields()
          else
            for each key in content.data
              print "    - "; key; ": "; content.data[key]
            end for
          end if
        end if
        
        ' Format timestamps to readable time
        if content.data.start <> invalid and content.data.end <> invalid
          startTime = extractTimeFromISO(content.data.start)
          endTime = extractTimeFromISO(content.data.end)
          if startTime <> "" and endTime <> ""
            meta = startTime + " - " + endTime
            print "✓ Time meta set to: "; meta
          else
            meta = content.data.start + "  -  " + content.data.end
            print "✓ Time meta set to (raw): "; meta
          end if
        else if content.data.start <> invalid
          meta = extractTimeFromISO(content.data.start)
          if meta = "" then meta = content.data.start
          print "✓ Time meta set to (start only): "; meta
        end if
      else
        print "⚠️ No data object available"
      end if
     
  
      m.meta.text = meta
      print "=========================================="
    else
      print "❌ Content is INVALID!"
      print "=========================================="
    end if
  end sub
  
  sub onFocused()
    if m.top.hasFocus()
      m.title.color = "0xFFFFFFFF"
      m.meta.color = "0xFFFFFFFF"
      m.thumb.blendColor = "0x00FFFFFF" ' reset
      m.top.setFocus(true)
    else
      m.title.color = "0xFFFFFF"
      m.meta.color = "0xCCCCCC"
      m.thumb.blendColor = "0x33FFFFFF" ' dim
    end if
  end sub

' Extract and format time from ISO timestamp
' Input: "2025-10-13T01:00:00-05:00"
' Output: "01:00 AM"
function extractTimeFromISO(isoTimestamp as String) as String
    if isoTimestamp = invalid or isoTimestamp = ""
        return ""
    end if
    
    ' Split by "T" to get time part
    parts = isoTimestamp.Split("T")
    if parts.count() < 2
        return ""
    end if
    
    timePart = parts[1]  ' "01:00:00-05:00"
    
    ' Parse time
    timeComponents = timePart.Split(":")
    if timeComponents.count() < 2
        return ""
    end if
    
    hour = val(timeComponents[0])
    minute = timeComponents[1]
    
    ' Convert to 12-hour format
    ampm = "AM"
    if hour >= 12
        ampm = "PM"
        if hour > 12
            hour = hour - 12
        end if
    else if hour = 0
        hour = 12
    end if
    
    ' Format: "01:00 AM"
    formatted = hour.ToStr() + ":" + minute + " " + ampm
    return formatted
  end function