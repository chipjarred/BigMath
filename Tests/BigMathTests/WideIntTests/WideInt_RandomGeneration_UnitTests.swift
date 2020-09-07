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
class WideInt_RandomGeneration_UnitTests: XCTestCase
{
    typealias Digit = UInt32
    typealias IntType = WideInt<Digit>
    
    // -------------------------------------
    func test_genrating_random_number_over_closed_range_does_not_generate_a_number_outside_of_that_range()
    {
        for _ in 0..<100
        {
            let lower = IntType(5)
            let upper = IntType(10)
            let x = IntType.random(in: lower...upper)
            XCTAssertGreaterThanOrEqual(x, lower)
            XCTAssertLessThanOrEqual(x, upper)
        }
        
        for _ in 0..<100
        {
            let lower = IntType(-5)
            let upper = IntType(10)
            let x = IntType.random(in: lower...upper)
            XCTAssertGreaterThanOrEqual(x, lower)
            XCTAssertLessThanOrEqual(x, upper)
        }

        for _ in 0..<100
        {
            let lower = IntType(-10)
            let upper = IntType(-5)
            let x = IntType.random(in: lower...upper)
            XCTAssertGreaterThanOrEqual(x, lower)
            XCTAssertLessThanOrEqual(x, upper)
        }

        for _ in 0..<100
        {
            let lower = IntType(5)
            let upper = IntType(10) << 32
            let x = IntType.random(in: lower...upper)
            XCTAssertGreaterThanOrEqual(x, lower)
            XCTAssertLessThanOrEqual(x, upper)
        }

        for _ in 0..<100
        {
            let lower = -IntType(5)
            let upper = IntType(10) << 32
            let x = IntType.random(in: lower...upper)
            XCTAssertGreaterThanOrEqual(x, lower)
            XCTAssertLessThanOrEqual(x, upper)
        }
        
        for _ in 0..<100
        {
            let lower = IntType(5) << 32
            let upper = IntType(10) << 32
            let x = IntType.random(in: lower...upper)
            XCTAssertGreaterThanOrEqual(x, lower)
            XCTAssertLessThanOrEqual(x, upper)
        }
        
        for _ in 0..<100
        {
            let lower = IntType(-10) << 32
            let upper = IntType(-5) << 32
            let x = IntType.random(in: lower...upper)
            XCTAssertGreaterThanOrEqual(x, lower)
            XCTAssertLessThanOrEqual(x, upper)
        }

        for _ in 0..<100
        {
            let lower = -IntType(5) << 32
            let upper = IntType(10) << 32
            let x = IntType.random(in: lower...upper)
            XCTAssertGreaterThanOrEqual(x, lower)
            XCTAssertLessThanOrEqual(x, upper)
        }

        for _ in 0..<100
        {
            let upper = IntType.random(in: (IntType.min + 1)...)
            let lower = IntType.random(in: ...upper)
            assert(lower <= upper)
            let x = IntType.random(in: lower...upper)
            XCTAssertGreaterThanOrEqual(x, lower)
            XCTAssertLessThanOrEqual(x, upper)
        }
    }
    
    // -------------------------------------
    func test_genrating_random_number_over_range_does_not_generate_a_number_outside_of_that_range()
    {
        for _ in 0..<100
        {
            let lower = IntType(5)
            let upper = IntType(10)
            let x = IntType.random(in: lower..<upper)
            XCTAssertGreaterThanOrEqual(x, lower)
            XCTAssertLessThan(x, upper)
        }
        
        for _ in 0..<100
        {
            let lower = IntType(-5)
            let upper = IntType(10)
            let x = IntType.random(in: lower..<upper)
            XCTAssertGreaterThanOrEqual(x, lower)
            XCTAssertLessThan(x, upper)
        }
        
        for _ in 0..<100
        {
            let lower = IntType(-10)
            let upper = IntType(-5)
            let x = IntType.random(in: lower..<upper)
            XCTAssertGreaterThanOrEqual(x, lower)
            XCTAssertLessThan(x, upper)
        }

        for _ in 0..<100
        {
            let lower = IntType(5)
            let upper = IntType(10) << 32
            let x = IntType.random(in: lower..<upper)
            XCTAssertGreaterThanOrEqual(x, lower)
            XCTAssertLessThan(x, upper)
        }
        
        for _ in 0..<100
        {
            let lower = IntType(-5)
            let upper = IntType(10) << 32
            let x = IntType.random(in: lower..<upper)
            XCTAssertGreaterThanOrEqual(x, lower)
            XCTAssertLessThan(x, upper)
        }
        
        for _ in 0..<100
        {
            let lower = IntType(5) << 32
            let upper = IntType(10) << 32
            let x = IntType.random(in: lower..<upper)
            XCTAssertGreaterThanOrEqual(x, lower)
            XCTAssertLessThan(x, upper)
        }
        
        for _ in 0..<100
        {
            let lower = IntType(-5) << 32
            let upper = IntType(10) << 32
            let x = IntType.random(in: lower..<upper)
            XCTAssertGreaterThanOrEqual(x, lower)
            XCTAssertLessThan(x, upper)
        }
        
        for _ in 0..<100
        {
            let lower = IntType(-10) << 32
            let upper = IntType(-5) << 32
            let x = IntType.random(in: lower..<upper)
            XCTAssertGreaterThanOrEqual(x, lower)
            XCTAssertLessThan(x, upper)
        }

        for _ in 0..<100
        {
            let upper = IntType.random(in: 2...)
            let lower = IntType.random(in: ...upper)
            let x = IntType.random(in: lower..<upper)
            XCTAssertGreaterThanOrEqual(x, lower)
            XCTAssertLessThan(x, upper)
        }
    }
}
