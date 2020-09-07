//
//  WideUInt_Codable_UnitTests.swift
//
//
//  Created by Chip Jarred on 8/17/20.
//

import XCTest
@testable import BigMath

// -------------------------------------
class WideUInt_Codable_UnitTests: XCTestCase
{
    typealias Digit = UInt32
    typealias SignedDigit = UInt32
    typealias IntType = WideUInt<Digit>
    var random64: UInt64 { return UInt64.random(in: 0...UInt64.max) }

    // -------------------------------------
    func test_can_decode_encoded_WideUInt()
    {

        for _ in 0..<100
        {
            let x64 = random64
            let x = IntType(x64)
            
            do
            {
                let xData = try JSONEncoder().encode(x)
                do
                {
                    let y = try JSONDecoder().decode(IntType.self, from: xData)
                    XCTAssertEqual(x, y)
                }
                catch
                {
                    XCTFail(
                        "JSONDecoder threw exception for x = \(x): "
                        + "\(error.localizedDescription)"
                    )
                }
            }
            catch
            {
                XCTFail(
                    "JSONEncoder threw exception for x = \(x): "
                    + "\(error.localizedDescription)"
                )
            }
        }
    }
}
