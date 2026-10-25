' ============================================================================
' SdTheme.brs - mySDAtv's one colour and type table.
'
' PROVENANCE. Geometry, type scale, motion and focus language are the Tulix
' Roku engine's, as wpa_live_roku ships them (source/WpTheme.brs, 2026-10-06:
' rail, tile glow, rest scale 0.92, Manrope + Inter). The COLOUR is mySDAtv's
' own, from its logo's three colours (owner, 2026-10-06: "use mySDAtv
' colours"; palette 4 "My red" picked from six options the same day):
'   red      "my"    #F0262B   the focus colour (rail pill, tile glow)
'   gold     "SDA"   #FAD35A   where the viewer is (the selected row)
'   blue     "tv"    #0981FB   the rail lockup
' The first build's cyan-on-navy ("sdanavy") stays below as a palette.
'
' Scope note: this file lives in source/ and every component that wants it
' must <script>-include it explicitly - source/ is NOT in SceneGraph
' component scope (knowledge/dev-roku/source-dir-not-in-component-scope).
' Names are prefixed `Sd` so a short helper never collides with the legacy
' screens' own functions.
'
' Every ground and surface colour on the redesigned screens is painted from
' here in init() via SdPaint, never an XML literal - so the palette changes
' in this one file (knowledge/dev-roku/trial-palette-must-paint-from-the-
' theme-at-init). XML colours are pre-init values only.
' ============================================================================

' The ACTIVE palette. A new palette is one entry in SdPalette plus, when it
' has a ground picture, one entry in tools/build-assets.ps1 $GROUNDS.
'   "myred"    navy-charcoal page, the "my" RED as the focus colour, the
'              "SDA" GOLD for "selected" - owner trial, 2026-10-06 (current)
'   "sdanavy"  the globe's navy, its cyan ring as the accent - first build,
'              2026-10-06
function SdPaletteName() as string
    return "myred"
end function

function SdPalette(name as string) as object
    if name = "sdanavy"
        ' The globe's navy, lit from the top left, the cyan ring as the
        ' highlight. Dark-navy ink on every cyan fill (white on #17C1EE is
        ' too faint), the rail's focus pill included.
        return {
            gGround: "pkg:/images/png/ground/sdanavy.png", gRail: ""
            gGroundFade: "pkg:/images/png/ground/sdanavy_fade_left.png", gFadeTint: "0xFFFFFFFF"
            cGround: "0x04142BFF", cRail: "0x00000000", cSurface: "0x0C2342FF", cSurfaceAlt: "0x10294CFF"
            cRaised: "0x173459FF", cHairline: "0x1E3D66FF", cHairlineUp: "0x2A4C78FF"
            cCard: "0x04142BB3", aGlow: 0.65
            cAccent: "0x17C1EEFF", cAccentUp: "0x5CD4F4FF", cAccentDeep: "0x0981FBFF"
            cOnAccent: "0x04142BFF", cOnAccent2: "0x062A3AFF", cOnWhite: "0x04142BFF"
            cSelected: "0x17C1EEFF"
            gGlow20: "pkg:/images/png/shapes/glow_frame_g20.9.png", gGlow30: "pkg:/images/png/shapes/glow_frame_g30.9.png"
        }
    end if
    ' "myred": the logo's "my" red is the one focus colour (rail pill, tile
    ' glow, focused title) with WHITE ink on it; the "SDA" gold marks where
    ' the viewer IS (the selected rail row, the selected DVR day), so focus
    ' and place never share a colour. A navy-charcoal ground (#0B1222) keeps
    ' the red from reading as an alarm.
    return {
        gGround: "pkg:/images/png/ground/myred.png", gRail: ""
        gGroundFade: "pkg:/images/png/ground/myred_fade_left.png", gFadeTint: "0xFFFFFFFF"
        cGround: "0x0B1222FF", cRail: "0x00000000", cSurface: "0x151E33FF", cSurfaceAlt: "0x19233AFF"
        cRaised: "0x212C47FF", cHairline: "0x27324EFF", cHairlineUp: "0x334063FF"
        cCard: "0x0B1222B3", aGlow: 0.65
        cAccent: "0xF0262BFF", cAccentUp: "0xF45A5EFF", cAccentDeep: "0xC0161BFF"
        cOnAccent: "0xFFFFFFFF", cOnAccent2: "0xFDE3E4FF", cOnWhite: "0xC0161BFF"
        cSelected: "0xFAD35AFF"
        gGlow20: "pkg:/images/png/shapes/glow_frame_g20_myred.9.png", gGlow30: "pkg:/images/png/shapes/glow_frame_g30_myred.9.png"
    }
end function

' Colours are 0xRRGGBBAA strings, which is what SceneGraph colour fields take.
' Memoised on m: item components call this for every recycled tile.
function SdTheme() as object
    if m.sdThemeCache <> invalid then return m.sdThemeCache
    p = SdPalette(SdPaletteName())

    m.sdThemeCache = {
        ' -- ground and surfaces (the active palette) --------------------------
        gGround:    p.gGround
        gRail:      p.gRail
        gGroundFade:p.gGroundFade
        gFadeTint:  p.gFadeTint
        cGround:    p.cGround
        cRail:      p.cRail
        ' Cards, list rows.
        cSurface:   p.cSurface
        cSurfaceAlt:p.cSurfaceAlt
        ' Chips, inputs, secondary buttons.
        cRaised:    p.cRaised
        cHairline:  p.cHairline
        cHairlineUp:p.cHairlineUp
        cCard:      p.cCard

        ' -- accent --------------------------------------------------------------
        cAccent:    p.cAccent
        cAccentUp:  p.cAccentUp
        cAccentDeep:p.cAccentDeep
        ' Ink drawn ON an accent fill.
        cOnAccent:  p.cOnAccent
        cOnAccent2: p.cOnAccent2
        cOnWhite:   p.cOnWhite
        cNavFocus:  p.cAccent
        cOnNavFocus:p.cOnAccent
        ' Where the viewer IS, as opposed to what they are on: the selected
        ' rail row and DVR day when their list does not hold focus.
        cSelected:  p.cSelected

        ' -- the logo's other two colours -----------------------------------------
        ' "my" red: LIVE and recording marks; "SDA" gold: the rail lockup.
        cBrandRed:  "0xF0262BFF"
        cBrandGold: "0xFAD35AFF"
        cBrandBlue: "0x0981FBFF"
        cLive:      "0xF0262BFF"

        ' -- type ------------------------------------------------------------------
        cText:      "0xFFFFFFFF"
        cText2:     "0xB4BCCBFF"
        cText3:     "0x7D879AFF"
        ' Rail glyph at rest.
        cIconIdle:  "0xC4CAD6FF"

        ' -- overlays ----------------------------------------------------------------
        cScrim:     "0x000000E6"
        cClear:     "0x00000000"
        cWhite:     "0xFFFFFFFF"
        cPlate:     "0x0A1A33E6"

        ' -- focus glow --------------------------------------------------------------
        gGlow20:    p.gGlow20
        gGlow30:    p.gGlow30
        aGlow:      p.aGlow
        gMark60:    "pkg:/images/png/brand/mark_60.png"
        gMark240:   "pkg:/images/png/brand/mark_240.png"

        ' -- type faces ----------------------------------------------------------------
        fDisplay:   "pkg:/images/fonts/Manrope-Bold.ttf"
        fDisplayXB: "pkg:/images/fonts/Manrope-ExtraBold.ttf"
        fBold:      "pkg:/images/fonts/Inter-Bold.ttf"
        fSemi:      "pkg:/images/fonts/Inter-SemiBold.ttf"
        fMedium:    "pkg:/images/fonts/Inter-Medium.ttf"
        fRegular:   "pkg:/images/fonts/Inter-Regular.ttf"

        ' -- layout contract -----------------------------------------------------------
        ' Authored at 1920x1080 (manifest ui_resolutions=fhd); a 720p panel
        ' downscales by exactly 2/3, so geometry is in multiples of 3.
        ' Screens are laid out ONCE, for the collapsed rail (content from x
        ' 160); the open rail slides the page right by railShift and never
        ' re-lays it (WPALive contract T4).
        contentX:   160
        contentW:   1700
        railW:      440
        railCollapsedW: 120
        railShift:  320
    }
    return m.sdThemeCache
end function

' Paints palette colours (and pictures) onto a component's own nodes from
' the theme: [[nodeId, field, themeKey], ...].
sub SdPaint(top as object, specs as object)
    t = SdTheme()
    for each s in specs
        n = top.findNode(s[0])
        if n <> invalid then n.setField(s[1], t[s[2]])
    end for
end sub

' One cached Font node per face and size: rows rebuild on every focus move.
function SdFont(uri as string, size as integer) as object
    key = uri + "#" + size.toStr()
    if m.sdFontCache = invalid then m.sdFontCache = {}
    if m.sdFontCache[key] <> invalid then return m.sdFontCache[key]
    f = CreateObject("roSGNode", "Font")
    f.uri = uri
    f.size = size
    m.sdFontCache[key] = f
    return f
end function

' --------------------------------------------------- artwork stand-ins --

' A card with no picture: a two-hue diagonal gradient hashed from the title
' (WPALive's website rule, so every channel keeps its own colour) and the
' monogram in white at 35 %. Returns { a: top-left, b: bottom-right }.
function SdToneFor(key as string) as object
    h = 0
    for i = 1 to Len(key)
        c = Asc(Mid(key, i, 1))
        if c > 65535 then c = 55296 + ((c - 65536) \ 1024)
        h = (31 * h + c) mod 360
    end for
    return { a: SdHsl(h, 0.55, 0.22), b: SdHsl((h + 40) mod 360, 0.60, 0.12) }
end function

sub SdPaintTone(base as object, ramp as object, label as object, key as string)
    t = SdToneFor(key)
    base.blendColor = t.b
    ramp.blendColor = t.a
    ramp.opacity = 1.0
    if label <> invalid then label.color = "0xFFFFFF59"
end sub

' CSS hsl() to "0xRRGGBBFF" (h in degrees, s and l in 0..1).
function SdHsl(h as integer, s as float, l as float) as string
    l2 = 2 * l - 1
    if l2 < 0 then l2 = -l2
    c = (1 - l2) * s
    hp = h / 60.0
    f = hp - 2 * Int(hp / 2) - 1
    if f < 0 then f = -f
    x = c * (1 - f)
    sector = Int(hp)
    r = 0.0 : g = 0.0 : b = 0.0
    if sector = 0
        r = c : g = x
    else if sector = 1
        r = x : g = c
    else if sector = 2
        g = c : b = x
    else if sector = 3
        g = x : b = c
    else if sector = 4
        r = x : b = c
    else
        r = c : b = x
    end if
    m0 = l - c / 2
    return "0x" + SdHex2(r + m0) + SdHex2(g + m0) + SdHex2(b + m0) + "FF"
end function

function SdHex2(v as float) as string
    n = Int(v * 255 + 0.5)
    if n < 0 then n = 0
    if n > 255 then n = 255
    return Right("0" + UCase(StrI(n, 16)), 2)
end function

' The first letters of the first two words ("Hope Channel" -> HC), or ONE
' letter for a single word.
function SdInitials(title as string) as string
    words = []
    for each w in title.Trim().Split(" ")
        if w <> "" then words.push(w)
    end for
    if words.count() = 0 then return ""
    if words.count() = 1 then return UCase(Left(words[0], 1))
    return UCase(Left(words[0], 1) + Left(words[1], 1))
end function

' The white ring around a FOCUSED button: a white pill six pixels larger on
' every side, created BEFORE the plate (declaration order is draw order),
' radius + 6 so the two curves stay concentric.
function SdRing(parent as object, x as integer, y as integer, w as integer, h as integer, plateRadius as integer) as object
    ring = parent.createChild("Poster")
    ring.uri = "pkg:/images/png/shapes/pill_r" + (plateRadius + 6).toStr() + ".9.png"
    ring.width = w + 12
    ring.height = h + 12
    ring.translation = [x - 6, y - 6]
    ring.blendColor = "0xFFFFFFFF"
    ring.visible = false
    return ring
end function

' The width Inter Bold draws `text` at `size` px, from the shipped TTF's own
' advances (source/SdMetrics.brs). SceneGraph has no measuring API
' (knowledge/dev-roku/text-measurement-and-label-height).
function SdTextW(text as string, size as integer) as integer
    return SdTextWIn(text, size, "bold")
end function

' The same, for a named face: "bold" (Inter Bold), "medium" (Inter Medium),
' "display" (Manrope Bold).
function SdTextWIn(text as string, size as integer, face as string) as integer
    if text = "" then return 0
    if face = "medium"
        adv = SdInterMediumAdvances()
    else if face = "display"
        adv = SdManropeBoldAdvances()
    else
        adv = SdInterBoldAdvances()
    end if
    tenths = 0
    for i = 1 to Len(text)
        c = Asc(Mid(text, i, 1))
        if c >= 32 and c <= 126 then tenths = tenths + adv[c - 32] else tenths = tenths + 600
    end for
    return Int(tenths * size / 1000 + 0.5)
end function
