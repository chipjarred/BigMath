//
//  WideUInt_Multiplication_SchoolBook_UnitTests.swift
//
//
//  Created by Chip Jarred on 8/22/20.
//

import XCTest
@testable import BigMath

// -------------------------------------
class WideUInt_Multiplication_SchoolBook_UnitTests: WideUInt_Multiplication_UnitTests
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
        return x.multipliedFullWidth_schoolbook(by: y)
    }
}
