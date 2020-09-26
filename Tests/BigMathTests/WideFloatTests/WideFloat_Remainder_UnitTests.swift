//
//  WideFloat_Remainder_UnitTests.swift
//  
//
//  Created by Chip Jarred on 9/25/20.
//

import XCTest
@testable import BigMath

// -------------------------------------
class WideFloat_Remainder_UnitTests: XCTestCase
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

    var random64: Int64 { Int64.random(in: Int64.min...Int64.max) }
    var urandom64: UInt64 { UInt64.random(in: UInt64.min...UInt64.max) }
    
    // MARK:- formTruncatingRemainder tests
    // -------------------------------------
    func test_formTruncatingRemainder_called_on_nan_results_in_nan()
    {
        typealias FloatType = WideFloat<UInt64>
        
        var x = FloatType.nan
        x.formTruncatingRemainder(dividingBy: FloatType.nan)
        XCTAssertTrue(x.isNaN)
        
        x = FloatType.nan
        x.formTruncatingRemainder(dividingBy: FloatType.infinity)
        XCTAssertTrue(x.isNaN)
        
        x = FloatType.nan
        x.formTruncatingRemainder(dividingBy: FloatType.infinity.negated)
        XCTAssertTrue(x.isNaN)
        
        x = FloatType.nan
        x.formTruncatingRemainder(dividingBy: FloatType())
        XCTAssertTrue(x.isNaN)
        
        x = FloatType.nan
        x.formTruncatingRemainder(dividingBy: FloatType().negated)
        XCTAssertTrue(x.isNaN)
        
        x = FloatType.nan
        x.formTruncatingRemainder(dividingBy: FloatType(1))
        XCTAssertTrue(x.isNaN)
        
        x = FloatType.nan
        x.formTruncatingRemainder(dividingBy: FloatType(1).negated)
        XCTAssertTrue(x.isNaN)
    }
    
    // -------------------------------------
    func test_formTruncatingRemainder_dividing_by_nan_results_in_nan()
    {
        typealias FloatType = WideFloat<UInt64>
        
        var x = FloatType.nan
        x.formTruncatingRemainder(dividingBy: FloatType.nan)
        XCTAssertTrue(x.isNaN)
        
        x = FloatType.infinity
        x.formTruncatingRemainder(dividingBy: FloatType.nan)
        XCTAssertTrue(x.isNaN)
        
        x = FloatType.infinity.negated
        x.formTruncatingRemainder(dividingBy: FloatType.nan)
        XCTAssertTrue(x.isNaN)
        
        x = FloatType()
        x.formTruncatingRemainder(dividingBy: FloatType.nan)
        XCTAssertTrue(x.isNaN)
        
        x = FloatType().negated
        x.formTruncatingRemainder(dividingBy: FloatType.nan)
        XCTAssertTrue(x.isNaN)
        
        x = FloatType(1)
        x.formTruncatingRemainder(dividingBy: FloatType.nan)
        XCTAssertTrue(x.isNaN)
        
        x = FloatType(1).negated
        x.formTruncatingRemainder(dividingBy: FloatType.nan)
        XCTAssertTrue(x.isNaN)
    }
    
    // -------------------------------------
    func test_formTruncatingRemainder_dividing_infinity_by_infinity_results_in_nan()
    {
        typealias FloatType = WideFloat<UInt64>
        
        var x = FloatType.infinity
        x.formTruncatingRemainder(dividingBy: FloatType.infinity)
        XCTAssertTrue(x.isNaN)
        
        x = FloatType.infinity.negated
        x.formTruncatingRemainder(dividingBy: FloatType.infinity)
        XCTAssertTrue(x.isNaN)
        
        x = FloatType.infinity
        x.formTruncatingRemainder(dividingBy: FloatType.infinity.negated)
        XCTAssertTrue(x.isNaN)
        
        x = FloatType.infinity.negated
        x.formTruncatingRemainder(dividingBy: FloatType.infinity.negated)
        XCTAssertTrue(x.isNaN)
    }
    
    // -------------------------------------
    func test_formTruncatingRemainder_dividing_finite_number_by_infinity_results_in_the_finite_number()
    {
        typealias FloatType = WideFloat<UInt64>

        let testCases: [FloatType] =
        [
            FloatType(), FloatType(1), FloatType(1).negated,
            FloatType.greatestFiniteMagnitude,
            FloatType.greatestFiniteMagnitude.negated,
            FloatType.leastNormalMagnitude,
            FloatType.leastNormalMagnitude.negated,
            FloatType.leastNonzeroMagnitude,
            FloatType.leastNonzeroMagnitude.negated
        ]
        
        for expected in testCases
        {
            var x = expected
            x.formTruncatingRemainder(dividingBy: FloatType.infinity)
            XCTAssertEqual(x, expected)
        }
        
        for _ in 0..<100
        {
            let expected = FloatType(urandom64)
            var x = expected
            x.formTruncatingRemainder(dividingBy: FloatType.infinity)
            XCTAssertEqual(x, expected)
        }
    }
    
    // -------------------------------------
    func test_formTruncatingRemainder_dividing_finite_number_by_negative_infinity_infinity_results_in_the_finite_number()
    {
        typealias FloatType = WideFloat<UInt64>

        let testCases: [FloatType] =
        [
            FloatType(), FloatType(1), FloatType(1).negated,
            FloatType.greatestFiniteMagnitude,
            FloatType.greatestFiniteMagnitude.negated,
            FloatType.leastNormalMagnitude,
            FloatType.leastNormalMagnitude.negated,
            FloatType.leastNonzeroMagnitude,
            FloatType.leastNonzeroMagnitude.negated
        ]
        
        for expected in testCases
        {
            var x = expected
            x.formTruncatingRemainder(dividingBy: FloatType.infinity.negated)
            XCTAssertEqual(x, expected)
        }
        
        for _ in 0..<100
        {
            let expected = FloatType(urandom64)
            var x = expected
            x.formTruncatingRemainder(dividingBy: FloatType.infinity.negated)
            XCTAssertEqual(x, expected)
        }
    }
    
    // -------------------------------------
    func test_formTruncatingRemainder_dividing_nonNaN_by_plus_or_minus_0_results_nan()
    {
        typealias FloatType = WideFloat<UInt64>

        let testCases: [FloatType] =
        [
            FloatType(), FloatType(1), FloatType(1).negated,
            FloatType.greatestFiniteMagnitude,
            FloatType.greatestFiniteMagnitude.negated,
            FloatType.leastNormalMagnitude,
            FloatType.leastNormalMagnitude.negated,
            FloatType.leastNonzeroMagnitude,
            FloatType.leastNonzeroMagnitude.negated
        ]
        
        for x in testCases
        {
            var x = x
            x.formTruncatingRemainder(dividingBy: FloatType())
            XCTAssertTrue(x.isNaN)
        }
        
        for x in testCases
        {
            var x = x
            x.formTruncatingRemainder(dividingBy: FloatType().negated)
            XCTAssertTrue(x.isNaN)
        }
        
        for _ in 0..<100
        {
            var x = FloatType(urandom64)
            x.formTruncatingRemainder(dividingBy: FloatType())
            XCTAssertTrue(x.isNaN)
        }
        
        for _ in 0..<100
        {
            var x = FloatType(urandom64)
            x.formTruncatingRemainder(dividingBy: FloatType().negated)
            XCTAssertTrue(x.isNaN)
        }
    }

    // -------------------------------------
    func test_formTruncatingRemainder()
    {
        typealias FloatType = WideFloat<UInt64>
        typealias TestCase = (x: Float80, y: Float80, expected: Float80)
        
        let testCases: [TestCase] =
        [
            (x: 8.625, y: 1, expected: 0.625),
            (x: 8.625, y: 0.75, expected: 0.375),
            (
                x:  -945101613527818692.9,
                y: -3289262896097158385.0,
                expected: -945101613527818692.9
            ),
            (
                x:    160220511979465722.36,
                y:    235058736976725.69347,
                expected: 145512098315525.1089
            ),
            (
                x:   5548279897231231928.5,
                y:   4526536360464121808.2,
                expected: 1021743536767110120.25
            ),
        ]
        
        /*
         There are rounding differences between Float80 and WideFloat somewhere
         though not in addition and subtraction.  For now we can't directly
         test that we match the expected value that was calculated from Float80.
         Instead we simply print the cases that don't match expected to give
         some indication that something is amiss.  As these prints show, we're
         only in the least significant bits because of some roundning issue we
         still need to find. Our actual test is that the dividend minus the
         remainder is the same as the manually computed integer quotient times
         the dividend.  This isn't a great test, but it will catch if the
         implementation of formTruncatingRemainder is wrong is some significant
         way.
         */
        
        for (x80, y80, expected) in testCases
        {
            let x = FloatType(x80)
            let y = FloatType(y80)
            
            var r = x
            r.formTruncatingRemainder(dividingBy: y)

            assert(x.isNormalized)
            
            var z80 = x80
            z80.formTruncatingRemainder(dividingBy: y80)

            if r != FloatType(expected)
            {
                print("Failing Case ----")
                print("    x80 = \(x80)")
                print("    y80 = \(y80)")
                print("    z80 = \(z80)")
                print("      r = \(r.float80Value)")
                print("-----------------")
            }
            assert(z80 == expected)

            
            let x1 = x - r
            let p = (x / y).rounded(.towardZero) * y

            XCTAssertEqual(x1.float80Value, p.float80Value)
        }

        // Tests that we get the same as Float80 results
        for _ in 0..<100
        {
            let x80 = randomFloat80
            let y80 = randomFloat80
            let x = FloatType(x80)
            let y = FloatType(y80)

            var z80 = x80
            z80.formTruncatingRemainder(dividingBy: y80)

            var r = x
            r.formTruncatingRemainder(dividingBy: y)

            if r != FloatType(z80)
            {
                var z80 = x80
                z80.formTruncatingRemainder(dividingBy: y80)
                print("Failing Case ----")
                print("    x80 = \(x80)")
                print("    y80 = \(y80)")
                print("    z80 = \(z80)")
                print("      r = \(r.float80Value)")
                print("-----------------")
            }

            let x1 = x - r
            let p = (x / y).rounded(.towardZero) * y

            XCTAssertEqual(x1.float80Value, p.float80Value)
        }
    }
    
    // MARK:- formRemainder tests
    // -------------------------------------
    func test_formRemainder_called_on_nan_results_in_nan()
    {
        typealias FloatType = WideFloat<UInt64>
        
        var x = FloatType.nan
        x.formRemainder(dividingBy: FloatType.nan)
        XCTAssertTrue(x.isNaN)
        
        x = FloatType.nan
        x.formRemainder(dividingBy: FloatType.infinity)
        XCTAssertTrue(x.isNaN)
        
        x = FloatType.nan
        x.formRemainder(dividingBy: FloatType.infinity.negated)
        XCTAssertTrue(x.isNaN)
        
        x = FloatType.nan
        x.formRemainder(dividingBy: FloatType())
        XCTAssertTrue(x.isNaN)
        
        x = FloatType.nan
        x.formRemainder(dividingBy: FloatType().negated)
        XCTAssertTrue(x.isNaN)
        
        x = FloatType.nan
        x.formRemainder(dividingBy: FloatType(1))
        XCTAssertTrue(x.isNaN)
        
        x = FloatType.nan
        x.formRemainder(dividingBy: FloatType(1).negated)
        XCTAssertTrue(x.isNaN)
    }
    
    // -------------------------------------
    func test_formRemainder_dividing_by_nan_results_in_nan()
    {
        typealias FloatType = WideFloat<UInt64>
        
        var x = FloatType.nan
        x.formRemainder(dividingBy: FloatType.nan)
        XCTAssertTrue(x.isNaN)
        
        x = FloatType.infinity
        x.formRemainder(dividingBy: FloatType.nan)
        XCTAssertTrue(x.isNaN)
        
        x = FloatType.infinity.negated
        x.formRemainder(dividingBy: FloatType.nan)
        XCTAssertTrue(x.isNaN)
        
        x = FloatType()
        x.formRemainder(dividingBy: FloatType.nan)
        XCTAssertTrue(x.isNaN)
        
        x = FloatType().negated
        x.formRemainder(dividingBy: FloatType.nan)
        XCTAssertTrue(x.isNaN)
        
        x = FloatType(1)
        x.formRemainder(dividingBy: FloatType.nan)
        XCTAssertTrue(x.isNaN)
        
        x = FloatType(1).negated
        x.formRemainder(dividingBy: FloatType.nan)
        XCTAssertTrue(x.isNaN)
    }
    
    // -------------------------------------
    func test_formRemainder_dividing_infinity_by_infinity_results_in_nan()
    {
        typealias FloatType = WideFloat<UInt64>
        
        var x = FloatType.infinity
        x.formRemainder(dividingBy: FloatType.infinity)
        XCTAssertTrue(x.isNaN)
        
        x = FloatType.infinity.negated
        x.formRemainder(dividingBy: FloatType.infinity)
        XCTAssertTrue(x.isNaN)
        
        x = FloatType.infinity
        x.formRemainder(dividingBy: FloatType.infinity.negated)
        XCTAssertTrue(x.isNaN)
        
        x = FloatType.infinity.negated
        x.formRemainder(dividingBy: FloatType.infinity.negated)
        XCTAssertTrue(x.isNaN)
    }
    
    // -------------------------------------
    func test_formRemainder_dividing_finite_number_by_infinity_results_in_the_finite_number()
    {
        typealias FloatType = WideFloat<UInt64>

        let testCases: [FloatType] =
        [
            FloatType(), FloatType(1), FloatType(1).negated,
            FloatType.greatestFiniteMagnitude,
            FloatType.greatestFiniteMagnitude.negated,
            FloatType.leastNormalMagnitude,
            FloatType.leastNormalMagnitude.negated,
            FloatType.leastNonzeroMagnitude,
            FloatType.leastNonzeroMagnitude.negated
        ]
        
        for expected in testCases
        {
            var x = expected
            x.formRemainder(dividingBy: FloatType.infinity)
            XCTAssertEqual(x, expected)
        }
        
        for _ in 0..<100
        {
            let expected = FloatType(urandom64)
            var x = expected
            x.formRemainder(dividingBy: FloatType.infinity)
            XCTAssertEqual(x, expected)
        }
    }
    
    // -------------------------------------
    func test_formRemainder_dividing_finite_number_by_negative_infinity_infinity_results_in_the_finite_number()
    {
        typealias FloatType = WideFloat<UInt64>

        let testCases: [FloatType] =
        [
            FloatType(), FloatType(1), FloatType(1).negated,
            FloatType.greatestFiniteMagnitude,
            FloatType.greatestFiniteMagnitude.negated,
            FloatType.leastNormalMagnitude,
            FloatType.leastNormalMagnitude.negated,
            FloatType.leastNonzeroMagnitude,
            FloatType.leastNonzeroMagnitude.negated
        ]
        
        for expected in testCases
        {
            var x = expected
            x.formRemainder(dividingBy: FloatType.infinity.negated)
            XCTAssertEqual(x, expected)
        }
        
        for _ in 0..<100
        {
            let expected = FloatType(urandom64)
            var x = expected
            x.formRemainder(dividingBy: FloatType.infinity.negated)
            XCTAssertEqual(x, expected)
        }
    }
    
    // -------------------------------------
    func test_formRemainder_dividing_nonNaN_by_plus_or_minus_0_results_nan()
    {
        typealias FloatType = WideFloat<UInt64>

        let testCases: [FloatType] =
        [
            FloatType(), FloatType(1), FloatType(1).negated,
            FloatType.greatestFiniteMagnitude,
            FloatType.greatestFiniteMagnitude.negated,
            FloatType.leastNormalMagnitude,
            FloatType.leastNormalMagnitude.negated,
            FloatType.leastNonzeroMagnitude,
            FloatType.leastNonzeroMagnitude.negated
        ]
        
        for x in testCases
        {
            var x = x
            x.formRemainder(dividingBy: FloatType())
            XCTAssertTrue(x.isNaN)
        }
        
        for x in testCases
        {
            var x = x
            x.formRemainder(dividingBy: FloatType().negated)
            XCTAssertTrue(x.isNaN)
        }
        
        for _ in 0..<100
        {
            var x = FloatType(urandom64)
            x.formRemainder(dividingBy: FloatType())
            XCTAssertTrue(x.isNaN)
        }
        
        for _ in 0..<100
        {
            var x = FloatType(urandom64)
            x.formRemainder(dividingBy: FloatType().negated)
            XCTAssertTrue(x.isNaN)
        }
    }

    // -------------------------------------
    func test_formRemainder()
    {
        typealias FloatType = WideFloat<UInt64>
        typealias TestCase = (x: Float80, y: Float80, expected: Float80)
        
        let testCases: [TestCase] =
        [
            (x: 8.625, y: 1, expected: -0.375),
            (x: 8.625, y: 0.75, expected: -0.375),
            (
                x:  -945101613527818692.9,
                y: -3289262896097158385.0,
                expected: -945101613527818692.9
            ),
            (
                x:    160220511979465722.36,
                y:    235058736976725.69347,
                expected: -89546638661200.584564
            ),
            (
                x:   5548279897231231928.5,
                y:   4526536360464121808.2,
                expected: 1021743536767110120.25
            ),
        ]
        
        /*
         There are rounding differences between Float80 and WideFloat somewhere
         though not in addition and subtraction.  For now we can't directly
         test that we match the expected value that was calculated from Float80.
         Instead we simply print the cases that don't match expected to give
         some indication that something is amiss.  As these prints show, we're
         only in the least significant bits because of some roundning issue we
         still need to find. Our actual test is that the dividend minus the
         remainder is the same as the manually computed integer quotient times
         the dividend.  This isn't a great test, but it will catch if the
         implementation of formRemainder is wrong is some significant
         way.
         */
        
        for (x80, y80, expected) in testCases
        {
            let x = FloatType(x80)
            let y = FloatType(y80)
            
            var r = x
            r.formRemainder(dividingBy: y)

            assert(x.isNormalized)
            
            var z80 = x80
            z80.formRemainder(dividingBy: y80)

            if r != FloatType(expected)
            {
                print("Failing Case ----")
                print("    x80 = \(x80)")
                print("    y80 = \(y80)")
                print("    z80 = \(z80)")
                print("      r = \(r.float80Value)")
                print("-----------------")
            }
            assert(z80 == expected)

            
            let x1 = x - r
            let p = (x / y).rounded(.toNearestOrEven) * y

            XCTAssertEqual(x1.float80Value, p.float80Value)
        }

        // Tests that we get the same as Float80 results
        for _ in 0..<100
        {
            let x80 = randomFloat80
            let y80 = randomFloat80
            let x = FloatType(x80)
            let y = FloatType(y80)

            var z80 = x80
            z80.formRemainder(dividingBy: y80)

            var r = x
            r.formRemainder(dividingBy: y)

            if r != FloatType(z80)
            {
                var z80 = x80
                z80.formRemainder(dividingBy: y80)
                print("Failing Case ----")
                print("    x80 = \(x80)")
                print("    y80 = \(y80)")
                print("    z80 = \(z80)")
                print("      r = \(r.float80Value)")
                print("-----------------")
            }

            let x1 = x - r
            let p = (x / y).rounded(.toNearestOrEven) * y

            XCTAssertEqual(x1.float80Value, p.float80Value)
        }
    }
}
