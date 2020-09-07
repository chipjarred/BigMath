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

import XCTest
@testable import BigMath

// -------------------------------------
class WideInt_Addition_UnitTests: XCTestCase
{
    typealias Digit = UInt32
    typealias SignedDigit = UInt32
    typealias IntType = WideInt<Digit>
    typealias UIntType = WideUInt<Digit>
    
    // -------------------------------------
    func wideInt(from x: Int64) -> IntType
    {
        let ux = UInt64(bitPattern: x)
        
        return IntType(
            bitPattern: UIntType(
                low: ux.low,
                high: ux.high
            )
        )
    }
    
    // -------------------------------------
    func test_overflowing_addition_of_two_64_bit_WideInts_produces_the_same_result_as_adding_the_equivalent_Int64s()
    {
        var random64: Int64 { return Int64.random(in: Int64.min...Int64.max) }
        
        for _ in 0..<100
        {
            let x64 = random64
            let y64 = random64
            
            let x = wideInt(from: x64)
            let y = wideInt(from: y64)

            let z64 = x64 &+ y64
            var z = x &+ y
            
            XCTAssertEqual(z.bitPattern.low, UInt64(bitPattern: z64).low)
            XCTAssertEqual(z.bitPattern.high, UInt64(bitPattern: z64).high)

            z = y &+ x
            
            XCTAssertEqual(z.bitPattern.low, UInt64(bitPattern: z64).low)
            XCTAssertEqual(z.bitPattern.high, UInt64(bitPattern: z64).high)
        }
    }
}
