//
//  WideFloat_Comparable_UnitTests.swift
//  
//
//  Created by Chip Jarred on 9/14/20.
//

import XCTest
@testable import BigMath

class WideFloat_Comparable_UnitTests: XCTestCase
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
    
    var random64: Int64 { Int64.random(in: Int64.min...Int64.max) }
    var urandom64: UInt64 { UInt64.random(in: UInt64.min...UInt64.max) }

    // -------------------------------------
    func test_nan_compares_false_with_everything()
    {
        var negInfinity = FloatType.infinity
        negInfinity.negate()
        
        let otherValues: [FloatType] =
        [
            FloatType.nan, FloatType.signalingNaN,
            FloatType.infinity, FloatType.infinity.negated,
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
            XCTAssertFalse(FloatType.nan == other)
            XCTAssertFalse(FloatType.nan != other)
            XCTAssertFalse(FloatType.nan > other)
            XCTAssertFalse(FloatType.nan >= other)
            XCTAssertFalse(FloatType.nan < other)
            XCTAssertFalse(FloatType.nan <= other)
        }
        
        for _ in 0..<100
        {
            let other = FloatType(randomDouble)
            
            XCTAssertFalse(FloatType.nan == other)
            XCTAssertFalse(FloatType.nan != other)
            XCTAssertFalse(FloatType.nan > other)
            XCTAssertFalse(FloatType.nan >= other)
            XCTAssertFalse(FloatType.nan < other)
            XCTAssertFalse(FloatType.nan <= other)
        }
        
        for _ in 0..<100
        {
            let other = FloatType(urandom64)
            
            XCTAssertFalse(FloatType.nan == other)
            XCTAssertFalse(FloatType.nan != other)
            XCTAssertFalse(FloatType.nan > other)
            XCTAssertFalse(FloatType.nan >= other)
            XCTAssertFalse(FloatType.nan < other)
            XCTAssertFalse(FloatType.nan <= other)
        }
        
        for _ in 0..<100
        {
            let other = FloatType(random64)
            
            XCTAssertFalse(FloatType.nan == other)
            XCTAssertFalse(FloatType.nan != other)
            XCTAssertFalse(FloatType.nan > other)
            XCTAssertFalse(FloatType.nan >= other)
            XCTAssertFalse(FloatType.nan < other)
            XCTAssertFalse(FloatType.nan <= other)
        }
    }
    
    // -------------------------------------
    func test_signalingNaN_compares_false_with_everything()
    {
        let otherValues: [FloatType] =
        [
            FloatType.nan, FloatType.signalingNaN,
            FloatType.infinity, FloatType.infinity.negated,
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
            XCTAssertFalse(FloatType.signalingNaN == other)
            XCTAssertFalse(FloatType.signalingNaN != other)
            XCTAssertFalse(FloatType.signalingNaN > other)
            XCTAssertFalse(FloatType.signalingNaN >= other)
            XCTAssertFalse(FloatType.signalingNaN < other)
            XCTAssertFalse(FloatType.signalingNaN <= other)
        }
        
        for _ in 0..<100
        {
            let other = FloatType(randomDouble)
            
            XCTAssertFalse(FloatType.signalingNaN == other)
            XCTAssertFalse(FloatType.signalingNaN != other)
            XCTAssertFalse(FloatType.signalingNaN > other)
            XCTAssertFalse(FloatType.signalingNaN >= other)
            XCTAssertFalse(FloatType.signalingNaN < other)
            XCTAssertFalse(FloatType.signalingNaN <= other)
        }
        
        for _ in 0..<100
        {
            let other = FloatType(urandom64)
            
            XCTAssertFalse(FloatType.signalingNaN == other)
            XCTAssertFalse(FloatType.signalingNaN != other)
            XCTAssertFalse(FloatType.signalingNaN > other)
            XCTAssertFalse(FloatType.signalingNaN >= other)
            XCTAssertFalse(FloatType.signalingNaN < other)
            XCTAssertFalse(FloatType.signalingNaN <= other)
        }
        
        for _ in 0..<100
        {
            let other = FloatType(random64)
            
            XCTAssertFalse(FloatType.signalingNaN == other)
            XCTAssertFalse(FloatType.signalingNaN != other)
            XCTAssertFalse(FloatType.signalingNaN > other)
            XCTAssertFalse(FloatType.signalingNaN >= other)
            XCTAssertFalse(FloatType.signalingNaN < other)
            XCTAssertFalse(FloatType.signalingNaN <= other)
        }
    }
    
    // -------------------------------------
    func test_infinity_is_equal_to_infinity()
    {
        XCTAssertEqual(FloatType.infinity, FloatType.infinity)
        XCTAssertEqual(FloatType.infinity.negated, FloatType.infinity.negated)
    }
    
    // -------------------------------------
    func test_infinity_is_greater_than_any_other_nonNaN_value()
    {
        let otherValues: [FloatType] =
        [
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

        for other in otherValues {
            XCTAssertGreaterThan(FloatType.infinity, other)
        }
        
        for _ in 0..<100
        {
            let other = FloatType(randomDouble)
            
            XCTAssertGreaterThan(FloatType.infinity, other)
        }
        
        for _ in 0..<100
        {
            let other = FloatType(urandom64)
            
            XCTAssertGreaterThan(FloatType.infinity, other)
        }
        
        for _ in 0..<100
        {
            let other = FloatType(random64)
            
            XCTAssertGreaterThan(FloatType.infinity, other)
        }
    }
    
    // -------------------------------------
    func test_negative_infinity_is_less_than_any_other_nonNaN_value()
    {
        let otherValues: [FloatType] =
        [
            FloatType.infinity,
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

        for other in otherValues {
            XCTAssertLessThan(FloatType.infinity.negated, other)
        }
        
        for _ in 0..<100
        {
            let other = FloatType(randomDouble)
            
            XCTAssertLessThan(FloatType.infinity.negated, other)
        }
        
        for _ in 0..<100
        {
            let other = FloatType(urandom64)
            
            XCTAssertLessThan(FloatType.infinity.negated, other)
        }
        
        for _ in 0..<100
        {
            let other = FloatType(random64)
            
            XCTAssertLessThan(FloatType.infinity.negated, other)
        }
    }
    
    
    // -------------------------------------
    func test_minus0_and_plus0_compare_as_equal()
    {
        /*
         IEEE 754, which we mostly follow, says that +0 == -0 for comparison
         purposes.
         */
        XCTAssertEqual(FloatType(), FloatType())
        XCTAssertEqual(FloatType().negated, FloatType().negated)
        XCTAssertEqual(FloatType(), FloatType().negated)
        XCTAssertEqual(FloatType().negated, FloatType())
    }
}
