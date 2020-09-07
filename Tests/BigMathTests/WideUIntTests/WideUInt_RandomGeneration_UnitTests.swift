//
//  WideUInt_RandomGeneration_UnitTests.swift
//
//
//  Created by Chip Jarred on 8/17/20.
//

import XCTest
@testable import BigMath

// -------------------------------------
class WideUInt_RandomGeneration_UnitTests: XCTestCase
{
    typealias Digit = UInt32
    typealias IntType = WideUInt<Digit>
    
    // -------------------------------------
    func test_genrating_random_number_over_closed_range_does_not_generate_a_number_outside_of_that_range()
    {
        for _ in 0..<100
        {
            let lower = IntType(low: 5)
            let upper = IntType(low: 10)
            let x = IntType.random(in: lower...upper)
            XCTAssertGreaterThanOrEqual(x, lower)
            XCTAssertLessThanOrEqual(x, upper)
        }
        
        for _ in 0..<100
        {
            let lower = IntType(low: 5)
            let upper = IntType(high: 10)
            let x = IntType.random(in: lower...upper)
            XCTAssertGreaterThanOrEqual(x, lower)
            XCTAssertLessThanOrEqual(x, upper)
        }
        
        for _ in 0..<100
        {
            let lower = IntType(high: 5)
            let upper = IntType(high: 10)
            let x = IntType.random(in: lower...upper)
            XCTAssertGreaterThanOrEqual(x, lower)
            XCTAssertLessThanOrEqual(x, upper)
        }

        for _ in 0..<100
        {
            let upper = IntType.random(in: 1...)
            let lower = IntType.random(in: ...upper)
            let x = IntType.random(in: lower...upper)
            XCTAssertGreaterThanOrEqual(x, lower)
            XCTAssertLessThanOrEqual(x, upper)
        }
    }
    
    // -------------------------------------
    func test_genrating_random_number_over_range_does_not_generate_a_number_outside_of_that_range()
    {
        for _ in 0..<100
        {
            let lower = IntType(low: 5)
            let upper = IntType(low: 10)
            let x = IntType.random(in: lower..<upper)
            XCTAssertGreaterThanOrEqual(x, lower)
            XCTAssertLessThan(x, upper)
        }
        
        for _ in 0..<100
        {
            let lower = IntType(low: 5)
            let upper = IntType(high: 10)
            let x = IntType.random(in: lower..<upper)
            XCTAssertGreaterThanOrEqual(x, lower)
            XCTAssertLessThan(x, upper)
        }
        
        for _ in 0..<100
        {
            let lower = IntType(high: 5)
            let upper = IntType(high: 10)
            let x = IntType.random(in: lower..<upper)
            XCTAssertGreaterThanOrEqual(x, lower)
            XCTAssertLessThan(x, upper)
        }

        for _ in 0..<100
        {
            let upper = IntType.random(in: 2...)
            let lower = IntType.random(in: ...upper)
            let x = IntType.random(in: lower..<upper)
            XCTAssertGreaterThanOrEqual(x, lower)
            XCTAssertLessThan(x, upper)
        }
    }
}
