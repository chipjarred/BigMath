//
//  WideUInt_Initialization_UnitTests.swift
//  
//
//  Created by Chip Jarred on 9/11/20.
//

import Foundation
import XCTest
@testable import BigMath

// -------------------------------------
class WideUInt_Initialization_UnitTests: XCTestCase
{
    typealias Digit = UInt32
    typealias IntType = WideUInt<Digit>
    
    // -------------------------------------
    var randomDouble: Double
    {
        let bigLimit = Double(UInt64.max)
        let bigRange = 0...bigLimit
        let littleRange = Double.leastNormalMagnitude...1
        let x = Double.random(in: bigRange)
        return  x * Double.random(in: littleRange)
    }
    
    // -------------------------------------
    var randomDecimal: Decimal
    {
        let bigLimit = Decimal(UInt64.max)
        let bigRange = 0...bigLimit
        let littleRange = Decimal.leastNormalMagnitude...1
        var x = Decimal.random(in: bigRange)
        let f = Decimal.random(in: littleRange)
        assert(x < Decimal(UInt64.max))
        x *= f
        assert(x < Decimal(UInt64.max))
        return x
    }
    
    // -------------------------------------
    func test_WideUInt_initialized_with_Double_is_same_as_UInt64_initialized_with_same_Double()
    {
        for _ in 0..<100
        {
            let originalValue = randomDouble
            
            let wideValue = IntType(originalValue)
            let value64 = UInt64(originalValue)
            
            XCTAssertEqual(wideValue.low, value64.low)
            XCTAssertEqual(wideValue.high, value64.high)
        }
    }
    
    // -------------------------------------
    func test_WideUInt_can_recover_the_floor_of_the_Double_value_it_was_initialized_with()
    {
        for _ in 0..<100
        {
            let originalValue = randomDouble
            
            let wideValue = IntType(originalValue)
            let recoveredValue = Double(wideValue)
            
            XCTAssertEqual(floor(originalValue), recoveredValue)
        }
    }
    
    // -------------------------------------
    func test_WideUInt_initialized_with_Decimal_is_same_as_UInt64_initialized_with_same_Decimal()
    {
        for _ in 0..<100
        {
            let originalValue = randomDecimal
            
            let wideValue = IntType(originalValue)
            let value64 = originalValue.uint64Value
            
            /*
             These prints are here because they found bug in Apple's
             NSDecimalNumber.  Leaving them here to be re-enabled to see if
             it's fixed, which will require undoing our work around in our
             Decimal extension.
             */
//            print("       orig = \(originalValue)")
//            print("  uintValue = \(originalValue.uintValue)")
//            print(" uint8Value = \(originalValue.uint8Value)")
//            print("uint16Value = \(originalValue.uint16Value)")
//            print("uint32Value = \(originalValue.uint32Value)")
//            print("uint64Value = \(originalValue.uint64Value)")
//
//            print("   intValue = \(originalValue.intValue)")
//            print("  int8Value = \(originalValue.int8Value)")
//            print(" int16Value = \(originalValue.int16Value)")
//            print(" int32Value = \(originalValue.int32Value)")
//            print(" int64Value = \(originalValue.int64Value)")

            XCTAssertEqual(wideValue.low, value64.low)
            XCTAssertEqual(wideValue.high, value64.high)
        }
    }
    
    // -------------------------------------
    func test_WideUInt_can_recover_the_floor_of_the_Decimal_value_it_was_initialized_with()
    {
        for _ in 0..<100
        {
            let originalValue = randomDecimal
            
            let wideValue = IntType(originalValue)
            let recoveredValue = Decimal(wideValue)
            
            XCTAssertEqual(originalValue.floor, recoveredValue)
        }
    }
}
