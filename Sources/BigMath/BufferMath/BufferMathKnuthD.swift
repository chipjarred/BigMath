/*
Copyright 2020 Chip Jarred

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
 so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

// -------------------------------------
/**
 Compute `y = y - x * k`
 
 - Parameters:
    - x: A multiprecision number with the least signficant digit
        stored at index 0 (ie. little endian).  It is multiplied by the "digit",
        `k`, with the resulting product being subtracted from `y`
    - k: Scalar multiple to apply to `x` prior to subtraction
    - y: Both the number being subtracted from, and the storage for the result,
        represented as a collection of digits with the least signficant digits
        at index 0.
 
 - Returns: The borrow out of the most signficant digit of `y`.
 */
@usableFromInline @inline(__always)
func subtractReportingBorrowKnuth(
    _ x: MutableUIntBuffer,
    times k: UInt,
    from y: inout MutableUIntBuffer) -> Bool
{
    assert(x.count + 1 <= y.count)
    
    var xPtr = x.baseAddress!
    let xEnd = xPtr + x.count
    var yPtr = y.baseAddress!

    var borrow: UInt = 0
    while xPtr < xEnd
    {
        borrow = yPtr.pointee.subtractFromSelfReportingBorrow(borrow)
        let (pHi, pLo) = k.multipliedFullWidth(by: xPtr.pointee)
        borrow &+= pHi
        borrow &+= yPtr.pointee.subtractFromSelfReportingBorrow(pLo)
        
        xPtr += 1
        yPtr += 1
    }
    
    return 0 != yPtr.pointee.subtractFromSelfReportingBorrow(borrow)
}

// -------------------------------------
/**
 Compute `y = y - x * k`
 
 - Parameters:
    - x: A multiprecision number with the least signficant digit
        stored at index 0 (ie. little endian).  It is multiplied by the "digit",
        `k`, with the resulting product being subtracted from `y`
    - k: Scalar multiple to apply to `x` prior to subtraction
    - y: Both the number being subtracted from, and the storage for the result,
        represented as a collection of digits with the least signficant digits
        at index 0.
 
 - Returns: The borrow out of the most signficant digit of `y`.
 */
@usableFromInline @inline(__always)
func subtractReportingBorrowKnuth(
    _ x: UIntBuffer,
    times k: UInt,
    from y: inout MutableUIntBuffer) -> Bool
{
    assert(x.count + 1 <= y.count)
    
    var xPtr = x.baseAddress!
    let xEnd = xPtr + x.count
    var yPtr = y.baseAddress!

    var borrow: UInt = 0
    while xPtr < xEnd
    {
        borrow = yPtr.pointee.subtractFromSelfReportingBorrow(borrow)
        let (pHi, pLo) = k.multipliedFullWidth(by: xPtr.pointee)
        borrow &+= pHi
        borrow &+= yPtr.pointee.subtractFromSelfReportingBorrow(pLo)
        
        xPtr += 1
        yPtr += 1
    }
    
    return 0 != yPtr.pointee.subtractFromSelfReportingBorrow(borrow)
}

// -------------------------------------
/**
 Add two multiprecision numbers.
 
 - Parameters:
    - x: The first addend as a collection digits with the least signficant
        digit at index 0 (ie. little endian).
    - y: The second addend and the storage for the resulting sum as a
        collection of digits with the the least signficant digit at index 0
        (ie. little endian).
 */
@usableFromInline @inline(__always)
func += (left: inout MutableUIntBuffer, right: MutableUIntBuffer )
{
    assert(right.count + 1 == left.count)
    var carry: UInt = 0
    
    var xPtr = right.baseAddress!
    let xEnd = xPtr + right.count
    var yPtr = left.baseAddress!
    
    while xPtr < xEnd
    {
        carry = yPtr.pointee.addToSelfReportingCarry(carry)
        carry &+= yPtr.pointee.addToSelfReportingCarry(xPtr.pointee)
        
        xPtr += 1
        yPtr += 1
    }
    
    yPtr.pointee &+= carry
}

// -------------------------------------
/**
 Add two multiprecision numbers.
 
 - Parameters:
    - x: The first addend as a collection digits with the least signficant
        digit at index 0 (ie. little endian).
    - y: The second addend and the storage for the resulting sum as a
        collection of digits with the the least signficant digit at index 0
        (ie. little endian).
 */
@usableFromInline @inline(__always)
func += (left: inout MutableUIntBuffer, right: UIntBuffer )
{
    assert(right.count + 1 == left.count)
    var carry: UInt = 0
    
    var xPtr = right.baseAddress!
    let xEnd = xPtr + right.count
    var yPtr = left.baseAddress!
    
    while xPtr < xEnd
    {
        carry = yPtr.pointee.addToSelfReportingCarry(carry)
        carry &+= yPtr.pointee.addToSelfReportingCarry(xPtr.pointee)
        
        xPtr += 1
        yPtr += 1
    }
    
    yPtr.pointee &+= carry
}

// -------------------------------------
/**
 Shift the multiprecision unsigned integer, `x`, left by `shift` bits.
 
 - Parameters:
    - x: The mutliprecision unsigned integer to be left-shfited, stored as a
        collection of digits with the least signficant digit stored at index 0.
        (ie. little endian)
    - shift: the number of bits to shift `x` by.
    - y: Storage for the resulting shift of `x`.  May alias `x`.
 */
@usableFromInline @inline(__always)
func leftShiftKnuth(
    _ x: UIntBuffer,
    by shift: Int,
    into y: inout MutableUIntBuffer)
{
    assert(y.count >= x.count)
    assert(y.startIndex == x.startIndex)
    
    let bitWidth = MemoryLayout<UInt>.size * 8
    
    for i in (1..<x.count).reversed() {
        y[i] = (x[i] << shift) | (x[i - 1] >> (bitWidth - shift))
    }
    y[0] = x[0] << shift
}

// -------------------------------------
/**
 Shift the multiprecision unsigned integer,`x`, right by `shift` bits.
 
 - Parameters:
    - x: The mutliprecision unsigned integer to be right-shfited, stored as a
        collection of digits with the least signficant digit stored at index 0.
        (ie. little endian)
    - shift: the number of bits to shift `x` by.
    - y: Storage for the resulting shift of `x`.  May alias `x`.
 */
@usableFromInline @inline(__always)
func rightShiftKnuth(
    _ x: MutableUIntBuffer,
    by shift: Int,
    into y: inout MutableUIntBuffer)
{
    assert(y.count == x.count)
    assert(y.startIndex == x.startIndex)
    let bitWidth = MemoryLayout<UInt>.size * 8
    
    let lastElemIndex = x.count - 1
    for i in 0..<lastElemIndex {
        y[i] = (x[i] >> shift) | (x[i + 1] << (bitWidth - shift))
    }
    y[lastElemIndex] = x[lastElemIndex] >> shift
}

// -------------------------------------
/**
 Divide the multiprecision number stored in `x`, by the "digit",`y.`
 
 - Parameters:
    - x: The dividend as a multiprecision number with the least signficant digit
        stored at index 0 (ie. little endian).
    - y: The single digit divisor (where digit is the same radix as digits of
        `x`).
    - z: storage to receive the quotient on exit.  Must be same size as `x`

- Returns: A single digit remainder.
 */
@usableFromInline @inline(__always)
func divide(
    _ x: UIntBuffer,
    by y: UInt,
    result z: inout MutableUIntBuffer) -> UInt
{
    assert(x.count == z.count)
    assert(x.startIndex == z.startIndex)
    
    var r: UInt = 0
    var i = x.count - 1
    
    (z[i], r) = x[i].quotientAndRemainder(dividingBy: y)
    i -= 1
    
    while i >= 0
    {
        (z[i], r) = y.dividingFullWidth((r, x[i]))
        i -= 1
    }
    return r
}

// -------------------------------------
/// Multiply a tuple of digits by 1 digit
@usableFromInline @inline(__always)
internal func * (
    left: (high: UInt, low: UInt),
    right: UInt) -> (high: UInt, low: UInt)
{
    var product = left.low.multipliedFullWidth(by: right)
    let productHigh = left.high.multipliedFullWidth(by: right)
    assert(productHigh.high == 0, "multiplication overflow")
    let c = product.high.addToSelfReportingCarry(productHigh.low)
    assert(c == 0, "multiplication overflow")
    
    return product
}

infix operator /% : MultiplicationPrecedence

// -------------------------------------
/// Divide a tuple of digits by 1 digit obtaining both quotient and remainder
@usableFromInline @inline(__always)
internal func /% (
    left: (high: UInt, low: UInt),
    right: UInt)
    -> (quotient: (high: UInt, low: UInt), remainder: (high: UInt, low: UInt))
{
    var r: UInt
    let q: (high: UInt, low: UInt)
    (q.high, r) = left.high.quotientAndRemainder(dividingBy: right)
    (q.low, r) = right.dividingFullWidth((high: r, low: left.low))
    
    return (q, (high: 0, low: r))
}

// -------------------------------------
/**
 Tests if  the tuple, `left`, is greater than tuple, `right`.
 
 - Returns: `UInt8` that has the value of 1 if `left` is greater than right;
    otherwise, 0.  This is done in place of returning a boolean as part of an
    optimization to avoid hidden conditional branches in boolean expressions.
 */
@usableFromInline @inline(__always)
internal func > (left: (high: UInt, low: UInt), right: (high: UInt, low: UInt))
    -> UInt8
{
    return UInt8(left.high > right.high)
        | (UInt8(left.high == right.high) & UInt8(left.low > right.low))
}

// -------------------------------------
/// Add a digit to a tuple's low part, carrying to the high part.
@usableFromInline @inline(__always)
func += (left: inout (high: UInt, low: UInt), right: UInt) {
    left.high &+= left.low.addToSelfReportingCarry(right)
}

// -------------------------------------
/// Add one tuple to another tuple
@usableFromInline @inline(__always)
func += (left: inout (high: UInt, low: UInt), right: (high: UInt, low: UInt))
{
    left.high &+= left.low.addToSelfReportingCarry(right.low)
    left.high &+= right.high
}

// -------------------------------------
/// Subtract a digit from a tuple, borrowing the high part if necessary
@usableFromInline @inline(__always)
func -= (left: inout (high: UInt, low: UInt), right: UInt) {
    left.high &-= left.low.subtractFromSelfReportingBorrow(right)
}

// -------------------------------------
/**
 Divide multiprecision unsigned integer, `x`, by multiprecision unsigned
 integer, `y`, obtaining both the quotient and remainder.
 
 Implements Alogorithm D, from Donald Knuth's, *The Art of Computer Programming*
 , Volume 2,*Semi-numerical Algorithms*, Chapter 4.3.3.
 
 - Parameters:
    - dividend: The dividend stored as an unsigned multiprecision integer with
        its least signficant digit at index 0 (ie, little endian). Must have at
        least as many digits as `divisor`.
    - divisor: The divisor stored as a an unsigned multiprecision integer with
        its least signficant digit stored at index 0 (ie. little endian).
    - quotient: Buffer to receive the quotient (`x / y`).  Must be the size of
        the dividend minus the size of the divisor plus one.
    - remainder: Buffer to receive the remainder (`x % y`).  Must be the size
        of the dividend, plus one (this buffer is used for intermediate
        computations as well).
    - scratch: Buffer to hold normalized divisor during computation.  Must be
        the same size as `divisor`.
 */
@usableFromInline @inline(__always)
internal func fullWidthDivide_KnuthD(
    _ dividend: UIntBuffer,
    by divisor: UIntBuffer,
    quotient: MutableUIntBuffer,
    remainder: MutableUIntBuffer,
    scratch: MutableUIntBuffer)
{
    let divisor = signficantDigits(of: divisor)
    let dividend = signficantDigits(of: dividend)
    var quotient = quotient[...]
    var remainder = remainder[...]
    
    typealias Digit = UInt
    typealias TwoDigits = (high: UInt, low: UInt)
    let digitWidth = Digit.bitWidth
    let m = dividend.count
    let n = divisor.count
    
    assert(n > 0, "Divisor must have at least one digit")
    assert(divisor.reduce(0) { $0 | $1 } != 0, "Division by 0")
    assert(m >= n, "Dividend must have at least as many digits as the divisor")
    assert(
        quotient.count >= m - n + 1,
        "Must have space for the number of digits in the dividend minus the "
        + "number of digits in the divisor plus one more digit."
    )
    assert(
        remainder.count >= m + 1,
        "Remainder must have space for the same number of digits as the "
        + "dividend plus one"
    )
    assert(
        scratch.count >= n,
        "Scratch space for normalized divisor is not the same size as the "
        + "divisor."
    )

    guard n > 1 else
    {
        remainder[0] = divide(
            dividend,
            by: divisor.first!,
            result: &quotient[dividend.indices]
        )
        return
    }

    let shift = divisor.last!.leadingZeroBitCount
    
    var v = scratch
    leftShiftKnuth(divisor, by: shift, into: &v)

    var u = remainder
    u[m] = dividend[m - 1] >> (digitWidth - shift)
    leftShiftKnuth(dividend, by: shift, into: &u)
    
    let vLast: Digit = v.last!
    let vNextToLast: Digit = v[n - 2]
    let partialDividendDelta: TwoDigits = (high: vLast, low: 0)
    var uWindow: MutableUIntBuffer

    for j in (0...(m - n)).reversed()
    {
        let jPlusN = j &+ n
        
        uWindow = u[j...jPlusN]
        let ujPlusN = uWindow[uWindow.endIndex - 1]
        let ujPlusNMinus1 = uWindow[uWindow.endIndex - 2]
        let ujPlusNMinus2 = uWindow[uWindow.endIndex - 3]

        let dividendHead: TwoDigits = (high: ujPlusN, low: ujPlusNMinus1)
        
        // These are tuple arithemtic operations.  `/%` is custom combined
        // division and remainder operator.  See TupleMath.swift
        var (q̂, r̂) = dividendHead /% vLast
        var partialProduct = q̂ * vNextToLast
        var partialDividend:TwoDigits = (high: r̂.low, low: ujPlusNMinus2)
        
        while true
        {
            if (UInt8(q̂.high != 0) | (partialProduct > partialDividend)) == 1
            {
                q̂ -= 1
                r̂ += vLast
                partialProduct -= vNextToLast
                partialDividend += partialDividendDelta
                
                if r̂.high == 0 { continue }
            }
            break
        }

        quotient[j] = q̂.low
        
        if subtractReportingBorrowKnuth(v, times: q̂.low, from: &uWindow)
        {
            quotient[j] &-= 1
            uWindow += v // digit collection addition!
        }
    }
    
    rightShiftKnuth(u[0..<n], by: shift, into: &u[0..<n])
}

// -------------------------------------
/**
 - Returns: Remainder
 */
@inline(__always)
internal func floatDivide(
    _ x: UIntBuffer,
    by y: UInt,
    result z: MutableUIntBuffer) -> UInt
{
    assert(y != 0)
    assert(x.count > 0)
    assert(z.count >= x.count)
    
    let xStart = x.baseAddress!
    var xPtr = xStart + (x.count - 1)
    let zStart = z.baseAddress!
    var zPtr = zStart + (z.count - 1)
    
    if z.count > x.count {
        zeroBuffer(z[x.endIndex..<z.endIndex])
    }
    
    var r: UInt = 0
    
    repeat
    {
        (zPtr.pointee, r) = y.dividingFullWidth((r, xPtr.pointee))
        xPtr -= 1
        zPtr -= 1
    }
    while xPtr >= xStart
    
    while zPtr >= zStart
    {
        (zPtr.pointee, r) = y.dividingFullWidth((r, 0))
        zPtr -= 1
    }
    
    return r
}


// -------------------------------------
/**
 This version is intended for use with normalized floating point significands.
 
 Divide multiprecision unsigned integer, `x`, by multiprecision unsigned
 integer, `y`, obtaining both the quotient and remainder.
 
 Implements Alogorithm D, from Donald Knuth's, *The Art of Computer Programming*
 , Volume 2,*Semi-numerical Algorithms*, Chapter 4.3.3.
 
 - Parameters:
    - dividend: The dividend stored as an unsigned multiprecision integer with
        its least signficant digit at index 0 (ie, little endian). Must have at
        least as many digits as `divisor`.
    - divisor: The divisor stored as a an unsigned multiprecision integer with
        its least signficant digit stored at index 0 (ie. little endian).
    - quotient: Buffer to receive the quotient (`x / y`).  Must be the size of
        the dividend.
    - remainder: Buffer to receive the remainder (`x % y`).  Must be the size
        of the dividend.
 */
@usableFromInline @inline(__always)
internal func floatDivide_KnuthD(
    _ dividend: UIntBuffer,
    by divisor: UIntBuffer,
    quotient: MutableUIntBuffer,
    remainder: MutableUIntBuffer)
{
    var remainder = remainder[...]
    
    typealias Digit = UInt
    typealias TwoDigits = (high: UInt, low: UInt)
    let digitWidth = Digit.bitWidth
    let m = dividend.count
    let n = divisor.count
    
    assert(n > 0, "Divisor must have at least one digit")
    assert(
        dividend.reduce(0, | ) == 0
        || dividend.last!.bit(at: digitWidth - 2),
        "Dividend not normalized, dividend.last = \(binary: dividend.last!)"
    )
    assert(!dividend.last!.bit(at: digitWidth - 1), "Dividend is negative")
    assert(divisor.reduce(0) { $0 | $1 } != 0, "Division by 0")
    assert(divisor.last!.bit(at: digitWidth - 2), "Divisor not normalized")
    assert(!divisor.last!.bit(at: digitWidth - 1), "Divisor is negative")
    assert(m >= n, "Dividend must have at least as many digits as the divisor")
    assert(quotient.count >= m,
        "Must have space for the number of digits in the dividend"
    )
    assert(
        remainder.count >= m + 1,
        "Remainder must have space for the same number of digits as the "
        + "dividend plus one"
    )

    guard n > 1 else
    {
        remainder[0] = floatDivide(
            dividend,
            by: divisor.first!,
            result: quotient
        )
        return
    }

    let v = divisor
    var u = remainder
    copy(buffer: dividend, to: u[1...])
    u[0] = 0
    
    let vLast: Digit = v.last!
    let vNextToLast: Digit = v[n - 2]
    let partialDividendDelta: TwoDigits = (high: vLast, low: 0)
    
    let quotientStart = quotient.baseAddress!
    var quotientPtr = quotientStart + (quotient.count - 1)
    var uWindow = u

    var j = u.count - n - 1
    while j >= 0
    {
        let jPlusN = j &+ n
        
        uWindow = u[j...jPlusN]
        let ujPlusN = uWindow[uWindow.endIndex - 1]
        let ujPlusNMinus1 = uWindow[uWindow.endIndex - 2]
        let ujPlusNMinus2 = uWindow[uWindow.endIndex - 3]

        let dividendHead: TwoDigits = (high: ujPlusN, low: ujPlusNMinus1)
        
        // These are tuple arithemtic operations.  `/%` is custom combined
        // division and remainder operator.  See TupleMath.swift
        var (q̂, r̂) = dividendHead /% vLast
        var partialProduct = q̂ * vNextToLast
        var partialDividend:TwoDigits = (high: r̂.low, low: ujPlusNMinus2)
        
        while true
        {
            if (UInt8(q̂.high != 0) | (partialProduct > partialDividend)) == 1
            {
                q̂ -= 1
                r̂ += vLast
                partialProduct -= vNextToLast
                partialDividend += partialDividendDelta
                
                if r̂.high == 0 { continue }
            }
            break
        }

        quotientPtr.pointee = q̂.low
        
        if subtractReportingBorrowKnuth(v, times: q̂.low, from: &uWindow)
        {
            quotientPtr.pointee &-= 1
            uWindow += v // digit collection addition!
        }
        
        quotientPtr -= 1
        j -= 1
    }
//
//    while quotientPtr >= quotientStart
//    {
//        let jPlusN = j &+ n
//        
//        uWindow = u[j...jPlusN]
//        let ujPlusN = uWindow[uWindow.endIndex - 1]
//        let ujPlusNMinus1 = uWindow[uWindow.endIndex - 2]
//        let ujPlusNMinus2 = uWindow[uWindow.endIndex - 3]
//
//        let dividendHead: TwoDigits = (high: ujPlusN, low: ujPlusNMinus1)
//        
//        // These are tuple arithemtic operations.  `/%` is custom combined
//        // division and remainder operator.  See TupleMath.swift
//        var (q̂, r̂) = dividendHead /% vLast
//        var partialProduct = q̂ * vNextToLast
//        var partialDividend:TwoDigits = (high: r̂.low, low: ujPlusNMinus2)
//        
//        while true
//        {
//            if (UInt8(q̂.high != 0) | (partialProduct > partialDividend)) == 1
//            {
//                q̂ -= 1
//                r̂ += vLast
//                partialProduct -= vNextToLast
//                partialDividend += partialDividendDelta
//                
//                if r̂.high == 0 { continue }
//            }
//            break
//        }
//
//        quotientPtr.pointee = q̂.low
//        
//        if subtractReportingBorrowKnuth(v, times: q̂.low, from: &uWindow)
//        {
//            quotientPtr.pointee &-= 1
//            uWindow += v // digit collection addition!
//        }
//        
//        quotientPtr -= 1
//        j -= 1
//    }

    // Since we require a dividend and divisor to be already normalized, we
    // don't need to denormalize the remainder
}
