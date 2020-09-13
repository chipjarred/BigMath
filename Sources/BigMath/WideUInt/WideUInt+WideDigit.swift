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

// --------------------------------------
public protocol WideDigit: FixedWidthInteger, UnsignedInteger, Codable
{
    var signBit: Bool { get }
    mutating func invert()
}

// --------------------------------------
extension WideDigit
{
    // --------------------------------------
    @inlinable
    public func withUnsafeBytes<R>(
        _ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R
    {
        return try Swift.withUnsafeBytes(of: self) { return try body($0) }
    }
    
    // --------------------------------------
    @inlinable var decimalValue: Decimal
    {
        return Swift.withUnsafeBytes(of: self)
        {
            let uintBuf = $0.bindMemory(to: UInt.self)
            return BigMath.decimalValue(from: uintBuf[...])
        }
    }
    
    @inlinable func convert<F: BinaryFloatingPoint>(to: F.Type) -> F
    {
        return Swift.withUnsafeBytes(of: self)
        {
            let uintBuf = $0.bindMemory(to: UInt.self)
            return BigMath.convert(from: uintBuf[...], to: F.self)
        }
    }
    
    // -------------------------------------
    @inlinable
    public init(_ source: Decimal)
    {
        let value = source.floor
        
        precondition(
            !source.isNaN && value >= 0
                && value <= Decimal(Self.max),
            "\(source) cannot be represented by \(Self.self)"
        )
        self.init(_floor: value)
    }

    // -------------------------------------
    @usableFromInline @inline(__always)
    internal init(_floor: Decimal)
    {
        assert(_floor >= 0)
        assert(_floor.exponent <= Self.bitWidth)
        self.init()
        withMutableBuffer { set(buffer: $0, from: _floor) }
    }

}

// --------------------------------------
extension WideUInt: WideDigit
{
    @inlinable
    public var signBit: Bool { return high.signBit }
}

// --------------------------------------
extension UInt: WideDigit
{
    @inlinable
    public var signBit: Bool { return self >> (Self.bitWidth - 1) == 1 }
    
    @inlinable public mutating func invert() { self = ~self }
}

// --------------------------------------
extension UInt64: WideDigit
{
    @inlinable
    public var signBit: Bool { return self >> (Self.bitWidth - 1) == 1 }
    
    @inlinable public mutating func invert() { self = ~self }
}

// --------------------------------------
extension UInt32: WideDigit
{
    @inlinable
    public var signBit: Bool { return self >> (Self.bitWidth - 1) == 1 }
    
    @inlinable public mutating func invert() { self = ~self }
}

