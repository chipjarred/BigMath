//
//  WideFloat_Division_UnitTests.swift
//  
//
//  Created by Chip Jarred on 9/17/20.
//

import XCTest
@testable import BigMath

// -------------------------------------
class WideFloat_Division_UnitTests: XCTestCase
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
    func test_dividing_NaN_results_in_NaN()
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
            var quotient = FloatType.nan / other
            XCTAssertTrue(quotient.isNaN)
            XCTAssertFalse(quotient.isSignalingNaN)
            
            quotient = other / FloatType.nan
            XCTAssertTrue(quotient.isNaN)
            XCTAssertFalse(quotient.isSignalingNaN)
        }
        
        for _ in 0..<100
        {
            let other = FloatType(randomDouble)
            var quotient = FloatType.nan / other
            XCTAssertTrue(quotient.isNaN)
            XCTAssertFalse(quotient.isSignalingNaN)
            
            quotient = other / FloatType.nan
            XCTAssertTrue(quotient.isNaN)
            XCTAssertFalse(quotient.isSignalingNaN)
        }
        
        for _ in 0..<100
        {
            let other = FloatType(urandom64)
            var quotient = FloatType.nan / other
            XCTAssertTrue(quotient.isNaN)
            XCTAssertFalse(quotient.isSignalingNaN)
            
            quotient = other / FloatType.nan
            XCTAssertTrue(quotient.isNaN)
            XCTAssertFalse(quotient.isSignalingNaN)
        }
        
        for _ in 0..<100
        {
            let other = FloatType(random64)
            var quotient = FloatType.nan / other
            XCTAssertTrue(quotient.isNaN)
            XCTAssertFalse(quotient.isSignalingNaN)
            
            quotient = other / FloatType.nan
            XCTAssertTrue(quotient.isNaN)
            XCTAssertFalse(quotient.isSignalingNaN)
        }
    }
    
    // -------------------------------------
    func test_dividing_sNaN_results_in_NaN()
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
            var quotient = FloatType.signalingNaN / other
            XCTAssertTrue(quotient.isNaN)
            XCTAssertFalse(quotient.isSignalingNaN)
            
            quotient = other / FloatType.signalingNaN
            XCTAssertTrue(quotient.isNaN)
            XCTAssertFalse(quotient.isSignalingNaN)
        }
        
        for _ in 0..<100
        {
            let other = FloatType(randomDouble)
            var quotient = FloatType.signalingNaN / other
            XCTAssertTrue(quotient.isNaN)
            XCTAssertFalse(quotient.isSignalingNaN)
            
            quotient = other / FloatType.signalingNaN
            XCTAssertTrue(quotient.isNaN)
            XCTAssertFalse(quotient.isSignalingNaN)
        }
        
        for _ in 0..<100
        {
            let other = FloatType(urandom64)
            var quotient = FloatType.signalingNaN / other
            XCTAssertTrue(quotient.isNaN)
            XCTAssertFalse(quotient.isSignalingNaN)
            
            quotient = other / FloatType.signalingNaN
            XCTAssertTrue(quotient.isNaN)
            XCTAssertFalse(quotient.isSignalingNaN)
        }
        
        for _ in 0..<100
        {
            let other = FloatType(random64)
            var quotient = FloatType.signalingNaN / other
            XCTAssertTrue(quotient.isNaN)
            XCTAssertFalse(quotient.isSignalingNaN)
            
            quotient = other / FloatType.signalingNaN
            XCTAssertTrue(quotient.isNaN)
            XCTAssertFalse(quotient.isSignalingNaN)
        }
    }
    
    // -------------------------------------
    func test_dividing_infinity_by_infinity_is_NaN()
    {
        var quotient = FloatType.infinity / FloatType.infinity
        XCTAssertTrue(quotient.isNaN)
        
        quotient = FloatType.infinity / -FloatType.infinity
        XCTAssertTrue(quotient.isNaN)
        
        quotient = -FloatType.infinity / FloatType.infinity
        XCTAssertTrue(quotient.isNaN)
        
        quotient = -FloatType.infinity / -FloatType.infinity
        XCTAssertTrue(quotient.isNaN)
    }
    
    // -------------------------------------
    func test_dividing_finite_number_by_infinity_is_zero()
    {
        let testCases: [FloatType] =
        [
            .greatestFiniteMagnitude,
            -.greatestFiniteMagnitude,
            .leastNonzeroMagnitude,
            -.leastNonzeroMagnitude,
            .leastNonzeroMagnitude,
            -.leastNonzeroMagnitude,
        ]
        
        for x in testCases
        {
            var quotient = x / FloatType.infinity
            
            XCTAssertTrue(quotient.isZero)
            XCTAssertEqual(quotient.sign, x.sign)
            
            quotient = x / FloatType.infinity.negated
            
            XCTAssertTrue(quotient.isZero)
            XCTAssertNotEqual(quotient.sign, x.sign)
        }
        
        for _ in 0..<100
        {
            let x = FloatType(randomDouble)
            var quotient = x / FloatType.infinity
            
            XCTAssertTrue(quotient.isZero)
            XCTAssertEqual(quotient.sign, x.sign)
            
            quotient = x / FloatType.infinity.negated
            
            XCTAssertTrue(quotient.isZero)
            XCTAssertNotEqual(quotient.sign, x.sign)
        }
    }

    
    // -------------------------------------
    func test_dividing_zero_by_zero_is_NaN()
    {
        var quotient = FloatType.zero / FloatType.zero
        XCTAssertTrue(quotient.isNaN)
        
        quotient = FloatType.zero / -FloatType.zero
        XCTAssertTrue(quotient.isNaN)
        
        quotient = -FloatType.zero / FloatType.zero
        XCTAssertTrue(quotient.isNaN)
        
        quotient = -FloatType.zero / -FloatType.zero
        XCTAssertTrue(quotient.isNaN)
    }
    
    // -------------------------------------
    func test_dividing_zero_by_infinity_is_zero()
    {
        var quotient = FloatType.zero / FloatType.infinity
        XCTAssertTrue(quotient.isZero)
        XCTAssertFalse(quotient.isNegative)
        
        quotient = FloatType.zero / -FloatType.infinity
        XCTAssertTrue(quotient.isZero)
        XCTAssertTrue(quotient.isNegative)

        quotient = -FloatType.zero / FloatType.infinity
        XCTAssertTrue(quotient.isZero)
        XCTAssertTrue(quotient.isNegative)

        quotient = -FloatType.zero / -FloatType.infinity
        XCTAssertTrue(quotient.isZero)
        XCTAssertFalse(quotient.isNegative)
    }
    
    // -------------------------------------
    func test_dividing_zero_by_finite_number_is_zero()
    {
        let testCases: [FloatType] =
        [
            .greatestFiniteMagnitude,
            -.greatestFiniteMagnitude,
            .leastNonzeroMagnitude,
            -.leastNonzeroMagnitude,
            .leastNonzeroMagnitude,
            -.leastNonzeroMagnitude,
        ]
        
        for x in testCases
        {
            var quotient = FloatType.zero / x
            
            XCTAssertTrue(quotient.isZero)
            XCTAssertEqual(quotient.sign, x.sign)
            
            quotient = FloatType.zero.negated / x
            
            XCTAssertTrue(quotient.isZero)
            XCTAssertNotEqual(quotient.sign, x.sign)
        }
        
        for _ in 0..<100
        {
            let x = FloatType(randomDouble)
            var quotient = FloatType.zero / x
            
            XCTAssertTrue(quotient.isZero)
            XCTAssertEqual(quotient.sign, x.sign)
            
            quotient = FloatType.zero.negated / x
            
            XCTAssertTrue(quotient.isZero)
            XCTAssertNotEqual(quotient.sign, x.sign)
        }
    }
    
    // -------------------------------------
    func test_dividing_infinity_by_zero_is_infinity()
    {
        var quotient = FloatType.infinity / FloatType.zero
        XCTAssertTrue(quotient.isInfinite)
        XCTAssertFalse(quotient.isNegative)
        
        quotient = FloatType.infinity / -FloatType.zero
        XCTAssertTrue(quotient.isInfinite)
        XCTAssertTrue(quotient.isNegative)

        quotient = -FloatType.infinity / FloatType.zero
        XCTAssertTrue(quotient.isInfinite)
        XCTAssertTrue(quotient.isNegative)

        quotient = -FloatType.infinity / -FloatType.zero
        XCTAssertTrue(quotient.isInfinite)
        XCTAssertFalse(quotient.isNegative)
    }
    
    // -------------------------------------
    func test_dividing_finite_number_by_zero_is_infinity()
    {
        let testCases: [FloatType] =
        [
            .greatestFiniteMagnitude,
            -.greatestFiniteMagnitude,
            .leastNonzeroMagnitude,
            -.leastNonzeroMagnitude,
            .leastNonzeroMagnitude,
            -.leastNonzeroMagnitude,
        ]
        
        for x in testCases
        {
            var quotient = x / FloatType.zero
            
            XCTAssertTrue(quotient.isInfinite)
            XCTAssertEqual(quotient.sign, x.sign)
            
            quotient = x / FloatType.zero.negated
            
            XCTAssertTrue(quotient.isInfinite)
            XCTAssertNotEqual(quotient.sign, x.sign)
        }
        
        for _ in 0..<100
        {
            let x = FloatType(randomDouble)
            var quotient = x / FloatType.zero
            
            XCTAssertTrue(quotient.isInfinite)
            XCTAssertEqual(quotient.sign, x.sign)
            
            quotient = x / FloatType.zero.negated
            
            XCTAssertTrue(quotient.isInfinite)
            XCTAssertNotEqual(quotient.sign, x.sign)
        }
    }
    
    // -------------------------------------
    func test_dividing_finite_number_by_one_is_that_number()
    {
        let testCases: [FloatType] =
        [
            .greatestFiniteMagnitude,
            -.greatestFiniteMagnitude,
            .leastNonzeroMagnitude,
            -.leastNonzeroMagnitude,
            .leastNonzeroMagnitude,
            -.leastNonzeroMagnitude,
        ]
        
        for x in testCases
        {
            var quotient = x / 1
            let one: FloatType = 1
            XCTAssertEqual(one.exponent, 0)
            
            XCTAssertEqual(quotient, x)
            
            quotient = x / -1
            
            XCTAssertEqual(quotient, -x)
        }
        
        for _ in 0..<100
        {
            let x = FloatType(randomDouble)
            var quotient = x / 1
            
            XCTAssertEqual(quotient, x)
            
            quotient = x / -1
            
            XCTAssertEqual(quotient, -x)
        }
    }
    
    // -------------------------------------
    func test_division_of_nonzero_finite_numbers()
    {
        for _ in 0..<100
        {
            let x0 = randomDouble
            let y0 = randomDouble
            let expected = x0 / y0

            // We allow a tolerance because WideFloat has more precision than
            // Double
            let tolerance = Double(
                sign: .plus,
                exponent: expected.exponent - 52,
                significand: 1)
            
            let x = FloatType(x0)
            let y = FloatType(y0)
            
            let quotient = x / y
            
            XCTAssertLessThanOrEqual(
                abs(quotient.doubleValue - expected), tolerance
            )
        }
        
        for _ in 0..<100
        {
            let x0 = randomFloat80
            let y0 = randomFloat80
            let expected = x0 / y0

            let x = FloatType(x0)
            let y = FloatType(y0)
            
            let quotient = x / y
            
            XCTAssertEqual(quotient.float80Value, expected)
        }
    }
    
    // -------------------------------------
    func test_division_of_bigger_nonzero_finite_numbers()
    {
        typealias FloatType = WideFloat<UInt4096>
        
        for _ in 0..<100
        {
            let expMin = WExp.min.intValue / 2
            let expMax = WExp.max.intValue / 2
            let x = FloatType(
                significandBitPattern: UInt4096.random(in: ...),
                exponent: Int.random(in: expMin..<expMax)
            )
            let y = FloatType(
                significandBitPattern: UInt4096.random(in: ...),
                exponent: Int.random(
                    in: (-abs(x.exponent))..<(abs(x.exponent))
                ) - 1
            )
                        
            let q = x.divide_KnuthD(by: y)
            
            /*
             We can't just compare that q * y == x, because with any finite
             precision, in general they won't be, even if everything is working
             properly.  We also don't have an equivalent built-in type to
             compare it to as we do in the 64-bit case.  Instead, we have to
             check that q, the quotient, is different from the infinitely
             precise quotient by at most 1 in the least significant bit, but
             again, we don't have a built-in type capable of representing that
             to use.  Instead, we rely on multi-precision multiplication and
             subtraction working to test it indirectly.
             
             Given the true quotient, q̅, and our computed quotient, q, our
             computation of q is good if
             
                    -q.ulp <= q̅ - q <= +q.ulp

             Where q.ulp, is the magnitude of q's least significant bit. Given
             infinite precision division, q̅ = x / y
             
                    -q.ulp <= x / y - q <= +q.ulp
             
             Multiplying by y gives
             
                    -q.ulp * y <= x - q * y <= +q.ulp * y
             
             Which can be condensed to
             
                    x - q * y <= abs(q.ulp * y)
             
             This inequality is our test.
             
             Since we have unit tests for multiplication and subtraction, we
             can assume that they're working for the sake of this test.  If
             they're not, this test will fail, but so should those other tests.
             So if this test fails, the first thing should be to review and
             possibly revise the subtraction and multiplication tests before
             concluding that division isn't working.
             */
            let p = q * y
            let r = (x - p).magnitude
            let expected = y * q.ulp
            
            XCTAssertLessThanOrEqual(r, expected)
        }
    }

    // -------------------------------------
    func test_singleDigit_Newton_Raphson_multiplicative_inverse()
    {
        typealias FloatType = WideFloat<UInt64>
        
        for _ in 0..<100
        {
            let x = FloatType(
                significandBitPattern: urandom64,
                exponent: Int.random(in: WExp.min.intValue..<WExp.max.intValue)
            )
            assert(x.isNormalized)
            let xInv = x.multiplicativeInverse_NewtonRaphson
            
            let product = x * xInv
            XCTAssertLessThanOrEqual(FloatType(1) - product, 2 * product.ulp)
        }
    }

    // -------------------------------------
    func test_multidigit_Newton_Raphson_multiplicative_inverse()
    {
        typealias FloatType = WideFloat<UInt256>
        
        for _ in 0..<100
        {
            let x = FloatType(
                significandBitPattern: UInt256.random(in: ...),
                exponent: Int.random(in: WExp.min.intValue..<WExp.max.intValue)
            )
            assert(x.isNormalized)
            let xInv = x.multiplicativeInverse_NewtonRaphson
            
            let product = x * xInv
            XCTAssertLessThanOrEqual(FloatType(1) - product, 2 * product.ulp)
        }
    }

    // -------------------------------------
    func test_bigger_multidigit_Newton_Raphson_multiplicative_inverse()
    {
        typealias FloatType = WideFloat<UInt4096>
        
        for _ in 0..<100
        {
            let x = FloatType(
                significandBitPattern: UInt4096.random(in: ...),
                exponent: Int.random(in: WExp.min.intValue..<WExp.max.intValue)
            )
            assert(x.isNormalized)
            let xInv = x.multiplicativeInverse_NewtonRaphson
            
            let product = x * xInv
            XCTAssertLessThanOrEqual(FloatType(1) - product, product.ulp)
        }
    }
    
    // -------------------------------------
    func test_singleDigit_KnuthD_multiplicative_inverse()
    {
        typealias FloatType = WideFloat<UInt64>
        
        for _ in 0..<100
        {
            let x = FloatType(
                significandBitPattern: urandom64,
                exponent: Int.random(in: WExp.min.intValue..<WExp.max.intValue)
            )
            assert(x.isNormalized)
            let xInv = x.multiplicativeInverse_KnuthD
            
            let product = x * xInv
            XCTAssertLessThanOrEqual(FloatType(1) - product, product.ulp)
        }
    }
    
    // -------------------------------------
    func test_bigger_multidigit_KnuthD_multiplicative_inverse()
    {
        typealias FloatType = WideFloat<UInt4096>
        
        for _ in 0..<100
        {
            let x = FloatType(
                significandBitPattern: UInt4096.random(in: ...),
                exponent: Int.random(in: WExp.min.intValue..<WExp.max.intValue)
            )
            assert(x.isNormalized)
            let xInv = x.multiplicativeInverse_KnuthD
            
            let product = x * xInv
            XCTAssertLessThanOrEqual(FloatType(1) - product, product.ulp)
        }
    }

    // -------------------------------------
    func test_bigger_multidigit_Knuth_multiplicative_inverse()
    {
        typealias FloatType = WideFloat<UInt4096>
        
        for _ in 0..<100
        {
            let x = FloatType(
                significandBitPattern: UInt4096.random(in: ...),
                exponent: Int.random(in: WExp.min.intValue..<WExp.max.intValue)
            )
            assert(x.isNormalized)
            let xInv = x.multiplicativeInverse_KnuthD
            
            let product = x * xInv
            XCTAssertLessThanOrEqual(FloatType(1) - product, product.ulp)
        }
    }
}
