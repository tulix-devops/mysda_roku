' ============================================================================
' ScChannels.brs - C3. Two focus zones: the chips (moving along them filters
' the grid at once) and the grid.
' ============================================================================

sub init()
    ScEnsureGlobals()
    m.t = ScTheme()
    m.chipsGroup = m.top.findNode("chips")
    m.grid = m.top.findNode("grid")
    ' Room above the top row and right of the last column for the lift.
    m.grid.clippingRect = [-40, -40, 6 * 276 + 60, 3 * 262 + 40]
    m.grid.observeField("itemSelected", "onSelected")
    m.top.observeField("focusedChild", "onFocusChild")
    m.global.observeField("catVersion", "rebuild")
    m.zone = "grid"
    m.filter = 0
    m.chipIndex = 0
    m.filters = []
    m.chips = []
    rebuild()
end sub

sub onActive()
end sub

' The chips: All, Television, Languages, then each language present.
function makeFilters() as object
    tv = ScChildren(m.global.catTv)
    lang = ScChildren(m.global.catLang)
    out = [
        { label: "All", items: [] },
        { label: "Television", items: tv },
        { label: "Languages", items: lang }
    ]
    for each c in tv
        out[0].items.push(c)
    end for
    for each c in lang
        out[0].items.push(c)
    end for
    order = ["Português", "Español", "Français", "Russian", "Romanian", "Asia"]
    for each name in order
        items = []
        for each c in lang
            if c.scLang = name then items.push(c)
        end for
        if items.count() > 0 then out.push({ label: name, items: items })
    end for
    return out
end function

sub rebuild()
    m.filters = makeFilters()
    total = m.filters[0].items.count()
    ScSetTitle(m.top.findNode("title"), m.top.findNode("subtitle"), "Channels", total.toStr() + " live channels")

    m.chipsGroup.removeChildrenIndex(m.chipsGroup.getChildCount(), 0)
    m.chips = []
    x = 0
    for each f in m.filters
        chip = m.chipsGroup.createChild("ScPill")
        chip.h = 54
        chip.fontSize = 22
        chip.text = f.label + "  " + f.items.count().toStr()
        chip.translation = [x, 0]
        x = x + chip.w + 16
        m.chips.push(chip)
    end for
    if m.filter > m.filters.count() - 1 then m.filter = 0
    showFilter()
    paintChips()
end sub

sub showFilter()
    root = CreateObject("roSGNode", "ContentNode")
    for each ch in m.filters[m.filter].items
        root.appendChild(ScLogoCard(ch, "channel", 252, 179))
    end for
    m.grid.content = root
end sub

sub onSelected()
    root = m.grid.content
    if root = invalid then return
    ScActivate(root.getChild(m.grid.itemSelected))
end sub

' The selected filter's chip is white; it lifts only while the chips hold
' focus (one focus indicator: in the grid, the lifted card is it).
sub paintChips()
    chipsFocused = m.top.hasFocus() and m.zone = "chips"
    for i = 0 to m.chips.count() - 1
        m.chips[i].selected = (i = m.filter)
        m.chips[i].lit = (chipsFocused and i = m.filter)
    end for
end sub

sub onFocusChild()
    if m.top.hasFocus()
        if m.zone = "grid" and m.grid.content <> invalid and m.grid.content.getChildCount() > 0
            m.grid.setFocus(true)
        else
            m.zone = "chips"
        end if
    end if
    paintChips()
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false
    if m.zone = "chips" and m.top.hasFocus()
        if key = "left"
            if m.filter > 0
                m.filter = m.filter - 1
                showFilter()
                paintChips()
                return true
            end if
            return false
        end if
        if key = "right"
            if m.filter < m.filters.count() - 1
                m.filter = m.filter + 1
                showFilter()
                paintChips()
            end if
            return true
        end if
        if key = "down" or key = "OK"
            if m.grid.content <> invalid and m.grid.content.getChildCount() > 0
                m.zone = "grid"
                m.grid.setFocus(true)
                paintChips()
                ScFocusChanged()
            end if
            return true
        end if
        return false
    end if
    ' The grid did not take Up: it was its top row.
    if key = "up" and m.zone = "grid"
        m.zone = "chips"
        m.grid.setFocus(false)
        m.top.setFocus(true)
        paintChips()
        ScFocusChanged()
        return true
    end if
    return false
end function
