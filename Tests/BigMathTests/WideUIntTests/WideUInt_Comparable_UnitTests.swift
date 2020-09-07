//
//  WideUInt_Comparable_UnitTests.swift
//  
//
//  Created by Chip Jarred on 8/17/20.
//

import XCTest
@testable import BigMath

// -------------------------------------
class WideUInt_Comparable_UnitTests: XCTestCase
{
    typealias Digit = UInt32
    typealias IntType = WideUInt<Digit>
    
    // MARK:- Equality testing
    // -------------------------------------
    func test_zero_equals_zero()
    {
        let x = IntType(low: 0, high: 0)
        let y = IntType(low: 0, high: 0)
        
        XCTAssertTrue(x == y)
        XCTAssertTrue(y == x)
    }
    
    // -------------------------------------
    func test_any_number_equals_itself()
    {
        var randomDigit: Digit { return Digit.random(in: 0..<Digit.max) }
        
        for _ in 0..<100
        {
            let x = IntType(low: randomDigit, high: randomDigit)
            let y = x
            
            XCTAssertTrue(x == y)
            XCTAssertTrue(y == x)
        }
    }
    
    // -------------------------------------
    func test_zero_does_not_equal_nonzero()
    {
        var randomDigit: Digit { return Digit.random(in: 1..<Digit.max) }
        
        for _ in 0..<100
        {
            let x = IntType(low: 0, high: 0)
            var y = IntType(low: randomDigit, high: 0)
            
            XCTAssertFalse(x == y)
            XCTAssertFalse(y == x)
            
            swap(&y.low, &y.high)
            
            XCTAssertFalse(x == y)
            XCTAssertFalse(y == x)
            
            y.high = randomDigit
            
            XCTAssertFalse(x == y)
            XCTAssertFalse(y == x)
        }
    }
    
    // -------------------------------------
    func test_a_number_does_not_equal_a_different_number()
    {
        var randomDigit: Digit { return Digit.random(in: 1..<Digit.max) }
        
        for _ in 0..<100
        {
            let x = IntType(low: randomDigit, high: randomDigit)
            var y = x
            
            repeat { y.low = randomDigit } while (y.low == x.low)
            
            XCTAssertFalse(x == y)
            XCTAssertFalse(y == x)
            
            y = x
            
            repeat { y.high = randomDigit } while (y.high == x.high)
            
            XCTAssertFalse(x == y)
            XCTAssertFalse(y == x)
            
            repeat { y.low = randomDigit } while (y.low == x.low)
            
            XCTAssertFalse(x == y)
            XCTAssertFalse(y == x)
        }
    }
    
    // -------------------------------------
    func test_not_equals_returns_opposite_of_equals()
    {
        var randomDigit: Digit { return Digit.random(in: 1..<Digit.max) }
        
        for _ in 0..<100
        {
            let x = IntType(low: randomDigit, high: randomDigit)
            var y = x
            
            XCTAssertNotEqual(x == y, x != y)
            XCTAssertNotEqual(y == x, y != x)
            
            y = IntType(low: randomDigit, high: randomDigit)
            
            XCTAssertNotEqual(x == y, x != y)
            XCTAssertNotEqual(y == x, y != x)
        }
    }
    
    // MARK:- LessThan testing
    // -------------------------------------
    func test_x_lessThan_y_returns_true_when_x_is_less_than_y()
    {
        var randomDigit: Digit { return Digit.random(in: 0..<(Digit.max - 1)) }
        
        for _ in 0..<100
        {
            var x = IntType(low: randomDigit, high: 0)
            var y = IntType(low: x.low + 1, high: 0)
            
            XCTAssertTrue(x < y)
            
            y = IntType(low: x.low, high: 1)
            
            XCTAssertTrue(x < y)
            
            x.high = randomDigit
            y = IntType(low: x.low, high: x.high + 1)
            
            XCTAssertTrue(x < y)
            
            y = IntType(low: x.low + 1, high: x.high)
            
            XCTAssertTrue(x < y)
        }
    }
    
    // -------------------------------------
    func test_x_lessThan_y_returns_false_when_x_greater_than_y()
    {
        var randomDigit: Digit { return Digit.random(in: 1..<Digit.max) }
        
        for _ in 0..<100
        {
            var x = IntType(low: randomDigit, high: 0)
            var y = IntType(low: x.low - 1, high: 0)
            
            XCTAssertFalse(x < y)
            
            x.high = randomDigit
            y = IntType(low: x.low - 1, high: x.high)
            
            XCTAssertFalse(x < y)
            
            x.low = Digit.max
            y.high -= 1
            
            XCTAssertFalse(x < y)
            
            x.low = 0

            XCTAssertFalse(x < y)
        }
    }
    
    // -------------------------------------
    func test_x_lessThan_y_returns_false_when_x_equals_than_y()
    {
        var randomDigit: Digit { return Digit.random(in: 1..<Digit.max) }
        
        for _ in 0..<100
        {
            var x = IntType(low: randomDigit, high: 0)
            var y = x
            
            XCTAssertFalse(x < y)
            
            x.high = randomDigit
            y = x
            
            XCTAssertFalse(x < y)
            
            x.low = Digit.max
            y = x
            
            XCTAssertFalse(x < y)
            
            x.low = 0
            y = x

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
            var x = IntType(low: randomDigit, high: 0)
            var y = IntType(low: x.low + 1, high: 0)
            
            XCTAssertTrue(x <= y)
            
            y = IntType(low: x.low, high: 1)
            
            XCTAssertTrue(x <= y)
            
            x.high = randomDigit
            y = IntType(low: x.low, high: x.high + 1)
            
            XCTAssertTrue(x <= y)
            
            y = IntType(low: x.low + 1, high: x.high)
            
            XCTAssertTrue(x <= y)
        }
    }
    
    // -------------------------------------
    func test_x_lessThanOrEqual_y_returns_false_when_x_greater_than_y()
    {
        var randomDigit: Digit { return Digit.random(in: 1..<Digit.max) }
        
        for _ in 0..<100
        {
            var x = IntType(low: randomDigit, high: 0)
            var y = IntType(low: x.low - 1, high: 0)
            
            XCTAssertFalse(x <= y)
            
            x.high = randomDigit
            y = IntType(low: x.low - 1, high: x.high)
            
            XCTAssertFalse(x <= y)
            
            x.low = Digit.max
            y.high -= 1
            
            XCTAssertFalse(x <= y)
            
            x.low = 0

            XCTAssertFalse(x <= y)
        }
    }
    
    // -------------------------------------
    func test_x_lessThanOrEqual_y_returns_true_when_x_equals_than_y()
    {
        var randomDigit: Digit { return Digit.random(in: 1..<Digit.max) }
        
        for _ in 0..<100
        {
            var x = IntType(low: randomDigit, high: 0)
            var y = x
            
            XCTAssertTrue(x <= y)
            
            x.high = randomDigit
            y = x
            
            XCTAssertTrue(x <= y)

            x.low = Digit.max
            y = x
            
            XCTAssertTrue(x <= y)

            x.low = 0
            y = x

            XCTAssertTrue(x <= y)
        }
    }
    
    // MARK:- GreaterThan testing
    // -------------------------------------
    func test_x_greaterThan_y_returns_false_when_x_is_less_than_y()
    {
        var randomDigit: Digit { return Digit.random(in: 0..<(Digit.max - 1)) }
        
        for _ in 0..<100
        {
            var x = IntType(low: randomDigit, high: 0)
            var y = IntType(low: x.low + 1, high: 0)
            
            XCTAssertFalse(x > y)
            
            y = IntType(low: x.low, high: 1)
            
            XCTAssertFalse(x > y)
            
            x.high = randomDigit
            y = IntType(low: x.low, high: x.high + 1)
            
            XCTAssertFalse(x > y)
            
            y = IntType(low: x.low + 1, high: x.high)
            
            XCTAssertFalse(x > y)
        }
    }
    
    // -------------------------------------
    func test_x_greaterThan_y_returns_true_when_x_greater_than_y()
    {
        var randomDigit: Digit { return Digit.random(in: 1..<Digit.max) }
        
        for _ in 0..<100
        {
            var x = IntType(low: randomDigit, high: 0)
            var y = IntType(low: x.low - 1, high: 0)
            
            XCTAssertTrue(x > y)
            
            x.high = randomDigit
            y = IntType(low: x.low - 1, high: x.high)
            
            XCTAssertTrue(x > y)
            
            x.low = Digit.max
            y.high -= 1
            
            XCTAssertTrue(x > y)
            
            x.low = 0

            XCTAssertTrue(x > y)
        }
    }
    
    // -------------------------------------
    func test_x_greaterThan_y_returns_false_when_x_equals_than_y()
    {
        var randomDigit: Digit { return Digit.random(in: 1..<Digit.max) }
        
        for _ in 0..<100
        {
            var x = IntType(low: randomDigit, high: 0)
            var y = x
            
            XCTAssertFalse(x > y)
            
            x.high = randomDigit
            y = x
            
            XCTAssertFalse(x > y)

            x.low = Digit.max
            y = x
            
            XCTAssertFalse(x > y)

            x.low = 0
            y = x

            XCTAssertFalse(x > y)
        }
    }
    
    // MARK:- GreaterThanOrEqual testing
    // -------------------------------------
    func test_x_greaterThanOrEqual_y_returns_false_when_x_is_less_than_y()
    {
        var randomDigit: Digit { return Digit.random(in: 0..<(Digit.max - 1)) }
        
        for _ in 0..<100
        {
            var x = IntType(low: randomDigit, high: 0)
            var y = IntType(low: x.low + 1, high: 0)
            
            XCTAssertFalse(x >= y)
            
            y = IntType(low: x.low, high: 1)
            
            XCTAssertFalse(x >= y)
            
            x.high = randomDigit
            y = IntType(low: x.low, high: x.high + 1)
            
            XCTAssertFalse(x >= y)
            
            y = IntType(low: x.low + 1, high: x.high)
            
            XCTAssertFalse(x >= y)
        }
    }
    
    // -------------------------------------
    func test_x_greaterThanOrEqual_y_returns_true_when_x_greater_than_y()
    {
        var randomDigit: Digit { return Digit.random(in: 1..<Digit.max) }
        
        for _ in 0..<100
        {
            var x = IntType(low: randomDigit, high: 0)
            var y = IntType(low: x.low - 1, high: 0)
            
            XCTAssertTrue(x >= y)
            
            x.high = randomDigit
            y = IntType(low: x.low - 1, high: x.high)
            
            XCTAssertTrue(x >= y)
            
            x.low = Digit.max
            y.high -= 1
            
            XCTAssertTrue(x >= y)
            
            x.low = 0

            XCTAssertTrue(x >= y)
        }
    }
    
    // -------------------------------------
    func test_x_greaterThanOrEqual_y_returns_true_when_x_equals_than_y()
    {
        var randomDigit: Digit { return Digit.random(in: 1..<Digit.max) }
        
        for _ in 0..<100
        {
            var x = IntType(low: randomDigit, high: 0)
            var y = x
            
            XCTAssertTrue(x >= y)
            
            x.high = randomDigit
            y = x
            
            XCTAssertTrue(x >= y)
            
            x.low = Digit.max
            y = x
            
            XCTAssertTrue(x >= y)
            
            x.low = 0
            y = x

            XCTAssertTrue(x >= y)
        }
    }
}
