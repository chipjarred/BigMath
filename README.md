# BigMath

*Coming soon: Big floating point types*

## OMG! You did what?

After numerical correctness, speed is by far the most important requirement for this library.    To that end, I have been forced to use techniques that would be frowned on by the Swift community and maybe by Apple.  And to be honest, I don't advocate them either... unless you really need them.   I make heavy use of `@inline(__always)`, which is not kosher Swift.   I often have to go out of my way to side-step Swift's usual safety features because they slow down my code.  I use bit twiddling and computation to replace conditional branches where I can.  Basically for this library, I'll do anything I can think of to save a few clock cycles.

These have made a huge difference in performance, but there still remain some thorns in my side.   Profiling reveals that protocol and generic thunking remain noticeable drains on performance which I expected to be alleviated by inlining.  In truth the inlining does help, but it doesn't eliminate all of the thunking overhead.  Another is that I often am forced to initialize a potentially large numeric type (perhaps thousands of bits) before I can write bytes to it, which I'm doing to initialize it.  So I essentially have to intialize it twice.   The inability of generics to have stored static properties means that values that ought to be stored as constants, are in fact initialized on every use, which is ridiculous for a property like `.zero`, or `.pi`.  Also Swift still makes copies of instances of these potentially large numeric types more often than should be necessary.  

The remaining performance drains may require me shift away from generics, and unfortuantely use separate and distinct types for every single size of integer I want, with the code duplication that goes with it.  Protocol extensions can help alleviate that, but protocol thunking is one of the problems I'm trying to overcome.

That said, I'm getting noticeably better performance than any of the available Swift multiprecision libraries I've tried, so the effort and "breaking the rules" is paying off.   It could be that these techniques might affect AppStore acceptance.  That isn't an issue for my use case, but it could be for you.

To anyone who thinks these sorts of techniques can't possibly result in that much better performance, take a look at the Performance section below for integer multiplication and division.  I re-ran the comparsion tests, and show the original measurements along side the new ones.

## Motivation

My motivation in creating this package is that for one of my personal projects, I have a need for  floating point types with more precision than the `Float80` Swift-native type, and after trying some of the popular multiprecision Swift packages already available, I quickly concluded that they were much, much too slow.  Much of their sluggishness has to do with the way they store their digits, or "limbs," as some people prefer to call them.  They put them in an array, which means lots of dynamic memory allocation, which is slow.  Many of them don't even bother to make their API `@inlinable`, which wouldn't solve all the problems, but would avoid a lot of protocol/generic witness table thunking and unnecesary function call overhead.   To be fair, they also provide dynamic *arbitrary* precision, which means they can be used, for example, to find the millionth digit of *π*, or find the next prime number after the largest discovered so far. 

I don't need that.  I'm using optimization methods on computation graphs that contain upwards of a million nodes, and the optimization process requires potentially millions of iterations through the graph (no it's not a neural network  - if it were, I'd be using the GPU or cloud - sadly the graph isn't easily parallelized).  To give some perspective, when I use `Float80`, I can get about 10 iterations per second.  The first multi-precision library I tried had no output after a couple of hours, at which point I went to bed.  When I got up in the morning, it still hadn't even finished the first iteration.   Of course I fully expect multiprecision to be slower than using native types, but I do insist that it be fast enough for me to get results before the heat death of the universe.  I have no idea how long the others would have taken since I aborted each trial after they exceeded 30 minutes without finishing even the first iteration.  Incidentally, one of the types I tried was Apple's `Foundation` type, `Decimal`.  Its performance was just as bad as any of the libraries I tried, though at least they seem to actually store the digits directly in the struct.  I was a bit baffled by where the exponent is stored  - in one of its eight 16-bit digits that the debugger says form its mantissa, maybe?  

I need *fast* types.  I also need high precision, but I don't need arbitrary precision.   I'm prefectly fine with being limited to a choice made at compile time, just as one does with the choice of `Float`, `Double`, or `Float80`.   That means I can take a different approach than most other frameworks seem to.

## So where are the floating point types?

In short, I'm not there *yet*. (Actually, in progress... and coming very soon!)

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

I haven't done a lot of real benchmarking yet, though I have done informal comparison experiments on the performance for the smaller types (`UInt128`, and `UInt256`) that are promising.  Real benchmarking is a to-do, and an important one since performance is the whole reason for writing my own BigMath library anyway.  Plus it would be helpful for anyone considering using this package to see some actual numbers.

The extensions for these protocols make heavy use of `@inlinable`, as do `WideInt` and `WideUInt`.  That means the compiler can see their implementation, and even if it chooses not to actually inline them, it should generate specialized functions that can be called without the protocol/generic witness table thunking overhead that would otherwise be required.

### Integer Arithmetic

#### Addition and Subtraction

These are implemented with the same straight-forward algorithm every child learns in school.  It is an O(*n*) algorithm, with very good cache characteristics.  The only improvements one might make would be micro-optimizations, and I've done the ones I can identify.

#### Multiplication

There are two multiplication algorithms implemented: "school book" and Karatsuba.

1. The "school book" method  is O(*n*^2), but has really good CPU cache characteristics.  It is used for all multiplications for integers with a number of bits lower than a certain threshold.  That threshold is currently set at 8192 bits (128 64-bit digits)

2. Karatsuba is O(*n*^log2 3) which is theoretically faster than schoolbook, but its divide and conquer approach makes it less cache-friendly.   As a result its superior complexity advantages only appear for large numbers of digits.   It is a recursive algorithm, and whenever recurision brings the number of digits below the school book threshold, it calls the school book method.

The tests I've run to determine where the cross-over in performance is indicate that it's somewhere above 16384-bit integers.  The test results are below, and you can see that at 16384, school book's superior cache characteristics start to lose out to its *n*^2 complexity, so not only does it have a marked impact on its performance, but the difference between it and Karatsuba finally begins to close.  I suspect that at 32768 bits, Karatsuba would start to win out, however, the increased build-times when including integers that large became intolerable, which is fine for me - I don't need integers *that* large, but I do wish I could have actually seen the cross-over. (*Update: After many optimizations that benefited all algorithms used, you can now see the cross-over at 8192, though that may just be a statistical variation - maybe some some other process on my machine kicked in during the school book run, but you can see a bigger difference at 16384 that is too large to be explained by system "noise"*)

These tests consisted of randomly generating 100,000 multiplicand-multiplier pairs and doing full width multiplication (meaning the result is twice as wide as the operands).  The run times in the following table do not include generation of these pairs.  One algorithm is timed multiplying all of the pairs before  the second algorithm is timed multiplying the same pairs.  Both algorithms are tested on a single type before testing them on the next type.

Time in seconds to run algorithm 100,000 times :
| Integer Type | School Book |  Karatsuba |  Shool Book 2 | Karatsuba 2 |
|     :--: |              --: |               --: |  --: |  --: |
|    `UInt128` |      0.09 |    0.116 | 0.003  | 0.005 |
|    `UInt256` |      0.14 |    0.341 | 0.004  | 0.007 |
|    `UInt512` |      0.27 |    0.690 | 0.010  | 0.014 |
|   `UInt1024` |      0.534 |    1.401 | 0.032  | 0.036 |
|   `UInt2048` |      1.142 |    2.980 | 0.127  | 0.129 |
|   `UInt4096` |      2.589 |    6.446 | 0.505  | 0.511 |
|   `UInt8192` |      6.363 |  14.333 | 2.057  | 2.056 |
|  `UInt16384` |    50.782 |  72.539 | 8.106  | 6.415 |

*School Book 2 and Karatsuba 2 are measurements made after many optimizations.  As you can see, performance has dramatically improved!*

Another thing to note is that up to `UInt8192` in these tests, Karatsuba is actually just calling the school book method.  On first blush, one would expect that their performance should be identical, and yet Karatsuba's failing over to school book is markedly slower than just calling school book directly. (*Note: after optimizations, they're actually pretty close, as one would expect.*)   The reason for this is that school book is a completely iterative algorithm, and easily inlinable.  Karatsuba, on the other hand, is recursive, and not tail recursive which one could translate into an iterative version fairly easily.  It works by doing 3 smaller multiplications and combining the results.   That recursive nature is a problem for inlining, so even the top-level call to that function is a real, honest-to-God function call.  That overhead accounts for the performance difference.  If I can figure out a clever way to do Karatsuba iteratively without doing any heap allocations, I will implement it, and revisit these tests.

I should also mention that I only created the types larger than 4096 bits for these tests.  They have been disabled to keep build times reasonable.

#### Division
Division uses Donald Knuth's "Algorthm D" from *The Art of Computer Programming*, which assuming the divisor and dividend are similar lengths, as typically they are in this package, is O(*n*^2). 

At least two of the libraries I looked at claimed that their shift-subtract algorithm was O(*n*), but on closer inspection it definitely isn't.  Both the shift and the subtract are each O(*n*) and they are in an O(*n*) loop, making the algorithm O(*n*^2) as well, and inefficiently so, as they have to process each bit individually, whereas Knuth's algorithm does whole digit arithmetic, which for my implementation translates to native 64-bit integer arithmetic instructions (or 32-bit if you're still a on a 32-bit machine).  Bit level shift and subtract is a reasonable hardware implementation, but I don't see how it could be a good software one.  

Although I believed the shift-subtract division algorithm would be slower than Knuth's, it does have some advantages, that I thought could possibly lead to better performance than I perceived:

    - It doesn't require any additional "scratch" work space.  The Knuth algorithm requires normalizing the divisor and the dividend.  As written Knuth's algorithm does this "in-place", but that means the divisor and dividend are both modified.   One does not usually expect for an arithmetic operation to modify its operands, so they must be put in working storage for the normalization.  The way the algorithm works, the storage to receive the remainder works perfectly for the normalized dividend; however, the normalized divisor requires its own storage.   Shift-subtract can work with only the space already required to receive the quotient and remainder.
    
    - It doesn't require any division or multiplication instructions.  It's literally shift and subtract.   The Knuth algorithm finds an estimated quotient digit using two-digit division, and then corrects it using two-digit multiplication, and then it does multiprecision combined multiplication and subtraction, where the multiplciation is a multiprecision number by a single digit, and it does a possible corrrective multiprecision addition if its estimated quotient turns out to be one too large.  Although I thought it very unlikely, it seemed plausible that shift-subtract just might be able to out-perform Knuth.
    
Since speed is king in this library, I implemented the shift-subtract division algorithm to compare it Knuth's, and though I was was a little biased, I nonetheless did my best to give it every speed advantage I could think of.   After all, I had given a lot of care optimizing Knuth's algorithm.  It wouldn't be a fair test if I hadn't done the same for shift-subtract.  I ran the test, which was full-width division, meaning the dividend is twice as wide as the divisor, on 128-bit, 256-bit, 512-bit, 1024-bit, 2048-bit and 4096-bit unsigned integer divisors.  For each test, 100,000 randomly generated dividends and divisors were created to be used in the tests prior to starting the clock, and both algorithms divided the same dividends and divisors in the same order.   The results are in, and they speak for themselves:

Time in seconds to run algorithm 100,000 times :
| Integer Type | Shift-Subtract | Knuth D | Knuth D2 | Shift-Subtract2 |  Knuth D3 |
|     :--:     |            --: |     --: |     --: |     --: |     --: |
|    `UInt128`   |      13.63     |   0.55  |    0.19   |     7.18 | 0.10 |
|    `UInt256`   |      27.47     |   0.93  |    0.37   |   14.41 | 0.20 |
|    `UInt512`   |      55.57     |   1.66  |    0.70   |   29.84 | 0.31 |
|   `UInt1024`   |     114.69     |   3.15  |  1.39   |   63.94 | 0.53 |
|   `UInt2048`   |     243.78     |   6.40  |  2.89   | 143.19 | 1.06 |
|   `UInt4096`   |     543.61     |  13.40  |  6.37  | 346.76 | 2.50 |

*Knuth D is the version of the algorithm used in the original comparison with shift-subtract*

*Knuth D2 is an updated version with better 64-bit implementation.  It was not part of the original comparison test, and is provided here to show the improvement in implementation performance.*

*Shift-Subtract2 and KnuthD3 are the results after many optimizations.*

*Update: After reaching out to the owner of one of those libraries that was using shift-subtract, we adapated the Knuth algothorithm for his array-based library and he now reports a 25x speed up for division!*

While avalailable to be called explicitly, shift-subtract division is not used to implement any of the normal division operations.

### Floating Point Arithmetic

For the most part floating point arithmetic is implemented on top of the integer arithmetic already discussed.   There is necessarily some additional overhead in handling special values such as  `NaN` and `infinity`.   Additionally in some cases, the floating point calculations take longer than their equivalent integer calculations, because they have to be calculated to their full precision.  For example, integer division stops when it finds the full integer quotient.   Floating point division, on the other hand, must continue calculating until the quotient precision is filled and beyond to get proper rounding of the least significant digit.

In some cases additional algorithms are available.  Some are there just because I was searching for the fastest, and the only way to know for sure was to implement them, and in others, they are available, because in some special cases, the code that uses this library might be able to employ them in special cases to get better performance than they would offer in the general case.  

#### Addition and subtraction

Addition an subtraction employ an adapted version of the same O(*n*) algorithm used by integer arithmetic in order to handle differing exponents in their operands  without having to do an actual preliminary shift of the operand with the lower exponent.  They take longer to run than their integer counterpart not only because of special value checking, but also to handle shifting results due to carrying out of the high bit, and handling rounding of the least significant bit.

#### Multiplication

Multiplication uses the same algorithms as for integer multiplication, choosing between "school book" and Karatusba methods based on the size of the significand, using the same threshold.  Exponents are fixed up after the significand is calculated.

#### Division

Three different algorithms are implemented for floating point division.  

The default is a slight variant of Knuth's "Algorithm D" that is used for integer division.   Although markedly slower than its integer counter part, because of the necessity to fill out the full precision of the quotient, it is nonetheless faster than the other two methods.

Both of the alternative methods rely on finding the multiplicative inverse of the divisor.   Both of those methods provide a means for just getting the multiplicative inverse separate from the division.

The first multiplicative inverse method is by using the Knuth algorithm to divide 1 by the divisor, then multiplying the result by the dividend.  Since it's essentially doing the same work as simply dividing using Knuth division, with the additional work of a multiplication at the end, it always underperforms the straight Knuth division.  However it is competitive with straight Knuth division, so if the application using this library needs to repeatedly divide by the same number, using this method to calculate the inverse once and then using multiplication repeatedly would achieve significantly better performance.

The last method is Newton-Raphson.  Despite its quadratic convergence when calculating the multiplicative inverse, it is an order of magnitude slower than finding the multiplicative inverse using Knuth division.   I implemented it and spent quite a lot of time optimizing it in hopes of making it competitive, but for the sizes this library is capable of handling, it just will never be a useful algorithm.   It may be more useful for the truly large numbers of digits that arbitrary precision libraries might handle.

The following table shows their relative performance  compared to Knuth Integer division after much optimization:

Time in seconds to run algorithm 100,000 times :
| Floating Point Type | Knuth D (Integer) | Knuth D (Floating Point) | Knuth Multiplicative Inverse | Newton-Raphson | 
|     :--:     |            --: |     --: |     --: |     --: | 
|    `Float128`     | 0.078  | 0.354 | 0.487 |   1.425 |
|    `Float256`     | 0.148  | 0.379 | 0.516 |   1.749 |
|    `Float512`     | 0.159  | 0.446 | 0.609 |   2.411 |
|    `Float1024`   | 0.175  | 0.646 | 0.882 |   4.484 |
|    `Float2048`   | 0.209  | 1.335 | 1.802 | 12.114 |
|    `Float4096`   | 0.297  | 3.970 | 5.297 | 44.654 |

### Memory Allocation
Importantly, the algorithm implementations in this package do not allocate anything from the heap.  Where they need scratch buffers for intermediate computation, they are allocated on the stack.

Actually there are two places where I do dynamically allocate memory:

1. The `words` property from the `BinaryInteger` protocol allocates an array of `UInt`s to return.  In earlier versions, I returned an `UnsafeBufferPointer<UInt>` just to satisfy the requirement, but that seemed like a bad idea.  The pointer returned wasn't even valid, and even it were, it wouldn't continue to be for long if you held on to after the integer you got it from went out of scope.  I don't use it anywhere, but I have to have it to conform to `BinaryInteger`. 

2. To work around not having stored static properties in generics `WideFloat` uses two internal global arrays to store the constants `0` and `1` in such a way that they can be quickly cast to whatever `WideFloat` size is needed up to the array size.  Beyond that it has to fall back to initializing the `WideFloat` on each request.  The arrays are invisible to the user, and allocated only once for an entire program execution.  I may add more of these, for things like `.pi`.  I'll probably add `2` as well, as it's used by Newton-Raphson division to find the multiplicative inverse.  The problem is that the arrays have to be a decent size to handle any reasonably large number of `WideFloat` widths someone might want to use, and except for `.pi` when I get around to implementing it, they contain nothing but zeros followed by whatever most significant digit represents the number in question.  Internally, I'll probably move away from these arrays at some point by writing custom variants of the buffer-level math routines to handle the constants in a much more efficient way, but they'll need to remain for users, unless I can come up with a more efficient way to do it.  The integer types do not use the arrays.


