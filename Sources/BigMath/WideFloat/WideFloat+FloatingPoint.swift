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
        if isZero { return Self.leastNonzeroMagnitude }
        
        let expOffset = UInt.bitWidth - 2
        if exponent < Int.min + expOffset { return Self.zero }
        
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
    @inlinable
    public static func / (left: Self, right: Self) -> Self
    {
        #if false
        return left.divide_MultInv(by: right)
        #else
        return left.divide_KnuthD(by: right)
        #endif
    }
    
    // -------------------------------------
    @inlinable
    public static func /= (left: inout Self, right: Self) {
        left = left / right
    }
    
    // -------------------------------------
    @inlinable
    public mutating func round(_ rule: FloatingPointRoundingRule)
    {
        #warning("Implement me!")
        fatalError("Unimplemented")
    }
    
    // -------------------------------------
    /**
     Divide two `WideFloats` by finding the `divisor`'s multiplicative inverse
     using Newton's method, and multiplying it by the `dividend`.
     */
    @inlinable
    public func divide_NewtonRaphson(by divisor: Self) -> Self
    {
        if let result = self.divideSpecialValues(by: divisor) { return result }

        let divisorInv = divisor.multiplicativeInverse_NewtonRaphson_Core
        return self.multiply_Core(divisorInv)
    }
    
    // -------------------------------------
    /**
     Divide two `WideFloats` by finding the `divisor`'s multiplicative inverse
     using Knuth's Algorithm D, and multiplying it by the `dividend`.
     */
    @inlinable
    public func divide_MultInv(by divisor: Self) -> Self
    {
        if let result = self.divideSpecialValues(by: divisor) { return result }

        let divisorInv = divisor.multiplicativeInverse_KnuthD_Core
        return self.multiply_Core(divisorInv)
    }
    
    // -------------------------------------
    @usableFromInline
    internal struct Remainder
    {
        var low = RawSignificand()
        @usableFromInline var r: RawSignificand
        var extra = UInt()

        @usableFromInline init() { r = RawSignificand() }
        
        @usableFromInline init(_ source: RawSignificand) {
            r = source
        }
        
        @usableFromInline @inline(__always)
        func buffer() -> UIntBuffer
        {
            let address = Swift.withUnsafeBytes(of: self) {
                return UInt(bitPattern: $0.baseAddress!)
            }
            
            let ptr = UnsafeRawPointer(bitPattern: address)!
            let bufferSize = MemoryLayout<Self>.size
            let buffer = UnsafeRawBufferPointer(
                start: ptr,
                count:  bufferSize
            )
            return UIntBuffer.init(buffer)
        }
        
        @usableFromInline @inline(__always)
        mutating func mutableBuffer() -> MutableUIntBuffer
        {
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
    @usableFromInline
    internal struct Quotient
    {
        @usableFromInline var r: RawSignificand
        var extra = UInt()

        @usableFromInline init() { r = RawSignificand() }
        
        @usableFromInline init(_ source: RawSignificand) {
            r = source
        }
        
        @usableFromInline @inline(__always)
        func buffer() -> UIntBuffer
        {
            let address = Swift.withUnsafeBytes(of: self) {
                return UInt(bitPattern: $0.baseAddress!)
            }
            
            let ptr = UnsafeRawPointer(bitPattern: address)!
            let bufferSize = MemoryLayout<Self>.size
            let buffer = UnsafeRawBufferPointer(
                start: ptr,
                count:  bufferSize
            )
            return UIntBuffer.init(buffer)
        }
        
        @usableFromInline @inline(__always)
        mutating func mutableBuffer() -> MutableUIntBuffer
        {
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
        
        @usableFromInline @inline(__always)
        mutating func adjust()
        {
            let buf = mutableBuffer()

            let leadZeros = countLeadingZeroBits(buf.immutable)
            
            let rightShift = UInt.bitWidth - leadZeros + 1
            if rightShift < 0 { leftShift(buffer: buf, by: -rightShift) }
            else { BigMath.rightShift(buffer: buf, by: rightShift) }
        }
    }

    // -------------------------------------
    /**
     Divide two `WideFloats` by dividing their significands using Knuth's
     Algorithm D and then adjusting the exponents.
     */
    @inlinable
    public func divide_KnuthD(by divisor: Self) -> Self
    {
        if let result = self.divideSpecialValues(by: divisor) { return result }

        var dividendSig = self._significand
        var divisorSig = divisor._significand
                
        var q = Quotient()
        var r = Remainder()
        
        let divisorBuf = divisorSig.mutableBuffer().immutable
        let dividendBuf = dividendSig.mutableBuffer().immutable
        let qBuf = q.mutableBuffer()
        let rBuf = r.mutableBuffer()

        dividendSig.setBit(at: RawSignificand.bitWidth - 1, to: 0)
        divisorSig.setBit(at: RawSignificand.bitWidth - 1, to: 0)

        floatDivide_KnuthD(
            dividendBuf,
            by: divisorBuf,
            quotient: qBuf,
            remainder: rBuf
        )
        
        q.adjust()
        
        let qExpDelta = (
            self.significand.floatValue / divisor.significand.floatValue
        ).exponent
        
        var result = Self(
            significandBitPattern: q.r,
            exponent: self.exponent - divisor.exponent + qExpDelta
        )
        result.negate(if: self.isNegative != divisor.isNegative)
        return result
    }

    // MARK:- Multiplicative inverses
    // -------------------------------------
    @inlinable
    public var multiplicativeInverse: Self {
        return multiplicativeInverse_KnuthD
    }
    
    // -------------------------------------
    @inlinable
    public var multiplicativeInverse_NewtonRaphson: Self
    {
        if let result = multiplicativeInverseOfSpecialValue { return result }
        
        return multiplicativeInverse_NewtonRaphson_Core
    }
    
    // -------------------------------------
    /**
     Handles the core of calculating the multiplicative inverse.  Shared by
     division method and multiplicative inverse property, which both handle
     special cases, so this method does not, and for that reason should not be
     called directly.
     */
    @usableFromInline @inline(__always)
    internal var multiplicativeInverse_NewtonRaphson_Core: Self
    {
        typealias BiggerSig = WideUInt<RawSignificand>
        typealias BiggerFloat = WideFloat<BiggerSig>
        
        /*
         Using Newton's method to find the multiplicative inverse.  Given a good
         starting point, it doubles the number of good bits each iteration.
         */
        let s = significand.magnitude
        var x = s.multiplicativeInverse_NewtonRaphson0
        assert(!x.isNegative)
        let deltaExp = x._exponent + s._exponent

        let iterations = Int(log2(Double(RawSignificand.bitWidth))) - 4
        var two = Self.one
        two._exponent = 1
        
        var sx = BiggerFloat()
        var twoMinusSX = Self()
        
        let xBuf = x.mutableFloatBuffer()
        var sxBuf = sx.mutableFloatBuffer()
        var twoMinusSXBuf = twoMinusSX.mutableFloatBuffer()
        let sBuf = s.floatBuffer()
        let twoBuf = two.floatBuffer()
        
        if xBuf.significand.count > karatsubaCutoff
        {
            var scratch1 = RawSignificand()
            var scratch2 = RawSignificand()
            var scratch3 = BiggerSig()
            
            var s1Buf = scratch1.mutableBuffer()
            var s2Buf = scratch2.mutableBuffer()
            var s3Buf = scratch3.mutableBuffer()

            for _ in 0..<iterations
            {
                /*
                 There are two formulations
                    x = x * (2 - s * x)
                    x = x + x * (1 - s * x)
                 We're using the first one
                 */
                
                zeroBuffer(sxBuf.significand)
                let sxHigh = sBuf.multiply_karatsuba(
                    by: xBuf,
                    scratch1: &s1Buf,
                    scratch2: &s2Buf,
                    scratch3: &s3Buf,
                    result: &sxBuf
                )

                assert(!sxHigh.isZero)
                assert(!sxHigh.isNegative)
                
                FloatingPointBuffer.subtract(twoBuf, sxHigh, into: &twoMinusSXBuf)
                assert(!twoMinusSXBuf.isZero)

                zeroBuffer(sxBuf.significand)
                let xHigh = xBuf.multiply_karatsuba(
                    by: twoMinusSXBuf,
                    scratch1: &s1Buf,
                    scratch2: &s2Buf,
                    scratch3: &s3Buf,
                    result: &sxBuf
                )
                assert(!xHigh.isZero)
                copy(buffer: xHigh.uintBuf.immutable, to: xBuf.uintBuf)
            }
        }
        else
        {
            for _ in 0..<iterations
            {
                /*
                 There are two formulations
                    x = x * (2 - s * x)
                    x = x + x * (1 - s * x)
                 We're using the first one
                 */
                
                zeroBuffer(sxBuf.significand)
                let sxHigh = sBuf.multiply_schoolBook(by: xBuf, result: &sxBuf)
                assert(!sxHigh.isZero)
                assert(!sxHigh.isNegative)
                
                FloatingPointBuffer.subtract(twoBuf, sxHigh, into: &twoMinusSXBuf)
                assert(!twoMinusSXBuf.isZero)

                zeroBuffer(sxBuf.significand)
                let xHigh =
                    xBuf.multiply_schoolBook(by: twoMinusSXBuf, result: &sxBuf)
                assert(!xHigh.isZero)
                copy(buffer: xHigh.uintBuf.immutable, to: xBuf.uintBuf)
            }
        }

        assert(!x.isZero)

        x.addExponent(-self.exponent)
        x.addExponent(-deltaExp)
        assert(x.isNormalized, "x.sig = \(binary: x._significand)")

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
        
        let sig = self.significand
        let f80Value = sig.float80Value
        let f80Inverse = 1 / f80Value
        
        return Self(f80Inverse)
    }

    // -------------------------------------
    @inlinable
    public var multiplicativeInverse_KnuthD: Self
    {
        if let result = multiplicativeInverseOfSpecialValue { return result }

        return multiplicativeInverse_KnuthD_Core
    }
    
    // -------------------------------------
    /**
     Handles the core of calculating the multiplicative inverse.  Shared by
     division method and multiplicative inverse property, which both handle
     special cases, so this method does not, and for that reason should not be
     called directly.
     */
    @usableFromInline @inline(__always)
    internal var multiplicativeInverse_KnuthD_Core: Self
    {
        let sig = self.significand
        var dividendSig = RawSignificand.zero
        dividendSig.setBit(at: RawSignificand.bitWidth - 2, to: 1)
        var divisorSig = sig._significand
                
        var q = Quotient()
        var r = Remainder()
        
        let divisorBuf = divisorSig.mutableBuffer().immutable
        let dividendBuf = dividendSig.mutableBuffer().immutable
        let qBuf = q.mutableBuffer()
        let rBuf = r.mutableBuffer()

        divisorSig.setBit(at: RawSignificand.bitWidth - 1, to: 0)

        floatDivide_KnuthD(
            dividendBuf,
            by: divisorBuf,
            quotient: qBuf,
            remainder: rBuf
        )
        
        q.adjust()
        
        let fSig = sig.floatValue
        let fInv = 1 / fSig
        var x = Self(
            significandBitPattern: q.r,
            exponent: fInv.exponent
        )
        let deltaExp = -fSig.exponent - fInv.exponent
        x._exponent = -self._exponent + deltaExp
        x.negate(if: self.isNegative)
        return x
    }
    
    // MARK: - Special value handling
    // -------------------------------------
    /**
     Handles division involving NaNs, infinities and zeros, as well as
     cases where the result can be obtained purelfy from the exponents.
     
     This method is intended to separate the noise of special value handling
     from the main operation logic.
     
     - Returns: the result of the division, or `nil` if no special value
        was involved.
     */
    @usableFromInline @inline(__always)
    internal func divideSpecialValues(by right:Self) -> Self?
    {
        /*
         Ugh - all this conditional branching sucks.  Most of the conditions
         should be fairly predictable, though, as ideally dividing NaNs and
         infinities should be unusual.  However, dividing 0 is more common
         and IEEE 754 has special rules for signed 0s that we have to handle.
         */
        let hasSpecialValue =
            UInt8(self._exponent == Int.max) | UInt8(right._exponent == Int.max)
        if hasSpecialValue == 1
        {
            if UInt8(self.isNaN) | UInt8(right.isNaN) == 1
            {
                let hasSignalingNaN =
                    UInt8(self.isSignalingNaN) | UInt8(right.isSignalingNaN)
                
                if hasSignalingNaN == 1 {
                    Self.handleSignalingNaN(self, right)
                }
                
                // sNaNs are converted to qNaNs after being handled per IEEE 754
                return Self.nan
            }
            
            if self.isInfinite
            {
                if right.isInfinite { return Self.nan }
                
                if right.isZero
                {
                    var result = Self.infinity
                    result.negate(if: self.isNegative != right.isNegative)
                    return result
                }
                
                var result = Self.zero
                result.negate(if: self.isNegative != right.isNegative)
                return result
            }
            else if right.isInfinite
            {
                if self.isZero
                {
                    var result = Self.zero
                    result.negate(if: self.isNegative != right.isNegative)
                    return result
                }
                
                var result = Self.zero
                result.negate(if: self.isNegative != right.isNegative)
                return result
            }
        }
        
        if self.isZero
        {
            if right.isZero { return Self.nan }
            
            var result = Self.zero
            result.negate(if: self.isNegative != right.isNegative)
            return result
        }
        else if right.isZero
        {
            var result = Self.infinity
            result.negate(if: self.isNegative != right.isNegative)
            return result
        }
        
        // Handle underflow to 0, and overflow to infinity
        if right.exponent > 0
        {
            if Int.min + right.exponent > self.exponent
            {
                var result = Self.zero
                result.negate(if: self.isNegative != right.isNegative)
                return result
            }
        }
        else if Int.max + right.exponent <= self.exponent
        {
            var result = Self.infinity
            result.negate(if: self.isNegative != right.isNegative)
            return result
        }
        
        return nil
    }
    
    // -------------------------------------
    /**
     Handles finding the multiplicative inverse of NaNs, infinities and zero.
     
     This property is intended to separate the noise of special value handling
     from the main operation logic.
     
     - Returns: the result of the multiplicative inverse, or `nil` if no
        special value was involved.
     */
    @usableFromInline @inline(__always)
    internal var multiplicativeInverseOfSpecialValue: Self?
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
        
        return nil
    }
}
