//
//  WideUInt_BitwiseOperators.swift
//  
//
//  Created by Chip Jarred on 8/18/20.
//

import XCTest
@testable import BigMath

// -------------------------------------
class WideUInt_BitwiseOperators: XCTestCase
{
    typealias Digit = UInt32
    typealias IntType = WideUInt<Digit>
    let lowMask = UInt64(UInt32.max)
    
    var random64: UInt64 { return UInt64.random(in: 0...UInt64.max) }
    var randomShift: Int { return Int.random(in: 0...(3 * Digit.bitWidth)) }
    
    // MARK:- Bitshift tests
    // -------------------------------------
    func test_WideUInt_assign_right_shift_gives_same_result_as_UInt64_right_shift()
    {
        // -------------------------------------
        for _ in 0...100
        {
            let shift = randomShift
            let x64 = random64
            let z64 = x64 >> shift
            
            var x = IntType(x64)
            x >>= shift
            
            XCTAssertEqual(x.low, Digit(z64 & lowMask))
            XCTAssertEqual(x.high, Digit(z64 >> 32))
        }
    }
    
    // -------------------------------------
    func test_WideUInt_right_shift_gives_same_result_as_UInt64_right_shift()
    {
        // -------------------------------------
        for _ in 0...100
        {
            let shift = randomShift
            let x64 = random64
            let z64 = x64 >> shift
            
            let x = IntType(x64)
            let z = x >> shift
            
            XCTAssertEqual(z.low, Digit(z64 & lowMask))
            XCTAssertEqual(z.high, Digit(z64 >> 32))
        }
    }
    
    // -------------------------------------
    func test_WideUInt_assign_left_shift_gives_same_result_as_UInt64_left_shift()
    {
        // -------------------------------------
        for _ in 0...100
        {
            let shift = randomShift
            let x64 = random64
            let z64 = x64 << shift
            
            var x = IntType(x64)
            x <<= shift
            
            XCTAssertEqual(x.low, Digit(z64 & lowMask))
            XCTAssertEqual(x.high, Digit(z64 >> 32))
        }
    }
    
    // -------------------------------------
    func test_WideUInt_left_shift_gives_same_result_as_UInt64_left_shift()
    {
        // -------------------------------------
        for _ in 0...100
        {
            let shift = randomShift
            let x64 = random64
            let z64 = x64 << shift
            
            let x = IntType(x64)
            let z = x << shift
            
            XCTAssertEqual(z.low, Digit(z64 & lowMask))
            XCTAssertEqual(z.high, Digit(z64 >> 32))
        }
    }
    
    // -------------------------------------
    func test_WideUInt_assign_AND_gives_same_result_as_UInt64_AND()
    {
        // -------------------------------------
        for _ in 0...100
        {
            let x64 = random64
            let y64 = random64
            let z64 = x64 & y64
            
            var x = IntType(x64)
            let y = IntType(y64)
            x &= y
            
            XCTAssertEqual(x.low, Digit(z64 & lowMask))
            XCTAssertEqual(x.high, Digit(z64 >> 32))
        }
    }
    
    // -------------------------------------
    func test_WideUInt_AND_gives_same_result_as_UInt64_AND()
    {
        // -------------------------------------
        for _ in 0...100
        {
            let x64 = random64
            let y64 = random64
            let z64 = x64 & y64
            
            let x = IntType(x64)
            let y = IntType(y64)
            let z = x & y
            
            XCTAssertEqual(z.low, Digit(z64 & lowMask))
            XCTAssertEqual(z.high, Digit(z64 >> 32))
        }
    }
    
    // -------------------------------------
    func test_WideUInt_assign_OR_gives_same_result_as_UInt64_OR()
    {
        // -------------------------------------
        for _ in 0...100
        {
            let x64 = random64
            let y64 = random64
            let z64 = x64 | y64
            
            var x = IntType(x64)
            let y = IntType(y64)
            x |= y
            
            XCTAssertEqual(x.low, Digit(z64 & lowMask))
            XCTAssertEqual(x.high, Digit(z64 >> 32))
        }
    }
    
    // -------------------------------------
    func test_WideUInt_OR_gives_same_result_as_UInt64_OR()
    {
        // -------------------------------------
        for _ in 0...100
        {
            let x64 = random64
            let y64 = random64
            let z64 = x64 | y64
            
            let x = IntType(x64)
            let y = IntType(y64)
            let z = x | y
            
            XCTAssertEqual(z.low, Digit(z64 & lowMask))
            XCTAssertEqual(z.high, Digit(z64 >> 32))
        }
    }
    
    // -------------------------------------
    func test_WideUInt_assign_XOR_gives_same_result_as_UInt64_XOR()
    {
        // -------------------------------------
        for _ in 0...100
        {
            let x64 = random64
            let y64 = random64
            let z64 = x64 ^ y64
            
            var x = IntType(x64)
            let y = IntType(y64)
            x ^= y
            
            XCTAssertEqual(x.low, Digit(z64 & lowMask))
            XCTAssertEqual(x.high, Digit(z64 >> 32))
        }
    }
    
    // -------------------------------------
    func test_WideUInt_XOR_gives_same_result_as_UInt64_XOR()
    {
        // -------------------------------------
        for _ in 0...100
        {
            let x64 = random64
            let y64 = random64
            let z64 = x64 ^ y64
            
            let x = IntType(x64)
            let y = IntType(y64)
            let z = x ^ y
            
            XCTAssertEqual(z.low, Digit(z64 & lowMask))
            XCTAssertEqual(z.high, Digit(z64 >> 32))
        }
    }
    
    // -------------------------------------
    func test_WideUInt_bitwise_complement_gives_same_result_as_UInt64_bitwise_complement()
    {
        // -------------------------------------
        for _ in 0...100
        {
            let x64 = random64
            let z64 = ~x64
            
            let x = IntType(x64)
            let z = ~x
            
            XCTAssertEqual(z.low, Digit(z64 & lowMask))
            XCTAssertEqual(z.high, Digit(z64 >> 32))
        }
    }
    
    // -------------------------------------
    func test_WideUInt_twos_complement_gives_same_result_as_UInt64_twos_complement()
    {
        // -------------------------------------
        for _ in 0...100
        {
            let x64 = random64
            let z64 = UInt64(bitPattern: -Int64(bitPattern: x64))
            
            let x = IntType(x64)
            let z = x.negated
            
            XCTAssertEqual(z.low, Digit(z64 & lowMask))
            XCTAssertEqual(z.high, Digit(z64 >> 32))
        }
    }
    
    // -------------------------------------
    func test_WideUInt_self_modifying_twos_complement_gives_same_result_as_UInt64_twos_complement()
    {
        // -------------------------------------
        for _ in 0...100
        {
            let x64 = random64
            let z64 = UInt64(bitPattern: -Int64(bitPattern: x64))
            
            let x = IntType(x64)
            var z = x
            z.negate()
            
            XCTAssertEqual(z.low, Digit(z64 & lowMask))
            XCTAssertEqual(z.high, Digit(z64 >> 32))
        }
    }
}
