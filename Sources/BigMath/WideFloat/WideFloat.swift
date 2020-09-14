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
public struct WideFloat<T: WideDigit>
{
    public typealias RawSignificand = T
    public typealias Exponent = Int
    
    @usableFromInline var exponent: Exponent
    @usableFromInline var significand: RawSignificand
    
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
        significand.setBit(at: RawSignificand.bitWidth - 2, to: 0)
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
        self.significand = significandBitPattern
        self.exponent = exponent
        self.normalize()
    }
    
    // -------------------------------------
    @inlinable
    public init()
    {
        self.significand = RawSignificand()
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
            var shift = sBitCount - sigWidth
            if shift > 0
            {
                /*
                 For rounding, we do "bankers'" rounding because that's what
                 the Swift standard library does.
                 
                 In this case, adding "half" means adding half of the least
                 signficant bit we will not truncate, which is adding 1 to the
                 bit immediately to the right of it.
                 
                 If we get a carry out of the add, then we have rippled all
                 the way up to a new most signficant bit, which means we need to
                 increase the exponent.
                 */
                var halfBit: I.Magnitude = 0
                var mask = halfBit
                halfBit.setBit(at: shift - 1, to: 1)
                mask = (halfBit << 1) - 1
                let fract = s & mask
                var carry: I.Magnitude = 0
                if fract > halfBit || fract == halfBit && s.bit(at: shift) {
                    carry = s.addToSelfReportingCarry(halfBit)
                }
                let iCarry = Int(carry)
                shift &+= iCarry
                s >>= shift
                let highBitIndex = I.Magnitude.bitWidth - shift
                let existingHighBit = s.getBit(at: highBitIndex)
                s.setBit(at: highBitIndex, to: existingHighBit | carry)
                exp &+= iCarry

                /*
                 Technically, given a large enough integer, we could overflow
                 the exponent into "infinity", but even on systems where our
                 exponent is only 32-bits, an integer large enough to overflow
                 our exponent would have a significand so large as to overflow
                 the run-time stack just by creating it in the first place,
                 crashing the program, so this scenario is only theoretical.
                 
                 We did think about it, so the following line is left commented
                 out as purely informational.
                 
                 if exp == UInt.max { s = 0 } // Setting infinity
                 */
            }
        }
        
        self.significand = RawSignificand(s)
        self.exponent = exp
        
        // Normalize significand
        if self.significand.bit(at: RawSignificand.bitWidth - 1) {
            self.significand >>= 1 // leave room for sign bit
        }
        else if !self.significand.bit(at: RawSignificand.bitWidth - 2) {
            self.significand <<= self.significand.leadingZeroBitCount - 1
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
    @usableFromInline @inline(__always)
    internal func withFloatBuffer<R>(body: (FloatingPointBuffer) -> R) -> R
    {
        return significand.withBuffer
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
        return significand.withMutableBuffer
        {
            var fBuf =
                FloatingPointBuffer(rawSignificand: $0, exponent: exponent)
            defer { self.exponent = fBuf.exponent }
            return body(&fBuf)
        }
    }
}
