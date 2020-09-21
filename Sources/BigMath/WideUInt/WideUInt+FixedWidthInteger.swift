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

// -------------------------------------
extension WideUInt: FixedWidthInteger
{
    // -------------------------------------
    @inlinable public var nonzeroBitCount: Int
    {
        let selfBuffer = self.buffer()
        
        var result = 0
        
        for digit in selfBuffer {
            result &+= digit.nonzeroBitCount
        }
        
        return result
    }
    
    // -------------------------------------
    @inlinable public var leadingZeroBitCount: Int
    {
        let selfBuffer = self.buffer()
        
        var result = 0
        
        for digit in selfBuffer.reversed()
        {
            let curLeadingZeros = digit.leadingZeroBitCount
            result &+= curLeadingZeros
            guard curLeadingZeros == UInt.bitWidth else { break }
        }
        
        return result
    }
    
    // -------------------------------------
    @inlinable public var byteSwapped: Self {
        return Self(low: high.byteSwapped, high: low.byteSwapped)
    }

    // -------------------------------------
    @inlinable
    public func dividedReportingOverflow(by rhs: Self)
        -> (partialValue: Self, overflow: Bool)
    {
        if rhs.isZero { return (self, true) }
        
        // Dividing a number by the same bitwidth non-zero number can't overflow
        return (quotientAndRemainder(dividingBy: rhs).quotient, false)
    }
    
    // -------------------------------------
    @inlinable
    public func remainderReportingOverflow(dividingBy rhs: Self)
        -> (partialValue: Self, overflow: Bool)
    {
        if rhs.isZero { return (self, true) }
        
        // Dividing a number by the same bitwidth non-zero number can't overflow
        return (quotientAndRemainder(dividingBy: rhs).remainder, false)
    }
    
    // -------------------------------------
    @inlinable
    public func quotientAndRemainder(dividingBy x: Self)
        -> (quotient: Self, remainder: Self)
    {
        precondition(!x.isZero, "Dividing by 0")
        
        var q = KnuthDRemainder<Self>()
        var r = KnuthDRemainder<Self>()
        var scratch = Self()
        
        let dividend = self.buffer()
        let divisor = x.buffer()
        let quotient = q.mutableBuffer()
        let remainder = r.mutableBuffer()
        let scratchBuf = scratch.mutableBuffer()
        
        fullWidthDivide_KnuthD(
            dividend,
            by: divisor,
            quotient: quotient,
            remainder: remainder,
            scratch: scratchBuf
        )

        return (quotient: q.r, remainder: r.r)
    }
    
    // -------------------------------------
    @inlinable
    public func dividingFullWidth(_ dividend: (high: Self, low: Self))
        -> (quotient: Self, remainder: Self)
    {
        typealias BiggerInt = WideUInt<Self>
        precondition(!self.isZero, "Dividing by 0")
        
        return dividingFullWidth_KnuthD(dividend)
    }

    
    // -------------------------------------
    @usableFromInline
    internal struct KnuthDRemainder<T: WideDigit> where T.Magnitude == T
    {
        public var r = T()
        public var overflow: UInt = 0
        
        // -------------------------------------
        @usableFromInline @inline(__always)
        internal mutating func withMutableBuffer<R>(
            body: (MutableUIntBuffer) -> R) -> R
        {
            let buffer = self.mutableBuffer()
            return body(buffer)
        }

        // -------------------------------------
        /*
         - Important: This is so unsafe, but we need it for performance!  Calling
            a closure via withUnsafeBytes turns out to be way more costly than
            expected.  I would have thought it would disappear with inlining, but
            it doesn't.
         */
        @usableFromInline @inline(__always)
        internal mutating func mutableBuffer() -> MutableUIntBuffer
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
            return MutableUIntBuffer.init(buffer)
        }

        @inline(__always) public init() { }
    }
    
    // -------------------------------------
    @inlinable
    public func dividingFullWidth_KnuthD(_ dividend: (high: Self, low: Self))
        -> (quotient: Self, remainder: Self)
    {
        typealias BiggerInt = WideUInt<Self>
        var q = KnuthDRemainder<Self>()
        var r = KnuthDRemainder<BiggerInt>()
        var scratch = Self()
        let dividend = BiggerInt(dividend)
        
        let dividendBuf = dividend.buffer()
        let divisorBuf = self.buffer()
        let quotient = q.mutableBuffer()
        let remainder = r.mutableBuffer()
        let scratchBuf = scratch.mutableBuffer()
        
        fullWidthDivide_KnuthD(
            dividendBuf,
            by: divisorBuf,
            quotient: quotient,
            remainder: remainder,
            scratch: scratchBuf
        )

        return (quotient: q.r, remainder: r.r.low)
    }
    
    // -------------------------------------
    @inlinable
    public func dividingFullWidth_ShiftSubtract(_ dividend: (high: Self, low: Self))
        -> (quotient: Self, remainder: Self)
    {
        typealias BiggerInt = WideUInt<Self>
        var q = KnuthDRemainder<Self>()
        var r = KnuthDRemainder<BiggerInt>()
        let dividend = BiggerInt(dividend)
        
        let dividendBuf = dividend.buffer()
        let divisor = self.buffer()
        let quotient = q.mutableBuffer()
        let remainder = r.mutableBuffer()
        
        fullWidthDivide_ShiftSubtract(
            dividendBuf,
            by: divisor,
            quotient: quotient,
            remainder: remainder
        )

        return (quotient: q.r, remainder: r.r.low)
    }
}
