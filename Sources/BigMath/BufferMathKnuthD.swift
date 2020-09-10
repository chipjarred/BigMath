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
 Subtract two `FixedWidthInteger`s, `x`, and `y`, storing the result back to
 `y`. (ie. `x -= y`)
 
 - Parameters:
    - x: The minuend and recipient of the resulting difference.
    - y: The subtrahend
 
 - Returns: Borrow out of the difference.
 */
@usableFromInline @inline(__always)
func subtractReportingBorrow<T: FixedWidthInteger>(_ x: inout T, _ y: T) -> T
{
    let b: Bool
    (x, b) = x.subtractingReportingOverflow(y)
    return T(b)
}

// -------------------------------------
/**
 Add two `FixedWidthInteger`s, `x`, and `y`, storing the result back to `x`.
 (ie. `x += y`)
 
 - Parameters:
    - x: The first addend and recipient of the resulting sum.
    - y: The second addend
 
 - Returns: Carry out of the sum.
 */
@usableFromInline @inline(__always)
func addReportingCarry<T: FixedWidthInteger>(_ x: inout T, _ y: T) -> T
{
    let c: Bool
    (x, c) = x.addingReportingOverflow(y)
    return T(c)
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
func subtractReportingBorrow<T, U>(
    _ x: T,
    times k: T.Element,
    from y: inout U) -> Bool
    where T: RandomAccessCollection,
    T.Element: FixedWidthInteger,
    T.Element.Magnitude == T.Element,
    T.Index == Int,
    U: RandomAccessCollection,
    U: MutableCollection,
    U.Element == T.Element,
    U.Index == T.Index
{
    assert(x.count + 1 <= y.count)
    
    var i = x.startIndex
    var j = y.startIndex

    var borrow: T.Element = 0
    while i < x.endIndex
    {
        borrow = subtractReportingBorrow(&y[j], borrow)
        let (pHi, pLo) = k.multipliedFullWidth(by: x[i])
        borrow &+= pHi
        borrow &+= subtractReportingBorrow(&y[j], pLo)
        
        i &+= 1
        j &+= 1
    }
    
    return 0 != subtractReportingBorrow(&y[j], borrow)
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
func += <T, U>(left: inout U, right: T )
    where T: RandomAccessCollection,
    T.Element: FixedWidthInteger,
    T.Index == Int,
    U: RandomAccessCollection,
    U: MutableCollection,
    U.Element == T.Element,
    U.Index == T.Index
{
    assert(right.count + 1 == left.count)
    var carry: T.Element = 0
    
    var i = right.startIndex
    var j = left.startIndex
    while i < right.endIndex
    {
        carry = addReportingCarry(&left[j], carry)
        carry &+= addReportingCarry(&left[j], right[i])
        
        i &+= 1
        j &+= 1
    }
    
    left[j] &+= carry
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
func leftShift<T, U>(_ x: T, by shift: Int, into y: inout U)
    where
    T: RandomAccessCollection,
    T.Element:BinaryInteger,
    T.Index == Int,
    U: RandomAccessCollection,
    U: MutableCollection,
    U.Element == T.Element,
    U.Index == T.Index
{
    assert(y.count >= x.count)
    assert(y.startIndex == x.startIndex)
    
    let bitWidth = MemoryLayout<T.Element>.size * 8
    
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
func rightShift<T, U>(_ x: T, by shift: Int, into y: inout U)
    where
    T: RandomAccessCollection,
    T.Element:BinaryInteger,
    T.Index == Int,
    U: RandomAccessCollection,
    U: MutableCollection,
    U.Element == T.Element,
    U.Index == T.Index
{
    assert(y.count == x.count)
    assert(y.startIndex == x.startIndex)
    let bitWidth = MemoryLayout<T.Element>.size * 8
    
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
func divide<T, U>(_ x: T, by y: T.Element, result z: inout U) -> T.Element
    where T: RandomAccessCollection,
    T.Element: FixedWidthInteger,
    T.Element.Magnitude == T.Element,
    T.Index == Int,
    U: RandomAccessCollection,
    U: MutableCollection,
    U.Element == T.Element,
    U.Index == T.Index
{
    assert(x.count == z.count)
    assert(x.startIndex == z.startIndex)
    
    var r: T.Element = 0
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
internal func * <T>(
    left: (high: T, low: T),
    right: T) -> (high: T, low: T)
    where T: FixedWidthInteger, T.Magnitude == T
{
    var product = left.low.multipliedFullWidth(by: right)
    let productHigh = left.high.multipliedFullWidth(by: right)
    assert(productHigh.high == 0, "multiplication overflow")
    let c = addReportingCarry(&product.high, productHigh.low)
    assert(c == 0, "multiplication overflow")
    
    return product
}

infix operator /% : MultiplicationPrecedence

// -------------------------------------
/// Divide a tuple of digits by 1 digit obtaining both quotient and remainder
@usableFromInline @inline(__always)
internal func /% <T>(
    left: (high: T, low: T),
    right: T) -> (quotient: (high: T, low: T), remainder: (high: T, low: T))
    where T: FixedWidthInteger, T.Magnitude == T
{
    var r: T
    let q: (high: T, low: T)
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
internal func > <T>(left: (high: T, low: T), right: (high: T, low: T)) -> UInt8
    where T: FixedWidthInteger, T.Magnitude == T
{
    return UInt8(left.high > right.high)
        | (UInt8(left.high == right.high) & UInt8(left.low > right.low))
}

// -------------------------------------
/// Add a digit to a tuple's low part, carrying to the high part.
@usableFromInline @inline(__always)
func += <T>(left: inout (high: T, low: T), right: T)
    where T: FixedWidthInteger, T.Magnitude == T

{
    left.high &+= addReportingCarry(&left.low, right)
}

// -------------------------------------
/// Add one tuple to another tuple
@usableFromInline @inline(__always)
func += <T>(left: inout (high: T, low: T), right: (high: T, low: T))
    where T: FixedWidthInteger, T.Magnitude == T

{
    left.high &+= addReportingCarry(&left.low, right.low)
    left.high &+= right.high
}

// -------------------------------------
/// Subtract a digit from a tuple, borrowing the high part if necessary
@usableFromInline @inline(__always)
func -= <T>(left: inout (high: T, low: T), right: T)
    where T: FixedWidthInteger, T.Magnitude == T

{
    left.high &-= subtractReportingBorrow(&left.low, right)
}


// -------------------------------------
/**
 Divide multiprecision unsigned integer, `x`, by multiprecision unsigned
 integer, `y`, obtaining both the quotient and remainder.
 
 Implements Alogorithm D, from Donald Knuth's, *The Art of Computer Programming*
 , Volume 2,*Semi-numerical Algorithms*, Chapter 4.3.3.
 
 - Note: This version of the function is super-generic, hence the long list of
 type constraints, but you can use any kind of random access collection for the
 buffers, even different ones, so long as they use the same unsigned integer
 type for digits, that it is promotable (meaning there is a larger integer size
 defined on which basic  arithmetic operations can be performend, and so long
 as the collections use `Int` as their index type.  For performance reasons,
 you probably want to specialize it for your particular collection types, in
 order to  avoid lots of generic/protocol thunking through witness tables, but
 that should only require changing the function signature.  However, it is
 declared as `public` and `@inlinable`, not becuase I expect the  compiler to
 actually inline it, but because it exposes the implementation for it create a
 specialized version for the parameters it is called with.
 
 - Parameters:
    - dividend: The dividend stored as an unsigned multiprecision integer with
        its least signficant digit at index 0 (ie, little endian). Must have at
        least as many digits as `divisor`.
    - divisor: The divisor stored as a an unsigned multiprecision integer with
        its least signficant digit stored at index 0 (ie. little endian).
    - quotient: Buffer to receive the quotient (`x / y`).  Must be the size of
        the dividend minus the size of the divisor plus one.
    - remainder: Buffer to receive the remainder (`x % y`).  Must be the size
        of the divisor.
 */
@inlinable
public func fullWidthDivide_KnuthD<T, U, V, W>(
    _ dividend: T,
    by divisor: U,
    quotient: inout V,
    remainder: inout W
)
    where
    T: RandomAccessCollection,
    T.Element: FixedWidthInteger,
    T.Element.Magnitude == T.Element,
    T.Index == Int,
    U: RandomAccessCollection,
    U.Element == T.Element,
    U.Index == T.Index,
    V: RandomAccessCollection,
    V: MutableCollection,
    V.Element == T.Element,
    V.Index == T.Index,
    W: RandomAccessCollection,
    W: MutableCollection,
    W.Element == T.Element,
    W.Index == T.Index
{
    typealias Digit = T.Element
    typealias TwoDigits = (high: T.Element, low: T.Element)
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
        remainder.count == n,
        "Remainder must have space for the same number of digits as the divisor"
    )

    guard n > 1 else
    {
        remainder[0] = divide(dividend, by: divisor.first!, result: &quotient)
        return
    }

    let shift = divisor.last!.leadingZeroBitCount
    
    var v = [Digit](repeating: 0, count: n)
    leftShift(divisor, by: shift, into: &v)

    var u = [Digit](repeating: 0, count: m + 1)
    u[m] = dividend[m - 1] >> (digitWidth - shift)
    leftShift(dividend, by: shift, into: &u)
    
    let vLast: Digit = v.last!
    let vNextToLast: Digit = v[n - 2]
    let partialDividendDelta: TwoDigits = (high: vLast, low: 0)

    for j in (0...(m - n)).reversed()
    {
        let jPlusN = j &+ n
        
        let dividendHead: TwoDigits = (high: u[jPlusN], low: u[jPlusN &- 1])
        
        // These are tuple arithemtic operations.  `/%` is custom combined
        // division and remainder operator.  See TupleMath.swift
        var (q̂, r̂) = dividendHead /% vLast
        var partialProduct = q̂ * vNextToLast
        var partialDividend:TwoDigits = (high: r̂.low, low: u[jPlusN &- 2])
        
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
        
        if subtractReportingBorrow(v[0..<n], times: q̂.low, from: &u[j...jPlusN])
        {
            quotient[j] &-= 1
            u[j...jPlusN] += v[0..<n] // digit collection addition!
        }
    }
    
    rightShift(u[0..<n], by: shift, into: &remainder)
}

// -------------------------------------
/*
 Divide multiprecision unsigned integer, `x`, by multiprecision unsigned
 integer, `y`, obtaining both the quotient and remainder.
 
 Implements Alogorithm D, from Donald Knuth's, *The Art of Computer Programming*
 , Volume 2,*Semi-numerical Algorithms*, Chapter 4.3.1.
 
 - Parameters:
    - dividend: The dividend stored as an unsigned multiprecision integer with
        its least signficant digit at index 0 (ie, little endian). Must have at
        least as many digits as `divisor`.
    - divisor: The divisor stored as a an unsigned multiprecision integer with
        its least signficant digit stored at index 0 (ie. little endian).
    - quotient: Buffer to receive the quotient (`x / y`).  Must be the size of
        the dividend minus the size of the divisor plus one.
    - remainder: Buffer to receive the remainder (`x % y`).  Must be the size
        of the dividend, plus one (this buffer is used for intermediate computatons as well).
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
    leftShift(divisor, by: shift, into: &v)

    var u = remainder
    u[m] = dividend[m - 1] >> (digitWidth - shift)
    leftShift(dividend, by: shift, into: &u)
    
    let vLast: Digit = v.last!
    let vNextToLast: Digit = v[n - 2]
    let partialDividendDelta: TwoDigits = (high: vLast, low: 0)

    for j in (0...(m - n)).reversed()
    {
        let jPlusN = j &+ n
        
        let dividendHead: TwoDigits = (high: u[jPlusN], low: u[jPlusN &- 1])
        
        // These are tuple arithemtic operations.  `/%` is custom combined
        // division and remainder operator.  See TupleMath.swift
        var (q̂, r̂) = dividendHead /% vLast
        var partialProduct = q̂ * vNextToLast
        var partialDividend:TwoDigits = (high: r̂.low, low: u[jPlusN &- 2])
        
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
        
        if subtractReportingBorrow(v[0..<n], times: q̂.low, from: &u[j...jPlusN])
        {
            quotient[j] &-= 1
            u[j...jPlusN] += v[0..<n] // digit collection addition!
        }
    }
    
    rightShift(u[0..<n], by: shift, into: &remainder)
}
