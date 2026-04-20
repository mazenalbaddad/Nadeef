import Testing
@testable import nadeef

@Suite("SwiftSingleLineCommentInterceptor")
struct SwiftSingleLineCommentInterceptorTests {
    
    private let interceptor = SwiftSingleLineCommentInterceptor()
    
    @Test func fullLineCommentBecomesNil() {
        #expect(interceptor.intercept(line: "// a comment") == nil)
    }
    
    @Test func leadingWhitespaceBeforeCommentBecomesNil() {
        #expect(interceptor.intercept(line: "    // indented comment") == nil)
    }
    
    @Test func codeLineIsPreserved() {
        #expect(interceptor.intercept(line: "let x = 1") == "let x = 1")
    }
    
    @Test func trailingCommentIsPreservedBecausePrefixCheckOnly() {
        // Documents current behavior: only pure-prefix comments are stripped.
        #expect(interceptor.intercept(line: "let x = 1 // note") == "let x = 1 // note")
    }
    
    @Test func emptyLineIsPreserved() {
        #expect(interceptor.intercept(line: "") == "")
    }
}
