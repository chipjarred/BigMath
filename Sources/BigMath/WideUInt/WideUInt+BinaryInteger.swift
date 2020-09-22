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
extension WideUInt: BinaryInteger
{
    public typealias Words = [UInt]
    
    // -------------------------------------
    @inlinable
    public var words: Words { return Words(self.buffer()) }

    // -------------------------------------
    @inlinable
    public static var isSigned: Bool { return false }
    
    // -------------------------------------
    @inlinable
    public static var bitWidth: Int { return MemoryLayout<Self>.size * 8 }
    
    // -------------------------------------
    @inlinable public var bitWidth: Int { return Self.bitWidth }
    
    // -------------------------------------
    @inlinable
    public var trailingZeroBitCount: Int
    {
        let selfBuffer = self.buffer()
        return countTrailingZeroBits(selfBuffer)
    }

    // -------------------------------------
    @inlinable
    public init?<T>(exactly source: T) where T : BinaryFloatingPoint
    {
        let value = floor(source)
        guard value == source
            && source >= 0
            && source.exponent < Self.bitWidth
            && source <= T(Self.max)
            && !source.isNaN
        else { return nil }
        
        self.init(_floor: value)
    }
    
    // -------------------------------------
    @inlinable
    public init?(exactly source: Decimal)
    {
        let value = source.floor
        guard value == source
            && source >= 0
            && source.exponent < Self.bitWidth
            && source <= Decimal(Self.max)
            && !source.isNaN
        else { return nil }
        
        self.init(_floor: value)
    }
    
    // -------------------------------------
    @inlinable
    public init<T>(_ source: T) where T : BinaryFloatingPoint
    {
        let value = floor(source)
        
        let tMax = T(
            sign: .plus,
            exponent: T.Exponent(Self.bitWidth),
            significand: 1
        )
        
        precondition(
            !source.isNaN && value >= 0
                && value < tMax,
            "\(source) cannot be represented by \(Self.self)"
        )
        self.init(_floor: value)
    }

    // -------------------------------------
    @usableFromInline @inline(__always)
    internal init<T>(_floor: T) where T: BinaryFloatingPoint
    {
        assert(_floor >= 0)
        assert(_floor.exponent <= Self.bitWidth)
        self.init()
        
        let selfBuffer = self.mutableBuffer()
        set(buffer: selfBuffer, from: _floor)
    }

    // -------------------------------------
    @inlinable
    public init<T>(clamping source: T) where T : BinaryInteger
    {
        if source < 0 { self.init() }
        else if MemoryLayout<T>.size > MemoryLayout<Self>.size {
            self.init(truncatingIfNeeded: Swift.min(source, T(Self.max)))
        }
        else {  self.init(withBytesOf: source) }
    }
    
    // -------------------------------------
    @inlinable
    public init<T>(_ source: T) where T : BinaryInteger
    {
        assert(
            source.bitWidth == MemoryLayout<T>.size * 8,
            "\(Self.self) can only represent a FixedWidthInteger that"
            + " stores its bit pattern and *only* its bit pattern directly"
            + " in itself (ie. not in an Array, or other indirect storage.)"
        )
        if MemoryLayout<T>.size > MemoryLayout<Self>.size
        {
            precondition(
                (0...T(Self.max)).contains(source),
                "\(source) cannot be represented by \(Self.self)"
            )
        }
        self.init(withBytesOf: source)
    }
    
    // -------------------------------------
    @inlinable
    public init<T>(truncatingIfNeeded source: T) where T : BinaryInteger {
        self.init(withBytesOf: source)
    }
    
    // -------------------------------------
    @inlinable
    public init<S>(_truncatingBits source: S) where S : BinaryInteger {
        self.init(withBytesOf: source)
    }
    
    // -------------------------------------
    @inlinable
    public var negated: Self
    {
        var result = self
        result.negate()
        return result
    }
    
    // -------------------------------------
    @inlinable
    public mutating func negate()
    {
        let selfBuffer = mutableBuffer()
        arithmeticNegate(selfBuffer.immutable, to: selfBuffer )
    }
    
    // -------------------------------------
    @inlinable
    public mutating func invert()
    {
        let selfBuffer = mutableBuffer()
        bitwiseComplement(selfBuffer.immutable, to: selfBuffer )
    }

    // -------------------------------------
    @inlinable
    public static prefix func ~ (x: Self) -> Self
    {
        var result = Self()
        let resultBuffer = result.mutableBuffer()
        let xBuffer = x.buffer()
        
        bitwiseComplement(xBuffer, to: resultBuffer )

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
    public static func &= (lhs: inout Self, rhs: Self)
    {
        let lhsBuffer = lhs.mutableBuffer()
        let rhsBuffer = rhs.buffer()
        
        bitwiseAnd(lhsBuffer.immutable, rhsBuffer, to: lhsBuffer)
    }
    
    // -------------------------------------
    @inlinable
    public static func |= (lhs: inout Self, rhs: Self)
    {
        let lhsBuffer = lhs.mutableBuffer()
        let rhsBuffer = rhs.buffer()
        
        bitwiseOr(lhsBuffer.immutable, rhsBuffer, to: lhsBuffer)
    }
    
    // -------------------------------------
    @inlinable
    public static func ^= (lhs: inout Self, rhs: Self)
    {
        let lhsBuffer = lhs.mutableBuffer()
        let rhsBuffer = rhs.buffer()
        
        bitwiseXOr(lhsBuffer.immutable, rhsBuffer, to: lhsBuffer)
    }
    
    // -------------------------------------
    @inlinable
    public static func >> <RHS: BinaryInteger>(lhs: Self, rhs: RHS) -> Self
    {
        var result = Self()
        lhs.rightShift(by: Int(rhs), into: &result, signExtend: false)
        return result
    }
    
    // -------------------------------------
    @inlinable
    public static func << <RHS: BinaryInteger>(lhs: Self, rhs: RHS) -> Self
    {
        var result = Self()
        let resultBuffer = result.mutableBuffer()
        let lhsBuffer = lhs.buffer()
        
        BigMath.leftShift(from: lhsBuffer, to: resultBuffer, by: Int(rhs))

        return result
    }
    
    // -------------------------------------
    @inlinable
    public static func >>= <RHS: BinaryInteger>(lhs: inout Self, rhs: RHS) {
        lhs.rightShift(by: Int(rhs), signExtend: false)
    }
    
    // -------------------------------------
    @usableFromInline @inline(__always)
    internal mutating func rightShift(by shift: Int, signExtend: Bool)
    {
        let selfBuffer = self.mutableBuffer()
        
        BigMath.rightShift(buffer: selfBuffer, by: shift, signExtend: signExtend)
    }

    // -------------------------------------
    @usableFromInline @inline(__always)
    internal func rightShift(
        by shift: Int,
        into dst: inout Self,
        signExtend: Bool)
    {
        let resultBuf = dst.mutableBuffer()
        let srcBuf = self.buffer()
        
        BigMath.rightShift(
            from: srcBuf,
            to: resultBuf,
            by: shift,
            signExtend: signExtend
        )
    }

    // -------------------------------------
    @inlinable
    public static func <<= <RHS: BinaryInteger>(lhs: inout Self, rhs: RHS)
    {
        let lhsBuffer = lhs.mutableBuffer()
        
        leftShift(buffer: lhsBuffer, by: Int(rhs))
    }
}
