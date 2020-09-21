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

// -------------------------------------
extension WideInt: BinaryInteger
{
    public typealias Words = [UInt]
    
    // -------------------------------------
    @inlinable
    public var words: Words { return bitPattern.words }

    // -------------------------------------
    @inlinable
    public static var isSigned: Bool { return true }
    
    // -------------------------------------
    @inlinable public var bitWidth: Int { return Self.bitWidth }
    
    // -------------------------------------
    @inlinable
    public var trailingZeroBitCount: Int { bitPattern.trailingZeroBitCount }

    // -------------------------------------
    @inlinable
    public init?<T>(exactly source: T) where T : BinaryFloatingPoint
    {
        if source < 0
        {
            guard var bits = Magnitude(exactly: -source) else { return nil }
            bits.negate()
            self.init(bitPattern: bits)
        }
        else
        {
            guard let bits = Magnitude(exactly: source) else { return nil }
            self.init(bitPattern: bits)
        }
    }
    
    // -------------------------------------
    @inlinable
    public init<T>(_ source: T) where T : BinaryFloatingPoint
    {
        if source < 0
        {
            self.bitPattern = Magnitude(-source)
            self.bitPattern.negate()
        }
        else { self.bitPattern = Magnitude(source) }
    }
            
    // -------------------------------------
    @inlinable
    public init<T>(clamping source: T) where T : BinaryInteger
    {
        if source < 0 { self = 0 }
        else if MemoryLayout<T>.size > MemoryLayout<Self>.size
        {
            self.init(withBytesOf:
                Swift.max(T(Self.min), Swift.min(source, T(Self.max)))
            )
        }
        else { self.init(withBytesOf: source) }
    }
    
    // -------------------------------------
    public init<T>(_ source: T) where T : BinaryInteger
    {
        assert(
            source.bitWidth == MemoryLayout<T>.size * 8,
            "\(Self.self) can only represent a FixedWidthInteger that"
            + " stores its bit pattern and *only* its bit pattern directly"
            + " in itself (ie. not in an Array, or other indirect storage.)"
        )
        self.init(withBytesOf: source)

        if MemoryLayout<T>.size > MemoryLayout<Self>.size
        {
            precondition(
                unsafeBitCast(self, to: T.self) == source,
                "\(source) cannot be represented by \(Self.self)"
            )
        }
    }
    
    // -------------------------------------
    public init<T>(truncatingIfNeeded source: T) where T : BinaryInteger {
        self.init(withBytesOf: source)
    }
    
    // -------------------------------------
    @inlinable
    public var negated: Self
    {
        var result = self
        result.bitPattern.negate()
        return result
    }
    
    // -------------------------------------
    @inlinable
    public mutating func negate() { self.bitPattern.negate() }
    
    // -------------------------------------
    @inlinable
    public mutating func invert() { self.bitPattern.invert() }

    // -------------------------------------
    @inlinable
    public static prefix func ~ (x: Self) -> Self
    {
        var result = x
        result.bitPattern.invert()
        return result
    }
    
    // -------------------------------------
    @inlinable
    public static func / (lhs: Self, rhs: Self) -> Self {
        return lhs.quotientAndRemainder(dividingBy: rhs).quotient
    }
    
    // -------------------------------------
    @inlinable
    public static func /= (lhs: inout Self, rhs: Self) {
        lhs = lhs / rhs
    }
    
    // -------------------------------------
    @inlinable
    public static func % (lhs: Self, rhs: Self) -> Self {
        return lhs.quotientAndRemainder(dividingBy: rhs).remainder
    }
    
    // -------------------------------------
    @inlinable
    public static func %= (lhs: inout Self, rhs: Self) {
        lhs = lhs % rhs
    }
    
    // -------------------------------------
    @inlinable
    public static func & (lhs: Self, rhs: Self) -> Self
    {
        var result = lhs
        result &= rhs
        return result
    }
    
    // -------------------------------------
    @inlinable
    public static func | (lhs: Self, rhs: Self) -> Self
    {
        var result = lhs
        result |= rhs
        return result
    }
    
    // -------------------------------------
    @inlinable
    public static func ^ (lhs: Self, rhs: Self) -> Self
    {
        var result = lhs
        result ^= rhs
        return result
    }

    // -------------------------------------
    @inlinable
    public static func &= (lhs: inout Self, rhs: Self) {
        lhs.bitPattern &= rhs.bitPattern
    }
    
    // -------------------------------------
    @inlinable
    public static func |= (lhs: inout Self, rhs: Self) {
        lhs.bitPattern |= rhs.bitPattern
    }
    
    // -------------------------------------
    @inlinable
    public static func ^= (lhs: inout Self, rhs: Self) {
        lhs.bitPattern ^= rhs.bitPattern
    }
    
    // -------------------------------------
    @inlinable
    public static func >> <RHS: BinaryInteger>(lhs: Self, rhs: RHS) -> Self
    {
        var result = Self()
        lhs.bitPattern.rightShift(
            by: Int(rhs),
            into: &result.bitPattern,
            signExtend: lhs.bitPattern.signBit
        )
        return result
    }
    
    // -------------------------------------
    @inlinable
    public static func << <RHS: BinaryInteger>(lhs: Self, rhs: RHS) -> Self
    {
        var result = lhs
        result.bitPattern <<= rhs
        return result
    }
    
    // -------------------------------------
    @inlinable
    public static func >>= <RHS: BinaryInteger>(lhs: inout Self, rhs: RHS)
    {
        lhs.bitPattern.rightShift(
            by: Int(rhs),
            signExtend: lhs.bitPattern.signBit
        )
    }

    // -------------------------------------
    @inlinable
    public static func <<= <RHS: BinaryInteger>(lhs: inout Self, rhs: RHS) {
        lhs.bitPattern <<= rhs
    }
}
