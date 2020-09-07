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
extension WideInt: Numeric
{
    // -------------------------------------
    @inlinable public var magnitude: Magnitude
    {
        if bitPattern.signBit { return bitPattern.negated }
        return bitPattern
    }

    // -------------------------------------
    @inlinable
    public init?<T>(exactly source: T) where T : BinaryInteger
    {
        self.init(_truncatingBits: source)
        
        // Compiler should be able to optimize away this condition for inlining
        if MemoryLayout<T>.size > MemoryLayout<Self>.size
        {
            // If casting back to T doesn't give source, we don't represent
            // source exactly
            guard unsafeBitCast(self, to: T.self) == source else { return nil }
        }
        
        /*
         This assertion exists because most BigInt libraries I've seen store
         their data in an array, so they don't actually behave like built-in
         integer types, and we require that they do.
         */
        assert(
            unsafeBitCast(self, to: T.self) == source,
            "Umm... I think \(T.self) doesn't store its value "
            + "directly in itself.  Sorry that's incompatible behavior."
        )
    }
    
    // -------------------------------------
    @inlinable
    public init<T>(_truncatingBits source: T) where T : BinaryInteger
    {
        // First get the data from source into self
        self =  Swift.withUnsafeBytes(of: source) {
            $0.baseAddress!
                .bindMemory(to: Self.self, capacity: 1).pointee
        }
        
        // In case source has a smaller bitwidth, mask out the extra bits
        // Since memory layouts are known at compile time, this condition
        // should be optimized away.
        if MemoryLayout<T>.size < MemoryLayout<Self>.size
        {
            var mask =
                Magnitude.max >> (Self.bitWidth - MemoryLayout<T>.size * 8)
            self.bitPattern &= mask
            
            if source < 0
            {
                mask = Magnitude.max << (MemoryLayout<T>.size * 8)
                self.bitPattern |= mask
            }
        }
    }
    
    // -------------------------------------
    @inlinable
    public static func * (lhs: Self, rhs: Self) -> Self
    {
        let (result, overflow) = lhs.multipliedReportingOverflow(by: rhs)
        precondition(!overflow, "Muliplication overflowed \(Self.self)")
        return result
    }
    
    // -------------------------------------
    @inlinable
    public static func *= (lhs: inout Self, rhs: Self) {
        lhs = lhs * rhs
    }
    
    // -------------------------------------
    @inlinable
    public static func &* (lhs: Self, rhs: Self) -> Self
    {
        let (result, _) = lhs.multipliedReportingOverflow(by: rhs)
        return result
    }
    
    // -------------------------------------
    @inlinable
    public static func &*= (lhs: inout Self, rhs: Self) {
        lhs = lhs &* rhs
    }

    // -------------------------------------
    @inlinable
    public func multipliedFullWidth(by other: Self)
        -> (high: Self, low: Self.Magnitude)
    {
        let leftIsNegative = self.bitPattern.signBit
        let rightIsNegative = other.bitPattern.signBit
        let resultIsNegative =
            UInt8(leftIsNegative) ^ UInt8(rightIsNegative) == 1
        
        let left = leftIsNegative
            ? self.bitPattern.negated
            : self.bitPattern
        
        let right = rightIsNegative
            ? other.bitPattern.negated
            : other.bitPattern
                
        var result = left.multipliedFullWidth(by: right)
        
        if resultIsNegative
        {
            result.low.invert()
            let carry = result.low.addToSelfReportingCarry(1)
            result.high.invert()
            _ = result.high.addToSelfReportingCarry(carry)
        }
        
        return (
            high: Self(bitPattern: result.high),
            low: result.low
        )
    }

    // -------------------------------------
    @inlinable
    public func multipliedReportingOverflow(by other: Self)
        -> (partialValue: Self, overflow: Bool)
    {
        let leftIsNegative = self.bitPattern.signBit
        let rightIsNegative = other.bitPattern.signBit
        let resultIsNegative =
            UInt8(leftIsNegative) ^ UInt8(rightIsNegative) == 1
        
        let left = leftIsNegative
            ? self.bitPattern.negated
            : self.bitPattern
        
        let right = rightIsNegative
            ? other.bitPattern.negated
            : other.bitPattern
                
        var (result, overflow) = left.multipliedReportingOverflow(by: right)
        
        if resultIsNegative { result.negate() }
        else { overflow = UInt8(overflow) | UInt8(result.signBit) == 1 }
        
        return (partialValue: Self(bitPattern: result), overflow: overflow)
    }
    
}
