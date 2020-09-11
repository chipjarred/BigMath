//
//  FloatingPointBuffer.swift
//  
//
//  Created by Chip Jarred on 9/10/20.
//

// -------------------------------------
/**
 Although inspired by the IEEE 425 standard, we're not super-faithful to it.
 We don't support subnormal values and we store the leading integral 1 for
 finite values.  Subnormal values would require handling offset exponents,
 which means having more conditional branches in basic operations.  Not storing
 the integral 1 likewise requires special case logic.  IEEE 425 does those
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
            
            significand[significand.count - 1].setBit(
                at: UInt.bitWidth - 1,
                to: newValue
            )
        }
    }
    
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
    private var signficandHeadValue: UInt
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
        return significandTail.reduce(signficandHeadValue) { $0 | $1 } == 0
    }
    
    // -------------------------------------
    /**
     Infinity is encoded as exponent bits, including sign bit, all set to `1`,
     and significand set to `0`.
     */
    @usableFromInline @inline(__always)
    var isInfinity: Bool
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
        signficandHeadValue = 1
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
        signficandHeadValue = 1
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
        signficandHeadValue = 1
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
        
        // This handles +/-0
        if exponent == 0 {
            return significandIsZero
        }
        
        // This handles all other finite values.
        return (significandHead >> (UInt.bitWidth - 2) & 1) == 1
    }
    
    // -------------------------------------
    /*
     Ignores sign bit when counting leading zeros.
     */
    @inline(__always)
    private var leadingSignficandZeroBitCount: Int
    {
        var leadingZeros = signficandHeadValue.leadingZeroBitCount
        if leadingZeros == UInt8.bitWidth - 1 // head is +0 or -0
        {
            for digit in significandTail.reversed()
            {
                guard digit == 0 else
                {
                    leadingZeros += digit.leadingZeroBitCount
                    break
                }
                
                leadingZeros += UInt8.bitWidth
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
        leftShift(buffer: significand, by: leadingZeros)
        signBit = savedSign
        exponent -= leadingZeros
    }
    
    // MARK:- Initializers
    // -------------------------------------
    @inline(__always)
    private init(
        signficand: MutableUIntBuffer,
        exponent: Int,
        isNegative: Bool)
    {
        self.exponent = exponent
        self.significand = signficand
        self.signBit = UInt(isNegative)
        
        self.normalize()
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
            signficand: fixedpoint,
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
            signficand: buffer,
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
        return Self(signficand: buffer, exponent: -1, isNegative: isNegative)
    }
}
