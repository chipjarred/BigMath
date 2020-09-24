//
//  Float_v_Integer_Knuth_Tests.swift
//
//
//  Created by Chip Jarred on 9/7/20.
//

import XCTest
import BigMath
import Foundation

// ------------------------------------------
extension UInt32
{
    fileprivate static var rngState:UInt32 = UInt32.random(in: 0...UInt32.max)
    
    @inline(__always)
    static func fastRandom() -> Self
    {
        Self.rngState = UInt32(UInt64(Self.rngState) * 48271 % 0x7fffffff)
        return .rngState
    }
}

// ------------------------------------------
extension UInt
{
    @inline(__always)
    static func fastRandom() -> Self
    {
        return MemoryLayout<UInt>.size == MemoryLayout<UInt32>.size
            ? UInt(UInt32.fastRandom())
            : UInt(UInt32.fastRandom()) << 32 | UInt(UInt32.fastRandom())
    }
}


// -------------------------------------
fileprivate func setWithRandomBytes<T>(_ dst: inout T)
{
    assert(MemoryLayout<T>.size >= MemoryLayout<UInt>.size)

    withUnsafeMutableBytes(of: &dst)
    {
        let uintBuf = $0.bindMemory(to: UInt.self)
        for i in uintBuf.indices {
            uintBuf[i] = UInt.fastRandom()
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
        -> [(dividend: T, divisor: T)]
        where
            T: WideUnsignedInteger,
            T.Wrapped == WideUInt<T.Digit>
    {
        var testCases = [(dividend: T, divisor: T)]()
        testCases.reserveCapacity(count)

        for _ in 0..<count
        {
            var dividend = T()
            var divisor = T()
            setWithRandomBytes(&dividend)
            setWithRandomBytes(&divisor)
            testCases.append((dividend, divisor))
        }
        
        return testCases
    }
    
    // -------------------------------------
    static func generateFPTests<T>(
        from intTests: [(dividend:T, divisor: T)])
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
            let wideDivisor = WideUInt<T>(intDivisor)
            
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
        var doNewtonRaphson: Bool { true }
        
        let testCases = Self.generateTests(count: iterations, forType: T.self)
        let fpTestCases = Self.generateFPTests(from: testCases)
        
        // To make the tests fair, we have double the width of the integer
        // division, because internally the floating point must do double width
        // division for precision purposes.
        let intTestCases = testCases.map
        {
            (
                dividend: WideUInt(high: $0.dividend.wrapped),
                divisor: WideUInt(high: $0.divisor.wrapped)
            )
        }

        var start = Date()
        for (dividend, divisor) in intTestCases
        {
            (_, _) = dividend.quotientAndRemainder(dividingBy: divisor)
        }
        let intKnuthTime = Date().timeIntervalSince(start)
        
        start = Date()
        for (dividend, divisor) in fpTestCases {
            let _ = dividend.divide_KnuthD(by: divisor)
        }
        let floatKnuthTime = Date().timeIntervalSince(start)
        
        start = Date()
        for (dividend, divisor) in fpTestCases {
            let _ = dividend.divide_MultInv(by: divisor)
        }
        let multInverseKnuth = Date().timeIntervalSince(start)
        
        if doNewtonRaphson
        {
            start = Date()
            for (dividend, divisor) in fpTestCases {
                let _ = dividend.divide_NewtonRaphson(by: divisor)
            }
        }
        let newtonRaphson = Date().timeIntervalSince(start)

        
        print("\n")
        print("Results for \(T.self): \(iterations) iterations")
        print("           Integer Knuth D = \(intKnuthTime) seconds")
        print("             Float Knuth D = \(floatKnuthTime) seconds")
        print("    Float Mult Inv Knuth D = \(multInverseKnuth) seconds")
        if doNewtonRaphson {
            print("            Newton-Raphson = \(newtonRaphson) seconds")
        }
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
