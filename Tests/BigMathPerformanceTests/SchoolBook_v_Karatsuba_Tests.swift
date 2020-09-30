//
//  SchoolBook_v_Karatsuba_Tests.swift
//
//
//  Created by Chip Jarred on 9/7/20.
//

import XCTest
import BigMath
import Foundation


// -------------------------------------
class SchoolBook_v_Karatsuba_Tests: XCTestCase
{
    // -------------------------------------
    @inline(__always)
    static func generateTests<T>(
        count: Int,
        forType: T.Type) -> [(x: T, y: T)]
        where
            T: WideUnsignedInteger,
            T.Wrapped == WideUInt<T.Digit>
    {
        var testCases = [(x: T, y: T)]()
        testCases.reserveCapacity(count)

        for _ in 0..<count
        {
            var x = T()
            var y = T()
            setWithRandomBytes(&x)
            setWithRandomBytes(&y)
            testCases.append((x, y))
        }
        
        return testCases
    }

    // -------------------------------------
    func compare_algorithms<T>(_ iterations: Int, forType: T.Type)
        where
            T: WideUnsignedInteger,
            T.Wrapped == WideUInt<T.Digit>
    {
        var productHigh = T()
        var productLow = T()
        
        let testCases = Self.generateTests(count: iterations, forType: T.self)
        
        var start = Date()
        for (x, y) in testCases
        {
            (productHigh.wrapped, productLow.wrapped) =
                x.wrapped.multipliedFullWidth_schoolbook(by: y.wrapped)
        }
        let schoolBookTime = Date().timeIntervalSince(start)
        
        start = Date()
        for (x, y) in testCases
        {
            (productHigh.wrapped, productLow.wrapped) =
                x.wrapped.multipliedFullWidth_karatsuba(by: y.wrapped)
        }
        let karatsubaTime = Date().timeIntervalSince(start)
        
        start = Date()
        for (x, y) in testCases
        {
            (productHigh.wrapped, productLow.wrapped) =
                x.wrapped.multipliedFullWidth_karatsuba_async(by: y.wrapped)
        }
        let karatsubaAsyncTime = Date().timeIntervalSince(start)

        print("\n")
        print("Results for \(T.self): \(iterations) iterations")
        print("          School book = \(schoolBookTime) seconds")
        print("            Karatsuba = \(karatsubaTime) seconds")
        print("    Karatsuba (async) = \(karatsubaAsyncTime) seconds")
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
//        compare_algorithms(iterations, forType: UInt8192.self)
//        compare_algorithms(iterations, forType: UInt16384.self)
//        compare_algorithms(iterations, forType: UInt32768.self)
//        compare_algorithms(iterations, forType: UInt65536.self)
    }
}
