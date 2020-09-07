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
class WideInt_Comparable_UnitTests: XCTestCase
{
    typealias Digit = UInt32
    typealias IntType = WideInt<Digit>
    typealias UIntType = WideUInt<Digit>
    
    var randomDigit: Digit { return Digit.random(in: 0...Digit.max) }
    var randomUInt: UIntType {
        return UIntType(low: randomDigit, high: randomDigit)
    }
    var randomInt: IntType {
        return IntType(bitPattern: randomUInt)
    }
    var randomShift: Int { return Int.random(in: 0..<IntType.bitWidth) }
    
    var randomXLessThanY: (x: IntType, y: IntType)
    {
        while true
        {
            var bits1 = randomUInt
            var bits2 = randomUInt
            if bits1 == bits2 { continue }
            
            let b1 = unsafeBitCast(bits1, to: Int64.self)
            let b2 = unsafeBitCast(bits2, to: Int64.self)
            if b1 > b2 { swap(&bits1, &bits2) }
            
            return (IntType(bitPattern: bits1), IntType(bitPattern: bits2))
        }
    }

    // MARK:- Equality testing
    // -------------------------------------
    func test_zero_equals_zero()
    {
        let x = IntType()
        let y = IntType()
        
        XCTAssertTrue(x == y)
        XCTAssertTrue(y == x)
    }
    
    // -------------------------------------
    func test_any_number_equals_itself()
    {
        for _ in 0..<100
        {
            let x = randomInt
            let y = x
            
            XCTAssertTrue(x == y)
            XCTAssertTrue(y == x)
        }
    }
    
    // -------------------------------------
    func test_zero_does_not_equal_nonzero()
    {
        for _ in 0..<100
        {
            let x = IntType()
            let y = randomInt | 1
            
            XCTAssertFalse(x == y)
            XCTAssertFalse(y == x)
        }
    }
    
    // -------------------------------------
    func test_a_number_does_not_equal_a_different_number()
    {
        for _ in 0..<100
        {
            let (x, y) = randomXLessThanY
            
            XCTAssertFalse(x == y)
            XCTAssertFalse(y == x)
        }
    }
    
    // -------------------------------------
    func test_not_equals_returns_opposite_of_equals()
    {
        for _ in 0..<100
        {
            let x = randomInt
            var y = x
            
            XCTAssertNotEqual(x == y, x != y)
            XCTAssertNotEqual(y == x, y != x)
            
            y = randomInt ^ x
            
            XCTAssertNotEqual(x == y, x != y)
            XCTAssertNotEqual(y == x, y != x)
        }
    }
    
    // MARK:- LessThan testing
    // -------------------------------------
    func test_x_lessThan_y_returns_true_when_x_is_less_than_y()
    {
        for _ in 0..<100
        {
            let (x, y) = randomXLessThanY
            XCTAssertTrue(x < y)
        }
    }
    
    // -------------------------------------
    func test_x_lessThan_y_returns_false_when_x_greater_than_y()
    {
        for _ in 0..<100
        {
            let (y, x) = randomXLessThanY
            XCTAssertFalse(x < y)
        }
    }
    
    // -------------------------------------
    func test_x_lessThan_y_returns_false_when_x_equals_than_y()
    {
        for _ in 0..<100
        {
            let x = randomInt
            let y = x
            
            XCTAssertFalse(x < y)
        }
    }
    
    // MARK:- LessThanOrEqual testing
    // -------------------------------------
    func test_x_lessThanOrEqual_y_returns_true_when_x_is_less_than_y()
    {
        var randomDigit: Digit { return Digit.random(in: 0..<(Digit.max - 1)) }
        
        for _ in 0..<100
        {
            let (x, y) = randomXLessThanY
            XCTAssertTrue(x <= y)
        }
    }
    
    // -------------------------------------
    func test_x_lessThanOrEqual_y_returns_false_when_x_greater_than_y()
    {
        for _ in 0..<100
        {
            let (y, x) = randomXLessThanY
            XCTAssertFalse(x <= y)
        }
    }
    
    // -------------------------------------
    func test_x_lessThanOrEqual_y_returns_true_when_x_equals_than_y()
    {
        for _ in 0..<100
        {
            let x = randomInt
            let y = x
            XCTAssertTrue(x <= y)
        }
    }
    
    // MARK:- GreaterThan testing
    // -------------------------------------
    func test_x_greaterThan_y_returns_false_when_x_is_less_than_y()
    {
        for _ in 0..<100
        {
            let (x, y) = randomXLessThanY
            XCTAssertFalse(x > y)
        }
    }
    
    // -------------------------------------
    func test_x_greaterThan_y_returns_true_when_x_greater_than_y()
    {
        for _ in 0..<100
        {
            let (y, x) = randomXLessThanY
            XCTAssertTrue(x > y)
        }
    }
    
    // -------------------------------------
    func test_x_greaterThan_y_returns_false_when_x_equals_than_y()
    {
        for _ in 0..<100
        {
            let x = randomInt
            let y = x
            
            XCTAssertFalse(x > y)
        }
    }
    
    // MARK:- GreaterThanOrEqual testing
    // -------------------------------------
    func test_x_greaterThanOrEqual_y_returns_false_when_x_is_less_than_y()
    {
        for _ in 0..<100
        {
            let (x, y) = randomXLessThanY
            XCTAssertFalse(x >= y)
        }
    }
    
    // -------------------------------------
    func test_x_greaterThanOrEqual_y_returns_true_when_x_greater_than_y()
    {
        for _ in 0..<100
        {
            let (y, x) = randomXLessThanY
            XCTAssertTrue(x >= y)
        }
    }
    
    // -------------------------------------
    func test_x_greaterThanOrEqual_y_returns_true_when_x_equals_than_y()
    {
        for _ in 0..<100
        {
            let x = randomInt
            let y = x
            XCTAssertTrue(x >= y)
        }
    }
}
