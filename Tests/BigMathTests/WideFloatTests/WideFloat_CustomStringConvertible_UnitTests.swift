//
//  WideFloat_CustomStringConvertible_UnitTests.swift
//  
//
//  Created by Chip Jarred on 9/27/20.
//

import XCTest
@testable import BigMath

// -------------------------------------
class WideFloat_CustomStringConvertible_UnitTests: XCTestCase
{
    
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
    /*
     TODO: Need more thorough tests.  For now I'm just hacking something
     together for CustomStringConvertible to make debugging easier
     */
    func test()
    {
        typealias FloatType = WideFloat<UInt64>
        
        var s = FloatType.nan.description
        XCTAssertEqual(s, "nan")

        s = FloatType.infinity.description
        XCTAssertEqual(s, "inf")

        s = FloatType.infinity.negated.description
        XCTAssertEqual(s, "-inf")

        s = FloatType().description
        XCTAssertEqual(s, "0")

        s = FloatType().negated.description
        XCTAssertEqual(s, "-0")

        s = FloatType(1).description
        XCTAssertEqual(s, "1.0e+0")

        s = FloatType(1).negated.description
        XCTAssertEqual(s, "-1.0e+0")

        s = FloatType(1_e-1).description
        XCTAssertEqual(
            s,
            "1.000000000000000056e-1"
        )

        s = FloatType(1_e-1).negated.description
        XCTAssertEqual(
            s,
            "-1.000000000000000056e-1"
        )

        s = FloatType(5.2593562_e-32).description
        XCTAssertEqual(
            s,
            "5.259356199999999648e-32"
        )

        s = FloatType(5.2593562_e-32).negated.description
        XCTAssertEqual(
            s,
            "-5.259356199999999648e-32"
        )
        
        s = FloatType(Float80.leastNormalMagnitude).description
        XCTAssertEqual(
            s,
            "3.362103143112093517e-4932"
        )
        
        // TODO: Fix conversion from subnormal Float80, and retry this test.
        // Value in XCTAssertEqual is the string returned from Float80,
        // When correct we'll probably produce more significant digits.
//        print("Float80.leastNonzeroMagnitude = \(Float80.leastNonzeroMagnitude)")
//        s = FloatType(Float80.leastNonzeroMagnitude).description
//        XCTAssertEqual(
//            s,
//            "4e-4951"
//        )
        
        s = FloatType(Float80.greatestFiniteMagnitude).description
        XCTAssertEqual(
            s,
            "1.189731495357231761e+4932"
        )
        
        var f80: Float80 = 6811486791259321580.0
        print(f80.description)
        s = FloatType(f80).description
        XCTAssertEqual(
            s,
            "6.811486791259321580e+18"
        )
        
        f80 = -999460035951907607.2
        print(f80.description)
        s = FloatType(f80).description
        XCTAssertEqual(
            s,
            "-9.994600359519076072e+17"
        )
    }
}
