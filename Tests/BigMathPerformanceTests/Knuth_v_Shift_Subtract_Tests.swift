//
//  Knuth_v_Shift_Subtract_Tests.swift
//  
//
//  Created by Chip Jarred on 9/7/20.
//

import XCTest
import BigMath
import Foundation


// -------------------------------------
class Knuth_v_Shift_Subtract_Tests: XCTestCase
{
    // -------------------------------------
    @inline(__always)
    static func generateTests<T>(
        count: Int,
        forType: T.Type)
        -> [(dividend:(high: T, low: T), divisor: T)]
        where
            T: WideUnsignedInteger,
            T.Wrapped == WideUInt<T.Digit>
    {
        var testCases = [(dividend:(high: T, low: T), divisor: T)]()
        testCases.reserveCapacity(count)

        for _ in 0..<count
        {
            var high = T()
            var low = T()
            var divisor = T()
            setWithRandomBytes(&high)
            setWithRandomBytes(&low)
            setWithRandomBytes(&divisor)
            testCases.append(((high, low), divisor))
        }
        
        return testCases
    }

    // -------------------------------------
    func compare_algorithms<T>(_ iterations: Int, forType: T.Type)
        where
            T: WideUnsignedInteger,
            T.Wrapped == WideUInt<T.Digit>
    {
        var quotient = T()
        var remainder = T()
        
        let testCases = Self.generateTests(count: iterations, forType: T.self)

        var start = Date()
        for (dividend, divisor) in testCases
        {
            (quotient.wrapped, remainder.wrapped) = divisor.wrapped
                .dividingFullWidth_ShiftSubtract(
                    (dividend.high.wrapped, dividend.low.wrapped)
            )
        }
        let shiftSubtractTime = Date().timeIntervalSince(start)
        
        start = Date()
        for (dividend, divisor) in testCases
        {
            (quotient.wrapped, remainder.wrapped) = divisor.wrapped
                .dividingFullWidth_KnuthD(
                    (dividend.high.wrapped, dividend.low.wrapped)
            )
        }
        let knuthTime = Date().timeIntervalSince(start)
        
        print("\n")
        print("Results for \(T.self): \(iterations) iterations")
        print("    Shift-Subtract = \(shiftSubtractTime) seconds")
        print("           Knuth D = \(knuthTime) seconds")
    }
    
    // -------------------------------------
    func test_compare_algorithms()
    {
        let iterations = 100_000
        
        compare_algorithms(iterations, forType: UInt128.self)
        compare_algorithms(iterations, forType: UInt256.self)
        compare_algorithms(iterations, forType: UInt512.self)
        compare_algorithms(iterations, forType: UInt1024.self)
        compare_algorithms(iterations, forType: UInt2048.self)
        compare_algorithms(iterations, forType: UInt4096.self)
    }
}
