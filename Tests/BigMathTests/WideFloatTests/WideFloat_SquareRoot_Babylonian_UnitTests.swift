//
//  WideFloat_SquareRoot_UnitTests.swift
//  
//
//  Created by Chip Jarred on 9/26/20.
//

import XCTest
@testable import BigMath

// -------------------------------------
class WideFloat_SquareRoot_Babylonian_UnitTests: XCTestCase
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
    func test_squareRoot_returns_nan_when_given_nan() {
        XCTAssertTrue(FloatType.nan.squareRoot_Babylonian().isNaN)
    }
    
    // -------------------------------------
    func test_squareRoot_returns_infinity_when_given_infinity() {
        XCTAssertTrue(FloatType.infinity.squareRoot_Babylonian().isInfinite)
    }
    
    // -------------------------------------
    func test_squareRoot_returns_nan_when_given_minus_infinity() {
        XCTAssertTrue((-FloatType.infinity).squareRoot_Babylonian().isNaN)
    }
    
    // -------------------------------------
    func test_squareRoot_returns_zero_when_given_zero()
    {
        XCTAssertTrue((Float80.zero).squareRoot().isZero)
        XCTAssertTrue((FloatType()).squareRoot_Babylonian().isZero)
    }
    
    // -------------------------------------
    func test_squareRoot_returns_zero_when_given_minus_zero()
    {
        XCTAssertTrue((-Float80.zero).squareRoot().sign == .minus)
        XCTAssertTrue((-FloatType()).squareRoot_Babylonian().isZero)
    }
    
    // -------------------------------------
    func test_squareRoot_of_negative_finite_numbers_is_nan()
    {
        let testCases: [FloatType] =
        [
            FloatType.one.negated,
            FloatType.leastNonzeroMagnitude.negated,
            FloatType.leastNormalMagnitude.negated,
            FloatType.greatestFiniteMagnitude.negated
        ]
        
        for x in testCases {
            XCTAssertTrue(x.squareRoot_Babylonian().isNaN)
        }
        
        for _ in 0..<100
        {
            let x = FloatType(-abs(randomFloat80))
            XCTAssertTrue(x.squareRoot_Babylonian().isNaN)
        }
    }
    
    // -------------------------------------
    func test_squareRoot_of_positive_finite_64_bit_WideFloat_matches_Float80()
    {
        for _ in 0..<100
        {
            let x80 = abs(randomFloat80)
            let x80Sqrt = x80.squareRoot()
            
            let x = FloatType(x80)
            let xSqrt = x.squareRoot_Babylonian()
            let diff = abs(x80Sqrt - xSqrt.float80Value)
            XCTAssertLessThanOrEqual(diff, x80Sqrt.ulp)
        }
    }
    
    // -------------------------------------
    func test_squareRoot_of_positive_finite_128_bit_WideFloat_can_recover_square()
    {
        typealias FloatType = WideFloat<UInt4096>
        
        for _ in 0..<100
        {
            let expMin = WExp.min.intValue / 8
            let expMax = WExp.max.intValue / 8
            
            let square = FloatType(
                significandBitPattern: UInt4096.random(in: ...),
                exponent: Int.random(in: expMin..<expMax)
            )
            
            let squareRoot = square.squareRoot_Babylonian()
            
            if square >= 1 {
                XCTAssertLessThanOrEqual(squareRoot, square)
            }
            else {
                XCTAssertGreaterThanOrEqual(squareRoot, square)
            }
            let recoveredSquare = squareRoot * squareRoot

            let diff = abs(square - recoveredSquare)
            XCTAssertLessThanOrEqual(diff, square.ulp)
        }
    }
}
