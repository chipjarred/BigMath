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

 We do support NaN, sNaN, signed infinity and signed zeros; however, since we
 don't used offset exponents,  we can't use `-1` (all ones) to encode these as
 IEEE 754 does.  Instead, we use `Int.max` in the  exponent.  To distinquish
 between them, we the two least signficant bits of the significand bits.  The
 other bits are don't care bits, except in the case of the infinity, for which
 the sign bit applies.  In the following table X indicates that the bit is not
 used, qNaN refers to *quiet* NaN (ordinary), and sNaN refers to signaling NaN
 
                    +----------+-----------------------+
                    | Exponent |    Significand Bits   |
                    |   Value  | Sign  | Bit 1 | Bit 0 |
        +-----------+----------+-------+-------+-------+
        | +Infinity |  Int.max |   0   |   0   |   0   |
        | -Infinity |  Int.max |   1   |   0   |   0   |
        |   qNaN    |  Int.max |   X   |   0   |   1   |
        |   sNaN    |  Int.max |   X   |   1   |   1   |
        +-----------+----------+-------+-------+-------+

 As with IEEE 754, the significand is kept as signed magnitude rather than 2's
 compliment.
 */
@usableFromInline
struct FloatingPointBuffer
{
    @usableFromInline var uintBuf: MutableUIntBuffer
    
    var exponentIndex: Int { uintBuf.endIndex - 1}

    @usableFromInline @inline(__always)
    var exponent: Int
    {
        get { Int(bitPattern: uintBuf[exponentIndex]) }
        set { uintBuf[exponentIndex] = UInt(bitPattern: newValue) }
    }
    
    @usableFromInline @inline(__always)
    var significand: MutableUIntBuffer
    {
        get { uintBuf[..<exponentIndex] }
        set
        {
            assert(newValue.count == uintBuf[..<exponentIndex].count)
            uintBuf[..<exponentIndex] = newValue
        }
    }

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
    @usableFromInline @inline(__always)
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
    /**
     `true` if all bits of the signficand except the sign bit, are `0`;
     otherwise, `false`.
     */
    @usableFromInline @inline(__always)
    internal var significandIsZero: Bool {
        return significandTail.reduce(significandHeadValue) { $0 | $1 } == 0
    }
    
    // -------------------------------------
    /**
     `true` if the value is` +0` or` -0`; otherwise `false`
     
     It does an O(1) check by exploiting that we keep the significand
     normalized.  If the exponent is` Int.min`, and the significand head value is `0`,
     then the value is `0`.
     */
    @usableFromInline @inline(__always)
    var isZero: Bool
    {
        assert(isNormalized, "Must be normalized for this test to work")
        assert(exponent != Int.min || significandHeadValue == 0)
        return exponent == Int.min
    }
    
    // -------------------------------------
    @usableFromInline @inline(__always)
    internal mutating func setZero()
    {
        exponent = Int.min
        significandHeadValue = 0
        let tail = significandTail
        if tail.count > 0 { zeroBuffer(tail) }
    }

    // -------------------------------------
    /**
     `true` if the most significant non-sign bit of the sigificand is `1` and
     all lower bits are `0`; otherwise `false`
     */
    @usableFromInline @inline(__always)
    internal var significandIsOne: Bool
    {
        let mask: UInt = 1 << (UInt.bitWidth - Int(2))
        return significandHeadValue & mask == mask
            && significandTail.reduce(0) { $0 | $1 } == 0
    }
    
    // -------------------------------------
    /**
     Infinity is encoded as exponent bits, including sign bit, all set to `1`,
     and significand set to `0`.
     */
    @usableFromInline @inline(__always)
    var isInfinite: Bool
    {
        if exponent == Int.max {
            return significand.baseAddress!.pointee & 3 == 0
        }
        
        return false
    }
    
    // -------------------------------------
    @usableFromInline @inline(__always)
    internal mutating func setInfinity()
    {
        exponent = Int.max
        var s = significand.baseAddress!.pointee
        s &= UInt.max ^ 3
        significand.baseAddress!.pointee = s
    }

    // -------------------------------------
    /**
     `NaN` is encoded with exponent bits, except for sign bit set to `1` and
     non--zero value for signficand.
     */
    @usableFromInline @inline(__always)
    var isNaN: Bool
    {
        if exponent == Int.max {
            return significand.baseAddress!.pointee & 1 == 1
        }
        
        return false
    }
    
    // -------------------------------------
    @usableFromInline @inline(__always)
    internal mutating func setNaN()
    {
        exponent = Int.max
        significand.baseAddress!.pointee = 1
    }

    // -------------------------------------
    /**
     `sNaN` is encoded with exponent bits, including the sign bit set to `1`
     and non--zero value for signficand.
     */
    @usableFromInline @inline(__always)
    var isSignalingNaN: Bool
    {
        if exponent == Int.max {
            return significand.baseAddress!.pointee & 3 == 3
        }
        
        return false
    }
    
    // -------------------------------------
    @usableFromInline @inline(__always)
    internal mutating func setSignalingNaN(to set: Bool = true)
    {
        exponent = Int.max
        significand.baseAddress!.pointee = 3
    }
    
    // -------------------------------------
    /// `true` for NaNs and infinity; otherwise `false`
    @usableFromInline @inline(__always)
    internal var isSpecialValue: Bool { return exponent == Int.max }
    
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
        if exponent == Int.max { return true }
        
        // If the significand is zero, the exponent must be Int.min
        if significandIsZero { return exponent == Int.min }
        
        /*
         Otherwise the 2nd most significant bit, that is the integral bit, must
         be one.
         */
        let sigHead = significandHead
        return sigHead.bit(at:UInt.bitWidth - 2)
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
    /*
     Ignores sign bit when counting non-zero bits.
     */
    @inline(__always)
    private var nonZeroSignificandBitCount: Int
    {
        let sigHead = significandHeadValue

        var leadingZeros = sigHead.nonzeroBitCount
        
        for digit in significandTail.reversed() {
            leadingZeros += digit.nonzeroBitCount
        }

        return leadingZeros
    }

    // -------------------------------------
    @usableFromInline @inline(__always)
    mutating func normalize()
    {
        // NaN, sNaN and infinities are already normalized
        if exponent == Int.max { return }
        
        // totalBits doesn't include sign bit
        let totalBits = significand.count * UInt.bitWidth - 1
        let leadingZeros = leadingSignficandZeroBitCount
        
        if leadingZeros == totalBits
        {
            /*
             We have an all-zero significand.  That's 0.  If the exponent is not
             zero, then we have to set it to Int.min.  We *could* conditionally
             test for that, but it's faster and has the same logical outcome
             if we just set it to Int.min unconditionally.
             */
            exponent = Int.min
            return
        }
        
        self.leftShift(into: &self, by: leadingZeros)
        
        assert(isNormalized)
    }
    
    // -------------------------------------
    /**
     - Important: This method will simply copy/shift the bits of the
     significand into the result.  Assuming the result is large enough to hold
     the shifted signficant bits, which will result in the proper integer value,
     but *it will truncate high bits of integers that don't fit into the result
     type*.  If that's not OK, the calling code
     should check **before** calling this method.
     
     The same is true for checking if the floating point is negative, and the
     result type is unsigned.
     
     NaNs and Infinity should also be handled before calling this method.
     */
    @usableFromInline @inline(__always)
    func convert<I: FixedWidthInteger>(to: I.Type) -> I
    {
        assert(!isNaN && !isInfinite)
        guard exponent >= 0 else { return I() }

        var result = I.Magnitude()
        
        result.withMutableBuffer
        {
            var resultBuf = $0
            let commonLen = min(significand.count, resultBuf.count)
            let s = significand[..<(significand.startIndex + commonLen)]
            
            BigMath.leftShiftKnuth(
                s.immutable,
                by: exponent - I.Magnitude.bitWidth + 2,
                into: &resultBuf
            )
            
            if isNegative && (exponent + 1) < I.Magnitude.bitWidth
            {
                // Convert from signed magnitude to twos complement
                BigMath.setBit(at: exponent + 1, in: &resultBuf, to: 0)
                BigMath.arithmeticNegate(resultBuf.immutable, to: resultBuf)
            }
        }
        
        return unsafeBitCast(result, to: I.self)
    }
    
    
    // -------------------------------------
    @usableFromInline @inline(__always)
    func convert(to: Float.Type) -> Float
    {
        assert(exponent != Int.max)
        
        if isZero || exponent < Float.leastNonzeroMagnitude.exponent
        {
            var result = Float.zero
            if isNegative { result.negate() }
            return result
        }
        if exponent > Float.greatestFiniteMagnitude.exponent
        {
            var result = Float.infinity
            if isNegative { result.negate() }
            return result
        }
        
        let shift = Float.significandBitCount
        var sigHead = significandHead
        sigHead &= (UInt.max >> 2)
        sigHead.roundingRightShift(by: (UInt.bitWidth - 2) - shift)
        
        return Float(
            sign: FloatingPointSign(rawValue:
                select(
                    if: isNegative,
                    then: FloatingPointSign.minus.rawValue,
                    else: FloatingPointSign.plus.rawValue
                )
            )!,
            exponentBitPattern: UInt(exponent &+ 127),
            significandBitPattern: UInt32(sigHead)
        )
    }
    
    // -------------------------------------
    @usableFromInline @inline(__always)
    func convert(to: Double.Type) -> Double
    {
        assert(exponent != Int.max)
        
        if isZero || exponent < Double.leastNonzeroMagnitude.exponent
        {
            var result = Double.zero
            if isNegative { result.negate() }
            return result
        }
        if exponent > Double.greatestFiniteMagnitude.exponent
        {
            var result = Double.infinity
            if isNegative { result.negate() }
            return result
        }
        
        let shift = Double.significandBitCount
        var sigHead = significandHead
        sigHead &= (UInt.max >> 2)
        sigHead.roundingRightShift(by: (UInt.bitWidth - 2) - shift)

        return Double(
            sign: FloatingPointSign(rawValue:
                select(
                    if: isNegative,
                    then: FloatingPointSign.minus.rawValue,
                    else: FloatingPointSign.plus.rawValue
                )
            )!,
            exponentBitPattern: UInt(exponent &+ 1023),
            significandBitPattern: UInt64(sigHead)
        )
    }

    // -------------------------------------
    @usableFromInline @inline(__always)
    func convert<F: BinaryFloatingPoint>(to: F.Type) -> F
    {
        if isZero
        {
            var result: F = 0
            if isNegative { result.negate() }
            return result
        }
        
        let radix = F(
            sign: .plus,
            exponent: F.Exponent(UInt.bitWidth),
            significand: 1
        )
        
        var result: F = 0
        for digit in significandTail
        {
            result /= radix
            result += F(digit)
        }
        
        result += F(significandHeadValue)

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
    
    // -------------------------------------
    @usableFromInline @inline(__always)
    func convert_saved<F: BinaryFloatingPoint>(to: F.Type) -> F
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
    @usableFromInline @inline(__always)
    internal init(wideFloatUIntBuffer: MutableUIntBuffer) {
        self.uintBuf = wideFloatUIntBuffer
    }
    
    // -------------------------------------
    @usableFromInline @inline(__always)
    static func makeNaN(signaling: Bool, with buffer: MutableUIntBuffer) -> Self
    {
        assert(buffer.count > 0, "Must have room for at least one digit.")

        buffer.baseAddress!.pointee |= (1 | (UInt(signaling) << 1))
        var result = Self(wideFloatUIntBuffer: buffer)
        result.exponent = Int.max
        return result
    }
    
    // -------------------------------------
    @usableFromInline @inline(__always)
    static func makeInfinity(
        isNegative: Bool,
        with buffer: MutableUIntBuffer) -> Self
    {
        assert(buffer.count > 0, "Must have room for at least one digit.")

        buffer.baseAddress!.pointee = 0
        var result = Self(wideFloatUIntBuffer: buffer)
        result.exponent = Int.max
        result.signBit = UInt(isNegative)
        return result
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
        
        let leftSign = Int(left.signBit)
        let rightSign = Int(right.signBit)

        let hasSpecialValue = UInt8(left.exponent == Int.max)
            | UInt8(right.exponent == Int.max)
        if hasSpecialValue == 1
        {
            if UInt8(left.isNaN) | UInt8(right.isNaN) == 1 {
                return .unordered
            }
            if left.isInfinite
            {
                if right.isInfinite {
                    return ComparisonResult(rightSign &- leftSign)
                }
                
                return ComparisonResult(
                    select(if: leftSign == 1, then: -1, else: 1)
                )
            }
            return ComparisonResult(
                select(if: rightSign == 1, then: 1, else: -1)
            )
        }
        
        if left.isZero
        {
            if right.isZero { return .orderedSame }
            return ComparisonResult(
                select(if: rightSign == 1, then: 1, else: -1)
            )
        }
        else if right.isZero
        {
            return ComparisonResult(
                select(if: leftSign == 1, then: -1, else: 1)
            )
        }
        
        let signResult = ComparisonResult(rawValue: rightSign &- leftSign)!
        guard signResult == .orderedSame else { return signResult }
        
        /*
         With the easy case of differing significand signs handled,
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
        let savedSignBit = dst.signBit
        
        /*
         Zeroing the sign bit unconditionally then restoring it makes the logic
         simpler.
         */
        dst.signBit = 0

        BigMath.rightShift(
            from: self.significand.immutable,
            to: dst.significand,
            by: shift
        )
        
        dst.signBit = savedSignBit

        /*
         Now that the shift is done, we just need to adjust the dst exponent
         so that dst maintains its value (except that it's lost some precision
         now).
         */
        dst.exponent = self.exponent
        dst.addExponent(shift)
    }
    
    // -------------------------------------
    /**
     Special case of right shifting meant for use in adding and subtracting.
     Needs to handle rounding of the bit that will be the least significant
     shift after shifting.
     
     The "normal" right shift doesn't bother with rounding.  It just truncates.
     */
    @usableFromInline @inline(__always)
    internal mutating func rightShiftForAddOrSubtract(by shift: Int)
    {
        assert(shift >= 0)
        
        guard exponent <= Int.max &- shift else
        {
            setInfinity()
            return
        }
        
        BigMath.roundingRightShift(
            from: self.significand.immutable,
            to: self.significand,
            by: shift
        )
        
        addExponent(shift)
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
        dst.exponent = self.exponent
        dst.addExponent(-shift)
    }
    
    // -------------------------------------
    @usableFromInline @inline(__always)
    internal static func add(_ x: Self, _ y: Self, into z: inout Self)
    {
        assert(!x.isNaN && !y.isNaN)
        assert(!x.isInfinite && !y.isInfinite)
        assert(x.isNormalized && y.isNormalized)
        assert(x.significand.count == y.significand.count)
        assert(x.significand.count == z.significand.count)
        
        if x.signBit == y.signBit {
            addUnalignedMagnitudes(x, y, result: &z)
        }
        else { subtractUnalignedMagnitudes(x, y, result: &z) }
    }
    
    // -------------------------------------
    @usableFromInline @inline(__always)
    internal static func subtract(_ x: Self, _ y: Self, into z: inout Self)
    {
        assert(!x.isNaN, "x.exponent = \(x.exponent), x.isNaN - \(x.isNaN)")
        assert(!y.isNaN, "y.exponent = \(y.exponent), y.isNaN - \(y.isNaN)")
        assert(!x.isInfinite && !y.isInfinite)
        assert(x.isNormalized && y.isNormalized)
        assert(x.significand.count == y.significand.count)
        assert(x.significand.count == z.significand.count)
        
        if x.signBit != y.signBit
        {
            addUnalignedMagnitudes(x, y, result: &z)
            if z.signBit != x.signBit { z.negate() }
        }
        else { subtractUnalignedMagnitudes(x, y, result: &z) }
    }
    
    // -------------------------------------
    @inline(__always)
    private func digitAndShift(forRightShift shift: Int)
        -> (digitIndex: Int, bitShift: Int)
    {
        let digitIndexShift: Int =
            MemoryLayout<UInt>.size == MemoryLayout<UInt64>.size
            ? 6
            : 5

        return (
            digitIndex: shift >> digitIndexShift,
            bitShift: shift & (UInt.bitWidth - 1)
        )
    }
        
    // -------------------------------------
    @inline(__always)
    private static func addUnalignedMagnitudes(
        _ x: Self,
        _ y: Self,
        result z: inout Self)
    {
        assert(!x.isNaN && !y.isNaN)
        assert(!y.isInfinite && !y.isInfinite)
        assert(x.significand.startIndex == 0)
        assert(y.significand.startIndex == 0)
        assert(x.significand.count == y.significand.count)
        assert(x.significand.count == z.significand.count)
        assert(x.isNormalized && y.isNormalized)

        // We want x to have the larger exponent, so if it's not, we exploit
        // commutativity by just wapping them.
        var x = x
        var y = y
        if x.exponent < y.exponent { swap(&x, &y) }
        
        let exponentDelta = x.exponent - y.exponent
        z.exponent = x.exponent
        
        /*
         If y's exponent puts it's most significant bit more than one bit to
         the right of x's least signficant bit, then it has no effect on the
         sum, even with rounding.  z's exponent is already set, so just copy
         x's significand into z, and we're done.
         */
        if exponentDelta > x.significand.count * UInt.bitWidth + 1
        {
            BigMath.copy(buffer: x.significand.immutable, to: z.significand)
            z.signBit = x.signBit
            return
        }
        
        var carry = roundingBit(
            forRightShift: exponentDelta,
            of: y.significand.immutable
        )
        
        let (yDigitIndex, yShift) =
            y.digitAndShift(forRightShift: exponentDelta)
        
        var xPtr = x.significand.baseAddress!
        let xHeadPtr = xPtr + x.significand.count - 1
        
        let yStart = y.significand.baseAddress!
        let yEnd = yStart + y.significand.count
        let yHeadPtr = yEnd - 1
        var yPtr = yStart + yDigitIndex
        
        var zPtr = z.significand.baseAddress!
        
        var yDigitLow = yPtr < yEnd
            ?   (yPtr == yHeadPtr ? y.significandHeadValue : yPtr.pointee)
            :   0
        
        yPtr += 1
        
        while xPtr < xHeadPtr
        {
            let xDigit = xPtr.pointee
            
            let yDigitHigh = yPtr < yEnd
                ?   (yPtr == yHeadPtr ? y.significandHeadValue : yPtr.pointee)
                :   0
            let yDigit =
                (yDigitLow >> yShift) | (yDigitHigh << (UInt.bitWidth - yShift))
            yDigitLow = yDigitHigh

            var zDigit: UInt
            (zDigit, carry) = xDigit.addingReportingCarry(carry)
            carry &+= zDigit.addToSelfReportingCarry(yDigit)
            zPtr.pointee = zDigit
            
            xPtr += 1
            yPtr += 1
            zPtr += 1
        }
        
        let xHead = x.significandHeadValue
        
        let yDigitHigh = yPtr < yEnd
            ?   (yPtr == yHeadPtr ? y.significandHeadValue : yPtr.pointee)
            :   0

        let yHead =
            (yDigitLow >> yShift) | (yDigitHigh << (UInt.bitWidth - yShift))
        
        var (zHead, _) = xHead.addingReportingCarry(carry)
        _ = zHead.addToSelfReportingCarry(yHead)
        z.significandHead = zHead

        /*
         zHead has room for sign bit, and any carry would have propagated to
         it.  Since we haven't set the sign yet, if it's 1, then we need
         to right shift z by 1.
         
         rightShiftForAddOrSubtract takes care of possible additional
         shift/rounding that might occur as a result of rounding carries
         propagating all the way up the sign bit.  It also handles setting
         infinity if the exponent will be set to Int.max
         */
        while zHead & ~(UInt.max >> 1) != 0
        {
            z.rightShiftForAddOrSubtract(by: 1)
            zHead = z.significandHead
        }
        
        // Now we set the sign bit and normalize
        z.signBit = x.signBit
        z.normalize()
    }
    
    // -------------------------------------
    @inline(__always)
    private static func subtractUnalignedMagnitudes(
        _ x: Self,
        _ y: Self,
        result z: inout Self)
    {
        assert(!x.isNaN && !y.isNaN)
        assert(!y.isInfinite && !y.isInfinite)
        assert(x.significand.count == y.significand.count)
        assert(x.significand.count == z.significand.count)
        assert(x.isNormalized && y.isNormalized)
        
        /*
         We want x to have the larger exponent, so if it's not, we swap them,
         but that means we need to invert the sign bit from the natural result
         at the end.
         */
        var x = x
        var y = y
        var resultSign = x.signBit
        if x.exponent < y.exponent
        {
            swap(&x, &y)
            resultSign ^= 1
        }
        
        let exponentDelta = x.exponent - y.exponent
        z.exponent = x.exponent
        
        /*
         If y's exponent puts it's most significant bit more than one bit to
         the right of x's least signficant bit, then it has no effect on the
         sum, even with rounding.  z's exponent is already set, so just copy
         x's significand into z, and we're done.
         */
        if exponentDelta > x.significand.count * UInt.bitWidth + 1
        {
            BigMath.copy(buffer: x.significand.immutable, to: z.significand)
            z.signBit = x.signBit
            return
        }
        
        var borrow = roundingBit(
            forRightShift: exponentDelta,
            of: y.significand.immutable
        )
        
        let (yDigitIndex, yShift) =
            y.digitAndShift(forRightShift: exponentDelta)
        
        var xPtr = x.significand.baseAddress!
        let xHeadPtr = xPtr + x.significand.count - 1
        
        let yStart = y.significand.baseAddress!
        let yEnd = yStart + y.significand.count
        let yHeadPtr = yEnd - 1
        var yPtr = yStart + yDigitIndex
        
        var zPtr = z.significand.baseAddress!
        
        var yDigitLow = yPtr < yEnd
            ?   (yPtr == yHeadPtr ? y.significandHeadValue : yPtr.pointee)
            :   0
        
        yPtr += 1
        
        while xPtr < xHeadPtr
        {
            let xDigit = xPtr.pointee
            
            let yDigitHigh = yPtr < yEnd
                ?   (yPtr == yHeadPtr ? y.significandHeadValue : yPtr.pointee)
                :   0
            let yDigit =
                (yDigitLow >> yShift) | (yDigitHigh << (UInt.bitWidth - yShift))
            yDigitLow = yDigitHigh

            var zDigit: UInt
            (zDigit, borrow) = xDigit.subtractingReportingBorrow(borrow)
            borrow &+= zDigit.subtractFromSelfReportingBorrow(yDigit)
            zPtr.pointee = zDigit
            
            xPtr += 1
            yPtr += 1
            zPtr += 1
        }
        
        let xHead = x.significandHeadValue

        let yDigitHigh = yPtr < yEnd
            ?   (yPtr == yHeadPtr ? y.significandHeadValue : yPtr.pointee)
            :   0

        let yHead =
            (yDigitLow >> yShift) | (yDigitHigh << (UInt.bitWidth - yShift))
        var (zHead, _) = xHead.subtractingReportingBorrow(borrow)
        _ = zHead.subtractFromSelfReportingBorrow(yHead)
        z.significandHead = zHead

        /*
         zHead has room for sign bit, and any borrow would have propagated to
         it.  Since we haven't set the sign yet, if it's 1, then
         subtracting y from x gives the opposite sign of x, so we need to
         invert resultSign, and our result is now in 2's complement form, which
         means we need to arithmetically negate it to put it back into signed
         magnitude form.
         */
        if zHead & ~(UInt.max >> 1) != 0
        {
            resultSign ^= 1
            BigMath.arithmeticNegate(z.significand.immutable, to: z.significand)
        }
        
        // Now we set the sign bit and normalize
        z.signBit = resultSign
        z.normalize()
    }
    
    // -------------------------------------
    /**
     Multiply this `FloatingPointBuffer` by another using the school book
     method.
     
     Caller must handle signs, including for infinities and zero.

     - Parameters:
        - other: Muptiplier.  Must be positive and be the same precision as the
            receiving `FloatingPointBuffer`.
        - result: `FloatingPoint` buffer to receive the result.  Must be twice
            the precision of the receiving `FloatingPointBuffer`.

     
     - Returns: A `FloatingPointBuffer` referring to the upper half of `result`.
     */
    @usableFromInline @inline(__always)
    internal func multiply_schoolBook(by other: Self, result: inout Self)
        -> Self
    {
        assert(self.significand.count == other.significand.count)
        assert(result.significand.count == 2 * self.significand.count)
        
        if UInt8(self.isSpecialValue) | UInt8(other.isSpecialValue) == 1
        {
            if UInt8(self.isNaN) | UInt8(other.isNaN) == 1 {
                result.setNaN()
            }
            else { result.setInfinity() }
            
            return result.upperHalf()
        }
                
        let zSig = result.significand

        let halfWidth = zSig.count / 2
        let midIndex = zSig.startIndex &+ halfWidth

        let zSigLow = zSig[..<midIndex]
        let zSigHigh = zSig[midIndex...]
        
        assert(zSigLow.count == zSigHigh.count)
        
        BigMath.fullMultiplyBuffers_SchoolBook(
            self.significand.immutable,
            other.significand.immutable,
            result: zSig
        )
        
        result.exponent = 2
        result.normalize()
        result.addExponent(self.exponent)
        result.addExponent(other.exponent)
        result.assertNormalized()

        assert(!result.isNegative)
        result.assertNormalized()
        return result.upperHalf()
    }
    
    // -------------------------------------
    /**
     Multiply this `FloatingPointBuffer` by another using the karatsuba
     method.
     
     Caller must handle signs, including for infinities and zero.

     - Parameters:
        - other: Muptiplier.  Must be positive and be the same precision as the
            receiving `FloatingPointBuffer`.
        - scratch1: `MutableUIntBuffer` which must be at least as large as the
            receiving `FloatingPointBuffer`'s significand
        - scratch2: `MutableUIntBuffer` which must be at least as large as the
            receiving `FloatingPointBuffer`'s significand
        - scratch2: `MutableUIntBuffer` which must be at least **twice** as
            large as the receiving `FloatingPointBuffer`'s significand
        - result: `FloatingPoint` buffer to receive the result.  Must be twice
            the precision of the receiving `FloatingPointBuffer`.

     
     - Returns: A `FloatingPointBuffer` referring to the upper half of `result`.
     */
    @usableFromInline @inline(__always)
    internal func multiply_karatsuba(
        by other: Self,
        scratch1: inout MutableUIntBuffer,
        scratch2: inout MutableUIntBuffer,
        scratch3: inout MutableUIntBuffer,
        result: inout Self
        ) -> Self
    {
        assert(self.significand.count == other.significand.count)
        assert(result.significand.count == 2 * self.significand.count)
        assert(scratch1.count >= self.significand.count)
        assert(scratch2.count >= self.significand.count)
        assert(scratch3.count >= 2 * self.significand.count)
        
        if UInt8(self.isSpecialValue) | UInt8(other.isSpecialValue) == 1
        {
            if UInt8(self.isNaN) | UInt8(other.isNaN) == 1 {
                result.setNaN()
            }
            else { result.setInfinity() }
            
            return result.upperHalf()
        }
                
        let zSig = result.significand

        let halfWidth = zSig.count / 2
        let midIndex = zSig.startIndex &+ halfWidth

        let zSigLow = zSig[..<midIndex]
        let zSigHigh = zSig[midIndex...]
        
        assert(zSigLow.count == zSigHigh.count)
        
        BigMath.fullMultiplyBuffers_Karatsuba(
            self.significand.immutable,
            other.significand.immutable,
            scratch1: scratch1,
            scratch2: scratch2,
            scratch3: scratch3,
            result: zSig
        )
        
        result.exponent = 2
        result.normalize()
        result.addExponent(self.exponent)
        result.addExponent(other.exponent)
        result.assertNormalized()

        assert(!result.isNegative)
        result.assertNormalized()
        return result.upperHalf()
    }

    // -------------------------------------
    @inline(__always)
    private func assertNormalized()
    {
        #if DEBUG
        if isNormalized { return }
        
        assertionFailure("FloatingPointBuffer not normalized!!!\n\(dumpStr)")
        #endif
    }
    
    // -------------------------------------
    private var dumpStr: String
    {
        return
            """
               exponent = \(exponent) : 0b\(binary: exponent)
            significand = 0b\(binary: significand)
            """
    }
    
    // -------------------------------------
    private func dump(){
        print(dumpStr)
    }
        
    // -------------------------------------
    @usableFromInline @inline(__always)
    internal mutating func addExponent(_ other: Int)
    {
        // -------------------------------------
        @inline(__always) func addExponents(_ x: Int, _ y: Int) -> Int
        {
            if y < 0 {
                if Int.min &- y > x { return Int.min }
            }
            else if Int.max &- y < x { return Int.max }
            
            return x &+ y
        }
        
        if isSpecialValue { return }
        
        exponent = addExponents(exponent, other)
        if exponent == Int.max { setInfinity() }
        else if exponent == Int.min { setZero() }
    }
    
    // -------------------------------------
    /*
     Obtain a `FloatingPointBuffer` alias into the receiving
     `FloatingPointBuffer` that is half the receiver's precision, and
     appropriately rounded.
     
     The receiver must be normalized and non-negative
     
     - Note: the receiver is modified in the process, becuase of the aliasing!
     */
    @inline(__always)
    private mutating func upperHalf() -> FloatingPointBuffer
    {
        assert(isNormalized)
        assert(!isNegative)
        
        let halfSigWidth = (uintBuf.count &- 1) / 2
        let midPointIndex = uintBuf.startIndex &+ halfSigWidth
        let highBuf = uintBuf[midPointIndex...]
        var high = FloatingPointBuffer(wideFloatUIntBuffer: highBuf)
        
        if UInt8(isSpecialValue) | UInt8(isZero) == 1
        {
            if isNaN
            {
                if isSignalingNaN { high.setSignalingNaN() }
                else { high.setNaN() }
            }
            else if isInfinite { high.setInfinity() }
            else if isZero { high.setZero() }
            return high
        }
        
        // With special value handling out of the way, what we need to do is
        // round the upperhalf of the significand as though we were going to
        // do rounding right shift.  In fact, we're just going to point past
        // the lower half, which is faster than actually shifting.
        let halfSigBitWidth = halfSigWidth * UInt.bitWidth
        let highSig = high.significand
        let highSigImmutable = highSig.immutable
        
        let rBit = roundingBit(
            forRightShift: halfSigBitWidth,
            of: significand.immutable
        )
        _ = addReportingCarry(highSigImmutable, rBit, result: highSig)
        
        // handle possible carry into the sign bit
        if high.isNegative {  high.rightShiftForAddOrSubtract(by: 1) }
        
        assert(high.isNormalized)
        return high
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
