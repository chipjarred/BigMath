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
@usableFromInline
internal struct WExp:
    Hashable,
    ExpressibleByIntegerLiteral,
    Comparable,
    AdditiveArithmetic
{
    @usableFromInline internal typealias IntegerLiteralType = Int
    
    @usableFromInline internal static let max: Self = Self(Int.max)
    @usableFromInline internal static let min: Self = Self(Int.min)

    private var rawValue: Int
    
    // -------------------------------------
    @usableFromInline @inline(__always) internal var intValue: Int
    {
        get { rawValue }
        set { rawValue = newValue }
    }
    
    // -------------------------------------
    @usableFromInline @inline(__always) internal var bitPattern: UInt
    {
        get { UInt(bitPattern: rawValue) }
        set { rawValue = Int(bitPattern: newValue) }
    }
    
    @usableFromInline @inline(__always) internal var isSpecial: Bool {
        self.intValue == Self.max.intValue
    }

    // -------------------------------------
    @usableFromInline @inline(__always)
    init(_ source: Int) { self.rawValue = source }
    
    // -------------------------------------
    @usableFromInline @inline(__always)
    init(bitPattern: UInt) { self.init(Int(bitPattern: bitPattern)) }
    
    // -------------------------------------
    @usableFromInline @inline(__always)
    init(integerLiteral: Int) { self.init(integerLiteral) }

    // -------------------------------------
    @usableFromInline @inline(__always)
    static func == (left: Self, right: Self) -> Bool {
        return left.intValue == right.intValue
    }
    
    // -------------------------------------
    @usableFromInline @inline(__always)
    static func < (left: Self, right: Self) -> Bool {
        return left.intValue < right.intValue
    }
    
    // -------------------------------------
    @usableFromInline @inline(__always)
    static prefix func - (_ x: Self) -> Self
    {
        var result = x
        result.intValue = -result.intValue
        return result
    }
    
    // -------------------------------------
    @usableFromInline @inline(__always)
    static func + (left: Self, right: Self) -> Self {
        return Self(left.intValue + right.intValue)
    }
    
    // -------------------------------------
    @usableFromInline @inline(__always)
    static func - (left: Self, right: Self) -> Self {
        return Self(left.intValue - right.intValue)
    }
}
