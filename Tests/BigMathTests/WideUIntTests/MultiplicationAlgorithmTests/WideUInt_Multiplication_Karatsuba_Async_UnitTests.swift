//
//  WideUInt_Multiplication_Karatsuba_UnitTests.swift
//
//
//  Created by Chip Jarred on 8/22/20.
//

import XCTest
@testable import BigMath

// -------------------------------------
class WideUInt_Multiplication_Karatsuba_Async_UnitTests: WideUInt_Multiplication_UnitTests
{
    typealias Digit = UInt32
    typealias IntType = WideUInt<Digit>

    // -------------------------------------
    /*
     Over-ridable method so that we can use share a common test set of tests for
     multiple multiplication algorithms
     */
    override func multiplyFullWidth<T: WideDigit>(
        _ x: WideUInt<T>,
        by y: WideUInt<T>) -> (high: WideUInt<T>, low: WideUInt<T>)
    {
        return x.multipliedFullWidth_karatsuba_async(by: y, forceUse: true)
    }
    
    // -------------------------------------
    func test_randomValues()
    {
        for _ in 0..<50
        {
            let x = UInt4096.random(in: 0..<UInt4096.max / 2)
            let y = UInt4096.random(in: 0..<UInt4096.max / 2)
            
            let zKaratsuba = x.wrapped.multipliedFullWidth_karatsuba_async(
                    by: y.wrapped,
                    forceUse: true
            )
            let zSchoolBook =
                x.wrapped.multipliedFullWidth_schoolbook(by: y.wrapped)
            
            XCTAssertEqual(zKaratsuba.high, zSchoolBook.high)
            XCTAssertEqual(zKaratsuba.low, zSchoolBook.low)
        }
    }
}
