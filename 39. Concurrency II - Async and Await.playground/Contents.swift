import _Concurrency
import Foundation

public struct Continuation<A, R> {
    fileprivate let `return`: (@escaping (A) async -> R) async -> R
    public init(_ `return`: @escaping (@escaping (A) async -> R) async -> R) {
        self.return = `return`
    }
    public init(_ a: A) {
        self = .init { downstream in
            await downstream(a)
        }
    }
    public func callAsFunction(_ f: @escaping (A) async -> R) async -> R {
        await `return`(f)
    }
}

public extension Continuation {
    // Self = Continuation<A, R>
    func map<B>(_ f: @escaping (A) -> B) -> Continuation<B, R> {
        .init { downstream in await self { a in
            await downstream(f(a))
        } }
    }
    func flatMap<B>(_ f: @escaping (A) -> Continuation<B, R>) -> Continuation<B, R> {
        .init { downstream in await self { a in
            await f(a)(downstream)
        } }
    }
    func log(_ f: @escaping (A) -> String) -> Continuation<A, R> {
        .init { downstream in await self { a in
            print(f(a))
            return await downstream(a)
        } }
    }
}

public typealias Just<A> = Continuation<A, A>
public extension Just where R == A {
    func futureValue() async -> A { await `return`(identity) }
}

public func identity<T>(_ t: T) -> T { t }

public func zip<S, A, B, R>(
    _ ca: Continuation<S, A>, _ bridge1: @escaping (S) -> A,
    _ cb: Continuation<S, B>, _ bridge2: @escaping (S) -> B
) async -> Continuation<(A, B), R> {
    .init { downstream in
        //        async let a = ca(bridge1)
        //        async let b = cb(bridge2)
        //        return await downstream(await (a, b))
        let pair = await withTaskGroup(of: (A, B).self) { group -> (A, B) in
            group.async { await (ca(bridge1), cb(bridge2)) }
            guard let pair = await group.next() else { fatalError("Zip failed") }
            return pair
        }
        return await downstream(pair)
    }
}

public func zip<A, B, R>(
    _ ca: Continuation<A, A>,
    _ cb: Continuation<B, B>
) async -> Continuation<(A, B), R> {
    .init { downstream in
            //                    async let a = ca.futureValue()
            //                    async let b = cb.futureValue()
            //                    return await downstream(await (a, b))
        let pair = await withTaskGroup(of: (A, B).self) { group -> (A, B) in
            group.async { await (ca(identity), cb(identity)) }
            guard let pair = await group.next() else { fatalError("Zip failed") }
            return pair
        }
        return await downstream(pair)
    }
}

// Three functions that compose together
func doubler(_ value: Int) -> Double { .init(value * 2) }
func toString(_ value: Double) -> String { "\(value)" }
func encloseInSpaces(_ value: String) -> String { "   \(value)   " }

func test() {
    let futureString: Just<String> = Continuation<Int, String>(14)
        .map(doubler)
        .map(toString)
        .map(encloseInSpaces)
    type(of: futureString)

    let futureDouble: Just<Double> = Continuation<Int, Double>(14)
        .map(doubler)
    type(of: futureDouble)

    let handle = Task {
        let fv = await futureString.futureValue()
        type(of: fv)
        let value = fv.trimmingCharacters(in: .whitespaces)
        type(of: value)
        print(value)
    }

    handle.cancel()

    _ = Task {
        let (d, s) = await zip(futureDouble, futureString).futureValue()
        print("D = \(d)")
        print("S = \(s)")
    }
}

test()

// we can compose functions
public func compose<A, B, C>(
    _ f: @escaping (A) async -> B,
    _ g: @escaping (B) async -> C
) -> (A) async -> C {
    { a in await g(f(a)) }
}

// we can compose functions
public func curriedCompose<A, B, C>(
    _ f: @escaping (A) async -> B
) -> (@escaping (B) async -> C) async -> (A) async -> C {
    { g in { a in await g(f(a)) } }
}

struct Func<A, B> {
    let call: (A) async -> B
    func callAsFunction(_ a: A) async -> B { await call(a) }
    init(_ call: @escaping (A) async -> B) { self.call = call }
}

extension Func {
    func map<C>(_ f: @escaping (B) -> C) -> Func<A, C> {
        .init { a in
            f(await call(a))
        }
    }
    func contraMap<C>(_ f: @escaping (C) -> A) -> Func<C, B> {
        .init { c in
            await call(f(c))
        }
    }
    func flatMap<C>(_ f: @escaping (B) -> Func<A, C>) -> Func<A, C> {
        .init { a in
            await f(call(a))(a)
        }
    }
    func dimap<C, D>(
        _ f: @escaping (C) -> A,
        _ g: @escaping (B) -> D
    ) -> Func<C, D> {
        .init { c in
            g(await self(f(c)))
        }
    }
}

func zip<A, B, C, D>(
    _ f: Func<A, B>,
    _ g: Func<C, D>
) -> Func<(A, C), (B, D)> {
    .init { a, c in
        await (f(a), g(c))
    }
}

func zip<A, B, C, D, R>(
    _ f: Func<A, B>,
    _ g: Func<C, D>,
    with h: @escaping (B, D) async -> R
) -> Func<(A, C), R> {
    .init { a, c in
        await h(f(a), g(c))
    }
}

let f1 = Func(doubler).map(toString).map(encloseInSpaces)
Task {
    let value = await f1(14)
        .trimmingCharacters(in: .whitespaces)
    print(value)
}
