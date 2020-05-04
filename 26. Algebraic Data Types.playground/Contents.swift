/*: 
 ## Algebraic Data Types

 It is my observation that Swift as a language has two parts:

 1. a relatively small kernel of syntax and
 functionality that centers around Swift's powerful type system and
 makes excellent use of contemporary functional programming patterns.
 Call this kernel 10% of the language.
 2. a much larger set of syntax that is built on the 10% kernl
 and which exists to provide backwards compatibility to C,
 Objective C, and even Python. This portion of the language
 makes use of standard single inheritance, pointer-based, object-oriented
 programming techniques. Call this 90% of the language

 What frequently confuses people coming to Swift from other OO languages is
 that they feel that because they know and are familiar with the large portions
 of the 90%, they "know" the language.  This happened to me.
 It has taken about 6 years or working with the language on daily basis
 for me to see the language in this 90/10 light.  Seeing it this way
 has completely changed my approach to the language and my style
 of using it.
 
 I used to start class off with the following warning:
 
 ——————————————————————————————————
 
 THINGS IN SWIFT THAT EVERYONE HAS PROBLEMS WITH
 
 * Special Syntax
 * The Type System
 * Closures, and in particular "trailing closure syntax"
 * Generics
 * Optionals
 * map/reduce/zip
 * value types and reference types
 
 ——————————————————————————————————

 When teaching the type system, I would make everyone memorize
 the fundamental elements of the Swift type system:
 `function, tuple, struct, enum, class, protocol` because
 I felt the type system was idiosyncratic and that was the only way you
 could learn it.  Now I know that the reason its hard is because my teaching
 sucked.  The point of this playground is to suck less.
 
 The secret to life is setting expectations correctly.
 
 BTW, you wills still have to learn all six elements of the type system.
 
 If you are coming from an OO background it is frequently the case that you will think the following things when you pick up Swift:
 
 * Classes and protocols look quite familiar to what you are accustomed to in Java or ObjC or JavaScript and should be the first tool you reach for when designing new code, just as they are in those languages.
 * Structs seem like classes with several useless limitations
 * Functions appear to be just like methods
 * Generics seem a bit superfluous given that inheritance is available for classes
 * Enums and tuples look like trivial extensions from C
 
 Be aware that each and every one of these perceptions is mistaken in some fundamental way.
 */

/*:
 ### Types are sets of identifiable objects
 
 It's important that we be able to say clearly what a type is.  The most useful definition
 I've run across is to say that it's a set of values that we can define relationships between.
 
 1. If it's a set - we can say what's in and what's out of the set
 2. Each thing can only be in the set once
 3. We can identify every element of the set unambiguously
 
 ### Types have cardinality
 
 If a type is a set, then we can say how many things are in the set. The number may be
 infinite in theory but in programming practice we are constrained to finite size things.
 Really large, but still finite.  If we constrain ourselves to Strings of less than 100TB for
 example, I doubt that much of life would change.
 
 The "size" of the set is called it's cardinality. We can observe things about cardinality:
 
 1. Each type with identical cardinality is in some sense the same type.  We call this being
 isomorphic
 2. Isomorphism means that I can mechanically convert from one type to another
 3. So we can classify types by their cardinality
 
 ### Structs Bool, BoolBool, BoolBoolBool, Boolah Boolah
 
 So lets play around with this idea of cardinality because it leads to some interesting
 results which we can actually observe in Swift. Let's start with the smallest
 type we can think of (for now), `Bool`:
*/
var b = true
b = false
/*:
 `Bool` is a type with just two values: `true` and `false`.
 We can say what's in, those two values and what's out, everything else.
 Each element can be unambiguously identified.  The cardinality is two.
 This is definitely a type.
 
 Any type with
 just two values is isomorphic to `Bool`.  For example, how many values can
 the struct `BoolWrapper` assume?
*/
struct BoolWrapper {
     var b: Bool
 }
/*:

 1. How many values are there in the following various Boolean structs
 */

struct BoolBool {
    var b1: Bool
    var b2: Bool
}

/// Answer: 4
let bb1 = BoolBool(b1: false, b2: false)
let bb2 = BoolBool(b1: false, b2: true)
let bb3 = BoolBool(b1: true,  b2: false)
let bb4 = BoolBool(b1: true, b2: true)

struct BoolBoolBool {
    var b1: Bool
    var b2: Bool
    var b3: Bool
}

/// Answer: 8
let bbb1 = BoolBoolBool(b1: false, b2: false, b3: false)
let bbb2 = BoolBoolBool(b1: false, b2: false, b3: true)
let bbb3 = BoolBoolBool(b1: false, b2: true,  b3: false)
let bbb4 = BoolBoolBool(b1: false, b2: true,  b3: true)
let bbb5 = BoolBoolBool(b1: true,  b2: false, b3: false)
let bbb6 = BoolBoolBool(b1: true,  b2: false, b3: true)
let bbb7 = BoolBoolBool(b1: true,  b2: true,  b3: false)
let bbb8 = BoolBoolBool(b1: true,  b2: true,  b3: true)
/*:
 I could repeat this process ad infinitum, hopefully you see the pattern. I'm adding
 1 bit to my struct at each step along the way.  Every time I add a new Bool var to
 my struct I increase the number of possible values by a factor of two.
 
 So let's just skip up to the next smallest type given to us by Swift.
 */
struct LittleInt {
    var i: UInt8
}

/*:
 How many values are in that struct? Answer 256. How 'bout the following
 struct?
 */
struct BoolLittleInt {
    var i: UInt8
    var b: Bool
}
/*:
 Answer: 512.  Do you see why?
 
 How many values are there in Int? How many values are there in String?
 
 So the pattern is that every time you add a `var` to a `struct`
 the cardinality of the struct type gets multiplied by the cardinality
 of the type you added. This is general truth for _all_ structs.

 Hence `struct`s are called (tah dah) Product types.
 
 So here's a question. Why can't I make a struct with a
 number of values that is not a power of 2?  Hold that thought
 while we talk about something else for bit.
 
 ### Tuples as Product types
 
 The product types we have been talking about so far all have names.
 And the names make them non-interchangeable. BoolWrapper has no more
 additional structure than plain ol' Bool.  But the following won't
 compile:
 */

//var wrapper: BoolWrapper = true

/*:
 If you think about it, I could say that anything that has the same structure
 could have the same type.  And some languages do exactly that.  Other languages
 say, no you have to name everything and once you give it name
 that's it, the name alone determines the type.  Languages that use the name
 are said to have nominal types, languages that use the structure are
 said to have structural types.
 
 Swift has both. In Swift, structural types cannot have names, structure alone
 specifies the type.  Nominal types in Swift have to have unique names and
 only things of the same named type can be interchanged.  Structural types
 are called `tuples` and are in fact the type that is passed to functions.
 They can of course also be passed back, their just types after all.
 Both tuples and structs are product types.
 
 Here're some examples:
 */
var tup: (Bool) = (true)
type(of: tup)
var tuptup = (true, true)
type(of: tuptup)
/*: This won't compile */
//var nameTup = (myBool: true)
//type(of: nameTup)

/*:  But this will */
var nameTupTup = (b1: true, b2: false)
type(of: nameTupTup)

tuptup = nameTupTup
tuptup
nameTupTup = tuptup
nameTupTup
var bb = BoolBool(b1: true, b2: false)

/*:
 This won't compile because `bb` is nominal and `tuptup` is structural
 so they can't be interchanged even though their structures are identical.
 */

// bb = tuptup

/*:
 Here's the big thing about nominal types: they have names. (duh)
 And names specify name*spaces*
 that allow us to "extend" nominal types with functions.
 This will be hugely important a few playgrounds from now.
 */
extension BoolBool {
    var description: String { "b1: \(b1), b2: \(b2)"}
}
/*:
 Try that for tuptup.  It can't even be begun, because
 the type of tuptup _has no name_.
*/
/*:
 ### Enums as Sum Types
 
 Back to the question above: can I make a type with some number of
 values that is not a power of 2?
 
 The answer is yes, but I can't do it with a Product type alone.
 So here's are two examples of a type with 3 values:
 */
enum Three {
    case one
    case two
    case three
}
/*:
 Here's another one:
 */
enum Hmmm {
    case yes
    case no
    case maybe
}
/*:
 And here's an example of an enum with two values:
 */
enum Two {
    case `false`
    case `true`
}
/*:
 So here's an interesting question.  Is `Bool` in the
 Swift standard library implemented as an enum or as a struct?
 
 What's the cardinality of `Three` and `Hmm`?  Answer: 3

 Suppose I wanted a 6-valued type.  One way I could do it
 is:
 */
enum Six {
    case one
    case two
    case three
    case four
    case five
    case six
}
/*:
 That's a little tedious.  Seems like there ought to be
 a more convenient way of building up just the right
 cardinality I need for any given task.
 It turns out that I can associate other values with each
 case of an enum:
 */
enum ThreeByTwo {
    case one(Bool)
    case two(Bool)
    case three(Bool)
}
/*:
 So in this case I have three values and each value can have
 one of two values in its associated type - giving 6 possible
 values of ThreeByTwo.  Here they all are:
 */
var tbt1 = ThreeByTwo.one(false)
var tbt2 = ThreeByTwo.one(true)
var tbt3 = ThreeByTwo.two(false)
var tbt4 = ThreeByTwo.two(true)
var tbt5 = ThreeByTwo.three(false)
var tbt6 = ThreeByTwo.three(true)
/*:
 I can of course turn this around and make it TwoByThree
 */
struct TwoByThree {
    var t1: Three
    var t2: Three
}
/*:
 Again anywhere I could use Six, I could use ThreeByTwo or TwoByThree with
 the appropriate mechanical translation and vice-versa. It's the cardinality
 that matters here.  The structure we put on top of that cardinality is for
 our convenience.
 
 And as you might have guessed by now enums are called Sum types because
 everytime I add a case to an enum, I'm _adding_ the cardinality associated
 with the case to the overall cardinality of enum.  In structs and tuples
 I multiply for each new var, in enums I add for each new case.
 
 And the two combined allow me to have precisely the cardinality that I
 want.
 
 Let's do another form of a three-valued type:
 */
enum OptionalBool {
    case some(Bool)
    case none
}
/*:
 This particular form of enum is so incredibly important that it has
 a special name and a huge amount of special syntax in Swift which we will
 discuss later.  For now, you should note that I could use this
 precise technique to take _any_ type whatsoever and add one more value
 to it.
 
 In particular, here I'm using to express the idea of a missing
 value of the type in question - Bool.
 I have made a type that says I could have some boolean value or
 I could have not have a Bool.
 And I do that by taking a two-valued type and
 adding one more value to it.
 
 One more fact about enums that's worth noting is that I can
 raise the cardinality of the type to powers by nesting them. Let's do
 an example.
 */
indirect enum PowerOfThree {
    case zero(PowerOfThree)
    case one(PowerOfThree)
    case two(PowerOfThree)
    case terminate
}

let fourteen = PowerOfThree.one(.one(.two(.terminate)))
/*:
 Mental excercise: Why did I choose that name for that variable?
*/

/*:

 ### Functions are people too, Functions as Types
 
 So we have product types and we have sum types.  Let's
 take a look at functions for a while.  Just like we
 did for Type, let's come up with a working definition
 of Function.  Here's the definition that we'll work
 with:
 
 A function takes a single value of a specified type and returns a
 single value of a specified type.
 The returned type can be the same type or a different type,
 but both the input type and the returned type must be
 specified in advance: i.e. a function doesn't get to change its
 mind about what it returns after you have invoked it.
 You have to know both types before you can use the function.
 
 Now that's a very broad definition and for purposes of this discussion
 I want to restrict it a bit. For the rest of this playground,
 functions are also:
 
 1. Total: a function _must_ return a value of the specified return type for
 _all_ values of the specified input type. No throwing or dying or not
 returning.
 2. Deterministic: given an input value, a function must return the same value
 for that input every time you call it.
 3. Side-effect free: calling a function can have no effect that you can observe
 after the function has returned.  It has to be a black box.
 
 A function which meets those specifications is called a `pure` function.
 Like everything pure, functions like this are very valuable.  In
 particular they let us do the same sort of analysis on them that we
 have been doing for structs, tuples and enums.
 
 So the first questions we should ask, is can functions be types?
 Do they form a set? Can I identify them separately?  It turns
 out that they can be types and they do form a set.  And you can
 identify them separately, if the way you disambiguate a function is
 by comparing outputs given inputs.  I.e. two functions x and y,
 that are of the form (A) -> B
 are the same if and only if for every value in the type A, x and
 y return the same value of B.  Let me reiterate: you can test
 that x and y are the same function by looping over all the values
 in A, handing each value in turn to x and to y and then comparing
 x and y's output.  If they are the same in every case, then x and
 y are considered identical functions.
 
 They may have completely different implementations, one may take
 a lot longer to return than the other, from a type-theory standpoint
 that doesn't matter.  Our definition of "same" is that they
 give the same output for _any_ given input.
 
 Lets start with a simple example.  Let's consider pure functions
 from Bool to Bool.  The first question we have to ask how many
 pure Bool -> Bool funcs are there?  Well, here they all are:
 */
func bf1(_ b: Bool) -> Bool { b ? false : false }
func bf2(_ b: Bool) -> Bool { b ? false : true  }
func bf3(_ b: Bool) -> Bool { b ? true  : false }
func bf4(_ b: Bool) -> Bool { b ? true  : true  }
/*:
 Under our definitions of pure and identity, there are no
 (Bool) -> Bool functions that are not in that list.
 
 Can we do the same trick for (Three) -> Bool?  Sure.
 Here they are:
 */

func bt1(_ t: Three) -> Bool { switch t { case .one: return false; case .two: return false; case .three: return false } }
func bt2(_ t: Three) -> Bool { switch t { case .one: return false; case .two: return false; case .three: return true  } }
func bt3(_ t: Three) -> Bool { switch t { case .one: return false; case .two: return true ; case .three: return false } }
func bt4(_ t: Three) -> Bool { switch t { case .one: return false; case .two: return true ; case .three: return true  } }
func bt5(_ t: Three) -> Bool { switch t { case .one: return true ; case .two: return false; case .three: return false } }
func bt6(_ t: Three) -> Bool { switch t { case .one: return true ; case .two: return false; case .three: return true  } }
func bt7(_ t: Three) -> Bool { switch t { case .one: return true ; case .two: return true ; case .three: return false } }
func bt8(_ t: Three) -> Bool { switch t { case .one: return true ; case .two: return true ; case .three: return true  } }
/*:
 How about (Bool) -> Three? Sure.. here they are.
 */
func tb1(_ t: Bool) -> Three { t ? .one   : .one   }
func tb2(_ t: Bool) -> Three { t ? .one   : .two   }
func tb3(_ t: Bool) -> Three { t ? .one   : .three }
func tb4(_ t: Bool) -> Three { t ? .two   : .one   }
func tb5(_ t: Bool) -> Three { t ? .two   : .two   }
func tb6(_ t: Bool) -> Three { t ? .two   : .three }
func tb7(_ t: Bool) -> Three { t ? .three : .one   }
func tb8(_ t: Bool) -> Three { t ? .three : .two   }
func tb9(_ t: Bool) -> Three { t ? .three : .three }
/*:
 Ok, so we have the following information:
 
     (2-valued type) -> 2-valued type : 4 possible pure functions
     (3-valued type) -> 2-valued type : 8 possible pure functions
     (2-valued type) -> 3-valued type : 9 possible pure functions

 Anyone see a pattern here? Yeah:
 
     (A) -> B : has B to the power of A (B ^ A) cardinality
 
 Tah Dah functions are exponential types! Specifically,
 
     (A) -> B
 
 is the name of a specific type with cardinality of B^A.
 Different values of A or B yield different cardinality
 and are therefore different types.
 
 ### "Higher Order" Functions
 
 So if functions are types does that mean that I can
 have a function which takes a function as input and/or
 returns a function as output?  Of course it does!
 To illustrate lets write one.
 */
 func bool2BoolToBool2Three(
    _ f: (Bool) -> Bool
 ) -> (Bool) -> Three {
    let v1 = f(false)
    let v2 = f(true)
    switch (v1, v2) {
    case (false, false): return tb1
    case (false, true): return tb2
    case (true, false): return tb3
    case (true, true): return tb4
    }
}
/*:
 Note that tb1, tb2, tb3 and tb4 were all defined above
 and can be returned just by name.  Also note,
 that I'm not saying the above is particularly useful
 per se, I'm saying that higher order functions are
 not really anything different than lower order functions,
 you are passing in a value in a particular type and
 getting back a value in a type.  Same as always.
 We'll show how useful this is in future playgrounds.
 
 So (Bool) -> Bool has cardinality of 4 and
 (Bool) -> Three has cardinality of 9. That means that there
 are 9^4 or 6561 possible values that `bool2BoolToBool2Three`
 could have assumed because for each of the four input values
 we could freely choose from any of the 9 possible
 output values - we simply chose one of them.
 Clearly this gets out of hand exponentially fast.
 
 How 'bout (Bool) -> (Bool) -> Bool? I won't
 work it out for you, but (Bool) -> Bool has four
 values, Bool has 2, so (Bool) -> (Bool) -> Bool
 has cardinality of 4^2 or 16.
 
 So what happens if I add a func type to a struct as a var.
 Yeah, I multiply the cardinality of the struct before adding
 the func by the cardinality of the func to get the new cardinality.
  
 What happens if I add a func type to an enum as an associated
 value of a new case?  Just add the cardinality of the func
 to the cardinality of the enum.
 
 So here's a question, suppose that A is a tuple of (C, D)? In
 other words I have a function:
 
     (C, D) -> B
 
 what's the cardinality of (C, D), well it's just (cardinality of
 C) x (cardinality of D) because (C, D) is a Product type. So the
 cardinality of
 
     (C, D) -> B = B ^ (C x D)
 
 But B ^ (C x D) is the same as (B^D)^C (remember logarithms?).
 But that is just the cardinality of
 
     (C) -> (D) -> B
 
 Ok, so what _that_ means is that there is a 1-to-1 relationship between
 functions of the form:
 
     (C, D) -> B
 
 and functions of the form:
 
     (C) -> (D) -> B
 
 You can always convert between one form and the other.  In fact, using
 generics (to be discussed below) you can write a function which accepts
 a function in the first form and returns a function in the second form.
 And you can write a function which reverses that.
 
 If you paid close attention to the arithmetic, you would also have noticed
 that there is a 1-to-1 relationship between those two functions and these
 two as well:
 
     (D, C) -> B
     (D) -> (C) -> B
 
 Which simply says that order of arguments to a multi-argument function
 doesn't matter.
 
 To be clear about what (C) -> (D) -> B means, it is a function which
 accepts a value of type C and returns a function of type (D) -> B.
 This is called `currying` (C, D) -> B and is named after the mathemetician
 Haskell Currey who invented the technique and proved the equivalence.
 
 Curried functions are _incredibly_ useful and you will soon learn
 to prefer them to functions taking multiple arguments.  There are
 languages which in fact, make curried functions the default form
 of every function (e.g. Haskell).  

 ### Void as the Unit type
 
 Bool has 2 values, can you think of a type that has 1 value?
 Yep there is one, it's called Void and you use it all the time.
 You just didn't know that it was the one-valued type.  The name
 is really unfortunate, because you'd think Void meant not that
 there was one value but that there were no values.  But that is
 not what it means.  It turns out that when C and C++ were returning
 void* or void that they were actually returning something, it
 was just something they couldn't express well in their type
 system.
 
 Here's the thing about it though, because Void only has one value,
 you don't really have to name it.  If I tell you that I'm returning
 Void, then when I say `return`, you know which value I'm referring
 to already - the one value that Void has.  Other types we deal
 with almost all have the interesting property that you can combine
 them with another value of the same type to get a new value of that
 type.  In Bool for example, you `&&` or `||` one Bool with another
 to get a new Bool.  It's kind of hard to think of a type that doesn't
 have that kind of behavior in fact - except for Void.  Because
 there's only one value of Void you'd be combining it with itself
 to get itself, which can be a somewhat pointless exercise.
 
 How would we specify such a type? That is an excellent question.
 Is void a struct, an enum, a tuple (or is there some other type
 of types that I haven't told you about yet?).
 
 It turns out that while we could choose actually to represent it as pretty
 much any of those three things, Swift chooses to represent it
 as the tuple.  Void is defined to be the structural type `()`. The
 empty tuple.  Void is just a typealias for `()`.  Interestingly,
 and this is a desirable property of using a structural type, the
 way of referring to the type and the value are identical.  Both
 are called `()` and which one is meant at any given point in
 code is determined by context.
 
 3. Does it check out? (Void) -> Bool, (Void) -> Three, (Bool) -> Void, (Three) -> Void, (Void) -> Void
 4. What happens is I add a Never field to a struct?
 5. What happens if I add a Never field to an enum?
 4. What does it mean if you add a var of type Void to a struct?
 5. What does it mean if you add a var of type Void to an enum?
 6. Final thing, because there's only one, the type and the value are expressed the same syntactically
 
 ### Never as the _real_ Void type
 1. So Void is the type with just one value, can you think of type with zero values? - Never
 2. How would we specify that? the empty enum.
 3. Does it check out? (Never) -> Bool, (Never) -> Three, (Bool) -> Never, (Three) -> Never, (Never) -> Never
 4. (A) -> Never is not a function according to the definition because it does not return a value
 5. Swift will let you write that and will actually prevent you from doing anything that invokes return
 
 ### The meaning of generics
 1. Generics are the functions of types - they take types in and return new types, the represent universal quantification.
 2. In  a very real sense they are us programming the compiler
 3. Even the syntax is reminiscent of function, this is not accidental: `G<A>`
 4. The difference is that the function is computed at compile time, not run time, so that you can use the type in your code.
 5. There is no type analysis at run-time in a pure Swift program, the runtime anlysis is there for first ObjC, and now additionally
 Python

 ### The meaning of protocols
 1. Protocols what emerges when you try to solve simultaneous functions of types - the represent existential quantification
 2. Sums of types
 3. For protocols, Swift creates the existential type and it is that type that you extend when you write a protocol extension.
 4. Existential types (aka protocols) are just as "real" as Universal types (aka generics)

 */

