' ============================================================================
' ScTheme.brs - the C - Showcase design tokens (docs/design/showcase.md).
'
' Near-black ground so frame grabs and logos carry the colour; white focus
' fill with dark ink; the logo's "tv" blue for progress and checkmarks; the
' logo's "my" red for LIVE. Plus Jakarta Sans throughout.
'
' Source scope: every component that calls Sc* helpers includes this file
' with a <script> tag (knowledge/dev-roku/source-dir-not-in-component-scope).
' Colours are painted from here in init(), never left as XML literals
' (knowledge/dev-roku/trial-palette-must-paint-from-the-theme-at-init).
' ============================================================================

function ScTheme() as object
    if m.scThemeCache <> invalid then return m.scThemeCache
    m.scThemeCache = {
        ' -- ground and surfaces ----------------------------------------------
        cGround:     "0x07080CFF"
        cSurface:    "0x12141BFF"   ' cards, panels
        cSurface2:   "0x1B1E27FF"   ' a not-yet-aired slot's plate
        cRaised:     "0xFFFFFF24"   ' secondary buttons, chips at rest (14 %)
        cTrack:      "0xFFFFFF33"   ' progress track (20 %)
        cCapsule:    "0x181A22D1"   ' the nav capsule (rgba 24,26,34,0.82)
        cCapsuleRing: "0xFFFFFF14"  ' its 1 px ring (8 %)
        cNavSel:     "0xFFFFFF2E"   ' the current destination's circle (18 %)
        cTag:        "0x07080CCC"   ' a tag over a picture (80 %)
        cScrim:      "0x07080CFF"   ' fades and scrims, alpha from the asset
        cShadow:     "0x000000FF"
        cVideo:      "0x000000FF"   ' behind the video plane
        cPlate:      "0xFFFFFFFF"   ' logo plates

        ' -- text --------------------------------------------------------------
        cText:       "0xFFFFFFFF"
        cText1:      "0xDADDE5FF"   ' a caption at rest
        cText2:      "0xA6ABB8FF"   ' meta, menu at rest
        cText3:      "0x6E7383FF"

        ' -- accents -----------------------------------------------------------
        cAccent:     "0x1E8BFFFF"   ' progress, checkmarks
        cLive:       "0xF0262BFF"   ' LIVE pill and dot
        cFocus:      "0xFFFFFFFF"   ' the focused button's fill
        cOnFocus:    "0x07080CFF"   ' and its ink

        ' -- faces -------------------------------------------------------------
        fXB:   "pkg:/images/fonts/PlusJakartaSans-ExtraBold.ttf"
        fBold: "pkg:/images/fonts/PlusJakartaSans-Bold.ttf"
        fSemi: "pkg:/images/fonts/PlusJakartaSans-SemiBold.ttf"
        fMed:  "pkg:/images/fonts/PlusJakartaSans-Medium.ttf"

        ' -- layout ------------------------------------------------------------
        contentX: 184     ' page content starts right of the capsule
        titleY:   46      ' every screen names itself here
        rightX:   1824    ' 1920 - 96, the right margin
        logo:     "pkg:/images/png/sc/logo_144.png"
    }
    return m.scThemeCache
end function

' A round shape at the right size for this device. 9-patch corners draw at
' DEVICE pixels, so a 720p UI gets the 2/3-radius copy
' (knowledge/dev-roku/ninepatch-borders-draw-at-device-pixels).
' name: "r2" "r7" "r14" "r17" "r22" "r26" "r35" "r51" "caps14" "caps18" "shadow14"
function ScShape(name as string) as string
    if m.scHd = invalid
        m.scHd = (CreateObject("roDeviceInfo").GetUIResolution().height = 720)
    end if
    if m.scHd then return "pkg:/images/png/sc/" + name + "_hd.9.png"
    return "pkg:/images/png/sc/" + name + ".9.png"
end function

' The radius-pill for a box of height h: radius floor((h-1)/2)
' (knowledge/dev-roku/ninepatch-pill-radius-off-by-one), from the set
' build-sc-assets.ps1 makes.
function ScPillFor(h as integer) as string
    if h >= 100 then return ScShape("r51")
    if h >= 70 then return ScShape("r35")
    if h >= 54 then return ScShape("r26")
    if h >= 44 then return ScShape("r22")
    if h >= 34 then return ScShape("r17")
    if h >= 28 then return ScShape("r14")
    if h >= 14 then return ScShape("r7")
    return ScShape("r2")
end function

' The headroom every ScCard keeps above its art for the focus lift (a lift
' of 5 % on a 216-px card is 11 px); row and grid item heights include it.
function ScCardPad() as integer
    return 12
end function

' CSS hsl() to "0xRRGGBBFF" (h in degrees, s and l in 0..1). Ported from
' wpa_live_roku WpHsl, the tone cards' colour maths.
function ScHsl(h as integer, s as float, l as float) as string
    h = h mod 360
    if h < 0 then h = h + 360
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
    mm = l - c / 2
    return "0x" + ScHex2(r + mm) + ScHex2(g + mm) + ScHex2(b + mm) + "FF"
end function

function ScHex2(v as float) as string
    n = Int(v * 255 + 0.5)
    if n < 0 then n = 0
    if n > 255 then n = 255
    return Right("0" + UCase(StrI(n, 16)), 2)
end function

function ScGlyph(name as string) as string
    return "pkg:/images/png/sc/" + name + ".png"
end function

' Paint nodes from the theme: [[nodeId, field, themeKey], ...]. A themeKey
' that starts with "pkg:" or "0x" is used as-is.
sub ScPaint(top as object, list as object)
    t = ScTheme()
    for each item in list
        node = top.findNode(item[0])
        if node <> invalid
            v = item[2]
            if t.doesExist(v) then v = t[v]
            node[item[1]] = v
        end if
    end for
end sub

' A Font node, cached per component (the font fields take a NODE).
function ScFont(uri as string, size as integer) as object
    if m.scFonts = invalid then m.scFonts = {}
    key = uri + "@" + size.toStr()
    f = m.scFonts[key]
    if f = invalid
        f = CreateObject("roSGNode", "Font")
        f.uri = uri
        f.size = size
        m.scFonts[key] = f
    end if
    return f
end function

' The width of text at a size, from the measured advances (ScMetrics.brs).
' face: "xb" | "bold" | "semi". Non-ASCII (en dash, middle dot) counts as an
' "n", which is close for both.
function ScTextW(text as string, size as integer, face as string) as integer
    if face = "xb"
        adv = ScJakartaXBAdvances()
    else if face = "semi"
        adv = ScJakartaSemiAdvances()
    else
        adv = ScJakartaBoldAdvances()
    end if
    total = 0
    n = Len(text)
    for i = 1 to n
        c = Asc(Mid(text, i, 1))
        if c >= 32 and c <= 126
            total = total + adv[c - 32]
        else
            total = total + adv[110 - 32]
        end if
    end for
    return Int(total * size / 1000 + 0.5)
end function
