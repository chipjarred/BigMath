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
    
    func binStr<T: FixedWidthInteger>(_ x: T) -> String
    {
        var s = ""
        for i in (0..<T.bitWidth).reversed()
        {
            let bit = (x >> i) & 1
            s.append(bit == 1 ? "1" : "0")
        }
        return s
    }
    
    func binSigStr<T: BinaryFloatingPoint>(_ x: T) -> String
    {
        assert(x >= 0)
        var sig = UInt64(x.significandBitPattern)
        sig <<= sig.leadingZeroBitCount - 2
        if x != 0 {
            sig.setBit(at: 62, to: true)
        }
        
        return binStr(sig)
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
}
