/*:
 # Higher Order Functions IV - Contravariance and Combine

 ![Swift Type System](swift-type-system.png)
 
 ![Functional Programming Patterns](fp.png)

 ![Lessons from Haskel](haskell.png)

 ### Things we need for Combine
 
 1. higher-order functions on sum types (`map`, `flatMap`)
 2. Nominal function types (`callAsFunction`)
 3. Contravariance I: `contraFlatMap` and Transducers
 4. Contravariance II: `diMap`
 5. Currying
 6. Polymorphism via partial application (instead of inheritance)
 7. tail call optimization via trampolining
 
 ### Things we need for Uni-directional Dataflow Architecture
 
 1. Reducers
 2. Higher-order reducers
 3. Contravariance III: `contraMap`
 */

precedencegroup CompositionPrecedence {
  associativity: right
  higherThan: AssignmentPrecedence
  lowerThan: MultiplicationPrecedence, AdditionPrecedence
}
infix operator >>>: CompositionPrecedence

/*:
 Handy functions for composition
 */
public func identity<T>(_ t: T) -> T { t }
public func void<T>(_ t: T) -> Void { }
public func cons<T>(_ t: T) -> () -> T { { t } }
public func unwrap<T>(_ t: T?) -> T { t! }

/*:
 Let's review `map` and `flatMap`
 
 The map function has the following signature on each of the types shown:

 ```
     Array<A>: func map<B>( (A) ->  B ) ->      Array<B>
  Optional<A>: func map<B>( (A) ->  B ) ->   Optional<B>
    Result<A>: func map<B>( (A) ->  B ) ->     Result<B>
 Publisher<A>: func map<B>( (A) ->  B ) ->  Publisher<B>
    Future<A>: func map<B>( (A) ->  B ) ->     Future<B>
```

 In Swift 5.2 it is not possible to write a single protocol
 which describes map for all of the above because you are not
 allowed to include generic types in conjuction with the
 `associatedtype` keyword.
 
 And flatMap looks like this:
 
 ```
     Array<A>: func flatMap<B>( (A) ->      Array<B> ) ->      Array<B>
  Optional<A>: func flatMap<B>( (A) ->   Optional<B> ) ->   Optional<B>
    Result<A>: func flatMap<B>( (A) ->     Result<B> ) ->     Result<B>
 Publisher<A>: func flatMap<B>( (A) ->  Publisher<B> ) ->  Publisher<B>
    Future<A>: func flatMap<B>( (A) ->     Future<B> ) ->     Future<B>
 ```
 
 Let's look at a couple of the flatMaps, first Optional:

```
 @inlinable
 public func flatMap<U>(
   _ transform: (Wrapped) throws -> U?
 ) rethrows -> U? {
   switch self {
   case .some(let y):
     return try transform(y)
   case .none:
     return .none
   }
 }
```
 Here's Result
 
```
 public func flatMap<NewSuccess>(
   _ transform: (Success) -> Result<NewSuccess, Failure>
 ) -> Result<NewSuccess, Failure> {
   switch self {
   case let .success(success):
     return transform(success)
   case let .failure(failure):
     return .failure(failure)
   }
 }
```
 
 And here's Array
 
```
   @inlinable
   public func flatMap<SegmentOfResult: Sequence>(
     _ transform: (Element) throws -> SegmentOfResult
   ) rethrows -> [SegmentOfResult.Element] {
     var result: [SegmentOfResult.Element] = []
     for element in self {
       result.append(contentsOf: try transform(element))
     }
     return result
   }
 }
```
 So we see that essentially any of the generics we
 use every day have map and flatMap defined on them.
 
 */

/*:
 So what would it look like if we did a generic
 nominally-typed function?
 
 Lets define a struct which wraps a function
 underneath and meets the above protocol.
 */
public struct Func<A, B> {
    public let call: (A) -> B
    
    public init(_ call: @escaping (A) -> B) {
        self.call = call
    }
}
/*:
 So, we've created this nominally-typed function
 thingy, what can we do with it.  Well one thing
 would be to do composition.
 */
public func >>> <A, B, C>(
    _ f: @escaping (A) -> B,
    _ g: @escaping (B) -> C
) -> Func<A, C> {
    .init { (a: A) -> C in g(f(a)) }
}
// (A) -> B >>> (B) -> C => (A) -> C
/*:
 And to be complete lets do this:
 */
func >>> <A, B, C> (
    _ f: @escaping (A) -> B,
    _ g: Func<B, C>
) -> Func<A,C> {
    f >>> g.call
}

func >>> <A, B, C>(
    _ f: Func<A, B>,
    _ g: @escaping (B) -> C
) -> Func<A,C> {
    f.call >>> g
}

func >>> <A, B, C> (
    _ f: Func<A, B>,
    _ g: Func<B, C>
) -> Func<A,C> {
    f.call >>> g.call
}

/*:
 To be clear composition does this:
 
     (A) -> B >>> (B) -> C
 
 becomes:
 
 (A) -> C
 
 and:
 
    (A) -> (B) -> C >>> (C) -> (D) -> E
 
 becomes:
 
    (A) -> (B) -> (D) -> E
 
 and so on:
 
 So what would map look like?  How 'bout this?
 */
extension Func {
    func map<C>(
        _ f: @escaping (B) -> C
    ) -> Func<A, C> {
        self >>> f
    }
}
/*:
 Yeah, map on this struct is just composition.
 
     (A) -> B >>> (B) -> C = (A) -> C
 
 But this is where Func is a little different.  It has two sides.
 And therefore it has a second form of map.
 */
extension Func {
    func contraMap<C>(
        _ f: @escaping (C) -> A
    ) -> Func<C, B> {
        f >>> self
    }
}
/*:
 Reverse composition.  In this case we have:
 
     (C) -> A >>> (A) -> B = (C) -> B
 
 So... where would you use this?  How about a type you
 are really familiar with?
 */
let array = [1.0, 2.0, 3.0, 4.0]

typealias Predicate<A> = Func<A, Bool>
let containedIn = Predicate<Double> { array.contains($0) }

extension Predicate {
    func evaluate(at value: A) -> Bool { self.call(value) as! Bool }
}
/*:
 ContraMap gets used in situations where you a wrapping
 up a function which has a fixed return type, but which
 can have varying input types.
 
 Which means that we should go back and look at `map` as being
 a form which has fixed input types, but varying return types.
 
 The thing to realize is that if I want to change a
 
     Predicate<Double> -> Predicate<Int>
 
 I have to provide:
 
     (Int) -> Double
 
 rather than:
 
     (Double) -> Int
 
 Which seems entirely backwards.  The trick is to see
 through Predicate<Double> to its true character as a
 Func<Double, Bool>
 
 */
let intContainedIn = containedIn.contraMap {(val: Int) in Double(val) }
    
intContainedIn.evaluate(at: 5)

/*:
as a reminder
 ```
     Array<A>: func flatMap<B>( (A) ->      Array<B> ) ->      Array<B>
  Optional<A>: func flatMap<B>( (A) ->   Optional<B> ) ->   Optional<B>
    Result<A>: func flatMap<B>( (A) ->     Result<B> ) ->     Result<B>
 Publisher<A>: func flatMap<B>( (A) ->  Publisher<B> ) ->  Publisher<B>
    Future<A>: func flatMap<B>( (A) ->     Future<B> ) ->     Future<B>
```
 
 So what does flatMap look like on Func?
 */
extension Func {
    func flatMap<C>(
        _ f: @escaping (B) -> (A) -> C
    ) -> Func<A, C> {
        // (A) -> B
        // (B) -> (A) -> C
        // (A) -> B >>> (B) -> (A) -> C
        // (A) -> (A) -> C
        .init { (a: A) -> C in (self >>> f).call(a)(a) }
    }
}

/*:
 Is there a contraFlatMap?  of course there is!
 
 But this one needs more explanation.
 */
extension Func {
    func contraFlatMap<C>(
        _ join:  @escaping ((A) -> B) -> (A) -> B, // Self -> Self
        _ transform:@escaping (C) -> A
    ) -> Func<C, B> {
        transform >>> join(self.call)
    }
}
/*:
 Ok, one more form for this stuff:
 */
extension Func {
    func dimap<C, D>(
        _ hoist: @escaping (C) -> A,
        _ lower: @escaping (B) -> D
    ) -> Func<C, D> {
        hoist >>> self >>> lower
    }
}
