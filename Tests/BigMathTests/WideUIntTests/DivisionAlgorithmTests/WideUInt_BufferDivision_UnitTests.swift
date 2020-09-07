//
//  WideUInt_BufferDivision_UnitTests.swift
//  
//
//  Created by Chip Jarred on 8/24/20.
//

import XCTest
@testable import BigMath

// -------------------------------------
class WideUInt_BufferDivision_UnitTests: XCTestCase
{
    typealias Digit = UInt
    typealias IntType = WideUInt<Digit>
    typealias BigIntType = WideUInt<IntType>

    var randomDigit: Digit { Digit.random(in: 0...Digit.max) }
    var randomInt: IntType { IntType(low: randomDigit, high: randomDigit) }
    var randomBigInt: BigIntType { BigIntType(low: randomInt, high: randomInt) }
    var random64: UInt64 { UInt64.random(in: 0...UInt64.max) }
    
    // -------------------------------------
    func random(lessThan x: IntType) -> IntType
    {
        let xMask = IntType.max >> x.leadingZeroBitCount
        var y: IntType
        
        /*
         Can't use % (modulus) because we're testing division and modulus for
         IntType, so we can't rely on those operations working correctly (if we
         could, we'd wouldn't be testing them)
         */
        while true
        {
            y = randomInt & xMask
            if y < x { return y }
        }
    }
    
    // -------------------------------------
    func test_divideBufferByDigit()
    {
        for _ in 0...1
        {
            let (quotient, divisor): (IntType, IntType) =
            {
                var q: IntType
                var d: IntType
                
                repeat { (q, d) = (randomInt, IntType(low: randomDigit)) }
                while q < d
                
                return (q, d)
            }()
            let remainder = random(lessThan: divisor)
            
            var dividend = BigIntType(quotient.multipliedFullWidth(by: divisor))
            dividend &+= BigIntType(low: remainder)
            
            var q = BigIntType()
            
            let r = q.withMutableBuffer
            { qBuf in
                dividend.withBuffer
                { dBuf in
                    divide(buffer: dBuf, by: divisor.low, result: qBuf)
                }
            }
            
            XCTAssertEqual(q.low, quotient)
            XCTAssertEqual(r, remainder.low)
        }
    }
}
