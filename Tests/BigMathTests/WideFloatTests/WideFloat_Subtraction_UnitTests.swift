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
            FloatType.greatestFiniteMagnigude,
            FloatType.greatestFiniteMagnigude.negated,
            FloatType(),
            FloatType().negated,
            FloatType(1),
            FloatType(1).negated
        ]
        
        for other in otherValues
        {
            var sum = FloatType.nan - other
            XCTAssertTrue(sum.isNaN)
            XCTAssertFalse(sum.isSignalingNaN)
            
            sum = other + FloatType.nan
            XCTAssertTrue(sum.isNaN)
            XCTAssertFalse(sum.isSignalingNaN)
        }
        
        for _ in 0..<100
        {
            let other = FloatType(randomDouble)
            var sum = FloatType.nan - other
            XCTAssertTrue(sum.isNaN)
            XCTAssertFalse(sum.isSignalingNaN)
            
            sum = other + FloatType.nan
            XCTAssertTrue(sum.isNaN)
            XCTAssertFalse(sum.isSignalingNaN)
        }
        
        for _ in 0..<100
        {
            let other = FloatType(urandom64)
            var sum = FloatType.nan - other
            XCTAssertTrue(sum.isNaN)
            XCTAssertFalse(sum.isSignalingNaN)
            
            sum = other + FloatType.nan
            XCTAssertTrue(sum.isNaN)
            XCTAssertFalse(sum.isSignalingNaN)
        }
        
        for _ in 0..<100
        {
            let other = FloatType(random64)
            var sum = FloatType.nan - other
            XCTAssertTrue(sum.isNaN)
            XCTAssertFalse(sum.isSignalingNaN)
            
            sum = other + FloatType.nan
            XCTAssertTrue(sum.isNaN)
            XCTAssertFalse(sum.isSignalingNaN)
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
            FloatType.greatestFiniteMagnigude,
            FloatType.greatestFiniteMagnigude.negated,
            FloatType(),
            FloatType().negated,
            FloatType(1),
            FloatType(1).negated
        ]
        
        for other in otherValues
        {
            var sum = FloatType.signalingNaN - other
            XCTAssertTrue(sum.isNaN)
            XCTAssertFalse(sum.isSignalingNaN)
            
            sum = other + FloatType.signalingNaN
            XCTAssertTrue(sum.isNaN)
            XCTAssertFalse(sum.isSignalingNaN)
        }
        
        for _ in 0..<100
        {
            let other = FloatType(randomDouble)
            var sum = FloatType.signalingNaN - other
            XCTAssertTrue(sum.isNaN)
            XCTAssertFalse(sum.isSignalingNaN)
            
            sum = other + FloatType.signalingNaN
            XCTAssertTrue(sum.isNaN)
            XCTAssertFalse(sum.isSignalingNaN)
        }
        
        for _ in 0..<100
        {
            let other = FloatType(urandom64)
            var sum = FloatType.signalingNaN - other
            XCTAssertTrue(sum.isNaN)
            XCTAssertFalse(sum.isSignalingNaN)
            
            sum = other + FloatType.signalingNaN
            XCTAssertTrue(sum.isNaN)
            XCTAssertFalse(sum.isSignalingNaN)
        }
        
        for _ in 0..<100
        {
            let other = FloatType(random64)
            var sum = FloatType.signalingNaN - other
            XCTAssertTrue(sum.isNaN)
            XCTAssertFalse(sum.isSignalingNaN)
            
            sum = other + FloatType.signalingNaN
            XCTAssertTrue(sum.isNaN)
            XCTAssertFalse(sum.isSignalingNaN)
        }
    }
}
