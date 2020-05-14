
/*:
 ### Problem 1
 
 The map function has the following signature on each of the types shown:
 ```
     Array<A>: func map<B>( (A) ->  B ) ->      Array<B>
  Optional<A>: func map<B>( (A) ->  B ) ->   Optional<B>
    Result<A>: func map<B>( (A) ->  B ) ->     Result<B>
 Publisher<A>: func map<B>( (A) ->  B ) ->  Publisher<B>
    Future<A>: func map<B>( (A) ->  B ) ->     Future<B>
 ```
 In Swift 5.2 it is not possible to write a single protocol which describes map for
 all of the above.  Try to do it
 and explain what prevents it from being done.  Explain why, even if it could be done, it
 could not be implemented as an existential type.
 */

/*:
 ### Problem 2
 
 Write the following functions as generics:
 
 1. a function called `identity` which accepts a value of a generic type and returns it
 2. a function called `void` which accepts a value of a generic type and returns void
 3. a function called `cons` which accepts a value of a generic type and returns a void-accepting function which in turn returns the value
 4. a function called `unwrap` which accepts an optional value of a generic type and returns an implicitly unwrapped value of that type
 */

/*:
 ### Problem 3
 
 I am defining the following operator to facilitate readability below.  _*In one word*_
 describe what it does. _*In two symbols*_ state which syntactic element in the
 implementation causes the two inputs to require the `@escaping` keyword
 */
precedencegroup CompositionPrecedence {
  associativity: right
  higherThan: AssignmentPrecedence
  lowerThan: MultiplicationPrecedence, AdditionPrecedence
}
infix operator >>>: CompositionPrecedence
public func >>> <A, B, C>(
    _ f: @escaping (A) -> B,
    _ g: @escaping (B) -> C
) -> (A) -> C {
    { (a: A) -> C in g(f(a)) }
}
/*:
 For the following problems write the specified code using this type:
 */
struct Func<A, B> {
    var call: (A) -> B
    
    public init(_ call: @escaping (A) -> B) {
        self.call = call
    }

    func callAsFunction(_ a: A) -> B {
        call(a)
    }
}
/*:
 ### Problem 4
 
 In one line of code each, extend the operator above by
 implementing the following overloads.
 Use point-free style and allow the compiler to do as much type inference
 as possible.

 ```
 func >>> <A, B, C> (
     _ f: @escaping (A) -> B,
     _ g: Func<B, C>
 ) -> Func<A,C>

 func >>> <A, B, C>(
     _ f: Func<A, B>,
     _ g: @escaping (B) -> C
 ) -> Func<A,C>
 
 func >>> <A, B, C> (
     _ f: Func<A, B>,
     _ g: Func<B, C>
 ) -> Func<A,C>

```
 
 */

/*:
 ### Problem 5 - Map
 
 In an extension to Func, and using the above operators, write the map function with the following signature
 in one line of code, using point-free style and as much inference as possible.
 ```
 func map<C>(
     _ f: @escaping (B) -> C
 ) -> Func<A, C>
 ```

 */

/*:
### Problem 6 - ContraMap

In an extension to Func, and using the above operators,  in a separate extension
write the contraMap function with the following signature
in one line of code, using point-free style and as much inference as possible.
```
func contraMap<C>(
    _ f:  @escaping (C) -> A
) -> Func<C, B>
```
*/

/*:
### Problem 7 - FlatMap

In an extension to Func, and using the above operators, in a separate extension
write the flatMap function with the following signature
in one line of code, using point-free style and as much inference as possible.
```
func flatMap<C>(
    _ f:  @escaping (B) -> (A) -> C
) -> Func<A, C>
```
*/

/*:
### Problem 8 - ContraFlatMap

In an extension to Func, and using the above operators,  in a separate extension
write the contraFlatMap function with the following signature
in one line of code, using point-free style and as much inference as possible.
```
func contraFlatMap<C>(
    _ join:  @escaping ((A) -> B) -> (A) -> B,
    _ f:  @escaping (C) -> A
) -> Func<C, B>
```
*/

/*:
### Problem 9 - DiMap

In an extension to Func, and using the above operators,  in a separate extension
write the dimap function with the following signature
in one line of code, using point-free style and as much inference as possible.
```
func dimap<C, D>(
    _ f:  @escaping (C) -> A,
    _ g:  @escaping (B) -> D
) -> Func<C, D>
```
*/
