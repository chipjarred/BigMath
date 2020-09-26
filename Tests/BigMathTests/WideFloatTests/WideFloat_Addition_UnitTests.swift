//
//  WideFloat_Addition_UnitTests.swift
//  
//
//  Created by Chip Jarred on 9/14/20.
//

import XCTest
@testable import BigMath

// -------------------------------------
class WideFloat_Addition_UnitTests: XCTestCase
{
    typealias FloatType = WideFloat<UInt64>
    
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
    var randomDouble: Double
    {
        let bigLimit = Double(UInt64.max) / 2
        let bigRange = -bigLimit...bigLimit
        let littleRange = Double.leastNormalMagnitude...1
        let x = Double.random(in: bigRange)
        return  x * Double.random(in: littleRange)
    }
    
    // -------------------------------------
    var randomFloat: Float
    {
        let bigLimit = Float(UInt64.max) / 2
        let bigRange = -bigLimit...bigLimit
        let littleRange = Float.leastNormalMagnitude...1
        let x = Float.random(in: bigRange)
        return  x * Float.random(in: littleRange)
    }

    var random64: Int64 { Int64.random(in: Int64.min...Int64.max) }
    var urandom64: UInt64 { UInt64.random(in: UInt64.min...UInt64.max) }
    
    // -------------------------------------
    func test_adding_NaN_results_in_NaN()
    {
        let otherValues: [FloatType] =
        [
            FloatType.nan, FloatType.signalingNaN,
            FloatType.infinity, FloatType.infinity.negated,
            FloatType.leastNormalMagnitude,
            FloatType.leastNormalMagnitude.negated,
            FloatType.leastNonzeroMagnitude,
            FloatType.leastNonzeroMagnitude.negated,
            FloatType.greatestFiniteMagnitude,
            FloatType.greatestFiniteMagnitude.negated,
            FloatType(),
            FloatType().negated,
            FloatType(1),
            FloatType(1).negated
        ]
        
        for other in otherValues
        {
            var sum = FloatType.nan + other
            XCTAssertTrue(sum.isNaN)
            XCTAssertFalse(sum.isSignalingNaN)
            
            sum = other + FloatType.nan
            XCTAssertTrue(sum.isNaN)
            XCTAssertFalse(sum.isSignalingNaN)
        }
        
        for _ in 0..<100
        {
            let other = FloatType(randomDouble)
            var sum = FloatType.nan + other
            XCTAssertTrue(sum.isNaN)
            XCTAssertFalse(sum.isSignalingNaN)
            
            sum = other + FloatType.nan
            XCTAssertTrue(sum.isNaN)
            XCTAssertFalse(sum.isSignalingNaN)
        }
        
        for _ in 0..<100
        {
            let other = FloatType(urandom64)
            var sum = FloatType.nan + other
            XCTAssertTrue(sum.isNaN)
            XCTAssertFalse(sum.isSignalingNaN)
            
            sum = other + FloatType.nan
            XCTAssertTrue(sum.isNaN)
            XCTAssertFalse(sum.isSignalingNaN)
        }
        
        for _ in 0..<100
        {
            let other = FloatType(random64)
            var sum = FloatType.nan + other
            XCTAssertTrue(sum.isNaN)
            XCTAssertFalse(sum.isSignalingNaN)
            
            sum = other + FloatType.nan
            XCTAssertTrue(sum.isNaN)
            XCTAssertFalse(sum.isSignalingNaN)
        }
    }
    
    // -------------------------------------
    func test_adding_sNaN_results_in_NaN()
    {
        let otherValues: [FloatType] =
        [
            FloatType.nan, FloatType.signalingNaN,
            FloatType.infinity.negated,
            FloatType.leastNormalMagnitude,
            FloatType.leastNormalMagnitude.negated,
            FloatType.leastNonzeroMagnitude,
            FloatType.leastNonzeroMagnitude.negated,
            FloatType.greatestFiniteMagnitude,
            FloatType.greatestFiniteMagnitude.negated,
            FloatType(),
            FloatType().negated,
            FloatType(1),
            FloatType(1).negated
        ]
        
        for other in otherValues
        {
            var sum = FloatType.signalingNaN + other
            XCTAssertTrue(sum.isNaN)
            XCTAssertFalse(sum.isSignalingNaN)
            
            sum = other + FloatType.signalingNaN
            XCTAssertTrue(sum.isNaN)
            XCTAssertFalse(sum.isSignalingNaN)
        }
        
        for _ in 0..<100
        {
            let other = FloatType(randomDouble)
            var sum = FloatType.signalingNaN + other
            XCTAssertTrue(sum.isNaN)
            XCTAssertFalse(sum.isSignalingNaN)
            
            sum = other + FloatType.signalingNaN
            XCTAssertTrue(sum.isNaN)
            XCTAssertFalse(sum.isSignalingNaN)
        }
        
        for _ in 0..<100
        {
            let other = FloatType(urandom64)
            var sum = FloatType.signalingNaN + other
            XCTAssertTrue(sum.isNaN)
            XCTAssertFalse(sum.isSignalingNaN)
            
            sum = other + FloatType.signalingNaN
            XCTAssertTrue(sum.isNaN)
            XCTAssertFalse(sum.isSignalingNaN)
        }
        
        for _ in 0..<100
        {
            let other = FloatType(random64)
            var sum = FloatType.signalingNaN + other
            XCTAssertTrue(sum.isNaN)
            XCTAssertFalse(sum.isSignalingNaN)
            
            sum = other + FloatType.signalingNaN
            XCTAssertTrue(sum.isNaN)
            XCTAssertFalse(sum.isSignalingNaN)
        }
    }
    
    // -------------------------------------
    func test_adding_infinity_to_infinity_of_same_sign_results_in_infinity_of_same_sign()
    {
        var sum = FloatType.infinity + FloatType.infinity
        XCTAssertTrue(sum.isInfinite)
        XCTAssertFalse(sum.isNegative)

        sum = FloatType.infinity.negated + FloatType.infinity.negated
        XCTAssertTrue(sum.isInfinite)
        XCTAssertTrue(sum.isNegative)
    }
    
    // -------------------------------------
    func test_adding_infinities_with_opposite_signs_results_in_NaN()
    {
        var sum = FloatType.infinity.negated + FloatType.infinity
        XCTAssertTrue(sum.isNaN)

        sum = FloatType.infinity.negated + FloatType.infinity.negated.negated
        XCTAssertTrue(sum.isNaN)
    }
    
    // -------------------------------------
    func test_adding_infinity_to_finite_numbers_results_in_infinity_with_same_sign_as_original_infinity()
    {
        let otherValues: [FloatType] =
        [
            FloatType.leastNormalMagnitude,
            FloatType.leastNormalMagnitude.negated,
            FloatType.leastNonzeroMagnitude,
            FloatType.leastNonzeroMagnitude.negated,
            FloatType.greatestFiniteMagnitude,
            FloatType.greatestFiniteMagnitude.negated,
            FloatType(),
            FloatType().negated,
            FloatType(1),
            FloatType(1).negated
        ]
        
        for other in otherValues
        {
            var sum = FloatType.infinity + other
            XCTAssertTrue(sum.isInfinite)
            XCTAssertFalse(sum.isNegative)
            
            sum = other + FloatType.infinity
            XCTAssertTrue(sum.isInfinite)
            XCTAssertFalse(sum.isNegative)
            
            sum = FloatType.infinity.negated + other
            XCTAssertTrue(sum.isInfinite)
            XCTAssertTrue(sum.isNegative)
            
            sum = other + FloatType.infinity.negated
            XCTAssertTrue(sum.isInfinite)
            XCTAssertTrue(sum.isNegative)
        }
        
        for _ in 0..<100
        {
            let other = FloatType(randomDouble)
            var sum = FloatType.infinity + other
            XCTAssertTrue(sum.isInfinite)
            XCTAssertFalse(sum.isNegative)
            
            sum = other + FloatType.infinity
            XCTAssertTrue(sum.isInfinite)
            XCTAssertFalse(sum.isNegative)
            
            sum = FloatType.infinity.negated + other
            XCTAssertTrue(sum.isInfinite)
            XCTAssertTrue(sum.isNegative)
            
            sum = other + FloatType.infinity.negated
            XCTAssertTrue(sum.isInfinite)
            XCTAssertTrue(sum.isNegative)
        }
        
        for _ in 0..<100
        {
            let other = FloatType(urandom64)
            var sum = FloatType.infinity + other
            XCTAssertTrue(sum.isInfinite)
            XCTAssertFalse(sum.isNegative)
            
            sum = other + FloatType.infinity
            XCTAssertTrue(sum.isInfinite)
            XCTAssertFalse(sum.isNegative)
            
            sum = FloatType.infinity.negated + other
            XCTAssertTrue(sum.isInfinite)
            XCTAssertTrue(sum.isNegative)
            
            sum = other + FloatType.infinity.negated
            XCTAssertTrue(sum.isInfinite)
            XCTAssertTrue(sum.isNegative)
        }
        
        for _ in 0..<100
        {
            let other = FloatType(random64)
            var sum = FloatType.infinity + other
            XCTAssertTrue(sum.isInfinite)
            XCTAssertFalse(sum.isNegative)
            
            sum = other + FloatType.infinity
            XCTAssertTrue(sum.isInfinite)
            XCTAssertFalse(sum.isNegative)
            
            sum = FloatType.infinity.negated + other
            XCTAssertTrue(sum.isInfinite)
            XCTAssertTrue(sum.isNegative)
            
            sum = other + FloatType.infinity.negated
            XCTAssertTrue(sum.isInfinite)
            XCTAssertTrue(sum.isNegative)
        }
    }
    
    // -------------------------------------
    func test_adding_zero_of_the_same_sign_results_in_a_zero_of_the_same_sign()
    {
        var sum = FloatType.zero + FloatType.zero
        XCTAssertTrue(sum.isZero)
        XCTAssertFalse(sum.isNegative)

        sum = FloatType.zero.negated + FloatType.zero.negated
        XCTAssertTrue(sum.isZero)
        XCTAssertTrue(sum.isNegative)
    }
    
    // -------------------------------------
    func test_adding_zero_with_opposite_signs_results_in_plus_zero()
    {
        var sum = FloatType.zero.negated + FloatType.zero
        XCTAssertTrue(sum.isZero)
        XCTAssertFalse(sum.isNegative)

        sum = FloatType.zero + FloatType.zero.negated
        XCTAssertTrue(sum.isZero)
        XCTAssertFalse(sum.isNegative)
    }
    
    // -------------------------------------
    func test_adding_zero_to_a_fininte_number_results_in_that_number()
    {
        let otherValues: [FloatType] =
        [
            FloatType.leastNormalMagnitude,
            FloatType.leastNormalMagnitude.negated,
            FloatType.leastNonzeroMagnitude,
            FloatType.leastNonzeroMagnitude.negated,
            FloatType.greatestFiniteMagnitude,
            FloatType.greatestFiniteMagnitude.negated,
            FloatType(),
            FloatType().negated,
            FloatType(1),
            FloatType(1).negated
        ]
        
        for other in otherValues
        {
            var sum = FloatType.zero + other
            XCTAssertEqual(sum, other)
            
            sum = other + FloatType.zero
            XCTAssertEqual(sum, other)

            sum = FloatType.zero.negated + other
            XCTAssertEqual(sum, other)

            sum = other + FloatType.zero.negated
            XCTAssertEqual(sum, other)
        }
        
        for _ in 0..<100
        {
            let other = FloatType(randomDouble)
            var sum = FloatType.zero + other
            XCTAssertEqual(sum, other)

            sum = other + FloatType.zero
            XCTAssertEqual(sum, other)

            sum = FloatType.zero.negated + other
            XCTAssertEqual(sum, other)

            sum = other + FloatType.zero.negated
            XCTAssertEqual(sum, other)
        }

        for _ in 0..<100
        {
            let other = FloatType(urandom64)
            var sum = FloatType.zero + other
            XCTAssertEqual(sum, other)

            sum = other + FloatType.zero
            XCTAssertEqual(sum, other)

            sum = FloatType.zero.negated + other
            XCTAssertEqual(sum, other)

            sum = other + FloatType.zero.negated
            XCTAssertEqual(sum, other)
        }

        for _ in 0..<100
        {
            let other = FloatType(random64)
            var sum = FloatType.zero + other
            XCTAssertEqual(sum, other)

            sum = other + FloatType.zero
            XCTAssertEqual(sum, other)

            sum = FloatType.zero.negated + other
            XCTAssertEqual(sum, other)

            sum = other + FloatType.zero.negated
            XCTAssertEqual(sum, other)
        }
    }
    
    // -------------------------------------
    func test_sum_of_finite_numbers_with_same_sign()
    {
        typealias FloatType = WideFloat<UInt64>
        typealias TestCase = (x0: Float80, y0: Float80)
        let testCases: [TestCase] =
        [
            (x0: 3.3438754589069757e+18, y0: 2.795557076356147e+18),
            (x0: 1.6787289753089926e+17, y0: 1.1212219972272362e+18),
            (x0: 2.2895838338253545e+18, y0: 2.9239756590262385e+18),
            (x0: 1.8092123572663117e+18, y0: 1.1119899223666446e+18),
            (x0: 8.42251154309711e+18,   y0: 5.395464610752836e+18),
            (x0: 3921743530623635028.8,   y0: 1092253370383467619.94),
            (x0: 2851439503983713699.8,   y0: 952720862328428043.6),
            (x0: 2.8034860905709696e+18,   y0: 1.0205570019754467e+18),
            (x0: 1526421666639781302.9,   y0: 3386992225624293455.0),
            (x0: 134393340826317853.414,   y0: 1963223591734300717.2),
            (x0: 1309043367877125907.6,   y0: 5280139609368010186.5),
            (x0: 2511758828445179212.2,   y0: 1140181425425421054.3),
            (x0: 6698532561063717367.5,   y0: 3000880569321499534.0),
            (x0: 616248215178195591.56,   y0: 327258896326224357.16),
            (x0: 301417465114347094.2,   y0: 1538662939856881797.6),
            (x0: 4310542092340702001.2,   y0: 2275436354807565290.0),
            (x0: 113068835571150011.305, y0: 247303356556640836.9),
            (x0: 2020963336285143181.4, y0: 461385513443127542.0),
            
            (x0: 3835190162924033424.8,   y0: 953279103336728802.56),
            (x0: 1823454549263605025.5, y0: 557209340990989702.62),
        ]
        
        for (x0, y0) in testCases
        {
            let expected = x0 + y0
            
            let x = FloatType(x0)
            let y = FloatType(y0)
            
            var sum = x + y

            if sum.float80Value != expected
            {
                print("------- Failing case:")
                print("           x = \(x0)")
                print("           y = \(y0)")
                print("    expected = \(expected)")
                print("      actual = \(sum.float80Value)")
                print("")
                print("  expected sig: \(binary: FloatType(expected)._significand)")
                print("actual sig sig: \(binary: sum._significand)")
            }


            XCTAssertEqual(sum.float80Value, expected)
            
            sum = y + x
            XCTAssertEqual(sum.float80Value, expected)
        }
        
        for _ in 0..<100
        {
            let x0 = abs(randomFloat80)
            let y0 = abs(randomFloat80)
            let expected = x0 + y0

            let x = FloatType(x0)
            let y = FloatType(y0)
            var sum = x + y

            if sum.float80Value != expected
            {
                print("\n -------- Failing case")
                print("    x: \(x0)")
                print("    y: \(y0)")
            }

            XCTAssertEqual(sum.float80Value, expected)

            sum = y + x
            XCTAssertEqual(sum.float80Value, expected)
        }
        
        for _ in 0..<100
        {
            let x0 = abs(randomDouble)
            let y0 = abs(randomDouble)
            let expected = x0 + y0

            let x = FloatType(x0)
            let y = FloatType(y0)
            var sum = x + y

            if sum.doubleValue != expected
            {
                print("\n -------- Failing case")
                print("    x: \(x0)")
                print("    y: \(y0)")
            }

            XCTAssertEqual(sum.doubleValue, expected)

            sum = y + x
            XCTAssertEqual(sum.doubleValue, expected)
        }
        
        for _ in 0..<100
        {
            let x0 = -abs(randomFloat80)
            let y0 = -abs(randomFloat80)
            let expected = x0 + y0

            let x = FloatType(x0)
            let y = FloatType(y0)
            var sum = x + y
            XCTAssertEqual(sum.float80Value, expected)

            sum = y + x
            XCTAssertEqual(sum.float80Value, expected)
        }
    }
    
    // -------------------------------------
    func test_sum_of_finite_numbers_with_opposite_signs()
    {
        typealias FloatType = WideFloat<UInt64>
        typealias TestCase = (x0: Float80, y0: Float80)
        let testCases: [TestCase] =
        [
            (x0: -798663440288876065.44, y0: 4069591507036733882.5),
            (x0: -2509994308763587309.2, y0: 684125384768649593.1),
            (x0: -798663440288876065.44, y0: 4069591507036733882.5),
            (x0: -3989386152194345781.0, y0: 144416403467492684.47),
        ]
        
        for (x0, y0) in testCases
        {
            let expected = x0 + y0
            
            let x = FloatType(x0)
            let y = FloatType(y0)
            
            var sum = x + y

            if sum.float80Value != expected
            {
                print("------- Failing case:")
                print("           x = \(x0)")
                print("           y = \(y0)")
                print("    expected = \(expected)")
                print("      actual = \(sum.float80Value)")
                print("")
                print("  expected sig: \(binary: FloatType(expected)._significand)")
                print("actual sig sig: \(binary: sum._significand)")
            }


            XCTAssertEqual(sum.float80Value, expected)

            sum = y + x
            XCTAssertEqual(sum.float80Value, expected)
        }
        
        for _ in 0..<100
        {
            let x0 = -abs(randomFloat80)
            let y0 = abs(randomFloat80)
            let expected = x0 + y0
            let x = FloatType(x0)
            let y = FloatType(y0)
            
            var sum = x + y

            if sum.float80Value != expected
            {
                print("------- Failing case:")
                print("           x = \(x0)")
                print("           y = \(y0)")
                print("    expected = \(expected)")
                print("      actual = \(sum.float80Value)")
                print("")
                print("  expected sig: \(binary: FloatType(expected)._significand)")
                print("actual sig sig: \(binary: sum._significand)")
            }


            XCTAssertEqual(sum.float80Value, expected)
            
            sum = y + x
            XCTAssertEqual(sum.float80Value, expected)
        }
        
        for _ in 0..<100
        {
            let x0 = -abs(randomDouble)
            let y0 = abs(randomDouble)
            let expected = x0 + y0
            
            let x = FloatType(x0)
            let y = FloatType(y0)
            var sum = x + y
            XCTAssertEqual(sum.doubleValue, expected)
            
            sum = y + x
            XCTAssertEqual(sum.doubleValue, expected)
        }
    }
}
