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

import Foundation

// -------------------------------------
internal struct PowerOf10Ladder
{
    // -------------------------------------
    // TODO: Replace this with precomputed values.  Will need to be conditionally
    // compiled to take into account 32-bit UInts on some platforms.
    static let uintLadder: [(value: UInt, decimalExponent: Int)] =
    {
        var decExp: Int = 1
        var val: UInt = 10
        
        var pairs = [(value: UInt, decimalExponent: Int)]()
        pairs.reserveCapacity(Int(log10(Double(UInt.max))))
        
        while true
        {
            let temp = val &* 10
            if temp < val { break }
            val = temp
            decExp += 1
            pairs.append((val, decExp))
        }
        
        return pairs
    }()

    // -------------------------------------
    fileprivate static func makePowerOf10Ladder<T: WideDigit>()
        -> [(value: WideFloat<T>, decimalExponent: Int)]
    {
        typealias FloatType = WideFloat<T>
        
        var pairs = [(value: FloatType, decimalExponent: Int)]()
        pairs.reserveCapacity(
            uintLadder.count * (T.bitWidth / UInt.bitWidth)
        )
        
        // We start by making a power of 10 ladder using the UInt version
        // to quickly get up to 64-bit powers of 10.
        for (uintVal, decExp) in uintLadder {
            pairs.append((FloatType(uintVal), decExp))
        }
        
        let lastUIntPowerOf10 = uintLadder.last!
        
        // Now we build up the power of 10 ladder all the way up for FloatType
        let ten = T(10)
        var val = T(lastUIntPowerOf10.value)
        var decExp = lastUIntPowerOf10.decimalExponent
        while true
        {
            let temp = val &* ten
            if temp < val { break }
            val = temp
            decExp += 1
            pairs.append((FloatType(val), decExp))
        }
        
        return pairs
    }

    // -------------------------------------
    /// Maps WideFloat type to its corresponding power of 10 ladder
    fileprivate static var wFloatPowerOf10Ladders: [Int: UnsafeRawBufferPointer]
        = [:]

    // -------------------------------------
    static internal func getPowerOf10LadderPtr<T>(for: T.Type)
        -> UnsafeBufferPointer<(value: WideFloat<T>, decimalExponent: Int)>
    {
        typealias PairType = (value: WideFloat<T>, decimalExponent: Int)
        
        let sigSize = MemoryLayout<T>.size
        
        // If we already have a ladder made for this type, return it
        if let ladder = wFloatPowerOf10Ladders[sigSize] {
            return ladder.bindMemory(to: PairType.self)
        }
        
        // Otherwise make one, cache it for later use, and return it
        let ladderArray: [PairType] = makePowerOf10Ladder()
        return ladderArray.withUnsafeBufferPointer
        {
            let newLadder =
                UnsafeMutableBufferPointer<PairType>.allocate(capacity: $0.count)
            newLadder.initialize(from: $0)
            let ladderPtr = UnsafeBufferPointer(newLadder)
            wFloatPowerOf10Ladders[sigSize] = UnsafeRawBufferPointer(ladderPtr)
            return ladderPtr
        }
    }
}
