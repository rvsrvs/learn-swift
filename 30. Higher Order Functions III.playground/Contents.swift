import Combine
/*:
 ## Higher Order Functions III - Recursive Chaining
 
 In this playground we want to begin to see exactly _how_ Combine uses
 functional composition to do what it does.
 We'll do this by writing our own mini version of Combine.
 Remember how in
 "Higher Order Functions I" we saw that the the higher order functions
 on Sequence were really just wrappers around for-loops
 which abstracted away patterns of for-loop usage that you
 never knew existed?  Well it turns out that Combine does
 precisely that same thing for _callbacks_.
 
 So what we're going to do in this playground is take the very first
 simple example of Combine that we experimented with in the
 Combine I playground and implement our own version of it.
 The idea is that by doing this, you'll gain a real understanding
 of how Combine recursively performs function composition
 to replace the standard callback.  For reference, here is the
 example we hope to code up:
 ```
 var r2: [String] = []
 let c1 = [1, 2, 3]
     .publisher
     .map { $0 * 2 }
     .map { Double($0) }
     .map { "\($0)" }
     .sink { r2.append($0) }
 ```
 We'll be taking this example and making a `myPublisher` to replace
 `publisher`, but other than that this code should look exactly the
 same by the time we are done.
 
 ### Combine and callbacks

 Callbacks have, since time immemorial, been the way that programmers
 deal with asynchrony - events which occur at unpredictable time intervals.
 Obvious examples of asynchrony include network requests returning their
 results, user gestures, gps location notifications, accelerometer events,
 and bluetooth notifications.
 
 In case you aren't familiar with this aspect of programming,
 the way that these events are dealt with in your code is to present the
 operating system with a function to be invoked when the event occurs.
 Such a function is called a `callback`, because the operating system,
 much like in a phone conversation, "calls you back" when it has something
 to tell you about an asynchronous event.
 
 So what's wrong with this mechanism? Sounds simple enough.  You make
 a function, you hand it to the operating system, it calls you back when
 it's good and ready and...  Well, to give an example of how complex
 it gets, suppose that the event the operating system handles is a user
 gesture. Any user gesture.
 
 User gestures come in a wide variety of shapes and sizes: taps, drags,
 pinches, zooms, et al.  Just expanding on taps, they themselves come
 with single, double and triple taps and with one, two, three or four
 fingers.  So in our simplified model, we hand iOS a function with
 some gigantic method that looks sort of like this:
 
 ```
 if gesture.isTap {
    let tap = gesture as! Tap
    switch tap.numTaps {
    case 1:
        switch tap.numTouches {
        case 1:
           // Code to handle a single tap with one finger
        case 2:
           ....
        case 3:
               ....
        case 4:
               ....
        }
    case 2:
        ...
    case 3:
        ...
    }
 } else if gesture.isDrag {
     ...
 } else
     ...
 ```
 
 Pretty clearly that's not a structure we want to have to maintain.
 For example, what if I want to do one thing on a single tap with two
 fingers at some points in my app and something else at other
 points?  In that case,
 I have to replace that entire piece of code. So what
 invariably happens is that you write a callback function which
 takes other callback functions as arguments. And those callback
 functions get nested into code such as that immediately above.
 I.e. the highest level callback is composed from smaller, more
 specific callback functions. And this process repeats ad nauseum.
 
 And we see, once again, functional composition in action. Ugly,
 unmaintainable action, but action, nonetheless.
 
 So callbacks generally consist of code that
 
 1. nests several levels deep,
 2. doesn't compose well, and
 3. contains a lot things that look like boilerplate
 
 This all sounds very reminiscent of what we saw with
 for-loops and the higher order functions on `Sequence`.
 Unsurprisingly, it turns out that that we can apply the same
 ideas to callbacks that we applied to for-loops.
 In the case of for-loops, we made higher order functions
 that used for-loops underneath and for callbacks, we'll make
 higher order functions that use callbacks underneath.
 
 ### Generating function-returning-functions
 
 Let's look again at our
 simplest example from the Combine I playground and see
 if we can't write something like Combine for ourselves.
 Here it is as a reminder:
 ```
 let c1 = [1, 2, 3]
     .publisher
     .map { $0 * 2 }
     .map { Double($0) }
     .map { "\($0)" }
     .sink { r2.append($0) }
 ```
 
 Now let's further look at a subset of that
 (I've pulled the publishers apart for explication):
 */
var result2 = [Int]()
let publisher1 = [1, 2, 3].publisher
publisher1
let publisher2 = publisher1.map { $0 * 2 }
publisher2
/*:
 Now that we know about function-returning-functions, we can actually
 describe what is going on here.  Let's discuss this line to start:
 
     let publisher1 = [1, 2, 3].publisher // return Publishers.Sequence
 
 The Publisher being used, i.e. `Publishers.Sequence`,  has an initializer
 which accepts an array. So on the invocation of
 `.publisher`, the array [1, 2, 3] instantiates a Publishers.Sequence using the
 array-accepting init.
 
 ### Doing our own mini Combine
 
 If we ignore the demand/backpressure and most of the
 error handling features of Combine to simplify things a bit,
 we can imagine that the `Array` publisher is implemented
 as something like the following (we can't be sure of course
 since Combine is closed-source).
 
 First, there's an enum
 that represents the termination of the sequence, either
 in a normal completion or in an error.  This is of course
 generic in the error type.
 */
enum Termination<E: Error> {
    case complete
    case failure(E)
}
/*:
 Then we need (as we saw earlier) some object that can
 accept the Termination.  For now, we'll create it, but
 not give it any functionality.
 */
struct MyCancellable { }
/*:
 Now we need a `Publisher` type which can actually take an array
 of objects and publish them.  It needs to be generic in the
 type of object published and in any errors it might generate.
 */
struct MySequencePublisher<Published, E: Error> {
    var array: [Published]
    
    init(_ array: [Published]) {
        self.array = array
    }
}
/*:
 The publisher needs to somehow get a sink attached to it so
 that it can emit the contents of the array into the `sink`.
 This turns out to be pretty simple to implement.
 */
extension MySequencePublisher {
    func sink(
        _ termination: (Termination<E>) -> Void = { _ in },
        _ value: (Published) -> Void
    ) -> MyCancellable {
        array.forEach(value)
        termination(.complete)
        return MyCancellable()
    }
}
/*:
 Note that this publisher, simply takes the elements of the array one at a
 time, publishes them with the `value` closure and then when it's gotten to
 the end of the array, it sends the `.complete` via the `termination` closure.
 
 You should also note this publisher emits its values _immediately_ upon
 invoking `sink` and _before_ it calls `return`.  So we're not showing
 all the features of Combine because this publisher is
 synchronous in nature.  It's sort of a bummer, but this is enough for
 us to see how Combine is architected.  In an _asynchronous_ publisher
 the `return` would happen and the `value` and `termination` closures
 would be invoked at some later point.  They would also have to be marked
 `escaping`, which these are not.
 
 After invoking `value` and `termination`, the publisher then returns
 a MyCancellable.  We can see in this implemenation why MyCancellable
 was left unimplemented - because by the
 time we could do anything with it, the publisher will have terminated
 anyway.
 Note that we provide a default for a termination closure
 which doesn't do anything. This just lets us ignore it for now and
 focus on the `value` function.
 
 If you don't understand the above, you should
 pause here and study it. It's important to understand because
 we are going to compose that function with other functions.  A lot.
 
 In this example, `termination` and `value` are our _callbacks_. All that
 we have done here is wrap the pair of them up as parameters to the `sink`
 function.
 
 Finally, we can make it possible for _any_ `Array` at all to produce
 one of our `MySequencePublisher` objects.
 */
extension Array {
    var myPublisher: MySequencePublisher<Element, Never> { MySequencePublisher(self) }
}
/*:
 And we are ready to use it.  Note the compactness of the style and
 how this looks precisely like our Combine example.
 */
let myPublisher1 = [1, 2, 3].myPublisher
let myCancellable1 = myPublisher1.sink { print("\($0)") }
/*:
 Again, this is a _very_ simplified model of what is going on,
 but it's enough to show the general concepts.  The big idea here
 is that sink accepts not just one, but two _callback_ functions.
 One function gets called for each value
 published and the other is called only when the publishing terminates.
 
 So, in the lines of code immediately above, as soon as we
 invoke `sink`, `myPublisher` returns a `MySequencePublisher` instance
 which we assign to `myPublisher1`. `myCancellable` for this
 particular publisher isn't really cancellable, but this is
 what we saw in the "Combine I" playground as well.
 
 ### Transforming Publishers
 
 Now lets examine the next line in our original setup:
 
     let publisher2 = publisher1.map { $0 * 2 }
 
 what this says is that `publisher1` responds to `map`
 taking a closure.
 
 Lets see if we can work out what that should do for `publisher2`
 because _that_ in turn
 will illuminate big parts of how Combine works. This is going
 to get a little complicated, so you may want to make sure you
 study this until you are sure that you understand it.
 
 First lets create a protocol for things that can have a `sink`
 function on them.  Note that this is exactly the signature of the
 `sink` function on MySequencePublisher. We have only
 abstracted away the type of thing being published into
 an associatedtype
 */
protocol Sinkable {
    associatedtype Sinking
    associatedtype Erroring: Error
    
    func sink(
        _: @escaping (Termination<Erroring>) -> Void,
        _: @escaping (Sinking) -> Void
    ) -> MyCancellable
}
/*:
 Now we need to make `MySequencePublisher` conform to that
 protocol.  That's pretty easy since it already does,
 we just associate the generic types with the associatedtypes
 via a typealias and we are done.
 (You may want to review Playground 22 if it's not clear to
 you how associatedtypes and typealiases work together).
 */
extension MySequencePublisher: Sinkable {
    typealias Sinking = Published
    typealias Erroring = E
}
/*:
 And now we are ready to implement some of the real magic of Combine -
 all the transforming types of Publishers.  We'll start with `map`.
 (And leave all the others as an excercise for the reader :) ).
 
 Lets make a list of what we are trying to accomplish and as
 we implement each point we'll comment on it.
 We want to create a type `MyMapPublisher` which:
 
  1. Accepts and stores a `Sinkable` predecessor type in its `init`.
  2. Accepts a `transform` function in its `init` which transforms the
     `Published` type of the predecessor to the `Published` type of the
     `MyMapPublisher`
  3. Implements a higher-order function `compose` which accepts
     a function of type `(Published) -> Void` and returns a function
     of type `(Predecessor.Published) -> Void`
  4. Conforms to `Sinkable` itself by implementing
     a `sink` method which calls `compose`, passing in the `value`
     function of the sink and hands the return from compose to
     to the `value` function of the predecessor sink.
 
 Just reading that list makes me a little dizzy, frankly.  Remember when
 I told you in "Higher Order Functions II" that Combine is a library
 for composing functions which compose functions?  _THAT_ list right
 above is exactly what I meant.  So lets see if we can do all that.

 The key thing to note here is this idea of a predecessor type.
 While it is nowhere in Apple's documentation, I find
 it useful to think of Publishers as coming in two varieties -
 "Originating" and "Transforming".  Originating publishers sit at the
 top of a chain and they _create_ values that are passed down the chain.
 By definition, they don't need a predecessor to hand them values
 because they create values themselves.  `MySequencePublisher`
 in this playground is of the Originating type.  Transforming
 publishers on the other hand, cannot create new values out of
 thin air, they only act when they receive a value to transform.
 `MyMapPublisher` is of the transforming type. By definition
 it _must_ have a predecessor.
 
 The predecessor is the "upstream" object from which this publisher
 will receive values and termination.  The predecessor type
 _must_ be sinkable for reasons which will become obvious below.
 
 Here's an implementation which takes care of points 1 and 2.
 */
struct MyMapPublisher<Predecessor: Sinkable, Published>{
    let predecessor: Predecessor
    let transform: (Predecessor.Sinking) -> Published
    
    init(
        _ predecessor: Predecessor,
        _ transform: @escaping (Predecessor.Sinking) -> Published
    ) {
        self.predecessor = predecessor
        self.transform = transform
    }
}
/*:
 Ok, so 1 and 2 weren't so hard.  `MyMapPublisher` just needed to get the
 correctly constrained generic parameters into place.
 That is, it needed to know what type of thing it's predecessor was
 and what type of value it would publish into its sink functions.
 And we have to make those types generic, so that we can work with any
 Sinkable and any Published type.
 
 The main thing to note is that when our `value` function is invoked,
 we are taking the output of the predecessor
 and tranforming it to our own output type.  _Every_ transforming publisher
 will do precisely this.  These publishers come in a handful of forms,
 most of which correspond to one of the higher order functions we looked
 at on `Sequence`.  Not all of them do but, as we discussed in a previous
 playground, many of them do for quite logical reasons.
 
 And because we are the `Map` publisher, we will do
 _exactly_ what all of the other `map`
 functions we have encountered along the way always do.
 That is, the `map` function will live inside some
 generic and transform the type parameter of the generic
 into another type and then create a new generic that
 is parameterized by the transformed type.  Hopefully
 you are seeing yet again just how general the concept of `map` is.
 
 Now let's see if we can implement the third requirement and
 implement `compose` on our map type.
 
 We could kind of use our `>>>` operator from "Higher Order Functions II"
 here, so let's pull that in quickly.
 */
precedencegroup CompositionPrecedence {
  associativity: right
  higherThan: AssignmentPrecedence
  lowerThan: MultiplicationPrecedence, AdditionPrecedence
}
infix operator >>>: CompositionPrecedence

func >>> <A, B, C>(
    _ f: @escaping (A) -> B,
    _ g: @escaping (B) -> C
) -> (A) -> C {
    { (a: A) -> C in g(f(a)) }
}
/*:
 So I just cut and pasted that from before.  If you don't remember it,
 back up to the end of "Higher Order Functions II" and review.
 The forward composition operator will make
 what we are about to do really easy to read (and almost
 as importantly, force you to focus on the functional composition
 that we are doing).
 
 So here's the way we meet requirement 3 above, regarding a `compose`
 function that takes the predecessor's output and maps it to our
 own output.
 */
extension MyMapPublisher {
    func compose(
        _ output: @escaping (Published) -> Void
    ) -> (Predecessor.Sinking) -> Void {
        transform >>> output
    }
}
/*:
 So all that our compose function does is return a function
 which first invokes `transform` and then invokes `output`
 on what transform returns.
 If you aren't comfortable with the functional notation
 yet, this is equivalent to:
 
    output(transform(input))  // g(f(a)) from >>> definition
 
 So there's requirement 3 from up above taken care of.  Also
 not nearly so hard as we thought it would be.
 
 The key thing to note here is that every
 different type of transforming publisher
 will implement a different `compose` function, but that
 the signature of that compose function will look _precisely_
 the same.
 
 The contents of `compose` make each transforming `Publisher`
 different, but all of the other things
 we attach to the publisher are actually common across every type
 we can think of.
 
 Ok, so lets implement requirement 4 and make `MyMapPublisher` conform
 to `Sinkable`
 */
extension MyMapPublisher: Sinkable {
    typealias Sinking = Published
    typealias Erroring = Predecessor.Erroring

    func sink(
        _ termination: @escaping (Termination<Erroring>) -> Void = { _ in },
        _ value: @escaping (Sinking) -> Void
    ) -> MyCancellable {
        predecessor.sink(termination, compose(value))
    }
}
/*:
 Once again, we see the standard functional programming pattern of
 all the work consisting of getting the types right
 in the function declaration and then having the implemenation come
 out to be a single line.  If you don't immediately see how we are
 connecting the downstream types to the upstream types there you'll
 want to study it until you do.
 
 Note that because we have separated the `compose` function out to its
 own function, the `sink` function is extremely general. We
 could in fact move this implementation to a protocol extension of
 `Sinkable` and not have to implement it on any type which conforms
 to `Sinkable`.  I won't here because then I'd need to change the
 code above and it would interrupt the flow of the playground. But
 you should be aware that that is precisely what Combine does in
 the Publisher protocol.  All of the generality that we are dealing
 with here lives in protocol extensions.
 
 It may be obvious but if you understand the line:
```
 predecessor.sink(termination, compose(value))
```
 you are well on your way to understanding Combine.  So let's be very
 clear about what that line is doing.
 
 (Remember that value here is not a "value" it's the name of a
 function that accepts new values of the Published type of
 this publiser)
 
 So, when you invoke `sink` on
 a _transforming_ publisher, that publisher composes a function
 using a) the `value` function it has been provided to publish values on and
 b) it's own internal state, in this case a `transform` function it
 captured when it was initialized.  The output of `compose`
 _must_ have the form of being a suitable `value` function for this
 publisher's predecessor.  The publisher then hands the `compose`d
 function to it's predecessor as the predecessor's own output function
 and the entire process recurses.
 
 Eventually this recursion of function composition reaches the top of
 the chain and an originating publisher simply accepts the final
 composed function as it's `value` function.  At that point all of the
 intermediate functions have been incorporated into one giant
 function, including the terminal closure attached to the original
 `sink` function.  The ultimate signature of the final composed
 function is `(Originating.Published) -> Void` with all of the
 intermediate types erased.  This function in a sense, is all
 that remains of the `Publisher` chain we created - all of the
 intermediate state is simply composed into a unified whole when
 the `sink` function is invoked.
 
 This step is absolutely at the heart of Combine.  Combine does
 what it does by recursively composing chains of `value` functions
 until it gets to the top of the chain.  It's almost like knitting,
 we're just using functions as the yarn.
 
 Now we are ready to implement the `map` function on our original publisher.
 Watch closely.  :)
 */
extension MySequencePublisher {
    func map<T> (
        _ transform: @escaping (Published) -> T
    ) -> MyMapPublisher<Self, T> {
        MyMapPublisher(self, transform)
    }
}
/*:
 Again, a one-liner with loads of typing involved. :)
 
 What we see is that when you call `map`, all that happens is that you transform
 the current `MySequencePublisher` into a `MyMapPublisher`.  Remember that none of the
 actual publishing can happen until you call `sink`. So basically, we're
 just collecting a bunch of closures here.
 
 So lets recall some code from up above:
```
     var result2 = [Int]()
     let publisher1 = [1, 2, 3].publisher
     publisher1
     let publisher2 = publisher1.map { $0 * 2 }
     publisher2
```
 Let's see what we get back from the following:
 */
let myPublisher2 = myPublisher1.map { $0 * 2 }
print(type(of: myPublisher2))
/*:
 This is one of the most revealing lines in the entire playground.
 Read the type of `myPublisher2` in the output below very
 carefully.  Here it is printed for you:
 ```
 MyMapPublisher<MySequencePublisher<Int, Never>, Int>
 ```
 What this tells us is that myPublisher2 has a MySequencePublisher
 wrapped up inside it.  Remember that the `map` function creates
 a `MyMapPublisher` and the `init` for that type accepts the
 predecessor as an argument which is then stored in the `init`'d
 value.  Whenever we create these transforming publishers
 we end up with nested predecessors, right back up to the top
 of the chain.
 
 Now, we don't have to keep those around, we can use some
 type erasure techniques here (and that's what Combine actually
 does.)  But I find it very useful for teaching purposes to keep
 them around to help you visualize what's going on.
 
 Let's print the new values that we get from our new publisher.
 */
print("=========== New output =============")

let myCancellable2 = myPublisher2.sink { print("\($0)") }
/*:
 And... if you look below, tah-dah! we have implemented `map` on our original
 `MySequencePublisher` correctly.  We're only missing one last piece in order
 to have completely mimicked what Combine does with its Map publisher.
 
 ### Recursive Composition and Chaining
 
 To truly get a feel for how Combine works, we need to implement
 chaining of all kinds of transforming publishers. (Actually on all publishers
 but for now we'll defer making it general across our originating publisher).
 In the example we're working through here,
 we need to get `MyMapPublisher` to implement `map` as
 well so that we can chain
 additional `map` calls onto it.
 So, let's do that, but let's do it the easy way.
 We'll start by declaring a `MyPublisher` protocol that has the `map`
 function in it.
 */
protocol MyPublisher: Sinkable {
    func map<T> (_ transform: @escaping (Sinking) -> T) -> MyMapPublisher<Self, T>
}
/*:
 Notice that the specification for `MyPublisher` uses the exact same
 signature that `MySequencePublisher` has already specified for the `map`
 function.  So we can just make `MySequencePublisher` conform to
 our new `MyPublisher` protocol.
 */
extension MySequencePublisher: MyPublisher { }
/*:
 Now notice that the following protocol extension uses
 the exact same implementation that we gave `MySequencePublisher` above.
 So in fact we could go up above and remove the implementation of `map`
 from `MySequencePublisher`, but then we'd have to rearrange a lot of
 things, so I'll leave that as an exercise for the reader.
 */
extension MyPublisher {
    func map<T> (_ transform: @escaping (Sinking) -> T) -> MyMapPublisher<Self, T> {
        MyMapPublisher(self, transform)
    }
}
/*:
 Lets do our exercise from "Higher Order Functions 1" and compare signatures of
 map functions (I've changed the generic parameter names to match across all three).
 ```
       Array<A>: func map <B>(_ f: (A) -> B) ->          Array<             B> // Array
    Optional<A>: func map <B>(_ f: (A) -> B) ->       Optional<             B> // Optional
 MyPublisher<A>: func map <B>(_ f: (A) -> B) -> MyMapPublisher<Predecessor, B> // MyPublisher
 ```
 There's an extra parameter type on `MyMapPublisher` that has to do with the predcessor
 but if we ignore that we see that that `map` on a `MyPublisher` does _exactly_
 what you expect `map` to do on any generic type, it transforms the
 generic type parameter.
 
 And now since `MyMapPublisher` already conforms to Sinkable, we can
 just tell it to conform to `MyPublisher` for free.
 */
extension MyMapPublisher: MyPublisher { }
/*:
 And now we can _chain_ map commands.  Remember our very first Combine example
 back in Combine I?  Here it is again:
```
 var r2: [String] = []
 let c1 = [1, 2, 3]
     .publisher
     .map { $0 * 2 }
     .map { Double($0) }
     .map { "\($0)" }
     .sink { r2.append($0) }
 ```
 The key things to note are that each one of those `map` calls is:
 
 1. being presented with it's downstream `sink` function as soon as the
    last `sink` is called in the chain.
 2. composing the downstream `sink` with its `transform` function and
 3. presenting the composition to it's upstream predecessor as its
    sink function.

 i.e. the chain above is doing recursive functional composition from
 the bottom of the chain to the top, _but only when `sink` is invoked_.
 And the recursion terminates at the top of the chain.
 
 Let's try it out with the code we just wrote.
 */
var r2: [String] = []
let c1 = [1, 2, 3]
    .myPublisher
    .map { $0 * 2 }
    .map { Double($0) }
    .map { "\($0)" }
    .sink { r2.append($0) }
r2
/*:
 And Boom! if you look at the output on the right, you'll see that
 we have taken _exactly_ the code that we used with Combine and
 made it produce _exactly_ the same output
 with our very own MySequencePublisher and MyMapPublisher types.
 
 For completeness,
 you might want to remove the implementation of `map` on `MySequencePublisher`
 and just make `MySequencePublisher` conform to `MyPublisher`, but I'm going
 to stop there and make some observations.
 
 Let's do one more thing to sort of give you an idea of what's going on here.
 */
let myPublisher3 = [1, 2, 3]
    .myPublisher
    .map { $0 * 2 }
    .map { Double($0) }
    .map { "\($0)" }
print(type(of: myPublisher3))
/*:
 If you look at the type of `myPublisher3` I think it's very
 revealing.  You get a real feel for what we have composed in this
 very simple way.  It's this complex set of nested structures
 each of which relate to the one before and behind them in the
 chain in a very specific way - their input has to match their
 predecessors output.  This is the key to understanding the error
 messages that you will invariably get from Combine.  You _must_
 make the input of a publisher match the output of its predecessor.
 
 ### Relationship to Combine
 
 By no means have
 we come close to implementing Combine, but we have done an example that shows
 the important features of:
 
 1. Replacing callbacks with chaining
 2. Making transforming publishers that can be implemented in a protocol
 3. Composing each type of publisher by recursively chaining its `sink` function
    to its predecessor's `sink` function
 
 What have we missed from Combine?  Well here's a partial list:
 
 1. Sink is not the only way of terminating a Combine chain.  We skipped
    pretty much all of Combine's subscribe features, in particular
    as we noted, backpressure.
 2. We have implemented only the very simplest form of Publishers,
    the ones for `Array` and `map`.  Everything else is more complex.
 3. We have completely ignored error handling
 4. We have done absolutely nothing with Cancellable
 5. We haven't explained those other really important fundamental
    elements of generics: `zip`, `reduce`, and `flatMap` at all.
 6. Everything here is synchronous and the whole point of Combine
    is really _asynchrony_.
 
 But we've made a start and in subsequent playgrounds we'll
 explain a lot of those features, we just won't implement our
 own version any more.
 
 ### "Point-free" Style
 
 One more thing I want to discuss before we finish talking about higher
 order functions - the "point-free" style aka tacit programming.
 [Wikipedia](https://en.wikipedia.org/wiki/Tacit_programming) is a pretty
 good place to start reading more about it.
 
 Point-free style is perfectly acceptable in Swift and is being
 used more and more (not least by me), so you need to be fluent
 with it.  The idea is that you defer creating variables as
 much as possible and instead simply compose your function
 from the bottom and call it once from the top. Let's work
 our example from above in that style.
 
 First we are going to need our curry function from
 "Higher Order Functions II", so let's go ahead and declare it.
 */
public func curry<A, B, C>(
    _ function: @escaping (A, B) -> C
) -> (A) -> (B) -> C {
    { (a: A) -> (B) -> C in
        { (b: B) -> C in
            function(a, b)
        }
    }
}
/*:
 And lets do one more so we can be completely point-free below.
 This one is called `pipe` and it makes everything read nicely
 left to right by piping the arguments to functions in from the
 left.
 */
infix operator |>: CompositionPrecedence
public func |> <A, B> (a: A, f: (A) -> B) -> B {
  return f(a)
}
/*:
 The goal in our example below is to replace all of the occurrences of
 inlined closures with functions which Swift can
 infer types on.  We'll remove the closures created in trailing
 closure syntax and let map operate directly on the functions which
 are currently being wrapped.  This can read much more cleanly and
 strips away a lot of unnecessary syntax.
 
 When looked at that way, you can see the following transformations,
 which we will dissect one by one:
 
     { $0 * 2 } => 2 |> curry(*)
 
 `curry(*)(2)` here takes the `*` infix operator which is a generic
 function of two arguments of the same type.  By currying that function
 and partially piping the value `2` into it, the compiler is able to infer
 that we are talking about multiplication of two `Int`s
 rather than multiplication on some other type and therefore can cause
 this expression to return a function which takes one Int argument
 and multiplies it by 2. Which is exactly the signature we need to
 pass to `map` on a `MySequencePublisher` of `Int`s.
 
     { Double($0) } => Double.init

 All init's are static functions on the type they are associated with.
 And it turns out that `Double.init` is overloaded on several different
 types, one of which is Int.  So there is a function called
 `Double.init` which takes a single argument of Int and the compiler
 can infer that that is the one mean here.  And this form saves
 us wrapping the init up into an enclosing closure.
 
     { "\0" } => \.description

 Swift has a special syntax for describing the functions which
 perform `get` and `set` on a type's properties.  These are
 referred to as `Keypath`s and they are a remarkably powerful
 feature of the language that you can plug in anywhere you
 need to access a getter or setter function.
 In this case `\.description` says take
 whatever type you have inferred us to be talking about here and
 invoke the getter named `description` on it. Since `description`
 returns a String, this is precisely the same as what we are doing
 on the left hand side of the => there.  Again, since keypaths
 can be interpreted as functions wrapping `get`, we don't need to
 wrap it up in an additional closure.
 
 So here are those changes applied to our example:
 */
var r3 = [String]()
let c2 = [1, 2, 3]
    .myPublisher
    .map(2 |> curry(*))
    .map(Double.init)
    .map(\.description)
    .sink { r3.append($0) }
r3
/*:
 You are probably wondering why I didn't move the `sink` to be
 point-free.  If you look closely, what we are doing in the
 `sink` method is mutating the `r3` array.  For somewhat
 technical reasons relating to capture semantics, I can do
 that with a closure created in-line, but I wouldn't be able
 to do that with a top level function.  To fix this, I'd need
 to wrap `r3` in a reference type and mutate the value through
 a method on the reference type.  That seemed a bit excessive
 as I want you to focus on the style more than on all of the
 minutiae, so for now we are leaving `sink`'s points sticking out.
 
 And as I mentioned at the beginning of Combine I, any time we see
 `map` functions following each other, we can compose the functions
 provided to the various maps together into a single function and
 just call map once with that single function.
 So since we have a very handy way of composing functions
 together, lets go ahead and do that.
 */
let transform = (2 |> curry(*)) >>> Double.init >>> \.description
/*:
 Note that in this form everything reads from left to right, our
 eyes never need to scan back to try to and figure out which function
 is using some part of our expression. Also
 note that `transform` is of type: `(Int) -> String`. Which, to me,
 seems quite remarkable.  Just like in "Higher Order Functions II"
 we've been able to type erase a lot of stuff and come up with
 a glued-together function which perfectly fits what we are trying to
 do. Now we can take our composed function and use it in one single
 `map` call.
 */
var r4 = [String]()
let c3 = [1, 2, 3]
    .myPublisher
    .map(transform)
    .sink { r4.append($0) }
r4
/*:
 One final word,
 we could have taken the entire expression for `transform`
 from above and then have
 pasted it in right there as-is.  That's one of the nice things
 about this style is that it has that level referential transparency.
 It helps you do what the Haskell community calls equational reasoning.
 
 And now I think we are ready to move ahead to the other features of
 Combine.
 */
