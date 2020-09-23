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
extension WideFloat: Numeric
{
    // -------------------------------------
    @inlinable
    public init?<T>(exactly source: T) where T : BinaryInteger
    {
        guard let significand = RawSignificand(exactly: source.magnitude) else {
            return nil
        }
        
        if MemoryLayout<T.Magnitude>.size >= MemoryLayout<RawSignificand>.size {
            if significand.leadingZeroBitCount == 0 { return nil }
        }
        self.init(significand)
        self.negate(if: source < 0)
    }
    
    // -------------------------------------
    @inlinable
    public static func * (left: Self, right: Self) -> Self
    {
        if let result = multiplySpecialValues(left, right) { return result }
                
        return left.multiply_Core(right)
    }
    
    // -------------------------------------
    /**
     Shared by multiplication and some division methods.
     */
    @usableFromInline @inline(__always)
    internal func multiply_Core(_ other: Self) -> Self
    {
        typealias WideProduct = WideFloat<WideUInt<RawSignificand>>
        var z = WideProduct()
        
        // Compute significand product
        let x = self.magnitude
        let y = other.magnitude
        
        let xBuf = x.floatBuffer()
        let yBuf = y.floatBuffer()
        var zBuf = z.mutableFloatBuffer()
        
        if useKaratsuba
        {
            var scratch1 = RawSignificand()
            var scratch2 = RawSignificand()
            var scratch3 = WideProduct.RawSignificand()
            
            var s1Buf = scratch1.mutableBuffer()
            var s2Buf = scratch2.mutableBuffer()
            var s3Buf = scratch3.mutableBuffer()
            
            _ = xBuf.multiply_karatsuba(
                by: yBuf,
                scratch1: &s1Buf,
                scratch2: &s2Buf,
                scratch3: &s3Buf,
                result: &zBuf
            )
        }
        else {
            _ = xBuf.multiply_schoolBook(by: yBuf, result: &zBuf)
        }
        
        var result = Self(
            significandBitPattern: z._significand.high,
            exponent: z.exponent
        )
        result.negate(if: self.isNegative != other.isNegative)
        return result
    }
    
    @inline(__always)
    private var useKaratsuba: Bool
    {
        return MemoryLayout<RawSignificand>.size >
            karatsubaCutoff * MemoryLayout<UInt>.size
    }
    
    // -------------------------------------
    /**
     Shared by multiplication and some division methods.
     */
    @usableFromInline @inline(__always)
    internal func multiply_Core_old(_ other: Self) -> Self
    {
        typealias WideProduct = WideFloat<WideUInt<RawSignificand>>
        var wideProduct = WideProduct()
        
        // Compute significand product
        var leftSig = self._significand
        leftSig.setBit(at: RawSignificand.bitWidth - 1, to: 0)
        var rightSig = other._significand
        rightSig.setBit(at: RawSignificand.bitWidth - 1, to: 0)

        (wideProduct._significand.high, wideProduct._significand.low) =
            leftSig.multipliedFullWidth(by: rightSig)
        
        let halfWidth = WideProduct.RawSignificand.bitWidth / 2
        
        wideProduct._exponent = 0
        wideProduct.normalize()

        wideProduct.roundingRightShift(
            by: halfWidth
                + wideProduct._significand.high.leadingZeroBitCount - 1
        )
        
        if wideProduct._significand.low.signBit {
            wideProduct.roundingRightShift(by: 1)
        }
        
        // Adjust exponents
        wideProduct.addExponent(2 - halfWidth)
        wideProduct.addExponent(self._exponent)
        wideProduct.addExponent(other._exponent)

        var result = Self(
            significandBitPattern: wideProduct._significand.low,
            exponent: wideProduct._exponent
        )
        assert(result.isNormalized)
        result.negate(if: self.isNegative != other.isNegative)
        return result
    }

    // -------------------------------------
    @inlinable
    public static func *= (left: inout Self, right: Self) {
        left = left * right
    }
    
    // MARK: - Special value handling
    // -------------------------------------
    /**
     Handles multiplication involving NaNs, infinities and zeros, as well as
     cases where the result can be obtained purelfy from the exponents.
     
     This method is intended to separate the noise of special value handling
     from the main operation logic.
     
     - Returns: the result of the multiplication, or `nil` if no special value
        was involved.
     */
    @usableFromInline @inline(__always)
    internal static func multiplySpecialValues(
        _ left: Self,
        _ right:Self) -> Self?
    {
        /*
         Ugh - all this conditional branching sucks.  Most of the conditions
         should be fairly predictable, though, as ideally multiplying NaNs and
         infinities should be unusual.  However, multiplying 0 is more common
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
                if right.isZero { return Self.nan }

                var result = Self.infinity
                result.negate(if: left.isNegative != right.isNegative)
                return result
            }
            else if right.isInfinite
            {
                if left.isZero { return Self.nan }
                
                var result = Self.infinity
                result.negate(if: left.isNegative != right.isNegative)
                return result
            }
        }
        
        if UInt8(left.isZero) | UInt8(right.isZero) == 1
        {
            var result = Self.zero
            result.negate(if: left.isNegative != right.isNegative)
            return result
        }
        
        // Handle underflow and overflow
        let leftExponentLessThan0 = left._exponent < 0
        if leftExponentLessThan0 == (right._exponent < 0)
        {
            if leftExponentLessThan0
            {
                if Int.min - left._exponent > right._exponent
                {
                    var result = Self.zero
                    result.negate(if: left.isNegative != right.isNegative)
                    return result
                }
            }
            else if Int.max - left._exponent <= right._exponent
            {
                var result = Self.infinity
                result.negate(if: left.isNegative != right.isNegative)
                return result
            }
        }

        return nil
    }
}
