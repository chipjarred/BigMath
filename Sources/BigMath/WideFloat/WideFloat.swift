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
public struct WideFloat<T: WideDigit> where T.Magnitude == T
{
    public typealias RawSignificand = T
    public typealias Exponent = Int
    
    @usableFromInline var exponent: Exponent
    @usableFromInline var _significand: RawSignificand
    
    // -------------------------------------
    public var significand: Self {
        return Self(significandBitPattern: _significand, exponent: 1)
    }
    
    // -------------------------------------
    /**
     The raw encoding of the value's significand field.
     
     The `significandBitPattern` property does not include the leading
     integral bit of the significand, even though `WideFloat` stores it
     explicitly, nor does it include the sign bit.
     */
    @inlinable
    public var significandBitPattern: RawSignificand
    {
        var result = _significand
        result &= (RawSignificand.max >> 2)
        result <<= 1
        return result
    }
    
    // -------------------------------------
    public var sign: FloatingPointSign
    {
        // These assertions are just in case the Swift team decides to change
        // their implementation of FloatingPointSign - they shouldn't but...
        assert(FloatingPointSign.plus.rawValue == 0)
        assert(FloatingPointSign.minus.rawValue == 1)
        return FloatingPointSign(rawValue: Int(isNegative))!
    }
    
    // -------------------------------------
    /**
     The raw encoding of the value's significand field.
     
     The `significandBitCount` property does not include the leading
     integral bit of the significand, even though `WideFloat` stores it
     explicitly, nor does it include the sign bit.
     */
    @inlinable
    public static var significandBitCount: Int {
        return RawSignificand.bitWidth - 2
    }
    
    // -------------------------------------
    @inlinable public var isNaN: Bool {
        return withFloatBuffer { return $0.isNaN }
    }
    
    // -------------------------------------
    @inlinable public var isSignalingNaN: Bool {
        return withFloatBuffer { return $0.isSignalingNaN }
    }
    
    // -------------------------------------
    @inlinable public var isInfinite: Bool {
        return withFloatBuffer { return $0.isInfinite }
    }
    
    // -------------------------------------
    @inlinable public var isNegative: Bool {
        return withFloatBuffer { return $0.isNegative }
    }
    
    // -------------------------------------
    @inlinable public var isZero: Bool {
        return withFloatBuffer { return $0.isZero }
    }
    
    // -------------------------------------
    @usableFromInline @inline(__always)
    internal var isNormalized: Bool {
        return withFloatBuffer { return $0.isNormalized }
    }
    
    // -------------------------------------
    @inlinable static public var infinity: Self
    {
        var result = Self()
        result.withMutableFloatBuffer { $0.setInfinity() }
        return result
    }
    
    // -------------------------------------
    @inlinable static public var nan: Self
    {
        var result = Self()
        result.withMutableFloatBuffer { $0.setNaN() }
        return result
    }

    // -------------------------------------
    @inlinable static public var signalingNaN: Self
    {
        var result = Self()
        result.withMutableFloatBuffer { $0.setSignalingNaN() }
        return result
    }
    
    // -------------------------------------
    @inlinable static public var greatestFiniteMagnigude: Self
    {
        var significand = RawSignificand()
        significand.invert()
        significand.setBit(at: RawSignificand.bitWidth - 1, to: 0)
        return Self(significandBitPattern: significand, exponent: Int.max - 1)
    }
    
    // -------------------------------------
    @inlinable static public var leastNormalMagnitude: Self
    {
        var significand = RawSignificand()
        significand.setBit(at: RawSignificand.bitWidth - 2, to: 1)
        return Self(significandBitPattern: significand, exponent: Int.min)
    }
    
    // -------------------------------------
    @inlinable static public var leastNonzeroMagnitude: Self {
        return leastNormalMagnitude
    }
    
    // -------------------------------------
    @inlinable public var magnitude: Self
    {
        var result = self
        result.negate(if: isNegative)
        return result
    }

    @inlinable public var float80Value: Float80 { convert(to: Float80.self) }
    @inlinable public var doubleValue: Double { convert(to: Double.self) }
    @inlinable public var floatValue: Float { convert(to: Float.self) }
    
    @inlinable public var uintValue: UInt { convert(to: UInt.self) }
    @inlinable public var uint64Value: UInt64 { convert(to: UInt64.self) }
    @inlinable public var uint32Value: UInt32 { convert(to: UInt32.self) }
    @inlinable public var uint16Value: UInt16 { convert(to: UInt16.self) }
    @inlinable public var uint8Value: UInt8 { convert(to: UInt8.self) }
    
    @inlinable public var intValue: Int { convert(to: Int.self) }
    @inlinable public var int64Value: Int64 { convert(to: Int64.self) }
    @inlinable public var int32Value: Int32 { convert(to: Int32.self) }
    @inlinable public var int16Value: Int16 { convert(to: Int16.self) }
    @inlinable public var int8Value: Int8 { convert(to: Int8.self) }

    // -------------------------------------
    @inlinable
    public init(significandBitPattern: RawSignificand, exponent: Int)
    {
        self._significand = significandBitPattern
        self.exponent = exponent
        self.normalize()
    }
    
    // -------------------------------------
    @inlinable
    public init()
    {
        self._significand = RawSignificand()
        self.exponent = 0
    }

    // -------------------------------------
    @inlinable
    public init<I: FixedWidthInteger>(_ source: I)
    {
        var s = source.magnitude
        var exp = I.bitWidth - s.leadingZeroBitCount - 1
        
        /*
         When source's Magnitude is bigger than our significand - 1 (for sign
         bit), we need to shift it down so we keep the most significant bits,
         but we need to handle rounding of the truncated part.
         
         Since MemoryLayouts are known at compile time this should be optimized
         away when it doesn't apply
         */
        if MemoryLayout<I.Magnitude>.size >= MemoryLayout<RawSignificand>.size
        {
            let sBitCount = I.Magnitude.bitWidth - s.leadingZeroBitCount
            let sigWidth = RawSignificand.bitWidth - 1
            let shift = sBitCount - sigWidth
            if shift > 0
            {
                s.roundingRightShift(by: shift)
                
                // There is a possibility that rounding might carry all the way
                // to the most signficant bit, so we have to test and maybe
                // shift again.
                let highBitMask = ~((I.Magnitude.max) >> 1)
                if s & highBitMask != 0
                {
                    // The only way the high bit would have been set is if s
                    // were all 1s.  In that case, the rounding made all the
                    // low bits 0, so we can just do a simple shift.
                    s >>= 1
                    exp += 1
                }
            }
        }
        
        self._significand = RawSignificand(s)
        self.exponent = exp
        
        // Normalize significand
        if self._significand.bit(at: RawSignificand.bitWidth - 1) {
            self._significand >>= 1 // leave room for sign bit
        }
        else if !self._significand.bit(at: RawSignificand.bitWidth - 2) {
            self._significand <<= self._significand.leadingZeroBitCount - 1
        }
        
        self.negate(if: source < 0)
    }
    
    // -------------------------------------
    @inlinable
    public init<F: BinaryFloatingPoint>(_ source: F)
    {
        guard !source.isNaN else
        {
            self.init()
            if source.isSignalingNaN {
                withMutableFloatBuffer { $0.setSignalingNaN() }
            }
            else { withMutableFloatBuffer { $0.setNaN() } }
            return
        }
        if source.isInfinite
        {
            self.init()
            withMutableFloatBuffer { $0.setInfinity() }
        }
        else
        {
            self.init(
                significandBitPattern:
                    Self.extractSignificandBits(from: source),
                exponent: 0
            )
            exponent = Exponent(source.exponent)
        }
        self.negate(if: source < 0)
    }
    
    // -------------------------------------
    @usableFromInline @inline(__always)
    static func extractSignificandBits<F: BinaryFloatingPoint>(
        from source: F) -> RawSignificand
    {
        /*
         We want to capture as many if the signficant bits of source as we can.
         We can hold RawSignificand.bitWidth-1 bits taking into account room
         for a sign bit. source.significandWidth + 1 gives us the number of
         bits to hold the source's signficand, including its integral bit.  So
         we want the minimum of those
         */
        let s = abs(source)
        let sigBitCount = min(RawSignificand.bitWidth, F.significandBitCount)
        
        let f = F(
            sign: .plus,
            exponent: -s.exponent + F.Exponent(sigBitCount),
            significand: 1
        )
        let dSignificand = floor(s * f)
        return RawSignificand(dSignificand)
    }
    
    // -------------------------------------
    @usableFromInline @inline(__always)
    internal mutating func normalize() {
        withMutableFloatBuffer { $0.normalize() }
    }
    
    // -------------------------------------
    @inlinable
    public mutating func negate() {
        withMutableFloatBuffer { $0.signBit ^= 1 }
    }
    
    // -------------------------------------
    @inlinable
    public var negated: Self
    {
        var r = self
        r.negate()
        return r
    }
    
    // -------------------------------------
    /// Branchless conditional negation
    @usableFromInline @inline(__always)
    internal mutating func negate(if doNegation: Bool) {
        withMutableFloatBuffer { $0.signBit ^= UInt(doNegation) }
    }
    
    // -------------------------------------
    @inlinable public func convert<F: BinaryFloatingPoint>(to: F.Type) -> F
    {
        if isNaN { return isSignalingNaN ? F.signalingNaN : F.nan }
        if isInfinite { return isNegative ? -F.infinity : F.infinity }
        
        if exponent >= F.greatestFiniteMagnitude.exponent
        {
            if exponent > F.greatestFiniteMagnitude.exponent
                || Self(F.greatestFiniteMagnitude) < self.magnitude
            {
                return isNegative ? -F.infinity : F.infinity
            }
        }
        else if exponent <= F.leastNonzeroMagnitude.exponent
        {
            if exponent < F.leastNonzeroMagnitude.exponent
                || Self(F.leastNonzeroMagnitude) < self.magnitude
            {
                return F(
                    sign: isNegative ? .minus : .plus,
                    exponent: 0,
                    significand: 0
                )
            }
        }
        
        return withFloatBuffer { return $0.convert(to: F.self) }
    }
    
    // -------------------------------------
    @inlinable public func convert<I: FixedWidthInteger>(to: I.Type) -> I
    {
        let maxRepresentableExponent = I.bitWidth - Int(I.isSigned)
        
        /*
         All of these tests are fast O(1) tests, so we use bitwise ops instead
         of booleans to avoid the hidden conditional branches in boolean
         short-circuit evaluation
         */
        var canBeRepresented = UInt8(!isNaN)
            & UInt8(!isInfinite)
            & (UInt8(I.isSigned) | UInt8(!self.isNegative))
            & UInt8(exponent <= maxRepresentableExponent)
        
        if canBeRepresented & UInt8(exponent == maxRepresentableExponent) == 1
        {
            if significandIsOne
            {
                /*
                 Strictly speaking, our value can't be represented by I, but
                 when initializing a WideFloat from the maximum magnitude of I,
                 we would round it up to our currrent value, so we allow
                 conversion back to that maximum magnitude.
                 */
                return UInt8(I.isSigned) & UInt8(isNegative) == 1
                    ? I.min
                    : I.max
            }
            canBeRepresented = 0
        }
        
        precondition(
            canBeRepresented == 1,
            "\(self) cannot be represented by \(I.self)"
        )
        
        return withFloatBuffer { return $0.convert(to: I.self) }
    }
    
    // -------------------------------------
    @usableFromInline @inline(__always)
    internal var significandIsZero: Bool {
        return withFloatBuffer { $0.significandIsZero }
    }

    // -------------------------------------
    @usableFromInline @inline(__always)
    internal var significandIsOne: Bool {
        return withFloatBuffer { $0.significandIsOne }
    }
    
    // -------------------------------------
    /**
     We don't currently do anything with sNaNs other than treat them as NaN,
     but this mechanism is in place for adding that support later.
     
     - Parameters:
        - possibleSignalingNaNs: Values, at least one of which should be a signaling NaN.
            Operations that call this method detect that one of its parameters is a signaling NaN, but in an
            effort to avoid conditional branching don't bother to sort out which one it is.  It's up to this
            handler to determine which are signaling NaNs and which aren't, and do the right thing with
            them.
     
     - Note: While at least one of the values should be a signaling NaN, the other values are not
        necessarily NaNs.  It's up to this routine to sort that out, if anything needs to be done at all.
     */
    @usableFromInline
    internal static func handleSignalingNaN(_ possibleSignalingNaNs: Self...) {
    }
    
    @usableFromInline @inline(__always)
    internal mutating func roundingRightShift(by shift: Int)
    {
        exponent = withMutableFloatBuffer
        {
            var buf = $0
            buf.rightShiftForAddOrSubtract(by: shift)
            return  buf.exponent
        }
    }

    // -------------------------------------
    @usableFromInline @inline(__always)
    internal func withFloatBuffer<R>(body: (FloatingPointBuffer) -> R) -> R
    {
        return _significand.withBuffer
        {
            let fBuf = FloatingPointBuffer(
                rawSignificand: $0.mutable,
                exponent: exponent
            )
            
            return body(fBuf)
        }
    }
    
    // -------------------------------------
    @usableFromInline @inline(__always)
    internal mutating func withMutableFloatBuffer<R>(
        body: (inout FloatingPointBuffer) -> R) -> R
    {
        return _significand.withMutableBuffer
        {
            var fBuf = FloatingPointBuffer(
                rawSignificand: $0,
                exponent: exponent
            )
            let result = body(&fBuf)
            self.exponent = fBuf.exponent
            return result
        }
    }
}
