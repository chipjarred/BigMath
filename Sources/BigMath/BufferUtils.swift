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
    
    @usableFromInline @inline(__always)
    var low: Self
    {
        assert(self.count.isMultiple(of: 2))
        return self[..<(self.count / 2)]
    }
    
    @usableFromInline @inline(__always)
    var high: Self
    {
        assert(self.count.isMultiple(of: 2))
        return self[(self.count / 2)...]
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
        return self[..<(self.count / 2)]
    }
    
    @usableFromInline @inline(__always)
    var high: Self
    {
        assert(self.count.isMultiple(of: 2))
        return self[(self.count / 2)...]
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
    
    return 0
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
