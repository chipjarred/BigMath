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

@usableFromInline @inline(__always)
internal var usePremadeWideFloats: Bool { false }

fileprivate let lotsOfZerosSize = usePremadeWideFloats ? 4096 : 0

fileprivate let lotsOfZeros = [UInt](
    repeating: 0,
    count: lotsOfZerosSize
)

// -------------------------------------
@usableFromInline @inline(__always)
internal func preallcoatedWideFloat<T>() -> WideFloat<T>
    where T: WideDigit
{
    typealias FloatType = WideFloat<T>
    let preallocateThreshold = 8
    
    if MemoryLayout<FloatType.RawSignificand>.size < preallocateThreshold
        || MemoryLayout<FloatType.RawSignificand>.size > lotsOfZerosSize
    {
        return FloatType(0)
    }

    return lotsOfZeros.withUnsafeBytes
    {
        let byteOffset = $0.count - MemoryLayout<FloatType>.size
        return $0.baseAddress!.advanced(by: byteOffset)
            .bindMemory(to: FloatType.self, capacity: 1).pointee
    }
}

// -------------------------------------
public struct WideFloat<T: WideDigit>:  Hashable
    where T.Magnitude == T
{
    public typealias RawSignificand = T
    public typealias Exponent = Int
    
    @usableFromInline var _significand: RawSignificand
    @usableFromInline var _exponent: WExp

    @inlinable public var exponent: Exponent { return _exponent.intValue }
    
    // -------------------------------------
    @inlinable public var significand: Self {
        return Self(significandBitPattern: _significand, exponent: 0)
    }
    
    // -------------------------------------
    /**
     The raw encoding of the value's significand field.
     
     The `significandBitPattern` property does not include the leading
     integral bit of the significand, even though `WideFloat` stores it
     explicitly, nor does it include the sign bit.
     */
    @inlinable public var significandBitPattern: RawSignificand
    {
        var result = _significand
        result &= (RawSignificand.max >> 2)
        result <<= 1
        return result
    }
    
    // -------------------------------------
    @inlinable public var sign: FloatingPointSign
    {
        // These assertions are just in case the Swift team decides to change
        // their implementation of FloatingPointSign - they shouldn't but...
        assert(FloatingPointSign.plus.rawValue == 0)
        assert(FloatingPointSign.minus.rawValue == 1)
        return FloatingPointSign(rawValue: Int(isNegative))!
    }
    
    // -------------------------------------
    /**
     The raw encoding of the value's significand field.
     
     The `significandBitCount` property does not include the leading
     integral bit of the significand, even though `WideFloat` stores it
     explicitly, nor does it include the sign bit.
     */
    @inlinable public static var significandBitCount: Int {
        return RawSignificand.bitWidth - 2
    }
    
    // -------------------------------------
    @inlinable public var isNaN: Bool {
        return floatBuffer().isNaN
    }
    
    // -------------------------------------
    @inlinable public var isSignalingNaN: Bool {
        return floatBuffer().isSignalingNaN
    }
    
    // -------------------------------------
    @inlinable public var isInfinite: Bool {
        return floatBuffer().isInfinite
    }
    
    // -------------------------------------
    @inlinable public var isNegative: Bool {
        return floatBuffer().isNegative
    }
    
    // -------------------------------------
    @inlinable public var isZero: Bool {
        return floatBuffer().isZero
    }
    
    // -------------------------------------
    @inlinable public static var zero: Self
    {
        if usePremadeWideFloats
        {
            var result: Self = preallcoatedWideFloat()
            result._exponent = WExp.min
            return result
        }
        else { return Self() }
    }
    
    // -------------------------------------
    @inlinable public static var one: Self
    {
        var result: Self = usePremadeWideFloats
            ? preallcoatedWideFloat()
            : Self()

        result._exponent.intValue = 0
        result._significand.setBit(at: RawSignificand.bitWidth - 1, to: 1)

        return result
    }
    
    // -------------------------------------
    @inlinable public static var two: Self
    {
        var result: Self = usePremadeWideFloats
            ? preallcoatedWideFloat()
            : Self()
        
        result._exponent.intValue = 0
        result._significand.setBit(at: RawSignificand.bitWidth - 1, to: 1)

        return result
    }

    // -------------------------------------
    @usableFromInline @inline(__always)
    internal var isNormalized: Bool {
        return floatBuffer().isNormalized
    }
    
    // -------------------------------------
    @inlinable static public var infinity: Self
    {
        var result = Self()
        var resultBuf = result.mutableFloatBuffer()
        resultBuf.setInfinity()
        return result
    }
    
    // -------------------------------------
    @inlinable static public var nan: Self
    {
        var result = Self()
        var resultBuf = result.mutableFloatBuffer()
        resultBuf.setNaN()
        return result
    }

    // -------------------------------------
    @inlinable static public var signalingNaN: Self
    {
        var result = Self()
        var resultBuf = result.mutableFloatBuffer()
        resultBuf.setSignalingNaN()
        return result
    }
    
    // -------------------------------------
    @inlinable static public var greatestFiniteMagnitude: Self
    {
        var significand = RawSignificand()
        significand.invert()
        return Self(
            significandBitPattern: significand,
            exponent: WExp.max.intValue - 1
        )
    }
    
    // -------------------------------------
    @inlinable static public var leastNormalMagnitude: Self
    {
        var significand = RawSignificand()
        significand.setBit(at: RawSignificand.bitWidth - 1, to: 1)
        return Self(
            significandBitPattern: significand,
            exponent: WExp.min.intValue + 1
        )
    }
    
    // -------------------------------------
    @inlinable static public var leastNonzeroMagnitude: Self {
        return leastNormalMagnitude
    }
    
    // -------------------------------------
    @inlinable public var magnitude: Self {
        return isNegative ? self.negated : self
    }

    @inlinable public var float80Value: Float80 { convert(to: Float80.self) }
    @inlinable public var doubleValue: Double { convert(to: Double.self) }
    @inlinable public var floatValue: Float { convert(to: Float.self) }
    
    @inlinable public var uintValue: UInt { convert(to: UInt.self) }
    @inlinable public var uint64Value: UInt64 { convert(to: UInt64.self) }
    @inlinable public var uint32Value: UInt32 { convert(to: UInt32.self) }
    @inlinable public var uint16Value: UInt16 { convert(to: UInt16.self) }
    @inlinable public var uint8Value: UInt8 { convert(to: UInt8.self) }
    
    @inlinable public var intValue: Int { convert(to: Int.self) }
    @inlinable public var int64Value: Int64 { convert(to: Int64.self) }
    @inlinable public var int32Value: Int32 { convert(to: Int32.self) }
    @inlinable public var int16Value: Int16 { convert(to: Int16.self) }
    @inlinable public var int8Value: Int8 { convert(to: Int8.self) }

    
    // -------------------------------------
    @usableFromInline @inline(__always)
    internal init(significandBitPattern: RawSignificand, exponent: WExp)
    {
        self._significand = significandBitPattern
        self._exponent = exponent
        
        self.normalize()
    }

    // -------------------------------------
    @usableFromInline @inline(__always)
    internal init(significandBitPattern: RawSignificand, exponent: Int)
    {
        self.init(
            significandBitPattern: significandBitPattern,
            exponent: WExp(exponent)
        )
    }
    
    // -------------------------------------
    @inlinable
    public init()
    {
        self._significand = RawSignificand()
        self._exponent = WExp.min
    }

    // -------------------------------------
    @inlinable
    public init<I: FixedWidthInteger>(_ source: I)
    {
        guard source != 0 else
        {
            self._significand = RawSignificand()
            self._exponent = WExp.min
            assert(self.isZero)
            return
        }
        
        var s = source.magnitude
        var exp = I.bitWidth - s.leadingZeroBitCount - 1
        
        /*
         When source's Magnitude is bigger than our significand - 1 (for sign
         bit), we need to shift it down so we keep the most significant bits,
         but we need to handle rounding of the truncated part.
         
         Since MemoryLayouts are known at compile time this should be optimized
         away when it doesn't apply
         */
        if MemoryLayout<I.Magnitude>.size >= MemoryLayout<RawSignificand>.size
        {
            let sBitCount = I.Magnitude.bitWidth - s.leadingZeroBitCount
            let sigWidth = RawSignificand.bitWidth
            let shift = sBitCount - sigWidth
            if shift > 0
            {
                s.roundingRightShift(by: shift)
                
                // There is a possibility that rounding might carry all the way
                // to the most signficant bit, so we have to test and maybe
                // shift again.
                let highBitMask = ~((I.Magnitude.max) >> 1)
                if s & highBitMask != 0
                {
                    // The only way the high bit would have been set is if s
                    // were all 1s.  In that case, the rounding made all the
                    // low bits 0, so we can just do a simple shift.
                    s >>= 1
                    exp += 1
                }
            }
        }
        
        self._significand = RawSignificand(s)
        self._exponent = WExp(exp)
        
        // Normalize significand
        if !self._significand.bit(at: RawSignificand.bitWidth - 1) {
            self._significand <<= self._significand.leadingZeroBitCount
        }
        self.negate(if: source < 0)
    }
    
    // -------------------------------------
    @inlinable
    public init<F: BinaryFloatingPoint>(_ source: F)
    {
        guard !source.isNaN else
        {
            self.init()
            var buf = mutableFloatBuffer()
            
            if source.isSignalingNaN { buf.setSignalingNaN() }
            else { buf.setNaN() }
            return
        }
        if source.isInfinite
        {
            self.init()
            var buf = mutableFloatBuffer()
            buf.setInfinity()
        }
        else
        {
            self.init(
                significandBitPattern:
                    Self.extractSignificandBits(from: source),
                exponent: 0
            )
            _exponent = WExp(Int(source.exponent))
        }
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
    @usableFromInline @inline(__always)
    internal mutating func normalize()
    {
        var buf = mutableFloatBuffer()
        buf.normalize()
    }
    
    // -------------------------------------
    @inlinable
    public mutating func negate()
    {
        var buf = mutableFloatBuffer()
        buf.negate()
    }
    
    // -------------------------------------
    @inlinable
    public var negated: Self
    {
        var r = self
        r.negate()
        return r
    }
    
    // -------------------------------------
    /// Branchless conditional negation
    @usableFromInline @inline(__always)
    internal mutating func negate(if doNegation: Bool)
    {
        var buf = mutableFloatBuffer()
        buf.negate(if: doNegation)
    }
    
    // -------------------------------------
    @inlinable public func convert<F: BinaryFloatingPoint>(to: F.Type) -> F
    {
        let buf = floatBuffer()
        if buf.isNaN { return buf.isSignalingNaN ? F.signalingNaN : F.nan }
        if buf.isInfinite { return buf.isNegative ? -F.infinity : F.infinity }
        
        if exponent >= F.greatestFiniteMagnitude.exponent
        {
            if exponent > F.greatestFiniteMagnitude.exponent
                || Self(F.greatestFiniteMagnitude) < self.magnitude
            {
                return buf.isNegative ? -F.infinity : F.infinity
            }
        }
        else if exponent <= F.leastNonzeroMagnitude.exponent
        {
            if exponent < F.leastNonzeroMagnitude.exponent
                || Self(F.leastNonzeroMagnitude) < self.magnitude
            {
                return F(
                    sign: buf.isNegative ? .minus : .plus,
                    exponent: 0,
                    significand: 0
                )
            }
        }
        
        return buf.convert(to: F.self)
    }
    
    // -------------------------------------
    @inlinable public func convert(to: Float.Type) -> Float
    {
        typealias F = Float
        
        let buf = floatBuffer()

        if buf.isNaN { return buf.isSignalingNaN ? F.signalingNaN : F.nan }
        if buf.isInfinite { return buf.isNegative ? -F.infinity : F.infinity }
        
        if exponent >= F.greatestFiniteMagnitude.exponent
        {
            if exponent > F.greatestFiniteMagnitude.exponent
                || Self(F.greatestFiniteMagnitude) < self.magnitude
            {
                return buf.isNegative ? -F.infinity : F.infinity
            }
        }
        else if exponent <= F.leastNonzeroMagnitude.exponent
        {
            if exponent < F.leastNonzeroMagnitude.exponent
                || Self(F.leastNonzeroMagnitude) < self.magnitude
            {
                return F(
                    sign: buf.isNegative ? .minus : .plus,
                    exponent: 0,
                    significand: 0
                )
            }
        }
        
        return buf.convert(to: F.self)
    }
    
    // -------------------------------------
    @inlinable public func convert(to: Double.Type) -> Double
    {
        typealias F = Double
        
        let buf = floatBuffer()

        if buf.isNaN { return buf.isSignalingNaN ? F.signalingNaN : F.nan }
        if buf.isInfinite { return buf.isNegative ? -F.infinity : F.infinity }
        
        if exponent >= F.greatestFiniteMagnitude.exponent
        {
            if exponent > F.greatestFiniteMagnitude.exponent
                || Self(F.greatestFiniteMagnitude) < self.magnitude
            {
                return buf.isNegative ? -F.infinity : F.infinity
            }
        }
        else if exponent <= F.leastNonzeroMagnitude.exponent
        {
            if exponent < F.leastNonzeroMagnitude.exponent
                || Self(F.leastNonzeroMagnitude) < self.magnitude
            {
                return F(
                    sign: buf.isNegative ? .minus : .plus,
                    exponent: 0,
                    significand: 0
                )
            }
        }
        
        return buf.convert(to: F.self)
    }

    // -------------------------------------
    @inlinable public func convert<I: FixedWidthInteger>(to: I.Type) -> I
    {
        let maxRepresentableExponent = I.bitWidth - Int(I.isSigned)
        
        let buf = floatBuffer()

        /*
         All of these tests are fast O(1) tests, so we use bitwise ops instead
         of booleans to avoid the hidden conditional branches in boolean
         short-circuit evaluation
         */
        var canBeRepresented = UInt8(!buf.isNaN)
            & UInt8(!isInfinite)
            & (UInt8(I.isSigned) | UInt8(!buf.isNegative))
            & UInt8(exponent <= maxRepresentableExponent)
        
        if canBeRepresented & UInt8(exponent == maxRepresentableExponent) == 1
        {
            if significandIsOne
            {
                /*
                 Strictly speaking, our value can't be represented by I, but
                 when initializing a WideFloat from the maximum magnitude of I,
                 we would round it up to our currrent value, so we allow
                 conversion back to that maximum magnitude.
                 */
                return UInt8(I.isSigned) & UInt8(buf.isNegative) == 1
                    ? I.min
                    : I.max
            }
            canBeRepresented = 0
        }
        
        precondition(
            canBeRepresented == 1,
            "\(self) cannot be represented by \(I.self)"
        )
        
        return buf.convert(to: I.self)
    }
    
    // -------------------------------------
    @usableFromInline @inline(__always)
    internal mutating func addExponent(_ exponentDelta: WExp)
    {
        var buf = mutableFloatBuffer()
        buf.addExponent(exponentDelta)
    }
    
    // -------------------------------------
    @usableFromInline @inline(__always)
    internal var significandIsZero: Bool
    {
        let buf = floatBuffer()
        return buf.significandIsZero
    }

    // -------------------------------------
    @usableFromInline @inline(__always)
    internal var significandIsOne: Bool
    {
        let buf = floatBuffer()
        return buf.significandIsOne
    }
    
    // -------------------------------------
    /**
     We don't currently do anything with sNaNs other than treat them as NaN,
     but this mechanism is in place for adding that support later.
     
     - Parameters:
        - possibleSignalingNaNs: Values, at least one of which should be a signaling NaN.
            Operations that call this method detect that one of its parameters is a signaling NaN, but in an
            effort to avoid conditional branching don't bother to sort out which one it is.  It's up to this
            handler to determine which are signaling NaNs and which aren't, and do the right thing with
            them.
     
     - Note: While at least one of the values should be a signaling NaN, the other values are not
        necessarily NaNs.  It's up to this routine to sort that out, if anything needs to be done at all.
     */
    @usableFromInline
    internal static func handleSignalingNaN(_ possibleSignalingNaNs: Self...) {
    }
    
    @usableFromInline @inline(__always)
    internal mutating func roundingRightShift(by shift: Int)
    {
        var buf = mutableFloatBuffer()
        let saveSign = buf.signBit
        buf.signBit = 0
        
        buf.rightShiftForAddOrSubtract(by: shift)
        
        buf.signBit = saveSign
        _exponent = buf.exponent
    }

    // -------------------------------------
    @usableFromInline @inline(__always)
    internal func withFloatBuffer<R>(body: (FloatingPointBuffer) -> R) -> R
    {
        let fBuf = floatBuffer()
        return body(fBuf)
    }
    
    // -------------------------------------
    @usableFromInline @inline(__always)
    internal mutating func withMutableFloatBuffer<R>(
        body: (inout FloatingPointBuffer) -> R) -> R
    {
        var fBuf = mutableFloatBuffer()
        return body(&fBuf)
    }
    
    // -------------------------------------
    /*
     - Important: This is so unsafe, but we need it for performance!  Calling
        a closure via withUnsafeBytes turns out to be way more costly than
        expected.  I would have thought it would disappear with inlining, but
        it doesn't.
     */
    @usableFromInline @inline(__always)
    internal func floatBuffer() -> FloatingPointBuffer
    {
        /*
         withUnsafeBytes invalidates the pointer on return, so we can't just
         return $0.  However, the address remains valid (this is *NOT*
         guaranteed behavior in future versons of Swift, and not technically
         supported even in the current version.  But we're desperate to avoid as
         many nested withUnsafeBytes calls as we can, and for that we need
         pointers outside of the withUnsafeBytes calls.  So we fake out
         withUnsafeBytes by turning the pointer into an integer, and then back
         into a pointer after we return.
         */
        let address = Swift.withUnsafeBytes(of: self) {
            return UInt(bitPattern: $0.baseAddress!)
        }
        
        let ptr = UnsafeRawPointer(bitPattern: address)!
        let bufferSize = MemoryLayout<Self>.size
        let buffer = UnsafeRawBufferPointer(start: ptr, count:  bufferSize)
        return FloatingPointBuffer(
            wideFloatUIntBuffer: UIntBuffer(buffer).mutable
        )
    }
    
    // -------------------------------------
    /*
     - Important: This is so unsafe, but we need it for performance!  Calling
        a closure via withUnsafeBytes turns out to be way more costly than
        expected.  I would have thought it would disappear with inlining, but
        it doesn't.
     */
    @usableFromInline @inline(__always)
    internal mutating func mutableFloatBuffer() -> FloatingPointBuffer
    {
        /*
         withUnsafeBytes invalidates the pointer on return, so we can't just
         return $0.  However, the address remains valid (this is *NOT*
         guaranteed behavior in future versons of Swift, and not technically
         supported even in the current version.  But we're desperate to avoid as
         many nested withUnsafeBytes calls as we can, and for that we need
         pointers outside of the withUnsafeBytes calls.  So we fake out
         withUnsafeBytes by turning the pointer into an integer, and then back
         into a pointer after we return.
         */
        let address = Swift.withUnsafeMutableBytes(of: &self) {
            return UInt(bitPattern: $0.baseAddress!)
        }
        
        let ptr = UnsafeMutableRawPointer(bitPattern: address)!
        let bufferSize = MemoryLayout<Self>.size
        let buffer = UnsafeMutableRawBufferPointer(
            start: ptr,
            count:  bufferSize
        )
        return FloatingPointBuffer(
            wideFloatUIntBuffer: MutableUIntBuffer(buffer)
        )
    }
}
