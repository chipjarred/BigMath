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
/*
 This entire extension should be unnecessary but Apple doesn't seem interested
 in giving Decimal any love lately
 */
internal extension Decimal
{    
    // -------------------------------------
    @usableFromInline var floor: Decimal
    {
        if self.isNaN || self.isInfinite { return self }
        
        var decimal = self
        var rounded = Decimal()
        NSDecimalRound(&rounded, &decimal, 0, .down)
        assert(rounded <= self)
        return rounded
    }
    
    // -------------------------------------
    @usableFromInline var ceil: Decimal
    {
        if self.isNaN || self.isInfinite { return self }
        
        var decimal = self
        var rounded = Decimal()
        NSDecimalRound(&rounded, &decimal, 0, .up)
        assert(rounded >= self)
        return rounded
    }
    
    // -------------------------------------
    @usableFromInline func fmod(_ divisor: Decimal) -> Decimal
    {
        let nsQ = (abs(self) as NSDecimalNumber)
            .dividing(by: abs(divisor) as NSDecimalNumber)
        let q = (nsQ as Decimal).floor
        let p = q * divisor
        let r = abs(self) - p
        
        return self < 0 ? -r : r
    }
    
    // -------------------------------------
    @usableFromInline var intValue: Int {
        return Int(truncatingIfNeeded: int64Value)
    }
    
    // -------------------------------------
    @usableFromInline var int8Value: Int8 {
        return Int8(truncatingIfNeeded: int32Value)
    }
    
    // -------------------------------------
    @usableFromInline var int16Value: Int16 {
        return Int16(truncatingIfNeeded: int32Value)
    }
    
    // -------------------------------------
    @usableFromInline var int32Value: Int32 {
        return (self as NSDecimalNumber).int32Value
    }
    
    // -------------------------------------
    @usableFromInline var int64Value: Int64
    {
        /*
         NSDecimalNumber is broken for 64-bit, so we're working around Apple's
         bug.
         */
        var uint64 = abs(self).uint64Value
        uint64.setBit(at: UInt64.bitWidth - 1, to: 0)
        if self < 0 { uint64 = ~uint64 &+ 1 }
        return Int64(bitPattern: uint64)
    }
    
    // -------------------------------------
    @usableFromInline var uintValue: UInt {
        return UInt(truncatingIfNeeded: uint64Value)
    }
    
    // -------------------------------------
    @usableFromInline var uint8Value: UInt8 {
        return UInt8(truncatingIfNeeded: uint32Value)
    }
    
    // -------------------------------------
    @usableFromInline var uint16Value: UInt16 {
        return UInt16(truncatingIfNeeded: uint32Value)
    }
    
    // -------------------------------------
    @usableFromInline var uint32Value: UInt32 {
        return (self as NSDecimalNumber).uint32Value
    }
    
    // -------------------------------------
    @usableFromInline var uint64Value: UInt64
    {
        /*
         Apparently NSDecimalNumber is boken for 64-bit, but 32-bit works, so
         at least we can work around Apple's bug.
         */
        let radix = Decimal(UInt32.max) + 1
        var t = self.floor
        var fDigit32 = t.fmod(radix)
        let low = UInt64(fDigit32.uint32Value)
        t /= radix
        fDigit32 = t.fmod(radix)
        let high = UInt64(fDigit32.uint32Value)
        
        return (high << 32) | low
    }
    
    // -------------------------------------
    @usableFromInline var floatValue: Float {
        return (self as NSDecimalNumber).floatValue
    }
    
    // -------------------------------------
    @usableFromInline var doubleValue: Double {
        return (self as NSDecimalNumber).doubleValue
    }
    
    // -------------------------------------
    @usableFromInline static func random(in range: ClosedRange<Decimal>)
        -> Decimal
    {
        let x = UInt64.random(in: 0...UInt64.max)
        var r = Decimal(x) / Decimal(UInt64.max)
        
        let delta = range.upperBound - range.lowerBound
        if delta == 0 { return range.lowerBound }
        
        r *= delta
        r += range.lowerBound
        return r
    }
}

// -------------------------------------
public extension Decimal
{
    // -------------------------------------
    init<T: WideDigit>(_ source: T) {
        self = source.decimalValue
    }
}
