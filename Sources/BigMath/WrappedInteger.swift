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
public protocol WrappedInteger:
    FixedWidthInteger
    where
        Self.IntegerLiteralType == Wrapped.IntegerLiteralType,
        Magnitude: WrappedInteger,
        Wrapped.Magnitude == Magnitude.Wrapped
{
    associatedtype Wrapped: FixedWidthInteger
    associatedtype Words = Wrapped.Words
    
    var wrapped: Wrapped { get set }
    
    init(wrapped: Wrapped)
}

// -------------------------------------
public extension WrappedInteger
{
    @inlinable static var bitWidth: Int {
        return MemoryLayout<Wrapped>.size * 8
    }
    
    @inlinable var bitWidth: Int { return Wrapped.bitWidth }
    @inlinable var inverted: Self { return ~self }
    @inlinable var words: Wrapped.Words { return wrapped.words }

    // -------------------------------------
    @inlinable var byteSwapped: Self {
        return Self(wrapped: wrapped.byteSwapped)
    }
    
    // -------------------------------------
    @inlinable var trailingZeroBitCount: Int {
        return wrapped.trailingZeroBitCount
    }
    
    // -------------------------------------
    @inlinable var leadingZeroBitCount: Int {
        return wrapped.leadingZeroBitCount
    }
    
    // -------------------------------------
    @inlinable var nonzeroBitCount: Int {
        return wrapped.nonzeroBitCount
    }
    
    // -------------------------------------
    @inlinable init(integerLiteral: IntegerLiteralType) {
        self.init(wrapped: Wrapped(integerLiteral: integerLiteral))
    }
    
//    // -------------------------------------
//    @inlinable init?<T>(exactly source: T) where T: BinaryInteger
//    {
//        guard let w = Wrapped(exactly: source) else { return nil }
//        self.init(wrapped: w)
//    }
    
//    // -------------------------------------
//    @inlinable init<T>(_ source: T) where T: BinaryInteger {
//        self.init(wrapped: Wrapped(source))
//    }
//
    // -------------------------------------
    @inlinable init<T>(_ source: T) where T: BinaryFloatingPoint {
        self.init(wrapped: Wrapped(source))
    }

    // -------------------------------------
    @inlinable init?<T>(exactly source: T) where T: BinaryFloatingPoint
    {
        guard let w = Wrapped(exactly: source) else { return nil }
        self.init(wrapped: w)
    }
    
    // -------------------------------------
    @inlinable init<T>(truncatingIfNeeded source: T) where T: BinaryInteger {
        self.init(wrapped: Wrapped(truncatingIfNeeded: source))
    }
    
    // -------------------------------------
    @inlinable init<T>(clamping source: T) where T: BinaryInteger {
        self.init(wrapped: Wrapped(clamping: source))
    }

    // -------------------------------------
    @inlinable static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.wrapped == rhs.wrapped
    }
    
    // -------------------------------------
    @inlinable static func < (lhs: Self, rhs: Self) -> Bool {
        return lhs.wrapped < rhs.wrapped
    }
    
    // -------------------------------------
    @inlinable static func <= (lhs: Self, rhs: Self) -> Bool {
        return lhs.wrapped <= rhs.wrapped
    }
    
    // -------------------------------------
    @inlinable static func > (lhs: Self, rhs: Self) -> Bool {
        return lhs.wrapped > rhs.wrapped
    }
    
    // -------------------------------------
    @inlinable static func >= (lhs: Self, rhs: Self) -> Bool {
        return lhs.wrapped >= rhs.wrapped
    }
    
    // -------------------------------------
    @inlinable static prefix func ~ (x: Self) -> Self {
        return Self(wrapped: ~x.wrapped)
    }

    // -------------------------------------
    @inlinable static func + (lhs: Self, rhs: Self) -> Self {
        Self(wrapped: lhs.wrapped + rhs.wrapped)
    }

    // -------------------------------------
    @inlinable static func - (lhs: Self, rhs: Self) -> Self {
        Self(wrapped: lhs.wrapped - rhs.wrapped)
    }
    
    // -------------------------------------
    @inlinable static func * (lhs: Self, rhs: Self) -> Self {
        Self(wrapped: lhs.wrapped * rhs.wrapped)
    }
    
    // -------------------------------------
    @inlinable static func / (lhs: Self, rhs: Self) -> Self {
        Self(wrapped: lhs.wrapped / rhs.wrapped)
    }
    
    // -------------------------------------
    @inlinable static func & (lhs: Self, rhs: Self) -> Self {
        Self(wrapped: lhs.wrapped & rhs.wrapped)
    }
    
    // -------------------------------------
    @inlinable static func | (lhs: Self, rhs: Self) -> Self {
        Self(wrapped: lhs.wrapped | rhs.wrapped)
    }
    
    // -------------------------------------
    @inlinable static func ^ (lhs: Self, rhs: Self) -> Self {
        Self(wrapped: lhs.wrapped ^ rhs.wrapped)
    }
    
    // -------------------------------------
    @inlinable static func << <RHS> (lhs: Self, rhs: RHS) -> Self
        where RHS: BinaryInteger
    {
        Self(wrapped: lhs.wrapped << rhs)
    }
    
    // -------------------------------------
    @inlinable static func >> <RHS> (lhs: Self, rhs: RHS) -> Self
        where RHS: BinaryInteger
    {
        Self(wrapped: lhs.wrapped >> rhs)
    }

    // -------------------------------------
    @inlinable static func % (lhs: Self, rhs: Self) -> Self {
        Self(wrapped: lhs.wrapped % rhs.wrapped)
    }
    
    // -------------------------------------
    @inlinable static func &+ (lhs: Self, rhs: Self) -> Self {
        Self(wrapped: lhs.wrapped &+ rhs.wrapped)
    }
    
    // -------------------------------------
    @inlinable static func &- (lhs: Self, rhs: Self) -> Self {
        Self(wrapped: lhs.wrapped - rhs.wrapped)
    }
    
    // -------------------------------------
    @inlinable static func &* (lhs: Self, rhs: Self) -> Self {
        Self(wrapped: lhs.wrapped &* rhs.wrapped)
    }
    
    // -------------------------------------
    @inlinable static func += (lhs: inout Self, rhs: Self) {
        lhs.wrapped += rhs.wrapped
    }
    
    // -------------------------------------
    @inlinable static func -= (lhs: inout Self, rhs: Self) {
        lhs.wrapped -= rhs.wrapped
    }
    
    // -------------------------------------
    @inlinable static func *= (lhs: inout Self, rhs: Self) {
        lhs.wrapped *= rhs.wrapped
    }
    
    // -------------------------------------
    @inlinable static func /= (lhs: inout Self, rhs: Self) {
        lhs.wrapped /= rhs.wrapped
    }
    
    // -------------------------------------
    @inlinable static func %= (lhs: inout Self, rhs: Self) {
        lhs.wrapped %= rhs.wrapped
    }
    
    // -------------------------------------
    @inlinable static func &= (lhs: inout Self, rhs: Self) {
        lhs.wrapped &= rhs.wrapped
    }
    
    // -------------------------------------
    @inlinable static func |= (lhs: inout Self, rhs: Self) {
        lhs.wrapped |= rhs.wrapped
    }
    
    // -------------------------------------
    @inlinable static func ^= (lhs: inout Self, rhs: Self) {
        lhs.wrapped ^= rhs.wrapped
    }
    
    // -------------------------------------
    @inlinable static func >>= <RHS> (lhs: inout Self, rhs: RHS)
        where RHS: BinaryInteger
    {
        lhs.wrapped >>= rhs
    }
    
    // -------------------------------------
    @inlinable static func <<= <RHS> (lhs: inout Self, rhs: RHS)
        where RHS: BinaryInteger
    {
        lhs.wrapped <<= rhs
    }

    // -------------------------------------
    @inlinable static func &+= (lhs: inout Self, rhs: Self) {
        lhs.wrapped += rhs.wrapped
    }
    
    // -------------------------------------
    @inlinable static func &-= (lhs: inout Self, rhs: Self) {
        lhs.wrapped -= rhs.wrapped
    }
    
    // -------------------------------------
    @inlinable static func &*= (lhs: inout Self, rhs: Self) {
        lhs.wrapped *= rhs.wrapped
    }
    
    // -------------------------------------
    @inlinable func addingReportingOverflow(_ x: Self)
        -> (partialValue: Self, overflow: Bool)
    {
        let (s, o) = wrapped.addingReportingOverflow(x.wrapped)
        return (Self(wrapped: s), o)
    }
    
    // -------------------------------------
    @inlinable func subtractingReportingOverflow(_ x: Self)
        -> (partialValue: Self, overflow: Bool)
    {
        let (s, o) = wrapped.subtractingReportingOverflow(x.wrapped)
        return (Self(wrapped: s), o)
    }
    
    // -------------------------------------
    @inlinable func multipliedReportingOverflow(by x: Self)
        -> (partialValue: Self, overflow: Bool)
    {
        let (s, o) = wrapped.multipliedReportingOverflow(by: x.wrapped)
        return (Self(wrapped: s), o)
    }
    
    // -------------------------------------
    @inlinable func dividedReportingOverflow(by x: Self)
        -> (partialValue: Self, overflow: Bool)
    {
        let (s, o) = wrapped.dividedReportingOverflow(by: x.wrapped)
        return (Self(wrapped: s), o)
    }
    
    // -------------------------------------
    @inlinable func remainderReportingOverflow(dividingBy x: Self)
        -> (partialValue: Self, overflow: Bool)
    {
        let (s, o) = wrapped.remainderReportingOverflow(dividingBy: x.wrapped)
        return (Self(wrapped: s), o)
    }
    
    // -------------------------------------
    @inlinable init<T>(_truncatingBits source: T) where T: BinaryInteger
    {
        let wrapped = Wrapped(truncatingIfNeeded: source)
        self.init(wrapped: wrapped)
    }

    // -------------------------------------
    @inlinable func dividingFullWidth(_ dividend: (high: Self, low: Magnitude))
        -> (quotient: Self, remainder: Self)
    {
        let (q, r) = wrapped.dividingFullWidth(
            (dividend.high.wrapped, dividend.low.wrapped)
        )
        return (Self(wrapped: q), Self(wrapped: r))
    }
    
    // -------------------------------------
    @inlinable func multipliedFullWidth(by other: Self)
        -> (high: Self, low: Magnitude)
    {
        let (high, low) = wrapped.multipliedFullWidth(by: other.wrapped)
        return (Self(wrapped: high), Magnitude(wrapped: low))
    }
}
