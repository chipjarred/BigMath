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
public protocol WideUnsignedInteger:
    WrappedInteger,
    WideDigit
    where
        Digit == Digit.Magnitude,
        IntegerLiteralType == UInt
{
    associatedtype Digit: WideDigit
    associatedtype Wrapped = WideUInt<Digit>
}

// -------------------------------------
public extension WideUnsignedInteger where Wrapped == WideUInt<Digit>
{
    var signBit: Bool { wrapped.high.signBit }
    mutating func invert() { wrapped.invert() }
    
    // -------------------------------------
    @inlinable static func random(in range: ClosedRange<Self>) -> Self
    {
        return Self(
            wrapped: Wrapped.random(
                in: range.lowerBound.wrapped...range.upperBound.wrapped
            )
        )
    }
    
    // -------------------------------------
    @inlinable static func random(in range: Range<Self>) -> Self
    {
        return Self(
            wrapped: Wrapped.random(
                in: range.lowerBound.wrapped..<range.upperBound.wrapped
            )
        )
    }
    
    // -------------------------------------
    @inlinable static func random(in range: PartialRangeUpTo<Self>) -> Self
    {
        return Self(
            wrapped: Wrapped.random(in: Wrapped.min..<range.upperBound.wrapped)
        )
    }
    
    // -------------------------------------
    @inlinable static func random(in range: PartialRangeThrough<Self>) -> Self
    {
        return Self(
            wrapped: Wrapped.random(in: Wrapped.min...range.upperBound.wrapped)
        )
    }
    
    // -------------------------------------
    @inlinable static func random(in range: PartialRangeFrom<Self>) -> Self
    {
        return Self(
            wrapped: Wrapped.random(in: range.lowerBound.wrapped...Wrapped.max)
        )
    }
    
    // -------------------------------------
    @inlinable static func random(in range: UnboundedRange) -> Self
    {
        let lowerBound = Wrapped.min
        let upperBound = Wrapped.max
        return Self(wrapped: Wrapped.random(in: lowerBound...upperBound))
    }
}
