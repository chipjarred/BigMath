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
    // -------------------------------------
    @inlinable
    public static prefix func - (x: Self) -> Self { return x.negated }
    
    // -------------------------------------
    @inlinable
    public static func + (left: Self, right: Self) -> Self
    {
        if let result = left.addSpecialValues(right) { return result }
        
        var result = Self()
        var resultBuf = result.mutableFloatBuffer()
        let leftBuf = left.floatBuffer()
        let rightBuf = right.floatBuffer()
        
        FloatingPointBuffer.add(leftBuf, rightBuf, into: &resultBuf)

        return result
    }
    
    // -------------------------------------
    @inlinable
    public static func - (left: Self, right: Self) -> Self
    {
        if let result = left.subtractSpecialValues(right) { return result }
        
        var result = Self()
        var resultBuf = result.mutableFloatBuffer()
        let leftBuf = left.floatBuffer()
        let rightBuf = right.floatBuffer()

        FloatingPointBuffer.subtract(leftBuf, rightBuf, into: &resultBuf)

        return result
    }
    
    // MARK: - Special value handling
    // -------------------------------------
    /*
     Handles addition involving NaNs, infinities and zeros.
     
     This method is intended to separate the noise of special value handling
     from the main operation logic.
     
     - Returns: the result of the addition, or `nil` if no special value was
        involved.
     */
    @usableFromInline @inline(__always)
    internal func addSpecialValues(_ other:Self) -> Self?
    {
        let selfBuf = self.floatBuffer()
        let otherBuf = other.floatBuffer()
        
        /*
         Ugh - all this conditional branching sucks.  Most of the conditions
         should be fairly predictable, though, as ideally adding NaNs and
         infinities should be unusual.  However, adding 0 is more common and
         IEEE 754 has special rules for signed 0s that we have to handle.
         */
        let hasSpecialValue =
            UInt8(selfBuf.isSpecialValue) | UInt8(otherBuf.isSpecialValue)
        if hasSpecialValue == 1
        {
            if UInt8(selfBuf.isNaN) | UInt8(otherBuf.isNaN) == 1
            {
                let hasSignalingNaN = UInt8(selfBuf.isSignalingNaN)
                    | UInt8(otherBuf.isSignalingNaN)
                
                if hasSignalingNaN == 1 { Self.handleSignalingNaN(self, other) }
                
                // sNaNs are converted to qNaNs after being handled per IEEE 754
                return Self.nan
            }
            if selfBuf.isInfinite
            {
                let differentSigns = selfBuf.isNegative != otherBuf.isNegative
                if UInt8(otherBuf.isInfinite) & UInt8(differentSigns) == 1 {
                    return Self.nan
                }
                return self
            }
            else if otherBuf.isInfinite { return other }
        }
        
        if selfBuf.isZero
        {
            if otherBuf.isZero
            {
                // We have to take into account special signed 0 rules
                return selfBuf.isNegative == otherBuf.isNegative
                    ? self
                    : self.magnitude
            }
            return other
        }
        if otherBuf.isZero { return self }
        return nil
    }

    // -------------------------------------
    /*
     Handles subtraction involving NaNs, infinities and zeros.
     
     This method is intended to separate the noise of special value handling
     from the main operation logic.
     
     - Returns: the result of the subtraction, or `nil` if no special value was
        involved.
     */
    @usableFromInline @inline(__always)
    internal func subtractSpecialValues(_ other:Self) -> Self?
    {
        let selfBuf = self.floatBuffer()
        let otherBuf = other.floatBuffer()
        
        /*
         Ugh - all this conditional branching sucks.  Most of the conditions
         should be fairly predictable, though, as ideally subtracting NaNs and
         infinities should be unusual.  However, subtracting 0 is more common
         and IEEE 754 has special rules for signed 0s that we have to handle.
         */
        let hasSpecialValue =
            UInt8(selfBuf.isSpecialValue) | UInt8(otherBuf.isSpecialValue)
        if hasSpecialValue == 1
        {
            if UInt8(selfBuf.isNaN) | UInt8(otherBuf.isNaN) == 1
            {
                let hasSignalingNaN = UInt8(selfBuf.isSignalingNaN)
                    | UInt8(otherBuf.isSignalingNaN)
                
                if hasSignalingNaN == 1 { Self.handleSignalingNaN(self, other) }
                
                // sNaNs are converted to qNaNs after being handled per IEEE 754
                return Self.nan
            }
            if selfBuf.isInfinite
            {
                let sameSigns = selfBuf.isNegative == otherBuf.isNegative
                if UInt8(otherBuf.isInfinite) & UInt8(sameSigns) == 1 {
                    return Self.nan
                }
                return self
            }
            else if otherBuf.isInfinite { return other.negated }
        }
        
        if selfBuf.isZero
        {
            if otherBuf.isZero
            {
                // We have to take into account special signed 0 rules
                return selfBuf.isNegative == otherBuf.isNegative
                    ? self.magnitude
                    : self
            }
            return other.negated
        }
        if otherBuf.isZero { return self }

        return nil
    }
}
