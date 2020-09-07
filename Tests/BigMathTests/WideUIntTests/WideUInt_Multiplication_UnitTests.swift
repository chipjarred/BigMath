//
//  WideUInt_Multiplication_UnitTests.swift
//  
//
//  Created by Chip Jarred on 8/18/20.
//

import XCTest
@testable import BigMath

// -------------------------------------
class WideUInt_Multiplication_UnitTests: XCTestCase
{
    typealias Digit = UInt32
    typealias IntType = WideUInt<Digit>
    
    // -------------------------------------
    /*
     Over-ridable method so that we can use share a common test set of tests for
     multiple multiplication algorithms
     */
    func multiplyFullWidth<T: WideDigit>(
        _ x: WideUInt<T>,
        by y: WideUInt<T>) -> (high: WideUInt<T>, low: WideUInt<T>)
    {
        return x.multipliedFullWidth(by: y)
    }
    
    // -------------------------------------
    func test_multipliedFullWidth_produces_0_when_given_0()
    {
        var randomDigit: Digit { return Digit.random(in: 0...Digit.max) }
        
        let x: IntType = 0
        
        for _ in 0..<100
        {
            let y = IntType(low: randomDigit, high: randomDigit)
            
            var z = multiplyFullWidth(x, by: y)
            
            XCTAssertEqual(z.low, 0)
            XCTAssertEqual(z.high, 0)
            
            z = multiplyFullWidth(y, by: x)
            
            XCTAssertEqual(z.low, 0)
            XCTAssertEqual(z.high, 0)
        }
    }
    
    // -------------------------------------
    func test_multipliedFullWidth_by_1_is_identity()
    {
        var randomDigit: Digit { return Digit.random(in: 0...Digit.max) }
        
        let x: IntType = 1
        
        for _ in 0..<100
        {
            let y = IntType(low: randomDigit, high: randomDigit)
            
            var z = multiplyFullWidth(x, by: y)
            
            XCTAssertEqual(z.low, y)
            XCTAssertEqual(z.high, 0)
            
            z = multiplyFullWidth(y, by: x)
            
            XCTAssertEqual(z.low, y)
            XCTAssertEqual(z.high, 0)
        }
    }
    
    // -------------------------------------
    func test_multipliedFullWidth_by_0_in_low_digit_and_1_in_high_digit_shifts_y_left_by_1_digit()
    {
        var randomDigit: Digit { return Digit.random(in: 0...Digit.max) }
        
        let x = IntType(low: 0, high: 1)
        
        for _ in 0..<100
        {
            let y = IntType(low: randomDigit, high: randomDigit)
            
            var z = multiplyFullWidth(x, by: y)
            
            XCTAssertEqual(z.low.low, 0)
            XCTAssertEqual(z.low.high, y.low)
            XCTAssertEqual(z.high.low, y.high)
            XCTAssertEqual(z.high.high, 0)

            z = multiplyFullWidth(y, by: x)
            
            XCTAssertEqual(z.low.low, 0)
            XCTAssertEqual(z.low.high, y.low)
            XCTAssertEqual(z.high.low, y.high)
            XCTAssertEqual(z.high.high, 0)
        }
    }
    
    // -------------------------------------
    func test_multipliedFullWidth_of_random_64_bit_WideUInts_produces_same_results_as_for_UInt64()
    {
        var random64: UInt64 { return UInt64.random(in: 0...UInt64.max) }
        
        let lowMask: UInt64 = 0x0000_0000__ffff_ffff
        
        for _ in 0..<100
        {
            let x64 = random64
            let y64 = random64
            
            let x = IntType(low: Digit(x64 & lowMask), high: Digit(x64 >> 32))
            let y = IntType(low: Digit(y64 & lowMask), high: Digit(y64 >> 32))

            let z64 = x64.multipliedFullWidth(by: y64)
            let z = multiplyFullWidth(x, by: y)
            
            XCTAssertEqual(z.low.low, Digit(z64.low & lowMask))
            XCTAssertEqual(z.low.high, Digit(z64.low >> 32))
            XCTAssertEqual(z.high.low, Digit(z64.high & lowMask))
            XCTAssertEqual(z.high.high, Digit(z64.high >> 32))
        }
    }
    
    // -------------------------------------
    func test_multipliedReportingOverflow_of_random_64_bit_WideUInts_produces_same_results_as_for_UInt64()
    {
        var random64: UInt64 { return UInt64.random(in: 0...UInt64.max) }
        
        let lowMask: UInt64 = 0x0000_0000__ffff_ffff
        
        for _ in 0..<100
        {
            let x64 = random64
            let y64 = random64
            
            let x = IntType(low: Digit(x64 & lowMask), high: Digit(x64 >> 32))
            let y = IntType(low: Digit(y64 & lowMask), high: Digit(y64 >> 32))

            let (z64, o64) = x64.multipliedReportingOverflow(by: y64)
            let (z, o) = x.multipliedReportingOverflow(by: y)
            
            XCTAssertEqual(o, o64)
            XCTAssertEqual(z.low, Digit(z64 & lowMask))
            XCTAssertEqual(z.high, Digit(z64 >> 32))
        }
        
        for _ in 0..<100
        {
            let x64 = random64 & lowMask
            let y64 = random64
            
            let x = IntType(low: Digit(x64 & lowMask), high: Digit(x64 >> 32))
            let y = IntType(low: Digit(y64 & lowMask), high: Digit(y64 >> 32))

            let (z64, o64) = x64.multipliedReportingOverflow(by: y64)
            let (z, o) = x.multipliedReportingOverflow(by: y)
            
            XCTAssertEqual(o, o64)
            XCTAssertEqual(z.low, Digit(z64 & lowMask))
            XCTAssertEqual(z.high, Digit(z64 >> 32))
        }
        
        for _ in 0..<100
        {
            let x64 = random64 & lowMask
            let y64 = random64 & lowMask
            
            let x = IntType(low: Digit(x64 & lowMask), high: Digit(x64 >> 32))
            let y = IntType(low: Digit(y64 & lowMask), high: Digit(y64 >> 32))

            let (z64, o64) = x64.multipliedReportingOverflow(by: y64)
            let (z, o) = x.multipliedReportingOverflow(by: y)
            
            XCTAssertEqual(o, o64)
            XCTAssertEqual(z.low, Digit(z64 & lowMask))
            XCTAssertEqual(z.high, Digit(z64 >> 32))
        }
        
        for _ in 0..<100
        {
            let x64 = random64 & 0xffff
            let y64 = random64 & 0xffff
            
            let x = IntType(low: Digit(x64 & lowMask), high: Digit(x64 >> 32))
            let y = IntType(low: Digit(y64 & lowMask), high: Digit(y64 >> 32))

            let (z64, o64) = x64.multipliedReportingOverflow(by: y64)
            let (z, o) = x.multipliedReportingOverflow(by: y)
            
            XCTAssertEqual(o, o64)
            XCTAssertEqual(z.low, Digit(z64 & lowMask))
            XCTAssertEqual(z.high, Digit(z64 >> 32))
        }
    }
}
