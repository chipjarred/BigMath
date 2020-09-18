//
//  WideFloat_Division_UnitTests.swift
//  
//
//  Created by Chip Jarred on 9/17/20.
//

import XCTest
@testable import BigMath

// -------------------------------------
class WideFloat_Division_UnitTests: XCTestCase
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
    func test_dividing_NaN_results_in_NaN()
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
            var product = FloatType.nan / other
            XCTAssertTrue(product.isNaN)
            XCTAssertFalse(product.isSignalingNaN)
            
            product = other / FloatType.nan
            XCTAssertTrue(product.isNaN)
            XCTAssertFalse(product.isSignalingNaN)
        }
        
        for _ in 0..<100
        {
            let other = FloatType(randomDouble)
            var product = FloatType.nan / other
            XCTAssertTrue(product.isNaN)
            XCTAssertFalse(product.isSignalingNaN)
            
            product = other / FloatType.nan
            XCTAssertTrue(product.isNaN)
            XCTAssertFalse(product.isSignalingNaN)
        }
        
        for _ in 0..<100
        {
            let other = FloatType(urandom64)
            var product = FloatType.nan / other
            XCTAssertTrue(product.isNaN)
            XCTAssertFalse(product.isSignalingNaN)
            
            product = other / FloatType.nan
            XCTAssertTrue(product.isNaN)
            XCTAssertFalse(product.isSignalingNaN)
        }
        
        for _ in 0..<100
        {
            let other = FloatType(random64)
            var product = FloatType.nan / other
            XCTAssertTrue(product.isNaN)
            XCTAssertFalse(product.isSignalingNaN)
            
            product = other / FloatType.nan
            XCTAssertTrue(product.isNaN)
            XCTAssertFalse(product.isSignalingNaN)
        }
    }
    
    // -------------------------------------
    func test_dividing_sNaN_results_in_NaN()
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
            var product = FloatType.signalingNaN / other
            XCTAssertTrue(product.isNaN)
            XCTAssertFalse(product.isSignalingNaN)
            
            product = other / FloatType.signalingNaN
            XCTAssertTrue(product.isNaN)
            XCTAssertFalse(product.isSignalingNaN)
        }
        
        for _ in 0..<100
        {
            let other = FloatType(randomDouble)
            var product = FloatType.signalingNaN / other
            XCTAssertTrue(product.isNaN)
            XCTAssertFalse(product.isSignalingNaN)
            
            product = other / FloatType.signalingNaN
            XCTAssertTrue(product.isNaN)
            XCTAssertFalse(product.isSignalingNaN)
        }
        
        for _ in 0..<100
        {
            let other = FloatType(urandom64)
            var product = FloatType.signalingNaN / other
            XCTAssertTrue(product.isNaN)
            XCTAssertFalse(product.isSignalingNaN)
            
            product = other / FloatType.signalingNaN
            XCTAssertTrue(product.isNaN)
            XCTAssertFalse(product.isSignalingNaN)
        }
        
        for _ in 0..<100
        {
            let other = FloatType(random64)
            var product = FloatType.signalingNaN / other
            XCTAssertTrue(product.isNaN)
            XCTAssertFalse(product.isSignalingNaN)
            
            product = other / FloatType.signalingNaN
            XCTAssertTrue(product.isNaN)
            XCTAssertFalse(product.isSignalingNaN)
        }
    }
    
    // -------------------------------------
    func test_dividing_infinity_by_infinity_is_NaN()
    {
        var quotient = FloatType.infinity / FloatType.infinity
        XCTAssertTrue(quotient.isNaN)
        
        quotient = FloatType.infinity / -FloatType.infinity
        XCTAssertTrue(quotient.isNaN)
        
        quotient = -FloatType.infinity / FloatType.infinity
        XCTAssertTrue(quotient.isNaN)
        
        quotient = -FloatType.infinity / -FloatType.infinity
        XCTAssertTrue(quotient.isNaN)
    }
    
    // -------------------------------------
    func test_dividing_finite_number_by_infinity_is_zero()
    {
        let testCases: [FloatType] =
        [
            .greatestFiniteMagnitude,
            -.greatestFiniteMagnitude,
            .leastNonzeroMagnitude,
            -.leastNonzeroMagnitude,
            .leastNonzeroMagnitude,
            -.leastNonzeroMagnitude,
        ]
        
        for x in testCases
        {
            var quotient = x / FloatType.infinity
            
            XCTAssertTrue(quotient.isZero)
            XCTAssertEqual(quotient.sign, x.sign)
            
            quotient = x / FloatType.infinity.negated
            
            XCTAssertTrue(quotient.isZero)
            XCTAssertNotEqual(quotient.sign, x.sign)
        }
        
        for _ in 0..<100
        {
            let x = FloatType(randomDouble)
            var quotient = x / FloatType.infinity
            
            XCTAssertTrue(quotient.isZero)
            XCTAssertEqual(quotient.sign, x.sign)
            
            quotient = x / FloatType.infinity.negated
            
            XCTAssertTrue(quotient.isZero)
            XCTAssertNotEqual(quotient.sign, x.sign)
        }
    }

    
    // -------------------------------------
    func test_dividing_zero_by_zero_is_NaN()
    {
        var quotient = FloatType.zero / FloatType.zero
        XCTAssertTrue(quotient.isNaN)
        
        quotient = FloatType.zero / -FloatType.zero
        XCTAssertTrue(quotient.isNaN)
        
        quotient = -FloatType.zero / FloatType.zero
        XCTAssertTrue(quotient.isNaN)
        
        quotient = -FloatType.zero / -FloatType.zero
        XCTAssertTrue(quotient.isNaN)
    }
    
    // -------------------------------------
    func test_dividing_zero_by_infinity_is_zero()
    {
        var quotient = FloatType.zero / FloatType.infinity
        XCTAssertTrue(quotient.isZero)
        XCTAssertFalse(quotient.isNegative)
        
        quotient = FloatType.zero / -FloatType.infinity
        XCTAssertTrue(quotient.isZero)
        XCTAssertTrue(quotient.isNegative)

        quotient = -FloatType.zero / FloatType.infinity
        XCTAssertTrue(quotient.isZero)
        XCTAssertTrue(quotient.isNegative)

        quotient = -FloatType.zero / -FloatType.infinity
        XCTAssertTrue(quotient.isZero)
        XCTAssertFalse(quotient.isNegative)
    }
    
    // -------------------------------------
    func test_dividing_zero_by_finite_number_is_zero()
    {
        let testCases: [FloatType] =
        [
            .greatestFiniteMagnitude,
            -.greatestFiniteMagnitude,
            .leastNonzeroMagnitude,
            -.leastNonzeroMagnitude,
            .leastNonzeroMagnitude,
            -.leastNonzeroMagnitude,
        ]
        
        for x in testCases
        {
            var quotient = FloatType.zero / x
            
            XCTAssertTrue(quotient.isZero)
            XCTAssertEqual(quotient.sign, x.sign)
            
            quotient = FloatType.zero.negated / x
            
            XCTAssertTrue(quotient.isZero)
            XCTAssertNotEqual(quotient.sign, x.sign)
        }
        
        for _ in 0..<100
        {
            let x = FloatType(randomDouble)
            var quotient = FloatType.zero / x
            
            XCTAssertTrue(quotient.isZero)
            XCTAssertEqual(quotient.sign, x.sign)
            
            quotient = FloatType.zero.negated / x
            
            XCTAssertTrue(quotient.isZero)
            XCTAssertNotEqual(quotient.sign, x.sign)
        }
    }
    
    // -------------------------------------
    func test_dividing_infinity_by_zero_is_infinity()
    {
        var quotient = FloatType.infinity / FloatType.zero
        XCTAssertTrue(quotient.isInfinite)
        XCTAssertFalse(quotient.isNegative)
        
        quotient = FloatType.infinity / -FloatType.zero
        XCTAssertTrue(quotient.isInfinite)
        XCTAssertTrue(quotient.isNegative)

        quotient = -FloatType.infinity / FloatType.zero
        XCTAssertTrue(quotient.isInfinite)
        XCTAssertTrue(quotient.isNegative)

        quotient = -FloatType.infinity / -FloatType.zero
        XCTAssertTrue(quotient.isInfinite)
        XCTAssertFalse(quotient.isNegative)
    }
    
    // -------------------------------------
    func test_dividing_finite_number_by_zero_is_infinity()
    {
        let testCases: [FloatType] =
        [
            .greatestFiniteMagnitude,
            -.greatestFiniteMagnitude,
            .leastNonzeroMagnitude,
            -.leastNonzeroMagnitude,
            .leastNonzeroMagnitude,
            -.leastNonzeroMagnitude,
        ]
        
        for x in testCases
        {
            var quotient = x / FloatType.zero
            
            XCTAssertTrue(quotient.isInfinite)
            XCTAssertEqual(quotient.sign, x.sign)
            
            quotient = x / FloatType.zero.negated
            
            XCTAssertTrue(quotient.isInfinite)
            XCTAssertNotEqual(quotient.sign, x.sign)
        }
        
        for _ in 0..<100
        {
            let x = FloatType(randomDouble)
            var quotient = x / FloatType.zero
            
            XCTAssertTrue(quotient.isInfinite)
            XCTAssertEqual(quotient.sign, x.sign)
            
            quotient = x / FloatType.zero.negated
            
            XCTAssertTrue(quotient.isInfinite)
            XCTAssertNotEqual(quotient.sign, x.sign)
        }
    }
    
    // -------------------------------------
    func test_dividing_finite_number_by_one_is_that_number()
    {
        let testCases: [FloatType] =
        [
            .greatestFiniteMagnitude,
            -.greatestFiniteMagnitude,
            .leastNonzeroMagnitude,
            -.leastNonzeroMagnitude,
            .leastNonzeroMagnitude,
            -.leastNonzeroMagnitude,
        ]
        
        for x in testCases
        {
            var quotient = x / 1
            
            XCTAssertEqual(quotient, x)
            
            quotient = x / -1
            
            XCTAssertEqual(quotient, -x)
        }
        
        for _ in 0..<100
        {
            let x = FloatType(randomDouble)
            var quotient = x / 1
            
            XCTAssertEqual(quotient, x)
            
            quotient = x / -1
            
            XCTAssertEqual(quotient, -x)
        }
    }
}
