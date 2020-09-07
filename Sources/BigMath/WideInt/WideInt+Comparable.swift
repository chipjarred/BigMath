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
infix operator <=> : ComparisonPrecedence

extension WideInt: Comparable
{
    // -------------------------------------
    @inlinable
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return (lhs <=> rhs) == .orderedSame
    }
    
    // -------------------------------------
    @inlinable
    public static func < (lhs: Self, rhs: Self) -> Bool {
        return (lhs <=> rhs) == .orderedAscending
    }
    
    // -------------------------------------
    @inlinable
    public static func > (lhs: Self, rhs: Self) -> Bool {
        return (lhs <=> rhs) == .orderedDescending
    }

    // -------------------------------------
    @inlinable
    public static func <= (lhs: Self, rhs: Self) -> Bool {
        return !(lhs > rhs)
    }
    
    // -------------------------------------
    @inlinable
    public static func >= (lhs: Self, rhs: Self) -> Bool {
        return !(lhs < rhs)
    }
    
    // -------------------------------------
    @inlinable
    public static func <=> (lhs: Self, rhs: Self) -> ComparisonResult
    {
        let leftIsNegative = lhs.bitPattern.signBit
        let rightIsNegative = rhs.bitPattern.signBit
        
        if leftIsNegative
        {
            if rightIsNegative
            { // Both are negative
                return lhs.bitPattern <=> rhs.bitPattern
            }
            else { return .orderedAscending }
        }
        else if rightIsNegative { return .orderedDescending }
        
        // Both are non-negative
        return lhs.bitPattern <=> rhs.bitPattern
    }
}
