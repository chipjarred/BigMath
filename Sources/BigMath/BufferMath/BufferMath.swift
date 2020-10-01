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

import Foundation
import Async

fileprivate let uintBitWidth = MemoryLayout<UInt>.size * 8

/// Number of digits below which Karatsuba fails over to school book
internal let karatsubaCutoff = 2048 / MemoryLayout<UInt>.size
@usableFromInline internal let karatsubaAsynCutoff = 8 * karatsubaCutoff


// MARK:- Buffer comparison
// -------------------------------------
@usableFromInline @inline(__always)
internal func compareBuffers(
    _ left: UIntBuffer,
    _ right: UIntBuffer) -> ComparisonResult
{
    if UInt8(left.count == 0) & UInt8(right.count == 0) == 1 {
        return .orderedSame
    }
    
    let left = left.count == 0 ? left : significantDigits(of: left)
    let right = right.count == 0 ? right : significantDigits(of: right)
    let leftCount = left.count
    let rightCount = right.count

    guard leftCount == rightCount else
    {
        return ComparisonResult(
            rawValue: select(
                if: left.count < right.count,
                then: -1,
                else: 1
            )
        )!
    }
    
    let lStart = left.baseAddress!
    var lPtr = lStart + (leftCount - 1)
    var rPtr = right.baseAddress! + (leftCount - 1)
    
    var result: Int
    
    repeat
    {
        let l = lPtr.pointee
        let r = rPtr.pointee
        
        result = -Int(l < r) | Int(l > r)
        
        lPtr -= 1
        rPtr -= 1
    } while Int(lPtr < lStart) | result == 0
    
    assert((-1...1).contains(result))
    
    return ComparisonResult(rawValue: result)!
}

// -------------------------------------
@usableFromInline @inline(__always)
internal func compareBuffers(
    _ left: MutableUIntBuffer,
    _ right: UIntBuffer) -> ComparisonResult
{
    compareBuffers(left.immutable, right)
}

// -------------------------------------
@usableFromInline @inline(__always)
internal func compareBuffers(
    _ left: UIntBuffer,
    _ right: MutableUIntBuffer) -> ComparisonResult
{
    compareBuffers(left, right.immutable)
}

// -------------------------------------
@usableFromInline @inline(__always)
internal func compareBuffers(
    _ left: MutableUIntBuffer,
    _ right: MutableUIntBuffer) -> ComparisonResult
{
    compareBuffers(left.immutable, right.immutable)
}


// MARK:- Bitwise operations
// -------------------------------------
@usableFromInline @inline(__always)
internal func leftShift(buffer x: MutableUIntBuffer, by shift: Int)
{
    if shift == 0 { return }
    else if shift >= x.count * UInt.bitWidth
    {
        zeroBuffer(x)
        return
    }
    
    let d = fastMin(digitShift(for: shift), x.count)
    let lShift = shift & (uintBitWidth - 1)
    let rShift = uintBitWidth - lShift
    
    let xStart = x.baseAddress!
    var dstPtr = xStart.advanced(by: x.count - 1)
    var srcPtr = xStart.advanced(by: x.count - d - 1)

    var prevDigit = srcPtr.pointee
    srcPtr -= 1

    while srcPtr >= xStart
    {
        let dstDigit = prevDigit << lShift
        prevDigit = srcPtr.pointee
        dstPtr.pointee = dstDigit | (prevDigit >> rShift)

        dstPtr -= 1
        srcPtr -= 1
    }

    dstPtr.pointee = prevDigit << lShift
    dstPtr -= 1

    while dstPtr >= xStart
    {
        dstPtr.pointee = 0
        dstPtr -= 1
    }
}

// -------------------------------------
@usableFromInline @inline(__always)
internal func rightShift(
    buffer x: MutableUIntBuffer,
    by shift: Int,
    signExtend: Bool = false
)
{
    if shift == 0 { return }
    
    let signBits = select(if: signExtend, then: UInt.max, else: 0)

    if shift >= x.count * UInt.bitWidth
    {
        fillBuffer(x, with: signBits)
        return
    }
        
    let d = fastMin(digitShift(for: shift), x.count)
    let rShift = shift & (uintBitWidth - 1)
    let lShift = uintBitWidth - rShift

    var dstPtr = x.baseAddress!
    let xEnd = dstPtr + x.count
    var srcPtr = dstPtr + d
    
    var srcDigit = srcPtr.pointee
    srcPtr += 1

    while srcPtr < xEnd
    {
        let dstDigit = srcDigit >> rShift
        srcDigit = srcPtr.pointee
        dstPtr.pointee = dstDigit | (srcDigit << lShift)

        dstPtr += 1
        srcPtr += 1
    }
    
    dstPtr.pointee = (srcDigit >> rShift) | (signBits << lShift)
    dstPtr += 1

    while dstPtr < xEnd
    {
        dstPtr.pointee = signBits
        dstPtr += 1
    }
}

// -------------------------------------
@inline(__always)
fileprivate func digitShift(for shift: Int) -> Int
{
    if MemoryLayout<UInt>.size == 8 {
        return shift >> 6
    }
    else if MemoryLayout<UInt>.size == 4 {
        return shift >> 5
    }
    else { fatalError("Shouldn't get here") }
}

// -------------------------------------
@inline(__always)
fileprivate func sameBuffer(_ src: UIntBuffer, _ dst: MutableUIntBuffer) -> Bool
{
    return
        Int(bitPattern: src.baseAddress!) == Int(bitPattern: dst.baseAddress!)
}

// -------------------------------------
@usableFromInline  @inline(__always)
internal func leftShift(
    from src: UIntBuffer,
    to dst: MutableUIntBuffer,
    by shift: Int)
{
    assert(shift >= 0)
    assert(src.count > 0)
    assert(dst.count >= src.count)
        
    if shift == 0
    {
        if sameBuffer(src, dst) { return }
        copy(buffer: src, to: dst)
        fillBuffer(dst[(dst.startIndex + src.count)...], with: 0)
        return
    }
    else if shift >= src.count * UInt.bitWidth
    {
        fillBuffer(dst, with: 0)
        return
    }
    
    let d = fastMin(digitShift(for: shift), src.count)
    let lShift = shift & (uintBitWidth - 1)
    let rShift = uintBitWidth - lShift
    
    let dstBase = dst.baseAddress!
    var dstPtr = dstBase.advanced(by: dst.count - 1)
    
    if d < src.count
    {
        let srcBase = src.baseAddress!
        var srcPtr = srcBase + (src.count - d - 1)
        
        var prevDigit = srcPtr.pointee
        srcPtr -= 1
        
        while UInt8(srcPtr >= srcBase) & UInt8(dstPtr >= dstBase) == 1
        {
            let dstDigit = prevDigit << lShift
            prevDigit = srcPtr.pointee
            dstPtr.pointee = dstDigit | (prevDigit >> rShift)

            dstPtr -= 1
            srcPtr -= 1
        }
        
        dstPtr.pointee = prevDigit << lShift
        dstPtr -= 1
    }
    
    while dstPtr >= dstBase
    {
        dstPtr.pointee = 0
        dstPtr -= 1
    }
}

// -------------------------------------
@usableFromInline  @inline(__always)
internal func rightShift(
    from src: UIntBuffer,
    to dst: MutableUIntBuffer,
    by shift: Int,
    signExtend: Bool = false)
{
    assert(shift >= 0)
    assert(src.count > 0)
    assert(dst.count == src.count)
    
    let signBits = select(if: signExtend, then: UInt.max, else: 0)
    
    if shift == 0
    {
        if sameBuffer(src, dst) { return }
        copy(buffer: src, to: dst)
        fillBuffer(dst[(dst.startIndex + src.count)...], with: signBits)
        return
    }
    
    let d = fastMin(digitShift(for: shift), src.count)
    let rShift = shift & (uintBitWidth - 1)
    let lShift = uintBitWidth - rShift

    var dstPtr = dst.baseAddress!
    let dstEnd = dstPtr + dst.count
    
    if d < src.count
    {
        let srcBase = src.baseAddress!
        let srcEnd = srcBase + src.count
        var srcPtr = srcBase + d
        
        var srcDigit = srcPtr.pointee
        srcPtr += 1

        while srcPtr < srcEnd
        {
            let dstDigit = srcDigit >> rShift
            srcDigit = srcPtr.pointee
            dstPtr.pointee = dstDigit | (srcDigit << lShift)

            dstPtr += 1
            srcPtr += 1
        }
        
        dstPtr.pointee = (srcDigit >> rShift) | (signBits << lShift)
        dstPtr += 1
    }
    
    while dstPtr < dstEnd
    {
        dstPtr.pointee = signBits
        dstPtr += 1
    }
}

// -------------------------------------
@inline(__always)
fileprivate func digitAndShift(in x: UIntBuffer, forRightShift shift: Int)
    -> (digitIndex: Int, bitShift: Int)
{
    let digitIndexShift: Int =
        MemoryLayout<UInt>.size == MemoryLayout<UInt64>.size
        ? 6
        : 5

    return (
        digitIndex: x.startIndex + shift >> digitIndexShift,
        bitShift: shift & (UInt.bitWidth &- 1)
    )
}


// -------------------------------------
/**
 Computes the bit that must be added to the least signficant non-truncated
 bit of this `UIntBufer` after it is right-shifted by `shift`
 bits.
 */
@usableFromInline @inline(__always)
internal func roundingBit(forRightShift shift: Int, of x: UIntBuffer) -> UInt
{
    assert(shift >= 0)
        
    if shift > x.count * UInt.bitWidth &+ 1 { return 0 }
    
    let (digitIndex, bitShift) = digitAndShift(in: x, forRightShift: shift &- 1)
    
    /*
     IEEE 754 seems to do "bankers" rounding.
     
     The banker's rounding rule works like this: If the truncated portion
     is more than half of the value of the value of a 1 in the least
     non-truncated position, then you round up.  If it's less than half,
     you round down.  If it's exactly half then the rounding direction
     depends on the least non-truncated bit value.  If it's even, you round
     down, and if it's odd you round up.
     
     We return 0 for rounding down, and 1 for rounding up, so the rounding
     can be done by the caller by unconditionally adding our return value to
     the last significant `UInt` it performs its right-shift.
     
     If the bit immediately to the right of our least significant
     non-truncated bit is 0, then we already know truncated bits are less
     than half of a 1 in the least non-truncated bit position, which means
     round down.
     
     If that bit is 1, however, we *might* need to round up. We already
     know that it's at least half.  We have to check if it's exactly
     half, rounding up if it is more than half, and if it is exactly half,
     round up or down according to the even/odd value of the least
     non-truncated bit.
     */
    
    /*
     Get a UInt containing the least non-truncated bit and the bit
     immediately to its right as the lowest 2 bits.
     */
    let xStart = x.baseAddress!
    let xEnd = xStart + x.count
    var xPtr = xStart + (digitIndex &+ 1)
    let validXRange = xStart..<xEnd
    
    let highShift = UInt.bitWidth &- bitShift

    var digit = xPtr < xEnd ? xPtr.pointee : 0
    var shiftedDigit = digit << highShift
    xPtr -= 1
    digit = validXRange.contains(xPtr) ? xPtr.pointee : 0
    shiftedDigit |= digit >> bitShift
    
    

    /*
     Do the truncated bits form at least half of the least non-truncated bit
     position?
     
     We use 3 for our mask, because that gets bits 0 and 1.  Bit 0 is most
     significant truncated bit and bit 1 is least non-truncated.  Bit 0 tells
     us whether the truncated bits form at least half of the least sigificant
     non-truncated bit position.
     
     Given the rounding rules above, we can make a table for what to do based
     on these two bits.
     
            +-------+-------+------------------+
            | Bit 1 | Bit 0 | Meaning          |
            +-------+-------+------------------+
            |   0   |   0   | Round down       |
            |   0   |   1   | Check lower bits |
            |   1   |   0   | Round down       |
            |   1   |   1   | Round up         |
            +-------+-------+------------------+
     
     So the only time we need to do the O(n) check for the lower bits is when
     bits 1 is 0 and bit 0 is 1... in other words when the lower two bits
     combine to form the value 1.  That's what the guard statement below tests.
     If these two bits do *not* form the value 1, then only time we round up is
     when they are both 1, which makes their combined value 3, which is what
     the return in the guard statement's else clause takes care of.
     
     The code after the guard statement does the check of the lower bits.
     */
    
    #if false
    // Slow but readable
    switch shiftedDigit & 0b11
    {
        case 0b00: return 0
        case 0b01: break
        case 0b10: return 0
        case 0b11: return 1
        default: fatalError("Unreachable")
    }
    #else
    // Fast but cryptic
    guard shiftedDigit & 0b11 == 0b01 else {
        return UInt(shiftedDigit & 0b11 == 0b11)
    }
    #endif

    // We have to check lower bits
    var accumulatedBits: UInt = digit << highShift
    xPtr -= 1
    
    while UInt8(xPtr >= xStart) & UInt8(accumulatedBits == 0) == 1
    {
        accumulatedBits |= xPtr.pointee
        xPtr -= 1
    }

    // round up if there were lower 1 bits; otherwise, round down
    return UInt(accumulatedBits != 0)
}

// -------------------------------------
/**
 - Returns: a `UInt` containing rounding information about the bits in `x` that
    would be shifted out as a result of applying a right shift of `shift` bits.
    The information is contained in the two least significant bits:
 
    - Bit 1 is known as the "guard" bit, and contains the most significant
        shifted out bit.
    - Bit 0 is the "sticky" bit, and is `0` only if *all* of the other
        shifted-out bits are `0`.  If any of the other shifted-out bits are `1`
        , bit 0 is set to `1` if *any* of the bits lower than the guard bit are
        `1`, then the sticky bit is `1`, which is how it gets it's name.  Once
        it's 1, its value "sticks" to `1`.
    
    This information is useful for applying bankers' rounding after an
    arithmetic operation.  If bit 1 is `0`, then round the result down.
    If bit 1 is `1`, then bit 0 is used to determine whether or not to round up
    based for an even non-truncated bit.
 */
@usableFromInline @inline(__always)
internal func guardAndStickyBits(forRightShift shift: Int, of x: UIntBuffer) -> UInt
{
    assert(shift >= 0)
            
    if shift > x.count * UInt.bitWidth &+ 1 { return 0 }
    
    let (digitIndex, bitShift) = digitAndShift(in: x, forRightShift: shift &- 1)
    
    let xStart = x.baseAddress!
    let xEnd = xStart + x.count
    var xPtr = xStart + (digitIndex &+ 1)
    let validXRange = xStart..<xEnd
    
    let highShift = UInt.bitWidth &- bitShift

    var digit = xPtr < xEnd ? xPtr.pointee : 0
    var shiftedDigit = digit << highShift
    xPtr -= 1
    digit = validXRange.contains(xPtr) ? xPtr.pointee : 0
    shiftedDigit |= digit >> bitShift
    
    let guardBit = (shiftedDigit & 1) << 1
    
    /*
     If we could assume that the right-shift for which we're currently
     calculating guard and sticky bits is the only shift to be applied, we
     could skip the O(n)  check if the lower bits below when we know that the
     guard bit (result bit 1) is 0. But if more shifts might be applied (for
     example, making room for a carry out of a floating point significand's
     high bit resulting from addition), those shifts will compute a new guard
     bit, and then our lower bits will matter for rounding.  The upshot of
     which is we can't skip checking the lower bits.
     */

    // Calculate sticky bit
    var accumulatedBits: UInt = digit << highShift
    xPtr -= 1
    
    while UInt8(xPtr >= xStart) & UInt8(accumulatedBits == 0) == 1
    {
        accumulatedBits |= xPtr.pointee
        xPtr -= 1
    }

    // round up if there were lower 1 bits; otherwise, round down
    return guardBit | UInt(accumulatedBits != 0)
}

// -------------------------------------
/*
 - Returns: a `UInt` containing rounding information about the bits in `x` that
    would be shifted out as a result of applying a right shift of `shift` bits.
    The information is contained in the three least significant bits:
 
    - Bit 2 is known as the "guard" bit, and contains the most significant
        shifted out bit.
    - Bit 1 is the "round bit".  It contains the second most significant
        significant shifted-out bit
    - Bit 0 is the "sticky" bit, and is `0` only if *all* of the other
        shifted-out bits lower than the round bit are `0`.  If any of the other
        shifted-out bits are `1`, bit 0 is set to `1` if *any* of the bits
        lower than the guard bit are `1`, then the sticky bit is `1`, which is
        how it gets it's name.  Once it's 1, its value "sticks" to `1`.
    
    This information is useful for applying bankers' rounding after an
    subtraction operation.  Bit 2 is the bit that can be shifted into the least
    significant dividend when the difference is left shifted in normalization.
    If bit 1 is `0`, then round the result down. If bit 1 is `1`, then bit 0 is
    used to determine whether or not to round up based for an even
    non-truncated bit.
 
    This method is similar to guardAndStickBits(forRightShift: of:), but
    contains three bits instead of two, which is needed for subtraction.
 */
@usableFromInline @inline(__always)
internal func guardRoundAndStickyBits(
    forRightShift shift: Int,
    of x: UIntBuffer) -> UInt
{
    assert(shift >= 0)
            
    let xWidth = x.count * UInt.bitWidth
    if shift > xWidth &+ 1 { return 0 }
    
    let (digitIndex, bitShift) = digitAndShift(in: x, forRightShift: shift &- 2)
    
    let xStart = x.baseAddress!
    let xEnd = xStart + x.count
    var xPtr = xStart + (digitIndex &+ 1)
    let validXRange = xStart..<xEnd
    
    let highShift = UInt.bitWidth &- bitShift

    var digit = xPtr < xEnd ? xPtr.pointee : 0
    var shiftedDigit = digit << highShift
    xPtr -= 1
    digit = validXRange.contains(xPtr) ? xPtr.pointee : 0
    shiftedDigit |= digit >> bitShift
    
    let guardBit = (shiftedDigit & 3) << 1
    
    // Calculate sticky bit
    var accumulatedBits: UInt = digit << highShift
    xPtr -= 1
    
    while UInt8(xPtr >= xStart) & UInt8(accumulatedBits == 0) == 1
    {
        accumulatedBits |= xPtr.pointee
        xPtr -= 1
    }

    // round up if there were lower 1 bits; otherwise, round down
    return guardBit | UInt(accumulatedBits != 0)
}

// -------------------------------------
/**
 Performs right shift, but rounds the non-truncated bits based on the
 shifted-out bits using "bankers'" rounding.  The ordinary right-shift simply
 shifts out the truncated bits.
 */
@usableFromInline @inline(__always)
internal func roundingRightShift(
    buffer x: MutableUIntBuffer,
    by shift: Int)
{
    assert(shift >= 0)
    if shift == 0 { return }
    
    let rBit = roundingBit(forRightShift: shift, of: x.immutable)
    
    rightShift(buffer: x,  by: shift)

    // Now we do the rounding
    if rBit != 0 { _ = addReportingCarry(x.immutable, 1, result: x) }
}

// -------------------------------------
/**
 Performs right shift, but rounds the non-truncated bits based on the
 shifted-out bits using "bankers'" rounding.  The ordinary right-shift simply
 shifts out the truncated bits.
 */
@usableFromInline @inline(__always)
internal func roundingRightShift(
    from x: UIntBuffer,
    to y: MutableUIntBuffer,
    by shift: Int)
{
    assert(shift >= 0)
    
    let rBit = roundingBit(forRightShift: shift, of: x)
    
    rightShift(from: x, to: y,  by: shift)

    // Now we do the rounding
    if rBit != 0 { _ = addReportingCarry(x, 1, result: y) }
}

// -------------------------------------
@usableFromInline @inline(__always)
internal func bitwiseAnd(
    _ x: UIntBuffer,
    _ y: UIntBuffer,
    to z: MutableUIntBuffer)
{
    assert(x.count > 0)
    assert(y.count > 0)
    assert(z.count == x.count)
    
    var xPtr = x.baseAddress!
    let xEnd = xPtr + x.count
    var yPtr = y.baseAddress!
    var zPtr = z.baseAddress!
    
    repeat
    {
        zPtr.pointee = xPtr.pointee & yPtr.pointee
        xPtr += 1
        yPtr += 1
        zPtr += 1
    } while xPtr < xEnd
}

// -------------------------------------
@usableFromInline @inline(__always)
internal func bitwiseOr(
    _ x: UIntBuffer,
    _ y: UIntBuffer,
    to z: MutableUIntBuffer)
{
    assert(x.count > 0)
    assert(y.count > 0)
    assert(z.count == x.count)
    
    var xPtr = x.baseAddress!
    let xEnd = xPtr + x.count
    var yPtr = y.baseAddress!
    var zPtr = z.baseAddress!
    
    repeat
    {
        zPtr.pointee = xPtr.pointee | yPtr.pointee
        xPtr += 1
        yPtr += 1
        zPtr += 1
    } while xPtr < xEnd
}

// -------------------------------------
@usableFromInline @inline(__always)
internal func bitwiseXOr(
    _ x: UIntBuffer,
    _ y: UIntBuffer,
    to z: MutableUIntBuffer)
{
    assert(x.count > 0)
    assert(y.count > 0)
    assert(z.count == x.count)
    
    var xPtr = x.baseAddress!
    let xEnd = xPtr + x.count
    var yPtr = y.baseAddress!
    var zPtr = z.baseAddress!
    
    repeat
    {
        zPtr.pointee = xPtr.pointee ^ yPtr.pointee
        xPtr += 1
        yPtr += 1
        zPtr += 1
    } while xPtr < xEnd
}

// -------------------------------------
@usableFromInline @inline(__always)
internal func bitwiseComplement(
    _ x: UIntBuffer,
    to y: MutableUIntBuffer)
{
    assert(x.count > 0)
    assert(y.count == x.count)
    
    var xPtr = x.baseAddress!
    let xEnd = xPtr + x.count
    var yPtr = y.baseAddress!
    
    repeat
    {
        yPtr.pointee = ~xPtr.pointee
        xPtr += 1
        yPtr += 1
    } while xPtr < xEnd
}

// -------------------------------------
@usableFromInline @inline(__always)
internal func countLeadingZeroBits(_ x: UIntBuffer) -> Int
{
    var result = 0
    
    for digit in x.reversed()
    {
        let curLeadingZeros = digit.leadingZeroBitCount
        result &+= curLeadingZeros
        guard curLeadingZeros == UInt.bitWidth else { break }
    }
    
    return result
}

// -------------------------------------
@usableFromInline @inline(__always)
internal func countTrailingZeroBits(_ x: UIntBuffer) -> Int
{
    var result = 0
    
    for digit in x
    {
        let curTrailingZeros = digit.trailingZeroBitCount
        result &+= curTrailingZeros
        guard curTrailingZeros == UInt.bitWidth else { break }
    }
    
    return result
}

// -------------------------------------
@usableFromInline @inline(__always)
internal func countNonzeroBits(_ x: UIntBuffer) -> Int
{
    var result = 0
    
    for digit in x {
        result &+= digit.nonzeroBitCount
    }
    
    return result
}

// MARK:- Arithmetic operations
// -------------------------------------
/// Two's complement arithmetic negation
@usableFromInline @inline(__always)
internal func arithmeticNegate(
    _ x: UIntBuffer,
    to y: MutableUIntBuffer)
{
    assert(x.count > 0)
    assert(y.count == x.count)
    
    var xPtr = x.baseAddress!
    let xEnd = xPtr + x.count
    var yPtr = y.baseAddress!
    
    var carry: UInt = 1
    repeat
    {
        (yPtr.pointee, carry) = (~xPtr.pointee).addingReportingCarry(carry)
        xPtr += 1
        yPtr += 1
    } while xPtr < xEnd
}

// MARK:- Addition
// -------------------------------------
@usableFromInline @inline(__always)
internal func addReportingCarry(
    _ x: UIntBuffer,
    _ y: UIntBuffer,
    carryIn: UInt = 0,
    result z: MutableUIntBuffer) -> UInt
{
    assert(x.count > 0)
    assert(y.count > 0)
    assert(z.count == fastMax(x.count, y.count))
    
    var xPtr = x.baseAddress!
    let xEnd = xPtr + x.count
    let commonEnd = xPtr + fastMin(x.count, y.count)
    var yPtr = y.baseAddress!
    let yEnd = yPtr + y.count
    var zPtr = z.baseAddress!
    let zEnd = zPtr + z.count

    var carry = carryIn
    
    repeat
    {
        // To allow x or y to alias z, compute the sum in a local variable
        // before storing it in z
        var sum: UInt
        (sum, carry) = xPtr.pointee.addingReportingCarry(carry)
        carry &+= sum.addToSelfReportingCarry(yPtr.pointee)
        zPtr.pointee = sum
        xPtr += 1
        yPtr += 1
        zPtr += 1
    } while xPtr < commonEnd
    
    while xPtr < xEnd
    {
        var sum: UInt
        (sum, carry) = xPtr.pointee.addingReportingCarry(carry)
        zPtr.pointee = sum
        xPtr += 1
        zPtr += 1
    }
    
    while yPtr < yEnd
    {
        var sum: UInt
        (sum, carry) = yPtr.pointee.addingReportingCarry(carry)
        zPtr.pointee = sum
        yPtr += 1
        zPtr += 1
    }
    
    if zPtr < zEnd
    {
        zPtr.pointee = carry
        carry = 0
        zPtr += 1
        
        while zPtr < zEnd {
            zPtr.pointee = 0
            zPtr += 1
        }
    }


    return carry
}


// -------------------------------------
@usableFromInline @inline(__always)
internal func addReportingCarry(
    _ x: UIntBuffer,
    _ y: UInt,
    result z: MutableUIntBuffer) -> UInt
{
    assert(x.count > 0)
    assert(z.count == x.count)
    
    var xPtr = x.baseAddress!
    let xEnd = xPtr + x.count
    var zPtr = z.baseAddress!

    var carry = y
    
    repeat
    {
        (zPtr.pointee, carry) = xPtr.pointee.addingReportingCarry(carry)
        xPtr += 1
        zPtr += 1
    } while xPtr < xEnd

    return carry
}

// MARK:- Subtraction
// -------------------------------------
@usableFromInline @inline(__always)
internal func subtractReportingBorrow(
    _ x: UIntBuffer,
    _ y: UIntBuffer,
    borrowIn: UInt = 0,
    result z: MutableUIntBuffer) -> UInt
{
    assert(x.count > 0)
    assert(y.count > 0)
    assert(z.count == max(x.count, y.count))
    
    var xPtr = x.baseAddress!
    let xEnd = xPtr + x.count
    let commonEnd = xPtr + fastMin(x.count, y.count)
    var yPtr = y.baseAddress!
    let yEnd = yPtr + y.count
    var zPtr = z.baseAddress!
    let zEnd = zPtr + z.count

    var borrow = borrowIn
    
    repeat
    {
        assert(zPtr < zEnd)
        // To allow x or y to alias z, compute the difference in a local
        // variable before storing it in z
        var difference: UInt
        (difference, borrow) = xPtr.pointee.subtractingReportingBorrow(borrow)
        borrow &+= difference.subtractFromSelfReportingBorrow(yPtr.pointee)
        zPtr.pointee = difference
        xPtr += 1
        yPtr += 1
        zPtr += 1
    } while xPtr < commonEnd
    
    while xPtr < xEnd
    {
        assert(zPtr < zEnd)
        (zPtr.pointee, borrow) = xPtr.pointee.subtractingReportingBorrow(borrow)
        xPtr += 1
        zPtr += 1
    }
    
    while yPtr < yEnd
    {
        assert(zPtr < zEnd)
        let zP: UInt
        (zP, borrow) = yPtr.pointee.subtractingReportingBorrow(borrow)
        zPtr.pointee = zP
        yPtr += 1
        zPtr += 1
    }
    
    if zPtr < zEnd
    {
        zPtr.pointee = 0 &- borrow
        borrow = 0
        zPtr += 1
        
        while zPtr < zEnd {
            zPtr.pointee = 0
            zPtr += 1
        }
    }

    return borrow
}

// -------------------------------------
@usableFromInline @inline(__always)
internal func subtractReportingBorrow(
    _ x: UIntBuffer,
    _ y: UInt,
    result z: MutableUIntBuffer) -> UInt
{
    assert(x.count > 0)
    assert(z.count == x.count)
    
    var xPtr = x.baseAddress!
    let xEnd = xPtr + x.count
    var zPtr = z.baseAddress!

    var borrow = y
    
    repeat
    {
        // To allow x or y to alias z, compute the difference in a local
        // variable before storing it in z
        (zPtr.pointee, borrow) = xPtr.pointee.subtractingReportingBorrow(borrow)
        xPtr += 1
        zPtr += 1
    } while xPtr < xEnd

    return borrow
}

// MARK:- Multiplication
// -------------------------------------
/**
 Performs full width muliplication of the multiprecision numbers stored in
 `xBuf` and `yBuf` placing the results in `zBuf`
 
 Implements the "school book" algorithm
 
 - Parameters:
    - xBuf: first muliplicand stored with least signficant `UInt` "digit"
        at index 0 (little endian)
    - yBuf: second muliplicand stored with least signficant `UInt` "digit"
        at index 0 (little endian)
    - zBuf: result buffer.  It's size must be the sum of the sizes of
        `xBuf` and `yBuf`.
    - needToZeroResult: Set to `true` if `zBuf` is not already zeroed.
        Defaults to `false`.  When set to `true`, only the portions of `zBuf` that need to be zeroed
        to guarantee a correct product will be zeroed.
 */
@usableFromInline @inline(__always)
internal func fullMultiplyBuffers_SchoolBook(
    _ xBuf: UIntBuffer,
    _ yBuf: UIntBuffer,
    result zBuf: MutableUIntBuffer,
    needToZeroResult: Bool = false)
{
    assert(xBuf.count > 0, "xBuf: empty buffer")
    assert(yBuf.count > 0, "yBuf: empty buffer")
    assert(zBuf.count == xBuf.count+yBuf.count, "Result buffer: wrong size")
    assert(
        needToZeroResult || 0 == zBuf.reduce(0) { $0 | $1 },
        "Result buffer: not zeroed"
    )
    
    var carry: UInt = 0
    
    var xPtr = xBuf.baseAddress!
    let xEnd = xPtr + xBuf.count
    let yEnd = yBuf.baseAddress! + yBuf.count
    var zNext = zBuf.baseAddress!
    var zPtr = zNext
    let zEnd = zPtr + zBuf.count

    if needToZeroResult
    {
        /*
         To save time, we zero just the part of zBuf where the first partial
         product will go.  The carries out of high position in each partial
         product overwrite the next position, which essentially takes care of
         initializing the rest of zBuf as the multiplication progresses.
         */
        let headEnd = zBuf.startIndex + max(xBuf.count, yBuf.count)
        zeroBuffer(zBuf[..<headEnd])
    }
    
    repeat
    {
        let x = xPtr.pointee
        zPtr = zNext

        var yPtr = yBuf.baseAddress!
        repeat
        {
            let (overflow, p) = x.multipliedFullWidth(by: yPtr.pointee)
            carry = zPtr.pointee.addToSelfReportingCarry(carry)
            carry &+= zPtr.pointee.addToSelfReportingCarry(p)
            carry &+= overflow
            zPtr += 1
            yPtr += 1
        }
        while yPtr < yEnd
        
        zPtr.pointee = carry
        carry = 0

        xPtr += 1
        zNext += 1
    }
    while xPtr < xEnd
    
    zPtr += 1
    while zPtr < zEnd
    {
        zPtr.pointee = 0
        zPtr += 1
    }
}

// -------------------------------------
/**
 Full width multiplication using the Karatsuba algorithm.  This method needs
 space for intermediate computation, and rather than dynamically allocate it as
 we go, which is slow, and takes up more memory the deeper the recursion goes,
 we pass in mutable, pre-allocated buffers that are reused through the  recursion.
 
 - Parameters:
    - xBuf: first muliplicand stored with least signficant `UInt` "digit"
        at index 0 (little endian)
    - yBuf: second muliplicand stored with least signficant `UInt` "digit"
        at index 0 (little endian).  Must be the same size as `xBuf`.
    - scratch1: scratch buffer for internal computation.  Must be the same
        size as `xBuf`.
    - scratch2: scratch buffer for internal computation.  Must be the same
        size as `xBuf`.
    - scratch3: scratch buffer for internal computation.  Must be the twice the
        size as `xBuf`.
    - zBuf: result buffer.  It's size must be the sum of the sizes of
        `xBuf` and `yBuf` (ie. twice the size of `xBuf`).
 */
@usableFromInline
internal func fullMultiplyBuffers_Karatsuba(
    _ xBuf: UIntBuffer,
    _ yBuf: UIntBuffer,
    scratch1: MutableUIntBuffer,
    scratch2: MutableUIntBuffer,
    scratch3: MutableUIntBuffer,
    result zBuf: MutableUIntBuffer,
    forceUse: Bool)
{
    assert(xBuf.count == yBuf.count)
    assert(xBuf.count == scratch1.count)
    assert(xBuf.count == scratch2.count)
    assert(xBuf.count * 2 == scratch3.count)
    assert(xBuf.count * 2 == zBuf.count)
    
    let differences = scratch1
    let middleTerm = scratch2
    let middleProduct = scratch3.low
    let extraScratch = scratch3.high
    
    let forceUse =
        UInt(forceUse) & UInt(bitPattern: ((xBuf.count & 1) ^ 1)) == 1

    guard xBuf.count > karatsubaCutoff || forceUse else
    {
        fullMultiplyBuffers_SchoolBook(
            xBuf,
            yBuf,
            result: zBuf,
            needToZeroResult: true
        )
        return
    }
    
    fullMultiplyBuffers_Karatsuba(
        xBuf.low,
        yBuf.low,
        scratch1: differences.low,
        scratch2: differences.high,
        scratch3: middleTerm,
        result: zBuf.low,
        forceUse: forceUse
    )
    
    fullMultiplyBuffers_Karatsuba(
        xBuf.high,
        yBuf.high,
        scratch1: differences.low,
        scratch2: differences.high,
        scratch3: middleTerm,
        result: zBuf.high,
        forceUse: forceUse
    )

    let sign1 = compareBuffers(xBuf.high, xBuf.low) == .orderedDescending
    let sign2 = compareBuffers(yBuf.low, yBuf.high) == .orderedDescending
    
    if sign1
    {
        _ = subtractReportingBorrow(
            xBuf.high,
            xBuf.low,
            result: differences.low
        )
    }
    else
    {
        _ = subtractReportingBorrow(
            xBuf.low,
            xBuf.high,
            result: differences.low
        )
    }
    
    if sign2
    {
        _ = subtractReportingBorrow(
            yBuf.low,
            yBuf.high,
            result: differences.high
        )
    }
    else
    {
        _ = subtractReportingBorrow(
            yBuf.high,
            yBuf.low,
            result: differences.high
        )
    }

    fullMultiplyBuffers_Karatsuba(
        differences.low.immutable,
        differences.high.immutable,
        scratch1: middleTerm.low,
        scratch2: middleTerm.high,
        scratch3: extraScratch,
        result: middleProduct,
        forceUse: forceUse
    )
    
    var carry = addReportingCarry(
        zBuf.low.immutable,
        zBuf.high.immutable,
        result: middleTerm
    )
    

    if sign1 == sign2
    {
        carry &+= addReportingCarry(
            middleTerm.immutable,
            middleProduct.immutable,
            result: middleTerm
        )
    }
    else {
        carry &-= subtractReportingBorrow(
            middleTerm.immutable,
            middleProduct.immutable,
            result: middleTerm
        )
    }
    
    let c = addReportingCarry(
        zBuf.low.high.immutable,
        middleTerm.low.immutable,
        result: zBuf.low.high
    )
    
    carry &+= addReportingCarry(
        zBuf.high.low.immutable,
        c,
        result: zBuf.high.low
    )
    
    carry &+= addReportingCarry(
        zBuf.high.low.immutable,
        middleTerm.high.immutable,
        result: zBuf.high.low
    )
    
    _ = addReportingCarry(
        zBuf.high.high.immutable,
        carry,
        result: zBuf.high.high
    )
}

// -------------------------------------
/**
 Full width multiplication using the Karatsuba algorithm.  This method needs
 space for intermediate computation, and rather than dynamically allocate it as
 we go, which is slow, and takes up more memory the deeper the recursion goes,
 we pass in mutable, pre-allocated buffers that are reused through the  recursion.
 
 - Parameters:
    - xBuf: first muliplicand stored with least signficant `UInt` "digit"
        at index 0 (little endian)
    - yBuf: second muliplicand stored with least signficant `UInt` "digit"
        at index 0 (little endian).  Must be the same size as `xBuf`.
    - scratch1: scratch buffer for internal computation.  Must be the same
        size as `xBuf`.
    - scratch2: scratch buffer for internal computation.  Must be the same
        size as `xBuf`.
    - scratch3: scratch buffer for internal computation.  Must be the twice the
        size as `xBuf`.
    - zBuf: result buffer.  It's size must be the sum of the sizes of
        `xBuf` and `yBuf` (ie. twice the size of `xBuf`).
 */
@usableFromInline
internal func fullMultiplyBuffers_Karatsuba_Async(
    _ xBuf: UIntBuffer,
    _ yBuf: UIntBuffer,
    scratch1: MutableUIntBuffer,
    scratch2: MutableUIntBuffer,
    scratch3: MutableUIntBuffer,
    scratch4: MutableUIntBuffer,
    scratch5: MutableUIntBuffer,
    result zBuf: MutableUIntBuffer,
    forceUse: Bool)
{
    assert(xBuf.count == yBuf.count)
    assert(xBuf.count == scratch1.count)
    assert(xBuf.count == scratch2.count)
    assert(xBuf.count * 2 == scratch3.count)
    assert(xBuf.count == scratch4.count)
    assert(xBuf.count * 2 == scratch5.count)
    assert(xBuf.count * 2 == zBuf.count)
    
    let forceUse =
        UInt(forceUse) & UInt(bitPattern: ((xBuf.count & 1) ^ 1)) == 1

    guard xBuf.count > karatsubaAsynCutoff || forceUse
    else
    {
        guard xBuf.count > karatsubaCutoff else
        {
            fullMultiplyBuffers_SchoolBook(
                xBuf,
                yBuf,
                result: zBuf,
                needToZeroResult: true
            )
            return
        }
        
        fullMultiplyBuffers_Karatsuba(
            xBuf,
            yBuf,
            scratch1: scratch1,
            scratch2: scratch2,
            scratch3: scratch3,
            result: zBuf,
            forceUse: false
        )
        return
    }
    
    let future1 = async
    {
        fullMultiplyBuffers_Karatsuba_Async(
            xBuf.low,
            yBuf.low,
            scratch1: scratch1.low,
            scratch2: scratch1.high,
            scratch3: scratch2,
            scratch4: scratch3.low.low,
            scratch5: scratch3.high,
            result: zBuf.low,
            forceUse: forceUse
        )
    }
    
    fullMultiplyBuffers_Karatsuba_Async(
        xBuf.high,
        yBuf.high,
        scratch1: scratch3.low.high,
        scratch2: scratch4.low,
        scratch3: scratch5.low,
        scratch4: scratch4.high,
        scratch5: scratch5.high,
        result: zBuf.high,
        forceUse: forceUse
    )
    
    future1.wait()

    let sign1 = compareBuffers(xBuf.high, xBuf.low) == .orderedDescending
    let sign2 = compareBuffers(yBuf.low, yBuf.high) == .orderedDescending
    
    if sign1
    {
        _ = subtractReportingBorrow(
            xBuf.high,
            xBuf.low,
            result: scratch1.low
        )
    }
    else
    {
        _ = subtractReportingBorrow(
            xBuf.low,
            xBuf.high,
            result: scratch1.low
        )
    }
    
    if sign2
    {
        _ = subtractReportingBorrow(
            yBuf.low,
            yBuf.high,
            result: scratch1.high
        )
    }
    else
    {
        _ = subtractReportingBorrow(
            yBuf.high,
            yBuf.low,
            result: scratch1.high
        )
    }

    fullMultiplyBuffers_Karatsuba_Async(
        scratch1.low.immutable,
        scratch1.high.immutable,
        scratch1: scratch2.low,
        scratch2: scratch2.high,
        scratch3: scratch3.high,
        scratch4: scratch4.low,
        scratch5: scratch5.low,
        result: scratch3.low,
        forceUse: forceUse
    )
    
    var carry = addReportingCarry(
        zBuf.low.immutable,
        zBuf.high.immutable,
        result: scratch2
    )
    

    if sign1 == sign2
    {
        carry &+= addReportingCarry(
            scratch2.immutable,
            scratch3.low.immutable,
            result: scratch2
        )
    }
    else {
        carry &-= subtractReportingBorrow(
            scratch2.immutable,
            scratch3.low.immutable,
            result: scratch2
        )
    }
    
    let c = addReportingCarry(
        zBuf.low.high.immutable,
        scratch2.low.immutable,
        result: zBuf.low.high
    )
    
    carry &+= addReportingCarry(
        zBuf.high.low.immutable,
        c,
        result: zBuf.high.low
    )
    
    carry &+= addReportingCarry(
        zBuf.high.low.immutable,
        scratch2.high.immutable,
        result: zBuf.high.low
    )
    
    _ = addReportingCarry(
        zBuf.high.high.immutable,
        carry,
        result: zBuf.high.high
    )
}

// -------------------------------------
/**
 Performs  muliplication of the multiprecision numbers stored in
 `xBuf` and `yBuf` placing the lower half of the full width product in `zBuf`
 
 Implements the "school book" algorithm
 
 - Parameters:
    - xBuf: first muliplicand stored with least signficant `UInt` "digit"
        at index 0 (little endian).  Must be the shorter of the two
        multiplicand buffers if they are of different lengths
    - yBuf: second muliplicand stored with least signficant `UInt` "digit"
        at index 0 (little endian).  Must be the longer of the two
        multiplicand buffers if they are of different lengths.
    - zBuf: result buffer.  It's size must be the same size as `yBuf`.
 
 - Returns: `true` if the multiplication overflows `zBuf`; otherwise `false`.
 */
@usableFromInline @inline(__always)
internal func lowerHalfMuliplyBuffers_SchoolBook(
    _ xBuf: UIntBuffer,
    _ yBuf: UIntBuffer,
    result zBuf: inout MutableUIntBuffer) -> Bool
{
    assert(xBuf.count > 0, "xBuf: empty buffer")
    assert(yBuf.count > 0, "yBuf: empty buffer")
    assert(xBuf.count <= yBuf.count, "Buffers are in the wrong order")
    assert(
        zBuf.count == Swift.max(xBuf.count, yBuf.count),
        "Result buffer: wrong size"
    )
    assert(0 == zBuf.reduce(0) { $0 | $1 }, "Result buffer: not zeroed")
    
    var carry: UInt = 0
    var overflow: UInt = 0
    
    var i = xBuf.startIndex
    repeat
    {
        let x = xBuf[i]
        var k = i

        var j = yBuf.startIndex
        let jMax = yBuf.endIndex - i
        while j < jMax
        {
            let (overflow, p) = x.multipliedFullWidth(by: yBuf[j])
            carry = zBuf[k].addToSelfReportingCarry(carry)
            carry &+= zBuf[k].addToSelfReportingCarry(p)
            carry &+= overflow
            k += 1
            j += 1
        }
        
        overflow |= carry

        while j < yBuf.endIndex && overflow == 0
        {
            overflow |= UInt(x != 0) | UInt(yBuf[j] != 0)
            j += 1
        }
        
        carry = 0
        i += 1
    } while i < xBuf.endIndex && overflow == 0
    
    while i < xBuf.endIndex
    {
        let x = xBuf[i]
        var k = i

        for j in 0..<(yBuf.endIndex - i)
        {
            let p: UInt
            (overflow, p) = x.multipliedFullWidth(by: yBuf[j])
            carry = zBuf[k].addToSelfReportingCarry(carry)
            carry &+= zBuf[k].addToSelfReportingCarry(p)
            carry &+= overflow
            k += 1
        }
        
        carry = 0
        i += 1
    }

    return overflow != 0
}

// -------------------------------------
/**
 Performs  muliplication of the multiprecision number stored in
 `xBuf` by the `UInt` `yBuf` placing the lower half of the full width product
 in `zBuf`
 
 - Parameters:
    - xBuf: first muliplicand stored with least signficant `UInt` "digit"
        at index 0 (little endian).
    - y: second multiplicand as a `UInt` "digit"
    - zBuf: result buffer.  It's size must be at least as large as `xBuf`.
 
 - Returns: `true` if the multiplication overflows `zBuf`; otherwise `false`.
 */
@usableFromInline @inline(__always)
internal func multiply(
    buffer xBuf: UIntBuffer,
    by y: UInt,
    result zBuf: MutableUIntBuffer) -> Bool
{
    return 0 != multiplyAdd(buffer: xBuf, times: y, plus: 0, result: zBuf)
}

// -------------------------------------
/**
 Fused multiply-add of a `UInt` to a buffer times a `UInt`
 */
@usableFromInline @inline(__always)
internal func multiplyAdd(
    buffer xBuf: UIntBuffer,
    times k: UInt,
    plus y: UInt,
    result zBuf: MutableUIntBuffer) -> UInt
{
    assert(xBuf.count > 0, "xBuf: empty buffer")
    assert(zBuf.count >= xBuf.count, "Result buffer: too small")
    
    var carry: UInt = y
    
    var xPtr = xBuf.baseAddress!
    let xEnd = xPtr + xBuf.count
    var zPtr = zBuf.baseAddress!
    let zEnd = zPtr + zBuf.count
    
    repeat
    {
        let overflow: UInt
        (overflow, zPtr.pointee) = xPtr.pointee.multipliedFullWidth(by: k)
        carry = zPtr.pointee.addToSelfReportingCarry(carry)
        carry &+= overflow
        
        xPtr += 1
        zPtr += 1
    } while xPtr < xEnd

    if zPtr < zEnd {
        zPtr.pointee = carry
        carry = 0
        zPtr += 1
        while zPtr < zEnd {
            zPtr.pointee = 0
            zPtr += 1
        }
    }
    
    return carry
}

// -------------------------------------
/**
 Performs  fused multiply-add of a buffer times `UInt` plus a buffer.
 */
@usableFromInline @inline(__always)
internal func multiplyAdd(
    buffer xBuf: UIntBuffer,
    times k: UInt,
    plus yBuf: UIntBuffer,
    result zBuf: MutableUIntBuffer) -> UInt
{
    assert(yBuf.count > 0, "xBuf: empty buffer")
    assert(xBuf.count > 0, "yBuf: empty buffer")
    assert(
        zBuf.count >= max(yBuf.count, xBuf.count),
        "Result buffer: too small"
    )
    
    var carry: UInt = 0
    
    var xPtr = xBuf.baseAddress!
    let xEnd = xPtr + xBuf.count
    var yPtr = yBuf.baseAddress!
    let yEnd = yPtr + yBuf.count
    var zPtr = zBuf.baseAddress!
    let zEnd = zPtr + zBuf.count
    let commonCount = min(yBuf.count, xBuf.count)
    let commonEnd = yPtr + commonCount

    repeat
    {
        var zVal = carry
        let p: UInt
        (carry, p) = xPtr.pointee.multipliedFullWidth(by: k)
        carry &+= zVal.addToSelfReportingCarry(p)
        carry &+= zVal.addToSelfReportingCarry(yPtr.pointee)
        zPtr.pointee = zVal
        
        yPtr += 1
        xPtr += 1
        zPtr += 1
    } while yPtr < commonEnd
    
    while yPtr < yEnd
    {
        zPtr.pointee = carry
        carry = zPtr.pointee.addToSelfReportingCarry(yPtr.pointee)
        
        yPtr += 1
        zPtr += 1
    }
    
    while xPtr < xEnd
    {
        var zVal = carry
        let p: UInt
        (carry, p) = xPtr.pointee.multipliedFullWidth(by: k)
        carry &+= zVal.addToSelfReportingCarry(p)
        zPtr.pointee = zVal
        
        xPtr += 1
        zPtr += 1
    }

    if zPtr < zEnd
    {
        zPtr.pointee = carry
        carry = 0
        zPtr += 1
        
        while zPtr < zEnd
        {
            zPtr.pointee = 0
            zPtr += 1
        }
    }
    
    return carry
}

// -------------------------------------
/**
 - Returns: Remainder
 */
@inline(__always)
internal func divide(
    buffer x: UIntBuffer,
    by y: UInt,
    result z: MutableUIntBuffer) -> UInt
{
    assert(y != 0)
    assert(x.count > 0)
    assert(z.count >= x.count)
    
    let xStart = x.baseAddress!
    var xPtr = xStart + (x.count - 1)
    var zPtr = z.baseAddress! + (x.count - 1)
    
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
    
    return r
}
