//
//  WideFloat_Addition_UnitTests.swift
//  
//
//  Created by Chip Jarred on 9/14/20.
//

import XCTest
@testable import BigMath

// -------------------------------------
class WideFloat_Addition_UnitTests: XCTestCase
{
    typealias FloatType = WideFloat<UInt64>
    
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
    func test_adding_NaN_results_in_NaN()
    {
        let otherValues: [FloatType] =
        [
            FloatType.nan, FloatType.signalingNaN,
            FloatType.infinity, FloatType.infinity.negated,
            FloatType.leastNormalMagnitude,
            FloatType.leastNormalMagnitude.negated,
            FloatType.leastNonzeroMagnitude,
            FloatType.leastNonzeroMagnitude.negated,
            FloatType.greatestFiniteMagnigude,
            FloatType.greatestFiniteMagnigude.negated,
            FloatType(),
            FloatType().negated,
            FloatType(1),
            FloatType(1).negated
        ]
        
        for other in otherValues
        {
            var sum = FloatType.nan + other
            XCTAssertTrue(sum.isNaN)
            XCTAssertFalse(sum.isSignalingNaN)
            
            sum = other + FloatType.nan
            XCTAssertTrue(sum.isNaN)
            XCTAssertFalse(sum.isSignalingNaN)
        }
        
        for _ in 0..<100
        {
            let other = FloatType(randomDouble)
            var sum = FloatType.nan + other
            XCTAssertTrue(sum.isNaN)
            XCTAssertFalse(sum.isSignalingNaN)
            
            sum = other + FloatType.nan
            XCTAssertTrue(sum.isNaN)
            XCTAssertFalse(sum.isSignalingNaN)
        }
        
        for _ in 0..<100
        {
            let other = FloatType(urandom64)
            var sum = FloatType.nan + other
            XCTAssertTrue(sum.isNaN)
            XCTAssertFalse(sum.isSignalingNaN)
            
            sum = other + FloatType.nan
            XCTAssertTrue(sum.isNaN)
            XCTAssertFalse(sum.isSignalingNaN)
        }
        
        for _ in 0..<100
        {
            let other = FloatType(random64)
            var sum = FloatType.nan + other
            XCTAssertTrue(sum.isNaN)
            XCTAssertFalse(sum.isSignalingNaN)
            
            sum = other + FloatType.nan
            XCTAssertTrue(sum.isNaN)
            XCTAssertFalse(sum.isSignalingNaN)
        }
    }
    
    // -------------------------------------
    func test_adding_sNaN_results_in_NaN()
    {
        let otherValues: [FloatType] =
        [
            FloatType.nan, FloatType.signalingNaN,
            FloatType.infinity.negated,
            FloatType.leastNormalMagnitude,
            FloatType.leastNormalMagnitude.negated,
            FloatType.leastNonzeroMagnitude,
            FloatType.leastNonzeroMagnitude.negated,
            FloatType.greatestFiniteMagnigude,
            FloatType.greatestFiniteMagnigude.negated,
            FloatType(),
            FloatType().negated,
            FloatType(1),
            FloatType(1).negated
        ]
        
        for other in otherValues
        {
            var sum = FloatType.signalingNaN + other
            XCTAssertTrue(sum.isNaN)
            XCTAssertFalse(sum.isSignalingNaN)
            
            sum = other + FloatType.signalingNaN
            XCTAssertTrue(sum.isNaN)
            XCTAssertFalse(sum.isSignalingNaN)
        }
        
        for _ in 0..<100
        {
            let other = FloatType(randomDouble)
            var sum = FloatType.signalingNaN + other
            XCTAssertTrue(sum.isNaN)
            XCTAssertFalse(sum.isSignalingNaN)
            
            sum = other + FloatType.signalingNaN
            XCTAssertTrue(sum.isNaN)
            XCTAssertFalse(sum.isSignalingNaN)
        }
        
        for _ in 0..<100
        {
            let other = FloatType(urandom64)
            var sum = FloatType.signalingNaN + other
            XCTAssertTrue(sum.isNaN)
            XCTAssertFalse(sum.isSignalingNaN)
            
            sum = other + FloatType.signalingNaN
            XCTAssertTrue(sum.isNaN)
            XCTAssertFalse(sum.isSignalingNaN)
        }
        
        for _ in 0..<100
        {
            let other = FloatType(random64)
            var sum = FloatType.signalingNaN + other
            XCTAssertTrue(sum.isNaN)
            XCTAssertFalse(sum.isSignalingNaN)
            
            sum = other + FloatType.signalingNaN
            XCTAssertTrue(sum.isNaN)
            XCTAssertFalse(sum.isSignalingNaN)
        }
    }
    
    // -------------------------------------
    func test_adding_infinity_to_infinity_of_same_sign_results_in_infinity_of_same_sign()
    {
        var sum = FloatType.infinity + FloatType.infinity
        XCTAssertTrue(sum.isInfinite)
        XCTAssertFalse(sum.isNegative)

        sum = FloatType.infinity.negated + FloatType.infinity.negated
        XCTAssertTrue(sum.isInfinite)
        XCTAssertTrue(sum.isNegative)
    }
    
    // -------------------------------------
    func test_adding_infinities_with_opposite_signs_results_in_NaN()
    {
        var sum = FloatType.infinity.negated + FloatType.infinity
        XCTAssertTrue(sum.isNaN)

        sum = FloatType.infinity.negated + FloatType.infinity.negated.negated
        XCTAssertTrue(sum.isNaN)
    }
    
    // -------------------------------------
    func test_adding_infinity_to_finite_numbers_results_in_infinity_with_same_sign_as_original_infinity()
    {
        let otherValues: [FloatType] =
        [
            FloatType.leastNormalMagnitude,
            FloatType.leastNormalMagnitude.negated,
            FloatType.leastNonzeroMagnitude,
            FloatType.leastNonzeroMagnitude.negated,
            FloatType.greatestFiniteMagnigude,
            FloatType.greatestFiniteMagnigude.negated,
            FloatType(),
            FloatType().negated,
            FloatType(1),
            FloatType(1).negated
        ]
        
        for other in otherValues
        {
            var sum = FloatType.infinity + other
            XCTAssertTrue(sum.isInfinite)
            XCTAssertFalse(sum.isNegative)
            
            sum = other + FloatType.infinity
            XCTAssertTrue(sum.isInfinite)
            XCTAssertFalse(sum.isNegative)
            
            sum = FloatType.infinity.negated + other
            XCTAssertTrue(sum.isInfinite)
            XCTAssertTrue(sum.isNegative)
            
            sum = other + FloatType.infinity.negated
            XCTAssertTrue(sum.isInfinite)
            XCTAssertTrue(sum.isNegative)
        }
        
        for _ in 0..<100
        {
            let other = FloatType(randomDouble)
            var sum = FloatType.infinity + other
            XCTAssertTrue(sum.isInfinite)
            XCTAssertFalse(sum.isNegative)
            
            sum = other + FloatType.infinity
            XCTAssertTrue(sum.isInfinite)
            XCTAssertFalse(sum.isNegative)
            
            sum = FloatType.infinity.negated + other
            XCTAssertTrue(sum.isInfinite)
            XCTAssertTrue(sum.isNegative)
            
            sum = other + FloatType.infinity.negated
            XCTAssertTrue(sum.isInfinite)
            XCTAssertTrue(sum.isNegative)
        }
        
        for _ in 0..<100
        {
            let other = FloatType(urandom64)
            var sum = FloatType.infinity + other
            XCTAssertTrue(sum.isInfinite)
            XCTAssertFalse(sum.isNegative)
            
            sum = other + FloatType.infinity
            XCTAssertTrue(sum.isInfinite)
            XCTAssertFalse(sum.isNegative)
            
            sum = FloatType.infinity.negated + other
            XCTAssertTrue(sum.isInfinite)
            XCTAssertTrue(sum.isNegative)
            
            sum = other + FloatType.infinity.negated
            XCTAssertTrue(sum.isInfinite)
            XCTAssertTrue(sum.isNegative)
        }
        
        for _ in 0..<100
        {
            let other = FloatType(random64)
            var sum = FloatType.infinity + other
            XCTAssertTrue(sum.isInfinite)
            XCTAssertFalse(sum.isNegative)
            
            sum = other + FloatType.infinity
            XCTAssertTrue(sum.isInfinite)
            XCTAssertFalse(sum.isNegative)
            
            sum = FloatType.infinity.negated + other
            XCTAssertTrue(sum.isInfinite)
            XCTAssertTrue(sum.isNegative)
            
            sum = other + FloatType.infinity.negated
            XCTAssertTrue(sum.isInfinite)
            XCTAssertTrue(sum.isNegative)
        }
    }
    
    // -------------------------------------
    func test_adding_zero_of_the_same_sign_results_in_a_zero_of_the_same_sign()
    {
        var sum = FloatType.zero + FloatType.zero
        XCTAssertTrue(sum.isZero)
        XCTAssertFalse(sum.isNegative)

        sum = FloatType.zero.negated + FloatType.zero.negated
        XCTAssertTrue(sum.isZero)
        XCTAssertTrue(sum.isNegative)
    }
    
    // -------------------------------------
    func test_adding_zero_with_opposite_signs_results_in_plus_zero()
    {
        var sum = FloatType.zero.negated + FloatType.zero
        XCTAssertTrue(sum.isZero)
        XCTAssertFalse(sum.isNegative)

        sum = FloatType.zero + FloatType.zero.negated
        XCTAssertTrue(sum.isZero)
        XCTAssertFalse(sum.isNegative)
    }
    
    // -------------------------------------
    func test_adding_zero_to_a_fininte_number_results_in_that_number()
    {
        let otherValues: [FloatType] =
        [
            FloatType.leastNormalMagnitude,
            FloatType.leastNormalMagnitude.negated,
            FloatType.leastNonzeroMagnitude,
            FloatType.leastNonzeroMagnitude.negated,
            FloatType.greatestFiniteMagnigude,
            FloatType.greatestFiniteMagnigude.negated,
            FloatType(),
            FloatType().negated,
            FloatType(1),
            FloatType(1).negated
        ]
        
        for other in otherValues
        {
            var sum = FloatType.zero + other
            XCTAssertEqual(sum, other)
            
            sum = other + FloatType.zero
            XCTAssertEqual(sum, other)

            sum = FloatType.zero.negated + other
            XCTAssertEqual(sum, other)

            sum = other + FloatType.zero.negated
            XCTAssertEqual(sum, other)
        }
        
        for _ in 0..<100
        {
            let other = FloatType(randomDouble)
            var sum = FloatType.zero + other
            XCTAssertEqual(sum, other)
            
            sum = other + FloatType.zero
            XCTAssertEqual(sum, other)

            sum = FloatType.zero.negated + other
            XCTAssertEqual(sum, other)

            sum = other + FloatType.zero.negated
            XCTAssertEqual(sum, other)
        }
        
        for _ in 0..<100
        {
            let other = FloatType(urandom64)
            var sum = FloatType.zero + other
            XCTAssertEqual(sum, other)
            
            sum = other + FloatType.zero
            XCTAssertEqual(sum, other)

            sum = FloatType.zero.negated + other
            XCTAssertEqual(sum, other)

            sum = other + FloatType.zero.negated
            XCTAssertEqual(sum, other)
        }
        
        for _ in 0..<100
        {
            let other = FloatType(random64)
            var sum = FloatType.zero + other
            XCTAssertEqual(sum, other)
            
            sum = other + FloatType.zero
            XCTAssertEqual(sum, other)

            sum = FloatType.zero.negated + other
            XCTAssertEqual(sum, other)

            sum = other + FloatType.zero.negated
            XCTAssertEqual(sum, other)
        }
    }
    
    // -------------------------------------
    func test_sum_of_finite_numbers_with_same_sign()
    {
        typealias FloatType = WideFloat<UInt64>
        typealias TestCase = (x0: Double, y0: Double)
        let testCases: [TestCase] =
        [
            (x0: 3.3438754589069757e+18, y0: 2.795557076356147e+18),
            (x0: 1.6787289753089926e+17, y0: 1.1212219972272362e+18),
            (x0: 2.2895838338253545e+18, y0: 2.9239756590262385e+18),
            (x0: 1.8092123572663117e+18, y0: 1.1119899223666446e+18),
            (x0: 8.42251154309711e+18,   y0: 5.395464610752836e+18),
        ]
        
        for (x0, y0) in testCases
        {
            let expected = x0 + y0
            
            let x = FloatType(x0)
            let y = FloatType(y0)
            
            var sum = x + y
            XCTAssertEqual(sum.doubleValue, expected)
            
            sum = y + x
            XCTAssertEqual(sum.doubleValue, expected)
        }
        
        for _ in 0..<100
        {
            let x0 = abs(randomDouble)
            let y0 = abs(randomDouble)
            let expected = x0 + y0

            let x = FloatType(x0)
            let y = FloatType(y0)
            var sum = x + y

            if sum.doubleValue != expected
            {
                print("\n -------- Failing case")
                print("    x: \(x0)")
                print("    y: \(y0)")
            }

            XCTAssertEqual(sum.doubleValue, expected)

            sum = y + x
            XCTAssertEqual(sum.doubleValue, expected)
        }
        
        for _ in 0..<100
        {
            let x0 = -abs(randomDouble)
            let y0 = -abs(randomDouble)
            let expected = x0 + y0

            let x = FloatType(x0)
            let y = FloatType(y0)
            var sum = x + y
            XCTAssertEqual(sum.doubleValue, expected)

            sum = y + x
            XCTAssertEqual(sum.doubleValue, expected)
        }
    }
    
    // -------------------------------------
    func test_sum_of_finite_numbers_with_opposite_signs()
    {
        typealias FloatType = WideFloat<UInt64>
        for _ in 0..<100
        {
            let x0 = -abs(randomDouble)
            let y0 = abs(randomDouble)
            let expected = x0 + y0
            
            let x = FloatType(x0)
            let y = FloatType(y0)
            var sum = x + y
            XCTAssertEqual(sum.doubleValue, expected)
            
            sum = y + x
            XCTAssertEqual(sum.doubleValue, expected)
        }
    }
}
