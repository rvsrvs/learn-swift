/*:
 # EventLoopPromise/Future, Combine and Swift 6 Concurrency

 This playground is designed to demonstrate what I feel are the main design considerations for, on the one hand NIO's EventLoopPromise/Future mechanism and Combine and on the other Swift 6 Concurrency.  The points to be made are:

 1. OOP techniques such as `objc_msgSend` are equivalent to the Continuation Passing Style (CPS) from functional programming
 1. CPS and the `direct` style are different but compatible techniques of function composition
 1. CPS gives rise to the Continuation monad below, the `direct` style gives rise to the Func monad below
 1. The tools that Apple provides for asynchrony in Swift 5 and lower (Thread, DispatchQueue, RunLoop, and OperationQueue) are wrappers around OS-level constructs which are inherently effect-ful because their invocation returns Void.
 1. The only options when using these techniques are for the invoking functions to either return Void themselves or to hang the thread they are running in.  Since hanging the thread is unacceptable, the only real option is for the the invoking context to return Void as well.
 1. The Continuation monad can accomodate Void returns by handling the value that would be ordinarily be returned as a side-effect at the end of composition chain.
 1. The Func monad becomes useless in the presence of Void returns
 1. Useful concepts like cancellation and, especially, back pressure are best suited to the Func monad
 1. NIO and Combine are Continuation-based in order to take advantage of the available asynchrony
 1. Restoring compositionality _requires_ asynchrony techniques which return values but which don't hang the thread in which they are invoked
 1. async/await and Actor are those techniques
 1. Those techniques are language-level features rather than OS-level features bc the operating system does not have a concept of "return value", but languages do.  i.e. This problem can only be addressed at the language level, NOT by the introduction of new OS constructs.
 */

// Three functions that compose together
func doubler(_ value: Int) -> Double { .init(value * 2) }
func toString(_ value: Double) -> String { "\(value)" }
func encloseInSpaces(_ value: String) -> String { "   \(value)   " }

// what does it mean to say that functions "compose"?
// The return value of one is the argument to the next. i.e.:
// I can compose (Int)    -> Double    with:
//               (Double) -> String    with:
//               (String) -> String
// to get: (Int) -> String

// Here is what the composition of the 3 functions above looks like in
// the standard swift function call notation
encloseInSpaces(toString(doubler(14)))

// Note that functions have type and it is the type that allows them to compose
type(of: doubler)
type(of: toString)
type(of: encloseInSpaces)

// I can take _any_ function of one variable and make it
// a computed var on the type of the variable
// This is possible because computed vars are really functions themselves
// Note how we simply replace `value` above with `self` in each case

extension Int {
    var doubler: Double { .init(self * 2) }
}
extension Double {
    var toString: String { "\(self)" }
}
extension String {
    var encloseInSpaces: String { "   \(self)   " }
}

// Using this object-oriented notation, `encloseInSpaces(toString(doubler(14)))` becomes:
14.doubler.toString.encloseInSpaces

// of course that notation can be extended to multi-arg functions as well and
// everything below can be similarly extended
extension Int {
    // (Int) -> () -> Double
    func yetAnotherDoubler() -> Double { .init(self * 2) }

    // (Int) -> (Double) -> Double
    func add(someDouble: Double) -> Double { Double(self) + someDouble }

    // (Int) -> (Int, Double) -> Double
    func multiply(by anInt: Int, andAdd aDouble: Double) -> Double { Double(self * anInt) + aDouble }
}

extension Int {
    static func anotherDoubler(_ anInt: Int) -> Double { .init(anInt * 2) }
}

// Note that the signature of `anotherDoubler` is exactly the same as our original `doubler` func
type(of: Int.anotherDoubler) // (Int) -> Double

// ANd note that this is how the free function gets turned into a `method`
func yetAnotherDoubler(_ `self`: Int) -> () -> Double {
    { .init(`self` * 2) }
}
type(of: yetAnotherDoubler)
type(of: Int.yetAnotherDoubler) // (Int) -> () -> Double

14.doubler
// Here's what the statement above looks like in ObjC style:
// [14 doubler]
14.yetAnotherDoubler()
// In ObjC, there is no distinction between the property and the zero arg function
// in ObjC style, [14 yetAnotherDoubler] is the same as doubler

// NB The compiler fibs to us about computed vars, it won't tell us the type like
// it will functions.  But we know that anywhere we have a KeyPath we can treat it as
// a function
type(of: \Int.doubler)

// These statements are exactly equivalent, however
doubler(14)
14.doubler

// Reminder for below I can _always_ rearrange arguments to a function
func flip<A, B, C>(
    _ f: @escaping (A, B) -> C
) -> (B, A) -> C {
    { b, a in f(a,b) }
}

// even (or especially) when the func is in the curried form
func flip<A, B, C>(
    _ f: @escaping (A) -> (B) -> C
) -> (B) -> (A) -> C {
    { b in { a in f(a)(b) } }
}

// And we can compose functions at run time rather than at compile time
public func compose<A, B, C>(
    _ f: @escaping (A) -> B,
    _ g: @escaping (B) -> C
) -> (A) -> C {
    { a in g(f(a)) }
}

// And we can use the infix form of any function with precisely two arguments
// In this case `+` is a function, just used in "infix" form
14 + 13

// And this fact allows us to make an infix version of our compose function
// which will be helpful in visualizing the relationship of `compose` to `apply`
// below
precedencegroup CompositionPrecedence {
  associativity: right
  higherThan: ApplicationPrecedence
  lowerThan: MultiplicationPrecedence, AdditionPrecedence
}

// here's a compose operator
infix operator >>> : CompositionPrecedence  // Application

// And this... is EXACTLY the same as compose only now we can use `infix` form
public func >>><A, B, C>(
    _ f: @escaping (A) -> B,
    _ g: @escaping (B) -> C
) -> (A) -> C {
    { a in g(f(a)) }
}

// Explicit composition
encloseInSpaces(toString(doubler(14)))

// composition via a higher-order function yields the identical result
let composedDoubleString = compose(doubler, compose(toString, encloseInSpaces))
composedDoubleString(14)

// Compose in infix form
// (Infix form makes several of the comparisons below easier to see in context)
let infixDoubleString = doubler >>> toString >>> encloseInSpaces
infixDoubleString(14)

// If we inline the compositions "by hand" we get:
let explicitToString = { innerInt in toString(doubler(innerInt) ) }
let explicitEncloseInSpaces = { outerInt in encloseInSpaces(explicitToString(outerInt) ) }
// lambda calculus form
let explicitDoubleString = { outerInt in encloseInSpaces({ innerInt in toString(doubler(innerInt)) }(outerInt) ) }
explicitDoubleString(14)

// NB, if we mark compose as `@inlinable` (which we can't do in a playground)
// The compiler will optimize the "by hand" form to be just the compositional form

// Let's demonstrate that.
let value = 14

// So these are all different notations for exactly the same thing
infixDoubleString(value)
explicitDoubleString(value)
(doubler >>> toString >>> encloseInSpaces)(value)

// We can apply the same techniques to the OO form as a higher order function, too.
public func apply<A, R>(
    _ a: A,
    _ f: (A) -> R
) -> R {
    f(a)
}

// Note if we could use @inlinable here: apply(a, f) == f(a)
// by direct substitution, these would all simplify down dramatically.
// [[[14 doubler] toString] encloseInSpaces]
            apply(14,      doubler)                                              // 14.doubler
      apply(apply(14,      doubler),         toString)                           // 14.doubler.toString
apply(apply(apply(14,      doubler),         toString),         encloseInSpaces) // 14.doubler.toString.encloseInSpaces
apply(apply(apply(14, \Int.doubler), \Double.toString), \String.encloseInSpaces) // The same done with keypaths
encloseInSpaces(toString(doubler(14)))
//  By the way...
// `apply` is EXACTLY the same operation
//  as `objc_msgSend`.  `apply` is just done _without_ inheritance and _with_ static rather
// than dynamic dispatch via selectors.
// Do you see why this statement is true?  If you are an ObjC programmer and don't
// see it, you should look at the type signatures for objc_msgSend and IMP

// And of course we can mix our composed functions with our apply function
apply(14, infixDoubleString)

// And we can do our apply/msgSend operator in infix form too.
precedencegroup ApplicationPrecedence {
  associativity: left
  higherThan: AssignmentPrecedence
}
infix operator |>  : ApplicationPrecedence  // Application

// Note that this is _exactly_ the apply function, only as an operator
public func |><A, R>(
    _ a: A,
    _ f: (A) -> R
) -> R {
    f(a)
}

// Given the above, these are EXACTLY the same thing
// we're just sprinkling on some syntactic sugar
apply(14, infixDoubleString)
14 |> infixDoubleString
infixDoubleString(14)

// Now lets compare and contrast apply and compose
// reminder, this is the composition
(doubler >>> toString >>> encloseInSpaces)(14)  // Direct Style

// What follows is probably the most important point in this
// playground.
// _None_ of lines below are the same thing as any of the others
// but all of them yield the same, identical result.
// i.e. We have shown that OOP, direct and continuation-passing styles
// can all be mechanically translated from one to the other.
// and either application or composition can be used between functions.
14 |>   doubler >>>   toString >>>   encloseInSpaces  // direct style
14 |> \.doubler >>> \.toString >>> \.encloseInSpaces  // direct style
14 |>   doubler |>    toString >>>   encloseInSpaces  // mixed style
14 |>   doubler >>>   toString |>    encloseInSpaces  // mixed style
14 |>   doubler |>    toString |>    encloseInSpaces  // Continuation Passing Style
14 |> \.doubler |>  \.toString |>  \.encloseInSpaces  // Continuation Passing Style
14     .doubler      .toString      .encloseInSpaces  // OOP native style

// It is precisely this equivalence that we want to capture in a
// concurrent manner and it is precisely this that breaks when
// any of the functions involved return Void.

// writing the above out long hand..

// lambda calc form
//14 |> doubler >>> toString >>> encloseInSpaces  // mixed style
compose(doubler, compose(toString, encloseInSpaces))(14)
({ outerInt in encloseInSpaces({ innerInt in toString(doubler(innerInt)) }(outerInt) ) })(14)

// The last one
apply(apply(apply(14, doubler), toString), encloseInSpaces)
// apply @inlinable
encloseInSpaces(apply(apply(14, doubler), toString))
encloseInSpaces(toString(apply(14, doubler)))
encloseInSpaces(toString(doubler(14)))

// Single Static Assignment (SSA) Form
// or you can think of it as what the compiler would put out:
let a = 14 |> doubler          // or doubler(14)
let b = a  |> toString         // or toString(a)
let c = b  |> encloseInSpaces  // or encloseInSpaces(b)

// In summary, all of these _do_ the same thing
// but _are not_ the same thing
(doubler >>> toString >>> encloseInSpaces)(14)  // Direct Style
compose(doubler, compose(toString, encloseInSpaces))(14)
      14 |>       doubler >>>      toString >>> encloseInSpaces  // mixed style
apply(14, compose(doubler, compose(toString,    encloseInSpaces)))

            14 |> doubler |>        toString >>> encloseInSpaces  // mixed style
apply(apply(14,   doubler), compose(toString,    encloseInSpaces))

            14 |>       doubler >>> toString |> encloseInSpaces  // mixed style
apply(apply(14, compose(doubler,    toString)), encloseInSpaces)

                14 |> doubler |> toString |> encloseInSpaces  // Continuation Passing Style
apply(apply(apply(14, doubler),  toString),  encloseInSpaces)

// Looking closely at that last one we discover that application
// and the continuation passing style are something that we
// already knew as the Object-Oriented style
14 |> doubler |>  toString |>  encloseInSpaces  // Continuation Passing Style
14   .doubler    .toString    .encloseInSpaces  // Object-Oriented Style
// [[[14 doubler] toString]    encloseInSpaces] // ObjC syntax
// objc_msgSend(objc_msgSend(objc_msgSend(14, doubler),  toString),  encloseInSpaces) // What ObjC does...
// encloseInSpaces(toString(doubler(14)))       // What the compiler does when |> is @inlinable

// Conclusion: OO with immutable types is exactly equivalent to CPS


// Now, what does `apply` look like if we _curry_ it?
//  NB This returned function is precisely the form of the Haskell Continuation monad
// ((A) -> R) -> R
func curriedApply<A, R>(
    _ a: A
) -> (@escaping (A) -> R) -> R {
    { f in f(a) }
}

// Proof that these do the same thing..
       apply(       apply(       apply(14, doubler), toString), encloseInSpaces)
curriedApply(curriedApply(curriedApply(14)(doubler))(toString))(encloseInSpaces)

// The Haskell Continuation equivalence means that we know we can write map/flatMap/zip on curriedApply

// BTW, it is instructive to curry compose as well, bc we will be coming
// back to this.
public func curriedCompose<A, B, C>(
    _ f: @escaping (A) -> B
) -> (@escaping (B) -> C) -> (A) -> C {
    { g in { a in g(f(a)) } }
}

compose       (doubler,        compose(toString, encloseInSpaces))(14)
curriedCompose(doubler)(curriedCompose(toString)(encloseInSpaces))(14)

// Again, note that these all give EXACTLY IDENTICAL results
// And that translating from one form to another ia a completely
// mechanical process
       apply(       apply(       apply(14, doubler), toString), encloseInSpaces)
curriedApply(curriedApply(curriedApply(14)(doubler))(toString))(encloseInSpaces)

// Note that apply nests left, compose nests right
       compose(doubler,        compose(toString, encloseInSpaces))(14)
curriedCompose(doubler)(curriedCompose(toString)(encloseInSpaces))(14)

// Also note that we are able to do this to ANY function that is in
// the standard one-argument form.  And that it is only slightly
// more complicated in the multi-argument form.
// And that we can do this only because we have generics.  Generics
// are absolutely critical to this ability to compose.


// Interesting side-note: suppose we _flip_ the arguments to apply

// Flipped form of apply (here called invoke) turns out to be the natively supported invocation form

// reminder this is the apply from above:
//public func apply<A, R>(
//    _ a: A,
//    _ f: (A) -> R
//) -> R {
//    f(a)
//}

// Flipping that yields:
public func invoke<A, R>(
    _ f: (A) -> R,
    _ a: A
) -> R {
    f(a)
}

// And then we _curry_ invoke
func curriedInvoke<A, R>(
    _ f: @escaping (A) -> R
) -> (A) -> R {
    f
}
// curried invoke just turns out to be the identity
// function operating on the supplied funcion.  Making it @inlinable allows the
// compiler to, in fact remove it and just use the
// native function invocation operation that is built in
// to the language.  Hence there is never any need for us to write `invoke` - it
// is native to the language.  It's the `apply` form which we have to introduce.

// The Big Leap
// Lifting curriedApply from a structural type, i.e. just a function
// to be a nominal type, i.e. a struct with a function as it's only member.

// Up to this point we've just been playing with Swift's
// syntax for functions, rearranging things in various ways
// and showing that different rearrangements produce identical
// results.  NOW we make real use of what Swift can give us.

// Notes:
// 1. the trailing function from curriedApply becomes the let
// 2. there are TWO inits: the default init + the init that takes the _leading_ value from curriedApply
// 3. the second of the two init's allows us to give our Continuation a `head` value as above
// 4. We add a callAsFunction to denote that this is in fact a function lifted from structual form to nominal form
// 5. the let is exactly the shape of the Haskell Continuation monad right down to the A and the R
// 6. `sink` has the name it does to line up with our intuition about Combine
public struct Continuation<A, R> {
    public let sink: (@escaping (A) -> R) -> R
    public init(sink: @escaping (@escaping (A) -> R) -> R) {
        self.sink = sink
    }
    public init(_ a: A) {
        self = .init { downstream in
            downstream(a)
        }
    }
    public func callAsFunction(_ f: @escaping (A) -> R) -> R {
        sink(f)
    }
}

// If this is correct, we should be able to
// implement curriedApply using the new type
// and have it just work..
func continuationApply<A, R>(
    _ a: A
) -> (@escaping (A) -> R) -> R {
    Continuation(a).sink // .sink here is exactly of type: (@escaping (A) -> R) -> R
}

// Proof that apply, curriedApply , continuationApply Continuation and method invocation are all the exact same thing:
apply            (apply            (apply            (14,      doubler),         toString),         encloseInSpaces)
curriedApply     (curriedApply     (curriedApply     (14)     (doubler))(        toString))(        encloseInSpaces)
continuationApply(continuationApply(continuationApply(14)     (doubler))(        toString))(        encloseInSpaces)
Continuation     (Continuation     (Continuation     (14)     (doubler))(        toString))(        encloseInSpaces)
Continuation     (Continuation     (Continuation     (14)(\Int.doubler))(\Double.toString))(\String.encloseInSpaces)
                                                      14      .doubler          .toString          .encloseInSpaces

// So... If we don't use inheritance or dynamic dispatch,
// i.e. Continuation is just the nominal function form of the structural func `objc_msgSend`...

// So why _did_ we lift `apply` to `Continuation`?
// So that we can do higher order functions on it.
// For example, `map`:
extension Continuation {
    func map<B>(_ f: @escaping (A) -> B) -> Continuation<B, R> {
        .init { downstream in self { a in
            downstream(f(a))
        } }
    }
}
// And with that we have the ability to do "higher-order" objc_msgSend
// Now... we can see that these forms two are also exactly the same:
Continuation(Continuation(Continuation(14)    (doubler))   (toString))(encloseInSpaces)
Continuation(                          14).map(doubler).map(toString) (encloseInSpaces)

// so `map` on continuation is exactly the same as `apply` which we have shown to be the same as
// OO method dispatch via `objc_msgSend`

// And of course we can do flatMap
extension Continuation {
    func flatMap<B>(_ f: @escaping (A) -> Continuation<B, R>) -> Continuation<B, R> {
        .init { downstream in self { a in
            f(a)(downstream)
        } }
    }
}

// And interestingly we can zip these iff A and R are equal
// otherwise we need to also provide a function (R) -> A as our
// sink.  But we need a helper function...
func identity<T>(_ t: T) -> T { t }

// So one form of zip looks like this...
func zip<A, B, R>(
    _ c1: Continuation<A, A>,
    _ c2: Continuation<B, B>
) -> Continuation<(A, B), R> {
    .init { downstream in
        // Note the resemblence to a `map` of two arguments rather than one
        // here's the one-argument form: downstream(f(a))
        downstream((c1(identity), c2(identity)))
    }
}

// In the other form we have to provide a means of connecting the inputs to the outputs
func zip<A, B, S, R>(
    _ c1: Continuation<S, A>, _ sink1: @escaping (S) -> A,
    _ c2: Continuation<S, B>, _ sink2: @escaping (S) -> B
) -> Continuation<(A, B), R> {
    .init { downstream in
        downstream((c1(sink1), c2(sink2)))
    }
}

// And if we move the free function form of zip into Continuation,
// it corresponds directly to NIO's `and` operation between two Futures
extension Continuation where R == A {
    func and<B>(_ c2: Continuation<B, B>) -> Continuation<(A, B), R> {
        zip(self, c2)
    }
}

// So lets use our zip function
let c1: Continuation<String, String> = Continuation(14).map(doubler).map(toString).map(encloseInSpaces)
let c2: Continuation<String, String> = Continuation(14).map(doubler).map(toString)

let combinedString = zip(c1, c2).sink { $0.0 + "/" + $0.1 }
combinedString
let combinedString2 = c1.and(c2).sink { $0.0 + "/" + $0.1 }
combinedString2

// And the above _starts_ to look like Combine and EventLoopFuture all of a sudden.
// But... Theres a problem..  We can't write receive(on:) and subscribe(on:)
// To see why, lets look at what Apple gives us for doing asynchronous work.

// Note that Executor is (modulo a syntax issue) equivalent to Continuation<Void, Void>
// We introduce it as a separate type rather than a type alias solely bc of the
// the syntax difference between () -> Void and (Void) -> Void
import Foundation
struct Executor {
    private let call: (@escaping () -> Void) -> Void
    public init(_ call: @escaping (@escaping () -> Void) -> Void) {
        self.call = call
    }
    public func callAsFunction(_ exec: @escaping () -> Void) {
        call(exec)
    }
}

// We can fit immediate invocation, Threads, DispatchQueues, RunLoops and OpQueues directly
// into our Executor because they _all_ use the same form: `(() -> Void) -> Void`
// for doing dispatch.
// But (modulo that slight syntax inconvenience), that's just Continuation<Void, Void>
// Here's the proof:
extension Executor {
    static var immediate: Self {
        .init { f in f() }
    }
    static var newThread: Self {
        .init { f in Thread.detachNewThread { f() } }
    }
    static var currentRunLoop: Self {
        .init { f in RunLoop.current.schedule { f() } }
    }
    static var currentOperationQueue: Self {
        .init { f in OperationQueue.current?.addOperation { f() } }
    }
}

extension OperationQueue {
    var executor: Executor { .init(addOperation) }
}
extension RunLoop {
    var executor: Executor { .init(schedule) }
}
extension DispatchQueue {
    var executor: Executor { .init { self.async(execute: $0) } }
}

// And now we can see the problem with concurrency and Combine.
// We can write `receive(on:)` and `subscribe(on:)`, but...
// we have to accept that our Continuation type will have R == Void
extension Continuation where R == Void {
    func receive(on executor: Executor) -> Just<A> {
        .init { downstream in self { a in
            executor { downstream(a) }
        } }
    }
    func subscribe(on executor: Executor) -> Just<A> {
        .init { downstream in executor {
            self { a in downstream(a) }
        } }
    }
}

// so let's "just" give that a name:
typealias Just<A> = Continuation<A, Void>

// But using our implemention of receive and subscribe
// _forces_ the return type
// to be Void _everywhere_ in the chain. And with that, we have completely
// broken our ability to intersperse composition with application.

// Observe:
let q: OperationQueue = {
    let newQueue = OperationQueue()
    newQueue.maxConcurrentOperationCount = 4
    return newQueue
}()

// Taking our example zip from above,
// we can put _every_ single operation on a different thread or run loop
// even the operation of attaching the sink
let j1: Just<String> = Just(14)
    .receive(on: q.executor)
    .map(doubler)
    .receive(on: q.executor)
    .map(toString)
    .receive(on: q.executor)
    .map(encloseInSpaces)
    .receive(on: q.executor)
    .subscribe(on: q.executor)

let j2: Just<String> = Just(14)
    .receive(on: q.executor)
    .map(doubler)
    .receive(on: q.executor)
    .map(toString)
    .receive(on: q.executor)
    .subscribe(on: q.executor)

// There is no way now to attach a sink and have it return a value
// back to an invoker, because by the time the value reaches the sink
// the invoker in another thread has _already_ returned

// But making Continuation return Void does have a really powerful
// side benefit. It allows us to do a parallel
// form of zip which is _thread safe_.
// NB This is only possible bc of the Void return type on `Just`.
// Also note here the small size of the critical section, i.e.
// (The parts between the lock and the unlock)
func zip<A, B>(_ ja: Just<A>, _ jb: Just<B>) -> Just<(A,B)> {
    .init { downstream in
        var lock = os_unfair_lock_s()
        var optionalA: A? = .none, optionalB: B? = .none
        ja { a in
            os_unfair_lock_lock(&lock)
            optionalA = a
            guard let b = optionalB else { os_unfair_lock_unlock(&lock); return }
            os_unfair_lock_unlock(&lock)
            downstream((a, b))
        }
        jb { b in
            os_unfair_lock_lock(&lock)
            optionalB = b
            guard let a = optionalA else { os_unfair_lock_unlock(&lock); return }
            os_unfair_lock_unlock(&lock)
            downstream((a, b))
        }
    }
}

// And we can also use the EventLoopFuture notation.
extension Continuation where R == Void {
    func and<B>(_ jb: Just<B>) -> Just<(A,B)> {
        zip(self, jb)
    }
}

// And _now_ we can make use of 4 threads concurrently,
// "just" at the cost of getting a Void return value.
let parallel = Just(())
    .receive(on: q.executor)
    .flatMap { zip(j1, j2) }
    .receive(on: q.executor)
    .subscribe(on: q.executor)

var v1: Void = parallel.sink { $0;  print($0) }
type(of: v1)
var v2: Void = parallel.sink { $0;  print($0) }
type(of: v2)
var v3: Void = parallel.sink { $0;  print($0) }
type(of: v3)
var v4: Void = parallel.sink { $0;  print($0) }
type(of: v4)

// So how do we recover compositionality???
// We introduce a new queueing construct which waits for a return value WITHOUT
// blocking the thread..
// Essentially we will make an AsyncContinuation with the form: ((A) async -> R) async -> R
// and put the awaits in where the compiler tells us.
// And we will do the same with our Func monad to get composition back as above.

struct Func<A, B> {
    let call: (A) -> B
    init(_ call: @escaping (A) -> B) {
        self.call = call
    }
    func callAsFunction(_ a: A) -> B {
        call(a)
    }
}

// (A) -> (A, W)
// (State, Action, Environment) async -> (State, Publisher<Action>)  Reduce
// (W, W) -> W
//import Combine
//struct Reducer<State, Action, Environment> {
//    let reducer: (inout State, Action, Environment) -> PassthroughSubject<Action, Never>
//}
//struct Generator<A, W> {
//    var a: A
//    let generator: (inout A) -> (W)
//    async var next: W? { generator(&self) }
//}


extension Func {
    func map<C>(_ f: @escaping (B) -> C) -> Func<A, C> {
        .init { a in
            f(self(a))
        }
    }
    func flatMap<C>(_ f: @escaping (B) -> Func<A, C>) -> Func<A, C> {
        .init { a in
            f(self(a))(a)
        }
    }
}

func zip<A, B, R>(_ a: Func<R, A>, _ b: Func<R, B>) -> Func<R, (A, B)> {
    .init { ( a($0), b($0) ) }
}

// To be continued...
