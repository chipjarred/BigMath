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
public struct WideUInt<T: WideDigit>: Hashable where T.Magnitude == T
{
    public typealias Digit = T
    public typealias Magnitude = Self
    
    // -------------------------------------
    @inlinable public static var max: Self {
        return Self(low: Digit.max, high: Digit.max)
    }
    
    @inlinable public static var min: Self { return 0 }
    
    @usableFromInline var low: Digit
    @usableFromInline var high: Digit
    
    // -------------------------------------
    @inlinable
    public init(low: Digit, high: Digit)
    {
        self.low = low
        self.high = high
    }
    
    // -------------------------------------
    @inlinable
    public init(low: Digit) {
        self.low = low
        self.high = 0
    }
    
    // -------------------------------------
    @inlinable
    public init(high: Digit)
    {
        self.low = 0
        self.high = high
    }
    
    // -------------------------------------
    @inlinable
    public init()
    {
        self.low = 0
        self.high = 0
    }

    // -------------------------------------
    @inlinable
    public init(_ source: (high: Digit, low: Digit))
    {
        self.low = source.low
        self.high = source.high
    }
    
    // -------------------------------------
    @usableFromInline @inline(__always)
    internal init<T>(withBytesOf source: T)
    {
        /*
         Dear Swift Team,
         
         I know requiring initilizaton of a variable before passing it as a
         reference is generally good programming practice, and reduces the
         number of bugs due to using uninitialized variables, but when you want
         to pass it as a reference *in order to initialize it* with some bytes,
         you're basically requiring us to initialize it twice, which for
         performance critical code is not good. Please provide a way to do this,
         even if it's in some kind of wordy "unsafeInit" syntax.
         
                                     Yours truly,
                                     A programmer trying to write fast code.
         */
        if MemoryLayout<Self>.size <= MemoryLayout<T>.size {
            self = unsafeBitCast(source, to: Self.self)
        }
        else if MemoryLayout<Digit>.size <= MemoryLayout<T>.size
        {
            self.init(low: unsafeBitCast(source, to: Digit.self))
            Swift.withUnsafeBytes(of: source)
            {
                let ptr = $0.baseAddress!.advanced(by: MemoryLayout<Digit>.size)
                Swift.withUnsafeMutableBytes(of: &self)
                {
                    _ = memcpy(
                        $0.baseAddress!,
                        ptr,
                        MemoryLayout<T>.size - MemoryLayout<Digit>.size
                    )
                }
            }
        }
        else
        {
            self.init()
            Swift.withUnsafeMutableBytes(of: &self) {
                $0.bindMemory(to: T.self).baseAddress!.pointee = source
            }
        }
    }

    // -------------------------------------
    @inlinable
    public static func extendingSign(of low: Digit) -> Self
    {
        let signBit = low >> (Digit.bitWidth - 1)
        let signMask = ~signBit &+ 1
        let extend: Digit = signMask & Digit.max
        return Self(low: low, high: extend)
    }
}

// -------------------------------------
extension WideUInt
{    
    // -------------------------------------
    @usableFromInline @inline(__always)
    internal mutating func withBuffers<R, S, T>(
        _ x: S,
        _ y: T,
        body: (MutableUIntBuffer, UIntBuffer, UIntBuffer) -> R) -> R
        where S: FixedWidthInteger, T: FixedWidthInteger
    {
        return self.withMutableBuffer
        { selfBuffer in
            return x.withBuffer
            { xBuffer in
                return y.withBuffer { yBuffer in
                    return body(selfBuffer, xBuffer, yBuffer)
                }
            }
        }
    }
    
    // -------------------------------------
    @usableFromInline
    static func assertSourceIsUsable<T: BinaryInteger>(
        _ source: T,
        file: StaticString = #file,
        line: UInt = #line)
    {
        assert(source.bitWidth == MemoryLayout<T>.size * 8,
            "\(Self.self) can only represent a FixedWidthInteger that"
            + " stores its bit pattern and *only* its bit pattern directly"
            + " in itself (ie. not in an Array, or other indirect storage.)"
        )
        assert(source as? ContiguousBytes != nil,
            "\(Self.self) can only represent a FixedWidthInteger that"
            + " stores its bit pattern and *only* its bit pattern directly"
            + " in itself (ie. not in an Array, or other indirect storage.)"
        )
    }
}

// -------------------------------------
extension WideUInt
{
    // -------------------------------------
    @inlinable
    public init(_ source: Self) { self = source }
    
    // -------------------------------------
    @inlinable
    public init<T: WideDigit>(_ source: WideUInt<T>)
    {
        precondition(
            Self.compareValues(of: Self.max, and: source) == .orderedDescending,
            "\(source) cannot be represented by \(Self.self)"
        )
        if source.isZero { self.init() }
        else { self.init(withBytesOf: source) }
    }

    // -------------------------------------
    @inlinable public init(_ source: UInt)
    {
        if source == 0 { self.init() }
        else { self.init(withBytesOf: source) }
    }
    @inlinable public init(_ source: UInt8)
    {
        if source == 0 { self.init() }
        else { self.init(withBytesOf: source) }
    }
    @inlinable public init(_ source: UInt16)
    {
        if source == 0 { self.init() }
        else { self.init(withBytesOf: source) }
    }
    @inlinable public init(_ source: UInt32)
    {
        if source == 0 { self.init() }
        else { self.init(withBytesOf: source) }
    }
    @inlinable public init(_ source: UInt64)
    {
        if source == 0 { self.init() }
        else { self.init(withBytesOf: source) }
    }

    // -------------------------------------
    @inlinable public init(_ source: Int) { self.init(Int64(source)) }
    @inlinable public init(_ source: Int8) { self.init(Int64(source)) }
    @inlinable public init(_ source: Int16) { self.init(Int64(source)) }
    @inlinable public init(_ source: Int32) { self.init(Int64(source)) }
    @inlinable public init(_ source: Int64)
    {
        precondition(
            source >= 0,
            "\(source) cannot be represented by \(Self.self)"
        )
        self.init(UInt64(source))
    }

    // -------------------------------------
    @usableFromInline @inline(__always)
    internal static func compareSizes<T, U>(
        of x: T,
        and y: U) -> ComparisonResult
        where T: FixedWidthInteger, U: FixedWidthInteger
    {
        if MemoryLayout<T>.size < MemoryLayout<U>.size {
            return .orderedAscending
        }
        if MemoryLayout<T>.size > MemoryLayout<U>.size {
            return .orderedDescending
        }
        
        return .orderedSame
    }
    
    // -------------------------------------
    @usableFromInline @inline(__always)
    internal static func compareValues<T, U>(
        of x: T,
        and y: U) -> ComparisonResult
        where T: FixedWidthInteger, U: FixedWidthInteger
    {
        if compareSizes(of: x, and: y) == .orderedAscending {
            return compareValues(of: U(truncatingIfNeeded: x), and: y)
        }
        return compareValues(of: x, and: T(truncatingIfNeeded: y))
    }
    
    // -------------------------------------
    @usableFromInline @inline(__always)
    internal static func compareValues<T>(
        of x: T,
        and y: T) -> ComparisonResult
        where T: FixedWidthInteger
    {
        if x < y { return .orderedAscending }
        if x > y { return .orderedDescending }
        return .orderedSame
    }
    
    
    // -------------------------------------
    @inlinable
    var isZero: Bool
    {
        return withBuffer
        {
            var ptr = $0.baseAddress!
            let endPtr = ptr + $0.count
            
            var accumulatedBits: UInt = 0
            while ptr < endPtr
            {
                accumulatedBits |= ptr.pointee
                ptr += 1
            }
            
            return accumulatedBits == 0
        }
    }

}

// -------------------------------------
extension WideUInt where Digit == UInt32
{
    // -------------------------------------
    @inlinable public init(_ source: UInt64)
    {
        self.init(
            low: Digit(source & UInt64(Digit.max)),
            high: Digit(source >> Digit.bitWidth)
        )
    }
}

// -------------------------------------
extension WideUInt: Codable { }

// -------------------------------------
extension WideUInt
{
    // -------------------------------------
    @inlinable
    public static func random(in range: ClosedRange<Self>) -> Self
    {
        assert(range.lowerBound <= range.upperBound)
        
        var delta = range.upperBound
        delta &-= range.lowerBound
        delta &+= 1

        if delta == 1 { return range.lowerBound }
        
        var result = Self()
        result.withMutableBuffer
        {
            var buf = $0
            for i in buf.indices {
                buf[i] = UInt.random(in: 0...UInt.max)
            }
        }
        if delta.isZero { return result }
        
        result %= delta
        result &+= range.lowerBound
        return result
    }
    
    // -------------------------------------
    @inlinable
    public static func random(in range: Range<Self>) -> Self
    {
        assert(range.lowerBound < range.upperBound)

        return random(in: range.lowerBound...(range.upperBound - 1))
    }
    
    // -------------------------------------
    @inlinable
    public static func random(in range: PartialRangeFrom<Self>) -> Self {
        return random(in: range.lowerBound...Self.max)
    }
    
    // -------------------------------------
    @inlinable
    public static func random(in range: PartialRangeUpTo<Self>) -> Self {
        return random(in: Self.min..<range.upperBound)
    }
    
    // -------------------------------------
    @inlinable
    public static func random(in range: PartialRangeThrough<Self>) -> Self {
        return random(in: Self.min...range.upperBound)
    }
    
    // -------------------------------------
    @inlinable
    public static func random(in range: UnboundedRange) -> Self {
        return random(in: Self.min...Self.max)
    }
}
