' ============================================================================
' ScLinks.brs - the two mySDAtv web pages shown as QR codes, side by side,
' on Log in and on Account (owner, 2026-11-19: both on www.mysdatv.com,
' "below, horizontally", on the Profile screen too). One place for the
' links and the words, so the two screens never drift apart.
' ============================================================================

' Register, then subscribe: the site's home page.
function ScSiteUrl() as string
    return "https://www.mysdatv.com/"
end function

' The site's own "Donate" page; the old donation.PNG held the same link.
function ScDonateUrl() as string
    return "https://www.mysdatv.com/mysdatv-donation-page"
end function

' The cards' words (ScQrCard). Set at init; the codes come later.
sub ScQrCardsFill(join as object, give as object)
    join.kicker = "Scan to sign up"
    join.title = "Create an account & subscribe"
    join.body = "mysdatv.com, then log in here with the same email and password."
    give.kicker = "Scan to give"
    give.title = "Donate to mySDAtv"
    give.body = "A tax-deductible donation unlocks catch-up for a whole year."
end sub

' Make the codes (each card encodes once, 0.1 s after this).
sub ScQrCardsArm(join as object, give as object)
    join.url = ScSiteUrl()
    give.url = ScDonateUrl()
end sub
