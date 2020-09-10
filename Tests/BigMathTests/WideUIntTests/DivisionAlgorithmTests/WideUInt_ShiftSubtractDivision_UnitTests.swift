//
//  WideUInt_ShiftSubtractDivision_UnitTests.swift
//
//
//  Created by Chip Jarred on 8/19/20.
//

import XCTest
@testable import BigMath

// -------------------------------------
class WideUInt_ShiftSubtractDivision_UnitTests: XCTestCase
{
    typealias Digit = UInt64
    typealias IntType = WideUInt<Digit>
    
    var random64: UInt64 { UInt64.random(in: 0...UInt64.max) }
    let lowMask = UInt64(Digit.max)
    
    // -------------------------------------
    func test_fullWidthDividing_by_1_gives_dividend()
    {
        for _ in 0..<100
        {
            let x = IntType(low: random64, high: random64)
            let y: IntType = 1
            
            let z = y.dividingFullWidth_ShiftSubtract((high: 0, low: x))
            
            XCTAssertEqual(z.quotient, x)
            XCTAssertEqual(z.remainder, 0)
        }
    }

    // -------------------------------------
    func test_fullWidthDividing_gives_same_results_as_UInt64()
    {
        typealias IntType = WideUInt<UInt32>
        for _ in 0..<100
        {
            let q64 = random64
            let y64 = random64
            let r64 = UInt64.random(in: 0..<y64)
            var x64 = q64.multipliedFullWidth(by: y64)
            let carry = x64.low.addToSelfReportingCarry(r64)
            x64.high &+= carry
            
            let x = (high: IntType(x64.high), low: IntType(x64.low))
            let y = IntType(y64)

            let (q, r) = y.dividingFullWidth_ShiftSubtract(x)
            
            let (_q64, _r64) = y64.dividingFullWidth(x64)
            
            XCTAssertEqual(q64, _q64)
            XCTAssertEqual(r64, _r64)
            
            XCTAssertEqual(q, IntType(_q64))
            XCTAssertEqual(r, IntType(_r64))
        }
    }
    
    // -------------------------------------
    func test_fullWidthDividing_gives_same_results_as_KnuthD()
    {
        typealias IntType = WideUInt<UInt64>
        for _ in 0..<100
        {
            let x = (
                high: IntType.random(in: ...),
                low: IntType.random(in: ...)
            )
            let y = IntType.random(in: ...)
            if x.high == 0 && x.low < y { continue }

            let (q, r) = y.dividingFullWidth_ShiftSubtract(x)
            let (q2, r2) = y.dividingFullWidth_KnuthD(x)

            XCTAssertEqual(q, q2)
            XCTAssertEqual(r, r2)
        }
    }
}
