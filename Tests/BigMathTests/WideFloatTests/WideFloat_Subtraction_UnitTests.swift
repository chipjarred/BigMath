//
//  WideFloat_Subtraction_UnitTests.swift
//  
//
//  Created by Chip Jarred on 9/15/20.
//

import XCTest
@testable import BigMath

// -------------------------------------
class WideFloat_Subtraction_UnitTests: XCTestCase
{
    typealias FloatType = WideFloat<UInt64>
    
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
    var randomDouble: Double
    {
        let bigLimit = Double(UInt64.max) / 2
        let bigRange = -bigLimit...bigLimit
        let littleRange = Double.leastNormalMagnitude...1
        let x = Double.random(in: bigRange)
        return  x * Double.random(in: littleRange)
    }
    
    // -------------------------------------
    var randomFloat: Float
    {
        let bigLimit = Float(UInt64.max) / 2
        let bigRange = -bigLimit...bigLimit
        let littleRange = Float.leastNormalMagnitude...1
        let x = Float.random(in: bigRange)
        return  x * Float.random(in: littleRange)
    }

    var random64: Int64 { Int64.random(in: Int64.min...Int64.max) }
    var urandom64: UInt64 { UInt64.random(in: UInt64.min...UInt64.max) }
    
    // -------------------------------------
    func test_subtracting_NaN_results_in_NaN()
    {
        let otherValues: [FloatType] =
        [
            FloatType.nan, FloatType.signalingNaN,
            FloatType.infinity, FloatType.infinity.negated,
            FloatType.leastNormalMagnitude,
            FloatType.leastNormalMagnitude.negated,
            FloatType.leastNonzeroMagnitude,
            FloatType.leastNonzeroMagnitude.negated,
            FloatType.greatestFiniteMagnitude,
            FloatType.greatestFiniteMagnitude.negated,
            FloatType(),
            FloatType().negated,
            FloatType(1),
            FloatType(1).negated
        ]
        
        for other in otherValues
        {
            var difference = FloatType.nan - other
            XCTAssertTrue(difference.isNaN)
            XCTAssertFalse(difference.isSignalingNaN)
            
            difference = other - FloatType.nan
            XCTAssertTrue(difference.isNaN)
            XCTAssertFalse(difference.isSignalingNaN)
        }
        
        for _ in 0..<100
        {
            let other = FloatType(randomDouble)
            var difference = FloatType.nan - other
            XCTAssertTrue(difference.isNaN)
            XCTAssertFalse(difference.isSignalingNaN)
            
            difference = other - FloatType.nan
            XCTAssertTrue(difference.isNaN)
            XCTAssertFalse(difference.isSignalingNaN)
        }
        
        for _ in 0..<100
        {
            let other = FloatType(urandom64)
            var difference = FloatType.nan - other
            XCTAssertTrue(difference.isNaN)
            XCTAssertFalse(difference.isSignalingNaN)
            
            difference = other - FloatType.nan
            XCTAssertTrue(difference.isNaN)
            XCTAssertFalse(difference.isSignalingNaN)
        }
        
        for _ in 0..<100
        {
            let other = FloatType(random64)
            var difference = FloatType.nan - other
            XCTAssertTrue(difference.isNaN)
            XCTAssertFalse(difference.isSignalingNaN)
            
            difference = other - FloatType.nan
            XCTAssertTrue(difference.isNaN)
            XCTAssertFalse(difference.isSignalingNaN)
        }
    }
    
    // -------------------------------------
    func test_subtracting_sNaN_results_in_NaN()
    {
        let otherValues: [FloatType] =
        [
            FloatType.nan, FloatType.signalingNaN,
            FloatType.infinity.negated,
            FloatType.leastNormalMagnitude,
            FloatType.leastNormalMagnitude.negated,
            FloatType.leastNonzeroMagnitude,
            FloatType.leastNonzeroMagnitude.negated,
            FloatType.greatestFiniteMagnitude,
            FloatType.greatestFiniteMagnitude.negated,
            FloatType(),
            FloatType().negated,
            FloatType(1),
            FloatType(1).negated
        ]
        
        for other in otherValues
        {
            var difference = FloatType.signalingNaN - other
            XCTAssertTrue(difference.isNaN)
            XCTAssertFalse(difference.isSignalingNaN)
            
            difference = other - FloatType.signalingNaN
            XCTAssertTrue(difference.isNaN)
            XCTAssertFalse(difference.isSignalingNaN)
        }
        
        for _ in 0..<100
        {
            let other = FloatType(randomDouble)
            var difference = FloatType.signalingNaN - other
            XCTAssertTrue(difference.isNaN)
            XCTAssertFalse(difference.isSignalingNaN)
            
            difference = other - FloatType.signalingNaN
            XCTAssertTrue(difference.isNaN)
            XCTAssertFalse(difference.isSignalingNaN)
        }
        
        for _ in 0..<100
        {
            let other = FloatType(urandom64)
            var difference = FloatType.signalingNaN - other
            XCTAssertTrue(difference.isNaN)
            XCTAssertFalse(difference.isSignalingNaN)
            
            difference = other - FloatType.signalingNaN
            XCTAssertTrue(difference.isNaN)
            XCTAssertFalse(difference.isSignalingNaN)
        }
        
        for _ in 0..<100
        {
            let other = FloatType(random64)
            var difference = FloatType.signalingNaN - other
            XCTAssertTrue(difference.isNaN)
            XCTAssertFalse(difference.isSignalingNaN)
            
            difference = other - FloatType.signalingNaN
            XCTAssertTrue(difference.isNaN)
            XCTAssertFalse(difference.isSignalingNaN)
        }
    }
    
    // -------------------------------------
    func test_subtracting_infinity_from_infinity_of_opposite_sign_results_in_infinity_of_same_sign_as_the_minuend()
    {
        var difference = FloatType.infinity - FloatType.infinity.negated
        XCTAssertTrue(difference.isInfinite)
        XCTAssertFalse(difference.isNegative)

        difference = FloatType.infinity.negated - FloatType.infinity
        XCTAssertTrue(difference.isInfinite)
        XCTAssertTrue(difference.isNegative)
    }
    
    // -------------------------------------
    func test_subtracting_infinity_from_infinity_of_same_sign_results_NaN()
    {
        var difference = FloatType.infinity - FloatType.infinity
        XCTAssertTrue(difference.isNaN)

        difference = FloatType.infinity.negated - FloatType.infinity.negated
        XCTAssertTrue(difference.isNaN)
    }
    
    // -------------------------------------
    func test_subtracting_zero_of_the_same_sign_results_in_a_positive_zero()
    {
        var difference = FloatType.zero - FloatType.zero
        XCTAssertTrue(difference.isZero)
        XCTAssertFalse(difference.isNegative)

        difference = FloatType.zero.negated - FloatType.zero.negated
        XCTAssertTrue(difference.isZero)
        XCTAssertFalse(difference.isNegative)
    }
    
    // -------------------------------------
    func test_subtracting_zero_of_the_different_sign_results_in_zero_with_same_sign_as_minuend()
    {
        var difference = FloatType.zero - FloatType.zero.negated
        XCTAssertTrue(difference.isZero)
        XCTAssertFalse(difference.isNegative)

        difference = FloatType.zero.negated - FloatType.zero
        XCTAssertTrue(difference.isZero)
        XCTAssertTrue(difference.isNegative)
    }
    
    // -------------------------------------
    func test_subtracting_zero_from_a_fininte_number_results_in_that_number()
    {
        let otherValues: [FloatType] =
        [
            FloatType.leastNormalMagnitude,
            FloatType.leastNormalMagnitude.negated,
            FloatType.leastNonzeroMagnitude,
            FloatType.leastNonzeroMagnitude.negated,
            FloatType.greatestFiniteMagnitude,
            FloatType.greatestFiniteMagnitude.negated,
            FloatType(),
            FloatType().negated,
            FloatType(1),
            FloatType(1).negated
        ]
        
        for other in otherValues
        {
            var difference =  other - FloatType.zero
            XCTAssertEqual(difference, other)
            
            difference = other - FloatType.zero.negated
            XCTAssertEqual(difference, other)
        }
        
        for _ in 0..<100
        {
            let other = FloatType(randomDouble)
            var difference =  other - FloatType.zero
            XCTAssertEqual(difference, other)
            
            difference = other - FloatType.zero.negated
            XCTAssertEqual(difference, other)
        }
        
        for _ in 0..<100
        {
            let other = FloatType(urandom64)
            var difference =  other - FloatType.zero
            XCTAssertEqual(difference, other)
            
            difference = other - FloatType.zero.negated
            XCTAssertEqual(difference, other)
        }
        
        for _ in 0..<100
        {
            let other = FloatType(random64)
            var difference =  other - FloatType.zero
            XCTAssertEqual(difference, other)
            
            difference = other - FloatType.zero.negated
            XCTAssertEqual(difference, other)
        }
    }
    
    // -------------------------------------
    func test_subtracting_a_fininte_number_from_zero_results_in_the_negative_of_that_number()
    {
        let otherValues: [FloatType] =
        [
            FloatType.leastNormalMagnitude,
            FloatType.leastNormalMagnitude.negated,
            FloatType.leastNonzeroMagnitude,
            FloatType.leastNonzeroMagnitude.negated,
            FloatType.greatestFiniteMagnitude,
            FloatType.greatestFiniteMagnitude.negated,
            FloatType(),
            FloatType().negated,
            FloatType(1),
            FloatType(1).negated
        ]
        
        for other in otherValues
        {
            var difference =  FloatType.zero - other
            XCTAssertEqual(difference, -other)
            
            difference = FloatType.zero.negated - other
            XCTAssertEqual(difference, -other)
        }
        
        for _ in 0..<100
        {
            let other = FloatType(randomFloat80)
            var difference =  FloatType.zero - other
            XCTAssertEqual(difference, -other)
            
            difference = FloatType.zero.negated - other
            XCTAssertEqual(difference, -other)
        }
        
        for _ in 0..<100
        {
            let other = FloatType(randomDouble)
            var difference =  FloatType.zero - other
            XCTAssertEqual(difference, -other)
            
            difference = FloatType.zero.negated - other
            XCTAssertEqual(difference, -other)
        }

        for _ in 0..<100
        {
            let other = FloatType(urandom64)
            var difference =  FloatType.zero - other
            XCTAssertEqual(difference, -other)
            
            difference = FloatType.zero.negated - other
            XCTAssertEqual(difference, -other)
        }
        
        for _ in 0..<100
        {
            let other = FloatType(random64)
            var difference =  FloatType.zero - other
            XCTAssertEqual(difference, -other)
            
            difference = FloatType.zero.negated - other
            XCTAssertEqual(difference, -other)
        }
    }
    
    // -------------------------------------
    func test_difference_of_finite_numbers_with_same_sign()
    {
        typealias FloatType = WideFloat<UInt64>
        
        typealias TestCase = (x: Float80, y: Float80, expected: Float80)
        let testCases: [TestCase] =
        [
            (
                x:        -3519362886109200388.5,
                y:        -1404720213004215800.1,
                expected: -2114642673104984588.4
            ),
            (
                x:         -977919184040800286.3,
                y:        -1977799499079525268.5,
                expected:   999880315038724982.2
            ),
        ]
        
        for (x80, y80, expected) in testCases
        {
            let x = FloatType(x80)
            let y = FloatType(y80)
            var difference = x - y
            
            if difference.float80Value != expected
            {
                print("------- Failing case:")
                print("           x = \(x80)")
                print("           y = \(y80)")
                print("    expected = \(expected)")
                print("      actual = \(difference.float80Value)")
                print("")
                print("  expected sig: \(binary: FloatType(expected)._significand)")
                print("actual sig sig: \(binary: difference._significand)")
            }
            
            XCTAssertEqual(difference.float80Value, expected)
            
            difference = y - x
            XCTAssertEqual(difference.float80Value, -expected)

        }
        
        for _ in 0..<100
        {
            let x0 = -abs(randomFloat80)
            let y0 = -abs(randomFloat80)
            let expected = x0 - y0
            
            let x = FloatType(x0)
            let y = FloatType(y0)
            var difference = x - y
            
            if difference.float80Value != expected
            {
                print("------- Failing case:")
                print("           x = \(x0)")
                print("           y = \(y0)")
                print("    expected = \(expected)")
                print("      actual = \(difference.float80Value)")
                print("")
                print("  expected sig: \(binary: FloatType(expected)._significand)")
                print("actual sig sig: \(binary: difference._significand)")
            }
            
            XCTAssertEqual(difference.float80Value, expected)
            
            difference = y - x
            XCTAssertEqual(difference.float80Value, -expected)
        }

        for _ in 0..<100
        {
            let x0 = abs(randomDouble)
            let y0 = abs(randomDouble)
            let expected = x0 - y0
            
            let x = FloatType(x0)
            let y = FloatType(y0)
            var difference = x - y
            XCTAssertEqual(difference.doubleValue, expected)
            
            difference = y - x
            XCTAssertEqual(difference.doubleValue, -expected)
        }
        
        for _ in 0..<100
        {
            let x0 = -abs(randomDouble)
            let y0 = -abs(randomDouble)
            let expected = x0 - y0
            
            let x = FloatType(x0)
            let y = FloatType(y0)
            var difference = x - y
            XCTAssertEqual(difference.doubleValue, expected)
            
            difference = y - x
            XCTAssertEqual(difference.doubleValue, -expected)
        }
    }
    
    // -------------------------------------
    func test_difference_of_finite_numbers_with_opposite_sign()
    {
        typealias FloatType = WideFloat<UInt64>
        for _ in 0..<100
        {
            let x0 = abs(randomFloat80)
            let y0 = -abs(randomFloat80)
            let expected = x0 - y0
            
            let x = FloatType(x0)
            let y = FloatType(y0)
            var difference = x - y

            if difference.float80Value != expected
            {
                print("------- Failing case:")
                print("           x = \(x0)")
                print("           y = \(y0)")
                print("    expected = \(expected)")
                print("      actual = \(difference.float80Value)")
                print("")
                print("  expected sig: \(binary: FloatType(expected)._significand)")
                print("actual sig sig: \(binary: difference._significand)")
            }

            XCTAssertEqual(difference.float80Value, expected)
            
            difference = y - x
            XCTAssertEqual(difference.float80Value, -expected)
        }
        
        for _ in 0..<100
        {
            let x0 = abs(randomDouble)
            let y0 = -abs(randomDouble)
            let expected = x0 - y0
            
            let x = FloatType(x0)
            let y = FloatType(y0)
            var difference = x - y
            XCTAssertEqual(difference.doubleValue, expected)
            
            difference = y - x
            XCTAssertEqual(difference.doubleValue, -expected)
        }
    }
}
