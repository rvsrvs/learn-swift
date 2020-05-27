/*:
 # Higher Order Functions IV - Contravariance and Combine

 ![Swift Type System](swift-type-system.png)
 
 ### Things we need for Combine
 
 1. higher-order functions on sum types (`map`, `flatMap`)
 2. Nominal function types (`callAsFunction` and `composition`)
 3. Contravariance I: `contraFlatMap`
 4. Contravariance II: `dimap`
 5. Currying: `curry` and `uncurry`
 6. Polymorphism via partial application (instead of inheritance)
 7. Flip and static methods
 8. tail call optimization via trampolining
 
 ### Things we need for Uni-directional Dataflow Architecture
 
 1. Reducers
 2. Higher-order reducers
 3. Contravariance III: `contraMap`
 */

/*:
 Handy functions for composition

```
public func identity<T>(_ t: T) -> T { t }
public func void<T>(_ t: T) -> Void { }
public func cons<T>(_ t: T) -> () -> T { { t } }
public func unwrap<T>(_ t: T?) -> T { t! }
```
 */

/*:
 ### Higher order functions on sum types
 Let's review `map` and `flatMap`
 
 The map function has the following signature on each of the types shown:

 ```
  Optional<A>: func map<B>( (A) ->  B ) ->   Optional<B>
    Result<A>: func map<B>( (A) ->  B ) ->     Result<B>
```
 
 And flatMap looks like this:
 
 ```
  Optional<A>: func flatMap<B>( (A) ->   Optional<B> ) ->   Optional<B>
    Result<A>: func flatMap<B>( (A) ->     Result<B> ) ->     Result<B>
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
 
```
 So we see that essentially any of the generics we
 use every day have map and flatMap defined on them.
 
 */

/*:
### Composition and CallAsFunction
```
public func >>> <A, B, C>(
    _ f: @escaping (A) -> B,
    _ g: @escaping (B) -> C
) -> (A) -> C {
    { (a: A) -> C in g(f(a)) }
}
```

 To be clear composition does this:
 
     (A) -> B >>> (B) -> C
 
 becomes:
 
     (A) -> C
 
 and:
 
     (A) -> (B) -> C >>> (C) -> (D) -> E
 
 becomes:
 
     (A) -> (B) -> (D) -> E
 
 and so on:

 ![Composition](Composition.png)
 
 And on the nominally-typed functions we have:
```
extension Func {
    func map<C>(
        _ f: @escaping (B) -> C
    ) -> Func<A, C> {
        self >>> f
    }
}
```
 Yeah, map on this struct is just composition.
 
     (A) -> B >>> (B) -> C => (A) -> C
 
 But this is where Func is a little different.  It has two sides.
 And therefore it has a second form of map.
```
extension Func {
    func contraMap<C>(
        _ f: @escaping (C) -> A
    ) -> Func<C, B> {
        f >>> self
    }
}
```
 Reverse composition.  In this case we have:
 
     (C) -> A >>> (A) -> B = (C) -> B
 
 
 So what does flatMap look like on Func?
```
extension Func {
    func flatMap<C>(
        _ f: @escaping (B) -> (A) -> C
    ) -> Func<A, C> {
        .init { (a: A) -> C in (self >>> f)(a)(a) }
    }
}
```
 Is there a contraFlatMap?  of course there is!
 
 But this one needs more explanation.
 
### Contravariance I: `contraFlatMap`

```
extension Func {
    func contraFlatMap<C>(
        _ join:  @escaping ((A) -> B) -> (A) -> B,
        _ transform:@escaping (C) -> A
    ) -> Func<C, B> {
        transform >>> join(self.call)
    }
}
```
### Contravariance II: `dimap`

```
 extension Func {
    func dimap<C, D>(
        _ hoist: @escaping (C) -> A,
        _ lower: @escaping (B) -> D
    ) -> Func<C, D> {
        hoist >>> self >>> lower
    }
}
```
 
### Currying

```
 public func curry<A, B, C>(
     _ function: @escaping (A, B) -> C
 ) -> (A) -> (B) -> C {
     { (a: A) -> (B) -> C in
         { (b: B) -> C in
             function(a, b)
         }
     }
 }
```
 
 So let's use this stuff
 
 ![Identity Join](JoinIdentity.png)
 
 
 
 ![Producer Join](JoinProducer.png)

 
 
 
 ![ContraFlatMap](ContraFlatMap.png)
 
 
 
 ![Publisher](PublisherProducer.png)

 
 ![Subscription](Subscription.png)
 
 
 ![Dimap](Dimap.png)


 ![Publisher Chaining](PublisherChaining.png)

 */
