/*:
 # Pointfree Style

 ### Definitions
 */

public func identity<T>(_ t: T) -> T { t }

public func flip<A, B, C>(
    _ function: @escaping (A) -> (C) -> B
) -> (C) -> (A) -> B {
    { (c: C) -> (A) -> B in
        { (a: A) -> B in
            function(a)(c)
        }
    }
}

struct A {
    var b: String
    var c: String

    func interpolate(_ s: String) -> String {
        b + " \(s) " + c
    }
}

type(of: A.interpolate)

var bs = [["b1"], ["b2"], ["b3"], ["b4"], ["b5"]]
var cs = [["c1"], ["c2"], ["c3"], ["c4"], ["c5"]]

/*:
### Readings

 For an interesting article on point-free style you can start with the wikipedia
 article on: [Tacit Programming](https://en.wikipedia.org/wiki/Tacit_programming)
 Particularly amusing is the line there stating: "The lack of argument naming gives point-free style
 a reputation of being unnecessarily obscure, hence the epithet "pointless style"."

 The "points" from which the point-free style is free are the intermediate variables.

 If you look at FreeCombine, you'll notice that everything is produced as the composition
 of functions and that you completely compose the function before applying any arguments to it.

 Compare and contrast the following two styles.  First the traditional style:
 */
let step1b = bs.flatMap { $0 }
let step1c = cs.flatMap { $0 }
let step1 = zip(step1b, step1c)
let step2 = step1.map { A(b: $0, c: $1) }
let step3 = step2.map { $0.interpolate("traditional interpolator") }
let traditionalAs = step3.reduce("") { $0 + $1 }
print(traditionalAs)
/*:
 Now the same code in the point-free style...
 */
let pointfreeAs = zip(bs.flatMap(identity), cs.flatMap(identity))
    .map(A.init)
    .map(flip(A.interpolate)("pointfree interpolater"))
    .reduce("", +)
print(pointfreeAs)
type(of: flip(A.interpolate))
type(of: flip(A.interpolate)("pointfree interpolater"))

/*:
 To truly understand the point-free style, you need to be sure that you grasp what is
 happening in the lines that include: `identity`, `A.init`, `flip` and `+`.
 The problem
 in your homework where this is mentioned wants you to recognize that initializers
 are just static funcs in the same manner as above and to use type inference as much
 as possible.

 The point-free style is generally easier to read and reason about _at the edges_, but
 it is harder to debug in between.  That is, if you know the type of the arguments at the top
 and the return type of the composed function, this is a much more condensed form and
 assuming it is correct and pure, you can ignore the inner workings of the composed function
 as you analyze your code.  If you need to debug a particular function, you can
 put break points in that function, assuming you have the source.

 OTOH, if you have a bug in the logic in the middle and you don't know where the bug is,
 the point-free style is harder to debug.
 */
