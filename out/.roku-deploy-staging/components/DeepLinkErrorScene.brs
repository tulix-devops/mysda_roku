sub init()
    print "DeepLinkErrorScene init"
  
    m.messageLabel = m.top.findNode("messageLabel")
    m.homeButton = m.top.findNode("homeButton")
    m.video = m.top.findNode("video")
    m.timer = m.top.findNode("focusTimer")
  
    ' Start focus fallback
    m.timer.observeField("fire", "onFocusReady")
  
    ' Optional if message passed externally
    m.top.observeField("message", "onMessageChanged")
  
    m.homeButton.observeField("buttonSelected", "onHomePressed")
  
    ' Load dummy video to trigger Roku error handling
    content = CreateObject("roSGNode", "ContentNode")
    content.streamFormat = "hls"
    ' content.url = "https://3abn.bozztv.com/3abndvr/3abn2_Kids_live/index-1748458800-870.m3u8"  
    content.url = "https://3abn.bozztv.com/3abndvr/3abn2_live/index.m3u8"
    content.title = "Deeplink Activated"
  
    m.video.content = content
    m.video.control = "play"
  
    m.video.observeField("state", "onPlayerStateChange")
  end sub
  
  sub onFocusReady()
    print "Timer fired, setting focus..."
    


    m.homeButton.setFocus(true)
    ' Set focus to the video player scene underneath (vod_screen)
    ' vod = m.global.findNode("vod_screen")
    ' if vod <> invalid
    '   vod.visible = true
    '   vod.setFocus(true)
    ' end if
  
    ' ' Remove error overlay (this scene)
    ' parent = m.top.getParent()
    ' if parent <> invalid
    '   parent.removeChild(m.top)
    ' end if
  end sub

  sub onMessageChanged()
    m.messageLabel.text = m.top.message
  end sub

  sub onPlayerStateChange()
    print "Video state: "; m.video.state
    print m.video.errorMsg
    if m.video.state = "error"
      print "Stream failed. Roku should show error dialog."
      ' You can still overlay errorLabel, retry button, etc., here
    end if
  end sub
  
  sub onHomePressed()
    ' Optional fallback if you still want a manual option

    m.timer.control = "stop"    
    vod = m.global.findNode("vod_screen")
    if m.video <> invalid
        m.video.control = "stop"
    end if

    if vod <> invalid
      vod.visible = true
      vod.setFocus(true)
    end if
  
    parent = m.top.getParent()
    if parent <> invalid
      parent.removeChild(m.top)
    end if
  end sub