//
//  WideFloat_Multiplication_UnitTests.swift.swift
//  
//
//  Created by Chip Jarred on 9/16/20.
//

import XCTest
@testable import BigMath

// -------------------------------------
class WideFloat_Multiplication_UnitTests: XCTestCase
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
    func test_multiplying_NaN_results_in_NaN()
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
            var product = FloatType.nan * other
            XCTAssertTrue(product.isNaN)
            XCTAssertFalse(product.isSignalingNaN)
            
            product = other * FloatType.nan
            XCTAssertTrue(product.isNaN)
            XCTAssertFalse(product.isSignalingNaN)
        }
        
        for _ in 0..<100
        {
            let other = FloatType(randomDouble)
            var product = FloatType.nan * other
            XCTAssertTrue(product.isNaN)
            XCTAssertFalse(product.isSignalingNaN)
            
            product = other * FloatType.nan
            XCTAssertTrue(product.isNaN)
            XCTAssertFalse(product.isSignalingNaN)
        }
        
        for _ in 0..<100
        {
            let other = FloatType(urandom64)
            var product = FloatType.nan * other
            XCTAssertTrue(product.isNaN)
            XCTAssertFalse(product.isSignalingNaN)
            
            product = other * FloatType.nan
            XCTAssertTrue(product.isNaN)
            XCTAssertFalse(product.isSignalingNaN)
        }
        
        for _ in 0..<100
        {
            let other = FloatType(random64)
            var product = FloatType.nan * other
            XCTAssertTrue(product.isNaN)
            XCTAssertFalse(product.isSignalingNaN)
            
            product = other * FloatType.nan
            XCTAssertTrue(product.isNaN)
            XCTAssertFalse(product.isSignalingNaN)
        }
    }
    
    // -------------------------------------
    func test_multiplying_sNaN_results_in_NaN()
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
            var product = FloatType.signalingNaN * other
            XCTAssertTrue(product.isNaN)
            XCTAssertFalse(product.isSignalingNaN)
            
            product = other * FloatType.signalingNaN
            XCTAssertTrue(product.isNaN)
            XCTAssertFalse(product.isSignalingNaN)
        }
        
        for _ in 0..<100
        {
            let other = FloatType(randomDouble)
            var product = FloatType.signalingNaN * other
            XCTAssertTrue(product.isNaN)
            XCTAssertFalse(product.isSignalingNaN)
            
            product = other * FloatType.signalingNaN
            XCTAssertTrue(product.isNaN)
            XCTAssertFalse(product.isSignalingNaN)
        }
        
        for _ in 0..<100
        {
            let other = FloatType(urandom64)
            var product = FloatType.signalingNaN * other
            XCTAssertTrue(product.isNaN)
            XCTAssertFalse(product.isSignalingNaN)
            
            product = other * FloatType.signalingNaN
            XCTAssertTrue(product.isNaN)
            XCTAssertFalse(product.isSignalingNaN)
        }
        
        for _ in 0..<100
        {
            let other = FloatType(random64)
            var product = FloatType.signalingNaN * other
            XCTAssertTrue(product.isNaN)
            XCTAssertFalse(product.isSignalingNaN)
            
            product = other * FloatType.signalingNaN
            XCTAssertTrue(product.isNaN)
            XCTAssertFalse(product.isSignalingNaN)
        }
    }
    
    // -------------------------------------
    func test_multipling_infinity_with_infinity_of_same_sign_results_in_plus_infinity()
    {
        var product = FloatType.infinity * FloatType.infinity
        XCTAssertTrue(product.isInfinite)
        XCTAssertFalse(product.isNegative)

        product = FloatType.infinity.negated * FloatType.infinity.negated
        XCTAssertTrue(product.isInfinite)
        XCTAssertFalse(product.isNegative)
    }
    
    // -------------------------------------
    func test_multiplying_infinities_with_opposite_signs_results_in_minus_infinity()
    {
        var product = FloatType.infinity.negated * FloatType.infinity
        XCTAssertTrue(product.isInfinite)
        XCTAssertTrue(product.isNegative)

        product = FloatType.infinity.negated * FloatType.infinity.negated.negated
        XCTAssertTrue(product.isInfinite)
        XCTAssertTrue(product.isNegative)
    }
    
    // -------------------------------------
    func test_multiplying_infinity_by_zero_results_in_NaN()
    {
        let zero = FloatType.zero
        let infinity = FloatType.infinity
        
        var product = infinity * zero
        XCTAssertTrue(product.isNaN)
        
        product = zero * infinity
        XCTAssertTrue(product.isNaN)
        
        product = infinity.negated * zero
        XCTAssertTrue(product.isNaN)
        
        product = zero * infinity.negated
        XCTAssertTrue(product.isNaN)
        
        product = infinity * zero.negated
        XCTAssertTrue(product.isNaN)
        
        product = zero.negated * infinity
        XCTAssertTrue(product.isNaN)
        
        product = infinity.negated * zero.negated
        XCTAssertTrue(product.isNaN)
        
        product = zero.negated * infinity.negated
        XCTAssertTrue(product.isNaN)
    }
    
    // -------------------------------------
    func test_multiplying_infinity_with_non_zero_finite_numbers_with_same_sign_results_in_plus_infinity()
    {
        let otherValues: [FloatType] =
        [
            FloatType.leastNormalMagnitude,
            FloatType.leastNonzeroMagnitude,
            FloatType.greatestFiniteMagnitude,
            FloatType(1),
        ]
        
        for other in otherValues
        {
            var product = FloatType.infinity * other
            XCTAssertTrue(product.isInfinite)
            XCTAssertFalse(product.isNegative)
            
            product = other * FloatType.infinity
            XCTAssertTrue(product.isInfinite)
            XCTAssertFalse(product.isNegative)

            product = FloatType.infinity.negated * other.negated
            XCTAssertTrue(product.isInfinite)
            XCTAssertFalse(product.isNegative)

            product = other.negated * FloatType.infinity.negated
            XCTAssertTrue(product.isInfinite)
            XCTAssertFalse(product.isNegative)
        }
        
        for _ in 0..<100
        {
            let other = FloatType(abs(randomDouble))
            var product = FloatType.infinity * other
            XCTAssertTrue(product.isInfinite)
            XCTAssertFalse(product.isNegative)
            
            product = other * FloatType.infinity
            XCTAssertTrue(product.isInfinite)
            XCTAssertFalse(product.isNegative)

            product = FloatType.infinity.negated * other.negated
            XCTAssertTrue(product.isInfinite)
            XCTAssertFalse(product.isNegative)

            product = other.negated * FloatType.infinity.negated
            XCTAssertTrue(product.isInfinite)
            XCTAssertFalse(product.isNegative)
        }

        for _ in 0..<100
        {
            let other = FloatType(urandom64)
            var product = FloatType.infinity * other
            XCTAssertTrue(product.isInfinite)
            XCTAssertFalse(product.isNegative)
            
            product = other * FloatType.infinity
            XCTAssertTrue(product.isInfinite)
            XCTAssertFalse(product.isNegative)

            product = FloatType.infinity.negated * other.negated
            XCTAssertTrue(product.isInfinite)
            XCTAssertFalse(product.isNegative)

            product = other.negated * FloatType.infinity.negated
            XCTAssertTrue(product.isInfinite)
            XCTAssertFalse(product.isNegative)
        }

        for _ in 0..<100
        {
            let other = FloatType(abs(random64))
            var product = FloatType.infinity * other
            XCTAssertTrue(product.isInfinite)
            XCTAssertFalse(product.isNegative)
            
            product = other * FloatType.infinity
            XCTAssertTrue(product.isInfinite)
            XCTAssertFalse(product.isNegative)

            product = FloatType.infinity.negated * other.negated
            XCTAssertTrue(product.isInfinite)
            XCTAssertFalse(product.isNegative)

            product = other.negated * FloatType.infinity.negated
            XCTAssertTrue(product.isInfinite)
            XCTAssertFalse(product.isNegative)
        }
    }
    
    // -------------------------------------
    func test_multiplying_infinity_with_non_zero_finite_numbers_with_opposite_sign_results_in_minus_infinity()
    {
        let otherValues: [FloatType] =
        [
            FloatType.leastNormalMagnitude,
            FloatType.leastNonzeroMagnitude,
            FloatType.greatestFiniteMagnitude,
            FloatType(1),
        ]
        
        for other in otherValues
        {
            var product = FloatType.infinity * other.negated
            XCTAssertTrue(product.isInfinite)
            XCTAssertTrue(product.isNegative)
            
            product = other.negated * FloatType.infinity
            XCTAssertTrue(product.isInfinite)
            XCTAssertTrue(product.isNegative)

            product = FloatType.infinity.negated * other
            XCTAssertTrue(product.isInfinite)
            XCTAssertTrue(product.isNegative)

            product = other * FloatType.infinity.negated
            XCTAssertTrue(product.isInfinite)
            XCTAssertTrue(product.isNegative)
        }
        
        for _ in 0..<100
        {
            let other = FloatType(abs(randomDouble))
            var product = FloatType.infinity * other.negated
            XCTAssertTrue(product.isInfinite)
            XCTAssertTrue(product.isNegative)
            
            product = other.negated * FloatType.infinity
            XCTAssertTrue(product.isInfinite)
            XCTAssertTrue(product.isNegative)

            product = FloatType.infinity.negated * other
            XCTAssertTrue(product.isInfinite)
            XCTAssertTrue(product.isNegative)

            product = other * FloatType.infinity.negated
            XCTAssertTrue(product.isInfinite)
            XCTAssertTrue(product.isNegative)
        }

        for _ in 0..<100
        {
            let other = FloatType(urandom64)
            var product = FloatType.infinity * other.negated
            XCTAssertTrue(product.isInfinite)
            XCTAssertTrue(product.isNegative)
            
            product = other.negated * FloatType.infinity
            XCTAssertTrue(product.isInfinite)
            XCTAssertTrue(product.isNegative)

            product = FloatType.infinity.negated * other
            XCTAssertTrue(product.isInfinite)
            XCTAssertTrue(product.isNegative)

            product = other * FloatType.infinity.negated
            XCTAssertTrue(product.isInfinite)
            XCTAssertTrue(product.isNegative)
        }

        for _ in 0..<100
        {
            let other = FloatType(abs(random64))
            var product = FloatType.infinity * other.negated
            XCTAssertTrue(product.isInfinite)
            XCTAssertTrue(product.isNegative)
            
            product = other.negated * FloatType.infinity
            XCTAssertTrue(product.isInfinite)
            XCTAssertTrue(product.isNegative)

            product = FloatType.infinity.negated * other
            XCTAssertTrue(product.isInfinite)
            XCTAssertTrue(product.isNegative)

            product = other * FloatType.infinity.negated
            XCTAssertTrue(product.isInfinite)
            XCTAssertTrue(product.isNegative)
        }
    }
    
    // -------------------------------------
    func test_multiplying_zero_by_a_finite_number_of_same_sign_results_in_plus_zero()
    {
        let otherValues: [FloatType] =
        [
            FloatType.leastNormalMagnitude,
            FloatType.leastNonzeroMagnitude,
            FloatType.greatestFiniteMagnitude,
            FloatType(),
            FloatType(1),
        ]
        
        for other in otherValues
        {
            var product = FloatType.zero * other
            XCTAssertTrue(product.isZero)
            XCTAssertFalse(product.isNegative)
            
            product = other * FloatType.zero
            XCTAssertTrue(product.isZero)
            XCTAssertFalse(product.isNegative)

            product = FloatType.zero.negated * other.negated
            XCTAssertTrue(product.isZero)
            XCTAssertFalse(product.isNegative)

            product = other.negated * FloatType.zero.negated
            XCTAssertTrue(product.isZero)
            XCTAssertFalse(product.isNegative)
        }
        
        for _ in 0..<100
        {
            let other = FloatType(abs(randomDouble))
            var product = FloatType.zero * other
            XCTAssertTrue(product.isZero)
            XCTAssertFalse(product.isNegative)
            
            product = other * FloatType.zero
            XCTAssertTrue(product.isZero)
            XCTAssertFalse(product.isNegative)

            product = FloatType.zero.negated * other.negated
            XCTAssertTrue(product.isZero)
            XCTAssertFalse(product.isNegative)

            product = other.negated * FloatType.zero.negated
            XCTAssertTrue(product.isZero)
            XCTAssertFalse(product.isNegative)
        }

        for _ in 0..<100
        {
            let other = FloatType(urandom64)
            var product = FloatType.zero * other
            XCTAssertTrue(product.isZero)
            XCTAssertFalse(product.isNegative)
            
            product = other * FloatType.zero
            XCTAssertTrue(product.isZero)
            XCTAssertFalse(product.isNegative)

            product = FloatType.zero.negated * other.negated
            XCTAssertTrue(product.isZero)
            XCTAssertFalse(product.isNegative)

            product = other.negated * FloatType.zero.negated
            XCTAssertTrue(product.isZero)
            XCTAssertFalse(product.isNegative)
        }

        for _ in 0..<100
        {
            let other = FloatType(abs(random64))
            var product = FloatType.zero * other
            XCTAssertTrue(product.isZero)
            XCTAssertFalse(product.isNegative)
            
            product = other * FloatType.zero
            XCTAssertTrue(product.isZero)
            XCTAssertFalse(product.isNegative)

            product = FloatType.zero.negated * other.negated
            XCTAssertTrue(product.isZero)
            XCTAssertFalse(product.isNegative)

            product = other.negated * FloatType.zero.negated
            XCTAssertTrue(product.isZero)
            XCTAssertFalse(product.isNegative)
        }
    }
    
    // -------------------------------------
    func test_multiplying_zero_by_a_finite_number_of_opposite_sign_results_in_minus_zero()
    {
        let otherValues: [FloatType] =
        [
            FloatType.leastNormalMagnitude,
            FloatType.leastNonzeroMagnitude,
            FloatType.greatestFiniteMagnitude,
            FloatType(),
            FloatType(1),
        ]
        
        for other in otherValues
        {
            var product = FloatType.zero * other.negated
            XCTAssertTrue(product.isZero)
            XCTAssertTrue(product.isNegative)
            
            product = other.negated * FloatType.zero
            XCTAssertTrue(product.isZero)
            XCTAssertTrue(product.isNegative)

            product = FloatType.zero.negated * other
            XCTAssertTrue(product.isZero)
            XCTAssertTrue(product.isNegative)

            product = other * FloatType.zero.negated
            XCTAssertTrue(product.isZero)
            XCTAssertTrue(product.isNegative)
        }
        
        for _ in 0..<100
        {
            let other = FloatType(abs(randomDouble))
            var product = FloatType.zero * other.negated
            XCTAssertTrue(product.isZero)
            XCTAssertTrue(product.isNegative)
            
            product = other.negated * FloatType.zero
            XCTAssertTrue(product.isZero)
            XCTAssertTrue(product.isNegative)

            product = FloatType.zero.negated * other
            XCTAssertTrue(product.isZero)
            XCTAssertTrue(product.isNegative)

            product = other * FloatType.zero.negated
            XCTAssertTrue(product.isZero)
            XCTAssertTrue(product.isNegative)
        }

        for _ in 0..<100
        {
            let other = FloatType(urandom64)
            var product = FloatType.zero * other.negated
            XCTAssertTrue(product.isZero)
            XCTAssertTrue(product.isNegative)
            
            product = other.negated * FloatType.zero
            XCTAssertTrue(product.isZero)
            XCTAssertTrue(product.isNegative)

            product = FloatType.zero.negated * other
            XCTAssertTrue(product.isZero)
            XCTAssertTrue(product.isNegative)

            product = other * FloatType.zero.negated
            XCTAssertTrue(product.isZero)
            XCTAssertTrue(product.isNegative)
        }

        for _ in 0..<100
        {
            let other = FloatType(abs(random64))
            var product = FloatType.zero * other.negated
            XCTAssertTrue(product.isZero)
            XCTAssertTrue(product.isNegative)
            
            product = other.negated * FloatType.zero
            XCTAssertTrue(product.isZero)
            XCTAssertTrue(product.isNegative)

            product = FloatType.zero.negated * other
            XCTAssertTrue(product.isZero)
            XCTAssertTrue(product.isNegative)

            product = other * FloatType.zero.negated
            XCTAssertTrue(product.isZero)
            XCTAssertTrue(product.isNegative)
        }
    }
    
    // -------------------------------------
    func test_multiplying_one_by_a_number_results_in_that_number()
    {
        let otherValues: [FloatType] =
        [
            FloatType.leastNormalMagnitude,
            FloatType.leastNonzeroMagnitude,
            FloatType.greatestFiniteMagnitude,
            FloatType(),
            FloatType(1),
        ]
        
        for other in otherValues
        {
            var product = FloatType(1) * other
            XCTAssertEqual(product, other)
            
            product = other * FloatType(1)
            XCTAssertEqual(product, other)

            product = FloatType(1) * other.negated
            XCTAssertEqual(product, other.negated)

            product = other.negated * FloatType(1)
            XCTAssertEqual(product, other.negated)
        }
        
        for _ in 0..<100
        {
            let other = FloatType(abs(randomDouble))
            var product = FloatType(1) * other
            XCTAssertEqual(product, other)
            
            product = other * FloatType(1)
            XCTAssertEqual(product, other)

            product = FloatType(1) * other.negated
            XCTAssertEqual(product, other.negated)

            product = other.negated * FloatType(1)
            XCTAssertEqual(product, other.negated)
        }

        for _ in 0..<100
        {
            let other = FloatType(urandom64)
            var product = FloatType(1) * other
            XCTAssertEqual(product, other)
            
            product = other * FloatType(1)
            XCTAssertEqual(product, other)

            product = FloatType(1) * other.negated
            XCTAssertEqual(product, other.negated)

            product = other.negated * FloatType(1)
            XCTAssertEqual(product, other.negated)
        }

        for _ in 0..<100
        {
            let other = FloatType(abs(random64))
            var product = FloatType(1) * other
            XCTAssertEqual(product, other)
            
            product = other * FloatType(1)
            XCTAssertEqual(product, other)

            product = FloatType(1) * other.negated
            XCTAssertEqual(product, other.negated)

            product = other.negated * FloatType(1)
            XCTAssertEqual(product, other.negated)
        }
    }
    
    // -------------------------------------
    func test_multiplying_negative_one_by_a_number_results_in_the_negative_of_that_number()
    {
        let otherValues: [FloatType] =
        [
            FloatType.leastNormalMagnitude,
            FloatType.leastNonzeroMagnitude,
            FloatType.greatestFiniteMagnitude,
            FloatType(),
            FloatType(1),
        ]
        
        for other in otherValues
        {
            var product = FloatType(1).negated * other
            XCTAssertEqual(product, other.negated)
            
            product = other * FloatType(1).negated
            XCTAssertEqual(product, other.negated)

            product = FloatType(1).negated * other.negated
            XCTAssertEqual(product, other)

            product = other.negated * FloatType(1).negated
            XCTAssertEqual(product, other)
        }
        
        for _ in 0..<100
        {
            let other = FloatType(abs(randomDouble))
            var product = FloatType(1).negated * other
            XCTAssertEqual(product, other.negated)
            
            product = other * FloatType(1).negated
            XCTAssertEqual(product, other.negated)

            product = FloatType(1).negated * other.negated
            XCTAssertEqual(product, other)

            product = other.negated * FloatType(1).negated
            XCTAssertEqual(product, other)
        }

        for _ in 0..<100
        {
            let other = FloatType(urandom64)
            var product = FloatType(1).negated * other
            XCTAssertEqual(product, other.negated)
            
            product = other * FloatType(1).negated
            XCTAssertEqual(product, other.negated)

            product = FloatType(1).negated * other.negated
            XCTAssertEqual(product, other)

            product = other.negated * FloatType(1).negated
            XCTAssertEqual(product, other)
        }

        for _ in 0..<100
        {
            let other = FloatType(abs(random64))
            var product = FloatType(1).negated * other
            XCTAssertEqual(product, other.negated)
            
            product = other * FloatType(1).negated
            XCTAssertEqual(product, other.negated)

            product = FloatType(1).negated * other.negated
            XCTAssertEqual(product, other)

            product = other.negated * FloatType(1).negated
            XCTAssertEqual(product, other)
        }
    }
    
    // -------------------------------------
    func test_multiplying_leastNormalMagnitude_by_itself_underflows_to_zero()
    {
        let x = FloatType.leastNormalMagnitude
        var product = x * x
        XCTAssertTrue(product.isZero)
        XCTAssertFalse(product.isNegative)
        
        product = x.negated * x.negated
        XCTAssertTrue(product.isZero)
        XCTAssertFalse(product.isNegative)
        
        product = x * x.negated
        XCTAssertTrue(product.isZero)
        XCTAssertTrue(product.isNegative)
        
        product = x.negated * x
        XCTAssertTrue(product.isZero)
        XCTAssertTrue(product.isNegative)
    }
    
    // -------------------------------------
    func test_multiplying_greatestFiniteMagnigude_by_itself_overflows_to_infinity()
    {
        let x = FloatType.greatestFiniteMagnitude
        var product = x * x
        XCTAssertTrue(product.isInfinite)
        XCTAssertFalse(product.isNegative)
        
        product = x.negated * x.negated
        XCTAssertTrue(product.isInfinite)
        XCTAssertFalse(product.isNegative)
        
        product = x * x.negated
        XCTAssertTrue(product.isInfinite)
        XCTAssertTrue(product.isNegative)
        
        product = x.negated * x
        XCTAssertTrue(product.isInfinite)
        XCTAssertTrue(product.isNegative)
        
        product = FloatType(1.01) * x
        XCTAssertTrue(product.isInfinite)
        XCTAssertFalse(product.isNegative)
    }
    
    // -------------------------------------
    func test_product_of_finite_numbers_with_same_sign()
    {
        typealias FloatType = WideFloat<UInt64>
        for _ in 0..<1000
        {
            let x0 = abs(randomDouble)
            let y0 = abs(randomDouble)
            let expected = x0 * y0
            
            // We allow a tolerance because WideFloat has more precision than
            // Double
            let tolerance = Double(
                sign: .plus,
                exponent: expected.exponent - 52,
                significand: 1)
            
            let x = FloatType(x0)
            let y = FloatType(y0)
            var product = x * y
            XCTAssertLessThanOrEqual(
                abs(product.doubleValue - expected), tolerance
            )
            
            product = y * x
            XCTAssertLessThanOrEqual(
                abs(product.doubleValue - expected), tolerance
            )
        }
        
        for _ in 0..<1000
        {
            let x0 = -abs(randomDouble)
            let y0 = -abs(randomDouble)
            let expected = x0 * y0
            
            // We allow a tolerance because WideFloat has more precision than
            // Double
            let tolerance = Double(
                sign: .plus,
                exponent: expected.exponent - 52,
                significand: 1)
            
            let x = FloatType(x0)
            let y = FloatType(y0)
            var product = x * y
            XCTAssertLessThanOrEqual(
                abs(product.doubleValue - expected), tolerance
            )
            
            product = y * x
            XCTAssertLessThanOrEqual(
                abs(product.doubleValue - expected), tolerance
            )
        }
    }
    
    // -------------------------------------
    func test_product_of_finite_numbers_with_opposite_signs()
    {
        typealias FloatType = WideFloat<UInt64>
        for _ in 0..<1000
        {
            let x0 = abs(randomDouble)
            let y0 = -abs(randomDouble)
            let expected = x0 * y0
            
            // We allow a tolerance because WideFloat has more precision than
            // Double
            let tolerance = Double(
                sign: .plus,
                exponent: expected.exponent - 52,
                significand: 1)
            
            let x = FloatType(x0)
            let y = FloatType(y0)
            var product = x * y
            XCTAssertLessThanOrEqual(
                abs(product.doubleValue - expected), tolerance
            )
            
            product = y * x
            XCTAssertLessThanOrEqual(
                abs(product.doubleValue - expected), tolerance
            )
        }
    }
    
    // -------------------------------------
    func test_some_specific_troublesome_cases()
    {
        typealias TestCase = (
            xSig: UInt64, xExp: Int,
            ySig: UInt64, yExp: Int,
            zSig: UInt64, zExp: Int
        )
        let testCases: [TestCase] =
        [
            (
                xSig: 5729532217080934400,   xExp: 60,
                ySig: 7423868869837347414,   yExp: -61,
                zSig: 0x4000_0000_0000_0000, zExp: 0
            )
        ]
        
        for (xSig, xExp, ySig, yExp, zSig, zExp) in testCases
        {
            let x = FloatType(significandBitPattern: xSig, exponent: xExp)
            let y = FloatType(significandBitPattern: ySig, exponent: yExp)
            let expected =
                FloatType(significandBitPattern: zSig, exponent: zExp)
            
            let z = x * y
            XCTAssertEqual(z, expected)
        }
    }
}
