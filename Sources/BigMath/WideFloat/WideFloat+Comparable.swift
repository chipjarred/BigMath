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

infix operator <=> : ComparisonPrecedence
// -------------------------------------
extension WideFloat: Comparable
{
    // -------------------------------------
    @inlinable
    public static func == (left: Self, right: Self) -> Bool  {
        return (left <=> right) == .orderedSame
    }
    
    // -------------------------------------
    @inlinable
    public static func != (left: Self, right: Self) -> Bool
    {
        switch left <=> right
        {
            case .unordered, .orderedSame: return false
            default: return true
        }
    }
    
    // -------------------------------------
    @inlinable
    public static func < (left: Self, right: Self) -> Bool  {
        return (left <=> right) == .orderedAscending
    }
    
    // -------------------------------------
    @inlinable
    public static func > (left: Self, right: Self) -> Bool  {
        return (left <=> right) == .orderedDescending
    }
    
    // -------------------------------------
    @inlinable
    public static func <= (left: Self, right: Self) -> Bool
    {
        switch left <=> right
        {
            case .unordered, .orderedDescending: return false
            default: return true
        }
    }
    
    // -------------------------------------
    @inlinable
    public static func >= (left: Self, right: Self) -> Bool
    {
        switch left <=> right
        {
            case .unordered, .orderedAscending: return false
            default: return true
        }
    }
    
    // -------------------------------------
    public enum ComparisonResult: Int
    {
        case orderedAscending = -1
        case orderedSame = 0
        case orderedDescending = 1
        case unordered = 2
        
        @usableFromInline @inline(__always) internal init(
            _ x: FloatingPointBuffer.ComparisonResult)
        {
            self.init(rawValue: x.rawValue)!
        }
    }

    // -------------------------------------
    @inlinable
    public static func <=> (left: Self, right: Self) -> ComparisonResult
    {
        let leftBuf = left.floatBuffer()
        let rightBuf = right.floatBuffer()
        
        return Self.ComparisonResult(leftBuf <=> rightBuf)
    }
}
