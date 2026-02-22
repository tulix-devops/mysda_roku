function init()
    ? "[home_scene] init"
    ' m.global.addField("liveChannelsEntity", "array", false)
    ' m.navBar = m.top.findNode("navigation_bar")
    ' m.navBar.setFocus(true)

    ' m.top.callFunc("checkDeeplink")



    ' initializeLiveChannelData()
    m.showParentGroupAnimation = m.top.findNode("showNavigationAnimation")

    m.top.navBarUnfocused = m.top.findNode("navBarUnfocused")

    m.authToken = ""


    checkDeeplink()



    ' m.top.ComponentController = m.top.findNode("ComponentController")
    ' m.top.buttonBar = m.top.ComponentController.findNode("buttonBar")
    ' m.top.buttonBar.visible = false

end function

sub showHomeScreen()
    m.homeScreen = m.top.findNode("home_screen")

end sub



sub checkDeepLink()
    if m.global.deeplinked = "1"
      m.global.deeplinked = "0"  ' reset so it doesn't trigger again
      print "Invalid deep link. Showing error screen."
      m.global.findNode("vod_screen").visible = false
      showDeepLinkError()
    '   if isContentAvailable(m.global.deepLinkedContentId)
    '     print "Valid content found. Navigate to player or content scene"
    '     ' your logic to push video player
    '   else
    '     print "Invalid deep link. Showing error screen."
    '     showDeepLinkError()
    '   end if
    else
        print "Im not getting Here YOu Know?"
        m.global.findNode("vod_screen").visible = true
        m.global.findNode("vod_screen").setFocus(true)
    end if
  end sub

  sub showDeepLinkError()
    m.errorScene = CreateObject("roSGNode", "DeepLinkErrorScene")
    m.errorScene.message = ""
    m.top.appendChild(m.errorScene)
  end sub





function initializeLiveChannelData()
    m.liveChannelData = createObject("roSGNode", "LiveScreenApi")
    m.liveChannelData.observeField("responseData", "handleResponseData")
    m.liveChannelData.control = "RUN"

end function




sub sendAppLaunchCompleteBeacon()
    ' Replace these placeholders with actual values from your Roku developer account
    developerId = "88cda8a8ed744cba6c0fc1cb4aedc3dcd307f448"
    channelId = "777725"
    timeStamp = m.top.timeNow()

    ' Construct the URL for the beacon
    beaconUrl = "https://beacon.appcloud.roku.com/beacon/roku/app/launchcomplete"
    beaconUrl = beaconUrl + "?did=" + developerId + "&cid=" + channelId + "&ts=" + timeStamp

    ' Send the GET request to the beacon URL
    request = createObject("roUrlTransfer")
    request.setUrl(beaconUrl)
    request.getToFile("NUL:") ' Send the request and ignore response

    ' Optionally log or handle any errors
    if request.getResponseCode() <> 200 then
        print "Error sending AppLaunchComplete beacon: " + request.getResponseCode()
    end if
end sub


sub handleResponseData()
    data = m.liveChannelData.responseData

    m.top.liveChannelsEntity = parseChannelEntity(data)


    m.global.liveChannelsEntity = m.top.liveChannelsEntity

end sub



function RetrieveAuthData() as object
    section = "AUTH"
    jsonData = RegRead("authData", section)
    print jsonData
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


function UpdateAuthData(accessToken as string, subscribed as boolean, isauth as boolean, expiry as integer)
    section = "AUTH"
    sec = CreateObject("roRegistrySection", section)

    ' Convert boolean values to integers
    if subscribed
        subscribedValue = 1
    else
        subscribedValue = 0
    end if

    if isauth
        isAuthValue = 1
    else
        isAuthValue = 0
    end if

    data = {
        accessToken: accessToken,
        subscribed: subscribedValue,
        expiry: expiry,
        ' expiry: 4,
        isauth: isAuthValue
    }
    jsonData = FormatJson(data)
    ' Write the associative array to the registry
    sec.Write("authData", jsonData)
    sec.Flush()
end function


function RegRead(key, section = invalid)
    if section = invalid section = "Default"
    sec = CreateObject("roRegistrySection", section)
    if sec.Exists(key) return sec.Read(key)
    ' return invalid
    return sec.Read(key)
end function
