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

@usableFromInline
internal typealias UInt2 = WideUInt<UInt>

// -------------------------------------
/**
 Performs the equivalent of a ternary operator but without the implicit branch
 
 - Parameters:
    - condition: `Bool` condition used to select one of the other parameters
    - `trueValue`: value to select if `condition` is `true`
    - `falseValue`: value to select if `condition` is `false`
 
 - Returns: `trueValue` if `condition` is `true`; otherwise, `falseValue`
 */
@usableFromInline @inline(__always)
func select<T: FixedWidthInteger>(
    if condition: Bool,
    then trueValue: T,
    else falseValue: T) -> T
{
    let mask = ~T(condition) &+ 1
    
    return (mask & trueValue) | (~mask & falseValue)
}

// -------------------------------------
/**
 Equivalent to `Swift.min(_,_)`, but without branching.
 
 - Note, this function may or may not be faster thatn `Swift.min`, depending
 on whether the compiler already performs this optimization, and even if it
 doesn't, on whether the the branch predictor can reliably choose the right
 branch.  You should test it with realistic data for your use case to see if
 you get better performance.
 */
@usableFromInline @inline(__always)
func fastMin<T: FixedWidthInteger>(_ x: T, _ y: T) -> T {
    select(if: x <= y, then: x, else: y)
}

// -------------------------------------
/**
 Equivalent to `Swift.max(_,_)`, but without branching.
 
 - Note, this function may or may not be faster thatn `Swift.max`, depending
 on whether the compiler already performs this optimization, and even if it
 doesn't, on whether the the branch predictor can reliably choose the right
 branch.  You should test it with realistic data for your use case to see if
 you get better performance.
 */
@usableFromInline @inline(__always)
func fastMax<T: FixedWidthInteger>(_ x: T, _ y: T) -> T {
    select(if: x >= y, then: x, else: y)
}

// -------------------------------------
/**
 Performs the equivalent of a ternary operator but without the implicit branch
 
 - Parameters:
    - condition: `Bool` condition used to select one of the other parameters
    - `trueValue`: value to select if `condition` is `true`
    - `falseValue`: value to select if `condition` is `false`
 
 - Returns: `trueValue` if `condition` is `true`; otherwise, `falseValue`
 */
@usableFromInline @inline(__always)
func select(
    if condition: Bool,
    then trueValue: Double,
    else falseValue: Double) -> Double
{
    return Double(
        bitPattern: select(
            if: condition,
            then: trueValue.bitPattern,
            else: falseValue.bitPattern
        )
    )
}

// -------------------------------------
/**
 Equivalent to `Swift.min(_,_)`, but without branching.
 
 - Note, this function may or may not be faster thatn `Swift.min`, depending
 on whether the compiler already performs this optimization, and even if it
 doesn't, on whether the the branch predictor can reliably choose the right
 branch.  You should test it with realistic data for your use case to see if
 you get better performance.
 */
@usableFromInline @inline(__always)
func fastMin(_ x: Double, _ y: Double) -> Double {
    select(if: x <= y, then: x, else: y)
}

// -------------------------------------
/**
 Equivalent to `Swift.max(_,_)`, but without branching.
 
 - Note, this function may or may not be faster thatn `Swift.max`, depending
 on whether the compiler already performs this optimization, and even if it
 doesn't, on whether the the branch predictor can reliably choose the right
 branch.  You should test it with realistic data for your use case to see if
 you get better performance.
 */
@usableFromInline @inline(__always)
func fastMax(_ x: Double, _ y: Double) -> Double {
    select(if: x >= y, then: x, else: y)
}

// -------------------------------------
@usableFromInline @inline(__always)
func setBit(_ bitIndex: Int, of x: inout UInt, to bitValue: UInt)
{
    assert(bitValue & (UInt.max << 1) == 0)
    x ^= ((~bitValue &+ 1) ^ x) & (1 << bitIndex)
}

// -------------------------------------
@usableFromInline @inline(__always)
func getBit(_ bitIndex: Int, of x: UInt) -> UInt {
    return (x >> bitIndex) & 1
}

// -------------------------------------
/**
 Divide a `WideUInt<UInt>` by a `UInt` returning full width quotient and full
 width remainder.
 
 This is a special divide function used by the implementation of Knuth's
 divisions "Algorithm D" from *The Art of Computer Programming*.  Specifically
 step D3 computes a partial quotient ,and then compares it to the radix, but the
 radix is basically two digits (think of base 10, which is radix 10. 10
 requires two digits to express the radix of a single digit).  The native Swift
 methods don't provide that high digit, and in fact `dividingFullWidth`'s
 documentation even says that if it overflows the resulting quotient and
 remainder are undefined.  That's fine for many uses, but it's unacceptable for
 this particular purpose, so this function does it properly.
 
 - Parameters:
    - x: The dividend expressed as a `UInt2` (aka. `WideUInt<UInt>`).
    - y: The divisor as a `UInt`

 - Returns: A tuple whose first element is the fullwidth quotient as a `UInt2`
    and whose second element is the full width remainder, also a `UInt2`.
 */
@usableFromInline @inline(__always)
internal func divMod(_ x: UInt2, by y: UInt)
    -> (quotient: UInt2, remainder: UInt2)
{
    if x.high == 0
    {
        let (q, r) = x.low.quotientAndRemainder(dividingBy: y)
        return (UInt2(low: q), UInt2(low: r))
    }
    
    // Calculate 2-digit quotient
    let (qHigh, r) = x.high.quotientAndRemainder(dividingBy: y)
    let (qLow,  _) = y.dividingFullWidth((r, x.low))
    let q = UInt2(low: qLow, high: qHigh)
    
    // Calculate 2-digit remainder
    var p = UInt2(qLow.multipliedFullWidth(by: y))
    p.high &+= qHigh &* y
    
    return (quotient: q, remainder: x - p)
}
