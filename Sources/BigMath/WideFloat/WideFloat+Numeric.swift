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
        
        typealias WideProduct = WideFloat<WideUInt<RawSignificand>>
        var wideProduct = WideProduct()
        
        var leftSig = left._significand
        leftSig.setBit(at: RawSignificand.bitWidth - 1, to: 0)
        var rightSig = right._significand
        rightSig.setBit(at: RawSignificand.bitWidth - 1, to: 0)

        (wideProduct._significand.high, wideProduct._significand.low) =
            leftSig.multipliedFullWidth(by: rightSig)
        
        let halfWidth = WideProduct.RawSignificand.bitWidth / 2
        
        wideProduct.normalize()
        
        wideProduct.roundingRightShift(
            by: halfWidth
                + wideProduct._significand.high.leadingZeroBitCount - 1
        )
        
        if wideProduct._significand.low.signBit {
            wideProduct.roundingRightShift(by: 1)
        }
        
        var productExponent = left._exponent + right._exponent
        let expUpdate = wideProduct._exponent - halfWidth + 2
        if expUpdate > 0
        {
            if Int.max - expUpdate <= productExponent
            {
                var result = Self.infinity
                result.negate(if: left.isNegative != right.isNegative)
                return result
            }
        }
        else if Int.min - expUpdate > productExponent
        {
            var result = Self.zero
            result.negate(if: left.isNegative != right.isNegative)
            return result
        }
        
        productExponent += expUpdate

        var result = Self(
            significandBitPattern: wideProduct._significand.low,
            exponent: productExponent
        )
        assert(result.isNormalized)
        result.negate(if: left.isNegative != right.isNegative)
        return result
    }
    
    // -------------------------------------
    @inlinable
    public static func *= (left: inout Self, right: Self) {
        left = left * right
    }
}
