import SwiftUI
import Combine

/*:
 ## Functional Reactive Programming
 The functional reactive programming (FRP) style as embodied in Combine takes functional decomposition into the asynchronous domain of handling events.  Under FRP you should think of your application as being a collection of functions which are nested in an event loop or loops. In GUI apps that's typically the event loop of the main thread, in server apps, it's the event loop of a worker thread.

 When an event enters the event loop, a function is selected to dispatch the event into. That function is called by passing in 1) the current state of the application AND 2) the new event.  The function returns 3) a tuple composed of the new state of the application and 4) any side-effects to be performed. In this model, ApplicationState is an immutable value type wrapped in a reference type which is mutable.  The old value type is replaced at the end of the event loop by the new value computed by the function the event was dispatched into and any accumulated side-effects are dispatched.

 Wrt to side-effects: in this model, side-effects are “pushed to the edge of the world” by cumulating them and executing them at the bottom of the event loop after execution of the event-handling function.   Side-effects can generate new events, which enter the queue of events to be processed.  Some types of side-effects that you can think of include: updating the display, firing a network request, and starting a timer.

 This model is precisely the one used by SwiftUI. Display update is a direct side-effect of updating ApplicationState implemented as part of the SwiftUI framework.  SwiftUI's Views are not mutable for this reason.  They are generated using a particular value of the Application State to which they are connected by property wrappers of various forms.

 The above ineluctably implies that long-running applications should be organized as collections of functions of the form: (ApplicationState, Event)->(ApplicationState, [Effect<Action>]).  In functional programming terms, functions with this signature are called reducers. Your application should decompose this function into a chain of function invocations mediated by the type system. If you are working with a mutable ApplicationState, this signature is (&ApplicationState, Event)->[Effect<Action>]. The equivalent form of this latter function in OO notation is: applicationState.handle(anEvent)->[Effect<Action>] where the applicationState is mutated by the event handling method call.

 The unconstrained creation of side-effects arising from the introduction of mutation by the OOP style is a critical difference between the two approaches. This difference explains why you don't want to return Void during your function application. Returning Void anywhere in this chain is a clear signal that you have introduced a side-effect that is not being pushed to the edge of the world and it breaks the flow of the function invocation chain, to boot.

 Chaining on the return type of Void means that the type system cannot help you reason about the handling of an event or assist in managing side-effects.  Allowing the type system to help is one of the main appeals of the FRP style and properly done can greatly improve programmer productivity.

 Side Note:  one way of looking at the imperative style is to observe that every statement is a Void-returning function call and that even when programming imperatively, the functional model still covers things. It's just that the ability of the type system to assist in writing the program has been discarded.

 The FRB style is so different from the traditional UIKit MVC model that it can be disorienting at first.  A good diagram of what this style looks like can be found [here](https://github.com/NoTests/RxFeedback.swift).  This is a nice graphic drawn from that location.

 ![State Diagram](state-frp.png)

 FRP-based applications should be thought of as following this model with State being divided into many intercommunicating substates.  This point is very important.  None of the discussion above implies at all that there should be only a single global state available to the application.  Most large UIKit applications end up with such a single global type (frequently signalled by a name that includes the word `Context`), but this is an anti-pattern in SwiftUI.
 */
