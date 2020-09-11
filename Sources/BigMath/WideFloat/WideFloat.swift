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
public struct WideFloat<T: WideDigit>
{
    public typealias Significand = T
    public typealias Exponent = Int
    
    @usableFromInline var exponent: Exponent
    @usableFromInline var significand: Significand
    
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
    @inlinable
    public init(significandBitPattern: Significand, exponent: Int)
    {
        self.significand = significandBitPattern
        self.exponent = exponent
        self.normalize()
    }
    
    // -------------------------------------
    @inlinable
    public init<I: FixedWidthInteger>(_ source: I)
    {
        let significand = Significand(source.magnitude)
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
        
        let dSignificand = abs(source / source.binade)
        self.init(
            significandBitPattern: Significand(dSignificand),
            exponent: Exponent(source.exponent)
        )
        self.negate(if: source < 0)
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
    @usableFromInline @inline(__always)
    internal func withFloatBuffer<R>(body: (FloatingPointBuffer) -> R) -> R
    {
        return significand.withBuffer
        {
            let fBuf = FloatingPointBuffer(
                significand: $0.mutable,
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
            var fBuf = FloatingPointBuffer(significand: $0, exponent: exponent)
            defer { self.exponent = fBuf.exponent }
            return body(&fBuf)
        }
    }
}
