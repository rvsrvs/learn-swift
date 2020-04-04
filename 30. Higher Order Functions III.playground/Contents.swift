import Combine
/*:
 ## Higher Order Functions III - Recursive Chaining
 
 In this playground we want to see exactly _how_ Combine uses
 functional composition to do what it does.  Remember how in
 Higher Order Functions I we saw that the the higher order functions
 on Sequence were really just wrappers around for-loops
 which abstracted away patterns of for-loop usage that you
 never knew existed?  Well it turns out that Combine does
 _precisely_ that same thing for _callbacks_.
 
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
 Because what if I want do one thing on a single tap with two
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
 
 So callbacks generate code that nests several levels deep,
 doesn't compose well, and contains a lot code that looks like
 boilerplate - sounds very reminiscent of what we saw with
 for-loops and the higher order functions on `Sequence`.  And
 unsurprisingly it turns out that that we can apply the same
 ideas to callbacks.  For for-loops, we made higher order functions
 that used for-loops underneath and for callbacks, we'll make
 higher order functions that use callbacks underneath.
 
 ### Combine recursively generates function-returning-functions
 
 Let's look at our
 simplest example from the Combine I playground and see
 if we can't write something like the Combine code ourselves.
 Here it is as a reminder:
 ```
 let c1 = [1, 2, 3]
     .publisher
     .map { $0 * 2 }
     .map { Double($0) }
     .map { "\($0)" }
     .sink { r2.append($0) }
 ```
 
 Let's look again at a subset of our simple Combine example
 (I've pulled the publishers apart for explication):
 */
var result2 = [Int]()
let publisher1 = [1, 2, 3].publisher
publisher1
let publisher2 = publisher1.map { $0 * 2 }
publisher2
let cancellable1 = publisher2.sink { result2.append($0) }
cancellable1
/*:
 Now that we know about function-returning-functions, we can actually
 describe what is going on here.  Let's discuss this line to start:
 
     let publisher1 = [1, 2, 3].publisher // return Publishers.Sequence
 
 The Publisher being used, i.e. `Publishers.Sequence`,  has an initializer
 which accepts a closure. On the invocation of
 `.publisher`, [1, 2, 3] instantiates a Publishers.Sequence using the
 closure-accepting init.
 
 ### Doing our own mini Combine
 
 If we ignore the Publisher protocol and demand/backpressure features
 of Combine to simplify things a bit, we can imagine that
 the `Array` publisher is implemented as something like
 the following (we can't be sure of course since Combine
 is closed-source).  First, there's an enum
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
 of objects and publish them.
 */
struct MySequencePublisher<Published, E: Error> {
    var array: [Published]
    
    init(_ array: [Published]) {
        self.array = array
    }
}
/*:
 The publisher needs to somehow get a sink attached to it so
 that it can emit the contents of the array into the `sink`,
 so that's a pretty simple implementation.
 */
extension MySequencePublisher {
    func sink(
        _ termination: (Termination<E>) -> Void = { _ in },
        _ value: (Published) -> Void
    ) -> MyCancellable {
        var slice = ArraySlice(array)
        while let head = slice.first {
            value(head)
            slice = slice.dropFirst()
        }
        termination(.complete)
        return MyCancellable()
    }
}
/*:
 Note that this publisher, simply takes the elements of the array one at a
 time, publishes them with the `value` closure and then when it's gotten to
 the end of the array, it sends the `.complete` via the `termination` closure.
 
 If you don't understand this, you should study it, it's important because
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
let myCancellable1 = [1, 2, 3].myPublisher.sink { print("\($0)") }
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
 what we saw in Combine I as well.
 
 ### Generalized Publishers
 
 Now lets examine the next line in our original setup:
 
     let publisher2 = publisher1.map { $0 * 2 }
 
 what this says is that `publisher1` responds to `map` taking a closure.
 
 Lets see if we can work out what that should do for `publisher2`
 because _that_ in turn
 will illuminate big parts of how Combine works. This is going
 to get a little complicated, so you may want to make sure you
 study this until you are sure that you understand it.
 
 First lets create a protocol for things that can have a `sink`
 function on them.  Note that this is exactly the signature
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
 Now we need to make MySequencePublisher conform to that
 protocol.  That's pretty easy, we just associate the
 generic types with the associatedtypes via a typealias
 command. (You may want to review Playground 22 if this
 is not clear).
 */
extension MySequencePublisher: Sinkable {
    typealias Sinking = Published
    typealias Erroring = E
}
/*:
 And now we are ready to implement some of the real magic of Combine -
 all the general kinds of Publishers.  We'll start with `map`.
 (And leave all the others as an excercise for the reader :) ).
 
 Lets make a list of what we are trying to accomplish and as
 we implement each point we'll comment on it.
 We want to create a type `MyMapPublisher` which:
 
  1. Accepts and stores a Sinkable predecessor type in its `init`.
  2. Accepts a `transform` function in its init which transforms the
     `Published` type of the predecessor to the `Published` type of the
     MyMapPublisher
  3. Implements a higher-order function `compose` which accepts
     a function of type `(Published) -> Void` and returns a function
     of type `(Predecessor.Published) -> Void`
  4. Conforms to Sinkable itself by implementing
     a `sink` method which calls `compose`, passing in the `value`
     function of the sink and hands the return from compose to
     to the `value` function of the predecessor sink.
 
 Just reading that list makes me a little dizzy, frankly.  Remember when
 I told you in Higher Order Functions I that Combine is a library
 for composing functions which compose functions?  _THAT_ list right
 above is exactly what I meant.  So lets see if we can do all that.

 Key thing to note here is this idea of a predecessor type.
 The predecessor is the "upstream" object from which this publisher
 will receive values and termination.  The predecessor type,
 _must_ be sinkable for reasons which will become obvious below.
 
 Here's our an implementation which takes care of points 1 and 2.
 */
struct MyMapPublisher<Predecessor: Sinkable, Published>{
    let predecessor: Predecessor
    let transform: (Predecessor.Sinking) -> Published
    
    init(_ predecessor: Predecessor, transform: @escaping (Predecessor.Sinking) -> Published) {
        self.predecessor = predecessor
        self.transform = transform
    }
}
/*:
 Ok, so 1 and 2 weren't so hard.  `MyMapPublisher` just needed to get the
 correctly constrained generic parameters into place when you think about it.
 The main thing to note is that we are taking the output of the predecessor
 and tranforming it to our own output type. And because we are the
 `Map` publisher, we do exactly what all of the `map` functions we
 have encountered along the way always do. We live inside some
 generic type and transform the generic type into another type
 and then create a new generic type that is parameterized by the
 transformed type.  Hopefully you are starting to see yet again
 just how general the concept of `map` is.
 
 Now let's see if we can implement the third requirement and
 implement `compose` on our map type.
 
 We could kind of use our `>>>` operator from Higher Order Functions II
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
 back up to Higher Order Functions II and review.  It will make
 what we are about to do really easy to read (and almost
 as importantly, force you to focus on the functional composition
 that we are doing here).
 
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
 
 The key thing
 to note here is that every different type of generalized publisher
 will implement a completely different `compose` function. That's
 what actually makes them different.  All of the other things
 we put on the publisher are actually common across every type
 we can think of.
 
 Ok, so lets implement requirement 4 and make `MyMapPublisher` conform
 to `Sinkable`
 */
extension MyMapPublisher: Sinkable {
    typealias Sinking = Published
    typealias Erroring = Predecessor.Erroring

    func sink(
        _ termination: @escaping (Termination<Predecessor.Erroring>) -> Void = { _ in },
        _ publish: @escaping (Published) -> Void) -> MyCancellable {
        predecessor.sink(termination, compose(publish))
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
 own function, the `sink` function is in fact, extremely general.
 
 Now we are ready to implement the `map` function on our original publisher.
 Watch closely.  :)
 */
extension MySequencePublisher {
    func map<T> (_ transform: @escaping (Published) -> T) -> MyMapPublisher<Self, T> {
        MyMapPublisher(self, transform: transform)
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
     let cancellable1 = publisher2.sink { result2.append($0) }
     cancellable1
```
 and of course, who could forget:
```
     let myPublisher1 = [1, 2, 3].myPublisher
     let myCancellable1 = [1, 2, 3].myPublisher.sink { print("\($0)")
```
 
 Let's see what we get back from the following:
 */
let myPublisher2 = myPublisher1.map { $0 * 2 }
myPublisher2

print("=========== New output =============")

let myCancellable2 = myPublisher2.sink { print("\($0)") }
/*:
 And... if you look below, tah-dah! we have implemented map on our original
 MySequencePublisher correctly.  We're only missing one last piece in order
 to have completely mimicked what Combine does with the map publisher.
 
 ### Recursive Composition and Chaining
 
 To truly get a feel for how Combine works, we need to implement
 chaining of all kinds of general publishers.  In the example we're working
 through here,
 we need to get MyMapPublisher to implement `map` as well so that we can chain
 additional `map` calls onto it.
 So, let's do that, but let's do it the easy way.
 We'll start by declaring a `MyPublisher` protocol that has the `map`
 function in it.
 */
protocol MyPublisher: Sinkable {
    func map<T> (_ transform: @escaping (Sinking) -> T) -> MyMapPublisher<Self, T>
}
/*:
 Notice that the specification for MyPublisher uses the exact same
 signature that MySequencePublisher has already specified for the `map`
 function.  Then notice that the following protocol extension uses
 the exact same implementation that we gave MySequencePublisher above.
 */
extension MyPublisher {
    func map<T> (_ transform: @escaping (Sinking) -> T) -> MyMapPublisher<Self, T> {
        MyMapPublisher(self, transform: transform)
    }
}
/*:
 And now since `MyMapPublisher` already conforms to Sinkable, we can
 just tell it to conform to MyMapPublisher.
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
 
 ### Relationship to Combine
 
 By no means have
 we come close to implementing Combine, but we have done an example that shows
 the important features of:
 
 1. Replacing callbacks with chaining
 2. Making generalized publishers that can be implemented in a protocol
 3. Composing each type of publisher by recursively chaining its `sink` function
    to its predecessor's `sink` function
 
 What have we missed from Combine?  Well here's a partial list:
 
 1. Sink is not the only way of terminating a Combine chain.  We skipped
    pretty much all of Combine's subscribe features, in particular
    as we noted, backpressure.
 2. We have implemented only the very simplest form of Publishers,
    the ones for `Array` and `map`.  Everything else is much more complex.
 3. We have completely ignored error handling
 4. We haven't explained those other really important fundamental
    elements of generics: `zip` and `flatMap` at all.
 5. Everything here is synchronous and the whole point of Combine
    is really _asynchrony_.
 
 But we've made a start and in subsequent playgrounds we'll explain a lot of those
 features, we just won't implement our own version any more.
 */
