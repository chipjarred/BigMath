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
class WideInt_Division_UnitTests: XCTestCase
{
    typealias Digit = UInt32
    typealias SignedDigit = UInt32
    typealias IntType = WideInt<Digit>
    typealias UIntType = WideUInt<Digit>
    
    // -------------------------------------
    func wideInt(high: Int32, low: Digit) -> IntType
    {
        return IntType(
            bitPattern: UIntType(
                low: low,
                high: Digit(bitPattern: high)
            )
        )
    }
    
    var random32: Int32 { Int32.random(in: Int32.min...Int32.max) }
    var urandom32: UInt32 { UInt32.random(in: 0...UInt32.max) }
    var random64: Int64 { Int64.random(in: Int64.min...Int64.max) }
    var urandom64: UInt64 { UInt64.random(in: 0...UInt64.max) }

    // -------------------------------------
    func test_fullWidthDividing_by_1_gives_dividend()
    {
        for _ in 0..<100
        {
            let x = wideInt(high: random32, low: urandom32)
            let y: IntType = 1
            
            let z = y.dividingFullWidth(
                (high: x.bitPattern.signBit ? -1 : 0, low: x.bitPattern)
            )
            
            XCTAssertEqual(z.quotient, x)
            XCTAssertEqual(z.remainder, 0)
        }
    }

    // -------------------------------------
    func test_fullWidthDividing_gives_same_results_as_Int64()
    {
        typealias IntType = WideInt<UInt32>
        typealias UIntType = WideUInt<UInt32>

        for _ in 0..<100
        {
            let x64 = (high: random64, low: urandom64)
            let y64 = random64
            let (q64, r64) = y64.dividingFullWidth(x64)
            
            let x = (high: IntType(x64.high), low: UIntType(x64.low))
            let y = IntType(y64)

            let (q, r) = y.dividingFullWidth((x.high, x.low))
            
            XCTAssertEqual(q, IntType(q64))
            XCTAssertEqual(r, IntType(r64))
        }
    }
}
