sub init()
    m.top.observeField("focused", "onFocused")
    m.label = m.top.findNode("label")
  end sub
  
  sub updateContent()
    content = m.top.itemContent

    print content
    print "DVRSideBarItem.brs content"
    if content <> invalid and content.title <> invalid
      m.label.text = content.title
    else
      m.label.text = ""
    end if
  end sub
  
  sub onFocused()
    if m.top.hasFocus()
      m.background.color = "0x6633FFAA"  ' focus highlight
      m.label.color = "0xFFFFFF"
    else
      m.background.color = "0x00000000"
      m.label.color = "0xCCCCCC"
    end if
  end sub