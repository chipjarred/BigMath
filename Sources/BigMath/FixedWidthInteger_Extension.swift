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
        let result = self.addingReportingOverflow(other)
        return (result.partialValue, Self(result.overflow))
    }
    
    // -------------------------------------
    @usableFromInline @inline(__always)
    internal mutating func addToSelfReportingCarry(_ other: Self) -> Self
    {
        let carry: Self
        (self, carry) = self.addingReportingCarry(other)
        return carry
    }
    
    // -------------------------------------
    @usableFromInline @inline(__always)
    internal func subtractingReportingBorrow(_ other: Self)
        -> (partialValue: Self, borrow: Self)
    {
        let result = self.subtractingReportingOverflow(other)
        return (result.partialValue, Self(result.overflow))
    }

    // -------------------------------------
    @usableFromInline @inline(__always)
    internal mutating func subtractFromSelfReportingBorrow(
        _ other: Self) -> Self
    {
        let borrow: Self
        (self, borrow) = self.subtractingReportingBorrow(other)
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
    @usableFromInline
    internal func withBuffer<R>(body: (UIntBuffer) -> R) -> R
    {
        return Swift.withUnsafeBytes(of: self) {
            return body($0.bindMemory(to: UInt.self)[...])
        }
    }
    
    // -------------------------------------
    @usableFromInline
    internal mutating func withMutableBuffer<R>(
        body: (MutableUIntBuffer) -> R) -> R
    {
        return withUnsafeMutableBytes(of: &self) {
            return body($0.bindMemory(to: UInt.self)[...])
        }
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
        
        return withBuffer {
            BigMath.getBit(at: bitIndex, from: $0)
        }
    }
    
    // -------------------------------------
    @inlinable
    public func bit(at bitIndex: Int) -> Bool {
        return getBit(at: bitIndex) != 0
    }
}
