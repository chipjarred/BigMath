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
extension WideInt: FixedWidthInteger
{
    // -------------------------------------
    @inlinable public var nonzeroBitCount: Int {
        return bitPattern.nonzeroBitCount
    }
    
    // -------------------------------------
    @inlinable public var leadingZeroBitCount: Int {
        return bitPattern.leadingZeroBitCount
    }
    
    // -------------------------------------
    @inlinable public var byteSwapped: Self {
        return Self(bitPattern: bitPattern.byteSwapped)
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
        let dividendIsNegative = self.bitPattern.signBit
        let divisorIsNegative = x.bitPattern.signBit
        let resultIsNegative =
            UInt8(dividendIsNegative) ^ UInt8(divisorIsNegative) == 1
        
        let dividend = dividendIsNegative
            ? self.bitPattern.negated
            : self.bitPattern
        let divisor = divisorIsNegative
            ? x.bitPattern.negated
            : x.bitPattern
        
        var result = dividend.quotientAndRemainder(dividingBy: divisor)

        if resultIsNegative { result.quotient.negate() }
        if dividendIsNegative { result.remainder.negate() }

        return (
            quotient: Self(bitPattern: result.quotient),
            remainder: Self(bitPattern: result.remainder)
        )
    }
    
    // -------------------------------------
    @inlinable
    public func dividingFullWidth(_ dividend: (high: Self, low: Self.Magnitude))
        -> (quotient: Self, remainder: Self)
    {
        let dividendIsNegative = dividend.high.bitPattern.signBit
        let divisorIsNegative = self.bitPattern.signBit
        let resultIsNegative =
            UInt8(dividendIsNegative) ^ UInt8(divisorIsNegative) == 1
        
        var dividendHigh = dividend.high.bitPattern
        var dividendLow  = dividend.low
        if dividendIsNegative
        {
            dividendLow.invert()
            let carry = dividendLow.addToSelfReportingCarry(1)
            dividendHigh.invert()
            dividendHigh &+= Magnitude(carry)
        }

        let divisor = divisorIsNegative
            ? self.bitPattern.negated
            : self.bitPattern
        
        var (quotient, remainder) =
            dividendHigh.quotientAndRemainder(dividingBy: divisor)
        (quotient, remainder) =
            divisor.dividingFullWidth((remainder, dividendLow))

        if resultIsNegative { quotient.negate() }
        if dividendIsNegative { remainder.negate() }
        
        return (
            quotient: Self(bitPattern: quotient),
            remainder: Self(bitPattern: remainder)
        )
    }
}
