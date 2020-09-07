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
extension WideInt: AdditiveArithmetic
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
        return Self(bitPattern: lhs.bitPattern &+ rhs.bitPattern)
    }
    
    // -------------------------------------
    @inlinable
    public static func &- (lhs: Self, rhs: Self) -> Self
    {
        return Self(bitPattern: lhs.bitPattern &- rhs.bitPattern)
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
        -> (partialValue: Self, carry: Magnitude.Digit)
    {
        let result = self.bitPattern.addingReportingCarry(other.bitPattern)
        
        return (
            partialValue: Self(bitPattern: result.partialValue),
            carry: result.carry
        )
    }
    
    // -------------------------------------
    @usableFromInline @inline(__always)
    internal mutating func addToSelfReportingCarry(_ other: Self)
        -> Magnitude.Digit
    {
        return self.bitPattern.addToSelfReportingCarry(other.bitPattern)
    }
    
    // -------------------------------------
    @usableFromInline @inline(__always)
    internal mutating func addToSelfReportingCarry(_ other: Magnitude.Digit)
        -> Magnitude.Digit
    {
        return self.bitPattern.addToSelfReportingCarry(other)
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
        -> (partialValue: Self, borrow: Magnitude.Digit)
    {
        let result =  self.bitPattern
            .subtractingReportingBorrow(other.bitPattern)
        
        return (
            partialValue: Self(bitPattern: result.partialValue),
            borrow: result.borrow
        )
    }

    // -------------------------------------
    @usableFromInline @inline(__always)
    internal mutating func subtractFromSelfReportingBorrow(_ other: Self)
        -> Magnitude.Digit
    {
        return self.bitPattern.subtractFromSelfReportingBorrow(other.bitPattern)
    }
    
    // -------------------------------------
    @usableFromInline @inline(__always)
    internal mutating func subtractFromSelfReportingBorrow(
        _ other: Magnitude.Digit) -> Magnitude.Digit
    {
        return self.bitPattern.subtractFromSelfReportingBorrow(other)
    }
}
