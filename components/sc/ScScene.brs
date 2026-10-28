' ============================================================================
' ScScene.brs - boot, the catalogue, the lazy schedules, the capsule, the
' screens, the dialog, sign-in and the catch-up gate, the one player, deep
' links and Back.
' ============================================================================

sub init()
    ? "[ScScene] init"
    ScEnsureGlobals()
    m.t = ScTheme()
    ScPaint(m.top, [["groundFill", "color", "cGround"], ["leftFade", "blendColor", "cScrim"], ["navFade", "blendColor", "cScrim"], ["logo", "uri", "logo"]])
    m.top.backgroundColor = m.t.cGround
    m.top.backgroundUri = ""

    m.screensGroup = m.top.findNode("screensGroup")
    m.nav = m.top.findNode("nav")
    m.dialog = m.top.findNode("dialog")
    m.signin = m.top.findNode("signin")
    m.playerHost = m.top.findNode("playerHost")
    m.channelPage = m.top.findNode("channelPage")
    m.logo = m.top.findNode("logo")
    m.clock = m.top.findNode("clock")
    m.navFade = m.top.findNode("navFade")
    m.leftFade = m.top.findNode("leftFade")
    m.clock.font = ScFont(m.t.fSemi, 27)
    m.clock.color = m.t.cText2

    m.screenNames = ["home", "channels", "radio", "catchup", "account"]
    m.current = "home"
    m.player = invalid
    m.pendingPlay = invalid
    m.authTask = invalid
    m.accessTask = invalid
    m.booted = false
    m.pendingDeepLink = invalid

    m.global.schedStore = CreateObject("roSGNode", "ContentNode")
    m.schedTasks = {}
    m.schedQueue = []

    m.global.observeField("schedWant", "onSchedWant")
    m.global.observeField("openScreen", "onOpenScreen")
    m.global.observeField("openChannel", "onOpenChannel")
    m.global.observeField("playItem", "onPlayItem")
    m.global.observeField("closeOverlay", "onCloseOverlay")
    m.global.observeField("openDialog", "onOpenDialog")
    m.global.observeField("dialogResult", "onDialogResult")
    m.global.observeField("openSignIn", "onOpenSignIn")
    m.global.observeField("requestSignOut", "onRequestSignOut")
    m.global.observeField("checkAccess", "startAccessCheck")
    m.nav.observeField("choose", "onNavChoose")
    m.nav.observeField("navHasFocus", "onNavFocus")
    m.signin.observeField("outcome", "onSignInOutcome")
    m.signin.observeField("submitRequest", "onSignInSubmit")

    publishSession()
    initClock()
    startFeeds()
    showScreen("home", true)
end sub

' ----------------------------------------------------------------- boot --

sub startFeeds()
    m.feedTasks = []
    m.feedsPending = 0
    for each kind in ["tv", "lang", "radio"]
        task = CreateObject("roSGNode", "ScFeedTask")
        task.kind = kind
        task.observeField("done", "onFeedDone")
        m.feedTasks.push(task)
        m.feedsPending = m.feedsPending + 1
        task.control = "RUN"
    end for
    w = m.top.findNode("bootWatchdog")
    w.observeField("fire", "onBootWatchdog")
    w.control = "start"
end sub

sub onFeedDone(msg as object)
    task = msg.getRoSGNode()
    if task.kind = "tv" then m.global.catTv = task.result
    if task.kind = "lang" then m.global.catLang = task.result
    if task.kind = "radio" then m.global.catRadio = task.result
    m.global.catVersion = m.global.catVersion + 1
    m.feedsPending = m.feedsPending - 1
    ' Television is what Home opens on: the channel is ready when it lands.
    if task.kind = "tv" then finishBoot()
    if m.feedsPending <= 0
        m.feedTasks = []
        if not task.ok and m.global.catTv <> invalid and m.global.catTv.getChildCount() = 0
            ? "[ScScene] the catalogue did not load"
        end if
        finishBoot()
    end if
    applyPendingDeepLink()
end sub

sub onBootWatchdog()
    if not m.booted then ? "[ScScene] boot watchdog: entering with "; m.feedsPending; " feed(s) out"
    finishBoot()
end sub

sub finishBoot()
    if m.booted then return
    m.booted = true
    m.top.findNode("bootWatchdog").control = "stop"
    ' AppLaunchComplete marks the channel ready for input, once.
    m.top.signalBeacon("AppLaunchComplete")
    applyPendingDeepLink()
end sub

' ------------------------------------------------------------- schedules --

' One load per stream per 20 minutes, at most two at once. Never in the boot
' gate (knowledge/dev-roku/secondary-feed-must-not-join-the-boot-gate).
sub onSchedWant()
    stream = m.global.schedWant
    if stream = invalid or stream = "" then return
    if m.schedTasks.doesExist(stream) then return
    have = ScSched(stream)
    if have <> invalid and ScNowSecs() - have.scAt < 1200 then return
    for each q in m.schedQueue
        if q = stream then return
    end for
    m.schedQueue.push(stream)
    pumpSchedules()
end sub

sub pumpSchedules()
    while m.schedTasks.count() < 2 and m.schedQueue.count() > 0
        stream = m.schedQueue.shift()
        ch = ScChannelByStream(stream)
        if ch <> invalid and ch.scDvr <> ""
            task = CreateObject("roSGNode", "ScScheduleTask")
            task.stream = stream
            task.url = ch.scDvr
            task.observeField("done", "onSchedDone")
            m.schedTasks[stream] = task
            task.control = "RUN"
        end if
    end while
end sub

sub onSchedDone(msg as object)
    task = msg.getRoSGNode()
    stream = task.stream
    m.schedTasks.delete(stream)
    res = task.result
    if res <> invalid and res.scOk
        store = m.global.schedStore
        old = ScSched(stream)
        if old <> invalid then store.removeChild(old)
        store.appendChild(res)
        m.global.schedLast = stream
        m.global.schedVersion = m.global.schedVersion + 1
    end if
    pumpSchedules()
end sub

' --------------------------------------------------------------- screens --

function screenNode(name as string) as dynamic
    return m.top.findNode(name)
end function

' Show a capsule destination. focusContent: focus goes into the page (the
' viewer chose it); otherwise the capsule keeps focus.
sub showScreen(name as string, focusContent as boolean)
    if screenNode(name) = invalid then name = "home"
    m.channelPage.visible = false
    m.channelPage.active = false
    for each n in m.screenNames
        s = screenNode(n)
        s.visible = (n = name)
        s.active = (n = name)
    end for
    m.current = name
    m.nav.selected = name
    if focusContent
        m.nav.navHasFocus = false
        focusPage()
    end if
end sub

sub focusPage()
    if m.channelPage.visible
        m.channelPage.setFocus(true)
    else
        screenNode(m.current).setFocus(true)
    end if
    ScFocusChanged()
end sub

sub onNavChoose()
    showScreen(m.nav.choose, true)
end sub

sub onNavFocus()
    open = m.nav.navHasFocus
    m.global.navOpen = open
    ' The page dims and the deep fade comes in WITH the capsule's own
    ' animation (same easing), from wherever they are now.
    anim = m.top.findNode("dimAnim")
    anim.control = "stop"
    pageTo = 1.0
    fadeTo = 0.0
    anim.duration = 0.18
    if open
        pageTo = 0.5
        fadeTo = 0.85
        anim.duration = 0.24
        m.navFade.visible = true
    end if
    m.top.findNode("dimPage").keyValue = [m.screensGroup.opacity, pageTo]
    m.top.findNode("dimFade").keyValue = [m.navFade.opacity, fadeTo]
    anim.control = "start"
    ScFocusChanged()
end sub

sub openNav()
    m.nav.navHasFocus = true
end sub

sub onOpenScreen()
    name = m.global.openScreen
    if name = invalid or name = "" then return
    m.pendingPlay = invalid
    destroyPlayer()
    closeDialog()
    showChrome(true)
    showScreen(name, true)
end sub

' The channel page sits over the current destination; the capsule still
' marks where the viewer came from (Home or Channels).
sub onOpenChannel()
    ch = m.global.openChannel
    if ch = invalid then return
    destroyPlayer()
    closeDialog()
    showChrome(true)
    m.channelPage.channel = invalid
    m.channelPage.channel = ch
    m.channelPage.visible = true
    m.channelPage.active = true
    screenNode(m.current).visible = false
    m.nav.navHasFocus = false
    m.channelPage.setFocus(true)
    ScFocusChanged()
end sub

sub closeChannelPage()
    m.channelPage.visible = false
    m.channelPage.active = false
    screenNode(m.current).visible = true
    focusPage()
end sub

' The logo, the clock, the capsule and the fades: down only for the player
' and the sign-in page.
sub showChrome(on as boolean)
    m.nav.visible = on
    m.logo.visible = on
    m.clock.visible = on
    m.leftFade.visible = on
    m.screensGroup.visible = on
    if not on then m.navFade.visible = false
end sub

' ---------------------------------------------------------------- dialog --

sub onOpenDialog()
    spec = m.global.openDialog
    if spec = invalid then return
    m.dialogReturnNav = m.nav.navHasFocus
    m.dialog.spec = spec
    m.dialog.visible = true
    m.dialog.setFocus(true)
    ScFocusChanged()
end sub

sub closeDialog()
    if m.dialog.visible then m.dialog.visible = false
end sub

sub onDialogResult()
    r = m.global.dialogResult
    if r = invalid then return
    closeDialog()
    id = r.id
    idx = r.index
    if id = "exit"
        if idx = 0
            m.global.sdExitApp = true
            return
        end if
        openNav()
        return
    end if
    if id = "needLogin"
        if idx = 0
            onOpenSignIn()
            return
        end if
        m.pendingPlay = invalid
    else if id = "needSub"
        m.pendingPlay = invalid
        if idx = 0
            showChrome(true)
            showScreen("account", true)
            return
        end if
    else if id = "accessError"
        if idx = 0 and m.pendingPlay <> invalid
            ' The check runs in the background; focus goes back to the page
            ' rather than staying on the hidden dialog (review C2).
            startAccessCheck()
            restoreFocus()
            return
        end if
        m.pendingPlay = invalid
    else if id = "signOut"
        if idx = 0 then onRequestSignOut()
    end if
    restoreFocus()
end sub

sub restoreFocus()
    if m.player <> invalid
        m.player.setFocus(true)
    else if m.signin.visible
        m.signin.setFocus(true)
    else if m.dialogReturnNav = true
        openNav()
    else
        focusPage()
    end if
    ScFocusChanged()
end sub

' --------------------------------------------------------------- session --

sub publishSession()
    auth = ScReadAuth()
    signedIn = (auth <> invalid)
    email = ""
    name = ""
    if signedIn
        if auth.customerEmail <> invalid then email = auth.customerEmail
        if auth.customerName <> invalid then name = auth.customerName
    end if
    if not signedIn then m.global.catchupAccess = ""
    m.global.viewerSignedIn = signedIn
    m.global.viewerEmail = email
    m.global.viewerName = name
    m.global.sessionVersion = m.global.sessionVersion + 1
end sub

sub onOpenSignIn()
    destroyPlayer()
    closeDialog()
    m.signinReturnNav = m.nav.navHasFocus
    showChrome(false)
    m.signin.visible = true
    m.signin.active = true
    m.signin.setFocus(true)
    ScFocusChanged()
end sub

sub onSignInSubmit()
    req = m.signin.submitRequest
    if type(req) <> "roAssociativeArray" or req.email = invalid then return
    if m.authTask <> invalid then return
    task = CreateObject("roSGNode", "ScAuthTask")
    task.kind = "signIn"
    task.email = req.email
    task.password = req.password
    ' The password is on the Task now; nowhere else.
    m.signin.submitRequest = {}
    task.observeField("result", "onAuthDone")
    m.authTask = task
    task.control = "RUN"
end sub

sub onRequestSignOut()
    if m.authTask <> invalid then return
    task = CreateObject("roSGNode", "ScAuthTask")
    task.kind = "signOut"
    task.observeField("result", "onAuthDone")
    m.authTask = task
    task.control = "RUN"
end sub

sub onAuthDone(msg as object)
    res = msg.getRoSGNode().result
    m.authTask = invalid
    if type(res) <> "roAssociativeArray" then return
    ? "[ScScene] auth "; res.kind; " ok="; res.ok; " reason="; res.reason; " status="; res.status
    m.global.catchupAccess = ""
    publishSession()
    if res.kind = "signIn" and m.signin.visible then m.signin.result = res
    if res.kind = "signIn" and res.ok = true then startAccessCheck()
end sub

sub onSignInOutcome()
    m.signin.active = false
    m.signin.visible = false
    showChrome(true)
    if m.signin.outcome = "signedIn" and m.pendingPlay <> invalid
        ' The access check started on sign-in plays it when it answers.
        focusPage()
        return
    end if
    m.pendingPlay = invalid
    if m.signinReturnNav = true then openNav() else focusPage()
end sub

' --------------------------------------------------------- catch-up gate --

' Live and radio are free; a recording needs a signed-in viewer whose
' account has catch-up (check-purchase, productId 15). The client-side gate
' is the only one: getdvr.php itself is open (data-brief, reported).
sub startAccessCheck()
    if m.accessTask <> invalid then return
    task = CreateObject("roSGNode", "ScAuthTask")
    task.kind = "checkAccess"
    task.observeField("result", "onAccessDone")
    m.accessTask = task
    task.control = "RUN"
end sub

sub onAccessDone(msg as object)
    res = msg.getRoSGNode().result
    m.accessTask = invalid
    if type(res) <> "roAssociativeArray" then return
    access = res.access
    ? "[ScScene] catch-up access: "; access; " ("; res.status; ")"
    if access = "unauthorized"
        m.global.catchupAccess = ""
        publishSession()
    else
        m.global.catchupAccess = access
        m.global.sessionVersion = m.global.sessionVersion + 1
    end if
    item = m.pendingPlay
    if item = invalid then return
    if access = "yes"
        m.pendingPlay = invalid
        startPlayer(item)
    else if access = "no"
        m.global.openDialog = { id: "needSub", title: "Catch-up isn't on this account yet", body: "Recordings are part of a mySDAtv subscription. Subscribe at mysdatv.com, or scan the donation code on the Account screen.", buttons: ["Account", "Not now"] }
    else if access = "unauthorized"
        m.global.openDialog = { id: "needLogin", title: "Please log in again", body: "Your session has ended. Log in to keep watching recordings.", buttons: ["Log in", "Not now"] }
    else
        m.global.openDialog = { id: "accessError", title: "We couldn't check your subscription", body: "Check the connection and try again.", buttons: ["Try again", "Cancel"] }
    end if
end sub

' ---------------------------------------------------------------- player --

sub onPlayItem()
    item = m.global.playItem
    if item = invalid then return
    if item.scKind = "catchup" and m.global.catchupAccess <> "yes"
        m.pendingPlay = item
        if not m.global.viewerSignedIn
            m.global.openDialog = { id: "needLogin", title: "Log in to watch recordings", body: "Catch-up keeps 21 days of every channel. Log in with your mysdatv.com subscription.", buttons: ["Log in", "Not now"] }
        else
            startAccessCheck()
        end if
        return
    end if
    startPlayer(item)
end sub

sub startPlayer(item as object)
    ' Whatever was waiting on the catch-up check is overtaken: a late "yes"
    ' must not replace what is playing now (review C3).
    m.pendingPlay = invalid
    destroyPlayer()
    closeDialog()
    m.playerReturnNav = m.nav.navHasFocus
    m.player = m.playerHost.createChild("ScPlayer")
    m.player.item = item
    showChrome(false)
    m.player.setFocus(true)
    ScFocusChanged()
end sub

sub destroyPlayer()
    if m.player = invalid then return
    ' Stop before removing: a Video node removed while playing keeps its
    ' decoder, and the next one cannot start.
    m.player.callFunc("teardown")
    m.playerHost.removeChild(m.player)
    m.player = invalid
end sub

' One layer at a time: the player closes onto the page it was opened from;
' the channel page closes onto its destination.
sub onCloseOverlay()
    if m.player <> invalid
        destroyPlayer()
        showChrome(true)
        if m.playerReturnNav = true then openNav() else focusPage()
        return
    end if
    if m.channelPage.visible then closeChannelPage()
end sub

' ------------------------------------------------------------- deep link --

sub onDeepLink()
    m.pendingDeepLink = m.top.deepLink
    applyPendingDeepLink()
end sub

' contentId = a catalogue channel id plays it live; anything else lands on
' Home. A link can arrive while a player or a dialog is up (roInput, a
' certification path): bring the shell to a known state first
' (knowledge/dev-roku/deep-link-while-running-must-reset-the-shell).
sub applyPendingDeepLink()
    link = m.pendingDeepLink
    if link = invalid or not m.booted then return
    id = ScStr(link.id)
    ch = ScChannelById(id)
    if ch = invalid and m.feedsPending > 0 then return
    m.pendingDeepLink = invalid
    m.pendingPlay = invalid
    destroyPlayer()
    closeDialog()
    if m.signin.visible
        m.signin.active = false
        m.signin.visible = false
    end if
    showChrome(true)
    showScreen("home", true)
    if ch <> invalid
        ? "[ScScene] deep link -> "; ch.title
        m.global.playItem = ScLiveItem(ch)
    else
        ? "[ScScene] deep link id not in the catalogue: "; id
    end if
end sub

' ------------------------------------------------------------------ back --

' Back that nothing consumed: from the page it opens the capsule; from the
' capsule on any destination but Home it goes Home; from the capsule on Home
' it asks to leave. Left at a page's left edge opens the capsule too.
function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false
    if m.player <> invalid or m.signin.visible or m.dialog.visible then return false
    if key = "back"
        if m.channelPage.visible and not m.nav.navHasFocus
            closeChannelPage()
            return true
        end if
        if not m.nav.navHasFocus
            openNav()
            return true
        end if
        ' A channel page under the capsule: Back returns to it.
        if m.channelPage.visible
            m.nav.navHasFocus = false
            focusPage()
            return true
        end if
        if m.current <> "home"
            showScreen("home", false)
            return true
        end if
        m.global.openDialog = { id: "exit", title: "Leave mySDAtv?", body: "", buttons: ["Exit", "Cancel"] }
        return true
    end if
    if key = "left" and not m.nav.navHasFocus
        openNav()
        return true
    end if
    return false
end function

' ----------------------------------------------------------------- clock --

sub initClock()
    t = m.top.findNode("clockTimer")
    t.observeField("fire", "onClockTick")
    t.control = "start"
    onClockTick()
end sub

sub onClockTick()
    m.clock.text = ScClock(ScNowSecs())
    m.global.minuteTick = m.global.minuteTick + 1
end sub
