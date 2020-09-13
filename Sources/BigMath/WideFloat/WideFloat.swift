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

    @inlinable public var float80Value: Float80 { convert(to: Float80.self) }
    @inlinable public var doubleValue: Double { convert(to: Double.self) }
    @inlinable public var floatValue: Float { convert(to: Float.self) }
    
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
        let exp = I.bitWidth - s.leadingZeroBitCount - 1
        
        /*
         When source is bigger than our significand, we need to shift it down so
         we keep the most significant bits.
         
         Since MemoryLayouts are known at compile time this should be optimized
         away when it doesn't apply
         */
        if MemoryLayout<I.Magnitude>.size > MemoryLayout<RawSignificand>.size
        {
            let sBitCount = I.Magnitude.bitWidth - s.leadingZeroBitCount
            let sigWidth = RawSignificand.bitWidth - 1
            if sBitCount > sigWidth {
                s >>= sBitCount - sigWidth
            }
        }
        
        self.significand = RawSignificand(s)
        self.exponent = exp
        
        // Normalize significand
        if self.significand.bit(at: RawSignificand.bitWidth - 1) {
            self.significand >>= 1 // leave room for sign bit
        }
        else if self.significand.bit(at: RawSignificand.bitWidth - 2) {
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
    @inlinable public func convert<F: BinaryFloatingPoint>(to: F.Type) -> F {
        return withFloatBuffer { return $0.convert(to: F.self) }
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
