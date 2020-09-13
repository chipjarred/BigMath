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

infix operator <=> : ComparisonPrecedence

// -------------------------------------
/**
 Although inspired by the IEEE 754 standard, we're not super-faithful to it.
 We don't support subnormal values and we store the leading integral 1 for
 finite values.  Subnormal values would require handling offset exponents,
 which means having more conditional branches in basic operations.  Not storing
 the integral 1 likewise requires special case logic.  IEEE 754 does those
 things because it allows gradual underflow, and in the case of not storing the
 leading 1 allows one extra bit of precision, but it's also typically
 implemented in hardware, and for smaller numbers of bits than we're using.
 We don't actually want to waste bits if we dont have to, but speed is more
 important, and this library lets you create types with more bits.  More bits
 means slower runtime of course, but you can choose which is more important -
 more precision, but slower computation, or less precision with faster
 computation.  But whatever precision you choose, want it to run as fast as
 possible.  Besides, we're using `Int` for our exponents, which is 64 bits on
 most platforms.  Subnormals shouldn't be much of a problem with exponents that
 large.  Even a Plank length expressed in meters is incomprehensibly huge
 compared to the tiny numbers one can express with a negative 64-bit exponent
 before subnormals would be an issue.

 We do support NaN, sNaN, signed infinity and signed zeros.
 
 As with IEEE 425, the significand is kept as signed magnitude rather than 2's
 compliment.
 */
@usableFromInline
struct FloatingPointBuffer
{
    @usableFromInline var exponent: Int
    @usableFromInline var significand: MutableUIntBuffer
    
    // -------------------------------------
    @usableFromInline @inline(__always)
    var signBit: UInt
    {
        get { significand.last!.getBit(at: UInt.bitWidth - 1) }
        set
        {
            assert(newValue == 0 || newValue == 1)
            
            significand[significand.endIndex - 1].setBit(
                at: UInt.bitWidth - 1,
                to: newValue
            )
        }
    }

    // -------------------------------------
    var isNegative: Bool { return signBit == 1 }
    
    // -------------------------------------
    @inline(__always)
    private var significandTail: MutableUIntBuffer {
        return significand[..<(significand.endIndex - 1)]
    }
    
    // -------------------------------------
    /**
     The value of most signficant `UInt` of the signficand including its sign
     bit.
     */
    @inline(__always)
    private var significandHead: UInt
    {
        get { significand.last! }
        set { significand[significand.endIndex - 1] = newValue }
    }
    
    // -------------------------------------
    /**
     Magnitude of the most signficant `UInt` of the signficand.
     */
    @inline(__always)
    private var significandHeadValue: UInt
    {
        get { significandHead & (UInt.max >> 1)}
        set
        {
            assert(newValue & ~(UInt.max >> 1) == 0)
            
            significandHead = newValue | (significandHead & ~(UInt.max >> 1))
        }
    }

    // -------------------------------------
    @usableFromInline @inline(__always)
    internal subscript(index: Int) -> UInt
    {
        get { significand[significand.startIndex + index] }
        set { significand[significand.startIndex + index] = newValue }
    }
    
    // -------------------------------------
    /**
     `true` if all bits of the signficand except the sign bit, are `0`;
     otherwise, `false`.
     */
    @inline(__always)
    private var significandIsZero: Bool {
        return significandTail.reduce(significandHeadValue) { $0 | $1 } == 0
    }
    
    // -------------------------------------
    /**
     Infinity is encoded as exponent bits, including sign bit, all set to `1`,
     and significand set to `0`.
     */
    @usableFromInline @inline(__always)
    var isInfinite: Bool
    {
        if exponent == Int.min {
            return significandIsZero
        }
        
        return false
    }
    
    // -------------------------------------
    @inline(__always)
    private mutating func setInfinity()
    {
        exponent |= -1
        significandHeadValue = 1
        var sTail = significandTail
        for i in sTail.indices { sTail[i] = 0  }
    }

    // -------------------------------------
    /**
     `NaN` is encoded with exponent bits, except for sign bit set to `1` and
     non--zero value for signficand.
     */
    @usableFromInline @inline(__always)
    var isNaN: Bool
    {
        if exponent & Int.max == Int.max {
            return !significandIsZero
        }
        
        return false
    }
    
    // -------------------------------------
    @inline(__always)
    private mutating func setNaN()
    {
        exponent |= Int.max
        significandHeadValue = 1
    }

    // -------------------------------------
    /**
     `sNaN` is encoded with exponent bits, including the sign bit set to `1`
     and non--zero value for signficand.
     */
    @usableFromInline @inline(__always)
    var isSignalingNaN: Bool
    {
        if exponent == -1 {
            return !significandIsZero
        }
        
        return false
    }
    
    // -------------------------------------
    @inline(__always)
    private mutating func setSignalingNaN(to set: Bool = true)
    {
        exponent |= -1
        significandHeadValue = 1
    }
    
    // -------------------------------------
    /**
     A floating point number is considered normalized if it satisfies any of
     the following conditions
     
        1. The value is finite and it's most signficant bit non-sign bit  is `1`
        2. The value is finite contains the value `+0.0` or `-0.0`
        3. It represents `NaN`
        4. It represents `+Infinty` or `-Infinty`.
     */
    @usableFromInline @inline(__always)
    var isNormalized: Bool
    {
        // This handles NaN, sNaN, and +/- Infinity
        if exponent & Int.max == Int.max { return true }
        
        // If the significand is zero, the exponent must be zero
        if significandIsZero { return exponent == 0 }
        
        /*
         Otherwise the 2nd most significant bit, that is the integral bit, must
         be one.
         */
        let sigHead = significandHead
        return ((sigHead >> (UInt.bitWidth - 2)) & 1) == 1
    }
    
    // -------------------------------------
    /*
     Ignores sign bit when counting leading zeros.
     */
    @inline(__always)
    private var leadingSignficandZeroBitCount: Int
    {
        let sigHead = significandHeadValue
        assert(sigHead.leadingZeroBitCount > 0)
        var leadingZeros = sigHead.leadingZeroBitCount - 1
        if sigHead == 0 // head is +0 or -0
        {
            for digit in significandTail.reversed()
            {
                guard digit == 0 else
                {
                    leadingZeros += digit.leadingZeroBitCount
                    break
                }
                
                leadingZeros += UInt.bitWidth
            }
        }
        
        return leadingZeros
    }
    
    // -------------------------------------
    @usableFromInline @inline(__always)
    mutating func normalize()
    {
        // NaN, sNaN and infinities are already normalized
        if exponent & Int.max == Int.max { return }
        
        // totalBits doesn't include sign bit
        let totalBits = significand.count * UInt.bitWidth - 1
        let leadingZeros = leadingSignficandZeroBitCount
        
        if leadingZeros == totalBits
        {
            /*
             We have an all-zero significand.  That's 0.  If the exponent is not
             zero, then we have to set it to zero.  We *could* conditionally
             test for that, but it's faster and has the same logical outcome
             if we just set it to 0 unconditionally.
             */
            exponent = 0
            return
        }
        
        let savedSign = signBit
        BigMath.leftShift(buffer: significand, by: leadingZeros)
        signBit = savedSign
        exponent -= leadingZeros
        assert(isNormalized)
    }
    
    // -------------------------------------
    @usableFromInline
    func convert<F: BinaryFloatingPoint>(to: F.Type) -> F
    {
        let radix = F(
            sign: .plus,
            exponent: F.Exponent(UInt.bitWidth),
            significand: 1
        )
        var result = F(significandHeadValue)
        
        for digit in significandTail.reversed()
        {
            result *= radix
            result += F(digit)
        }
        
        let sign = select(
            if: isNegative,
            then: FloatingPointSign.minus.rawValue,
            else: FloatingPointSign.plus.rawValue
        )
        result *= F(
            sign: FloatingPointSign(rawValue: sign)!,
            exponent: F.Exponent(exponent) - result.exponent,
            significand: 1
        )
        
        return result
    }
    

    // MARK:- Initializers
    // -------------------------------------
    @inline(__always)
    private init(
        significand: MutableUIntBuffer,
        exponent: Int,
        isNegative: Bool)
    {
        self.exponent = exponent
        self.significand = significand
        self.signBit = UInt(isNegative)
        
        self.normalize()
    }
    
    // -------------------------------------
    @usableFromInline @inline(__always)
    internal init(
        rawSignificand: MutableUIntBuffer,
        exponent: Int)
    {
        self.exponent = exponent
        self.significand = rawSignificand
    }

    // -------------------------------------
    /**
     - Parameters:
        - fixedpoint: A buffer of `UInt` digits interpreted as having a fixed
            radix point immediately to the right of the digit at
            `onesPlaceIndex`, though `onesPlaceIndex` may not actually be
            within the buffer indices.  The least significant digit in the
            buffer must be at `fixedpoint.startIndex`.  The value represented
            by `fixedpoint` is interpreted as *unsigned*.  Use the `isNegative`
            parameter to specify whether it is positive or negative.
        - onesPlaceIndex: 0-based index relative to the start of `fixedpoint`
            for the digit in the ones place.  It is *not* necessary that
            `onesPlaceIndex` be within number of digits in fixedpoints, nor
            even that it be positive.  This value is used for calculating the
            exponent for floating point representation.  Placing it outside of
            the range of digit indices in `fixedpoint` is a useful way of
            saying that the number is shifted away from the radix point by more
            positions than the precision of the number allows to be represented
            (ie. for a one digit number with a digit `X` and `onesPlaceIndex`
            of `-1` indices that the number should be treated as `0.X`).  Also
            note that `onesPlaceIndex = 0` refers to the same position as
            `fixedpoint.startIndex`.
        - isNegative: Set to `true` to indicate the value in `fixedpoint` is
            the magnitude of a negative number.
     */
    @usableFromInline @inline(__always)
    internal init(
        fixedpoint: MutableUIntBuffer,
        onesPlaceIndex: Int,
        isNegative: Bool)
    {
        assert(fixedpoint.count > 0, "Must have room for at least one digit.")
        
        let maxDigitIndex = fixedpoint.count - 1
        
        /*
         The fixed point representation puts the radix point immediately to the
         right of the digit at onesPlaceIndex.  We want to be able to treat it
         like a denormalized floating point, because then we can call our
         private initializer that will handle normalizing it.  To do that,
         we need to calculate the correct exponent that allows us to treat it
         together with fixedpoint as a denormalized floating point.  The
         floating point reprensentation puts the radix point immediately to the
         right of the most significant magnitude bit of the buffer, which is
         just to the right of the sign bit.
         
         We start by moving the radix point immediately to the right of the
         most signficant digit position in the buffer
         */
        var exponent = (maxDigitIndex - onesPlaceIndex) * UInt.bitWidth
        
        /*
         Then we move it immediately to the right of the most signficant
         non-sign bit.
         */
        exponent += UInt.bitWidth - 2
        
        self.init(
            significand: fixedpoint,
            exponent: exponent,
            isNegative: isNegative
        )
    }
    
    // -------------------------------------
    @usableFromInline @inline(__always)
    static func makeNaN(signaling: Bool, with buffer: MutableUIntBuffer) -> Self
    {
        assert(buffer.count > 0, "Must have room for at least one digit.")

        buffer.baseAddress!.pointee |= 1
        return Self(
            significand: buffer,
            exponent: select(if: signaling, then: -1, else: Int.max),
            isNegative: false
        )
    }
    
    // -------------------------------------
    @usableFromInline @inline(__always)
    static func makeInfinity(
        isNegative: Bool,
        with buffer: MutableUIntBuffer) -> Self
    {
        assert(buffer.count > 0, "Must have room for at least one digit.")

        zeroBuffer(buffer)
        return Self(significand: buffer, exponent: -1, isNegative: isNegative)
    }
    
    // MARK:-
    // -------------------------------------
    @usableFromInline
    enum ComparisonResult: Int
    {
        case orderedAscending = -1
        case orderedSame = 0
        case orderedDescending = 1
        case unordered = 2
        
        // This initializer can't be used to set .unordered.
        @inline(__always) fileprivate init(_ x: Int)
        {
            let xIsNegative = Int(x < 0)
            let xIsPositive = Int(x > 0)
            self.init(rawValue: (-xIsNegative & -1) | (-xIsPositive & 1))!
        }
    }
    
    // -------------------------------------
    @usableFromInline @inline(__always)
    static func <=> (left: Self, right: Self) -> ComparisonResult
    {
        assert(left.isNormalized && right.isNormalized)
        assert(left.significand.count == right.significand.count)
        
        let leftIsSpecialCase = left.exponent & Int.max == Int.max
        let rightIsSpecialCase = right.exponent & Int.max == Int.max
        
        if leftIsSpecialCase || rightIsSpecialCase
        {
            /*
             If either is NaN then the result is unordered.
             */
            if (leftIsSpecialCase && left.significandIsZero)
                || (rightIsSpecialCase && right.significandIsZero)
            {
                return .unordered
            }
            
            /*
             Neither is NaN, so the special case must be infinity. The
             correct results for those will fall out naturally from the
             normal finite number comparisons.  However, since our "official"
             encoding for infinity sets all exponent bits, and so far we've
             only tested the non-sign bits. We do assert that the exponent sign
             bit is set, because if it's not we've made a mistake somewhere.
             */
            assert(!leftIsSpecialCase  || left.exponent == -1)
            assert(!rightIsSpecialCase  || right.exponent == -1)
        }
        
        let leftSign = left.signBit
        let rightSign = right.signBit
        let signResult = ComparisonResult(rawValue: Int(leftSign &- rightSign))!
        guard signResult == .orderedSame else { return signResult }
        
        /*
         With the easy case of differing significand signs being handled,
         We know left and right are either both positive or both negative.
         We pretend that they're both positive, and then fix up for the
         negative case at the end.
         
         We can start with a fast comparision of the exponents, because we
         require left and right to be normalized.
         */
        var result = left.exponent - right.exponent
        if result == 0
        {
            /*
             With exponents the same, we have no choice but to do the O(n)
             check of the signficands.  Because the most significant digit
             contains the sign bit we have to handle it separately from the
             tail.
             */
            result =
                Int(left.significandHeadValue) - Int(right.significandHeadValue)
            if result == 0
            {
                result = compareBuffers(
                    left.significandTail,
                    right.significandTail).rawValue
            }
        }
        
        /*
         The only thing left to do is to fix up for when both are negative.
         We have to invert the result if they are.  For example 10 > 9 but
         -10 < -9.  Since we already know the two have the same sign, we only
         need to use one of the signs to do this.
         */
        result = select(if: leftSign == 1, then: -result, else: result)
        return ComparisonResult(result)
    }
    
    // -------------------------------------
    @usableFromInline @inline(__always)
    mutating func negate() {
        self.signBit = self.signBit ^ 1
    }
    
    // -------------------------------------
    @inline(__always)
    private func rightShift(into dst: inout Self, by shift: Int)
    {
        assert(dst.significand.count == self.significand.count)
        assert(shift >= 0)
                
        // Save the sign bit in case dst aliases self
        let savedSignBit = self.signBit

        BigMath.rightShift(
            from: self.significand.immutable,
            to: dst.significand,
            by: shift
        )
        
        /*
         We just shifted the sign bit.  We need to clear that shifted sign bit,
         and set the actual sign bit appropriately
         */
        let shiftedSignBitIndex =
            dst.significand.count * UInt.bitWidth - shift - 1
        setBit(at: shiftedSignBitIndex, in: &dst.significand, to: 0)
        dst.signBit = savedSignBit

        /*
         Now that the shift is done, we just need to adjust the dst exponent
         so that dst maintains its value (except that it's lost some precision
         now).
         */
        dst.exponent += shift
    }
    
    // -------------------------------------
    @inline(__always)
    private func leftShift(into dst: inout Self, by shift: Int)
    {
        assert(dst.significand.count == self.significand.count)
        assert(shift >= 0)
        
        // Save the sign bit in case dst aliases self
        let savedSignBit = self.signBit
                
        BigMath.leftShift(
            from: self.significand.immutable,
            to: dst.significand,
            by: shift
        )
        
        // We just shifted the sign bit away, so we have to restore it.
        dst.signBit = savedSignBit

        /*
         Now that the shift is done, we just need to adjust the dst exponent
         so that dst maintains its value.
         */
        dst.exponent -= shift
    }
    
    // -------------------------------------
    @inline(__always)
    private static func add(x: Self, y: Self, into z: inout Self)
    {
        assert(x.isNormalized && y.isNormalized)
        assert(x.significand.count == y.significand.count)
        assert(x.significand.count == z.significand.count)
        
        /*
         We have to align exponents, but we can't modify our inputs, so we
         shift-copy the one with the smaller exponent into the result, and do
         the addition there.
         */
        let expDiff = x.exponent - y.exponent
        if expDiff <= 0
        {
            x.leftShift(into: &z, by: -expDiff)
            z.addToSelfWithSameExponents(y)
        }
        else
        {
            y.leftShift(into: &z, by: expDiff)
            z.addToSelfWithSameExponents(x)
        }
    }
    
    // -------------------------------------
    @inline(__always)
    private static func subtract(x: Self, y: Self, into z: inout Self)
    {
        assert(x.isNormalized && y.isNormalized)
        assert(x.significand.count == y.significand.count)
        assert(x.significand.count == z.significand.count)
    
        /*
         We have to align exponents, but we can't modify our inputs, so we
         shift-copy the one with the smaller exponent into the result, and do
         the subtraction there.
         */
        let expDiff = x.exponent - y.exponent
        if expDiff <= 0
        {
            x.leftShift(into: &z, by: -expDiff)
            z.subtractFromSelfWithSameExponents(y)
            
            // We've just computed z = x - y, which is what want, so we're good.
        }
        else
        {
            y.leftShift(into: &z, by: expDiff)
            z.subtractFromSelfWithSameExponents(x)
            
            /*
             We've just computed z = y - x, but we want z = x - y.  We have to
             invert the sign bit (x - y == -(y - x))
             */
            z.signBit ^= 1
        }
    }

    // -------------------------------------
    @inline(__always)
    private mutating func addToSelfWithSameExponents(_ y: Self)
    {
        var x = self
        assert(x.significand.count == y.significand.count)
        assert(x.exponent == y.exponent)
        
        if x.signBit == y.signBit
        {
            var carry = addReportingCarry(
                x.significandTail.immutable,
                y.significandTail.immutable,
                result: x.significandTail
            )
            carry = x.significandHead.addToSelfReportingCarry(y.significandHead)
            if carry != 0
            {
                x.rightShift(into: &x, by: 1)
                x.significandHead.setBit(at: UInt.bitWidth - 2, to: 1)
            }
        }
        else
        {
            var borrow = subtractReportingBorrow(
                x.significandTail.immutable,
                y.significandTail.immutable,
                result: x.significandTail
            )
            borrow = x.significandHead.subtractFromSelfReportingBorrow(
                y.significandHead
            )
            if borrow != 0
            {
                /*
                 If we borrow out of the high bit we need invert our sign, but
                 the integer subtraction we just did will have put our
                 significand in twos compliment form, and we want it in signed
                 magnitude, so we have to convert it.
                 */
                let invertedSignBit = x.signBit ^ 1
                arithmeticNegate(x.significand.immutable, to: x.significand)
                x.signBit = invertedSignBit
            }
        }
        
        self.normalize()
    }
    
    // -------------------------------------
    @inline(__always)
    private mutating func subtractFromSelfWithSameExponents(_ y: Self)
    {
        var x = self
        assert(x.significand.count == y.significand.count)
        assert(x.exponent == y.exponent)
        
        if x.signBit != y.signBit
        {
            var carry = addReportingCarry(
                x.significandTail.immutable,
                y.significandTail.immutable,
                result: x.significandTail
            )
            carry = x.significandHead.addToSelfReportingCarry(y.significandHead)
            if carry != 0
            {
                x.rightShift(into: &x, by: 1)
                x.significandHead.setBit(at: UInt.bitWidth - 2, to: 1)
            }
        }
        else
        {
            var borrow = subtractReportingBorrow(
                x.significandTail.immutable,
                y.significandTail.immutable,
                result: x.significandTail
            )
            borrow = x.significandHead.subtractFromSelfReportingBorrow(
                y.significandHead
            )
            if borrow != 0
            {
                /*
                 If we borrow out of the high bit we need invert our sign, but
                 the integer subtraction we just did will have put our
                 significand in twos compliment form, and we want it in signed
                 magnitude, so we have to convert it.
                 */
                let invertedSignBit = x.signBit ^ 1
                arithmeticNegate(x.significand.immutable, to: x.significand)
                x.signBit = invertedSignBit
            }
        }
        
        self.normalize()
    }
}

// MARK:- Comparable conformance
// -------------------------------------
/*
 Because NaNs always compare .unordered, we have to implement all comparisons.
 */
extension FloatingPointBuffer: Comparable
{
    // -------------------------------------
    @usableFromInline @inline(__always)
    static func == (left: Self, right: Self) -> Bool {
        return (left <=> right) == .orderedSame
    }
    
    // -------------------------------------
    @usableFromInline @inline(__always)
    static func != (left: Self, right: Self) -> Bool
    {
        let compareResult = left <=> right
        var result = UInt8(compareResult != .orderedSame)
        result &= UInt8(compareResult != .unordered)
        return result == 1
    }
    
    // -------------------------------------
    @usableFromInline @inline(__always)
    static func < (left: Self, right: Self) -> Bool {
        return (left <=> right) == .orderedAscending
    }
    
    // -------------------------------------
    @usableFromInline @inline(__always)
    static func > (left: Self, right: Self) -> Bool {
        return (left <=> right) == .orderedDescending
    }
    
    // -------------------------------------
    @usableFromInline @inline(__always)
    static func <= (left: Self, right: Self) -> Bool
    {
        let compareResult = left <=> right
        var result = UInt8(compareResult != .orderedAscending)
        result &= UInt8(compareResult != .unordered)
        return result == 1
    }
    
    // -------------------------------------
    @usableFromInline @inline(__always)
    static func >= (left: Self, right: Self) -> Bool
    {
        let compareResult = left <=> right
        var result = UInt8(compareResult != .orderedDescending)
        result &= UInt8(compareResult != .unordered)
        return result == 1
    }
}
