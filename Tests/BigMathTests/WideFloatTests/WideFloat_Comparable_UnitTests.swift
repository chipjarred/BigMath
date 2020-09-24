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
            FloatType.greatestFiniteMagnitude,
            FloatType.greatestFiniteMagnitude.negated,
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
            FloatType.greatestFiniteMagnitude,
            FloatType.greatestFiniteMagnitude.negated,
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
            FloatType.greatestFiniteMagnitude,
            FloatType.greatestFiniteMagnitude.negated,
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
            FloatType.greatestFiniteMagnitude,
            FloatType.greatestFiniteMagnitude.negated,
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
    
    // -------------------------------------
    func test_finite_WideFloat_values_test_with_same_comparable_results_as_the_Double_values_they_are_created_from()
    {
        typealias TestCase = (x: Double, y: Double)
        let testCases =
        [
            (x: -6.632804489126267e+18, y: 186509121110083e+17),
            (x: 4.02757294920914e+18, y: 5.056763693166687e+18),
            (x: 3.850933609328316e+17, y: 4.83893331713415e+18),
        ]
        
        for (x, y) in testCases
        {
            let wX = FloatType(x)
            let wY = FloatType(y)
            
            if x < y && !(wX < wY)
            {
                print("\n-------- Failing case")
                print("    x: \(x)")
                print("    y: \(y)")
                print("   wX: \(binary: wX._significand)")
                print("   wY: \(binary: wY._significand)")
                print(" \(wX < wY)")
            }
            
            XCTAssertEqual(x < y, wX < wY)
            XCTAssertEqual(x <= y, wX <= wY)
            XCTAssertEqual(x == y, wX == wY)
            XCTAssertEqual(x != y, wX != wY)
            XCTAssertEqual(x >= y, wX >= wY)
            XCTAssertEqual(x > y, wX > wY)
        }
        
        for (x0, y0) in testCases
        {
            let x = 1 / x0
            let y = 1 / y0
            let wX = FloatType(x)
            let wY = FloatType(y)
            
            if x < y && !(wX < wY)
            {
                print("\n-------- Failing case")
                print("    x: \(x)")
                print("    y: \(y)")
            }
            
            XCTAssertEqual(x < y, wX < wY)
            XCTAssertEqual(x <= y, wX <= wY)
            XCTAssertEqual(x == y, wX == wY)
            XCTAssertEqual(x != y, wX != wY)
            XCTAssertEqual(x >= y, wX >= wY)
            XCTAssertEqual(x > y, wX > wY)
        }

        for _ in 0..<100
        {
            let x = randomDouble
            let y = randomDouble
            
            let wX = FloatType(x)
            let wY = FloatType(y)
            
            if x < y && !(wX < wY)
            {
                print("\n-------- Failing case")
                print("    x: \(x)")
                print("    y: \(y)")
            }
            
            XCTAssertEqual(x < y, wX < wY)
            XCTAssertEqual(x <= y, wX <= wY)
            XCTAssertEqual(x == y, wX == wY)
            XCTAssertEqual(x != y, wX != wY)
            XCTAssertEqual(x >= y, wX >= wY)
            XCTAssertEqual(x > y, wX > wY)
        }

        for _ in 0..<100
        {
            let x = 1 / randomDouble
            let y = 1 / randomDouble
            
            let wX = FloatType(x)
            let wY = FloatType(y)
            
            if x < y && !(wX < wY)
            {
                print("\n-------- Failing case")
                print("    x: \(x)")
                print("    y: \(y)")
            }
            
            XCTAssertEqual(x < y, wX < wY)
            XCTAssertEqual(x <= y, wX <= wY)
            XCTAssertEqual(x == y, wX == wY)
            XCTAssertEqual(x != y, wX != wY)
            XCTAssertEqual(x >= y, wX >= wY)
            XCTAssertEqual(x > y, wX > wY)
        }
    }
    
    // -------------------------------------
    func test_finite_WideFloat_values_test_with_same_comparable_results_as_the_UInt64_values_they_are_created_from()
    {
        typealias TestCase = (x: UInt64, y: UInt64)
        let testCases: [TestCase] = [ ]
        
        for (x, y) in testCases
        {
            let wX = FloatType(x)
            let wY = FloatType(y)
            
            if x < y && !(wX < wY)
            {
                print("\n-------- Failing case")
                print("    x: \(x)")
                print("    y: \(y)")
            }
            
            XCTAssertEqual(x < y, wX < wY)
            XCTAssertEqual(x <= y, wX <= wY)
            XCTAssertEqual(x == y, wX == wY)
            XCTAssertEqual(x != y, wX != wY)
            XCTAssertEqual(x >= y, wX >= wY)
            XCTAssertEqual(x > y, wX > wY)
        }
        
        for _ in 0..<100
        {
            let x = urandom64
            let y = urandom64
            
            let wX = FloatType(x)
            let wY = FloatType(y)
            
            if x < y && !(wX < wY)
            {
                print("\n-------- Failing case")
                print("    x: \(x)")
                print("    y: \(y)")
            }
            
            XCTAssertEqual(x < y, wX < wY)
            XCTAssertEqual(x <= y, wX <= wY)
            XCTAssertEqual(x == y, wX == wY)
            XCTAssertEqual(x != y, wX != wY)
            XCTAssertEqual(x >= y, wX >= wY)
            XCTAssertEqual(x > y, wX > wY)
        }
    }
    
    // -------------------------------------
    func test_finite_WideFloat_values_test_with_same_comparable_results_as_the_Int64_values_they_are_created_from()
    {
        typealias TestCase = (x: Int64, y: Int64)
        let testCases: [TestCase] = [ ]
        
        for (x, y) in testCases
        {
            let wX = FloatType(x)
            let wY = FloatType(y)
            
            if x < y && !(wX < wY)
            {
                print("\n-------- Failing case")
                print("    x: \(x)")
                print("    y: \(y)")
            }
            
            XCTAssertEqual(x < y, wX < wY)
            XCTAssertEqual(x <= y, wX <= wY)
            XCTAssertEqual(x == y, wX == wY)
            XCTAssertEqual(x != y, wX != wY)
            XCTAssertEqual(x >= y, wX >= wY)
            XCTAssertEqual(x > y, wX > wY)
        }
        
        for _ in 0..<100
        {
            let x = random64
            let y = random64
            
            let wX = FloatType(x)
            let wY = FloatType(y)
            
            if x < y && !(wX < wY)
            {
                print("\n-------- Failing case")
                print("    x: \(x)")
                print("    y: \(y)")
            }
            
            XCTAssertEqual(x < y, wX < wY)
            XCTAssertEqual(x <= y, wX <= wY)
            XCTAssertEqual(x == y, wX == wY)
            XCTAssertEqual(x != y, wX != wY)
            XCTAssertEqual(x >= y, wX >= wY)
            XCTAssertEqual(x > y, wX > wY)
        }
    }
}
