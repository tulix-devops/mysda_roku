' ============================================================================
' SdTile.brs - the content tile (port of wpa_live_roku WpTile.brs).
' ============================================================================

sub init()
    SdEnsureGlobals()
    m.t = SdTheme()

    m.poster       = m.top.findNode("poster")
    m.artClip      = m.top.findNode("artClip")
    m.artPlate     = m.top.findNode("artPlate")
    m.fallback     = m.top.findNode("fallback")
    m.fallbackFill = m.top.findNode("fallbackFill")
    m.fallbackOverlay = m.top.findNode("fallbackOverlay")
    m.fallbackText = m.top.findNode("fallbackText")
    m.cardFrame    = m.top.findNode("cardFrame")
    m.glowFrame    = m.top.findNode("glowFrame")
    m.cardGroup    = m.top.findNode("cardGroup")
    m.tileRoot     = m.top.findNode("tileRoot")
    m.growAnim     = m.top.findNode("growAnim")
    m.shrinkAnim   = m.top.findNode("shrinkAnim")
    m.titleLabel   = m.top.findNode("titleLabel")
    m.metaLabel    = m.top.findNode("metaLabel")

    ' A 9-patch's fixed borders draw at DEVICE pixels, unscaled by the
    ' plane's 2/3 downscale on a 720p panel, so the glow asset is picked per
    ' panel: 20 px at 720p (= 30 plane px), 30 at 1080p; and the picture
    ' sits 9 DEVICE px inside the cell (13.5 plane px at 720p)
    ' (knowledge/dev-roku/ninepatch-borders-draw-at-device-pixels).
    m.glowG = 30
    m.inset = 9
    ui = CreateObject("roDeviceInfo").GetUIResolution()
    if ui <> invalid and ui.height = 720
        m.glowFrame.uri = m.t.gGlow20
        m.inset = 13.5
    else
        m.glowFrame.uri = m.t.gGlow30
    end if
    a = m.t.aGlow
    m.top.findNode("glowInInterp").keyValue = [0.0, a]
    m.top.findNode("glowOutInterp").keyValue = [a, 0.0]

    m.defaultW = 330
    m.defaultH = 195
    m.cellW = m.defaultW
    m.cellH = m.defaultH
    m.artW = 312
    m.artH = 177

    ' invalid, NOT false: a tile that has never held focus must still get
    ' the resting state on its first update.
    m.wasFocused = invalid

    m.poster.observeField("loadStatus", "onPosterStatus")
    if m.global <> invalid then m.global.observeFieldScoped("focusTick", "onFocusTick")

    applySize()
end sub

sub onFocusTick()
    updateFocusVisual()
end sub

' Everything that depends on the cell size. Runs for EVERY item: a list
' recycles its item components.
sub applySize()
    w = m.cellW
    h = m.cellH
    inner = m.inset

    rim = 3
    if inner > 9 then rim = 4.5
    m.artPlate.translation = [inner - rim, inner - rim]
    m.artPlate.width = w - inner * 2 + rim * 2
    m.artPlate.height = h - inner * 2 + rim * 2
    m.artPlate.blendColor = m.t.cSurface
    m.cardFrame.translation = [inner, inner]
    m.cardFrame.width = w - inner * 2
    m.cardFrame.height = h - inner * 2
    m.cardFrame.blendColor = m.t.cSurface
    m.glowFrame.width = w + m.glowG * 2
    m.glowFrame.height = h + m.glowG * 2
    m.glowFrame.translation = [-m.glowG, -m.glowG]

    artW = Int(w - inner * 2 + 0.5)
    artH = Int(h - inner * 2 + 0.5)
    m.artW = artW
    m.artH = artH
    m.artClip.translation = [inner, inner]
    m.artClip.clippingRect = [0, 0, artW, artH]

    ' The poster box is 16:9 (or taller, to cover the clip) so zoomToFill has
    ' nothing to distort; the clip takes the overflow.
    boxH = Int(artW * 9 / 16)
    if boxH < artH then boxH = artH
    m.poster.width  = artW
    m.poster.height = boxH
    m.poster.loadWidth  = artW
    m.poster.loadHeight = boxH
    m.poster.translation = [0, -Int((boxH - artH) / 2)]

    m.fallbackFill.width = artW
    m.fallbackFill.height = artH
    m.fallbackOverlay.width = artW
    m.fallbackOverlay.height = artH
    m.fallbackText.width = artW
    m.fallbackText.height = artH
    m.fallbackText.font = SdFont(m.t.fDisplayXB, Int(artH * 0.36 / 3) * 3)

    capX = inner + 3
    m.titleLabel.width = artW - 3
    m.metaLabel.width = artW - 3
    m.titleLabel.translation = [capX, h + 12]
    m.metaLabel.translation  = [capX, h + 51]

    ' Shrink toward the BOTTOM-LEFT: the caption stays attached to its
    ' picture in both states, and at 1.0 the card fills its cell exactly.
    m.cardGroup.scaleRotateCenter = [0, h]
end sub

sub onContentSet()
    content = m.top.itemContent
    if content = invalid then return

    ' Geometry before the URI. EVERY branch assigns: recycled component.
    tw = content.sdTileW
    th = content.sdTileH
    if tw <> invalid and tw > 0 and th <> invalid and th > 0
        m.cellW = tw
        m.cellH = th
    else
        m.cellW = m.defaultW
        m.cellH = m.defaultH
    end if
    padTop = content.sdPadTop
    if padTop = invalid then padTop = 0
    padLeft = content.sdPadLeft
    if padLeft = invalid then padLeft = 0
    m.tileRoot.translation = [padLeft, padTop]
    applySize()

    title = content.title
    if title = invalid then title = ""
    m.titleLabel.text = title
    meta = content.sdMeta
    if meta = invalid then meta = ""
    m.metaLabel.text = meta

    art = content.sdArt
    if art = invalid or art = "" then art = content.hdPosterUrl
    if art = invalid then art = ""
    ' The feed's own stand-in is a picture of the words "no poster"; the
    ' tile's monogram card says the same thing in the channel's own colour.
    if art = "pkg:/images/png/no-poster-found.png" then art = ""

    m.fallbackText.text = SdInitials(title)
    SdPaintTone(m.fallbackFill, m.fallbackOverlay, m.fallbackText, title)
    if art <> ""
        ' The fallback stays visible UNDER the picture until it has loaded:
        ' a recycled tile never shows the previous item's picture, and a
        ' failed load leaves the monogram (knowledge/dev-roku/
        ' poster-recycled-item-loadstatus-traps).
        m.fallback.visible = true
        m.poster.visible = true
        if m.poster.uri = art
            ' Re-binding the same uri fires no loadStatus event: settle the
            ' fallback from the status it already has.
            onPosterStatus()
        else
            m.poster.uri = art
        end if
    else
        m.poster.uri = ""
        m.poster.visible = false
        m.fallback.visible = true
    end if

    updateFocusVisual()
end sub

sub onPosterStatus()
    s = m.poster.loadStatus
    if s = "ready"
        m.fallback.visible = false
    else if s = "failed"
        m.poster.visible = false
        m.fallback.visible = true
    end if
end sub

sub onFocusPercentChanged()
    updateFocusVisual()
end sub

sub updateFocusVisual()
    ' focusPercent is what the list drives - the only source that is right
    ' during a scroll - gated on the flag the list sets for its own focus.
    listLit = (m.top.gridHasFocus = true or m.top.listHasFocus = true or m.top.hostLit = true)
    lit = (m.top.focusPercent > 0.5 and listLit)

    if lit
        m.titleLabel.color = m.t.cAccent
    else
        m.titleLabel.color = m.t.cText
    end if

    if lit = m.wasFocused then return
    m.wasFocused = lit

    ' ONLY the picture dims: the corner caps must stay opaque.
    if lit
        m.poster.opacity = 1.0
        m.fallback.opacity = 1.0
        m.shrinkAnim.control = "stop"
        m.growAnim.control = "start"
    else
        m.poster.opacity = 0.82
        m.fallback.opacity = 0.82
        m.growAnim.control = "stop"
        m.shrinkAnim.control = "start"
    end if
end sub
