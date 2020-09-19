//
//  Float_v_Integer_Knuth_Tests.swift
//
//
//  Created by Chip Jarred on 9/7/20.
//

import XCTest
import BigMath
import Foundation


// -------------------------------------
fileprivate func setWithRandomBytes<T>(_ dst: inout T)
{
    withUnsafeMutableBytes(of: &dst) {
        for i in $0.indices {
            $0[i] = UInt8.random(in: 0...UInt8.max)
        }
    }
}

// -------------------------------------
class Float_v_Integer_Knuth_Tests: XCTestCase
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
    static func generateFPTests<T>(
        from intTests: [(dividend:(high: T, low: T), divisor: T)])
        -> [(dividend: WideFloat<WideUInt<T>>, divisor: WideFloat<WideUInt<T>>)]
        where
            T: WideUnsignedInteger,
            T.Wrapped == WideUInt<T.Digit>,
            T.Magnitude == T
    {
        var fpTests = [(dividend: WideFloat<WideUInt<T>>, divisor: WideFloat<WideUInt<T>>)]()
        fpTests.reserveCapacity(intTests.count)
        
        for (intDividend, intDivisor) in intTests
        {
            let wideDividend = WideUInt<T>(intDividend)
            let wideDivisor = WideUInt<T>(low: intDivisor)
            
            fpTests.append(
                (
                    WideFloat<WideUInt<T>>(wideDividend),
                    WideFloat<WideUInt<T>>(wideDivisor)
                )
            )
        }
        
        return fpTests
    }

    // -------------------------------------
    func compare_algorithms<T>(_ iterations: Int, forType: T.Type)
        where
            T: WideUnsignedInteger,
            T.Wrapped == WideUInt<T.Digit>,
            T.Magnitude == T
    {
        var quotient = T()
        var remainder = T()
        
        let testCases = Self.generateTests(count: iterations, forType: T.self)
        let fpTestCases = Self.generateFPTests(from: testCases)

        var start = Date()
        for (dividend, divisor) in testCases
        {
            (quotient.wrapped, remainder.wrapped) = divisor.wrapped
                .dividingFullWidth_KnuthD(
                    (dividend.high.wrapped, dividend.low.wrapped)
            )
        }
        let intKnuthTime = Date().timeIntervalSince(start)
        
        start = Date()
        for (dividend, divisor) in fpTestCases {
            let _ = dividend / divisor
        }
        let floatKnuthTime = Date().timeIntervalSince(start)
        
        start = Date()
        for (dividend, divisor) in fpTestCases
        {
            let divInv = divisor.multiplicativeInverse_KnuthD
            let _ = dividend * divInv
        }
        let multInverseKnuth = Date().timeIntervalSince(start)

        
        print("\n")
        print("Results for \(T.self): \(iterations) iterations")
        print("           Integer Knuth D = \(intKnuthTime) seconds")
        print("             Float Knuth D = \(floatKnuthTime) seconds")
        print("    Float Mult Inv Knuth D = \(multInverseKnuth) seconds")
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
