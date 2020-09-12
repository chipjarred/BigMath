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
    
    @inlinable public var float80Value: Float80 { convertTo(to: Float80.self) }
    @inlinable public var doubleValue: Double { convertTo(to: Double.self) }
    @inlinable public var floatValue: Float { convertTo(to: Float.self) }

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
    public init<I: FixedWidthInteger>(_ source: I)
    {
        let significand = RawSignificand(source.magnitude)
        self.init(significandBitPattern: significand, exponent: 0)
        self.negate(if: source < 0)
    }
    
    // -------------------------------------
    @inlinable
    public init<F: BinaryFloatingPoint>(_ source: F)
    {
        assert(
            F.radix == 2,
            "Sorry, only support binary (radix = 2) floating point values"
        )
        
        self.init(
            significandBitPattern: Self.extractSignificandBits(from: source),
            exponent: 0
        )
        assert(isNormalized)
        exponent = Exponent(source.exponent)
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
    @inlinable
    public init(_ source: Decimal)
    {
        /*
         Initializing from a Decimal is a pain, because it's not clear exactly
         how its stored.  It supports a compact and non-compact version.
         
         There's almost certainly a better way than we do here, but since so
         much of Decimal's implementation is undocumented, we do the converson
         the slow way for now.
         
         We need to get its mantissa.  For ordinary floating point types we
         divide by the value's binade, but Decimal doesn't support binade, so
         we have to make one for ourselves.
         */
        let binade =
            Decimal(sign: .plus, exponent: source.exponent, significand: 1)
        var mantissa = source / binade
        
        /*
         At this point we have Decimal's mantissa as an integer, but it's still
         stored as Decimal.  It could be too big for native integer types,
         and we don't want truncate the full width of a Decmial.  Since
         WideInteger can be initialized from a Double, we convert the Decimal
         to Double, but that looses precision.  So we have to convert the
         Double back to Decimal and subtract from the Decimal mantissa so we
         can get at those lost bits.  We repeat that process until the
         Decimal's mantissa has been reduced to less than 1. (Just in case
         there is some rounding error somewhere that causes it not to go to 0
         exactly).
         */
        var significand = RawSignificand(0)
        repeat
        {
            let dblSig = (mantissa as NSDecimalNumber).doubleValue
            mantissa -= Decimal(dblSig)
            significand += RawSignificand(dblSig)
        } while mantissa >= 1
        
        // Now we can use our FixedWidthInteger initializer
        self.init(significand)

        // Then correct the sign and exponent
        self.negate(if: source < 0)
        self.exponent = Exponent(source.exponent)
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
    @inlinable public func convertTo<F: BinaryFloatingPoint>(to: F.Type) -> F {
        return withFloatBuffer { return $0.convertTo(to: F.self) }
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
