/*:
 # Algebraic Data Types II - Algebra with Types
 
 ### The Meaning of Generics
 
 Ok so we have arithmetic of types.  We can add them, multiply them
 and raise them to powers.  Do we have algebra as well?  Can we have
 functions of types.  Sure we can!
 
 Generics are the functions of types - they take types in and return new types.
 This is the important point, we pass a type or types to a function and
 they give us entirely new types.
 
 There's one very big difference, these functions don't get invoked
 at run time - they can only be invoked at compile time.  If you think about
 it, we want to use the types that generics give us in our code, so
 these type functions need to run during the compile phase so that we
 can use the results.  If they ran at run time we could not have written
 code that used the types we created.
 
 In  a very real sense generics are us programming
 the Swift compiler to produce usable new types for us.
 
 Lets extend our Optional example from above.
 */
enum Optional<T> {
    case some(T)
    case none
}
/*:
 Here's a really informative way to look at that:

    f(x) = x + 1

`Optional<T>` is a function that takes a type T as an argument and
 adds one value to it, so its cardinality is the cardinality of T
 plus one.  Addition in ADT's is represented by an enum,
 so the Optional needed to be an enum.
*/
enum Either<X, Y> {
    case left(X)
    case right(Y)
}
/*:
 The cardinality of that is:
 
    f(x) = x + y
 */
struct Both<X, Y> {
    var x: X
    var y: Y
}
/*:
The cardinality of that is:

   f(x) = x * y

 Understanding the above
 is one of the places where nominal typing can obscure some
 really important insights.  People coming to Swift from ObjC or
 another language without a reasonably complete system of ADT's
 will look at Optional and think: "This is just their way of avoiding
 segfaults for NULL values".  Well, yes, it is.
 But it's actually
 much more.  It's a very general way of incrementing types.  And
 that functionality is so important that it has been given special
 syntax and a specific nominal type in the language.
 
 So look at Generics and think: function of types.
 Swift helps you with this, because even the syntax
 is reminiscent of function: `Optional<T>`
 _looks_ as if we are passing a T to a function.

 ### The meaning of protocols
 
 I highly recommend that you read [Joe Groff's explanation of how protocols and generics are related](https://forums.swift.org/t/improving-the-ui-of-generics/22814)
 
 I'll summarize it a bit for this context:
 
 1. Generics can be thought of as functions of types.  You plug in a type to a generic
 and it produces a new type as a result, just like giving any pure function an input value
 produces an output value.  And that's fun to do.  It's like drawing graphs in algebra,
 we put in a value, get an output and plot the two against each other.
 
 2. But... (you knew that was coming) It is really handy though to be
 able to _solve_ systems of functions simultaneously. That is, you want to say:
 yes I know that if f(x) = x^2 I can draw a pretty graph.  But what value(s) of
 x makes f(x) = 4.  For that we need _type constraints_.
 
 3. But constraints can both over- and under-constrain a problem. Under-constrain means
 that for f(x) = x^2, we constrain x >= 0.  There are lots of solutions to that problem.
 How 'bout if I make a constrain that f(x) < 0?  There aren't any solutions to that. In
 the first case, I have under-constrained the problem in that if I want the type system
 to produce a type with that set of constraints, it can't because it doesn't have enough
 information to know which one I mean.  In the second, it can't because there is no
 such type.
 
 4. Properly done, when we apply constraints to generics, there can be only one type
 that exists and the compiler can give us that type to work with.  This type is called
 the existential type. And it's what a protocol really is.
 
 3. Swift offers a really powerful system of type constraints.
 
 1. Protocols emerge when you try to solve simultaneous functions of types - the represent existential quantification
 2. For protocols, Swift creates the existential type and it is that type that you extend when you write a protocol extension.
 3. Existential types (aka protocols) are just as "real" as Universal types (aka generics)

 */

