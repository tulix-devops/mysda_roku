' ============================================================================
' ScAccount.brs - C8. One focus zone: the buttons.
' ============================================================================

sub init()
    ScEnsureGlobals()
    m.t = ScTheme()
    ScPaint(m.top, [["veil", "color", "cGround"], ["veilFade", "blendColor", "cScrim"]])
    ScSetTitle(m.top.findNode("title"), m.top.findNode("subtitle"), "Account", "")
    m.heading = m.top.findNode("heading")
    m.body = m.top.findNode("body")
    m.perksGroup = m.top.findNode("perks")
    m.buttonsGroup = m.top.findNode("buttons")
    m.heading.font = ScFont(m.t.fXB, 76)
    m.heading.color = m.t.cText
    m.heading.lineSpacing = -4
    m.body.font = ScFont(m.t.fSemi, 27)
    m.body.color = m.t.cText2
    m.body.lineSpacing = 10
    gp = m.top.findNode("givePlate")
    gp.uri = ScShape("r22")
    gp.blendColor = "0x12141BEB"
    qp = m.top.findNode("qrPlate")
    qp.uri = ScShape("r14")
    qp.blendColor = m.t.cPlate
    gt = m.top.findNode("giveTitle")
    gt.font = ScFont(m.t.fXB, 26)
    gt.color = m.t.cText
    gb = m.top.findNode("giveBody")
    gb.font = ScFont(m.t.fSemi, 20)
    gb.color = m.t.cText2
    gb.lineSpacing = 6

    m.pills = []
    m.actions = []
    m.btnIndex = 0
    m.top.observeField("focusedChild", "onFocusChild")
    m.global.observeField("sessionVersion", "draw")
    draw()
end sub

sub onActive()
    if m.top.active
        draw()
        buildWall()
        ' Signed in with access unknown: ask, so the screen can say.
        if m.global.viewerSignedIn and m.global.catchupAccess = "" then m.global.checkAccess = m.global.checkAccess + 1
    end if
end sub

sub draw()
    signedIn = m.global.viewerSignedIn
    if signedIn
        who = m.global.viewerEmail
        if m.global.viewerName <> "" then who = m.global.viewerName + " (" + m.global.viewerEmail + ")"
        m.heading.text = "You're logged in"
        access = m.global.catchupAccess
        status = "Catch-up is checked the first time you play a recording."
        if access = "yes" then status = "Catch-up is on this account: 21 days of every channel."
        if access = "no" then status = "Catch-up isn't on this account yet. Subscribe at mysdatv.com, or give instead."
        m.body.text = "Logged in as " + who + ". " + status
        labels = ["Watch catch-up", "Log out"]
        m.actions = ["catchup", "logout"]
    else
        m.heading.text = "Never miss a programme again"
        m.body.text = "Catch-up keeps 21 days of every channel. It is a small subscription at mysdatv.com; log in here with the same email and password."
        labels = ["Log in", "Not now"]
        m.actions = ["login", "home"]
    end if

    m.perksGroup.removeChildrenIndex(m.perksGroup.getChildCount(), 0)
    y = 0
    for each perk in ["Every channel, 21 days back", "Start live programmes from the top", "Whole series in one row"]
        tick = m.perksGroup.createChild("Poster")
        tick.uri = ScGlyph("check")
        tick.width = 30
        tick.height = 30
        tick.blendColor = m.t.cAccent
        tick.translation = [0, y + 6]
        lab = m.perksGroup.createChild("Label")
        lab.text = perk
        lab.font = ScFont(m.t.fBold, 26)
        lab.color = m.t.cText
        lab.translation = [46, y]
        lab.width = 800
        lab.height = 42
        lab.vertAlign = "center"
        y = y + 56
    end for

    m.buttonsGroup.removeChildrenIndex(m.buttonsGroup.getChildCount(), 0)
    m.pills = []
    x = 0
    for each text in labels
        p = m.buttonsGroup.createChild("ScPill")
        p.h = 74
        p.fontSize = 27
        p.text = text
        p.translation = [x, 0]
        x = x + p.w + 26
        m.pills.push(p)
    end for
    if m.btnIndex > m.pills.count() - 1 then m.btnIndex = 0
    paintPills()
end sub

' Today's grabs from whatever schedules are loaded, nine at most.
sub buildWall()
    wall = m.top.findNode("wall")
    wall.removeChildrenIndex(wall.getChildCount(), 0)
    thumbs = []
    for each sched in ScChildren(m.global.schedStore)
        for each p in ScChildren(sched.scToday)
            if thumbs.count() < 9 and p.scThumb <> "" and p.scEnd <= ScNowSecs() then thumbs.push(p.scThumb)
        end for
    end for
    for i = 0 to thumbs.count() - 1
        col = i mod 3
        row = Int(i / 3)
        pic = wall.createChild("Poster")
        pic.uri = thumbs[i]
        pic.loadWidth = 320
        pic.loadHeight = 180
        pic.loadDisplayMode = "scaleToZoom"
        pic.width = 353
        pic.height = 200
        pic.translation = [col * 373, row * 220]
    end for
end sub

sub onFocusChild()
    paintPills()
end sub

sub paintPills()
    lit = m.top.hasFocus()
    for i = 0 to m.pills.count() - 1
        m.pills[i].lit = (lit and i = m.btnIndex)
    end for
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false
    if key = "left"
        if m.btnIndex > 0
            m.btnIndex = m.btnIndex - 1
            paintPills()
            return true
        end if
        return false
    end if
    if key = "right"
        if m.btnIndex < m.pills.count() - 1
            m.btnIndex = m.btnIndex + 1
            paintPills()
        end if
        return true
    end if
    if key = "OK"
        a = m.actions[m.btnIndex]
        if a = "login"
            m.global.openSignIn = m.global.openSignIn + 1
        else if a = "home"
            m.global.openScreen = "home"
        else if a = "catchup"
            m.global.openScreen = "catchup"
        else if a = "logout"
            m.global.openDialog = { id: "signOut", title: "Log out of mySDAtv?", body: "Live channels and radio stay free. You can log in again any time.", buttons: ["Log out", "Cancel"] }
        end if
        return true
    end if
    return false
end function
