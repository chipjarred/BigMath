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
extension WideFloat: AdditiveArithmetic
{
    public static var zero: WideFloat<T> { return Self() }
    
    // -------------------------------------
    public static prefix func - (x: Self) -> Self { return x.negated }
    
    // -------------------------------------
    public static func + (left: Self, right: Self) -> Self
    {
        /*
         Ugh - all this conditional branching sucks.  Most of the conditions
         should be fairly predictable, though, as ideally adding NaNs and
         infinities should be unusual.  However, adding 0 is more common and
         IEEE 754 has special rules for signed 0s that we have to handle.
         */
        if UInt8(left.isNaN) | UInt8(right.isNaN) == 1
        {
            if UInt8(left.isSignalingNaN) | UInt8(right.isSignalingNaN) == 1 {
                handleSignalingNaN(left, right)
            }
            
            // sNaNs are converted to qNaNs after being handled per IEEE 754
            return Self.nan
        }
        if left.isInfinite
        {
            let differentSigns = left.isNegative != right.isNegative
            if UInt8(right.isInfinite) & UInt8(differentSigns) == 1 {
                return Self.nan
            }
            return left
        }
        else if right.isInfinite { return right }
        
        if left.isZero
        {
            if right.isZero
            {
                // We have to take into account special signed 0 rules
                return left.isNegative == right.isNegative
                    ? left
                    : left.magnitude
            }
            return right
        }
        if right.isZero { return left }
        
        var result = Self()
        result.withMutableFloatBuffer
        {
            var resultBuf = $0
            left.withFloatBuffer
            { leftBuf in
                right.withFloatBuffer {
                    FloatingPointBuffer.add(leftBuf, $0, into: &resultBuf)
                }
            }
            $0.exponent = resultBuf.exponent
        }

        return result
    }
    
    // -------------------------------------
    public static func - (left: Self, right: Self) -> Self
    {
        /*
         Ugh - all this conditional branching sucks.  Most of the conditions
         should be fairly predictable, though, as ideally subtracting NaNs and
         infinities should be unusual.  However, subtracting 0 is more common
         and IEEE 754 has special rules for signed 0s that we have to handle.
         */
        if UInt8(left.isNaN) | UInt8(right.isNaN) == 1
        {
            if UInt8(left.isSignalingNaN) | UInt8(right.isSignalingNaN) == 1 {
                handleSignalingNaN(left, right)
            }
            
            // sNaNs are converted to qNaNs after being handled per IEEE 754
            return Self.nan
        }
        if left.isInfinite
        {
            let sameSigns = left.isNegative == right.isNegative
            if UInt8(right.isInfinite) & UInt8(sameSigns) == 1 {
                return Self.nan
            }
            return left
        }
        else if right.isInfinite { return right.negated }
        
        if left.isZero
        {
            if right.isZero
            {
                // We have to take into account special signed 0 rules
                return left.isNegative == right.isNegative
                    ? left.magnitude
                    : left
            }
            return right.negated
        }
        if right.isZero { return left }
        
        var result = Self()
        result.withMutableFloatBuffer
        {
            var resultBuf = $0
            left.withFloatBuffer
            { leftBuf in
                right.withFloatBuffer {
                    FloatingPointBuffer.subtract(leftBuf, $0, into: &resultBuf)
                }
            }
            $0.exponent = resultBuf.exponent
        }

        return result
    }
}
