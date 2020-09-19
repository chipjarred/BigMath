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
extension WideFloat: FloatingPoint
{
    // -------------------------------------
    @inlinable
    public init(sign: FloatingPointSign, exponent: Int, significand: Self)
    {
        guard significand.exponent != Int.max else
        {   // Handle infinity and NaN
            self = significand.magnitude
            self.negate(if: sign == .minus)
            return
        }
        
        if significand.isZero
        {
            self = Self.zero
            self.negate(if: sign == .minus)
            return
        }
        
        let sigExponent = significand.exponent
        
        if exponent != 0
        {
            if exponent > 0
            {
                if Int.max - exponent <= sigExponent
                {
                    self = Self.infinity
                    self.negate(if: significand.isNegative)
                    return
                }
            }
            else if Int.min - exponent > sigExponent
            {
                self = Self.zero
                self.negate(if: significand.isNegative)
                return
            }
        }
        
        self.init(
            significandBitPattern: significand.magnitude._significand,
            exponent: significand.exponent + exponent
        )
        self.negate(if: sign == .minus)
    }
    
    // -------------------------------------
    @inlinable
    public init(signOf signSource: Self, magnitudeOf magnitudeSource: Self)
    {
        self.init(
            significandBitPattern: magnitudeSource._significand,
            exponent: magnitudeSource.exponent
        )
        self.negate(if: signSource.isNegative != magnitudeSource.isNegative)
    }
    
    // -------------------------------------
    @inlinable
    public init<Source>(_ value: Source) where Source : BinaryInteger
    {
        guard value != 0 else { self = Self.zero; return }
        
        // This is really slow, but if you insist on not using
        // FixedWidthIntegers, we don't really have a choice.
        self.init()
        var s = value.magnitude
        let shift = UInt.bitWidth
        var digitRadix = Self(1)
        digitRadix._exponent = UInt.bitWidth
        while s > 0
        {
            self *= digitRadix
            let digit = UInt(truncatingIfNeeded: s)
            self += Self(digit)
            
            s >>= shift
        }
        
        self.negate(if: value < 0)
    }
    
    // -------------------------------------
    @inlinable public static var radix: Int { return 2 }
    
    // -------------------------------------
    public static var pi: Self
    {
        #warning("Implement me!")
        fatalError("Unimplemented")
    }
    
    // -------------------------------------
    @inlinable public var ulp: Self
    {
        if exponent == Int.max { return Self.nan }
        
        let expOffset = UInt.bitWidth - 2
        if exponent < Int.min + expOffset { return Self.zero }
        if isZero { return Self.leastNonzeroMagnitude }
        
        var result = Self(1)
        result._exponent = self._exponent - expOffset
        return result
    }
    
    // -------------------------------------
    public mutating func formRemainder(dividingBy other: Self)
    {
        #warning("Implement me!")
        fatalError("Unimplemented")
    }
    
    // -------------------------------------
    public mutating func formTruncatingRemainder(dividingBy other: Self)
    {
        #warning("Implement me!")
        fatalError("Unimplemented")
    }
    
    // -------------------------------------
    public mutating func formSquareRoot()
    {
        #warning("Implement me!")
        fatalError("Unimplemented")
    }
    
    // -------------------------------------
    @inlinable
    public mutating func addProduct(_ lhs: Self, _ rhs: Self) {
        self += lhs * rhs
    }
    
    // -------------------------------------
    @inlinable public var nextUp: Self
    {
        if _exponent == Int.max
        {
            if isNaN { return Self.nan }
            if isNegative { return Self.greatestFiniteMagnitude.negated }
            return self
        }
        else if isZero {
            return Self.leastNonzeroMagnitude
        }
        else if self == Self.leastNonzeroMagnitude.negated {
            return Self.zero.negated
        }
        else if self == Self.greatestFiniteMagnitude {
            return Self.infinity
        }
        
        return self + self.ulp
    }
    
    // -------------------------------------
    @inlinable
    public func isEqual(to other: Self) -> Bool { return self == other }
    
    // -------------------------------------
    @inlinable
    public func isLess(than other: Self) -> Bool { return self < other }
    
    // -------------------------------------
    @inlinable
    public func isLessThanOrEqualTo(_ other: Self) -> Bool {
        return self <= other
    }
    
    // -------------------------------------
    @inlinable
    public func isTotallyOrdered(belowOrEqualTo other: Self) -> Bool {
        return self <= other
    }
    
    // -------------------------------------
    @inlinable public var isNormal: Bool { return true }
    @inlinable public var isFinite: Bool { return _exponent != Int.max}
    @inlinable public var isSubnormal: Bool { return false }
    
    // -------------------------------------
    @inlinable public var isCanonical: Bool
    {
        assert(isNormalized)
        return true
    }
    
    // -------------------------------------
    public static func / (left: Self, right: Self) -> Self
    {
        /*
         Ugh - all this conditional branching sucks.  Most of the conditions
         should be fairly predictable, though, as ideally dividing NaNs and
         infinities should be unusual.  However, dividing 0 is more common
         and IEEE 754 has special rules for signed 0s that we have to handle.
         */
        let hasSpecialValue =
            UInt8(left._exponent == Int.max) | UInt8(right._exponent == Int.max)
        if hasSpecialValue == 1
        {
            if UInt8(left.isNaN) | UInt8(right.isNaN) == 1
            {
                let hasSignalingNaN =
                    UInt8(left.isSignalingNaN) | UInt8(right.isSignalingNaN)
                
                if hasSignalingNaN == 1 { handleSignalingNaN(left, right) }
                
                // sNaNs are converted to qNaNs after being handled per IEEE 754
                return Self.nan
            }
            
            if left.isInfinite
            {
                if right.isInfinite { return self.nan }
                
                if right.isZero
                {
                    var result = Self.infinity
                    result.negate(if: left.isNegative != right.isNegative)
                    return result
                }
                
                var result = Self.zero
                result.negate(if: left.isNegative != right.isNegative)
                return result
            }
            else if right.isInfinite
            {
                if left.isZero
                {
                    var result = Self.zero
                    result.negate(if: left.isNegative != right.isNegative)
                    return result
                }
                
                var result = Self.zero
                result.negate(if: left.isNegative != right.isNegative)
                return result
            }
        }
        
        if left.isZero
        {
            if right.isZero { return Self.nan }
            
            var result = Self.zero
            result.negate(if: left.isNegative != right.isNegative)
            return result
        }
        else if right.isZero
        {
            var result = Self.infinity
            result.negate(if: left.isNegative != right.isNegative)
            return result
        }
        
        // Handle underflow to 0, and overflow to infinity
        if right.exponent > 0
        {
            if Int.min + right.exponent > left.exponent
            {
                var result = Self.zero
                result.negate(if: left.isNegative != right.isNegative)
                return result
            }
        }
        else if Int.max + right.exponent <= left.exponent
        {
            var result = Self.infinity
            result.negate(if: left.isNegative != right.isNegative)
            return result
        }
        
        #if false
        let rightInv = right.multiplicativeInverse_NewtonRaphson
        return left * rightInv
        #else
        var dividend = left._significand
        dividend.setBit(at: RawSignificand.bitWidth - 1, to: 0)
        var divisor = right._significand
        divisor.setBit(at: RawSignificand.bitWidth - 1, to: 0)
        
        let zero = RawSignificand.zero
        var qHigh, qLow, r: RawSignificand
        (qHigh, r) = dividend.quotientAndRemainder(dividingBy: divisor)
        (qLow, r) = divisor.dividingFullWidth((r, zero))
        let shift = qHigh.leadingZeroBitCount - 1
        qHigh <<= shift
        qHigh |= qLow >> (RawSignificand.bitWidth - shift)
        let qExpDelta = (
            left.significand.floatValue / right.significand.floatValue
        ).exponent
        
        var result = Self(
            significandBitPattern: qHigh,
            exponent: left.exponent - right.exponent + qExpDelta
        )
        result.negate(if: left.isNegative != right.isNegative)
        return result
        #endif
    }
    
    
    // -------------------------------------
    @inlinable
    public var multiplicativeInverse: Self {
        return multiplicativeInverse_KnuthD
    }
    
    // -------------------------------------
    @inlinable
    public var multiplicativeInverse_NewtonRaphson: Self
    {
        if _exponent == Int.max
        {
            if isNaN { return Self.nan }
            if isInfinite
            {
                var result = Self.zero
                result.negate(if: isNegative)
                return result
            }
        }
        
        if isZero || _exponent <= Int.min + 1
        {
            var result = Self.infinity
            result.negate(if: isNegative)
            return result
        }
        
        /*
         Using Newton's method to find the multiplicative inverse.  Given a good
         starting point, it doubles the number of good bits each iteration.
         */
        let s = significand.magnitude
        var x = s.multiplicativeInverse_NewtonRaphson0
        let deltaExp = x._exponent + s._exponent
        
        let sigSize = MemoryLayout<RawSignificand>.size
        let uintSize = MemoryLayout<UInt>.size
        let iterations = Int(log2(Double(sigSize / uintSize)))
        
        for _ in 0..<iterations
        {
            let sx = s * x
            let oneMinusSX = 1 - sx
            if oneMinusSX.isZero { break }
            let xOneMinusSX = x * oneMinusSX

            x =  x + xOneMinusSX
        }
        
        x._exponent = -self._exponent + deltaExp
        
        assert(x.isNormalized)
        
        x.negate(if: isNegative)
        return x
    }
    
    // -------------------------------------
    @inlinable
    public var multiplicativeInverse_KnuthD: Self
    {
        if _exponent == Int.max
        {
            if isNaN { return Self.nan }
            if isInfinite
            {
                var result = Self.zero
                result.negate(if: isNegative)
                return result
            }
        }
        
        if isZero || _exponent <= Int.min + 1
        {
            var result = Self.infinity
            result.negate(if: isNegative)
            return result
        }
        
        /*
         Using Newton's method to find the multiplicative inverse.  Given a good
         starting point, it doubles the number of good bits each iteration.
         */
        let s = significand.magnitude
        var x = s.multiplicativeInverse0_KnuthD
        let deltaExp = x._exponent + s._exponent
        
        x._exponent = -self._exponent + deltaExp
        
        assert(x.isNormalized)
        
        x.negate(if: isNegative)
        return x
    }

    // -------------------------------------
    @usableFromInline @inline(__always)
    internal var multiplicativeInverse_NewtonRaphson0: Self
    {
        assert(!isNaN)
        assert(!isZero)
        assert(!isInfinite)
        assert(!isNegative)
        
        let sig = self._significand
        let one = Self(1)
        var q = WideUInt<RawSignificand>()
        var r: RawSignificand
        (q.high, r) = one._significand.quotientAndRemainder(dividingBy: sig)
        (q.low, r) = sig.dividingFullWidth((r, RawSignificand.zero))
        
        let shift = RawSignificand.bitWidth - q.leadingZeroBitCount + 1
        q.roundingRightShift(by: shift)
        
        let result = Self(
            significandBitPattern: q.low,
            exponent: (1 / self.significand.doubleValue).exponent
        )
        assert(!result.isNegative)
        assert(result.isNormalized)
        return result
    }
    
    
    // -------------------------------------
    @inlinable
    internal var multiplicativeInverse0_KnuthD: Self
    {
        assert(!isNaN)
        assert(!isZero)
        assert(!isInfinite)
        assert(!isNegative)
        
        let sig = self._significand
        let one = Self(1)
        var q = WideUInt<RawSignificand>()
        var r: RawSignificand
        (q.high, r) = one._significand.quotientAndRemainder(dividingBy: sig)
        (q.low, r) = sig.dividingFullWidth((r, RawSignificand.zero))

        let shift = q.leadingZeroBitCount - 1
        q <<= shift
        
        q.roundingRightShift(by: RawSignificand.bitWidth)
        
        let result = Self(
            significandBitPattern: q.low,
            exponent: (1 / self.significand.floatValue).exponent
        )
        assert(!result.isNegative)
        assert(result.isNormalized)
        return result
    }

    
    // -------------------------------------
    @inlinable
    public static func /= (left: inout Self, right: Self) {
        left = left / right
    }
    
    // -------------------------------------
    public mutating func round(_ rule: FloatingPointRoundingRule)
    {
        #warning("Implement me!")
        fatalError("Unimplemented")
    }
}
