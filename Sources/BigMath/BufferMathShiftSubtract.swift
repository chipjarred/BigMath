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
/**
 This is an adaptation of the division algorithm used in the `divmod` method in
 `Limbs.swift`
 
    https://github.com/arguiot/Euler.git
 
 It's also used in at least one other library I've looked at.  The comment
 (identical in both) claims that it's an O(n) algorithm, but it definitely is
 not.  It has an order n loop, that contains an order n shift, an order n
 compare, and an order n subtraction.  It's in fact O(n^2).
 
 My intuition is that it must be slower than Knuth's Algorithm D, but I'm
 implementing it to test my intuition.  I could be wrong.  Knuth has good CPU
 cache characteristics, but this algorithm should have that too.  I think Knuth
 will do better, because the "n" in O(n^2) for Knuth is the number of digits in
 the dividend (and also the divisor - I'm assuming they're of similar length).
 The "n" in this algorithm is the number of *bits* in the dividend and divisor,
 which is a number 64 times greater than for Knuth.  But maybe, just maybe, the
 fact that it doesn't produce any multiply or divide instructions makes it
 sufficiently fast to win out.  I seriously doubt it, but we'll let the actual
 performance be the judge.  I'm giving this algorithm the best chance I can
 too.  The bit setting is done by non-branching code so the branch predictor
 won't mess that up.  I can't do anything about the if in the loop.  My left
 shift is better than the one in the original code, so I'm using mine.  I also
 start out narrowing the buffer ranges for the dividend and divsor to just the
 signficant digits - the original code is one of those arbitrary precision
 libraries that uses arrays, so they add and remove digits as they calculate
 (one of reasons those libraries are so slow).  Mine are fixed width integers,
 so I just use a buffer range to sort of simulate appending to the remainder.
 In fact, it's just adjusting a pointer to an address on the stack, so it's
 fast.
 
 - Note: I've done the benchmark, and I was right.  Shift-subtract is way
    slower than Knuth's algorithm.
 
    Time in seconds to run algorithm 100,000 times:
 
         | Integer Type | Shift-Subtract | Knuth D |
         |--------------|----------------|---------|
         |    UInt128   |      13.63     |   0.55  |
         |    UInt256   |      27.47     |   0.93  |
         |    UInt512   |      55.57     |   1.66  |
         |   UInt1024   |     114.69     |   3.15  |
         |   UInt2048   |     243.78     |   6.40  |
         |   UInt4096   |     543.61     |  13.40  |
 

 
 This algorithm does have the advantage of not requiring any scratch buffer at
 all.
 */
@usableFromInline
internal func fullWidthDivide_ShiftSubtract(
    _ dividend: UIntBuffer,
    by divisor: UIntBuffer,
    quotient: MutableUIntBuffer,
    remainder: MutableUIntBuffer)
{
    assert(divisor.reduce(0, | ) != 0, "Division by zero!")
    assert(quotient.reduce(0, | ) == 0, "Quotient not zeroed")
    assert(remainder.reduce(0, | ) == 0, "Remainder not zeroed")
    
    if dividend.reduce(0, | ) == 0 { return }
    
    var quotient = quotient
    var r = remainder[0...0]
    
    let x = signficantDigits(of: dividend)
    let y = signficantDigits(of: divisor)
    
    /*
     Quick check - if divisor has more signficant digits than dividend, then
     divisor is larger.  Return 0 quotient and dividend as remainder.
     */
    if y.count > x.count
    {
        copy(buffer: x, to: remainder)
        return
    }
    
    // bits of dividend minus one bit
    var i = (64 &* (x.count &- 1)) &+ Int(log2(Double(x.last!)))
    
    while i >= 0
    {
        leftShift(buffer: remainder[0...r.count], by: 1)
        if remainder[r.count] != 0 { r = remainder[0...r.count] }
        
        setBit(at: 0, in: &r, to: getBit(at: i, from: x))
        
        if compareBuffers(r, y) != .orderedAscending
        {
            _ = subtractReportingBorrow(r.immutable, y, result: r)
            setBit(at: i, in: &quotient, to: 1)
        }
        
        i -= 1
    }
}
