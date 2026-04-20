import Testing
@testable import nadeef

@Suite("CompositeLineInterceptor")
struct CompositeLineInterceptorTests {
    
    private struct TransformInterceptor: LineInterceptor {
        let transform: (String) -> String?
        func intercept(line: String) -> String? { transform(line) }
    }
    
    @Test func emptyInterceptorListReturnsInputUnchanged() {
        let composite = CompositeLineInterceptor(interceptors: [])
        #expect(composite.intercept(line: "hello") == "hello")
    }
    
    @Test func appliesInterceptorsInOrder() {
        let upper = TransformInterceptor { $0.uppercased() }
        let suffix = TransformInterceptor { $0 + "!" }
        let composite = CompositeLineInterceptor(interceptors: [upper, suffix])
        #expect(composite.intercept(line: "hi") == "HI!")
    }
    
    @Test func shortCircuitsWhenAnyInterceptorReturnsNil() {
        var callsAfterNil = 0
        let dropper = TransformInterceptor { _ in nil }
        let spy = TransformInterceptor { line in
            callsAfterNil += 1
            return line
        }
        let composite = CompositeLineInterceptor(interceptors: [dropper, spy])
        #expect(composite.intercept(line: "anything") == nil)
        #expect(callsAfterNil == 0)
    }
    
    @Test func realWorldChainStripsCommentThenBlanks() {
        let composite = CompositeLineInterceptor(interceptors: [
            SwiftSingleLineCommentInterceptor(),
            EmptyLineInterceptor()
        ])
        #expect(composite.intercept(line: "// comment") == nil)
        #expect(composite.intercept(line: "   ") == nil)
        #expect(composite.intercept(line: "let x = 1") == "let x = 1")
    }
}
