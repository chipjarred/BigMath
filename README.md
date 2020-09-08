# BigMath

*Coming soon: Big floating point types*

My motivation in creating this package is that for one of my personal projects, I have a need for  floating point types with more precision than the `Float80` Swift-native type, and after trying some of the popular multiprecision Swift packages already available, I quickly concluded that they were much, much too slow.  Much of their sluggishness has to do with the way they store their digits, or "limbs," as some people prefer to call them.  They put them in an array, which means lots of dynamic memory allocation, which is slow.  Many of them don't even bother to make their API `@inlinable`, which wouldn't solve all the problems, but would avoid a lot of protocol/generic witness table thunking and unnecesary function call overhead.   To be fair, they also provide dynamic *arbitrary* precision, which means they can be used, for example, to find the millionth digit of *π*, or find the next prime number after the largest discovered so far. 

I don't need that.  I'm using optimization methods on computation graphs that contain upwards of a million nodes, and the optimization process requires potentially millions of iterations through the graph (no it's not a neural network  - if it were, I'd be using the GPU or cloud - sadly the graph isn't easily parallelized).  To give some perspective, when I use `Float80`, I can get about 10 iterations per second.  The first multi-precision library I tried had no output after a couple of hours, at which point I went to bed.  When I got up in the morning, it still hadn't even finished the first iteration.   Of course I fully expect multiprecision to be slower than using native types, but it I do insist that it be fast enough for me to get results before the heat death of the universe.  I have no idea how long the others would have taken since I aborted each trial after they exceeded 30 minutes without finishing even the first iteration.  Incidentally, one of the types I tried was Apple's `Foundation` type, `Decimal`.  Its performance was just as bad as any of the libraries I tried, though at least they seem to actually store the digits directly in the struct.  I was a bit baffled by where the exponent is stored  - in one of its eight 16-bit digits that the debugger says form its mantissa, maybe?  

I need *fast* types.  I also need high precision, but I don't need arbitrary precision.   I'm prefectly fine with being limited to a choice made a compile time, just as one does with the choice of `Float`, `Double`, or `Float80`.   That means I can take a different approach than most other frameworks seem to.

## So where are the floating point types?

In short, I'm not there *yet*.

I'm working toward floating point types, but those  have to be built on a fast multiprecision integer types, so that the floating point types have a solid foundation.  Although I expect to do some optimizing, the integer types are more or less complete now, and before moving on to the floating point, I wanted to publish them to GitHub. In the process I also did a lot of project clean-up, because it had remnants of tons of experimentation, many of which were wrong turns, so I just decided to make a whole new package. 

## What's included

I've chosen to call my big integers "wide integers", because "big integer" has become a little too associated with integers that contain arbitrary numbers of digits.  A "wide integer" is just like a Swift-native integer... just wider.  They have a fixed number of bits that are contained directly in the integer itself.  Because their sizes are known at compile time, the compiler can do a lot of optimizations it can't do with array-based implementations.

### `WideUInt<T>`
The core type that everything is built on is a generic `struct`, `WideUInt`, that contains two "digits", which may themselves be `WideUInt`s.   This allows doubling the number of bits the integer contains by just composing bigger types from smaller ones.  A key feature is that the digits are stored directly in the struct, not off in some array off some place else in memory.  This means your local variables of these types are stored *on the runtime stack* (at least they are, if the compiler doesn't decide to box them - I love Swift, but there are times I wish it had the transparency of C).  This makes them unsuitable for truly gargantuan integer sizes, because one could eat up the runtime stack very quickly, but for reasonable sizes, it gives them good data locality.  The runtime stack is almost always hot in the CPU cache.  It also means that the memory allocation for one doesn't involve any heap allocation.  It's just decrementing the stack pointer register to make room for them in the current stack frame.  That's exactly how the built-in types work, and that's part of their speed.

Obviously `WideUInt` is an *unsigned* integer type, and conforms `FixedWidthInteger`, and `UnsignedInteger`, just as Swift-native unsigned integer types.

The `T` parameter is the "digit" type, which can be `UInt32`, `UInt64`, `UInt`, or any *unsigned* integer type provided by this package.  Although a `UInt128` type is provided by this package as well, you can build your own like so:

    typealias MyUInt128 = WideUInt<UInt64>
    
And then create 256-bit integer type from it:
    
    typealias MyUInt256 = WideUInt<MyUInt128>

*You should be aware that composing larger and larger types does have a dramatic impact on release build time.  Their nested, heavily inlined structure really exercises the Swift compiler's optimizers.   I recommend you build up to what you've empirically determined you need, and only build larger types when you've determined that you actually need them*

### `WideInt<T>`

`WideInt` is the *signed* integer type.  It conforms to `FixedWidthInteger`, and `SignedInteger`.  You build one up just like you do `WideUInt`.   And when I say, "just like", I mean, "just like."  They are built of *unsigned* digits, just like `WideUInt`.  So if you want to build your own wide signed integers, you will build unsigned integers to use as the digits:

    typealias MyInt128 = WideInt<UInt64>
    typealias MyInt256 = WideInt<MyUInt128>

### Wrapped Integers

`WideInt` and `WideUInt` can be used directly as wide integer types, but one of the drawbacks of the generic approach is that when you get error messages, they tend to expand out the generic type names, often duplicating them with "aka" references for `typealias` names, which adds a lot of visual noise to error messages, making them hard to read.   I wanted to provide a way to make types that are built on `WideInt` and `WideUInt`, but don't expose all that generic type expansion.  

That's where the `WrappedInteger` protocol comes in, and actually you may find it useful even if you don't need wide integers. It allows you to declare a type that wraps any `FixedWidthInteger` you like, and the wrapped type itself will conform to `FixedWidthInteger`.   So let's say you want provide an ASCII type.  You could wrap `UInt8` in a struct that conforms to `WrappedInteger` , thus making it a distinct type from `UInt8`, though it still has a memory footprint of 1 byte.  That use is similar to `RawRepresentable`, except `RawRepresentable` is intended for values whose domain is a subset of the `RawValue`, whereas `WrappedInteger` intends for the full domain of the wrapped type to be used, and `RawRepresentable` doesn't automatically give the conforming type itself the capabilities of the `RawValue` type.

Useful though the protocol might be in other contexts, the motiviation for creating `WrappedInteger` was to create cleanly typed wide integer types that show up distinctly in error messages.  I provide several of those that are ready for use.  They use sub-protocols of `WrappedInteger`:  `WideUnsignedInteger` and `WideSignedInteger`.

- `WideUnsignedInteger`
    - `UInt128`
    - `UInt256`
    - `UInt512`
    - `UInt1024`
    - `UInt2048`
    - `UInt4096`

- `WideSignedInteger`
    - `Int128`
    - `Int256`
    - `Int512`
    - `Int1024`
    - `Int2048`
    - `Int4096`

Any of the `WideUnsignedInteger`s can be used as digits for `WideInt`, and `WideUInt`, and in fact, that's exactly how they are built.  If you want to create your own, there's a small amount of boilerplate, but it's fairly easy.   Let's say you want to create `UInt8192` and `Int8192`.  This is the code to make that happen:

    public struct UInt8192: WideUnsignedInteger
    {
        public typealias Digit = UInt4096
        
        public var wrapped: Wrapped

        public static let zero: Self = Self(wrapped: Wrapped())
        public static let one: Self = Self(wrapped: Wrapped(1))
        public static let min: Self = Self(wrapped: Wrapped.min)
        public static let max: Self = Self(wrapped: Wrapped.max)

        @inlinable public init(wrapped: Wrapped) { self.wrapped = wrapped }
    }

    public struct Int8192: WideSignedInteger
    {
        public typealias Digit = UInt4096
        public typealias Magnitude = UInt8192
        
        public var wrapped: Wrapped

        public static let zero: Self = Self(wrapped: Wrapped())
        public static let one: Self = Self(wrapped: Wrapped(1))
        public static let min: Self = Self(wrapped: Wrapped.min)
        public static let max: Self = Self(wrapped: Wrapped.max)

        @inlinable public init(wrapped: Wrapped) { self.wrapped = wrapped }
    }

Note that the signed type has to specify the unsigned type for it's `Magnitude`, but they both use the same `Digit` type.
That's it.  The protocol extensions for `WideUnsignedInteger`, and `WideSignedInteger` make the rest happen for you.  You can build the unsigned type without creating the signed type, but the signed type will always need the unsigned type.

## Performance

I haven't done a lot of real benchmarking yet, though I have done informal comparisons experiments on the performance for the smaller types (`UInt128`, and `UInt256`) that are promising.  Real benchmarking is a to-do, and an important one since performance is the whole reason for writing my own BigMath library anyway.  Plus it would be helpful for anyone considering using this package to see some actual numbers.

The extensions for these protocols make heavy use of `@inlinable`, as do `WideInt` and `WideUInt`.  That means the compiler can see their implementation, and even if it chooses not to actually inline them, it should generate specialized functions that can be called without the protocol/generic witness table thunking overhead that would otherwise be required.

### Multiplication
The current default algorithm for multiplication is the "school book" method, which is O(*n*^2), but has really good CPU cache characteristics.  

There is a working version of Karatsuba multiplication available for `WideUInt`.  Karatsuba is O(*n*^log2 3) which is theoretically faster than schoolbook, but its divide and conquer approach makes it less cache-friendly.   As a result its superior complexity advantages only appear for large numbers of digits.   For that reason most Karatsuba implementations, including mine, have a threshold for the number of digits, below which it fails over to school book.  After some experimentation, I've set mine to 128 digits (which is based on results on one particular 64-bit Mac, so hardly the best choice for every machine this package might run on.)

The tests I've run to determine where the cross-over in performance is indicate that it's somewhere above 16384 bits integers.  The test results are below, and you can see that at 16384, school book's superior cache characteristics start to lose out to its *n*^2 complexity, so not only does it have a marked impact on its performance, but the difference between it and Karatsuba finally begins to close.  I suspect that at 32768 bits, Karatsuba would start to win out, however, the increased build-times when including integers that large became intolerable, which is fine for me - I don't need integers *that* large, but I do wish I could have actually seen the cross-over.

These tests consisted of randomly generating 100,000 multilicand-multiplier pairs and doing full width multiplication (meaning the result is twice as wide as the operands).  The run times in the following table do not include generation of these pairs.  One algorithm is timed multiplying all of the pairs before  the second algorithm is timed multiplying the same pairs.  Both algorithms are tested on a single type before testing them on the next type.

Time in seconds to run algorithm 100,000 times :
| Integer Type | School Book | Karatsuba |
|     :--:     |            --: |     --: |
|    `UInt128`   |      0.09    |   0.116  |
|    `UInt256`   |      0.14    |   0.341  |
|    `UInt512`   |      0.27    |   0.690  |
|   `UInt1024`   |     0.534    |   1.401  |
|   `UInt2048`   |     1.142    |   2.980  |
|   `UInt4096`   |     2.589    |   6.446  |
|   `UInt8192`   |     6.363    |  14.333  |
|  `UInt16384`   |    50.782    |  72.539  |

Another thing to note is that up to `UInt8192` in these tests, Karatsuba is actually just calling the school book method.  On first blush, one would expect that their performance should be identical, and yet Karatsuba's failing over to school book is markedly slower than just calling school book directly.   The reason for this is that school book is a completely iterative algorithm, and easily inlinable.  Karatsuba, on the other hand, is recursive, and not tail recursive which one could translate into an iterative version fairly easily.  It works by doing 3 smaller multiplications and combining the results.   That recursive nature is a problem for inlining, so even the top-level call to that function is a real, honest-to-God function call.  That overhead accounts for the performance difference.  If I can figure out a clever way to do Karatsuba iteratively without doing any heap allocations, I will implement it, and revisit these tests.

I should also mention that I only created the types larger than 4096 bits for these tests.  They have been disabled to keep build times reasonable.

### Division
Division uses Donald Knuth's "Algorthm D" from *The Art of Computer Programming*, which assuming the divisor and dividend are similar lengths, as typically they are in this package, is O(*n*^2). 

At least two of the libraries I looked at claimed that their shift-subtract algorithm was O(*n*), but on closer inspection it definitely isn't. Actually both had identical code and comments, so either one borrowed from the other or they both borrowed from a common source.  Both the shift and subtract are each O(*n*) and they are in an O(*n*) loop, making the algorithm O(*n*^2) as well, and inefficiently so, as they have to process each bit individually, whereas Knuth's algorithm does whole digit arithmetic, which for my implementation translates to native 64-bit integer arithmetic instructions (or 32-bit if you're still a on a 32-bit machine).  Bit level shift and subtract is a reasonable hardware implementation, but I don't see how it could be a good software one.  

I've implemented the shift-subtract division algorithm to benchmark it, and though I suspected it was going to be slower than Knuth's, and so was a little biased, I nonetheless did my best to give it every speed advantage I could think of.   After all, I had given a lot of care optimizing Knuth's algorithm.  It wouldn't be a fair test if I hadn't done the same for shift-subtract.  I ran the test, which was full-width division, meaning the dividend is twice as wide as the divisor, on 128-bit, 256-bit, 512-bit, 1024-bit, 2048-bit and 4096-bit unsigned integer divisors.  For each test, 100,000 randomly generated dividends and divisors were created to be used in the tests prior to starting the clock, and both algorithms divided the same dividends and divisors in the same order.   The results are in, and they speak for themselves:

Time in seconds to run algorithm 100,000 times :
| Integer Type | Shift-Subtract | Knuth D |
|     :--:     |            --: |     --: |
|    `UInt128`   |      13.63     |   0.55  |
|    `UInt256`   |      27.47     |   0.93  |
|    `UInt512`   |      55.57     |   1.66  |
|   `UInt1024`   |     114.69     |   3.15  |
|   `UInt2048`   |     243.78     |   6.40  |
|   `UInt4096`   |     543.61     |  13.40  |


### Memory Allocation
Importantly, the algorithm implementations in this package do not allocate anything from the heap.  Where they need scratch buffers for intermediate computation, they are allocated on the stack.


