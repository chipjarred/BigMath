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

infix operator <=> : ComparisonPrecedence

// -------------------------------------
@usableFromInline
internal struct WideExponent: Hashable, Comparable
{
    var rawExp: UInt
    
    /*
     The exponent format is intended allow checking for special values such as
     infinity or NaN efficiently, as well as the significand sign.  In addition,
     since we don't support gradual underflow, the only value that can use the
     exponent for zero is zero itself, which allows for a fast 0 test.
     
     The exponent contains 2 specially reserved bits.
     
     The high bit is the significand sign bit, which is set if the signifcand
     is negative, and clear if it is positive.
     
     The next highest bit is set for NaN, and clear for non-NaN values.  The
     type of NaN is encoded in the least significant bit.  If the least
     significant exponent bit is set, then the NaN is signaling, otherwise it
     is a quiet NaN.
     
     Infinities are encoded as all 1s in the non-special bit region of the
     exponent.
     */
    // There are 2 special bits.  The sign bit, the
    static let specialBitCount = 2
    static let magnitudeMask = UInt.max >> specialBitCount
    static let infinityBitPattern = magnitudeMask
    static let offset = Int(magnitudeMask >> 1)
    static let maxFiniteValue = Int(magnitudeMask - 1)
    static let expForZero =  -offset
    static let minNonzeroValue = expForZero + 1
    
    static let signMask = ~UInt.max >> 1
    static let nanBitMask = signMask >> 1
    static let nanTypeBitMask: UInt = 1
    static let signalingNaNMask = nanBitMask | nanTypeBitMask
    
    // -------------------------------------
    @usableFromInline @inline(__always)
    var intValue: Int
    {
        get { return Int(rawExp & Self.magnitudeMask) &- Self.offset }
        set
        {
            assert(Self.offset <= newValue, "applying offset will underflow")
            rawExp = UInt(bitPattern: newValue &+ Self.offset)
        }
    }
    
    // -------------------------------------
    @usableFromInline @inline(__always)
    var rawValue: UInt { return rawExp }
    
    // -------------------------------------
    @usableFromInline @inline(__always)
    var sigIsNegative: Bool { return rawExp & Self.signMask != 0 }
    
    // -------------------------------------
    @usableFromInline @inline(__always)
    var sigIsZero: Bool { return rawExp & Self.magnitudeMask == 0 }
    
    // -------------------------------------
    @usableFromInline @inline(__always)
    var sigIsZeroByte: UInt8 { return UInt8(sigIsZero) }
    
    // -------------------------------------
    @usableFromInline @inline(__always)
    mutating func negateSig() { rawExp ^= Self.signMask }
    
    // -------------------------------------
    @usableFromInline @inline(__always)
    var isNaN: Bool { return rawExp & Self.nanBitMask != 0 }
    
    // -------------------------------------
    @usableFromInline @inline(__always)
    var isSignalingNaN: Bool {
        return rawExp & Self.signalingNaNMask == Self.signalingNaNMask
    }
    
    // -------------------------------------
    @usableFromInline @inline(__always)
    static func makeSignalingNaN() -> Self {
        return Self(bitPattern: Self.signalingNaNMask)
    }

    // -------------------------------------
    @usableFromInline @inline(__always)
    var isQuietNaN: Bool {
        return rawExp & Self.signalingNaNMask == Self.nanBitMask
    }
    
    // -------------------------------------
    @usableFromInline @inline(__always)
    static func makeQuietNaN() -> Self {
        return Self(bitPattern: Self.nanBitMask)
    }

    // -------------------------------------
    @usableFromInline @inline(__always)
    var isInfinite: Bool {
        return rawExp & Self.infinityBitPattern == Self.infinityBitPattern
    }
    
    // -------------------------------------
    @usableFromInline @inline(__always)
    static func makePositiveInfinity() -> Self {
        return Self(bitPattern: Self.infinityBitPattern)
    }
    
    // -------------------------------------
    @usableFromInline @inline(__always)
    static func makeNegativeInfinity() -> Self {
        return Self(bitPattern: Self.infinityBitPattern | Self.signMask)
    }

    // -------------------------------------
    @usableFromInline @inline(__always)
    var sigSignBit: UInt
    {
        get { rawExp.getBit(at: UInt.bitWidth - 1) }
        set
        {
            assert(
                newValue == 0 || newValue == 1,
                "Attempting to set sign bit as non-binary value"
            )
            rawExp.setBit(at: UInt.bitWidth - 1, to: newValue)
        }
    }
    
    // -------------------------------------
    /// `true` if the value is NaN or infinite; otherwise `false`
    @usableFromInline @inline(__always)
    var isSpecial: Bool
    {
        let value = rawExp & (Self.infinityBitPattern | Self.nanBitMask)
        return value >= Self.infinityBitPattern
    }
    
    // -------------------------------------
    /// `1` if the value is NaN or infinite; otherwise `0`
    @usableFromInline @inline(__always)
    var isSpecialByte: UInt8 { return UInt8(isSpecial) }
    
    // -------------------------------------
    @usableFromInline @inline(__always)
    init() { rawExp = 0 }
    
    // -------------------------------------
    @usableFromInline @inline(__always)
    init(bitPattern: UInt) { self.rawExp = bitPattern }
    
    // -------------------------------------
    @usableFromInline @inline(__always)
    init?(_ source: Int)
    {
        guard source <= Self.offset else { return nil }
        rawExp = UInt(bitPattern: source &+ Self.offset)
    }
    
    // -------------------------------------
    /**
     - Returns: `true` if adding `delta` will overflow the resulting exponent;
        otherwise `false`
     */
    @usableFromInline @inline(__always)
    func add(_ delta: Int, result: inout Self) -> Bool
    {
        let curExp = intValue
        
        let willOverflow =
            1 == (UInt8(delta < 0) & UInt8(curExp < Self.expForZero &- delta))
            | (UInt8(delta > 0) & UInt8(curExp > Self.maxFiniteValue &- delta))
        
        let bitPattern = select(
            if: willOverflow,
            then: Self.magnitudeMask,
            else: UInt(bitPattern: curExp &+ delta &+ Self.offset)
        )
        
        result = Self(bitPattern: bitPattern)
        return willOverflow
    }
    
    // -------------------------------------
    /**
     - Returns: `true` if subtracting `delta` will overflow the resulting
        exponent; otherwise `false`
     */
    @usableFromInline @inline(__always)
    func subtract(_ delta: Int, result: inout Self) -> Bool
    {
        let curExp = intValue
        
        let willOverflow =
            1 == (UInt8(delta > 0) & UInt8(curExp < Self.expForZero &+ delta))
            | (UInt8(delta < 0) & UInt8(curExp > Self.maxFiniteValue &+ delta))
        
        let bitPattern = select(
            if: willOverflow,
            then: Self.magnitudeMask,
            else: UInt(bitPattern: curExp &- delta &+ Self.offset)
        )
        
        result = Self(bitPattern: bitPattern)
        return willOverflow
    }
    
    // -------------------------------------
    @usableFromInline @inline(__always)
    static func == (left: Self, right: Self) -> Bool {
        return (left <=> right) == .orderedSame
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
        let cResult = (left <=> right)
        return 1 == UInt8(cResult == .orderedAscending)
            | UInt8(cResult == .orderedSame)
    }
    
    // -------------------------------------
    @usableFromInline @inline(__always)
    static func >= (left: Self, right: Self) -> Bool
    {
        let cResult = (left <=> right)
        return 1 == UInt8(cResult == .orderedDescending)
            | UInt8(cResult == .orderedSame)
    }

    // -------------------------------------
    @usableFromInline @inline(__always)
    static func <=> (left: Self, right: Self)
        -> FloatingPointBuffer.ComparisonResult
    {
        typealias CResult = FloatingPointBuffer.ComparisonResult
        
        let rawExpDiff = Int(bitPattern: left.rawExp &- right.rawExp)
        
        /*
         My apologies to anyone reading these nested select statements.
         They're branchlessly replacing a big if-else... series
         */
        let result: CResult.RawValue
        result = select(
            if: UInt8(left.isNaN) | UInt8(right.isNaN) == 1,
            then: CResult.unordered.rawValue,
            else: select(
                if: left.sigIsZeroByte & right.sigIsZeroByte == 1,
                then: CResult.orderedSame.rawValue,
                else: select(
                    if: rawExpDiff < 0,
                    then: CResult.orderedAscending.rawValue,
                    else: select(
                        if: rawExpDiff == 0,
                        then: CResult.orderedSame.rawValue,
                        else:CResult.orderedDescending.rawValue
                    )
                )
            )
        )

        return FloatingPointBuffer.ComparisonResult(rawValue: result)!
    }
}
