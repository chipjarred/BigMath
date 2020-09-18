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
        #warning("Implement me!")
        fatalError("Unimplemented")
    }
    
    // -------------------------------------
    public static func /= (left: inout Self, right: Self)
    {
        #warning("Implement me!")
        fatalError("Unimplemented")
    }
    
    // -------------------------------------
    public mutating func round(_ rule: FloatingPointRoundingRule)
    {
        #warning("Implement me!")
        fatalError("Unimplemented")
    }
}
