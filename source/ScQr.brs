' ============================================================================
' ScQr.brs - a QR code encoder: byte mode, error correction level M,
' versions 1-10 (up to 213 bytes), after Project Nayuki's reference
' implementation (MIT). The Churches screen draws a church's link with it,
' on the device - no QR web service (owner, 2026-11-18).
'
' ScQrMatrix(text) returns { size, dark } where dark[y][x] is true for a dark
' module, or invalid when the text is too long. The mask is chosen by the
' standard penalty's rules 1, 2 and 4 (rule 3, finder look-alikes, is left
' out: any mask decodes; the penalty only picks the cleanest).
' BrightScript has no XOR: ScQrXor builds it from and / or / not, which are
' bitwise on integers.
' ============================================================================

function ScQrMatrix(text as string) as dynamic
    ScQrInitGf()
    ba = CreateObject("roByteArray")
    ba.FromAsciiString(text)
    n = ba.Count()
    eccPer = [0, 10, 16, 26, 18, 24, 16, 18, 22, 22, 26]
    blocks = [0, 1, 1, 1, 2, 2, 4, 4, 4, 5, 5]

    ver = 0
    ccBits = 8
    for v = 1 to 10
        cb = 8
        if v >= 10 then cb = 16
        cap = (ScQrRawModules(v) \ 8 - eccPer[v] * blocks[v]) * 8
        if 4 + cb + 8 * n <= cap
            ver = v
            ccBits = cb
            exit for
        end if
    end for
    if ver = 0 then return invalid

    ' -- the data codewords ------------------------------------------------
    rawCw = ScQrRawModules(ver) \ 8
    numBlocks = blocks[ver]
    eccLen = eccPer[ver]
    dataCw = rawCw - eccLen * numBlocks
    bits = []
    ScQrAppend(bits, 4, 4)
    ScQrAppend(bits, n, ccBits)
    for i = 0 to n - 1
        ScQrAppend(bits, ba[i], 8)
    end for
    term = dataCw * 8 - bits.count()
    if term > 4 then term = 4
    ScQrAppend(bits, 0, term)
    while bits.count() mod 8 <> 0
        bits.push(0)
    end while
    data = []
    for i = 0 to bits.count() - 1 step 8
        v = 0
        for j = 0 to 7
            v = v * 2 + bits[i + j]
        end for
        data.push(v)
    end for
    pad = 236
    while data.count() < dataCw
        data.push(pad)
        if pad = 236 then pad = 17 else pad = 236
    end while

    ' -- blocks, error correction, interleave ------------------------------
    numShort = numBlocks - (rawCw mod numBlocks)
    shortLen = rawCw \ numBlocks
    div = ScQrDivisor(eccLen)
    blks = []
    k = 0
    for i = 0 to numBlocks - 1
        datLen = shortLen - eccLen
        if i >= numShort then datLen = datLen + 1
        dat = []
        for j = 0 to datLen - 1
            dat.push(data[k])
            k = k + 1
        end for
        ecc = ScQrRemainder(dat, div)
        blk = []
        for each d in dat
            blk.push(d)
        end for
        ' A short block holds a place where the long ones have one more.
        if i < numShort then blk.push(-1)
        for each e in ecc
            blk.push(e)
        end for
        blks.push(blk)
    end for
    words = []
    for i = 0 to shortLen
        for j = 0 to numBlocks - 1
            if i <> shortLen - eccLen or j >= numShort then words.push(blks[j][i])
        end for
    end for

    ' -- the matrix ---------------------------------------------------------
    size = ver * 4 + 17
    st = { size: size, dark: [], fn: [] }
    for y = 0 to size - 1
        rd = []
        rf = []
        for x = 0 to size - 1
            rd.push(false)
            rf.push(false)
        end for
        st.dark.push(rd)
        st.fn.push(rf)
    end for
    for i = 0 to size - 1
        ScQrSet(st, 6, i, i mod 2 = 0)
        ScQrSet(st, i, 6, i mod 2 = 0)
    end for
    ScQrFinder(st, 3, 3)
    ScQrFinder(st, size - 4, 3)
    ScQrFinder(st, 3, size - 4)
    apos = ScQrAlignPos(ver, size)
    na = apos.count()
    for i = 0 to na - 1
        for j = 0 to na - 1
            corner = (i = 0 and j = 0) or (i = 0 and j = na - 1) or (i = na - 1 and j = 0)
            if not corner then ScQrAlign(st, apos[i], apos[j])
        end for
    end for
    ScQrFormat(st, 0)
    ScQrVersion(st, ver)

    ' Codewords in the zig-zag, two columns at a time, skipping column 6.
    total = words.count() * 8
    i = 0
    right = size - 1
    while right >= 1
        if right = 6 then right = 5
        upward = ((right + 1) and 2) = 0
        for vert = 0 to size - 1
            for j = 0 to 1
                x = right - j
                if upward then y = size - 1 - vert else y = vert
                if not st.fn[y][x] and i < total
                    st.dark[y][x] = ((words[i >> 3] >> (7 - (i and 7))) and 1) = 1
                    i = i + 1
                end if
            end for
        end for
        right = right - 2
    end while

    ' The mask with the lowest penalty.
    best = 0
    bestP = -1
    for mk = 0 to 7
        ScQrMask(st, mk)
        ScQrFormat(st, mk)
        p = ScQrPenalty(st)
        if bestP < 0 or p < bestP
            best = mk
            bestP = p
        end if
        ScQrMask(st, mk)
    end for
    ScQrMask(st, best)
    ScQrFormat(st, best)
    return { size: size, dark: st.dark }
end function

sub ScQrInitGf()
    if m.qrExp <> invalid then return
    ex = []
    lg = []
    for i = 0 to 511
        ex.push(0)
    end for
    for i = 0 to 255
        lg.push(0)
    end for
    x = 1
    for i = 0 to 254
        ex[i] = x
        lg[x] = i
        x = x << 1
        if (x and &h100) <> 0 then x = ScQrXor(x, &h11D)
    end for
    for i = 255 to 511
        ex[i] = ex[i - 255]
    end for
    m.qrExp = ex
    m.qrLog = lg
end sub

function ScQrXor(a as integer, b as integer) as integer
    return (a or b) and (not (a and b))
end function

function ScQrMul(a as integer, b as integer) as integer
    if a = 0 or b = 0 then return 0
    return m.qrExp[m.qrLog[a] + m.qrLog[b]]
end function

sub ScQrAppend(bits as object, value as integer, count as integer)
    for i = count - 1 to 0 step -1
        bits.push((value >> i) and 1)
    end for
end sub

function ScQrBit(x as integer, i as integer) as boolean
    return ((x >> i) and 1) <> 0
end function

function ScQrRawModules(ver as integer) as integer
    r = (16 * ver + 128) * ver + 64
    if ver >= 2
        na = ver \ 7 + 2
        r = r - ((25 * na - 10) * na - 55)
        if ver >= 7 then r = r - 36
    end if
    return r
end function

function ScQrDivisor(degree as integer) as object
    res = []
    for i = 1 to degree - 1
        res.push(0)
    end for
    res.push(1)
    root = 1
    for i = 0 to degree - 1
        for j = 0 to degree - 1
            res[j] = ScQrMul(res[j], root)
            if j + 1 < degree then res[j] = ScQrXor(res[j], res[j + 1])
        end for
        root = ScQrMul(root, 2)
    end for
    return res
end function

function ScQrRemainder(data as object, div as object) as object
    res = []
    for each d in div
        res.push(0)
    end for
    for each b in data
        factor = ScQrXor(b, res.shift())
        res.push(0)
        for i = 0 to div.count() - 1
            res[i] = ScQrXor(res[i], ScQrMul(div[i], factor))
        end for
    end for
    return res
end function

function ScQrAlignPos(ver as integer, size as integer) as object
    if ver = 1 then return []
    na = ver \ 7 + 2
    stp = ((ver * 8 + na * 3 + 5) \ (na * 4 - 4)) * 2
    res = [6]
    p = size - 7
    while res.count() < na
        nxt = [6, p]
        for k = 1 to res.count() - 1
            nxt.push(res[k])
        end for
        res = nxt
        p = p - stp
    end while
    return res
end function

sub ScQrSet(st as object, x as integer, y as integer, isDark as boolean)
    st.dark[y][x] = isDark
    st.fn[y][x] = true
end sub

sub ScQrFinder(st as object, cx as integer, cy as integer)
    for dy = -4 to 4
        for dx = -4 to 4
            x = cx + dx
            y = cy + dy
            if x >= 0 and x < st.size and y >= 0 and y < st.size
                ax = dx
                if ax < 0 then ax = -ax
                ay = dy
                if ay < 0 then ay = -ay
                d = ax
                if ay > d then d = ay
                ScQrSet(st, x, y, d <> 2 and d <> 4)
            end if
        end for
    end for
end sub

sub ScQrAlign(st as object, cx as integer, cy as integer)
    for dy = -2 to 2
        for dx = -2 to 2
            ax = dx
            if ax < 0 then ax = -ax
            ay = dy
            if ay < 0 then ay = -ay
            d = ax
            if ay > d then d = ay
            ScQrSet(st, cx + dx, cy + dy, d <> 1)
        end for
    end for
end sub

' Format bits: level M is 00, then the mask; BCH(15,5), XOR 0x5412.
sub ScQrFormat(st as object, mask as integer)
    data = mask
    rm = data
    for i = 1 to 10
        rm = ScQrXor(rm << 1, (rm >> 9) * &h537)
    end for
    bits = ScQrXor((data << 10) or rm, &h5412)
    size = st.size
    for i = 0 to 5
        ScQrSet(st, 8, i, ScQrBit(bits, i))
    end for
    ScQrSet(st, 8, 7, ScQrBit(bits, 6))
    ScQrSet(st, 8, 8, ScQrBit(bits, 7))
    ScQrSet(st, 7, 8, ScQrBit(bits, 8))
    for i = 9 to 14
        ScQrSet(st, 14 - i, 8, ScQrBit(bits, i))
    end for
    for i = 0 to 7
        ScQrSet(st, size - 1 - i, 8, ScQrBit(bits, i))
    end for
    for i = 8 to 14
        ScQrSet(st, 8, size - 15 + i, ScQrBit(bits, i))
    end for
    ScQrSet(st, 8, size - 8, true)
end sub

sub ScQrVersion(st as object, ver as integer)
    if ver < 7 then return
    rm = ver
    for i = 1 to 12
        rm = ScQrXor(rm << 1, (rm >> 11) * &h1F25)
    end for
    bits = (ver << 12) or rm
    for i = 0 to 17
        bt = ScQrBit(bits, i)
        a = st.size - 11 + (i mod 3)
        b = i \ 3
        ScQrSet(st, a, b, bt)
        ScQrSet(st, b, a, bt)
    end for
end sub

sub ScQrMask(st as object, mask as integer)
    size = st.size
    for y = 0 to size - 1
        rd = st.dark[y]
        rf = st.fn[y]
        for x = 0 to size - 1
            if not rf[x]
                if mask = 0
                    inv = (x + y) mod 2 = 0
                else if mask = 1
                    inv = y mod 2 = 0
                else if mask = 2
                    inv = x mod 3 = 0
                else if mask = 3
                    inv = (x + y) mod 3 = 0
                else if mask = 4
                    inv = (x \ 3 + y \ 2) mod 2 = 0
                else if mask = 5
                    inv = (x * y) mod 2 + (x * y) mod 3 = 0
                else if mask = 6
                    inv = ((x * y) mod 2 + (x * y) mod 3) mod 2 = 0
                else
                    inv = ((x + y) mod 2 + (x * y) mod 3) mod 2 = 0
                end if
                if inv then rd[x] = not rd[x]
            end if
        end for
    end for
end sub

function ScQrPenalty(st as object) as integer
    size = st.size
    d = st.dark
    p = 0
    ' Rule 1: runs of five or more in a row or a column.
    for y = 0 to size - 1
        rl = 1
        for x = 1 to size - 1
            if d[y][x] = d[y][x - 1]
                rl = rl + 1
                if rl = 5
                    p = p + 3
                else if rl > 5
                    p = p + 1
                end if
            else
                rl = 1
            end if
        end for
    end for
    for x = 0 to size - 1
        rl = 1
        for y = 1 to size - 1
            if d[y][x] = d[y - 1][x]
                rl = rl + 1
                if rl = 5
                    p = p + 3
                else if rl > 5
                    p = p + 1
                end if
            else
                rl = 1
            end if
        end for
    end for
    ' Rule 2: 2 x 2 blocks of one colour.
    dk = 0
    for y = 0 to size - 2
        for x = 0 to size - 2
            c = d[y][x]
            if c = d[y][x + 1] and c = d[y + 1][x] and c = d[y + 1][x + 1] then p = p + 3
        end for
    end for
    ' Rule 4: the dark share's distance from half.
    for y = 0 to size - 1
        for x = 0 to size - 1
            if d[y][x] then dk = dk + 1
        end for
    end for
    tot = size * size
    diff = dk * 20 - tot * 10
    if diff < 0 then diff = -diff
    k = (diff + tot - 1) \ tot - 1
    if k > 0 then p = p + k * 10
    return p
end function
