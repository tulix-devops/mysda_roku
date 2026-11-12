' ============================================================================
' ScUi.brs - what the Showcase screens share: the screen title, the RowList
' set-up, the card builders and what OK on a card does.
' ============================================================================

' The screen's own name at the content's left edge (x 184, y 46), Plus
' Jakarta 46/800, with a 24/600 grey subtitle after it (owner, 2026-10-06).
sub ScSetTitle(titleLabel as object, subLabel as object, title as string, subtitle as string)
    t = ScTheme()
    titleLabel.font = ScFont(t.fXB, 46)
    titleLabel.color = t.cText
    titleLabel.translation = [t.contentX, t.titleY - 8]
    titleLabel.height = 64
    titleLabel.vertAlign = "center"
    tw = ScTextW(title, 46, "xb")
    titleLabel.width = tw + 10
    titleLabel.text = title
    subLabel.font = ScFont(t.fSemi, 24)
    subLabel.color = t.cText2
    subLabel.translation = [t.contentX + tw + 18, t.titleY + 10]
    subLabel.width = 900
    subLabel.height = 40
    subLabel.vertAlign = "center"
    subLabel.text = subtitle
end sub

' A RowList the Showcase way (y = the first row LABEL's top): rows of ScCards, the focused card pinned at
' the content edge (x 184) and the ones scrolled past sliding left under the
' fade and the capsule rather than vanishing
' (knowledge/dev-roku/rowlist-fixedfocus-hides-items-before-focus).
' rowItemSize AND itemSize are both set: with itemSize unset a RowList
' builds not one item, silently (knowledge/dev-roku/rowlist-itemsize-vs-rowitemsize).
sub ScInitRowList(list as object, y as integer)
    t = ScTheme()
    off = 400
    list.itemComponentName = "ScCard"
    list.translation = [t.contentX - off, y]
    list.rowFocusAnimationStyle = "fixedFocus"
    ' Explicit: Up off row 0 must not be consumed (Home and the channel page
    ' hand it to their buttons).
    list.vertFocusAnimationStyle = "fixedFocus"
    list.focusXOffset = [off]
    list.showRowLabel = [true]
    list.showRowCounter = [false]
    ' The label sits in a band the RowList reserves ABOVE each row's items
    ' (about 43 px for a 32-px face, measured on device 2026-10-25): the list's
    ' y is the first label's top, and rowHeights include the band.
    ' The cards' 40 px of headroom holds the focus glow; the label sits 28 px (a NEGATIVE y moves it down)
    ' down into it so it stays close to its row.
    list.rowLabelOffset = [[off, -28]]
    list.rowLabelFont = ScFont(t.fXB, 32)
    list.rowLabelColor = t.cText
    list.drawFocusFeedback = false
    list.numRows = 6
    list.itemSpacing = [0, 0]
    list.rowItemSpacing = [[24, 0]]
end sub

' rows: [{ title, items: [card nodes], w, h, gap }]. h includes the caption;
' the card's headroom (ScCardPad) is added here.
' Keeps the viewer's place when the shape is rebuilt.
sub ScApplyRows(list as object, rows as object)
    root = CreateObject("roSGNode", "ContentNode")
    sizes = []
    heights = []
    maxH = 0
    for each r in rows
        if r.items.count() > 0
            row = root.createChild("ContentNode")
            row.title = r.title
            for each it in r.items
                row.appendChild(it)
            end for
            h = r.h + ScCardPad()
            sizes.push([r.w, h])
            heights.push(h + r.gap)
            if h + r.gap > maxH then maxH = h + r.gap
        end if
    end for
    if root.getChildCount() = 0
        list.visible = false
        return
    end if
    wasAt = list.rowItemFocused
    hadFocus = list.hasFocus()
    ' NEVER an empty sizing array: the list ignores the whole pass.
    list.rowItemSize = sizes
    list.rowHeights = heights
    list.itemSize = [2400, maxH]
    list.content = root
    list.visible = true
    if hadFocus and wasAt <> invalid and wasAt.count() = 2
        r = wasAt[0]
        if r > root.getChildCount() - 1 then r = root.getChildCount() - 1
        if r < 0 then r = 0
        c = wasAt[1]
        n = root.getChild(r).getChildCount()
        if c > n - 1 then c = n - 1
        if c < 0 then c = 0
        list.jumpToRowItem = [r, c]
    end if
end sub

' The card under focus in a RowList, or invalid.
function ScFocusedCard(list as object) as dynamic
    at = list.rowItemFocused
    root = list.content
    if at = invalid or at.count() < 2 or root = invalid then return invalid
    row = root.getChild(at[0])
    if row = invalid then return invalid
    return row.getChild(at[1])
end function

function ScSelectedCard(list as object) as dynamic
    at = list.rowItemSelected
    root = list.content
    if at = invalid or at.count() < 2 or root = invalid then return invalid
    row = root.getChild(at[0])
    if row = invalid then return invalid
    return row.getChild(at[1])
end function

' ------------------------------------------------------------- builders --

' A channel's "on now" frame card (Home's On now row, C1): the grab of what
' is on with the logo badge and progress; the programme as the title on a
' titled channel, else the channel's name and "Live now · 3 PM hour".
function ScOnNowCard(ch as object) as object
    n = ScCardNode("frame", { w: 384, h: 216, logo: ch.scLogo, action: "live", ref: ch })
    n.addFields({ scToneEdge: ScToneFor(ch).edge })
    ScFillOnNow(n, ch)
    return n
end function

sub ScFillOnNow(n as object, ch as object)
    sched = ScSched(ch.scStream)
    p = ScOnNow(sched)
    if p = invalid
        n.title = ch.title
        n.scMeta = "Live now"
        n.scThumb = ""
        n.scPct = -1.0
    else
        if p.title <> ""
            n.title = p.title
            n.scMeta = ch.title + " · until " + ScHm(ScLocalParts(p.scEnd))
        else
            n.title = ch.title
            n.scMeta = "Live now · " + ScHourText(p.scStart)
        end if
        n.scThumb = ScNowGrab(sched, p)
        n.scPct = ScProgress(p.scStart, p.scEnd)
    end if
    n.scTick = n.scTick + 1
end sub

' A channel's tone: a diagonal gradient in its own brand colour (sampled
' from its logo, source/ScBrand.brs), or - where the logo has too little
' colour - in a hue hashed from its title, as the other Tulix Roku apps' tone
' cards do (wpa_live_roku WpToneFor). { a: top-left, b: bottom-right,
' mid: between them, white: the logo's own background is white, edge: the
' logo's border colour, which its plate is painted }.
function ScToneFor(ch as object) as object
    hue = -1
    white = true
    edge = "0xFFFFFFFF"
    row = ScBrandTable()[ch.id]
    if type(row) = "roArray" and row.count() >= 2
        hue = row[0]
        white = row[1]
        if row.count() >= 3 then edge = row[2]
    end if
    if hue < 0
        key = ch.title
        hue = 0
        for i = 1 to Len(key)
            hue = (31 * hue + Asc(Mid(key, i, 1))) mod 360
        end for
    end if
    if white then edge = "0xFFFFFFFF"
    return { a: ScHsl(hue, 0.62, 0.36), b: ScHsl(hue + 12, 0.70, 0.13), mid: ScHsl(hue + 6, 0.66, 0.24), white: white, edge: edge }
end function

' A channel card: its logo, whole, on a gradient in the channel's own colour
' (owner, 2026-10-28: "the colour on a background, as we have on other Roku
' apps").
function ScLogoCard(ch as object, action as string, w as integer, h as integer) as object
    n = ScCardNode("logo", { w: w, h: h, logo: ch.scLogo, title: ch.title, action: action, ref: ch })
    t = ScToneFor(ch)
    n.addFields({ scToneA: t.a, scToneB: t.b, scToneMid: t.mid, scLogoWhite: t.white, scToneEdge: t.edge })
    return n
end function

' A recording: frame grab, logo badge, a tag, title and when.
function ScRecordingCard(p as object, ch as dynamic, w as integer, h as integer, tag as string, meta as string) as object
    logo = ""
    if ch <> invalid then logo = ch.scLogo
    n = ScCardNode("frame", { w: w, h: h, thumb: p.scThumb, logo: logo, title: ScProgLabel(p), tag: tag, meta: meta, action: "catchup", ref: p, ref2: ch })
    ' The badge plate in the logo's own border colour (no white rim).
    if ch <> invalid then n.addFields({ scToneEdge: ScToneFor(ch).edge })
    return n
end function

' ------------------------------------------------------------- actions --

' What OK on a card does.
sub ScActivate(card as dynamic)
    if card = invalid or m.global = invalid then return
    a = card.scAction
    if a = "live" or a = "radio"
        if card.scRef <> invalid then m.global.playItem = ScLiveItem(card.scRef)
    else if a = "channel"
        if card.scRef <> invalid then m.global.openChannel = card.scRef
    else if a = "catchup"
        p = card.scRef
        if p = invalid then return
        ' A slot still airing plays from its start; a later one is the live
        ' channel.
        if p.scStart > ScNowSecs()
            if card.scRef2 <> invalid then m.global.playItem = ScLiveItem(card.scRef2)
            return
        end if
        list = invalid
        if card.getParent() <> invalid then list = card.getParent()
        m.global.playItem = ScCatchupItem(p, card.scRef2, list)
    end if
end sub
