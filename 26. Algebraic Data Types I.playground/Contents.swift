/*:
 # Algebraic Data Types I - Arithmetic of Types
 
 NB In this playground we are experimenting with types.  There aren't
 many actual calls to functions, but in a few places you'll want to
 have run the playground so that you can see the types of things printed
 over on the right. So don't forget to hit run at least once.

 ### Types are sets of identifiable objects
 
 It's important that we be able to say clearly what a type is.  The most useful definition
 I've run across is to say that it's a set of values that we can define relationships between.
 
 1. If it's a set - we can say what's in and what's out of the set
 2. Each thing can only be in the set once
 3. We can identify every element of the set unambiguously
 
 ### Types have a size (aka cardinality)
 
 If a type is a set, then we should be able to say how
 many things are in the set. The number may be
 infinite in theory but in programming practice we are constrained to finite size things.
 Really large, but still finite.  If we constrain ourselves to Strings of less than 100TB for
 example, I doubt that much of life would change.
 
 The "size" of the set is called it's cardinality. We can observe things about cardinality:
 
 1. Each type with identical cardinality is in some sense the same type.
 2. What I mean by this is that I can mechanically convert from one
 type to another and back, paying attention only to the values in the type and not
 any of the relationships between that values that you might think of as existing.
 3. So one way that we can classify types is by their cardinality.
 
 Our goal in this playground is to show that Swift lets us build up types with
 any cardinality that we like. Then we can add additional structure to that
 type to our hearts content.  That’s in effect what Swift is about letting us do.
 
 Having correct cardinality of our types helps do two things:
 
 1. It eliminates an entire class of errors that arises from having
 invalid values for types.  If the cardinality is specified correctly
 it is impossible to have an invalid value.  You might get the specification
 wrong and have an inapprorpiate type for what you are trying to do
 but that's a different problem.
 
 2. Most importantly, having correct cardinality on our types allows
 the compiler to provide us much more help when coding.  It can keep
 us from typing things that don't make sense and suggest thing that do.
 It can identify when you haven't covered every input that you should or
 when you are trying to generate an output that you shouldn't.  In
 other words it helps us be the lazy selves we aspire to be and in so
 doing it makes us better, faster coders.
 
 ### Structs Bool, BoolBool, BoolBoolBool, Boolah Boolah
 
 So lets play around with this idea of cardinality because it leads to some interesting
 results which we can actually observe in Swift. Let's start with the smallest
 type we can think of (for now), `Bool`:
*/
var b = true
b = false
/*:
 `Bool` is a type with just two values: `true` and `false`.
 We can say what's in, (those two values) and what's out, everything else.
 Each element can be unambiguously identified.  The cardinality is two.
 This is definitely a type.
 
 Any type with just two values is equivalent to `Bool` in the sense
 we discuss above, i.e. you can tranlate in and out of it.  If you are a
 C programmer for example you are very used to translating between Bool and Int
 by ignoring values greater than one in your `Int` type.
 
 So to give an example cardinality of one our own types,
 how many values can the struct `BoolWrapper` below assume?
*/
struct BoolWrapper {
     var b: Bool
 }

/*:
 Answer: 2. And here they are:
 */

var bw1 = BoolWrapper(b: true)
var bw2 = BoolWrapper(b: false)
/*:
 Don't believe me?  Show me another value of BoolWrapper than
 besides those two.
 
 How many values are there in the following struct:
 */
struct BoolBool {
    var b1: Bool
    var b2: Bool
}
/*:
 *Answer: 4*  Here they are:
 */
let bb1 = BoolBool(b1: false, b2: false)
let bb2 = BoolBool(b1: false, b2: true)
let bb3 = BoolBool(b1: true,  b2: false)
let bb4 = BoolBool(b1: true, b2: true)
/*:
 How many values are there in this struct?
 */
struct BoolBoolBool {
    var b1: Bool
    var b2: Bool
    var b3: Bool
}
/*:
*Answer: 8*  Here they are:
*/
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
 How many values are in that struct? Answer 256.  Do you see why?
 
 How 'bout the following struct?
 */
struct BoolLittleInt {
    var i: UInt8
    var b: Bool
}
/*:
 Answer: 512.  Do you see why?
 
 So the pattern is that every time you add a `var` to a `struct`
 the cardinality of the type gets multiplied by the cardinality
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
 say, no you have to name everything and once you give it a name
 that's it, the name alone determines the type.  Languages that use the name
 to delineate the type are said to have nominal types,
 languages that use the structure are said to have structural types.
 (NB The [Swift book](https://docs.swift.org/swift-book/ReferenceManual/Types.html):
 refers to these as `compound` types, but that's not what the PL
 community calls them. They call them structural types and since
 I prefer that name and I'm the teacher and it's my playground,
 that's what we'll call them).
 
 Swift has both. In Swift, structural types cannot have names, structure alone
 specifies the type.  Nominal types in Swift have to have unique names and
 only things of the same named type can be interchanged.  Structural types
 are called `tuples` and are in fact the type that is passed to functions.
 They can of course also be passed back, they're just types after all.
 Both tuples and structs are product types, though.
 
 Here're some examples:
 */
var tup: (Bool) = (true)
type(of: tup)
/*:
 A structural type of only one type is viewed as just being of
 type of the single type.  Strange but true.
 
 OTOH, if we make a structural type with _two_ types things
 get more interesting.
 */
var tuptup: (Bool, Bool) = (true, true)
typealias StructuralBoolBool = (Bool, Bool)
type(of: tuptup)
/*:
 Swift syntax allows us to put annotations on our structural types, provided
 that the structural type has more than one value.  This won't compile
 for example.
 */
//var nameTup = (myBool: true)
//type(of: nameTup)
/*:
 But this will:
 */
var nameTupTup = (b1: true, b2: false)
type(of: nameTupTup)
/*:
 And we can show that the annotated type is the same as the
 unannotated type by assigning one to the other.
 */
tuptup = nameTupTup
tuptup
nameTupTup = tuptup
nameTupTup
/*:
 This shows that underneath _ALL_ structural types having the same
 structure are the same type.
 
 Nominal types with that same structure though are NOT the same.
 BoolBool is a nominal type with the structure (Bool, Bool) so
 let's make a value of that type.
 */
var bb = BoolBool(b1: true, b2: false)
/*:
 But we can't assign that value to or from the identical structural type.
 These statements won't compile because `bb` is nominal and `tuptup` is structural,
 so they can't be interchanged even though their structures are identical.
 */
// bb = tuptup
// tuptup = bb
/*:
 Here's the big thing about nominal types: *they have names*. (duh)
 
 And names can be used to specify name*spaces* that allow us to "extend" nominal
 types with functions. This is why you see the `extension`
 keyword so much in Swift, and it will be hugely important a few playgrounds
 from now.
 
 Here's an extension of our BoolBool nominal type. Note that
 the extension is associated with the _name_ of a type.
 */
extension BoolBool {
    var description: String { "b1: \(b1), b2: \(b2)"}
}
/*:
 Try doing that extension for the tuptup variable above.
 It can't even be begun, because the type of tuptup _has no name_.
 And that fact alone means you don't have anything
 that you can use to make an extension.
*/
/*:
 ### Enums as Sum Types
 
 Back to the question above: can I make a type with some number of
 values that is not a power of 2?
 
 The answer is yes, but I can't do it with a Product type alone,
 Because the "smallest" thing I can do in some sense with Product
 types is multiply them by two and that gives me only types
 with cardinality of a power of two.
 
 So here's an example of a type with 3 values:
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
 Yup, enums are the technique that let me have non-power-of-two
 types.
 
 Side note: It is a hole in the Swift type system
 that enums are purely nominal.  There is no structural type
 for them.  This has been discussed at length, but there
 seems to be no appetite on the part of the core team
 for adding a structural version of enums to the language.
 Maybe one day.
 
 Anyway, back to our regularly scheduled programming.
 
 Here's an example of an enum with two values:
 */
enum Two {
    case `false`
    case `true`
}
/*:
 So here's an interesting question.  Is `Bool` in the
 Swift standard library implemented as an enum or as a
 struct?
 
 Turns out that it's a struct, but for very practical reasons,
 LLVM (the compiler tool platform Swift is built on) supports
 a type UInt1 (aka a bit).  Swift implements Bool as a UInt1
 underneath because that's well-mapped to the hardware supported
 by LLVM.
 
 So what's the cardinality of `Three` and `Hmm`?  Answer: 3

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
enum TwoPlusTwoPlusTwo {
    case one(Bool)
    case two(Bool)
    case three(Bool)
}
/*:
 So in this case I have three values and each value can have
 one of two values in its associated type - giving 6 possible
 values of ThreeByTwo.  Here they all are:
 */
var tbt1 = TwoPlusTwoPlusTwo.one(false)
var tbt2 = TwoPlusTwoPlusTwo.one(true)
var tbt3 = TwoPlusTwoPlusTwo.two(false)
var tbt4 = TwoPlusTwoPlusTwo.two(true)
var tbt5 = TwoPlusTwoPlusTwo.three(false)
var tbt6 = TwoPlusTwoPlusTwo.three(true)
/*:
 I could also do a six valued type as 3x2 rather than 2+2+2:
 */
struct ThreeTimesTwo {
    var three: Three
    var two: Bool
}
/*
 You can work out the values there for yourself.
 
 I could do a five-valued type as:
 */
enum Five {
    case one
    case two
    case three
    case four
    case five
}
/*:
 Or as:
 */
enum TwoPlusTwoPlusOne{
    case oneAndTwo(Bool)
    case threeAndFour(Bool)
    case five
}
/*:
 Again anywhere I could use Six, I could use TwoPlusTwoPlusTwo with
 the appropriate mechanical translation and vice-versa. And anywhere
 I could use Five I could use TwoPlusTwoPlusOne.
 
 It's the cardinality that matters here.
 The structure we put on top of that cardinality is for
 our convenience.
 
 And as you might have guessed by now enums are called Sum types because
 everytime I add a case to an enum, I'm _adding_ the cardinality associated
 with the case to the overall cardinality of enum.  In structs and tuples
 when I add a new var of a given type,
 I multiply the cardinality of the struct by the cardinality
 of the type I'm adding. In enums, I add for each new case.
 
 And the two combined allow me to have precisely the cardinality that I
 want.
 
 Let's do another form of a three-valued type:
 */
enum BoolPlusOne {
    case bool(Bool)
    case notBool
}
/*:
 This particular form of enum is so incredibly important that it has
 a special name and a huge amount of special syntax in Swift which we will
 discuss later.  For now, you should note that I could use this
 precise technique to take _any_ type whatsoever and add one more value
 to it.
 
 In particular, here I'm using it to express the idea of something _not
 being_ a value of the type in question - in this case, Bool.
 I have made a type that says I could have some boolean value or
 I could not have a Bool. It's optional as to which I have.
 And I do that by taking a two-valued type and
 adding one more value to it.

 ### Functions are people too, Functions as Types
 
 So we have Product types and we have Sum types.
 And that allows us to have types with _any_ cardinality
 we find useful, without clumsy circumlocutions.
 
 So let's take a look at functions of those types
 for a while.  Just like we
 did for Type, let's come up with a working definition
 of Function.  Here's the definition that we'll work
 with:
 
 _A function takes a single value of a specified type and returns a
 single value of a specified type._
 
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
 for that input every time you call it. _Every_ time, no exceptions. No
 random number generators allowed here.
 3. Side-effect free: calling a function can have no effect that you can observe
 after the function has returned.  It has to be a black box. No setters,
 no callbacks, none of that stuff.
 
 A function which meets those specifications is called a `pure` function.
 Like anything that's very pure, functions like this are very valuable.  In
 particular they let us do the same sort of analysis on them that we
 have been doing for structs, tuples and enums.
 
 So the first questions we should ask, is can functions be types?
 Do they form a set? Can I identify them separately?
 
 It turns out that they can be types and they do form a set.
 And you can
 identify them separately, if the way you disambiguate a function is
 by comparing outputs given inputs.  I.e. two functions x and y,
 that are of the form (A) -> B
 are the same *if and only if* for _every_ value in the type A, x and
 y both return the same value of B.
 
 Let me reiterate: you can test
 that x and y are the same function by looping over all the values
 in A, handing each value in turn to x and to y and then comparing
 x and y's output.  If they are the same in every case, then x and
 y are considered identical functions.
 
 They may have completely different implementations, one may take
 a lot longer to return than the other, but from a type-theory standpoint
 that doesn't matter.  Our definition of "same" is that they
 give the same output for _any_ given input.
 
 Now you can partially
 see why I specified using a pure function.  I have to be able to
 loop over all inputs (Total) and get back the same value (Determistic)
 with nothing outside the function able to affect its return value
 (No Side-effects).
 
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
 
     (A) -> B : has cardinality B to the power of A (B ^ A)
 
 Tah Dah functions are exponential types! Specifically,
 
     (A) -> B
 
 is the name of a specific type with cardinality of B^A.
 Different values of A or B yield different cardinality
 and are therefore different types.  That point is important.
 Really important.  Two functions `f` and `f'` can only be the same type
 if they have the exact _same_ function signature, i.e. A = A' and
 B = B'.
 
 The key concept here is that type of a function is
 its function signature. It is the combination of
 those types into a cardinality of
 one type to the power of another
 that gives functions their vast variability -
 that in effect allows them to be the basis of our
 algorithms.
 
 ### Are functions structural or nominal?
 
 You sort of already know this, but you probably haven't thought
 about it.  Functions have to be structural types for the same
 reason that tuples have to: the entire type inference system of
 swift depends on it.  For functions to be substitutable as freely
 in type inference as they are, the inference engine can only
 rely on the structure of the function.  In fact, while you can
 name individual functions, there is not mechanism in Swift
 that would allow you to name a type signature.
 
 ### "Higher Order" Functions
 
 So if functions are types does that mean that I can
 have a function which takes a function as input and/or
 returns a function as output?  Of course it does!
 To illustrate lets write one.
 */
 func bool2BoolToBool2Three(
    _ f: (Bool) -> Bool  /// Input function type
 ) -> (Bool) -> Three {  /// Output function type
    let v1 = f(false)    /// Identify which (Bool) -> Bool func we mean
    let v2 = f(true)
    
    switch (v1, v2) {    /// based on the input, select an output
    case (false, false): return tb1
    case (false, true): return tb2
    case (true, false): return tb3
    case (true, true): return tb4
    }
}
/*:
 Note that tb1, tb2, tb3 and tb4 were all defined above
 as (Bool) -> Three functions, so
 they can be returned just by name.
 
 Also note, I'm not saying the above is particularly useful
 per se, I'm saying that higher order functions are
 not really anything different than lower order functions,
 you are passing in a value in a particular type and
 getting back a value of a particular type.  Same as always.
 We'll show how useful this is in future playgrounds.
 
 So (Bool) -> Bool has cardinality of 4 and
 (Bool) -> Three has cardinality of 9. That means that there
 are 9^4 or 6561 possible values that `bool2BoolToBool2Three`
 could have assumed because for each of the four input values
 we could freely choose from any of the 9 possible
 output values - we simply chose one set of them.
 
 Clearly this gets out of hand exponentially fast.  And
 that is why we don't implement higher order functions
 as gigantic pattern-matching switch statements. Exponential
 growth (as everyone should have learned in early 2020)
 is a bad thing.
 
 How 'bout (Bool) -> (Bool) -> Bool?
 That is, a function taking single Bool value and
 returning a (Bool) -> Bool function.
 
 I won't
 work it out for you, but (Bool) -> Bool has four
 values, Bool has 2, so (Bool) -> (Bool) -> Bool
 has cardinality of 4^2 or 16.  The trick to calculating
 this is to start at the far right for your value of B
 in B^A and work backwards to the left. (This will explain
 somethings in future playgrounds, btw).
 
 So what happens if I add a func type to a struct as a var.
 Yeah, I multiply the cardinality of the struct _before adding
 the func_, by the cardinality of the func itself
 to get the new cardinality.
  
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
 But that is just the cardinality of:
 
     (C) -> (D) -> B
 
 (if you don't believe me,
 see the example of `(Bool) -> (Bool) -> Bool` immediately above)
 
 Ok, so what _that_ means is that there is a 1-to-1 relationship between
 functions of the form:
 
     (C, D) -> B
 
 and functions of the form:
 
     (C) -> (D) -> B
 
 You can always convert between one form and the other.  In fact, using
 generics (to be discussed below) you can write a function which accepts
 a function in the first form and returns a function in the second form.
 And you can write a function which reverses that. And these are really
 simple 1-liners, there's nothing particularly complicated about them.
 
 If you paid close attention to the arithmetic, you would also have noticed
 that there is a 1-to-1 relationship between those two functions and these
 two as well:
 
     (D, C) -> B
     (D) -> (C) -> B
 
 Which simply says that order of arguments to a multi-argument function
 doesn't matter.  Which is good, because we already knew that, at least.
 
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
 there was _only one_ value, but that there were _no_ values.
 And in some languages it does mean that.  But that is
 not what it means in Swift.
 
 It turns out that when C and C++ were returning
 `void*` or `void` that they were actually returning something, it
 was just something they couldn't express well in their type
 system and so it seemed like they were returning nothing or
 a pointer to nothing. (That last bit about the pointers should
 really tip you off that there really is something being pointed at).
 
 Here's the thing about the one-valued type though,
 because it (Void) only has one value,
 you don't really have to name it.  If I tell you that I'm returning
 Void, then when I say `return`, you know which value I'm referring
 to already - the one value that Void has. And so the compiler can
 skip making you type out the one value you must be referring to.
 And it does.  But this is just syntactic sugar, you really are
 returning the one-value of the one-valued type.
 
 Other types we deal
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
 empty tuple.  The type Void is just a typealias for `()`.
 
 Interestingly, and this is a desirable property of using
 a structural type, the way of referring to the type and the
 value are identical.  Both are called `()` and which one is
 meant at any given point in Swift code at any given point
 is determined by context.
 
 So, I've made a bunch of assertions about this one-valued type
 thing, do they really check out? Let's see.
 
 What happens if we put Void in a struct?
 */
struct BoolVoid {
    var b: Bool = false
    var v: Void = ()
}
/*:
 So what's the cardinality of that? Right, it's 2. Do you
 see why?
 
 So Void works with Product types.  How 'bout if we put it in an enum?
 */
enum ThreeVoid {
    case one(Void)
    case two
    case three
}
/*:
 Still cardinality of three.  How bout with functions?
 
    (Void) -> Bool : 2^1 = 2 (you have Void -> true and Void -> false)
    (Void) -> Three: 3^1 = 3
    (Bool) -> Void: 1^2 = 1  ( ignore input and return void in all cases )
    (Three) -> Void: 1^3 = 1
    (Void) -> Void: 1^1 = 1
 
 Those check out too. So given that for any type there is only one
 Void-returning function and it gives you back what you knew before
 you called it, why would you ever call it?  Oh yeah, side-effects.
 I.e. you only call a Void-returning function to get the side-effect.
 And you only call a function that takes (Void) to get non-determinism,
 i.e. like certain laws, you have to pass it (a value) to find out what's in it.
 With a Void-accepting function, you don't know what value you'll get back.
 
 Swift's way of getting out of pure functions and allowing side-effects
 and non-determinism is to allow Void-returning and Void-accepting functions.
 All languages have to allow this, after all that's what I/O _is_,
 when you think about it. It is another hole in the Swift type system though
 that there is no-way to clearly delineate a non-deterministic or
 side-effect-producing func from a pure func.  There _are_ a couple of ways to
 mark partial (as opposed to total) functions, however.
 
 ### Never as the _real_ Void type
 
 So Void is the type with just one value, can you think of type with zero values?
 This one is a bit more tricky.  it doesn't map onto anything from C-based languages.
 There is one in Swift, though, it's called Never.  And this is how it is defined:
 */
enum Never { }
/*:
 It's an enum with no values.  Try to instantiate an instance of it.
 There's not even a way to type it.  First, lets check it out and see
 what it does to the cardinality of other types.
 */
struct BoolNever {
    var b: Bool
    var n: Never
}
//var bn: BoolNever = BoolNever(b: true, n: )
/*:
 What's the cardinality ot BoolNever?  Well if Never has cardinality zero and
 BoolNever is a product type it should be zero * 2 = zero.  To test that
 try creating an instance of BoolNever as in the comment above.  There's nothing
 you can type for the `n` value.  And if you try to type something the
 compiler will tell you that it's not a valid value.  Basically introducing
 Never there has taken the cardinality to zero, there is no value that we
 can make of BoolNever.

 Let's try an enum:
 */
enum ThreeNever {
    case one
    case two
    case three
    case never(Never)
}
let tn1 = ThreeNever.one
let tn2 = ThreeNever.two
let tn3 = ThreeNever.three
//let tnN = ThreeNever.never()
/*:
 We can make first three values just fine, but we can never make the never case and
 the compiler won't let you try anything.  So we've added zero to the cardinality
 of Three instead of multiplying like before.
 
 So far Never is behaving just like Zero in our arithmetic of types.
 
 let's try functions:
 */
// Doesn't compile unless we `Never` return bc we can't return Never,
// i.e. we are not pure anymore....
func voidToNever() -> Never {
    fatalError("hmmm.")
}
func neverToBool(_ n: Never) -> Bool {
    return true
}

func neverToNever(_ n: Never) -> Never {
   fatalError()
}

/*:
 So... we expect (A) -> Never to have cardinality of 0^A or zero.  Which
 it does.  In fact if you try to return anything from a function like that
 you'll get a compiler error.  So making Never be the return type means
 that we simply cannot have a pure function.  Swift in fact now denotes functions
 which don't return as having return type Never.  (It used to require
 that you annotate them with a special compiler flag: `@noreturn`).
 
 (Never) -> B should be B^0 or just 1.  You can write the function only one way,
 and we did.  There's just one problem: you can never call it.
 
 And finally (Never) -> Never is an odd one since it's cardinality is 0^0.
 Turns out that that the limit of x^x as x approaches zero from the right
 is 1, so you get to write one function there.
 
 You might think that you'll _never_ use `Never` - and you'd be as wrong as
 the ancient mathemeticians who never considered using zero in math. And
 then along came Arabic numerals.
 
 Speaking of Arabic numerals....
 
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
  Note, it might seem backwards to you based on how you interpret
  the enum.
 */
