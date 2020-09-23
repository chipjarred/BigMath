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
/*
 Custom type for exponents that also encodes the significand's sign bit.
 
 The significand sign bit is stored in the least significant bit.
 */
@usableFromInline
internal struct WExp:
    Hashable,
    ExpressibleByIntegerLiteral,
    Comparable,
    AdditiveArithmetic
{
    @usableFromInline internal typealias IntegerLiteralType = Int
    
    private static let intMax = Int.max >> 1
    private static let intMin = -intMax
    @usableFromInline internal static let max: Self = Self(intMax)
    @usableFromInline internal static let min: Self = Self(intMin)
    @usableFromInline internal static let validRange = intMin...intMax
    
    private static let sigSignMask: UInt = 1
    private static let expMask = ~sigSignMask

    private var rawValue: UInt
    
    // -------------------------------------
    @usableFromInline @inline(__always) internal var intValue: Int
    {
        get { Int(bitPattern: rawValue) >> 1 }
        set
        {
            assert(
                Self.validRange.contains(newValue),
                "\(newValue) not in range, \(Self.intMin)...\(Self.intMax)"
            )
            rawValue &= Self.sigSignMask
            rawValue |= UInt(bitPattern: newValue << 1)
        }
    }
    
    // -------------------------------------
    @usableFromInline @inline(__always) internal var sigSignBit: UInt
    {
        get { return rawValue & Self.sigSignMask }
        set
        {
            assert((0...1).contains(newValue))
            rawValue.setBit(at: 1, to: newValue)
        }
    }
    
    // -------------------------------------
    @usableFromInline @inline(__always) internal var bitPattern: UInt
    {
        get { rawValue }
        set { rawValue = newValue }
    }
    
    @usableFromInline @inline(__always) internal var isSpecial: Bool {
        self.intValue == Self.max.intValue
    }

    // -------------------------------------
    @usableFromInline @inline(__always)
    init(_ source: Int)
    {
        assert(
            Self.validRange.contains(source),
            "\(source) not in range, \(Self.intMin)...\(Self.intMax)"
        )
        rawValue = UInt(bitPattern: source << 1)
    }
    
    // -------------------------------------
    @usableFromInline @inline(__always)
    init(bitPattern: UInt) { self.rawValue = bitPattern }
    
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
