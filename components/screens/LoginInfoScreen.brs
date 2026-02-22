sub init()
    ' This screen is now a passive display that shows when hovering over Login/Logout
    ' It doesn't need focus or key handling - navigation bar controls everything
    m.top.visible = false
    m.top.focusable = false
end sub

