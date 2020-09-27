//
//  WideFloat_Rounding_UnitTests.swift
//  
//
//  Created by Chip Jarred on 9/26/20.
//

import XCTest
@testable import BigMath

// -------------------------------------
class WideFloat_Rounding_UnitTests: XCTestCase
{
    // -------------------------------------
    var randomFloat80: Float80
    {
        let bigLimit = Float80(UInt64.max) / 2
        let bigRange = -bigLimit...bigLimit
        let littleRange = Float80.leastNormalMagnitude...1
        let x = Float80.random(in: bigRange)
        return  x * Float80.random(in: littleRange)
    }
    
    // -------------------------------------
    func test_rounding_towardZero()
    {
        typealias FloatType = WideFloat<UInt64>
        typealias TestCase = (x: Float80, expected: Float80)
        
        let roundingRule = FloatingPointRoundingRule.towardZero
        
        let testCases: [TestCase] =
        [
        ]
        
        for (x80, expected) in testCases
        {
            let x = FloatType(x80)
            var y = x
            y.round(roundingRule)
            
            XCTAssertEqual(y.float80Value, expected)
        }
        
        for _ in 0..<100
        {
            let x80 = randomFloat80
            var expected = x80
            expected.round(roundingRule)
            
            let x = FloatType(x80)
            var y = x
            y.round(roundingRule)
            
            if y.float80Value != expected
            {
                print("--------- Failing case:")
                print("         x80 = \(x80)")
                print("    expected = \(expected)")
                print("      actual = \(y.float80Value)")
                print("x80.exponent = \(x80.exponent)")
            }
            
            XCTAssertEqual(y.float80Value, expected)
        }
    }
    
    // -------------------------------------
    func test_rounding_awayFromZero()
    {
        typealias FloatType = WideFloat<UInt64>
        typealias TestCase = (x: Float80, expected: Float80)
        
        let roundingRule = FloatingPointRoundingRule.awayFromZero
        
        let testCases: [TestCase] =
        [
        ]
        
        for (x80, expected) in testCases
        {
            let x = FloatType(x80)
            var y = x
            y.round(roundingRule)
            
            XCTAssertEqual(y.float80Value, expected)
        }
        
        for _ in 0..<100
        {
            let x80 = randomFloat80
            var expected = x80
            expected.round(roundingRule)
            
            let x = FloatType(x80)
            var y = x
            y.round(roundingRule)
            
            if y.float80Value != expected
            {
                print("--------- Failing case:")
                print("         x80 = \(x80)")
                print("    expected = \(expected)")
                print("      actual = \(y.float80Value)")
                print("x80.exponent = \(x80.exponent)")
            }
            
            XCTAssertEqual(y.float80Value, expected)
        }
    }

    // -------------------------------------
    func test_rounding_toNearestOrEven()
    {
        typealias FloatType = WideFloat<UInt64>
        typealias TestCase = (x: Float80, expected: Float80)
        
        let roundingRule = FloatingPointRoundingRule.toNearestOrEven
        
        let testCases: [TestCase] =
        [
        ]
        
        for (x80, expected) in testCases
        {
            let x = FloatType(x80)
            var y = x
            y.round(roundingRule)
            
            XCTAssertEqual(y.float80Value, expected)
        }
        
        for _ in 0..<100
        {
            let x80 = randomFloat80
            var expected = x80
            expected.round(roundingRule)
            
            let x = FloatType(x80)
            var y = x
            y.round(roundingRule)
            
            if y.float80Value != expected
            {
                print("--------- Failing case:")
                print("         x80 = \(x80)")
                print("    expected = \(expected)")
                print("      actual = \(y.float80Value)")
                print("x80.exponent = \(x80.exponent)")
            }
            
            XCTAssertEqual(y.float80Value, expected)
        }
    }
    
    // -------------------------------------
    func test_rounding_toNearestOrAwayFromZero()
    {
        typealias FloatType = WideFloat<UInt64>
        typealias TestCase = (x: Float80, expected: Float80)
        
        let roundingRule = FloatingPointRoundingRule.toNearestOrAwayFromZero
        
        let testCases: [TestCase] =
        [
        ]
        
        for (x80, expected) in testCases
        {
            let x = FloatType(x80)
            var y = x
            y.round(roundingRule)
            
            XCTAssertEqual(y.float80Value, expected)
        }
        
        for _ in 0..<100
        {
            let x80 = randomFloat80
            var expected = x80
            expected.round(roundingRule)
            
            let x = FloatType(x80)
            var y = x
            y.round(roundingRule)
            
            if y.float80Value != expected
            {
                print("--------- Failing case:")
                print("         x80 = \(x80)")
                print("    expected = \(expected)")
                print("      actual = \(y.float80Value)")
                print("x80.exponent = \(x80.exponent)")
            }
            
            XCTAssertEqual(y.float80Value, expected)
        }
    }
    
    // -------------------------------------
    func test_rounding_up()
    {
        typealias FloatType = WideFloat<UInt64>
        typealias TestCase = (x: Float80, expected: Float80)
        
        let roundingRule = FloatingPointRoundingRule.up
        
        let testCases: [TestCase] =
        [
        ]
        
        for (x80, expected) in testCases
        {
            let x = FloatType(x80)
            var y = x
            y.round(roundingRule)
            
            XCTAssertEqual(y.float80Value, expected)
        }
        
        for _ in 0..<100
        {
            let x80 = randomFloat80
            var expected = x80
            expected.round(roundingRule)
            
            let x = FloatType(x80)
            var y = x
            y.round(roundingRule)
            
            if y.float80Value != expected
            {
                print("--------- Failing case:")
                print("         x80 = \(x80)")
                print("    expected = \(expected)")
                print("      actual = \(y.float80Value)")
                print("x80.exponent = \(x80.exponent)")
            }
            
            XCTAssertEqual(y.float80Value, expected)
        }
    }
    
    // -------------------------------------
    func test_rounding_down()
    {
        typealias FloatType = WideFloat<UInt64>
        typealias TestCase = (x: Float80, expected: Float80)
        
        let roundingRule = FloatingPointRoundingRule.down
        
        let testCases: [TestCase] =
        [
        ]
        
        for (x80, expected) in testCases
        {
            let x = FloatType(x80)
            var y = x
            y.round(roundingRule)
            
            XCTAssertEqual(y.float80Value, expected)
        }
        
        for _ in 0..<100
        {
            let x80 = randomFloat80
            var expected = x80
            expected.round(roundingRule)
            
            let x = FloatType(x80)
            var y = x
            y.round(roundingRule)
            
            if y.float80Value != expected
            {
                print("--------- Failing case:")
                print("         x80 = \(x80)")
                print("    expected = \(expected)")
                print("      actual = \(y.float80Value)")
                print("x80.exponent = \(x80.exponent)")
            }
            
            XCTAssertEqual(y.float80Value, expected)
        }
    }
}
