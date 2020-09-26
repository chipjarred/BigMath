//
//  WideFloat_Initialization_UnitTests.swift
//  
//
//  Created by Chip Jarred on 9/11/20.
//

import XCTest
@testable import BigMath

// -------------------------------------
class WideFloat_Initialization_UnitTests: XCTestCase
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
    var randomDouble: Double
    {
        let bigLimit = Double(UInt64.max) / 2
        let bigRange = -bigLimit...bigLimit
        let littleRange = Double.leastNormalMagnitude...1
        let x = Double.random(in: bigRange)
        return  x * Double.random(in: littleRange)
    }
    
    // -------------------------------------
    var randomDecimal: Decimal
    {
        let bigLimit = Decimal(UInt64.max) / 2
        let bigRange = -bigLimit...bigLimit
        let littleRange = Decimal.leastNormalMagnitude...1
        var x = Decimal.random(in: bigRange)
        let f = Decimal.random(in: littleRange)
        x *= f
        return x
    }
    
    // -------------------------------------
    var urandom64: UInt64 { return UInt64.random(in: 0...UInt64.max) }
    
    // -------------------------------------
    var random64: Int64 { return Int64.random(in: Int64.min...Int64.max) }

    // -------------------------------------
    func test_WideFloat_isNaN_returns_true_for_WideFloat_nan()
    {
        let n = FloatType.nan
        XCTAssertTrue(n.isNaN)
    }
    
    // -------------------------------------
    func test_WideFloat_isNaN_returns_true_for_WideFloat_signalingNaN()
    {
        let n = FloatType.signalingNaN
        XCTAssertTrue(n.isNaN)
    }
    
    // -------------------------------------
    func test_WideFloat_isNaN_returns_false_for_WideFloat_infinity()
    {
        var n = FloatType.infinity
        XCTAssertFalse(n.isNaN)
        
        n.negate()
        XCTAssertFalse(n.isNaN)
    }

    // -------------------------------------
    func test_WideFloat_isNaN_returns_false_for_finiteValued_WideFloats()
    {
        for _ in 0..<100
        {
            let x = FloatType(randomDouble)
            XCTAssertFalse(x.isNaN)
        }
    }
    
    // -------------------------------------
    func test_WideFloat_isSignalingNaN_returns_false_for_WideFloat_nan()
    {
        let n = FloatType.nan
        XCTAssertFalse(n.isSignalingNaN)
    }
    
    // -------------------------------------
    func test_WideFloat_isSignalingNaN_returns_true_for_WideFloat_signalingNaN()
    {
        let n = FloatType.signalingNaN
        XCTAssertTrue(n.isSignalingNaN)
    }
    
    // -------------------------------------
    func test_WideFloat_isSignalingNaN_returns_false_for_WideFloat_infinity()
    {
        var n = FloatType.infinity
        XCTAssertFalse(n.isSignalingNaN)
        
        n.negate()
        XCTAssertFalse(n.isSignalingNaN)
    }

    // -------------------------------------
    func test_WideFloat_isSignalingNaN_returns_false_for_finiteValued_WideFloats()
    {
        for _ in 0..<100
        {
            let x = FloatType(randomDouble)
            XCTAssertFalse(x.isSignalingNaN)
        }
    }
    
    // -------------------------------------
    func test_WideFloat_isInfinite_returns_false_for_WideFloat_nan()
    {
        let n = FloatType.nan
        XCTAssertFalse(n.isInfinite)
    }
    
    // -------------------------------------
    func test_WideFloat_isInfinite_returns_false_for_WideFloat_signalingNaN()
    {
        let n = FloatType.signalingNaN
        XCTAssertFalse(n.isInfinite)
    }
    
    // -------------------------------------
    func test_WideFloat_isInfinite_returns_true_for_WideFloat_infinity()
    {
        var n = FloatType.infinity
        XCTAssertTrue(n.isInfinite)
        
        n.negate()
        XCTAssertTrue(n.isInfinite)
    }

    // -------------------------------------
    func test_WideFloat_isInfinite_returns_false_for_finiteValued_WideFloats()
    {
        for _ in 0..<100
        {
            let x = FloatType(randomDouble)
            XCTAssertFalse(x.isInfinite)
        }
    }

    // -------------------------------------
    func test_WideFloat_can_recover_the_Double_value_it_was_initialized_with()
    {
        for _ in 0..<100
        {
            let originalValue = randomDouble
            
            let wideValue = FloatType(originalValue)
            let recoveredValue = wideValue.doubleValue
            
            XCTAssertEqual(originalValue, recoveredValue)
        }
    }
    
    // -------------------------------------
    func computeDelta<T: FixedWidthInteger>(_ x: T, _ y: T) -> T
    {
        if x > y { return x - y }
        return y - x
    }
    
        
    // -------------------------------------
    func test_UInt64_value_from_WideFloat_initialized_with_unsigned_integer_is_same_as_that_unsigned_integer()
    {
        /*
         Note that for unsigned integers, since a 64-bit WideFloat uses the
         high bit of the significand as the sign bit, we actually lose the
         least significant bit, so we can't test for absolute equality, so we
         test that we're off by at most 1.
         */
        let specificCases: [UInt64] =
        [
            17871182804272940033, 9291187523362059265, 13048704065388569601,
            17799382659944555521, 11536022651085169665, 14564240196804064257,
            9728877293306455041, 12321310007454557185, 10458446715928531969,
            11492726620785812481, 14087785612018623489, 14666318631217525761,
            16985780926527751169, 15049745135151916033, 16218358710991188993,
            13178469215745127425, 14993775423123121153, 11593723618950734849,
            9674979217308963841, 16145887796025537537, 14733926704856732673,
            18288734576837403649, 16408533808159929345, 11098042140158985217,
            16601343413799529471, 16537284071973891071, 18418422684684643327,
            13585473927408114687, 14345753644382481407, 11341195357271129087,
            3771715963119138781, 772357319206383592, 4069883664751751859,
            3933083078007986966, 11001309344332245611, 1697364674518169086,
            4468088891154890401, 4436732622520509169, 9895636279434049713,
            
            0, 0xffff_ffff__ffff_ffff,
        ]
        
        for intValue in specificCases
        {
            let wFloat = FloatType(intValue)

            let actual = wFloat.uint64Value

            let actualDelta = computeDelta(intValue, actual)
            
            if actualDelta > 1
            {
                print("\n  -- Failing value: \(intValue)")
                print("      actual value: \(actual)")
                print("   intValue binary: \(binary: intValue)")
                print("     actual binary: \(binary: actual)")
                print(" wFloat Sig binary: \(binary: wFloat._significand)")
            }

            XCTAssertLessThanOrEqual(actualDelta, 1)
        }

        for _ in 0..<100
        {
            let intValue = urandom64
            let wFloat = FloatType(intValue)

            let actual = wFloat.uint64Value

            let actualDelta = computeDelta(intValue, actual)
            
            if actualDelta > 1
            {
                print("\n  -- Failing value: \(intValue)")
                print("      actual value: \(actual)")
                print("   intValue binary: \(binary: intValue)")
                print("     actual binary: \(binary: actual)")
                print(" wFloat Sig binary: \(binary: wFloat._significand)")
            }

            XCTAssertLessThanOrEqual(actualDelta, 1)
        }
    }
        
    // -------------------------------------
    func test_Int64_value_from_WideFloat_initialized_with_signed_integer_is_same_as_that_signed_integer()
    {
        let specificCases: [Int64] = [ 0, 1, -1, Int64.max, Int64.min ]
        
        for intValue in specificCases
        {
            let wFloat = FloatType(intValue)

            let actual = wFloat.int64Value
            
            if actual != intValue
            {
                print("\n  -- Failing value: \(intValue)")
                print("      actual value: \(actual)")
                print("   intValue binary: \(binary: intValue)")
                print("     actual binary: \(binary: actual)")
                print(" wFloat Sig binary: \(binary: wFloat._significand)")
            }

            XCTAssertEqual(actual, intValue)
        }

        for _ in 0..<1000
        {
            let intValue = random64
            let wFloat = FloatType(intValue)

            let actual = wFloat.int64Value

            if actual != intValue
            {
                print("\n  -- Failing value: \(intValue)")
                print("      actual value: \(actual)")
                print("   intValue binary: \(binary: intValue)")
                print("     actual binary: \(binary: actual)")
                print(" wFloat Sig binary: \(binary: wFloat._significand)")
            }

            XCTAssertEqual(actual, intValue)
        }
    }
    
    // -------------------------------------
    func test_Double_value_from_WideFloat_initialized_with_signed_integer_is_same_as_Double_initialized_with_that_signed_integer()
    {
        let specificCases: [Int64] = []
        
        for intValue in specificCases
        {
            let wFloat = FloatType(intValue)
            
            let actual = wFloat.doubleValue
            let expected = Double(intValue)
            
            XCTAssertEqual(actual, expected)
        }
        for _ in 0..<1000
        {
            let intValue = random64
            let wFloat = FloatType(intValue)
            
            let actual = wFloat.doubleValue
            let expected = Double(intValue)
            
            // We print failing cases so we can add them to specific cases above
            if actual != expected {
                print("\n  -- Failing Value: \(intValue)\n")
            }

            XCTAssertEqual(actual, expected)
        }
    }

    // TODO: Re-enable these once WideFloat supports Decimal conversion.
    #if false
    // -------------------------------------
    func test_WideFloat_Decimal_recovered_from_initing_with_Double_is_same_as_Decimal_from_that_Double()
    {
        for _ in 0..<100
        {
            let originalValue = randomDouble
            
            let wideValue = FloatType(originalValue)
            let recoveredValue = wideValue.decimalValue
            let expected = Decimal(originalValue)
            
            print("------------")
            print("recovered: \(recoveredValue)")
            print(" expected: \(expected)")

            XCTAssertEqual(recoveredValue, expected)
        }
        
//        for _ in 0..<100
//        {
//            let originalValue = 1 / randomDouble
//
//            let wideValue = FloatType(originalValue)
//            let recoveredValue = wideValue.decimalValue
//            let expected = Decimal(originalValue)
//
//            XCTAssertEqual(recoveredValue, expected)
//        }
    }

    // -------------------------------------
    func test_WideFloat_can_recover_the_Decimal_value_it_was_initialized_with()
    {
        for _ in 0..<100
        {
            let originalValue = randomDecimal
            let originalDoubleValue = originalValue.doubleValue
                        
            let wideValue = WideFloat<UInt128>(originalValue)
            let wideDoubleValue = wideValue.doubleValue
            let recoveredValue = wideValue.decimalValue
            
            print("------")
            print("original exp    = \(originalValue._exponent)")
            print("recovered exp   = \(recoveredValue._exponent)")
            print("           orig = \(originalValue)")
            print(" recoveredValue = \(recoveredValue)")
            print("wideDoubleValue = \(wideDoubleValue)")
            print("origDoubleValue = \(originalDoubleValue)")

            XCTAssertEqual(wideDoubleValue, originalDoubleValue)
            XCTAssertEqual(originalValue, recoveredValue)
        }
    }
    #endif
    
    // -------------------------------------
    func test_64_bit_WideFloat_inititalized_with_Float_80_can_recover_the_Float80()
    {
        for _ in 0..<100
        {
            let expected = randomFloat80
            let x = FloatType(expected)
            let x80 = x.float80Value
            
            XCTAssertEqual(x80, expected)
        }
    }
    
    // -------------------------------------
    func test_init_with_sign_exponent_and_significand()
    {
        var x = FloatType(sign: .plus, exponent: 0, significand: FloatType.nan)
        var dblX = Double(sign: .plus, exponent: 0, significand: Double.nan)
        
        XCTAssertEqual(x.isNaN, dblX.isNaN)
                
        x = FloatType(sign: .plus, exponent: 0, significand: FloatType.infinity)
        dblX = Double(sign: .plus, exponent: 0, significand: Double.infinity)
        
        XCTAssertEqual(x.isInfinite, dblX.isInfinite)
        XCTAssertEqual(x.sign, dblX.sign)
        
        x = -x
        dblX = -dblX
        
        XCTAssertEqual(x.doubleValue, dblX)
        XCTAssertEqual(x.sign, dblX.sign)

        x = FloatType(sign: .plus, exponent: 0, significand: 0)
        dblX = Double(sign: .plus, exponent: 0, significand: 0)
        
        XCTAssertEqual(x.doubleValue, dblX)
        XCTAssertEqual(x.sign, dblX.sign)
        
        x = -x
        dblX = -dblX
        
        XCTAssertEqual(x.doubleValue, dblX)
        XCTAssertEqual(x.sign, dblX.sign)

        x = FloatType(sign: .plus, exponent: 3, significand: 8)
        dblX = Double(sign: .plus, exponent: 3, significand: 8)
        
        XCTAssertEqual(x.doubleValue, dblX)
        XCTAssertEqual(x.sign, dblX.sign)
        
        x = -x
        dblX = -dblX
        
        XCTAssertEqual(x.doubleValue, dblX)
        XCTAssertEqual(x.sign, dblX.sign)
        
        x = FloatType(sign: .plus, exponent: -3, significand: 8)
        dblX = Double(sign: .plus, exponent: -3, significand: 8)
        
        XCTAssertEqual(x.doubleValue, dblX)
        XCTAssertEqual(x.sign, dblX.sign)
        
        x = -x
        dblX = -dblX
        
        XCTAssertEqual(x.doubleValue, dblX)
        XCTAssertEqual(x.sign, dblX.sign)

        x = FloatType(sign: .plus, exponent: 7, significand: 42)
        dblX = Double(sign: .plus, exponent: 7, significand: 42)
        
        XCTAssertEqual(x.doubleValue, dblX)
        XCTAssertEqual(x.sign, dblX.sign)
        
        x = -x
        dblX = -dblX
        
        XCTAssertEqual(x.doubleValue, dblX)
        XCTAssertEqual(x.sign, dblX.sign)
        
        x = FloatType(
            sign: .plus,
            exponent: 1,
            significand: FloatType.greatestFiniteMagnitude
        )
        
        XCTAssertTrue(x.isInfinite)
        XCTAssertFalse(x.isNegative)
        
        x = -x
        dblX = -dblX
        
        XCTAssertTrue(x.isInfinite)
        XCTAssertTrue(x.isNegative)
        
        x = FloatType(
            sign: .plus,
            exponent: -1,
            significand: FloatType.leastNonzeroMagnitude
        )
        
        XCTAssertTrue(x.isZero)
        XCTAssertFalse(x.isNegative)
        
        x = -x
        dblX = -dblX
        
        XCTAssertTrue(x.isZero)
        XCTAssertTrue(x.isNegative)
        
        x = FloatType(
            sign: .plus,
            exponent: -1,
            significand: FloatType.leastNormalMagnitude
        )
        
        XCTAssertTrue(x.isZero)
        XCTAssertFalse(x.isNegative)
        
        x = -x
        dblX = -dblX
        
        XCTAssertTrue(x.isZero)
        XCTAssertTrue(x.isNegative)
    }
}
