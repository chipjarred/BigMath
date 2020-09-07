//
//  WideUInt_Addition_UnitTests.swift
//  
//
//  Created by Chip Jarred on 8/17/20.
//

import XCTest
@testable import BigMath

// -------------------------------------
class WideUInt_Addition_UnitTests: XCTestCase
{
    typealias Digit = UInt32
    typealias IntType = WideUInt<Digit>
    
    // -------------------------------------
    func test_adding_0_to_x_produces_x()
    {
        var randomDigit: Digit { return Digit.random(in: 0...Digit.max) }
        
        for _ in 0..<100
        {
            let x = IntType(low: randomDigit, high: randomDigit)
            let y: IntType = 0
            
            var z = x + y
            
            XCTAssertEqual(z, x)
            
            z = y + x
            
            XCTAssertEqual(z, x)
        }
    }
    
    // -------------------------------------
    func test_adding_two_64_bit_WideUInts_produces_the_same_result_as_adding_the_equivalent_UInt64s()
    {
        var random64: UInt64 { return UInt64.random(in: 0...UInt64.max/2) }
        
        let lowMask: UInt64 = 0x0000_0000__ffff_ffff
        
        for _ in 0..<100
        {
            let x64 = random64
            let y64 = random64
            
            let x = IntType(low: Digit(x64 & lowMask), high: Digit(x64 >> 32))
            let y = IntType(low: Digit(y64 & lowMask), high: Digit(y64 >> 32))

            let z64 = x64 + y64
            var z = x + y
            
            XCTAssertEqual(z.low,  Digit(z64 & lowMask))
            XCTAssertEqual(z.high, Digit(z64 >> 32))

            z = y + x
            
            XCTAssertEqual(z.low,  Digit(z64 & lowMask))
            XCTAssertEqual(z.high, Digit(z64 >> 32))
        }
    }
    
    // -------------------------------------
    func test_overflowing_addition_of_0_to_x_produces_x()
    {
        var randomDigit: Digit { return Digit.random(in: 0...Digit.max) }
        
        for _ in 0..<100
        {
            let x = IntType(low: randomDigit, high: randomDigit)
            let y: IntType = 0
            
            var z = x &+ y
            
            XCTAssertEqual(z, x)
            
            z = y &+ x
            
            XCTAssertEqual(z, x)
        }
    }
    
    // -------------------------------------
    func test_overflowing_addition_of_two_64_bit_WideUInts_produces_the_same_result_as_adding_the_equivalent_UInt64s()
    {
        var random64: UInt64 { return UInt64.random(in: 0...UInt64.max) }
        
        let lowMask: UInt64 = 0x0000_0000__ffff_ffff
        
        for _ in 0..<100
        {
            let x64 = random64
            let y64 = random64
            
            let x = IntType(low: Digit(x64 & lowMask), high: Digit(x64 >> 32))
            let y = IntType(low: Digit(y64 & lowMask), high: Digit(y64 >> 32))

            let z64 = x64 &+ y64
            var z = x &+ y
            
            XCTAssertEqual(z.low,  Digit(z64 & lowMask))
            XCTAssertEqual(z.high, Digit(z64 >> 32))

            z = y &+ x
            
            XCTAssertEqual(z.low,  Digit(z64 & lowMask))
            XCTAssertEqual(z.high, Digit(z64 >> 32))
        }
    }
    
    // -------------------------------------
    func test_assignment_overflowing_addition_of_two_64_bit_WideUInts_produces_the_same_result_as_adding_the_equivalent_UInt64s()
    {
        var random64: UInt64 { return UInt64.random(in: 0...UInt64.max) }
        
        let lowMask: UInt64 = 0x0000_0000__ffff_ffff
        
        for _ in 0..<100
        {
            let x64 = random64
            let y64 = random64
            
            let x = IntType(low: Digit(x64 & lowMask), high: Digit(x64 >> 32))
            let y = IntType(low: Digit(y64 & lowMask), high: Digit(y64 >> 32))

            let z64 = x64 &+ y64
            var z = x
            z &+= y
            
            XCTAssertEqual(z.low,  Digit(z64 & lowMask))
            XCTAssertEqual(z.high, Digit(z64 >> 32))

            z = y
            z &+= x
            
            XCTAssertEqual(z.low,  Digit(z64 & lowMask))
            XCTAssertEqual(z.high, Digit(z64 >> 32))
        }
    }
}
