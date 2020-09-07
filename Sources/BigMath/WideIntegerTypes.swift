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

// MARK:- Unsigned Integers
// -------------------------------------
public struct UInt128: WideUnsignedInteger
{
    public typealias Digit = UInt64
    
    public var wrapped: Wrapped

    public static let zero: Self = Self(wrapped: Wrapped())
    public static let one: Self = Self(wrapped: Wrapped(1))
    public static let min: Self = Self(wrapped: Wrapped.min)
    public static let max: Self = Self(wrapped: Wrapped.max)

    @inlinable public init(wrapped: Wrapped) { self.wrapped = wrapped }
}

// -------------------------------------
public struct UInt256: WideUnsignedInteger
{
    public typealias Digit = UInt128
    
    public var wrapped: Wrapped

    public static let zero: Self = Self(wrapped: Wrapped())
    public static let one: Self = Self(wrapped: Wrapped(1))
    public static let min: Self = Self(wrapped: Wrapped.min)
    public static let max: Self = Self(wrapped: Wrapped.max)

    @inlinable public init(wrapped: Wrapped) { self.wrapped = wrapped }
}

// -------------------------------------
public struct UInt512: WideUnsignedInteger
{
    public typealias Digit = UInt256
    
    public var wrapped: Wrapped

    public static let zero: Self = Self(wrapped: Wrapped())
    public static let one: Self = Self(wrapped: Wrapped(1))
    public static let min: Self = Self(wrapped: Wrapped.min)
    public static let max: Self = Self(wrapped: Wrapped.max)

    @inlinable public init(wrapped: Wrapped) { self.wrapped = wrapped }
}

// -------------------------------------
public struct UInt1024: WideUnsignedInteger
{
    public typealias Digit = UInt512
    
    public var wrapped: Wrapped

    public static let zero: Self = Self(wrapped: Wrapped())
    public static let one: Self = Self(wrapped: Wrapped(1))
    public static let min: Self = Self(wrapped: Wrapped.min)
    public static let max: Self = Self(wrapped: Wrapped.max)

    @inlinable public init(wrapped: Wrapped) { self.wrapped = wrapped }
}

// -------------------------------------
public struct UInt2048: WideUnsignedInteger
{
    public typealias Digit = UInt1024
    
    public var wrapped: Wrapped

    public static let zero: Self = Self(wrapped: Wrapped())
    public static let one: Self = Self(wrapped: Wrapped(1))
    public static let min: Self = Self(wrapped: Wrapped.min)
    public static let max: Self = Self(wrapped: Wrapped.max)

    @inlinable public init(wrapped: Wrapped) { self.wrapped = wrapped }
}

// -------------------------------------
public struct UInt4096: WideUnsignedInteger
{
    public typealias Digit = UInt2048
    
    public var wrapped: Wrapped

    public static let zero: Self = Self(wrapped: Wrapped())
    public static let one: Self = Self(wrapped: Wrapped(1))
    public static let min: Self = Self(wrapped: Wrapped.min)
    public static let max: Self = Self(wrapped: Wrapped.max)

    @inlinable public init(wrapped: Wrapped) { self.wrapped = wrapped }
}

// MARK:- Signed Integers
// -------------------------------------
public struct Int128: WideSignedInteger
{
    public typealias Digit = UInt64
    public typealias Magnitude = UInt128
    
    public var wrapped: Wrapped

    public static let zero: Self = Self(wrapped: Wrapped())
    public static let one: Self = Self(wrapped: Wrapped(1))
    public static let min: Self = Self(wrapped: Wrapped.min)
    public static let max: Self = Self(wrapped: Wrapped.max)

    @inlinable public init(wrapped: Wrapped) { self.wrapped = wrapped }
}

// -------------------------------------
public struct Int256: WideSignedInteger
{
    public typealias Digit = UInt128
    public typealias Magnitude = UInt256
    
    public var wrapped: Wrapped

    public static let zero: Self = Self(wrapped: Wrapped())
    public static let one: Self = Self(wrapped: Wrapped(1))
    public static let min: Self = Self(wrapped: Wrapped.min)
    public static let max: Self = Self(wrapped: Wrapped.max)

    @inlinable public init(wrapped: Wrapped) { self.wrapped = wrapped }
}

// -------------------------------------
public struct Int512: WideSignedInteger
{
    public typealias Digit = UInt256
    public typealias Magnitude = UInt512
    
    public var wrapped: Wrapped

    public static let zero: Self = Self(wrapped: Wrapped())
    public static let one: Self = Self(wrapped: Wrapped(1))
    public static let min: Self = Self(wrapped: Wrapped.min)
    public static let max: Self = Self(wrapped: Wrapped.max)

    @inlinable public init(wrapped: Wrapped) { self.wrapped = wrapped }
}

// -------------------------------------
public struct Int1024: WideSignedInteger
{
    public typealias Digit = UInt512
    public typealias Magnitude = UInt1024
    
    public var wrapped: Wrapped

    public static let zero: Self = Self(wrapped: Wrapped())
    public static let one: Self = Self(wrapped: Wrapped(1))
    public static let min: Self = Self(wrapped: Wrapped.min)
    public static let max: Self = Self(wrapped: Wrapped.max)

    @inlinable public init(wrapped: Wrapped) { self.wrapped = wrapped }
}

// -------------------------------------
public struct Int2048: WideSignedInteger
{
    public typealias Digit = UInt1024
    public typealias Magnitude = UInt2048
    
    public var wrapped: Wrapped

    public static let zero: Self = Self(wrapped: Wrapped())
    public static let one: Self = Self(wrapped: Wrapped(1))
    public static let min: Self = Self(wrapped: Wrapped.min)
    public static let max: Self = Self(wrapped: Wrapped.max)

    @inlinable public init(wrapped: Wrapped) { self.wrapped = wrapped }
}

// -------------------------------------
public struct Int4096: WideSignedInteger
{
    public typealias Digit = UInt2048
    public typealias Magnitude = UInt4096
    
    public var wrapped: Wrapped

    public static let zero: Self = Self(wrapped: Wrapped())
    public static let one: Self = Self(wrapped: Wrapped(1))
    public static let min: Self = Self(wrapped: Wrapped.min)
    public static let max: Self = Self(wrapped: Wrapped.max)

    @inlinable public init(wrapped: Wrapped) { self.wrapped = wrapped }
}
