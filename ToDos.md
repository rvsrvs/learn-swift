# To Do

1. Add a separate playground on map culminating in map on function types, show that it is equivalent to `>>>`
2. Add a separate playground on flatMap culminating in flatMap on function types
3. Do a separate playground on contraMap, using Predicate as an example. Show that it is a characteristic of generics over functions
4. Add a playground on contraFlatMap continuing to use Predicate as the example
5. Add a separate playground on dimap as the composition of a contraMap and a map.
6. Carry the preceding playgrounds into a playground on the Func type.  Provid std forms of map, flatmap, contramap, contraflatmap, dimap, invmap
7. Do a separate playground on Protocol Witnesses explaining existential types, work through mechanically getting rid of protocols altogether
8. Carry the two preceding playgrounds into a playground on CallAsFunction protocol
9. Show the complete interaction between base functions, Func and CallAsFunction to produce the FunctionalProgramming.swift playground
10. Do a playground on KeyPath and Binding and show how they are alike. In particular show that the compose getters and setters
11. Do a playground on point-free style showing intermixing keypaths and functions. Explain the point-free style is all about composing the functions without application until the very end
12. Add a playground on zip(with:) as Applicative, putting a step in between map and flatMap
13. Replace existing Higher Order Functions III with a playground on Free Combine using the above.
14. Add Asynchrony to Free Combine
15. Add a playground showing how higher-order functions on types replace imperative language constructs:

  1. for-loops -> Sequence
  2. while-loops -> Trampoline
  3. throws -> Result
  4. call-backs -> Publisher
  5. inheritance -> Func via currying
  6. wait -> Future/Promise

16. Add KeyPaths and Bindings to the base swift material
17. Add CallAsFunction to the base swift material
18. Add a playground on function dispatch to the base material
19. Incorporate `@escaping` to the base material
20. Incorporate `inout` to the base material
21. Add a playground on invmap to show the extension to Reducers
22. Review current version of `The Swift Programming Language` for missed items.
23. Add a playground on variadic functions
