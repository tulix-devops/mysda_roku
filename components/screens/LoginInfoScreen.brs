sub init()
    ' This screen is now a passive display that shows when hovering over Login/Logout
    ' It doesn't need focus or key handling - navigation bar controls everything
    m.top.visible = false
    m.top.focusable = false
    SdEnsureGlobals()
    SdPaint(m.top, [["qrPlate", "blendColor", "cSurface"], ["qrWhite", "blendColor", "cWhite"], ["messageLabel", "color", "cText2"], ["donationLabel", "color", "cText"], ["hintPlate", "blendColor", "cAccent"], ["hintKey", "color", "cOnAccent"], ["instructionsLabel", "color", "cText2"]])
end sub
