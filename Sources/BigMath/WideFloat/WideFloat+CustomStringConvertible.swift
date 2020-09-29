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
// TODO: Replace this with precomputed values.  Will need to be conditionally
// compiled to take into account 32-bit UInts on some platforms.
let powerOf10Ladder: [(value: UInt, decimalExponent: Int)] =
{
    var decExp: Int = 1
    var val: UInt = 10
    
    var pairs = [(value: UInt, decimalExponent: Int)]()
    pairs.reserveCapacity(Int(log10(Double(UInt.max))))
    
    while true
    {
        let temp = val &* 10
        if temp < val { break }
        val = temp
        decExp += 1
        pairs.append((val, decExp))
    }
    
    return pairs
}()

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
         to be practical for a multi-precision library.
         
         Originally I said the performance wasn't terrible.  I take it back.
         It's not that bad for 64-bit WideFloat, but for 4096-bits it's truly
         awful!  I definitely have to replace this with a more efficient
         implementation.
         */        
        
        var temp = self.magnitude
        
        // Scale the WideFloat - this is the slow part, especially considering
        // our exponents can be 63.  The value range this scaling has to cover
        // is massive.
        var decExponent: Int
        let scale: Self
        (scale, decExponent) = temp.scalingFactorForConversionToBase10()
        
        temp *= scale
        
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

        var mantissaDigits = [Int]()
        // This isn't a correct calculation for the number of mantissa digits,
        // but the log calculation overflows for 4096-bit WideFloats
        mantissaDigits.reserveCapacity(
            20 * MemoryLayout<RawSignificand>.size / MemoryLayout<UInt>.size - 1
        )
        
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
        let one = Self.one
        let selfExp = self.exponent

        if selfExp == 0 { return (Self.one, 0) }
        
        let ten = Self(10)
        var scale = one
        var decExp: Int = 0

        for (decMultiple, decExpDelta) in powerOf10Ladder
        {
            let fMul = Self(decMultiple)
            let fMulExp = fMul.exponent

            if fMul.exponent > (abs(selfExp) - abs(scale.exponent))
            {
                if selfExp < 0
                {
                    while scale.exponent > -selfExp + fMulExp + 1
                    {
                        scale *= fMul
                        decExp -= decExpDelta
                    }
                }
                else
                {
                    while scale.exponent < selfExp - fMulExp - 1
                    {
                        scale /= fMul
                        decExp += decExpDelta
                    }
                }
            }
        }
        
        let tenExp = ten.exponent
        if selfExp < 0
        {
            while scale.exponent < -selfExp - tenExp
            {
                scale *= ten
                decExp -= 1
            }
        }
        else
        {
            while scale.exponent > -selfExp + tenExp
            {
                scale /= ten
                decExp += 1
            }
        }

        return (scale, decExp)
    }
}
