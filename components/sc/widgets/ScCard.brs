sub init()
    ScEnsureGlobals()
    m.t = ScTheme()
    m.art = m.top.findNode("art")
    m.shadow = m.top.findNode("shadow")
    m.plate = m.top.findNode("plate")
    m.ring = m.top.findNode("ring")
    m.thumb = m.top.findNode("thumb")
    m.logo = m.top.findNode("logo")
    m.fade = m.top.findNode("fade")
    m.caps = m.top.findNode("caps")
    m.badge = m.top.findNode("badge")
    m.tag = m.top.findNode("tag")
    m.tagPlate = m.top.findNode("tagPlate")
    m.tagText = m.top.findNode("tagText")
    m.track = m.top.findNode("track")
    m.fill = m.top.findNode("fill")
    m.inTitle = m.top.findNode("inTitle")
    m.inMeta = m.top.findNode("inMeta")
    m.title = m.top.findNode("title")
    m.meta = m.top.findNode("meta")
    m.veil = m.top.findNode("veil")
    m.logoPlate = m.top.findNode("logoPlate")
    m.ramp = m.top.findNode("ramp")
    m.logoCaps = m.top.findNode("logoCaps")
    m.logoCaps.uri = ScShape("caps14")

    m.shadow.uri = ScShape("shadow14")
    m.shadow.blendColor = "0x000000D0"
    m.plate.uri = ScShape("r14")
    ' A focused logo card's hairline ring: white at 40 %, 1 px outside.
    m.ring.uri = ScShape("r14")
    m.ring.blendColor = "0xFFFFFF66"
    m.veil.uri = ScShape("r14")
    m.veil.blendColor = m.t.cGround
    m.logoPlate.uri = ScShape("r14")
    m.logoPlate.blendColor = m.t.cPlate
    m.caps.uri = ScShape("caps14")
    m.caps.blendColor = m.t.cGround
    m.fade.blendColor = m.t.cGround
    m.top.findNode("badgePlate").uri = ScShape("r7")
    m.top.findNode("badgePlate").blendColor = m.t.cPlate
    m.tagPlate.uri = ScShape("r14")
    m.tagText.font = ScFont(m.t.fXB, 15)
    m.tagText.color = m.t.cText
    m.track.color = m.t.cTrack
    m.fill.color = m.t.cAccent
    m.inTitle.font = ScFont(m.t.fBold, 20)
    m.inTitle.color = m.t.cText
    m.inMeta.font = ScFont(m.t.fSemi, 16)
    m.inMeta.color = m.t.cText2
    m.title.font = ScFont(m.t.fBold, 23)
    m.meta.font = ScFont(m.t.fSemi, 19)
    m.meta.color = m.t.cText2
    m.lit = false
    m.kind = ""
    m.c = invalid
    m.pad = ScCardPad()
    ' A list can report focus before the card has content to draw.
    m.dim = []
    m.dimAt = -1.0
end sub

' A screen refreshes a card in place (on now, progress) by bumping its
' content's scTick; the card follows that one field of the node it shows.
' Items are recycled, so the old node is let go first.
sub onContent()
    c = m.top.itemContent
    if c = invalid then return
    if m.c = invalid or not m.c.isSameNode(c)
        if m.c <> invalid then m.c.unobserveFieldScoped("scTick")
        c.observeFieldScoped("scTick", "onTick")
        m.c = c
    end if
    draw()
end sub

sub onTick()
    draw()
end sub

sub draw()
    c = m.c
    if c = invalid then return
    kind = c.scCard
    w = c.scW
    h = c.scH
    m.kind = kind
    m.w = w
    m.h = h

    m.plate.width = w
    m.plate.height = h
    m.caps.width = w
    m.caps.height = h
    m.veil.width = w
    m.veil.height = h
    m.ring.translation = [-2, -2]
    m.ring.width = w + 4
    m.ring.height = h + 4
    b = 36
    m.shadow.translation = [-b, -b + 16]
    m.shadow.width = w + 2 * b
    m.shadow.height = h + 2 * b

    ' Headroom above the art for the focus lift: a RowList clips its items,
    ' and a card lifted 5 % from its bottom edge lost its top corners
    ' (owner, 2026-10-28). Every row's item height includes ScCardPad().
    m.art.translation = [0, m.pad]

    isFrame = (kind = "frame")
    isLogo = (kind = "logo" or kind = "station")
    isLater = (kind = "later")

    ' -- the art ----------------------------------------------------------
    ' A channel card is a tone: the plate in the tone's deep end, the
    ' diagonal ramp in its light end over it (wpa_live_roku WpPaintTone).
    isTone = (kind = "logo" and c.hasField("scToneA"))
    m.ramp.visible = isTone
    m.logoCaps.visible = false
    if isTone
        m.plate.blendColor = c.scToneB
        m.ramp.blendColor = c.scToneA
        m.ramp.width = w
        m.ramp.height = h
    else if isLogo
        m.plate.blendColor = m.t.cPlate
    else if isLater
        m.plate.blendColor = m.t.cSurface2
    else
        m.plate.blendColor = m.t.cSurface
    end if

    m.thumb.visible = isFrame and c.scThumb <> ""
    if m.thumb.visible
        m.thumb.width = w
        m.thumb.height = h
        ' Grabs are 320x180 at the source; never decode bigger than that.
        m.thumb.loadWidth = 320
        m.thumb.loadHeight = 180
        if m.thumb.uri <> c.scThumb then m.thumb.uri = c.scThumb
    end if
    ' Corner caps wherever a square picture meets the ground: a grab, the
    ' tone's ramp, or a channel logo drawn edge to edge. A plate is round by
    ' itself.
    m.caps.visible = m.thumb.visible or isTone or (kind = "logo" and c.scLogo <> "")

    ' The logo: whole, at its own 1.41 aspect, inside the plate (logo,
    ' station), or dimmed in the middle of a later slot, or as a frame's
    ' fallback until a grab exists.
    showLogo = isLogo or isLater or (isFrame and c.scThumb = "")
    m.logo.visible = showLogo and c.scLogo <> ""
    ' A frame with no grab: the logo full-strength on its own white plate in
    ' the middle (owner, 2026-10-28: the first row read "really dry" with
    ' dim logos on dark boxes).
    fallback = isFrame and c.scThumb = "" and c.scLogo <> ""
    ' On a tone card the logo is a 62 %-wide panel in the middle: on a white
    ' plate when it sits on white itself, otherwise edge to edge with its
    ' corners rounded by caps in the tone's middle colour - never a white rim
    ' round a dark logo.
    toneOnWhite = isTone and c.scLogoWhite
    ' On a tone card the logo ALWAYS sits on a plate in its own border colour
    ' (white for a logo on white, black for SUM TV, ...), set 6 px inside it:
    ' plate and logo edge match, so there is no seam, and the plate's round
    ' corners need no caps over the gradient - caps of one colour notched it
    ' (owner, 2026-10-29, SUM TV Latino).
    m.logoPlate.visible = fallback or isTone
    if fallback
        lw = Int(w * 0.50)
        lh = Int(lw / 1.41)
        m.logoPlate.width = lw
        m.logoPlate.height = lh
        m.logoPlate.translation = [Int((w - lw) / 2), Int((h - lh) / 2)]
    end if
    if isTone
        iw = Int(w * 0.62)
        ih = Int(iw / 1.41)
        ix = Int((w - iw) / 2)
        iy = Int((h - ih) / 2)
        m.logoPlate.width = iw
        m.logoPlate.height = ih
        m.logoPlate.translation = [ix, iy]
        m.logoPlate.blendColor = c.scToneEdge
    end if
    if m.logo.visible
        if isTone
            if toneOnWhite
                pw = Int(w * 0.62 * 0.9)
                ph = Int(pw / 1.41)
            else
                pw = Int(w * 0.62) - 12
                ph = Int(w * 0.62 / 1.41) - 12
            end if
        else if kind = "logo"
            ' Edge to edge: channel logos are 1.41 like the card, so the
            ' whole logo fills it - no white rim round a dark logo (owner,
            ' 2026-10-28: "white outline" on Minha TV, ANJO, SUM, GNTV).
            pw = w
            ph = h
        else if isLogo
            pw = Int(w * 0.86)
            ph = Int(h * 0.86)
        else if fallback
            pw = Int(w * 0.46)
            ph = Int(pw / 1.41)
        else
            pw = Int(w * 0.36)
            ph = Int(h * 0.44)
        end if
        m.logo.width = pw
        m.logo.height = ph
        m.logo.translation = [Int((w - pw) / 2), Int((h - ph) / 2)]
        m.logo.loadWidth = 450
        m.logo.loadHeight = 320
        ' Edge to edge means FILL: scaleToFit left a 1-px gap beside a 1.406
        ' logo in a 1.41 box, a hairline at its edge (owner, 2026-10-28). The
        ' stretch is under 0.5 %, invisible; nothing is cropped.
        edge = (kind = "logo" and not isTone)
        if edge then m.logo.loadDisplayMode = "scaleToFill" else m.logo.loadDisplayMode = "scaleToFit"
        if isLater then m.logo.opacity = 0.55 else m.logo.opacity = 1.0
        if m.logo.uri <> c.scLogo then m.logo.uri = c.scLogo
    end if

    ' Every frame card carries its channel's logo (data-brief rule).
    m.badge.visible = isFrame and c.scThumb <> "" and c.scLogo <> ""
    if m.badge.visible then m.top.findNode("badgeLogo").uri = c.scLogo

    ' -- tag --------------------------------------------------------------
    tag = c.scTag
    m.tag.visible = (tag <> "")
    if m.tag.visible
        tw = ScTextW(tag, 15, "xb") + 22
        m.tagPlate.width = tw
        m.tagText.width = tw
        m.tagText.text = tag
        if c.scTagLive then m.tagPlate.blendColor = m.t.cLive else m.tagPlate.blendColor = m.t.cTag
        if c.scTagPos = "br"
            m.tag.translation = [w - tw - 10, h - 40]
        else
            m.tag.translation = [w - tw - 10, 10]
        end if
    end if

    ' -- progress ---------------------------------------------------------
    pct = c.scPct
    m.track.visible = (pct >= 0)
    m.fill.visible = (pct >= 0)
    if pct >= 0
        m.track.width = w
        m.track.translation = [0, h - 5]
        m.fill.width = Int(w * pct)
        m.fill.translation = [0, h - 5]
    end if

    ' -- captions ---------------------------------------------------------
    inside = c.scInside
    m.fade.visible = inside
    m.inTitle.visible = inside
    m.inMeta.visible = inside
    m.title.visible = not inside
    m.meta.visible = not inside
    if inside
        m.fade.width = w
        m.fade.height = Int(h * 0.55)
        m.fade.translation = [0, h - Int(h * 0.55)]
        m.inTitle.width = w - 28
        m.inTitle.translation = [14, h - 60]
        m.inTitle.text = c.title
        m.inMeta.width = w - 28
        m.inMeta.translation = [14, h - 32]
        m.inMeta.text = c.scMeta
    else
        center = isLogo
        m.title.width = w
        m.meta.width = w
        if center
            m.title.horizAlign = "center"
            m.meta.horizAlign = "center"
            m.title.font = ScFont(m.t.fSemi, 19)
            m.title.translation = [0, m.pad + h + 10]
            m.meta.translation = [0, m.pad + h + 38]
        else
            m.title.horizAlign = "left"
            m.meta.horizAlign = "left"
            m.title.font = ScFont(m.t.fBold, 23)
            m.title.translation = [0, m.pad + h + 10]
            m.meta.translation = [0, m.pad + h + 44]
        end if
        m.title.text = c.title
        m.meta.text = c.scMeta
    end if

    if kind = "station"
        m.art.scaleRotateCenter = [w / 2, h / 2]
    else if kind = "logo"
        m.art.scaleRotateCenter = [w / 2, h]
    else
        m.art.scaleRotateCenter = [0, h]
    end if

    ' The layers that dim with focus, and the colour each is at full
    ' brightness (ScScaleColor darkens them; see onFocus). Colours are the
    ' STRINGS this card set: a blendColor read back off a node is an Integer
    ' (device, 2026-10-29: a Type Mismatch in ScScaleColor).
    plateColor = m.t.cSurface
    if isTone
        plateColor = c.scToneB
    else if isLogo
        plateColor = m.t.cPlate
    else if isLater
        plateColor = m.t.cSurface2
    end if
    m.dim = [[m.plate, plateColor]]
    if m.ramp.visible then m.dim.push([m.ramp, c.scToneA])
    if m.thumb.visible then m.dim.push([m.thumb, "0xFFFFFFFF"])
    if m.logoPlate.visible
        lpColor = m.t.cPlate
        if isTone then lpColor = c.scToneEdge
        m.dim.push([m.logoPlate, lpColor])
    end if
    if m.logo.visible then m.dim.push([m.logo, "0xFFFFFFFF"])
    if m.logoCaps.visible then m.dim.push([m.logoCaps, c.scToneMid])
    if m.badge.visible
        m.dim.push([m.top.findNode("badgePlate"), m.t.cPlate])
        m.dim.push([m.top.findNode("badgeLogo"), "0xFFFFFFFF"])
    end if
    if m.tag.visible
        tagColor = m.t.cTag
        if c.scTagLive then tagColor = m.t.cLive
        m.dim.push([m.tagPlate, tagColor])
    end if
    m.dimAt = -1.0
    onFocus()
end sub

sub applyDim(f as float)
    if Abs(f - m.dimAt) < 0.01 then return
    m.dimAt = f
    for each layer in m.dim
        layer[0].blendColor = ScScaleColor(layer[1], f)
    end for
end sub

' FOCUS, from the list's own focusPercent (gated on the list-set booleans,
' knowledge/dev-roku/list-owned-focus-fields-not-parent-walk).
' Every card keeps its size. In the row (or grid) that holds focus the cards
' at rest are darkened to 58 % - every layer's blendColor scaled (applyDim),
' the one way that leaves no line at any edge - with a grey caption; the
' focused one is full brightness, lifted 5 % from its bottom-left with a
' shadow and a white caption. Both follow focusPercent, so they glide with
' the list's own move. Brightness carries focus on this plane
' (knowledge/dev-roku/focus-border-abandoned-for-size-and-brightness); the
' hairline ring is gone (owner, 2026-10-28: "weird lines at the edges").
' History: 1.0 -> 1.07 alone read as no focus (device, 2026-10-25); the rest
' of the row shrinking to 0.94 read as shapes "changing drastically"; group
' opacity drew grey frames; a veil drew light seams (owner, 2026-10-28).
sub onFocus()
    fpRaw = m.top.focusPercent
    inFocus = m.top.gridHasFocus or (m.top.rowListHasFocus and m.top.rowHasFocus)
    m.veil.visible = false
    m.ring.visible = false
    if m.kind = "station"
        ' The Radio carousel: the station in the middle is the big one.
        s = 0.62 + 0.38 * fpRaw
        m.art.scale = [s, s]
        applyDim(0.45 + 0.55 * fpRaw)
        m.shadow.visible = (fpRaw > 0.05)
        m.shadow.opacity = fpRaw
        m.title.visible = false
        m.meta.visible = false
        return
    end if
    if inFocus
        fp = fpRaw
        s = 1.0 + 0.05 * fp
        m.art.scale = [s, s]
        applyDim(0.58 + 0.42 * fp)
        m.shadow.visible = (fp > 0.05)
        m.shadow.opacity = fp
        lit = (fp > 0.5)
        if lit then m.title.color = m.t.cText else m.title.color = m.t.cText2
        m.title.opacity = 0.75 + 0.25 * fp
    else
        m.art.scale = [1.0, 1.0]
        applyDim(1.0)
        m.shadow.visible = false
        m.title.color = m.t.cText1
        m.title.opacity = 1.0
    end if
end sub
