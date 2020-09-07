/*
Copyright 2020 Chip Jarred

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
 so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

import XCTest
@testable import BigMath

// -------------------------------------
class WideInt_Codable_UnitTests: XCTestCase
{
    typealias Digit = UInt32
    typealias IntType = WideInt<Digit>
    var random64: Int64 { return Int64.random(in: Int64.min...Int64.max) }

    // -------------------------------------
    func test_can_decode_encoded_WideInt()
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
