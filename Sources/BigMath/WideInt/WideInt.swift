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
public struct WideInt<T: WideDigit>: Hashable where T.Magnitude == T
{
    public typealias Magnitude = WideUInt<T>
    
    @inlinable
    public static var bitWidth: Int { return Magnitude.bitWidth }
    
    @inlinable
    public static var max: Self { return Self(bitPattern: Magnitude.max >> 1) }
    
    @inlinable
    public static var min: Self { return Self.max &+ 1 }

    @usableFromInline
    var bitPattern: Magnitude
    
    // -------------------------------------
    @inlinable
    public init() { self.bitPattern = 0 }
    
    // -------------------------------------
    @inlinable
    public init(bitPattern: Magnitude) { self.bitPattern = bitPattern }
    
    // -------------------------------------
    @inlinable
    public init(_ source: Int) {
        self.bitPattern = Magnitude(UInt(bitPattern: source))
    }
}


// -------------------------------------
extension WideInt: Codable { }

// -------------------------------------
extension WideInt
{
    // -------------------------------------
    @inlinable
    public static func random(in range: ClosedRange<Self>) -> Self
    {
        assert(range.lowerBound <= range.upperBound)
        
        var delta = range.upperBound
        delta &-= range.lowerBound
        
        if delta == 0 { return range.lowerBound }

        var result = Self(bitPattern: Magnitude.random(in: 0...delta.bitPattern))
        result &+= range.lowerBound
        
        assert(result >= range.lowerBound && result <= range.upperBound)
        return result
    }

    // -------------------------------------
    @inlinable
    public static func random(in range: Range<Self>) -> Self
    {
        assert(range.lowerBound < range.upperBound)
        return random(in: range.lowerBound...(range.upperBound &- 1))
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
