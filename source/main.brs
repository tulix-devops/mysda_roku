sub main(args as dynamic)
    screen = createObject("roSGScreen")
    m.global = screen.getGlobalNode()
    m.port = CreateObject("roMessagePort")
    screen.setMessagePort(m.port)

    contentId = invalid
    mediaType = invalid


	if (m.isDeepLinkingInitiated = true)
	
	end if

	if (args.contentID <> invalid and args.mediaType <> invalid)

		print "Main()::We have DeepLinking Request"
		print "Main()::DeepLinking mediaType "; args.mediaType
		print "Main()::DeepLinking contentId "; args.contentID
		print "Main()::DeepLinking reason "; args.reason
		m.isDeepLinkingInitiated = true
		m.deepLinkedContentId = args.contentID
		m.deepLinkedMediaType = args.mediaType
	
	end if
	' Test Deeplink with this
	' m.isDeepLinkingInitiated = true
	' m.deepLinkedContentId = "1"
	' m.deepLinkedMediaType = "Live"

	m.global.addfield("deeplinked", "string", FALSE)

	if (m.isDeepLinkingInitiated = true) then
		m.global.addfield("deepLinkedContentId", "string", FALSE)
		m.global.addfield("deepLinkedMediaType", "string", FALSE)
	
		m.global.deepLinkedContentId = m.deepLinkedContentId
		m.global.deepLinkedMediaType = m.deepLinkedMediaType
		m.global.deeplinked = "1"
	
	end if

	' Back from the rail sets sdExitApp after a confirmation (navigation_bar);
	' the loop below returns on it, which closes the channel. A GLOBAL field:
	' an observer on the scene's own exitApp field never delivered to this
	' port on fw 15.3.4 (measured 2026-10-06).
	m.global.addField("sdExitApp", "boolean", true)
	m.global.observeField("sdExitApp", m.port)

	homeScene = screen.createScene("home_scene")
	homeScene.signalBeacon("AppDialogInitiate")
	homeScene.signalBeacon("AppDialogComplete")
	homeScene.signalBeacon("AppLaunchComplete")

	screen.show()

	  while(true)
		msg = wait(0, m.port)
		msgType = type(msg)
		if msgType = "roSGScreenEvent"
			if msg.isScreenClosed() then return
		end if
		if msgType = "roInputEvent"
			info = msg.getInfo()
			getDeepLink(info)
		end if
		if msgType = "roSGNodeEvent" then
			field = msg.getField()
			if field = "exitApp" or field = "sdExitApp" then
				return
			end if
		end if
	end while
end sub

function getDeepLink(args) as object
	deeplink = invalid

	if args.contentid <> invalid and args.mediaType <> invalid
		deeplink = {
			id: args.contentId
			type: args.mediaType
		}
		m.global.addfield("deepLinkedContentId", "string", FALSE)
		m.global.addfield("deepLinkedMediaType", "string", FALSE)
		m.global.deepLinkedContentId = args.contentId
		m.global.deepLinkedMediaType = args.mediaType
		m.global.deeplinked = "1"
	end if

	return deeplink
end function





