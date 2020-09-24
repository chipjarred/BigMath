//
//  WideFloat_MIsc_UnitTests.swift
//  
//
//  Created by Chip Jarred on 9/17/20.
//

import XCTest
@testable import BigMath

class WideFloat_Misc_UnitTests: XCTestCase
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
    func test_ulp()
    {
        typealias TestCase = (x: FloatType, ulp: FloatType)
        let testCases: [TestCase] =
        [
            (x: FloatType(0),            ulp: .leastNonzeroMagnitude),
            (x: FloatType(0).negated,    ulp: .leastNonzeroMagnitude),
            (x: .infinity,               ulp: .nan),
            (x: -.infinity,              ulp: .nan),
            (x: .leastNonzeroMagnitude,  ulp: 0),
            (x: -.leastNonzeroMagnitude, ulp: 0),
            (
                x: .greatestFiniteMagnitude,
                ulp: FloatType(
                    sign: .plus,
                    exponent: WExp.max.intValue - 63,
                    significand: 1
                )
            ),
            (
                x: -.greatestFiniteMagnitude,
                ulp: FloatType(
                    sign: .plus,
                    exponent: WExp.max.intValue - 63,
                    significand: 1
                )
            ),
            (
                x: 1,
                ulp: FloatType(
                    sign: .plus,
                    exponent: -(UInt64.bitWidth - 2),
                    significand: 1
                )
            ),
            (
                x: FloatType(
                    sign: .plus,
                    exponent: -UInt64.bitWidth,
                    significand: 1
                ),
                ulp: FloatType(
                    sign: .plus,
                    exponent: -UInt64.bitWidth - (UInt64.bitWidth - 2),
                    significand: 1
                )
            )
        ]
        
        let x = FloatType(1.01)
        XCTAssertNotEqual(x - x.ulp, x)
        
        for (x, expected) in testCases
        {
            let ulpX = x.ulp
            
            if expected.isNaN
            {
                XCTAssertTrue(ulpX.isNaN)
                continue
            }
            
            if expected.isInfinite
            {
                XCTAssertTrue(ulpX.isInfinite)
                XCTAssertEqual(ulpX.sign, expected.sign)
                continue
            }
            
            if ulpX != expected
            {
                print("  actual ulp.exponent = \(ulpX.exponent)")
                print("expected ulp.exponent = \(expected.exponent)")
                print("   actual ulp.signBit = \(ulpX._exponent.sigSignBit)")
                print(" expected ulp.signBit = \(expected._exponent.sigSignBit)")
                print("       actual ulp.sig = \(binary: ulpX._significand)")
                print("     expected ulp.sig = \(binary: expected._significand)")
            }
            
            XCTAssertEqual(ulpX, expected)
        }
    }
    
    
    // -------------------------------------
    func test_nextUp()
    {
        typealias TestCase = (x: FloatType, nextUp: FloatType)
        let testCases: [TestCase] =
        [
            (x: FloatType(0),            nextUp: .leastNonzeroMagnitude),
            (x: FloatType(0).negated,    nextUp: .leastNonzeroMagnitude),
            (
                x: -FloatType.leastNonzeroMagnitude,
                nextUp: FloatType(0).negated
            ),
            (x: .infinity,               nextUp: .infinity),
            (x: -.infinity,              nextUp: -.greatestFiniteMagnitude),
            (x: .greatestFiniteMagnitude,nextUp: .infinity),
            (
                x: 1,
                nextUp: 1 + FloatType(1).ulp
            ),
        ]
        
        for (x, expected) in testCases
        {
            let xNextUp = x.nextUp
            
            if expected.isNaN
            {
                XCTAssertTrue(xNextUp.isNaN)
                continue
            }
            
            if expected.isInfinite
            {
                XCTAssertTrue(xNextUp.isInfinite)
                XCTAssertEqual(xNextUp.sign, expected.sign)
                continue
            }
            
            if expected.isZero
            {
                XCTAssertTrue(xNextUp.isZero)
                XCTAssertEqual(xNextUp.sign, expected.sign)
                continue
            }
            
            XCTAssertEqual(xNextUp, expected)
        }
    }
}
