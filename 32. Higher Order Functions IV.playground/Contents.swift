/*:
 # Higher Order Functions IV - Contravariance and Combine

 ![Swift Type System](swift-type-system.png)
 */
import UIKit
let image = UIImage(named: "swift-type-system")

precedencegroup CompositionPrecedence {
  associativity: right
  higherThan: AssignmentPrecedence
  lowerThan: MultiplicationPrecedence, AdditionPrecedence
}

/*:
 Handy functions for composition
 */
public func identity<T>(_ t: T) -> T { t }
public func void<T>(_ t: T) -> Void { }
public func cons<T>(_ t: T) -> () -> T { { t } }
public func unwrap<T>(_ t: T?) -> T { t! }

/*:
 Various forms of mixing plain functions with Funcs
 */
infix operator >>>: CompositionPrecedence
public func >>> <A, B, C>(
    _ f: @escaping (A) -> B,
    _ g: @escaping (B) -> C
) -> Func<A, C> {
    .init { (a: A) -> C in g(f(a)) }
}

/*:
 Various forms of mixing plain functions with Funcs
 */
func >>> <A, B, C, D: CallableAsFunction> (
    _ f: @escaping (A) -> B,
    _ g: D
) -> Func<A,C> where D.A == B, D.B == C {
    .init(f >>> g.call)
}

func >>> <A, B, C, D: CallableAsFunction>(
    _ f: D,
    _ g: @escaping (B) -> C
) -> Func<A,C> where D.A == A, D.B == B {
    .init(f.call >>> g)
}

func >>> <A, B, C, D: CallableAsFunction, E: CallableAsFunction> (
    _ f: D,
    _ g: E
) -> Func<A,C> where D.A == A, D.B == B, E.A == B, E.B == C{
    .init(f.call >>> g.call)
}

/*:
 Define an operator for the application of a
 function to a value
 */
infix operator |>: CompositionPrecedence
public func |> <A, B> (
    a: A,
    f: (A) -> B
) -> B {
    f(a)
}

public func |> <A, B, C: CallableAsFunction> (
    a: A,
    f: C
) -> B
    where A == C.A, B == C.B {
    f(a)
}

public func |> <A, B: CallableAsFunction, C: CallableAsFunction> (
    a: A,
    f: C
) -> B
    where A == C.A, B == C.B {
    f(a)
}

public func |> <A: CallableAsFunction, B: CallableAsFunction, C: CallableAsFunction> (
    a: A,
    f: C
) -> B
    where A == C.A, B == C.B {
    f(a)
}

public func |> <A: CallableAsFunction, B, C: CallableAsFunction> (
    a: A,
    f: C
) -> B where A == C.A, B == C.B {
    f(a)
}

public func |> <A: CallableAsFunction, B, C, D, E, F: CallableAsFunction> (
    a: A,
    f: ((B) -> C) -> (D) -> E
) -> F where A.A == B, A.B == C, F.A == D, F.B == E {
    .init(f(a.call))
}

public func |> <A, B: CallableAsFunction> (
    a: @escaping (A) -> B,
    f: @escaping ((A) -> B) -> (B.A) -> B.B
) -> B {
    .init(f(a))
}

/*:
 Allow structs which are callable as functions
 of one value to get all the same operations
 as regular functions
 */
public protocol CallableAsFunction {
    associatedtype A
    associatedtype B
    var call: (A) -> B { get }
    var function: Func<A, B> { get }
    
    init(_ call: @escaping (A) -> B)
    init(_ f: Func<A, B>)
    
    func callAsFunction(_ a: A) -> B
    
    func map<C>(
        _ f: @escaping (B) -> C
    ) -> Func<A, C>
    
    func map<C>(
        _ f: Func<B, C>
    ) -> Func<A, C>
    
    func contraMap<C>(
        _ f:  @escaping (C) -> A
    ) -> Func<C, B>

    func contraMap<C>(
        _ f: Func<C, A>
    ) -> Func<C, B>

    func flatMap<C>(
        _ f:  @escaping (B) -> (A) -> C
    ) -> Func<A, C>
    
    func flatMap<C>(
        _ f:  Func<B, Func<A,C>>
    ) -> Func<A, C>

    func contraFlatMap<C>(
        _ join:  @escaping ((A) -> B) -> (A) -> B,
        _ transform:  @escaping (C) -> A
    ) -> Func<C, B>

    func contraFlatMap<C>(
        _ join:  @escaping (Self) -> Self,
        _ transform:  @escaping (C) -> A
    ) -> Func<C, B>
    
    func contraFlatMap<C>(
        _ join:  @escaping ((A) -> B) -> (A) -> B,
        _ transform:  Func<C, A>
    ) -> Func<C, B>

    func contraFlatMap<C>(
        _ join:  Func<Self, Self>,
        _ transform:  Func<C, A>
    ) -> Func<C, B>

    func dimap<C, D>(
        _ f:  @escaping (C) -> A,
        _ g:  @escaping (B) -> D
    ) -> Func<C, D>
}

public extension CallableAsFunction {
    var function: Func<A, B> { .init(call) }
    
    func callAsFunction(_ a: A) -> B {
        call(a)
    }
        
    func map<C>(
        _ f: @escaping (B) -> C
    ) -> Func<A, C> {
        self >>> f
    }

    func map<C>(
        _ f: Func<B, C>
    ) -> Func<A, C> {
        self >>> f
    }

    func contraMap<C>(
        _ f: @escaping (C) -> A
    ) -> Func<C, B> {
        f >>> self
    }
    
    func contraMap<C>(
        _ f: Func<C, A>
    ) -> Func<C, B> {
        f >>> self
    }
    
    func flatMap<C>(
        _ f: @escaping (B) -> (A) -> C
    ) -> Func<A, C> {
        // self >>> f = ((A) -> B) >>> (B) -> (A) -> C = (A) -> (A) -> C
        // a |> (self >>> f) = (A) -> C
        .init { (a: A) in  a |> (a |> (self >>> f)) }
    }

    func flatMap<C>(
        _ f: Func<B, Func<A, C>>
    ) -> Func<A, C> {
        .init { (a: A) in  a |> (a |> (self.call >>> f)) }
    }

    func contraFlatMap<C>(
        _ join:  @escaping ((A) -> B) -> (A) -> B,
        _ transform:@escaping (C) -> A
    ) -> Func<C, B> {
        // self |> join = (A -> B) |> ((A) -> B) -> (A) -> B) = A -> B
        // transform >>> (self |> join)
        // = (C -> A) >>> (A -> B) = C -> B
        .init(transform >>> self.call |> join)
    }
    
    func contraFlatMap<C>(
        _ join:  @escaping (Self) -> Self,
        _ transform:@escaping (C) -> A
    ) -> Func<C, B> {
        transform >>> (self |> join)
    }
    
    func contraFlatMap<C>(
        _ join:  @escaping ((A) -> B) -> (A) -> B,
        _ transform: Func<C, A>
    ) -> Func<C, B> {
        transform >>> self.call |> join
    }
    
    func contraFlatMap<C>(
        _ join:  Func<Self, Self>,
        _ transform: Func<C, A>
    ) -> Func<C, B> {
        transform >>> (self.self |> join)
    }
    
    func dimap<C, D>(
        _ hoist: @escaping (C) -> A,
        _ lower: @escaping (B) -> D
    ) -> Func<C, D> {
        // C -> A >>> A -> B >>> B -> D = C -> D
        hoist >>> self >>> lower
    }
}

/*:
 Define a struct which wraps a function
 underneath and meets the above protocol.
 */
public struct Func<FA, FB>: CallableAsFunction {
    public typealias A = FA
    public typealias B = FB
    public let call: (FA) -> FB
    
    public init(_ call: @escaping (FA) -> FB) {
        self.call = call
    }
    
    public init(_ f: Func<A, B>) {
        self.call = f.call
    }
    
    public init<C>(_ f: @escaping (A) throws -> C) where B == Result<C, Error> {
        self = .init {
            do { return .success(try f($0)) }
            catch { return .failure(error) }
        }
    }
}

/*:
 # Combine as the composition of functions
 
 In the beginning is Demand for some values.
 You only have to say how much you want
 not what kind of thing you want. You can
 cancel anytime you want, which consists of indicating
 that you will never generate additional demand.
*/
public enum Demand {
    case none
    case max(Int)
    case unlimited
    case cancel
}
/*:
 And you might want to look at a demand and ask
 how big it is or if it is satisfied.
 */
extension Demand {
    var decremented: Demand {
        guard case .max(let value) = self else { return self }
        return value > 1 ? .max(value - 1) : .none
    }
    
    var unsatisfied: Bool {
        switch self {
        case .none: return false
        case .max(let val) where val > 0: return true
        case .max: return false
        case .unlimited: return true
        case .cancel: return false
        }
    }
    
    var satisfied: Bool { !unsatisfied }
}
/*:
 A Demand can be fulfilled with a Supply
 which can be either none, a value of the desired
 type, a failure to produce a value, or a notification
 that no future values can be forthcoming.
 
 Since Supply is a generic value parameterized by
 two other types, you expect it to have two
 map functions (and it does, in another file).
*/
public enum Supply<Value, Failure: Error> {
    case none
    case value(Value)
    case failure(Failure)
    case finished
}
/*:
 These are our 2 basic types.  Everything we do in this package
 is simply writing functions that manipulate supply and demand instances.
 Best of all, the manipulations that we want to do
 come in only 4 basic types of functions which can then be composed
 using only the standard functions on Func.
 So if you understand how to combine all these function-returning-functions
 you understand how Combine does its work.
 
 So diving into our function types...
 
 Ultimately, there must be a function which produces a Supply
 in response to a Demand.  We call such a function a Producer.
 */
public struct Producer<Value, Failure: Error> {
    public let call: (Demand) -> Supply<Value, Failure>
    public init(_ call: @escaping (Demand) -> Supply<Value, Failure>) {
        self.call = call
    }
}
/*:
 And of course it's `CallableAsFunction`
 */
extension Producer: CallableAsFunction {
    public typealias A = Demand
    public typealias B = Supply<Value, Failure>
    
    public init(_ f: Func<Demand, Supply<Value, Failure>>) {
        self.call = f.call
    }
}
/*:
 Since we have a function which can produce Supply in
 response to Demand, there must also be a function which
 consumes a Supply to satisfy a Demand.  We call
 such a function a Subscriber because it will not consume
 just one value of the supply, but an entire series of them
 until the demand is sated, as long as supply is available.
 
 In a very human manner a Subscriber consuming some Supply
 can induce even more Demand which it provides as its function
 return type.
 
 This way of describing the combination of producing
 and subscribing means that you can compose Subscribers
 with Producers. This should be very intuitive since it is
 how all of economics actually works as well.
 
 Composing a producer with a subscriber looks like this:
 
     (Demand) -> Supply >>> (Supply) -> Demand
 
 to yield:
 
     (Demand) -> Demand
 
 But... You can only form a Subscriber AFTER you have a Producer,
 so the composition of the two functions must be a `contraMap`
 or `contraFlatMap` (i.e. you have to prepend the Producer
 to the Subscriber).
 
 In particular, since we can produce Supply in batches, we are
 going to want to use `contraFlatMap`, which means that
 we are going to need at least one `join` function on
 Subscriber as well.
 
 This last point is _very_ important to understand, it reveals
 a huge amount about what `contraFlatMap` actually _means_
 
 `contraFlatMap`ping a Subscriber with a Producer yields a
 function from Demand to Demand as above:

     (Subscriber.contraFlatMap(Producer)) -> (Demand) -> Demand
 
 with the output function looping until either
 demand is sated or supply is exhausted.

 Note that this operation erases the Supply type in the process.
 
 So here's what Subscriber looks like, it's just the
 inverse of Producer:
 */
public struct Subscriber<Value, Failure: Error> {
    public let call: (Supply<Value, Failure>) -> Demand
    public init(_ call: @escaping (Supply<Value, Failure>) -> Demand) {
        self.call = call
    }
}
/*:
 And of course Subscribers are CallableAsFunction
 */
extension Subscriber: CallableAsFunction {
    public typealias A = Supply<Value, Failure>
    public typealias B = Demand
    
    public init(_ f: Func<Supply<Value, Failure>, Demand>) {
        self.call = f.call
    }
}
/*:
 To get a feel for why this is a contraFlatMap,
 let's see what a function which would implement
 the satiate/exhaust loop for a subscriber/producer
 pair might look like.  Note that the Producer<Value,Failure>,
 Subscriber<Value,Failure>, and Supply<Value, Failure>
 types have to match for the pairing to work.
 */
extension Subscriber {
    static func satiateOrExhaust(
        from producer: Producer<Value, Failure>,
        into subscriber: Subscriber<Value, Failure>
    ) -> Subscriber<Value, Failure> {
        .init { supply in
            var demand = subscriber(supply)
            while demand.unsatisfied {
                let nextSupply = producer(demand)
                switch nextSupply {
                case .none:
                    return demand
                case .value:
                    demand = subscriber(nextSupply)
                case .failure, .finished:
                    return subscriber(nextSupply)
                }
            }
            return demand
        }
    }
}
/*:
 Here we've constructed a new subscriber from the
 pairing of a producer and another subscriber.
 This "outer" subscriber receives a supply to kick things off
 and calls the inner subscriber and the producer repeatedly
 until either:

 1. the inner subscriber is satiated or
 2. the producer is exhausted.
 
 We need the outer subscriber so that we can iterate on the
 inner one. And _that_ is the key insight of contraFlatMap,
 not just in this case, but in all cases.  ContraFlatMap
 allows you to call a function (A) -> B multiple times while
 wrapped in context that also has signature (A) -> B, you
 just need an A to kick things off.
 
 Note that this is the dual of flatMap on a function.  In
 that case however we are given a function (B) -> C which
 already wraps another function (B) -> C which it can call
 multiple times.  This outer function just needs a B to
 kick things off.
 
 This sort of contraMap action is at the heart of
 Functional Reactive Programming (FRP).  In that model
 of writing applications, the values being passed
 through the functions are events which represent
 things that have occurred and data moves through
 applications in chains composed by contraMapping.
 
 So lets look closely at the signature of the
 satiate function.  If we curry it, it looks like this:
 
  (Producer) -> (Subscriber) -> Subscriber
 
 That last bit is telling.  It is precisely
 the signature of a `join` as used in a `contraFlatMap`
 of Subscriber. And that's something we'll be taking
 advantage of repeatedly below so keep it in mind.
 Let's move on to Subscriptions.
 
 A Subscription is a function which is its own independent source
 of demand, so it doesn't care about the demand returned from
 a Subscriber.  Hence a Subscription is a function
 (Demand) -> Void which can be derived as follows:
 
     (Subscriber.contraFlatMap(Producer)).map(void)
 
 erasing the Demand return type in the process.  The second
 `init` below allows us to go straight from:
 `(Subscriber.contraFlatMap(Producer))` to `Subscription` in
 this manner
 */
public struct Subscription {
    public let call: (Demand) -> Void
    public init(_ call: @escaping (Demand) -> Void) {
        self.call = call
    }
    
    public init(_ f: Func<Demand, Demand>) {
        self.init(f.map(void))
    }
}
/*:
 Subscription, too, is CallableAsFunction
 */
extension Subscription: CallableAsFunction {
    public typealias A = Demand
    public typealias B = Void

    public init(_ f: Func<Demand, Void>) {
        self.init(f.call)
    }
}
/*:
 Finally, we need some way of taking a Producer and a
 Subscriber and creating a Subscription.
 
 A Publisher is a curried function which combines a Producer
 and a Subscriber to yield a Subscription in precisely the manner
 shown above.  I.e. it has the form:
 
     (Producer) -> (Subscriber) -> Subscription

 That is to say that unlike Producer and Subscriber,
 Publisher is a higher-order function.  It accepts functions
 as input and produces functions as output.  (Remember,
 Producer, Subscriber and Subscription are themselves all
 functions).
 
 A Publisher can be initialized with a Producer (i a separate init below)
 or directly with a function (Subscriber) -> Subscription.
 This is a critical point.  There are several ways of preparing
 a Publisher, but the all _must_ end at:
 
     (Subscriber) -> Subscription
 
 In fact, most of this library is actually composed of functions
 of the form:
 
     (Publisher) -> (Subscriber) -> Subscription
 
 where a Publisher is created by "chaining" it onto another
 Publisher.  The forms that this can take are what make
 this technique so powerful.
 
 And as always, because Publisher is parameterized by
 generic types, it too, has multiple forms of map.  Which
 we will explore in detail.
*/
public struct Publisher<Output, Failure: Error> {
    public let call: (Subscriber<Output, Failure>) -> Subscription
    public init(_ call: @escaping (Subscriber<Output, Failure>) -> Subscription) {
        self.call = call
    }
}
/*:
 Guess what, CallableAsFunction :)
 */
extension Publisher: CallableAsFunction {
    public typealias A = Subscriber<Output, Failure>
    public typealias B = Subscription
    
    public init(_ f: Func<Subscriber<Output, Failure>, Subscription>) {
        self.call = f.call
    }
}
/*:
 Summarizing:
 
 All of FreeCombine is implemented
 as composition of the 2 basic value types
 using the 3 basic function types
 and one higher-order function type.
 
 To reiterate, the value types are:
 
     Demand
     Supply
 
 and the base function types (all represented as "call-as-function"
 Swift structs) are:
 
     Producer: (Demand) -> Supply
     Subscriber: (Supply) -> Demand
     Subscription: (Demand) -> Void
 
 The higher-order function type is Publisher:
 
     Publisher: (Subscriber) -> Subscription
 
 which takes on two even higher higher-order forms when curried
 as:
 
    (Producer)  -> (Subscriber) -> Subscription  and
    (Publisher) -> (Subscriber) -> Subscription
 
 these forms are not given names but much of the library is
 given over to them.
 
 We "Combine" these elements using the basic functional
 programming elements as follows:
 
    On Supply we use: map
 
    And on Subscriber and Subscription we use: contraFlatMap
 
    And on Publisher we use: dimap
 
 to form a plethora of more complex forms
 
 These are all functions we defined on our Func struct.
 
 And this is _all_ we need to create something like
 Combine or RxSwift.

 ### A little philosophy
 
 To do anything we need to connect our Producer type to our
 Subscriber type.  Subscriber is a function:
 
     (Supply) -> Demand
 
 Producer is a function:
    
     (Demand) -> Supply
 
 Clearly the two functions compose, the question is which way?
 I.e. do I want to end up with a function of (Demand) -> Demand
 or of (Supply) -> Supply.  Which comes first the chicken or the
 egg?
 
 In this, as in economics, Demand precedes Supply and
 is fed Supply which arises to satiate it, so
 we want to prepend our Producer function to our Subscriber
 function. Prepending says immediately that we will need
 to contraMap the Producer function onto the Subscriber
 function.
 
 There's one added wrinkle: we want to repeatedly
 call producer, feeding its output to the subscriber until
 either the producer can't produce anymore or the subscriber
 responds with no further demand.  Making multiple calls
 is precisely why `contraFlatMap` exists.
 
 Look closely at the signature of `contraFlatMap`
 
     func contraFlatMap<C>(
         _ join:  @escaping (Self) -> Self,
         _ transform:@escaping (C) -> A
     ) -> Func<C, B>
 
 That join at the beginning is a little weird. `contraFlatMap`
 allows us to wrap self (the subscriber function) in another
 function of the same signature which calls the self (inner
 function) as many times as necessary to deliver the values.
 This is precisely what we want.
 
 We will form an outer `join` function which when given
 an initial value will repeatedly call the producer
 and subscriber functions until one of them is exhausted.
 
 Here's what such a join function looks like.
 */
extension Subscriber {
    static func join(
        _ producer: Producer<Value, Failure>
    ) -> (Self) -> Self {
        return { subscriber in .init(satiateOrExhaust(from: producer, into: subscriber).call) }
    }
}
/*:
 This is the curried form I described above:
 
     (Producer) -> (Subscriber) -> Subscriber
 
 Where the meaning of this particular `join` is described
 by the `satiate` function.  This is the pattern we will
 adopt throughout.  We'll name a `join` and then see what
 we can do with it in the context of Publisher chaining.
 
 Note that the inner function is kicked off with a Supply.
 In FreeCombine this will always be the case.  Subscribers
 are functions (Supply) -> Demand, so `contraFlatMap`ping them
 will always require us to preserve that signature and
 our joins will have the form:
 
     (Subscriber) -> Subscriber
 
 or in detail:
 
     ((Supply) -> Demand) -> ((Supply) -> Demand)
 
 This supply is then provided to the downstreamSubscriber
 to obtain more demand.  If there is positive demand,
 we ask the producer for more supply. If there is any,
 we in turn feed the supply to the downstream.  Lather,
 rinse, repeat until one is exhausted.
 
 Now we can call `contraFlatMap` on the subscriber, rolling
 the producer up in our join function (remember the signature):

     func contraFlatMap<Demand>(
         _ join:  @escaping ((Supply) -> Demand) -> ((Supply) -> Demand),
         _ transform:@escaping (Demand) -> Supply
     ) -> Func<Demand, Demand>


 and passing the producer itself as the transform function.
 
 That one line produces a function (Subscriber) -> Subscription
 that when kicked with a demand will repeatedly call the producer
 and subscriber until one of them is exhausted.
 
 Here's how that looks:
 */
public extension Publisher {
    init(_ producer: Producer<Output, Failure>) {
        self.call = { subscriber in
            .init(subscriber.contraFlatMap(Subscriber.join(producer), producer.call))
        }
    }
}
/*:
 And now we can start writing Combine-like functions
 */
