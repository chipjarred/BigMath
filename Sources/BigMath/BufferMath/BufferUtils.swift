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

@usableFromInline internal typealias UIntBuffer =
    UnsafeBufferPointer<UInt>.SubSequence
@usableFromInline internal typealias MutableUIntBuffer =
    UnsafeMutableBufferPointer<UInt>.SubSequence

// -------------------------------------
extension UIntBuffer
{
    @usableFromInline @inline(__always)
    var baseAddress: UnsafePointer<UInt>? {
        return self.base.baseAddress?.advanced(by: self.startIndex)
    }
    
    /**
     This should be used cautiously, but there are places we need it to avoid code duplication
     */
    @usableFromInline @inline(__always)
    var mutable: MutableUIntBuffer {
        return UnsafeMutableBufferPointer(mutating: base)[indices]
    }
    
    @usableFromInline @inline(__always)
    var low: Self
    {
        assert(self.count.isMultiple(of: 2))
        return self[..<(self.startIndex + self.count / 2)]
    }
    
    @usableFromInline @inline(__always)
    var high: Self
    {
        assert(self.count.isMultiple(of: 2))
        return self[(self.startIndex + self.count / 2)...]
    }
    
    // -------------------------------------
    /**
     - Important: do not call with `n > self.count`
     - Returns: the digit as a `UInt` at index `n` or `0` if n is negative.
     */
    @usableFromInline @inline(__always)
    func nthDigit(_ n: Int) -> UInt
    {
        assert(count > 0)
        assert(n < count)
        
        let indexInRange = n >= 0
        let i = select(if: indexInRange, then: n, else: 0)
        return select(if: indexInRange, then: self[i], else: 0)
    }
    
    // -------------------------------------
    /**
     - Important: do not call with `n > self.count`
     - Returns: the digit as a `Double` at index `n` or `0` if n is negative.
     */
    @inline(__always) func nthDouble(
        _ n: Int) -> Double
    {
        assert(count > 0)
        assert(n < count)
        
        return Double(self.nthDigit(n))
    }
}

// -------------------------------------
extension MutableUIntBuffer
{
    @usableFromInline @inline(__always)
    var baseAddress: UnsafeMutablePointer<UInt>? {
        return self.base.baseAddress?.advanced(by: self.startIndex)
    }
    
    @usableFromInline @inline(__always)
    var immutable: UIntBuffer {
        return UnsafeBufferPointer(base)[indices]
    }
    
    @usableFromInline @inline(__always)
    var low: Self
    {
        assert(self.count.isMultiple(of: 2))
        return self[..<(self.startIndex + self.count / 2)]
    }
    
    @usableFromInline @inline(__always)
    var high: Self
    {
        assert(self.count.isMultiple(of: 2))
        return self[(self.startIndex + self.count / 2)...]
    }
    
    // -------------------------------------
    /**
     - Important: do not call with `n > self.count`
     - Returns: the digit as a `UInt` at index `n` or `0` if n is negative.
     */
    @usableFromInline @inline(__always)
    func nthDigit(_ n: Int) -> UInt
    {
        assert(count > 0)
        assert(n < count)
        
        let indexInRange = n >= 0
        let i = select(if: indexInRange, then: n, else: 0)
        return select(if: indexInRange, then: self[i], else: 0)
    }
    
    // -------------------------------------
    /**
     - Important: do not call with `n > self.count`
     - Returns: the digit as a `Double` at index `n` or `0` if n is negative.
     */
    @inline(__always) func nthDouble(
        _ n: Int) -> Double
    {
        assert(count > 0)
        assert(n < count)
        
        return Double(self.nthDigit(n))
    }
}

fileprivate let uintRadix = Double(
    sign: .plus,
    exponent: UInt.bitWidth,
    significand: 1
)

extension UInt
{
    @usableFromInline @inline(__always)
    static var radix: Double { return uintRadix }
}

// MARK: Buffer utilties
// -------------------------------------
@usableFromInline
internal enum BufferRoundingMode
{
    case none
    case down
    case up
}

// -------------------------------------
/// dst should already be floored
@usableFromInline @inline(__always)
internal func set<F: BinaryFloatingPoint>(
    buffer dst: MutableUIntBuffer,
    from src: F)
{
    assert(src == floor(src))
    assert(src >= 0)
    assert(src.exponent <= dst.count * UInt.bitWidth)
    assert(dst.reduce(0) { $0 | $1 } == 0)
    
    let radix = F(
        sign: .plus,
        exponent: F.Exponent(UInt.bitWidth),
        significand: 1
    )
    var f = src
    var dst = dst
    var i = dst.startIndex
    
    while f > 0
    {
        assert(i < dst.endIndex)
        
        let fDigit = fmod(f, radix)
        f -= fDigit
        f /= radix
        let digit = UInt(fDigit)
        dst[i] = digit
        
        i += 1
    }
}

// -------------------------------------
/// dst should already be floored
@usableFromInline @inline(__always)
internal func set(buffer dst: MutableUIntBuffer, from src: Decimal)
{
    assert(src >= 0)
    assert(src == src.floor)
    assert(src.exponent <= dst.count * UInt.bitWidth)
    assert(dst.reduce(0) { $0 | $1 } == 0)
    
    let radix = Decimal(UInt.max) + 1
    var f = src
    var dst = dst
    var i = dst.startIndex
    
    while f > 0 && i < dst.endIndex
    {
        let fDigit = f.fmod(radix)
        f -= fDigit
        f /= radix
        let digit = fDigit.uintValue
        dst[i] = digit
        
        i += 1
    }
}

// -------------------------------------
@usableFromInline @inline(__always)
internal func decimalValue(from src: UIntBuffer) -> Decimal
{
    let radix = Decimal(UInt.max) + 1
    
    var d: Decimal = 0
    for digit in src.reversed()
    {
        d *= radix
        d += Decimal(digit)
    }
    
    return d
}

// -------------------------------------
@usableFromInline @inline(__always)
internal func convert<F: BinaryFloatingPoint>(
    from src: UIntBuffer,
    to: F.Type) -> F
{
    let radix = F(
        sign: .plus,
        exponent: F.Exponent(UInt.bitWidth),
        significand: 1
    )
    
    var d: F = 0
    for digit in src.reversed()
    {
        d *= radix
        d += F(digit)
    }
    
    return d
}

// -------------------------------------
@usableFromInline @inline(__always)
internal func copy(buffer src: UIntBuffer, to dst: MutableUIntBuffer)
{
    assert(src.count > 0)
    assert(src.count <= dst.count)
    
    
    if src.baseAddress! > UnsafePointer(dst.baseAddress!)
    {   // Copy forward
        var srcPtr = src.baseAddress!
        let srcEnd = srcPtr + src.count
        var dstPtr = dst.baseAddress!
        
        repeat
        {
            dstPtr.pointee = srcPtr.pointee
            srcPtr += 1
            dstPtr += 1
        } while srcPtr < srcEnd
    }
    else
    {   // Copy backward
        let srcStart = src.baseAddress!
        let n = src.count - 1
        var srcPtr = srcStart + n
        var dstPtr = dst.baseAddress! + n
        
        repeat
        {
            dstPtr.pointee = srcPtr.pointee
            srcPtr -= 1
            dstPtr -= 1
        } while srcPtr >= srcStart
    }
}

// -------------------------------------
@usableFromInline @inline(__always)
internal func zeroBuffer(_ buffer: MutableUIntBuffer) {
    fillBuffer(buffer, with: 0)
}

// -------------------------------------
@usableFromInline @inline(__always)
internal func fillBuffer(
    _ buffer: MutableUIntBuffer,
    with value: UInt)
{
    assert(buffer.count > 0)
    
    var p = buffer.baseAddress!
    let end = p + buffer.count

    repeat
    {
        p.pointee = value
        p += 1
    } while p < end
}

// -------------------------------------
@usableFromInline @inline(__always)
internal func mostSignicantUInt(of x: UIntBuffer) -> UInt
{
    for i in x.indices.reversed() {
        if x[i] != 0 { return x[i] }
    }
    
    return 0
}

// -------------------------------------
@usableFromInline @inline(__always)
internal func indexOfMostSignificantUInt(of x: UIntBuffer) -> Int
{
    for i in x.indices.reversed() {
        if x[i] != 0 { return i }
    }
    
    return x.startIndex
}

// -------------------------------------
@usableFromInline @inline(__always)
internal func indexOfMostSignificantUInt(of x: MutableUIntBuffer) -> Int {
    return indexOfMostSignificantUInt(of: x.immutable)
}

// -------------------------------------
@usableFromInline @inline(__always)
internal func signficantDigits(of x: UIntBuffer) -> UIntBuffer {
    return x[...indexOfMostSignificantUInt(of: x)]
}

// -------------------------------------
@usableFromInline @inline(__always)
internal func signficantDigits(of x: MutableUIntBuffer) -> MutableUIntBuffer {
    return x[...indexOfMostSignificantUInt(of: x.immutable)]
}

// -------------------------------------
/**
 Given a bit index relative to a buffer, obtain the index for the corresponding digit and the
 index of the bit in that digit.
 */
@usableFromInline @inline(__always)
internal func digitAndBitIndex(for bitIndex: Int)
    -> (digitIndex: Int, bitIndex: Int)
{
    // Since memory layouts are known at compile-time, these ifs should be
    // optimized away leaving branchless calculations
    if MemoryLayout<UInt>.size == 8
    {
        return (
            digitIndex: bitIndex >> 6,
            bitIndex: bitIndex & 0x3F
        )
    }
    else if MemoryLayout<UInt>.size == 4
    {
        return (
            digitIndex: bitIndex >> 5,
            bitIndex: bitIndex & 0x1F
        )
    }
    else
    {
        return (
            digitIndex: bitIndex / UInt.bitWidth,
            bitIndex: bitIndex % UInt.bitWidth
        )
    }
}

// -------------------------------------
/**
 Set or clear the bit at a bit index relative to a buffer.
 */
@usableFromInline @inline(__always)
internal func setBit(
    at bitIndex: Int,
    in buff: inout MutableUIntBuffer,
    to value: UInt)
{
    assert(value == 0 || value == 1)
    let (digitIndex, bitIndex) = digitAndBitIndex(for: bitIndex)
    
    assert(buff.indices.contains(digitIndex))
    
    buff[digitIndex].setBit(at: bitIndex, to: value)
}

// -------------------------------------
/**
 Toggle the bit at a bit index relative to a buffer.
 */
@usableFromInline @inline(__always)
internal func toggleBit(
    at bitIndex: Int,
    in buff: inout MutableUIntBuffer)
{
    let (digitIndex, bitIndex) = digitAndBitIndex(for: bitIndex)
    
    assert(buff.indices.contains(digitIndex))
    
    buff[digitIndex].toggleBit(at: bitIndex)
}

// -------------------------------------
/**
Retrieve the value of a bit at a bit index relative to a buffer.
*/
@usableFromInline @inline(__always)
internal func getBit(at bitIndex: Int, from buff: UIntBuffer) -> UInt
{
    let (digitIndex, bitIndex) = digitAndBitIndex(for: bitIndex)
    assert(buff.indices.contains(digitIndex))

    return buff[digitIndex].getBit(at: bitIndex)
}

// -------------------------------------
@usableFromInline @inline(__always)
internal func copyBytes<T, U>(of src: T, into dst: inout U)
{
    #if true
    if MemoryLayout<T>.size >= MemoryLayout<U>.size {
        dst = unsafeBitCast(src, to: U.self)
    }
    else
    {
        withUnsafeMutableBytes(of: &dst)
        {
            $0.bindMemory(to: T.self).baseAddress!.pointee = src
            
            memset(
                $0.baseAddress!.advanced(by: MemoryLayout<T>.size),
                0,
                $0.count - MemoryLayout<T>.size
            )
        }
    }
    #else
    withUnsafeBytes(of: src)
    {
        let srcBuf = UnsafeRawBufferPointer(
            start: $0.baseAddress!,
            count: min($0.count, MemoryLayout<U>.size)
        )
        withUnsafeMutableBytes(of: &dst) { dstBuf in
            dstBuf.copyMemory(from: srcBuf)
        }
    }
    #endif
}
