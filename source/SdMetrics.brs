' ============================================================================
' SdMetrics.brs - copied from wpa_live_roku source/WpMetrics.brs (GENERATED there by
' tools/build-metrics.ps1 from the same Inter and Manrope TTFs), prefix renamed.
' Advances for printable ASCII (32..126), in tenths of a pixel at a 100 px
' font, measured from the shipped TTFs. SdTextW / SdTextWIn sum them.
' ============================================================================

' Inter-Bold - images/fonts/Inter-Bold.ttf
function SdInterBoldAdvances() as object
    if m.sdAdvCache <> invalid then return m.sdAdvCache
    m.sdAdvCache = [
        237, 338, 552, 649, 655, 1016, 672, 339, 377, 377, 559, 679, 334, 468, 334, 388,
        674, 431, 630, 646, 676, 622, 649, 582, 651, 649, 334, 343, 679, 679, 679, 560,
        1016, 747, 662, 740, 722, 607, 587, 750, 747, 281, 584, 719, 565, 932, 762, 771,
        648, 777, 657, 655, 667, 732, 747, 1038, 738, 731, 664, 377, 388, 377, 487, 476,
        365, 581, 630, 588, 630, 596, 398, 632, 623, 271, 271, 580, 271, 913, 623, 613,
        630, 630, 407, 560, 366, 623, 600, 850, 580, 602, 573, 469, 372, 469, 679
    ]
    return m.sdAdvCache
end function

' Inter-Medium - images/fonts/Inter-Medium.ttf
function SdInterMediumAdvances() as object
    if m.sdAdvMediumCache <> invalid then return m.sdAdvMediumCache
    m.sdAdvMediumCache = [
        267, 304, 494, 639, 646, 993, 653, 313, 369, 369, 521, 667, 303, 462, 303, 370,
        646, 415, 616, 627, 656, 603, 630, 571, 629, 630, 303, 315, 667, 667, 667, 527,
        982, 709, 657, 733, 722, 603, 589, 748, 745, 272, 575, 688, 565, 913, 756, 767,
        642, 769, 648, 646, 653, 740, 709, 1003, 701, 696, 641, 369, 370, 369, 477, 463,
        337, 568, 618, 577, 618, 587, 379, 620, 602, 252, 252, 559, 252, 888, 602, 604,
        618, 618, 387, 539, 340, 602, 575, 829, 557, 575, 559, 440, 346, 440, 667
    ]
    return m.sdAdvMediumCache
end function

' Manrope-Bold - images/fonts/Manrope-Bold.ttf
function SdManropeBoldAdvances() as object
    if m.sdAdvManropeCache <> invalid then return m.sdAdvManropeCache
    m.sdAdvManropeCache = [
        200, 361, 467, 931, 628, 901, 669, 261, 453, 453, 465, 571, 304, 420, 304, 433,
        658, 438, 596, 581, 609, 586, 621, 534, 612, 621, 342, 344, 638, 750, 638, 553,
        914, 671, 631, 739, 701, 585, 524, 732, 721, 281, 501, 647, 534, 855, 718, 749,
        639, 749, 660, 658, 606, 720, 641, 976, 656, 611, 664, 424, 433, 424, 681, 660,
        539, 576, 616, 576, 617, 602, 378, 616, 626, 281, 289, 538, 281, 899, 626, 618,
        616, 617, 399, 542, 433, 626, 553, 802, 554, 559, 534, 449, 301, 449, 716
    ]
    return m.sdAdvManropeCache
end function
