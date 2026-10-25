' ============================================================================
' main.brs - the channel's entry point: create the C · Showcase scene, hand
' it deep links (at launch and while running), and leave when asked.
'
' The scene signals AppLaunchComplete itself, once, when Home has content
' (Roku wants it when the channel is ready for input, not at Show()).
' ============================================================================

sub main(args as dynamic)
	screen = CreateObject("roSGScreen")
	m.port = CreateObject("roMessagePort")
	screen.setMessagePort(m.port)
	m.global = screen.getGlobalNode()

	' The capsule's exit confirmation sets sdExitApp; the loop below returns
	' on it, which closes the channel. A GLOBAL field: an observer on a
	' scene field never delivered to this port on fw 15.3.4 (measured
	' 2026-10-06; docs/team/knowledge/mysdatv-wpalive-port-pattern.md).
	m.global.addField("sdExitApp", "boolean", true)
	m.global.observeField("sdExitApp", m.port)

	' roInput: deep links that arrive while the channel runs.
	input = CreateObject("roInput")
	input.setMessagePort(m.port)

	scene = screen.CreateScene("ScScene")
	screen.show()

	link = deepLinkFrom(args)
	if link <> invalid then scene.deepLink = link

	while true
		msg = wait(0, m.port)
		msgType = type(msg)
		if msgType = "roSGScreenEvent"
			if msg.isScreenClosed() then return
		else if msgType = "roInputEvent"
			link = deepLinkFrom(msg.getInfo())
			if link <> invalid then scene.deepLink = link
		else if msgType = "roSGNodeEvent"
			if msg.getField() = "sdExitApp" then return
		end if
	end while
end sub

' { id, mediaType } from launch args or an roInputEvent's info, or invalid.
function deepLinkFrom(args as dynamic) as dynamic
	if args = invalid then return invalid
	if args.contentId = invalid or args.mediaType = invalid then return invalid
	return { id: args.contentId, mediaType: args.mediaType }
end function
