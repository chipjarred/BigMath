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
extension FixedWidthInteger
{
    @inlinable
    public static var bitWidth: Int { MemoryLayout<Self>.size * 8 }
        
    // -------------------------------------
    @usableFromInline @inline(__always)
    internal func addingReportingCarry(_ other: Self)
        -> (partialValue: Self, carry: Self)
    {
        let result = self &+ other
        return (result, Self(result < other))
    }
    
    // -------------------------------------
    @usableFromInline @inline(__always)
    internal mutating func addToSelfReportingCarry(_ other: Self) -> Self
    {
        self &+= other
        return Self(self < other)
    }
    
    // -------------------------------------
    @usableFromInline @inline(__always)
    internal func subtractingReportingBorrow(_ other: Self)
        -> (partialValue: Self, borrow: Self)
    {
        let result = self &- other
        return (result, Self(result > self))
    }

    // -------------------------------------
    @usableFromInline @inline(__always)
    internal mutating func subtractFromSelfReportingBorrow(
        _ other: Self) -> Self
    {
        let borrow = Self(self < other)
        self &-= other
        return borrow
    }
    
    // -------------------------------------
    @usableFromInline @inline(__always)
    internal mutating func roundingRightShift(by shift: Int)
    {
        self.withMutableBuffer {
            BigMath.roundingRightShift(from: $0.immutable, to: $0, by: shift)
        }
    }
    
    @usableFromInline
    internal typealias UIntBuffer = UnsafeBufferPointer<UInt>.SubSequence
    
    @usableFromInline
    internal typealias MutableUIntBuffer =
        UnsafeMutableBufferPointer<UInt>.SubSequence
    
    // -------------------------------------
    @usableFromInline @inline(__always)
    internal func withBuffer<R>(body: (UIntBuffer) -> R) -> R
    {
        let buffer = self.buffer()
        return body(buffer)
    }
    
    // -------------------------------------
    @usableFromInline @inline(__always)
    internal mutating func withMutableBuffer<R>(
        body: (MutableUIntBuffer) -> R) -> R
    {
        let buffer = self.mutableBuffer()
        return body(buffer)
    }
    
    // -------------------------------------
    /*
     - Important: This is so unsafe, but we need it for performance!  Calling
        a closure via withUnsafeBytes turns out to be way more costly than
        expected.  I would have thought it would disappear with inlining, but
        it doesn't.
     */
    @usableFromInline @inline(__always)
    internal func buffer() -> UIntBuffer
    {
        /*
         withUnsafeBytes invalidates the pointer on return, so we can't just
         return $0.  However, the address remains valid (this is *NOT*
         guaranteed behavior in future versons of Swift, and not technically
         supported even in the current version.  But we're desperate to avoid as
         many nested withUnsafeBytes calls as we can, and for that we need
         pointers outside of the withUnsafeBytes calls.  So we fake out
         withUnsafeBytes by turning the pointer into an integer, and then back
         into a pointer after we return.
         */
        let address = Swift.withUnsafeBytes(of: self) {
            return UInt(bitPattern: $0.baseAddress!)
        }
        
        let ptr = UnsafeRawPointer(bitPattern: address)!
        let bufferSize = MemoryLayout<Self>.size
        let buffer = UnsafeRawBufferPointer(start: ptr, count:  bufferSize)
        return UIntBuffer.init(buffer)
    }
    
    // -------------------------------------
    /*
     - Important: This is so unsafe, but we need it for performance!  Calling
        a closure via withUnsafeBytes turns out to be way more costly than
        expected.  I would have thought it would disappear with inlining, but
        it doesn't.
     */
    @usableFromInline @inline(__always)
    internal mutating func mutableBuffer() -> MutableUIntBuffer
    {
        /*
         withUnsafeBytes invalidates the pointer on return, so we can't just
         return $0.  However, the address remains valid (this is *NOT*
         guaranteed behavior in future versons of Swift, and not technically
         supported even in the current version.  But we're desperate to avoid as
         many nested withUnsafeBytes calls as we can, and for that we need
         pointers outside of the withUnsafeBytes calls.  So we fake out
         withUnsafeBytes by turning the pointer into an integer, and then back
         into a pointer after we return.
         */
        let address = Swift.withUnsafeMutableBytes(of: &self) {
            return UInt(bitPattern: $0.baseAddress!)
        }
        
        let ptr = UnsafeMutableRawPointer(bitPattern: address)!
        let bufferSize = MemoryLayout<Self>.size
        let buffer = UnsafeMutableRawBufferPointer(
            start: ptr,
            count:  bufferSize
        )
        return MutableUIntBuffer.init(buffer)
    }
}

// -------------------------------------
// TODO: Move this to SwiftTypeExtensions Package
extension FixedWidthInteger
{
    // -------------------------------------
    @usableFromInline @inline(__always)
    internal init(_ source: Bool)
    {
        assert(
            unsafeBitCast(source, to: UInt8.self) & 0xfe == 0,
            "Upper bits of Bool are not 0"
        )
        self.init(unsafeBitCast(source, to: UInt8.self))
    }
    
    // -------------------------------------
    /**
    Branchlessly set or clear the bit at a bit index.
    */
    @inlinable
    public mutating func setBit(at bitIndex: Int, to value: Bool) {
        setBit(at: bitIndex, to: UInt(value))
    }
    
    // -------------------------------------
    /**
    Branchlessly set or clear the bit at a bit index.
    */
    @inlinable
    public mutating func setBit(at bitIndex: Int, to value: UInt)
    {
        assert(value & ~1 == 0, "Not 1 or 0")
        assert((0..<Self.bitWidth).contains(bitIndex))
        
        withMutableBuffer
        {
            var buf = $0
            BigMath.setBit(at: bitIndex, in: &buf, to: value)
        }
    }
    
    // -------------------------------------
    /// Branchlessly toggle the bit at `bitIndex`
    @inlinable
    public mutating func toggleBit(at bitIndex: Int) {
        setBit(at: bitIndex, to: getBit(at: bitIndex) ^ 1)
    }
    
    // -------------------------------------
    @inlinable
    public func getBit(at bitIndex: Int) -> UInt
    {
        assert((0..<Self.bitWidth).contains(bitIndex))
        
        let selfBuffer = self.buffer()
        return BigMath.getBit(at: bitIndex, from: selfBuffer)
    }
    
    // -------------------------------------
    @inlinable
    public func bit(at bitIndex: Int) -> Bool {
        return getBit(at: bitIndex) != 0
    }
}
