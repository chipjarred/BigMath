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

// TODO: Revisit initializing from a Decimal and converting to Decimal when
// the needed arithmetic ops are implemented.
#if false
// -------------------------------------
extension WideFloat
{
    @inlinable public var decimalValue: Decimal { convert(to: Decimal.self) }
    
    // -------------------------------------
    @inlinable
    public init(_ source: Decimal)
    {
        self.init(
            significandBitPattern: Self.extractSignificandBits(from: source),
            _exponent: 0
        )
        assert(isNormalized)
        let n = source.binaryFloatExponent
        _exponent =  Exponent(n)
        self.negate(if: source < 0)
    }

    // -------------------------------------
    @usableFromInline @inline(__always)
    static func extractSignificandBits(from source: Decimal) -> RawSignificand
    {
        /*
         Extracting the mantissa from Decimal is a pain, because it's not clear
         exactly how its stored.  It supports a compact and non-compact version.
         
         There's almost certainly a better way than we do here, but since so
         much of Decimal's implementation is undocumented, we do the converson
         the slow way for now.
         */
        
        let s = abs(source)
        var mantissa = s._significand
        while mantissa - mantissa.floor != 0 {
            mantissa *= 10
        }
        let sig = RawSignificand(mantissa)
        return sig
    }

    // -------------------------------------
    @inlinable public func convert(to: Decimal.Type) -> Decimal {
        return withFloatBuffer { return $0.convert(to: Decimal.self) }
    }
}
#endif
