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
    @inlinable public var nonzeroBitCount: Int {
        return low.nonzeroBitCount + high.nonzeroBitCount
    }
    
    // -------------------------------------
    @inlinable public var leadingZeroBitCount: Int
    {
        return high.isZero
            ? low.leadingZeroBitCount + Digit.bitWidth
            : high.leadingZeroBitCount
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
        
        self.withBuffer
        { dividend in
            x.withBuffer
            { divisor in
                q.withMutableBuffer
                { quotient in
                    r.withMutableBuffer
                    { remainder in
                        scratch.withMutableBuffer
                        { scratch in
                            fullWidthDivide_KnuthD(
                                dividend,
                                by: divisor,
                                quotient: quotient,
                                remainder: remainder,
                                scratch: scratch
                            )
                        }
                    }
                }
            }
        }

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
        
        @inline(__always)
        public mutating func withMutableBuffer<R>(
            body: (MutableUIntBuffer) -> R) -> R
        {
            return withUnsafeMutableBytes(of: &self) {
                return body($0.bindMemory(to: UInt.self)[...])
            }
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
        
        dividend.withBuffer
        { dividend in
            self.withBuffer
            { divisor in
                q.withMutableBuffer
                { quotient in
                    r.withMutableBuffer
                    { remainder in
                        scratch.withMutableBuffer
                        { scratch in
                            fullWidthDivide_KnuthD(
                                dividend,
                                by: divisor,
                                quotient: quotient,
                                remainder: remainder,
                                scratch: scratch
                            )
                        }
                    }
                }
            }
        }

        return (
            quotient: q.r,
            remainder: r.r.low
        )
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
        
        dividend.withBuffer
        { dividend in
            self.withBuffer
            { divisor in
                q.withMutableBuffer
                { quotient in
                    r.withMutableBuffer
                    { remainder in
                        fullWidthDivide_ShiftSubtract(
                            dividend,
                            by: divisor,
                            quotient: quotient,
                            remainder: remainder
                        )
                    }
                }
            }
        }

        return (
            quotient: q.r,
            remainder: r.r.low
        )
    }
}
