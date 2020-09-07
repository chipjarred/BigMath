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
extension WideUInt: AdditiveArithmetic
{
    // -------------------------------------
    @inlinable
    public static func + (lhs: Self, rhs: Self) -> Self
    {
        let (result, overflow) = lhs.addingReportingOverflow(rhs)
        precondition(!overflow, "Addition overflows \(Self.self)")
        return result
    }
    
    // -------------------------------------
    @inlinable
    public static func - (lhs: Self, rhs: Self) -> Self
    {
        let (result, overflow) = lhs.subtractingReportingOverflow(rhs)
        precondition(!overflow, "Subtraction overflows \(Self.self)")
        return result
    }
    
    // -------------------------------------
    @inlinable
    public static func &+ (lhs: Self, rhs: Self) -> Self
    {
        let (resultLow, carry) = lhs.low.addingReportingOverflow(rhs.low)
        return Self(low: resultLow, high: lhs.high &+ rhs.high &+ Digit(carry))
    }
    
    // -------------------------------------
    @inlinable
    public static func &- (lhs: Self, rhs: Self) -> Self
    {
        let (resultLow, borrow) = lhs.low.subtractingReportingOverflow(rhs.low)
        return Self(low: resultLow, high: lhs.high &- rhs.high &- Digit(borrow))
    }
    
    // -------------------------------------
    @inlinable
    public static func += (lhs: inout Self, rhs: Self)
    {
        let carry: Bool
        (lhs, carry) = lhs.addingReportingOverflow(rhs)
        
        precondition(!carry, "Addition overflows \(Self.self)")
    }
    
    // -------------------------------------
    @inlinable
    public static func -= (lhs: inout Self, rhs: Self)
    {
        var borrow: Bool
        (lhs, borrow) = lhs.subtractingReportingOverflow(rhs)
        
        precondition(!borrow, "Subtraction overflows \(Self.self)")
    }
    
    // -------------------------------------
    @inlinable
    public static func &+= (lhs: inout Self, rhs: Self) {
        let _ = lhs.addToSelfReportingCarry(rhs)
    }
    
    // -------------------------------------
    @inlinable
    public static func &-= (lhs: inout Self, rhs: Self) {
        let _ = lhs.subtractFromSelfReportingBorrow(rhs)
    }
    
    // -------------------------------------
    @inlinable
    public func addingReportingOverflow(_ other: Self)
        -> (partialValue: Self, overflow: Bool)
    {
        let (sum, carry) = self.addingReportingCarry(other)
        
        return (partialValue: sum, overflow: carry != 0)
    }
    
    // -------------------------------------
    @usableFromInline @inline(__always)
    internal func addingReportingCarry(_ other: Self)
        -> (partialValue: Self, carry: Digit)
    {
        var sum = Self()
        let carry = sum.withBuffers(self, other) {
            addReportingCarry($1, $2, result: $0)
        }
        
        return (partialValue: sum, carry: Digit(carry))
    }
    
    // -------------------------------------
    @usableFromInline @inline(__always)
    internal mutating func addToSelfReportingCarry(_ other: Self) -> Digit
    {
        let carry = self.withBuffers(self, other) {
            addReportingCarry($1, $2, result: $0)
        }
        return Digit(carry)
    }
    
    // -------------------------------------
    @usableFromInline @inline(__always)
    internal mutating func addToSelfReportingCarry(_ other: Digit) -> Digit
    {
        let carry: Digit
        (self, carry) = self.addingReportingCarry(Self(low: other))
        return carry
    }

    // -------------------------------------
    @inlinable
    public func subtractingReportingOverflow(_ other: Self)
        -> (partialValue: Self, overflow: Bool)
    {
        let (difference, borrow) = self.subtractingReportingBorrow(other)
        
        return (partialValue: difference, overflow: borrow != 0)
    }
    
    // -------------------------------------
    @usableFromInline @inline(__always)
    internal func subtractingReportingBorrow(_ other: Self)
        -> (partialValue: Self, borrow: Digit)
    {
        var difference = Self()
        let borrow = difference.withBuffers(self, other) {
            subtractReportingBorrow($1, $2, result: $0)
        }
        
        return (partialValue: difference, borrow: Digit(borrow))
    }

    // -------------------------------------
    @usableFromInline @inline(__always)
    internal mutating func subtractFromSelfReportingBorrow(_ other: Self) -> Digit
    {
        let borrow = self.withBuffers(self, other) {
            subtractReportingBorrow($1, $2, result: $0)
        }
        return Digit(borrow)
    }
    
    // -------------------------------------
    @usableFromInline @inline(__always)
    internal mutating func subtractFromSelfReportingBorrow(_ other: Digit) -> Digit
    {
        let borrow: Digit
        (self, borrow) = self.subtractingReportingBorrow(Self(low: other))
        return borrow
    }
}
