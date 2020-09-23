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

// --------------------------------------
public extension String.StringInterpolation
{
    // --------------------------------------
    internal mutating func appendInterpolation(binary buf: UIntBuffer)
    {
        for digit in buf.reversed() {
            appendInterpolation(binary: digit)
        }
    }
    
    // --------------------------------------
    internal mutating func appendInterpolation(binary buf: MutableUIntBuffer) {
        appendInterpolation(binary: buf.immutable)
    }

    // --------------------------------------
    mutating func appendInterpolation<T: FixedWidthInteger>(binary x: T)
    {
        var s = ""
        for i in (0..<T.bitWidth).reversed()
        {
            let bit = (x >> i) & 1
            s.append(bit == 1 ? "1" : "0")
        }
        appendLiteral(s)
    }
}
