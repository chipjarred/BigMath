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
            print("original exp    = \(originalValue.exponent)")
            print("recovered exp   = \(recoveredValue.exponent)")
            print("           orig = \(originalValue)")
            print(" recoveredValue = \(recoveredValue)")
            print("wideDoubleValue = \(wideDoubleValue)")
            print("origDoubleValue = \(originalDoubleValue)")

            XCTAssertEqual(wideDoubleValue, originalDoubleValue)
            XCTAssertEqual(originalValue, recoveredValue)
        }
    }
    #endif
}
