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
        return multipliedFullWidth_schoolbook2(by: other)
    }
    
    // -------------------------------------
    /**
     Full width multiplication using the "school book" method, treating the
     `WideUInt` parameters as 2-"digit" numbers.  This method *may* have better
     performance for `WideUInt`s with relatively small bit widths, because it
     contains no loops and therefore no branches, but for larger sizes is likely
     to result in cache faults, slowing it down.
     */
    @inlinable
    public func multipliedFullWidth_schoolbook(by other: Self)
        -> (high: Self, low: Self.Magnitude)
    {
        typealias BiggerInt = WideUInt<Self>
        
        var result = BiggerInt(
            high: Self(self.high.multipliedFullWidth(by: other.high))
        )
        var p = Self(self.high.multipliedFullWidth(by: other.low))
        result &+= BiggerInt(
            low: Self(high: p.low), high: Self(low: p.high)
        )
        p = Self(self.low.multipliedFullWidth(by: other.high))
        result &+= BiggerInt(
            low: Self(high: p.low), high: Self(low: p.high)
        )
        result &+= BiggerInt(
            low: Self(self.low.multipliedFullWidth(by: other.low))
        )

        return (high: result.high, low: result.low)
    }
    
    // -------------------------------------
    /**
     Full width multiplication using the "school book" method, treating the
     `WideUInt` parameters as buffers of `UInt` "digits".  This method will
     have better cache performance for `WideUInt`s with large bit widths.
     */
    @inlinable
    public func multipliedFullWidth_schoolbook2(by other: Self)
        -> (high: Self, low: Self.Magnitude)
    {
        typealias BiggerInt = WideUInt<Self>
        
        var result: BiggerInt = 0
        result.withBuffers(self, other) {
            fullMultiplyBuffers_SchoolBook($1, $2, result: $0)
        }

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
        result.withBuffers(self, other)
        { rBuf, xBuf, yBuf in
            var scratch = Self()
            scratch.withMutableBuffer
            { s1Buf in
                var scratch = Self()
                scratch.withMutableBuffer
                { s2Buf in
                    var scratch = WideUInt<Self>()
                    scratch.withMutableBuffer
                    { s3Buf in
                        fullMultiplyBuffers_Karatsuba(
                            xBuf,
                            yBuf,
                            scratch1: s1Buf,
                            scratch2: s2Buf,
                            scratch3: s3Buf,
                            result: rBuf
                        )
                    }
                }
            }
        }
        
        return (result.high, result.low)
    }

    // -------------------------------------
    @inlinable
    public func multipliedReportingOverflow(by other: Self)
        -> (partialValue: Self, overflow: Bool)
    {
        var result: Self = 0
        let overflow: Bool = result.withBuffers(self, other)
        {
            var zBuf = $0
            return lowerHalfMuliplyBuffers_SchoolBook(
                $1,
                $2,
                result: &zBuf
            )
        }
        return (result, overflow)
    }
    
}
