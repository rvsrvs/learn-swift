import Combine
/*:
 ## The Point - Combine recursively generates function-returning-functions
 
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
 describe what is going on here.  Let's discuss this line:
 
     let publisher1 = [1, 2, 3].publisher // return Publishers.Sequence
 
 The Publisher being used, i.e. `Publishers.Sequence`,  has an initializer
 which accepts a closure. On the invocation of
 `.publisher`, [1, 2, 3] instantiates a Publishers.Sequence using the
 closure-accepting init.  It passes in a closure of something like
 the following form (we can't be sure bc Combine is closed-source):
 */
enum Deliverable<T, E: Error> {
    case complete
    case value(T)
    case failure(E)
}

//let closure = { ((delivery: Deliverable) -> Subscription.Demand) -> Void in
//    var slice = ArraySlice(self)
//    var completed = false
//    return {
//        guard !completed else { return }
//        while let head = slice.first, demand = delivery(head) {
//            slice = slice.dropFirst()
//        }
//        guard let head = slice.first else {
//            delivery(.complete)
//            completed = true
//            return
//        }
//    }
//}

/*:
 It returns a `Publishers.Sequence`
 which we assign to `publisher1`.  Now lets examine the next line:
 
     let publisher2 = publisher1.map { $0 * 2 } // Publishers.Sequence
 
 `publisher1` responds to `map` taking a closure.  `map` on `Publishers.Sequence`
 invokes another initializer of `Publishers.Sequence` which accepts a
 a closure. `publisher1`'s map implementation invokes that
 initializer passing in self and
 */

