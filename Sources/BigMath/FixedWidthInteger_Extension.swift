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
    Branchlessly set or clear the bit at a bit index relative to a buffer.
    */
    @inlinable
    public mutating func setBit(at bitIndex: Int, to value: Bool) {
        setBit(at: bitIndex, to: Self(value))
    }
    
    // -------------------------------------
    /**
    Branchlessly set or clear the bit at a bit index relative to a buffer.
    */
    @inlinable
    public mutating func setBit(at bitIndex: Int, to value: Self)
    {
        assert(value & ~1 == 0, "Not 1 or 0")
        assert((0..<Self.bitWidth).contains(bitIndex))
        
        // Non-branching bit set/clear
        let mask: Self = 1 << bitIndex

        // Choice of branchless bit setting/clearing twiddling. Either should be
        // faster than a conditional branch for any CPU manufactured since the
        // mid-1990s.
        #if false
        // This should work faster for CPUs that do speculative execution with
        // limited ALU redundancy.
        self ^= ((~value &+ 1) ^ self) & mask
        #else
        // This should work faster for most modern CPUs with significant ALU
        // redundancy.
        self = (self & ~mask) | ((~value &+ 1) & mask)
        #endif
    }
    
    // -------------------------------------
    @inlinable
    public func getBit(at bitIndex: Int) -> Self
    {
        assert((0..<Self.bitWidth).contains(bitIndex))
        return (self >> bitIndex) & 1
    }
    
    // -------------------------------------
    @inlinable
    public func bit(at bitIndex: Int) -> Bool {
        return getBit(at: bitIndex) != 0
    }
}
