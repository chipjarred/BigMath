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
class WideInt_Bitwise_UnitTests: XCTestCase
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
    
    var random64: Int64 { return Int64.random(in: Int64.min...Int64.max) }
    var randomShift: Int { return Int.random(in: 0...(3 * Digit.bitWidth)) }

    // MARK:- Bitshift tests
    // -------------------------------------
    func test_WideInt_assign_right_shift_gives_same_result_as_Int64_right_shift()
    {
        // -------------------------------------
        for _ in 0...100
        {
            let shift = randomShift
            let x64 = random64
            let z64 = x64 >> shift
            
            var x = IntType(x64)
            x >>= shift
            
            XCTAssertEqual(x.bitPattern.low, UInt64(bitPattern: z64).low)
            XCTAssertEqual(x.bitPattern.high, UInt64(bitPattern: z64).high)
        }
    }
    
    // -------------------------------------
    func test_WideInt_right_shift_gives_same_result_as_Int64_right_shift()
    {
        // -------------------------------------
        for _ in 0...100
        {
            let shift = randomShift
            let x64 = random64
            let z64 = x64 >> shift
            
            let x = IntType(x64)
            let z = x >> shift
            
            XCTAssertEqual(z.bitPattern.low, UInt64(bitPattern: z64).low)
            XCTAssertEqual(z.bitPattern.high, UInt64(bitPattern: z64).high)
        }
    }
    
    // -------------------------------------
    func test_WideInt_assign_left_shift_gives_same_result_as_Int64_left_shift()
    {
        // -------------------------------------
        for _ in 0...100
        {
            let shift = randomShift
            let x64 = random64
            let z64 = x64 << shift
            
            var x = IntType(x64)
            x <<= shift
            
            XCTAssertEqual(x.bitPattern.low, UInt64(bitPattern: z64).low)
            XCTAssertEqual(x.bitPattern.high, UInt64(bitPattern: z64).high)
        }
    }
    
    // -------------------------------------
    func test_WideInt_left_shift_gives_same_result_as_Int64_left_shift()
    {
        // -------------------------------------
        for _ in 0...100
        {
            let shift = randomShift
            let x64 = random64
            let z64 = x64 << shift
            
            let x = IntType(x64)
            let z = x << shift
            
            XCTAssertEqual(z.bitPattern.low, UInt64(bitPattern: z64).low)
            XCTAssertEqual(z.bitPattern.high, UInt64(bitPattern: z64).high)
        }
    }
    
    // -------------------------------------
    func test_WideInt_assign_AND_gives_same_result_as_Int64_AND()
    {
        // -------------------------------------
        for _ in 0...100
        {
            let x64 = random64
            let y64 = random64
            let z64 = x64 & y64
            
            var x = IntType(x64)
            let y = IntType(y64)
            x &= y
            
            XCTAssertEqual(x.bitPattern.low, UInt64(bitPattern: z64).low)
            XCTAssertEqual(x.bitPattern.high, UInt64(bitPattern: z64).high)
        }
    }
    
    // -------------------------------------
    func test_WideInt_AND_gives_same_result_as_Int64_AND()
    {
        // -------------------------------------
        for _ in 0...100
        {
            let x64 = random64
            let y64 = random64
            let z64 = x64 & y64
            
            let x = IntType(x64)
            let y = IntType(y64)
            let z = x & y
            
            XCTAssertEqual(z.bitPattern.low, UInt64(bitPattern: z64).low)
            XCTAssertEqual(z.bitPattern.high, UInt64(bitPattern: z64).high)
        }
    }
    
    // -------------------------------------
    func test_WideInt_assign_OR_gives_same_result_as_Int64_OR()
    {
        // -------------------------------------
        for _ in 0...100
        {
            let x64 = random64
            let y64 = random64
            let z64 = x64 | y64
            
            var x = IntType(x64)
            let y = IntType(y64)
            x |= y
            
            XCTAssertEqual(x.bitPattern.low, UInt64(bitPattern: z64).low)
            XCTAssertEqual(x.bitPattern.high, UInt64(bitPattern: z64).high)
        }
    }
    
    // -------------------------------------
    func test_WideInt_OR_gives_same_result_as_Int64_OR()
    {
        // -------------------------------------
        for _ in 0...100
        {
            let x64 = random64
            let y64 = random64
            let z64 = x64 | y64
            
            let x = IntType(x64)
            let y = IntType(y64)
            let z = x | y
            
            XCTAssertEqual(z.bitPattern.low, UInt64(bitPattern: z64).low)
            XCTAssertEqual(z.bitPattern.high, UInt64(bitPattern: z64).high)
        }
    }
    
    // -------------------------------------
    func test_WideInt_assign_XOR_gives_same_result_as_Int64_XOR()
    {
        // -------------------------------------
        for _ in 0...100
        {
            let x64 = random64
            let y64 = random64
            let z64 = x64 ^ y64
            
            var x = IntType(x64)
            let y = IntType(y64)
            x ^= y
            
            XCTAssertEqual(x.bitPattern.low, UInt64(bitPattern: z64).low)
            XCTAssertEqual(x.bitPattern.high, UInt64(bitPattern: z64).high)
        }
    }
    
    // -------------------------------------
    func test_WideInt_XOR_gives_same_result_as_Int64_XOR()
    {
        // -------------------------------------
        for _ in 0...100
        {
            let x64 = random64
            let y64 = random64
            let z64 = x64 ^ y64
            
            let x = IntType(x64)
            let y = IntType(y64)
            let z = x ^ y
            
            XCTAssertEqual(z.bitPattern.low, UInt64(bitPattern: z64).low)
            XCTAssertEqual(z.bitPattern.high, UInt64(bitPattern: z64).high)
        }
    }
    
    // -------------------------------------
    func test_WideInt_bitwise_complement_gives_same_result_as_Int64_bitwise_complement()
    {
        // -------------------------------------
        for _ in 0...100
        {
            let x64 = random64
            let z64 = ~x64
            
            let x = IntType(x64)
            let z = ~x
            
            XCTAssertEqual(z.bitPattern.low, UInt64(bitPattern: z64).low)
            XCTAssertEqual(z.bitPattern.high, UInt64(bitPattern: z64).high)
        }
    }
    
    // -------------------------------------
    func test_WideInt_twos_complement_gives_same_result_as_Int64_twos_complement()
    {
        // -------------------------------------
        for _ in 0...100
        {
            let x64 = random64
            let z64 = -x64
            
            let x = IntType(x64)
            let z = x.negated
            
            XCTAssertEqual(z.bitPattern.low, UInt64(bitPattern: z64).low)
            XCTAssertEqual(z.bitPattern.high, UInt64(bitPattern: z64).high)
        }
    }
    
    // -------------------------------------
    func test_WideInt_self_modifying_twos_complement_gives_same_result_as_Int64_twos_complement()
    {
        // -------------------------------------
        for _ in 0...100
        {
            let x64 = random64
            let z64 = -x64
            
            let x = IntType(x64)
            var z = x
            z.negate()
            
            XCTAssertEqual(z.bitPattern.low, UInt64(bitPattern: z64).low)
            XCTAssertEqual(z.bitPattern.high, UInt64(bitPattern: z64).high)
        }
    }
}
