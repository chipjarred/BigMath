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

fileprivate let uintBitWidth = MemoryLayout<UInt>.size * 8


// MARK:- Buffer comparison
// -------------------------------------
@usableFromInline @inline(__always)
internal func compareBuffers(
    _ left: UIntBuffer,
    _ right: UIntBuffer) -> ComparisonResult
{
    assert(left.count > 0)
    assert(right.count > 0)
    
    let left = signficantDigits(of: left)
    let right = signficantDigits(of: right)
    
    guard left.count == right.count else
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
    var lPtr = lStart + (left.count - 1)
    var rPtr = right.baseAddress! + (left.count - 1)
    
    repeat
    {
        let l = lPtr.pointee
        let r = rPtr.pointee
        
        guard l == r else
        {
            return ComparisonResult(
                rawValue: select(if: l < r, then: -1, else: 1)
            )!
        }
        
        lPtr -= 1
        rPtr -= 1
    } while lPtr >= lStart
    
    return .orderedSame
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
internal func leftShift(buffer x: MutableUIntBuffer, by shift: Int) {
    leftShift(from: x.immutable, to: x, by: shift)
}

// -------------------------------------
@usableFromInline @inline(__always)
internal func rightShift(
    buffer x: MutableUIntBuffer,
    by shift: Int,
    signExtend: Bool = false
)
{
    rightShift(from: x.immutable, to: x, by: shift, signExtend: signExtend)
}

// -------------------------------------
@usableFromInline
internal func leftShift(
    from src: UIntBuffer,
    to dst: MutableUIntBuffer,
    by shift: Int)
{
    assert(shift >= 0)
    assert(src.count > 0)
    assert(dst.count >= src.count)
    
    let d = fastMin(shift / uintBitWidth, src.count)
    let lShift = shift % uintBitWidth
    let rShift = uintBitWidth - lShift
    
    let dstBase = dst.baseAddress!
    var dstDigit = dstBase.advanced(by: dst.count - 1)
    
    if d < src.count
    {
        let srcBase = src.baseAddress!
        var srcDigit = srcBase + (src.count - d - 1)
        var prevDigit = srcDigit - 1
        
        while prevDigit >= srcBase
        {
            dstDigit.pointee =
                (srcDigit.pointee << lShift) | (prevDigit.pointee >> rShift)

            dstDigit -= 1
            srcDigit -= 1
            prevDigit -= 1
        }
        
        dstDigit.pointee = srcDigit.pointee << lShift
        dstDigit -= 1
    }
    
    while dstDigit >= dstBase
    {
        dstDigit.pointee = 0
        dstDigit -= 1
    }
}

// -------------------------------------
@usableFromInline
internal func rightShift(
    from src: UIntBuffer,
    to dst: MutableUIntBuffer,
    by shift: Int,
    signExtend: Bool = false)
{
    assert(shift >= 0)
    assert(src.count > 0)
    assert(dst.count == src.count)
    
    let d = fastMin(shift / uintBitWidth, src.count)
    let rShift = shift % uintBitWidth
    let lShift = uintBitWidth - rShift
    let signBits = select(if: signExtend, then: UInt.max, else: 0)

    var dstDigit = dst.baseAddress!
    let dstEnd = dstDigit + d
    
    if d < src.count
    {
        let srcBase = src.baseAddress!
        let srcEnd = srcBase + src.count
        var srcDigit = srcBase + d
        var nextDigit = srcDigit + 1
        
        while nextDigit < srcEnd
        {
            dstDigit.pointee =
                (srcDigit.pointee >> rShift) | (nextDigit.pointee << lShift)

            dstDigit += 1
            srcDigit += 1
            nextDigit += 1
        }
        
        dstDigit.pointee = (srcDigit.pointee >> rShift) | (signBits << lShift)
        dstDigit += 1
    }
    
    while dstDigit < dstEnd
    {
        dstDigit.pointee = signBits
        dstDigit += 1
    }
}

// -------------------------------------
@usableFromInline
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
@usableFromInline
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
@usableFromInline
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
@usableFromInline
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

// MARK:- Arithmetic operations
// -------------------------------------
/// Two's complement arithmetic negation
@usableFromInline
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
@usableFromInline
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

    return carry
}


// -------------------------------------
@usableFromInline
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
@usableFromInline
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

    return borrow
}

// -------------------------------------
@usableFromInline
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
 */
@usableFromInline @inline(__always)
internal func fullMultiplyBuffers_SchoolBook(
    _ xBuf: UIntBuffer,
    _ yBuf: UIntBuffer,
    result zBuf: MutableUIntBuffer)
{
    assert(xBuf.count > 0, "xBuf: empty buffer")
    assert(yBuf.count > 0, "yBuf: empty buffer")
    assert(zBuf.count >= xBuf.count+yBuf.count, "Result buffer: wrong size")
    assert(0 == zBuf.reduce(0) { $0 | $1 }, "Result buffer: not zeroed")
    
    var carry: UInt = 0
    
    var xPtr = xBuf.baseAddress!
    let xEnd = xPtr + xBuf.count
    let yEnd = yBuf.baseAddress! + yBuf.count
    var zNext = zBuf.baseAddress!
    var zPtr = zNext

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
    result zBuf: MutableUIntBuffer)
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
    
    guard xBuf.count > 128 else
    {
        fullMultiplyBuffers_SchoolBook(xBuf, yBuf, result: zBuf)
        return
    }
    
    fullMultiplyBuffers_Karatsuba(
        xBuf.low,
        yBuf.low,
        scratch1: differences.low,
        scratch2: differences.high,
        scratch3: middleTerm,
        result: zBuf.low
    )
    
    fullMultiplyBuffers_Karatsuba(
        xBuf.high,
        yBuf.high,
        scratch1: differences.low,
        scratch2: differences.high,
        scratch3: middleTerm,
        result: zBuf.high
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
        result: middleProduct
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
    assert(xBuf.count > 0, "xBuf: empty buffer")
    assert(zBuf.count >= xBuf.count, "Result buffer: too small")
    
    var carry: UInt = 0
    
    var xPtr = xBuf.baseAddress!
    let xEnd = xPtr + xBuf.count
    var zPtr = zBuf.baseAddress!
    let zEnd = zPtr + zBuf.count
    
    repeat
    {
        let overflow: UInt
        (overflow, zPtr.pointee) = xPtr.pointee.multipliedFullWidth(by: y)
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
    
    return carry != 0
}

// -------------------------------------
@usableFromInline @inline(__always)
internal func fullWidthDivide(
    _ x: UIntBuffer,
    by y: UIntBuffer,
    scratch: MutableUIntBuffer,
    quotient: MutableUIntBuffer,
    remainder: MutableUIntBuffer)
{
    assert(x.count > 0)
    assert(y.count > 0)
    assert(x.count >= y.count)
    assert(scratch.count == x.count)
    assert(remainder.count == x.count)
    assert(quotient.count == x.count)
    assert(0 != y.reduce(0) { $0 | $1 }, "Dividing by zero!!!")
    assert(0 == quotient.reduce(0) { $0 | $1 }, "Quotient buffer not zeroed")
    assert(0 == remainder.reduce(0) { $0 | $1 }, "Remainder buffer not zeroed")
    
    if y.count == 1
    {
        remainder.baseAddress!.pointee =
            divide(buffer: x, by: y.first!, result: quotient)
        return
    }
    
    copy(buffer: x, to: remainder)
    
    let y = signficantDigits(of: y)
    let yHigh = y.nthDigit(y.count - 1)
    let yLow = y.nthDigit(y.count - 2)
    var qStart = quotient.baseAddress!
    let qEnd = qStart + quotient.count
    var qPtr = qEnd
    let p = scratch
    var q, qLo: UInt
    repeat
    {
        let r = signficantDigits(of: remainder)
        (q, qLo) = divideFirstTwoDigits(of: r.immutable, by: (yHigh, yLow))
        
        if q == 0 {
            q = qLo
        }
        
        while multiply(buffer: y, by: q, result: p) {
            assert(false)
            q -= 1
        }
        
        if 0 != subtractReportingBorrow(
            remainder.immutable,
            p.immutable,
            result: remainder)
        {
            q -= 1
            let _ = addReportingCarry(remainder.immutable, y, result: remainder)
        }
        
        debugPrint(buffer: remainder.immutable)
        
        let _ = addReportingCarry(quotient.immutable, q, result: quotient)
        
        qPtr -= 1
//        qPtr.pointee &+= q
    } while q != 0
    
    // Shift quotient so its least signficant digits are at quotient[0]
    while qPtr < qEnd
    {
        let c = qPtr.pointee
        qPtr.pointee = 0
        qStart.pointee = c
        qStart += 1
        qPtr += 1
    }
}

// -------------------------------------
struct MiniFloat: Comparable
{
    public typealias Mantissa = WideUInt<UInt>
    var mantissa: Mantissa
    var exponent: UInt
    
    // -------------------------------------
    var high: Mantissa.Digit
    {
        get { return mantissa.high }
        set { mantissa.high = newValue }
    }
    
    // -------------------------------------
    var low: Mantissa.Digit
    {
        get { return mantissa.low }
        set { mantissa.low = newValue }
    }

    // -------------------------------------
    @usableFromInline @inline(__always)
    internal init(mantissa: Mantissa, exponent: UInt)
    {
        self.mantissa = mantissa
        self.exponent = exponent
    }
    
    // -------------------------------------
    public init(_ x: UInt, exponent: UInt)
    {
        
        self.mantissa = Mantissa(high: x)
        self.exponent = exponent
    }
    
    // -------------------------------------
    @inlinable
    public init(_ x: UIntBuffer)
    {
        assert(x.count > 0)
        self.init(
            mantissa: Mantissa(
                low: x.nthDigit(x.count - 2),
                high: x.nthDigit(x.count - 1)
            ),
            exponent: UInt(x.count - 1)
        )
    }
    
    // -------------------------------------
    @inlinable
    public init(_ x: MutableUIntBuffer) { self.init(x.immutable) }
    
    // -------------------------------------
    public func set(inBuffer x: MutableUIntBuffer)
    {
        assert(x.count > exponent)
        zeroBuffer(x)
        let xPtr = x.baseAddress! + Int(exponent)
        xPtr.pointee = self.high
        if xPtr != x.baseAddress! {
            (xPtr - 1).pointee = self.low
        }
        
    }
    
    // -------------------------------------
    @inlinable
    public static func == (left: Self, right: Self) -> Bool
    {
        return left.mantissa == right.mantissa
            && left.exponent == right.exponent
    }
    
    // -------------------------------------
    @inlinable
    public static func < (left: Self, right: Self) -> Bool
    {
        if left.exponent == right.exponent {
            return left.mantissa < right.mantissa
        }
        
        return left.exponent < right.exponent
    }
    
    // -------------------------------------
    public static func + (left: Self, right: Self) -> Self
    {
        if left.exponent < right.exponent {
            return right + left
        }
        
        if left.exponent == right.exponent
        {
            var result = left
            let carry = result.mantissa.addToSelfReportingCarry(right.mantissa)
            if carry != 0
            {
                result.low = result.high
                result.high = carry
                result.exponent &+= 1
            }
            return result
        }
        
        if left.exponent == right.exponent + 1
        {
            return left + Self(
                mantissa: Mantissa(low: right.high),
                exponent: right.exponent + 1
            )
        }
        
        return left
    }
    
    // -------------------------------------
    public static func - (left: Self, right: Self) -> Self
    {
        assert(left > right)
        
        if left.exponent == right.exponent
        {
            var result = left
            let borrow = result.mantissa.subtractFromSelfReportingBorrow(
                right.mantissa
            )
            if borrow != 0
            {
                result.low = result.high
                result.high = Mantissa.Digit.max
                result.exponent &-= 1
            }
        }
        
        if left.exponent == right.exponent + 1
        {
            return left - Self(
                mantissa: Mantissa(low: right.high),
                exponent: right.exponent + 1
            )
        }
        
        return left
    }
    
    // -------------------------------------
    public static func * (left: Self, right: Self) -> Self
    {
        let zMantissa = left.mantissa.multipliedFullWidth(by: right.mantissa)
        let zExponent = left.exponent + right.exponent
        if zMantissa.high.high != 0 {
            return Self(mantissa: zMantissa.high, exponent: zExponent + 1)
        }
        
        if zMantissa.high.low != 0
        {
            return Self(
                mantissa: Mantissa(
                    low: zMantissa.low.high,
                    high: zMantissa.high.low
                ),
                exponent: zExponent
            )
        }
        
        assert(zExponent > 0)
        
        return Self(mantissa: zMantissa.low, exponent: zExponent - 1)
    }
}

func debugPrint(buffer: UIntBuffer)
{
    var s = ""
    for i in buffer.indices.reversed()
    {
        s += String(format: "%016llX_", buffer[i])
    }
    
    print(s)
}

// -------------------------------------
/*
 - Returns: Remainder
 */
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

// -------------------------------------
@usableFromInline @inline(__always)
internal func divideFirstTwoDigits(
    of x: UIntBuffer,
    by y: (high: UInt, low: UInt)) -> (high: UInt, low: UInt)
{
    assert(y.high != 0)
    typealias UInt2 = WideUInt<UInt>

    let n = x.count
    let x = UInt2(
        low: x.nthDigit(n - 2),
        high: x.nthDigit(n - 1)
    )

    var r: UInt = 0
    var q = UInt2()
    
    (q.low, r) = x.high.quotientAndRemainder(dividingBy: y.high)
    
    let y = UInt2(y)
    var (p, overflow) = (UInt2(), false)
    while true
    {
        (p, overflow) = q.multipliedReportingOverflow(by: y)
        if overflow
        {
            q.low -= 1
            continue
        }
        break
    }
    
    while p > x
    {
        q -= 1
        p -= y
    }
    
    q.high = q.low
    (q.low,  r) = y.high.dividingFullWidth((r, x.low))

    while true
    {
        (p, _) = q.multipliedFullWidth(by: y)
        if p > x
        {
            q.low -= 1
            continue
        }
        break
    }

    return (q.high, q.low)
}
