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
extension WideUInt: Numeric
{
    @inlinable public var magnitude: Self { return self }

    // -------------------------------------
    @inlinable
    public init?<T>(exactly source: T) where T : BinaryInteger
    {
        guard source.signum() >= 0 else { return nil }
        
        if MemoryLayout<Digit>.size >= MemoryLayout<T>.size {
            self.init(low: Digit(source))
        }
        else
        {
            let digitMax = T(Digit.max)
            if MemoryLayout<Self>.size <= MemoryLayout<T>.size
            {
                let tMax = (digitMax << Digit.bitWidth) | digitMax
                guard source <= tMax else { return nil }
            }
            
            self.init(
                low: Digit(source & T(Digit.max)),
                high: Digit(source >> Digit.bitWidth)
            )
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
        return multipliedFullWidth_schoolbook(by: other)
    }
    
    // -------------------------------------
    /**
     Full width multiplication using the "school book" method, treating the
     `WideUInt` parameters as buffers of `UInt` "digits".  This method will
     have better cache performance for `WideUInt`s with large bit widths.
     */
    @inlinable
    public func multipliedFullWidth_schoolbook(by other: Self)
        -> (high: Self, low: Self.Magnitude)
    {
        typealias BiggerInt = WideUInt<Self>
        
        var result: BiggerInt = 0
        let resultBuffer = result.mutableBuffer()
        let selfBuffer = self.buffer()
        let otherBuffer = other.buffer()
        
        fullMultiplyBuffers_SchoolBook(selfBuffer, otherBuffer, result: resultBuffer)

        return (high: result.high, low: result.low)
    }

    // -------------------------------------
    /**
     Full width multiplication using the Karatsuba method
     */
    @inlinable
    public func multipliedFullWidth_karatsuba(by other: Self)
        -> (high: Self, low: Self.Magnitude)
    {
        var result = WideUInt<Self>()
        var scratch1 = Self()
        var scratch2 = Self()
        var scratch3 = WideUInt<Self>()
        
        let rBuf = result.mutableBuffer()
        let xBuf = self.buffer()
        let yBuf = other.buffer()
        let s1Buf = scratch1.mutableBuffer()
        let s2Buf = scratch2.mutableBuffer()
        let s3Buf = scratch3.mutableBuffer()

        fullMultiplyBuffers_Karatsuba(
            xBuf,
            yBuf,
            scratch1: s1Buf,
            scratch2: s2Buf,
            scratch3: s3Buf,
            result: rBuf
        )

        return (result.high, result.low)
    }

    // -------------------------------------
    @inlinable
    public func multipliedReportingOverflow(by other: Self)
        -> (partialValue: Self, overflow: Bool)
    {
        var result: Self = 0
        
        var zBuf = result.mutableBuffer()
        let xBuf = self.buffer()
        let yBuf = other.buffer()
        
        let overflow: Bool = lowerHalfMuliplyBuffers_SchoolBook(
            xBuf,
            yBuf,
            result: &zBuf
        )
            
        return (result, overflow)
    }
    
}
