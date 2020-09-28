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
extension WideFloat: CustomStringConvertible
{
    // -------------------------------------
    public var description: String
    {
        if isNaN { return "nan" }
        if isZero { return isNegative ? "-0" : "0" }
        if isInfinite { return isNegative ? "-inf" : "inf" }
        let ten = Self(10)
        let one = Self.one

        /*
         TODO: Fix precision/rounding binary to decimal conversion.
         
         This algorithm is a total hack.  I just need to be able to print
         numbers while debugging.  It does have some differences in least
         couple of sigificant digits than Float80.  I probably need to do
         double-width scaling prior to the actual digit extraction.  I'm just
         scaling with the current WideFloat type. I'm sure there are errors in
         the least significant bits resulting from not only the initial
         scaling, but also when multiplying by 10 for each digit.
         
         The fast and accurate methods I've seen for doing this conversion are
         for Doubles or Floats.  The Swift standard library uses a technique
         I have a paper about, but it uses a lookup table, which is not going
         to be practical for a multi-precision library.  The performance using
         this technique is not great, but actually not too bad as along as the
         string conversion doesn't happen too often.  I use a power scaling
         that is then refined to get an intial multiplier.
         */        
        
        var temp = self.magnitude
        
        let scaleFactor: Self
        var decExponent: Int
        (scaleFactor, decExponent) =
            temp.scalingFactorForConversionToBase10()

        temp *= scaleFactor

        var mantissaDigits = [Int]()
        mantissaDigits.reserveCapacity(
            Int(log10(pow(2, Double(RawSignificand.bitWidth))))
        )
        
        while temp >= ten
        {
            temp /= ten
            decExponent += 1
        }
        while temp < one
        {
            temp *= ten
            decExponent -= 1
        }
        
        let maxDigits = mantissaDigits.capacity
        while !temp.isZero && mantissaDigits.count < maxDigits
        {
            let f80Digit = temp.float80Value
            let digit = Int(f80Digit)

            assert((0...9).contains(digit))
            mantissaDigits.append(digit)
            
            temp -= Self(digit)
            temp *= ten
        }
        
        let digit = Int(temp.float80Value)
        if digit > 5 || digit == 5 && (mantissaDigits.last! & 1 == 1)
        {
            var carry = 1
            for i in mantissaDigits.indices.reversed()
            {
                if mantissaDigits[i] == 9 {
                    mantissaDigits[i] = 0
                }
                else
                {
                    mantissaDigits[i] += 1
                    carry = 0
                    break
                }
            }
            
            if carry == 1
            {
                mantissaDigits.insert(1, at: 0)
                decExponent += 1
            }
        }
        
        // For now we just always print scientific notation.
        while mantissaDigits.first! == 0 { mantissaDigits.removeFirst() }
        
        var mantissa = isNegative ? "-" : ""
        mantissa.reserveCapacity(mantissaDigits.count + 1)
        
        mantissa.append("\(mantissaDigits.first!).")
        mantissaDigits.removeFirst()
        
        if mantissaDigits.isEmpty { mantissa.append("0") }
        else
        {
            for digit in mantissaDigits {
                mantissa.append("\(digit)")
            }
        }
        
        return mantissa
            + ((decExponent < 0) ? "e-" : "e+")
            + "\(abs(decExponent))"
    }
    
    // -------------------------------------
    private func scalingFactorForConversionToBase10()
        -> (scale: Self, decimalExponent: Int)
    {
        assert(!isNegative)
        
        let ten = Self(10)
        let hundred = ten * ten
        let thousand = hundred * ten
        
        typealias ScalingInfo = (factor: Self, exp: Int)
        var scalingFactors: [ScalingInfo] =
        [
            (ten, 1),
            (hundred, 2),
            (thousand, 3),
        ]
        
        var scaleExp = 3
        var scalingFactor = thousand
        while scalingFactor.exponent < abs(self.exponent)
        {
            let newFactor = scalingFactor * scalingFactor
            if newFactor.isInfinite { break }
            scalingFactor = newFactor
            scaleExp *= 2
            scalingFactors.append((scalingFactor, scaleExp))
        }
        
        var decExp = 0
        var s = Self.one
        for (scalingFactor, scaleExp) in scalingFactors.reversed()
        {
            if self.exponent < 0
            {
                while s.exponent < -self.exponent - scalingFactor.exponent
                {
                    s *= scalingFactor
                    decExp -= scaleExp
                }
            }
            else
            {
                while s.exponent > -self.exponent + scalingFactor.exponent
                {
                    s /= scalingFactor
                    decExp += scaleExp
                }
            }
        }
        
        while s.exponent < -self.exponent - hundred.exponent
        {
            s *= hundred
            decExp -= 2
        }
        while s.exponent > -self.exponent + ten.exponent
        {
            s /= ten
            decExp += 1
        }

        return (s, decExp)
    }
}
