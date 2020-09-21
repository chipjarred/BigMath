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

    // -------------------------------------
    /**
    Branchlessly set or clear the bit at a bit index.
    */
    mutating func setBit(at bitIndex: Int, to value: Bool)
    
    // -------------------------------------
    /**
    Branchlessly set or clear the bit at a bit index.
    */
    mutating func setBit(at bitIndex: Int, to value: UInt)
    
    // -------------------------------------
    /**
    Branchlessly toggle the bit at a bit index.
    */
    mutating func toggleBit(at bitIndex: Int)
    
    // -------------------------------------
    /**
     Get the value of a bit at a bit index
     */
    func getBit(at bitIndex: Int) -> UInt
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
        let selfBuf = self.buffer()
        return BigMath.decimalValue(from: selfBuf)
    }
    
    @inlinable func convert<F: BinaryFloatingPoint>(to: F.Type) -> F
    {
        let selfBuf = self.buffer()
        return BigMath.convert(from: selfBuf, to: F.self)
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
        let selfBuffer = self.mutableBuffer()
        set(buffer: selfBuffer, from: _floor)
    }
    
    // -------------------------------------
    /**
     Get the value of a bit at a bit index as a boolean
     */
    @inlinable
    public func bit(at bitIndex: Int) -> Bool {
        return getBit(at: bitIndex) != 0
    }
    
    // -------------------------------------
    @inlinable
    var isZero: Bool
    {
        if MemoryLayout<Self>.size <= MemoryLayout<UInt64>.size {
            return self == 0
        }
        else
        {
            let selfBuffer = self.buffer()
            
            var ptr = selfBuffer.baseAddress!
            let endPtr = ptr + selfBuffer.count
            
            while ptr < endPtr
            {
                if ptr.pointee != 0 { return false }
                ptr += 1
            }
            
            return true
        }
    }
}

// --------------------------------------
extension WideUInt: WideDigit
{
    @inlinable
    public var signBit: Bool { return high.signBit }
        
    // -------------------------------------
    /**
    Branchlessly set or clear the bit at a bit index.
    */
    @inlinable
    public mutating func setBit(at bitIndex: Int, to value: Bool)
    {
        assert((0..<Self.bitWidth).contains(bitIndex))
        setBit(at: bitIndex, to: UInt(value))
    }

    // -------------------------------------
    /**
    Branchlessly set or clear the bit at a bit index.
    */
    @inlinable
    public mutating func setBit(at bitIndex: Int, to value: UInt)
    {
        assert(value & ~1 == 0, "Not 1 or 0")
        assert((0..<Self.bitWidth).contains(bitIndex))

        var selfBuffer = self.mutableBuffer()
        BigMath.setBit(at: bitIndex, in: &selfBuffer, to: value)
    }
    
    // -------------------------------------
    /**
    Branchlessly toggle the bit at a bit index.
    */
    @inlinable
    public mutating func toggleBit(at bitIndex: Int)
    {
        assert((0..<Self.bitWidth).contains(bitIndex))
        
        var selfBuffer = self.mutableBuffer()
        BigMath.toggleBit(at: bitIndex, in: &selfBuffer)
    }
    
    // -------------------------------------
    @inlinable
    public func getBit(at bitIndex: Int) -> UInt
    {
        assert((0..<Self.bitWidth).contains(bitIndex))
        
        let selfBuffer = self.buffer()
        return BigMath.getBit(at: bitIndex, from: selfBuffer)
    }
}

// --------------------------------------
extension UInt: WideDigit
{
    @inlinable
    public var signBit: Bool { return self >> (Self.bitWidth - 1) == 1 }
    
    @inlinable public mutating func invert() { self = ~self }

    // -------------------------------------
    /**
    Branchlessly set or clear the bit at a bit index.
    */
    @inlinable
    public mutating func setBit(at bitIndex: Int, to value: UInt)
    {
        assert(value & ~1 == 0, "Not 1 or 0")
        assert((0..<Self.bitWidth).contains(bitIndex))
        
        // Non-branching bit set/clear
        let mask: Self = 1 << bitIndex

        // Choice of branchless bit setting/clearing twiddling. Either should be
        // faster than a conditional branch for any CPU manufactured since the
        // mid-1990s.
        #if false
        // This should work faster for CPUs that do speculative execution with
        // limited ALU redundancy.
        self ^= ((~value &+ 1) ^ self) & mask
        #else
        // This should work faster for most modern CPUs with significant ALU
        // redundancy.
        self = (self & ~mask) | ((~value &+ 1) & mask)
        #endif
    }
    
    // -------------------------------------
    @inlinable
    public func getBit(at bitIndex: Int) -> UInt
    {
        assert((0..<Self.bitWidth).contains(bitIndex))
        return (self >> bitIndex) & 1
    }
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

