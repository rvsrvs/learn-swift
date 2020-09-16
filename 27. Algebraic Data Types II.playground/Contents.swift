import Foundation
/*:
 # Algebraic Data Types II - Algebra with Types
 
 Quick review, we saw the following things in the previous
 playground:
 
 1. Types are "bags of values" where we can say what
 values are in, what values are out and we can distinguish each
 value unambiguously from each other value.
 2. We can determine the cardinality of any of our types
 3. Structs and tuples are product types
 4. Enums are sum types
 5. Functions are themselves types and in particular are exponential types
 6. Structs and enums are nominal types
 7. Tuples are structural types (called compound types in the apple doc)
 8. Functions can take as arguments and return either
 nominal or structural types but they themselves are structural types
 9. Multi-argument functions are in one-to-one correspondence
 with their curried form and can be mechanically converted to
 the curried form and back
 10. Order of arguments to a function does not break currying
 11. Void is the type inhabited by only one value
 12. Never is the type inhabited by zero values
 
 All of this constitutes an arithmetic of types.
 
 ### The Meaning of Generics
 
 Ok so we have arithmetic of types.  We can add them, multiply them
 and raise them to powers.  Do we have algebra as well?  Can we have
 functions of types?  Sure we can!
 
 Generics are the functions of types - they take types in and return new types.
 This is the important point, we pass a type or types to a function and
 they give us entirely new types.
 
 There's one very big difference, these functions don't get invoked
 at run time - they can only be invoked at compile time.  If you think about
 it, we want to use the types that generics give us in our application, so
 these type functions need to run during the compile phase so that we
 can use the results.  If they ran at run time we could not have written
 code that used the types we created.
 
 In  a very real sense generics are us programming
 the Swift compiler to produce usable new types for us.
 
 ### Some Rules and a Digression
 
 Swift is a statically typed language.  That can mean a number of things,
 but for us, what it means is this: you can only make new types at compile
 time _NOT_ at runtime.  At runtime your code can
 only generate, use and destroy values of known types, it can't generate or
 destroy new types. This means that the cardinality of _every_ type
 must be known before runtime because the complete set of possible
 values of a given type _must_ be known before
 you are allowed to run your code.  This in turn means that every type
 must be completely specified when you compile your code, and no type
 your code will use can be left incompletely specified.  Additionally,
 nominal types must have their entire set of functions known by the
 time you get to runtime as well.
 
 The most numerous and frustrating errors you will get
 from the compiler are in fact those that tell you that you have
 failed to correctly specify a type.  Those are the ones where you will
 need to reason as the compiler does to address them.  Swift 5.2
 is an enormous step up in terms of generating usable error messages
 but you'll have to understand what you are doing to make sense of
 what it is telling you.
 
 ### Static vs Dynamic (Yes, lets poke the hornets nest)
 
 Given that other languages allow types to be determined at runtime
 this seems like it's too restrictive, i.e. other languages seem to be able to
 do things that Swift can't.  So why does Swift do it that way? What's
 the point?
 
 The point is that separating type generation and type usage into two
 distinct phases allows the compiler to do a lot of work for you that
 it can't in the dynamic typing style.  For example, there are whole
 classes of errors in dynamic typing systems that you can't even write
 in Swift, the compiler will simply refuse to compile them.  And it
 will bark at you as soon as you type them.
 
 (One of the big complaints
 I hear from people new to the language is that they spend all their
 time trying to make the compiler happy rather than programming.
 But don't be concerned, gradually what will happen is that the compiler
 will teach you to think about your program in a more thoroughly
 specified way.)
 
 So this distinction between compile-time and run-time has two big
 benefits for you:
 
 1. In dynamic
 languages you must write code to test for the errors that Swift
 won't even let you type or, more likely,
 find them at run time when some unexpected combination of data tickles
 code that you didn't think about.
 
 2. Static typing also helps Xcode help you write your code.  Lots of code
 completion is enabled only because the Swift compiler knows that in a
 given situation there are only a small number of availble things it will
 allow you to do.
 
 Whether you prefer this to dynamic typing or not,
 to use Swift effectively, you need to be able to use the tooling in this
 way. Fighting the compiler to let you use dynamic types is a losing
 proposition.
 
 Just as a side note [here's one of my favorite write ups
 on the difference](https://lexi-lambda.github.io/blog/2020/01/19/no-dynamic-type-systems-are-not-inherently-more-open/).
 It's about Haskell vs JavaScript but all the same arguments apply
 around Swift.
 
 ### Using Generics
 
 Lets extend our Optional example from above.
 */
enum Optional<T> {
    case some(T)
    case none
}
/*:
 Here's a really informative way to look at that:

    f(x) = x + 1

 What I'm saying there is that
 `Optional<T>` is a function that takes a type T as an argument and
 adds one value to it, so its cardinality is the cardinality of T
 plus one.  Addition in ADT's is represented by an enum,
 so for Optional to play the role of adding one additional value,
 it needed to be an enum.
 
 This formulation of Optional is one of the places where nominal typing
 can obscure some really important insights. Because the class is named
 "Optional" people coming to Swift from ObjC or
 another language without a reasonably complete system of ADT's
 will look at Optional and think: "This is just their way of avoiding
 segfaults for NULL values in my types".  Well, yes, it is.
 But it's actually much more.  It's a very general way of incrementing
 types.  And that functionality is so important that it has been given special
 syntax and a specific nominal type in the language.
 
 Let's do some more examples.  Suppose I wanted to express the
 idea of multiplying a type by a constant, say 2?
 */
struct Mult<X> {
    var x: X
    var y: Bool
}
/*:
 Algebraically, that is saying:
 
     f(x) = 2x
 
 Here's a type that Swift doesn't have exactly, but
 which other languages do have as standard.  It's a
 type that adds two other types together:
*/
enum Either<X, Y> {
    case left(X)
    case right(Y)
}
/*:
 The cardinality of that is:
 
    f(x, y) = x + y
 
 (The closest thing Swift has is Result).  Here's
 an example of multiplying two types:
 */
struct Both<X, Y> {
    var x: X
    var y: Y
}
/*:
 The cardinality of that is:

   f(x) = x * y
  
 How about (x+1)^y
 */
func powerOfTypes<X, Y>(y: Y) -> X? {
    .none
}
/*:
 (I could have done x^y, but then I'd need figure out
 how to fill in the function.)
 
 So look at Generics and think: function of types.
 Swift helps you with this, because even the syntax
 is reminiscent of function: `Optional<T>` just
 _looks_ as if we are passing a T to a function.
 
  ### Structural -> Nominal types and back
  
  It's always been possible to go back and forth between tuples
  and structs.  Simply create an init on a struct that takes a tuple
  and a var that provides it back.  But it was not possible to do the
  same with functions.
  
  As of Swift 5.2 it is possible to embed functions in structs, thereby turning them
  into nominal types.  We can even do that generically.
  */
public struct Func<A, B> {
    public let call: (A) -> B
    
    public init(_ call: @escaping (A) -> B) {
        self.call = call
    }
    
    func callAsFunction(_ a: A) -> B {
        call(a)
    }
}

let f = Func { (a: Int) in a * 2 }
type(of: f)
f(2)
/*:
  We will make extensive use of this in a future playground
  because it allows us to write higher-order functions on
  functions.
  
 ### Another Digression: The meaning of "object"
 
 Up to now, we haven't talked about "objects"
 or "classes". We've only talked about types and the functions
 that act on them.  This has been intentional.  The concepts
 are related, but "object" is a separate idea built on top of
 type.  There's an entire playground where I show how this
 works in detail, but for now we'll just discuss the mechanism
 for turning instances of types into objects, because
 this mechanism is very much interlaced with the idea
 of type constraints.
 
 The big use of nominal types is to be able to distinguish types
 which have the exact same structure from each other i.e. to
 give them separate namespaces.  Why would be need separate namespaces?
 Because we want to give different behavior to each named type.
 This is precisely what it means to be "Object Oriented".
 
 Well, ok, OOP is more completely defined by the ideas of polymorphism
 and encapsulation.  (Note, I am _NOT_ including inheritance in that
 list as a fundamental aspect of OO because inheritance is really just
 a technique for achieving polymorphism).  Swift's approach to achieving
 encapsulation and polymorphism is to use the namespace created for
 nominal type to assign a function as belonging to the type.
 
 It does this by allowing the declaration of "extensions".
 Extensions contain the functions that are assigned to that
 type's namespace.  You can have as many of them as you like
 and any nominal type can be extended. Here's an example:
 */
extension Int {
    static var someString: String { "Made up string" }
    var timesTwo: Int { self * 2 }
    static func addTogether(_ a: Int, _ b: Int) -> Int { a + b }
    static func addTogether2(_ a: Int) -> (Int) -> Int {
        return { b in a + b }
    }
    func add(_ other: Int) -> Int { self + other }
}

func addTogether(_ a: Int, _ b: Int) -> Int { a + b }

Int.someString

let i = 6
Int.addTogether(6, 11)
addTogether(6, 11)
i.add(11)
Int.addTogether2(i)(11)

type(of: Int.addTogether)
type(of: Int.add)
type(of: Int.addTogether2)
/*:
 If you go look in the object file that the compiler produces from
 the above code, you will find the following (suitably translated
 for you to be able to easily read it):
 
     func Int.someString() -> String
     func Int.timesTwo(Int) -> Int
     func Int.addTogether(Int, Int) -> Int
     func Int.add(Int) -> (Int) -> Int
 
 The compiler attaches behavior to types (i.e. turns the
 types instances into "objects" simply by:
 
 1. prepending the type name to the function names in the
 extension
 
 2. adding a curried layer passing in `self` to the _"instance
 methods"_ of the type
 
 3. changing var definitions into getter/setter pairs of functions
 
 We'll go into this in excruciating detail in a future playground, but
 for now, I want you to observe that we can add aditional
 information to types by using namespaces.  This becomes
 very important when we go to constrain our types because
 the constraints will operate not just on cardinality as
 we have been discussing up to now, but on the operations
 that we have added to the nominal types.
 
 With that, lets move on to one more type that Swift
 provides and then see how we can do some more algebra
 with types.
 
 ### The meaning of protocols
 
 I highly recommend that you read
 [Joe Groff's explanation of how protocols and generics are
 related](https://forums.swift.org/t/improving-the-ui-of-generics/22814)
 
 Let me take a few liberties to write what I think he should have said:
 
 ```
 Hey guys,
 
 Sorry.  We messed up when we designed the protocol feature for the language.
 We were sort of blindly copying what we had done in ObjC that we liked
 and we just didn't think it completely through.  We wish we could do better,
 because we love you guys, but a bunch of people have already written a bunch of
 code, so we're stuck and the best we can do is try to make it a little less
 painful.  Again, we're sorry.  We won't let it happen again because now
 we know.
 
 Joe
 ```
 
 Ok, it feels really good to have gotten that off my chest.  Let me explain
 what I mean by it.
 
 We'll start by explaining the idea of "existential" types. Here's one:
 */
protocol AlternativeCustomStringConvertible {
    var description: String { get }
    var alternativeDescription: String { get }
}
/*:
 This looks a lot like a struct doesn't it?  That's because it is.
 
 What the compiler does with that code, unbeknownst to you, is to
 create a struct that looks like this:
 */
struct _AlternativeCustomStringConvertible {
    var description: () -> String
    var alternativeDescription: () -> String
}
/*:
 That type is called the "existential" type.  I'll explain the reason
 for that naming below in more detail, but you can think of it as making sure
 that a type which matches the protocol actually exists.
 
 Using what you know about cardinality, you should be able to verify that
 the cardinality of `_AlternativeCustomStringConvertible` is precisely
 identical to that of a struct like:
 */
struct MyAlternativeCustomStringConvertible {
    var description: String
    var alternativeDescription: String
}
/*:
 If MyAlternativeCustomStringConvertible had more fields we would
 see that the cardinality of MyAlternativeCustomStringConvertible
 is guaranteed to be an integer multiple of the cardinality of
 _AlternativeCustomStringConvertible.
 
 This is exactly the kind of thing the compiler
 does whenever you declare a struct anyway, it's a completely
 mechanical translation of that.  Here's where the magic
 comes in.  You can declare `MyAlternativeCustomStringConvertible`
 to _"conform"_ to `AlternativeCustomStringConvertible` as follows:
 */
extension MyAlternativeCustomStringConvertible: AlternativeCustomStringConvertible { }
/*:
 And that can work because of the multiplicative nature of structs.
 
 And here's what they don't tell you very well in the docs:
 under the covers, when you added that "conformance", the compiler
 did the following things:
 
 1. It verified that `MyAlternativeCustomStringConvertible` did in fact
 have variables and/functions that matched the `protocol`'s declarations
 exactly, _by name_. (i.e. we're dealing with nominal types again).
 
 2. It created a type like `_AlternativeCustomStringConvertible` that you
 are not allowed to see.  I put the "_" in front of the name to signify
 that it's a secret invisible (to you) type.
 
 3. It added a var to `MyAlternativeCustomStringConvertible` that looks
 like:
 */
extension MyAlternativeCustomStringConvertible {
    var _alternativeCustomStringConvertibleConformance: _AlternativeCustomStringConvertible {
        _AlternativeCustomStringConvertible(
            description: { self.description },
            alternativeDescription: { self.alternativeDescription }
        )
    }
}
/*:
 Ok thats what it did structurally, But then it does some other sneaky
 things operationally that are hard to show but which I can describe:

 1. It added a field to `_AlternativeCustomStringConvertible` that copied the
 metatype information of the conforming type into the instance of the
 existential type.
 
 2. Then whenever `type(of:)` gets called on
 `_AlternativeCustomStringConvertible` it lies and says it is the type of the
 conforming type, _not_ of the existential type.
 
 3. Whenever, in your code, you invoke methods on `MyAlternativeCustomStringConvertible`
 in a context that expects the `AlternativeCustomStringConvertible` protocol, it
 simply replaces your instance of `MyAlternativeCustomStringConvertible` with an
 the return value of: `_alternativeCustomStringConvertibleConformance`
 
 Once you understand these subleties, protocols become remarkably useful and you
 see them everywhere.  They just have one drawback.  Because all of
 this is based on names of types and vars and functions, the language requires that
 any given type can only conform to a protocol one way and if you need to have
 multiple alternative descriptions, well, you need to do something else.  The
 something else you need to do being roughly equivalent to what I have done above.
 
 You may ask, how do you know all this?  Good question.  Here's the direct quote
 about this from Joe Groff's document referenced above:
 
 _Swift also has existential types, which provide value-level abstraction.
 By contrast with a generic type parameter, which binds some existing type
 that conforms to the constraints, an existential type is a different type
 that can hold any value of any type that conforms to a set of constraints,
 abstracting the underlying concrete type at the value level. Existentials
 allow values of varying concrete types to be used interchangeably as values
 of the same existential type, abstracting the difference between the
 underlying conforming types at the value level. Different instances of the
 same existential type can hold values of completely different underlying
 types, and mutating an existential value can change what underlying type
 the value holds._
 
 In fact, up until Swift 3, Swift actually exposed this functionality.
 You could ask the protocol conformance (aka the existential)
 for both its static type and its dynamic type.  The static type
 in this case would be: _AlternativeCustomStringConvertible, the dynamic
 type would be: MyAlternativeCustomStringConvertible.  Swift 3 took that away
 and you can now no longer see the static type. Which is ok, because you should
 never need it.
 
 This functionality is what Joe Groff, in the document above refers to as the
 "existential" type.  The compiler calls into existence this invisible type which
 you never see which but which gets used at run time like any normal type.
 
 ### More uses of protocols

 Quoting Joe Groff again:
 
 _One of the key things that existentials allow, because an existential
 type is a distinct type, is that they can in turn be used to parameterize
 other types, which is particularly useful for heterogeneous collections:_

     let xyz: [Collection] = [x, y, z]
 
 So Swift uses the existential type functionality described above to
 allow you to fold many types into one type and that allows you
 to put them in, for example arrays as in Joe's example above.
 
 Thinking in terms of cardinality, saying what we said above, i.e. :
 
     extension MyAlternativeCustomStringConvertible: AlternativeCustomStringConvertible { }
 
 means that MyAlternativeCustomStringConvertible
 is guaranteed to have cardinality that is some integer multiple of the
 cardinality of AlternativeCustomStringConvertible
 allowing things to fit together into things like Collections.
 
 This has the huge advantage of letting you have heterogeneous
 collections.  Quoting again:
 
 _Some generic functions can instead be expressed using existential types
 for arguments. The function foo above which takes any value conforming to
 Collection could alternatively be phrased as:_

     func foo(x: Collection) { ... }
 
 _which is notationally clearer and more concise than the generic form._
 
 By the way this is the mechanism that allows you to have
 "protocol extensions" in the first place.  There is a real type
 that can be extended and that is what the extension does.
 
### Protocols as Type Constraints
 
 But protocols get used in another way.  They are used to allow us,
 on generic types and functions, to restrict what types can be
 passed into the generic.  We can
 _"constrain"_ the types in a generic to be, not just any type, but
 a type with a particular cardinality _and set of functions in its
 namespace_.  Quoting Joe Groff again:
 
 _Generics provide type-level abstraction: they allow a function or
 type to be used uniformly with any type that conforms to a given
 set of constraints, while still preserving the identity of the specific
 type being used in any particular instance. A generic function introduces
 type variables that stand in for a specific type. This allows a function
 to declare that it accepts any value conforming to a protocol, such as
 any Collection type:_

     func foo<T: Collection>(x: T) { ... }
 
 _The type variable T abstracts away the specific Collection being
 operated on at the type level; the identity of the type is still
 preserved, and so the type system can preserve type relationships
 between different values. For example, a generic function can also
 declare that it accepts any two values of the same collection type,
 and returns an array whose elements are of that same type:_

     func bar<T: Collection>(x: T, y: T) -> [T] { ... }
 
 Above when we discussed existential types we were talking about
 a type that could be used at run time.  But here we're talking
 about Swift using that type at _compile_ time.  And remember,
 never the twain shall meet.  So syntactically, we have overloaded
 the type syntax (compile time) with a value syntax (run time)
 concept.
 
 *_Opinion_*
 
 And _that_ is where they messed up.  They overloaded
 the syntax for generic type constraints in a clumsy manner that
 is really inconsistent with the rest of the syntax for generics.
 This makes it hard to teach and hard to understand.
 
 What you are
 doing with type constraints is algebraically equivalent to asking
 the compiler to solve a quadratic equation, i.e. you aren't
 saying, just evaluate the "type-function" for a given type,
 you are saying _solve_ this system of "type-functions" and
 tell me if there is no solution. And the compiler will
 do exactly that as an error message.  And none of that really
 has anything to do with holding heterogeneous objects in a
 collection or performing other value-level abstractions.
 
 *_/Opinion_*
 
 By the way, when Joe talks about value-level vs type-level, this
 is well-approximated by thinking in terms of run time vs
 compile time.  Things at the value level happen at run time, things
 at the type level happen at compile time.
 
 Back to quoting Joe:
 
 _We gave existential types an extremely lightweight spelling,
 just the bare protocol name, partially following the example
 of other languages like Java and C# where interfaces also
 serve as value-abstracted types, and partially out of a hope
 that they would "just work" the way people expect; if you want
 a type that can hold any type conforming to a protocol, just
 use the protocol as a type, and you don't have to know what
 "existential" means or anything like that. In practice, for a
 number of reasons, this hasn't worked out as smoothly as we
 had originally hoped. Although the syntax strongly suggests that
 the protocol as a constraint and the protocol as a type are one
 thing, in practice, they're related but different things, and
 this manifests most confusingly in the "Protocol (the type) does
 not to conform to Protocol (the constraint)" error. To some degree
 this is a missing feature in the language, but in cases with
 nontrivial Self or associated type constraints, a protocol existential
 simply can't conform to its own protocol._
 
 Read that again.  In some cases you can get an error saying
 that a protocol doesn't conform to itself?  Joe's document
 is an excellent road map for where generics and type constraints
 and existential objects are going, but stay tuned for future
 developments.
 
 ### Classes - Reference types
 
 We have covered the entire type system except for one thing.
 The difference between value and reference types.
 Without looking at the output on the right, predict
 what the code below does.
 */
struct Wrapped: CustomStringConvertible {
    var val: String
    var description: String { val }
    init(_ val: String) {
        self.val = val
    }
}
var str = Wrapped("Hello, World!")
var str2 = str
str.val = "Hello, S65G!"
str2
/*:
 What's the value of str2? is it Hello, World! or is it Hello, S65G! ?
 
 Let's do another example
 */
class WrappedRef: CustomStringConvertible {
    var val: String
    var description: String { val }
    init(_ val: String) {
        self.val = val
    }
}
var strRef = WrappedRef("Hello, World!")
var strRef2 = strRef
strRef.val = "Hello, S65G!"
strRef2
/*:
 Once you understand the difference between those two examples,
 you know almost everything there is to know about reference
 types. Certainly you know everything you need to, to use them
 effectively.
 
 So when are they used effectively?  Sometimes you
 need a reference type to serve as an anchor to hold an object in
 place.  In the app we are going to write in this class
 we will need something to hold the current state of the application
 so that our UI has a consistent place to look when deciding
 what data to put on the screen.  That is a perfectly valid
 use of reference types.
 
 But reference types are like impure functions - you should use them when
 you need them, but _only_ when you need them.  They should not
 be the thing you reach for initially when writing code in Swift.
 And that means that we should _NEVER_ be using the the "I" word,
 aka inheritance.
 
 Yes, Swift has inheritance and it is implemented on `class`
 types, but in this class we will never use it and in there is
 in fact no need to ever use it - contrary to what you may have
 been taught for the last few decades.  Generics completely
 replace what has traditionally been the role of inheritance.
 And are much more powerful and type-safe to boot.
 
 And that concludes our tour of the Swift type system. Now
 on to using the darn thing.
 */
