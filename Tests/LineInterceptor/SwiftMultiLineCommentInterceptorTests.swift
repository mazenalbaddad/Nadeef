import Testing
@testable import nadeef

@Suite("SwiftMultiLineCommentInterceptor")
struct SwiftMultiLineCommentInterceptorTests {
    
    @Test func lineWithoutCommentIsPreserved() {
        let interceptor = SwiftMultiLineCommentInterceptor()
        #expect(interceptor.intercept(line: "let x = 1") == "let x = 1")
    }
    
    @Test func singleLineCommentIsStripped() {
        let interceptor = SwiftMultiLineCommentInterceptor()
        #expect(interceptor.intercept(line: "let x = /* comment */ 1") == "let x =  1")
    }
    
    @Test func multipleSingleLineCommentsAreStripped() {
        let interceptor = SwiftMultiLineCommentInterceptor()
        #expect(interceptor.intercept(line: "a /* x */ b /* y */ c") == "a  b  c")
    }
    
    @Test func openCommentCarriesStateToNextLine() {
        let interceptor = SwiftMultiLineCommentInterceptor()
        let first = interceptor.intercept(line: "keep /* start")
        let middle = interceptor.intercept(line: "inside comment")
        let last = interceptor.intercept(line: "end */ tail")
        
        #expect(first == "keep ")
        #expect(middle == "")
        #expect(last == " tail")
    }
    
    @Test func contentAfterCommentOnSameLineIsPreserved() {
        let interceptor = SwiftMultiLineCommentInterceptor()
        #expect(interceptor.intercept(line: "/* start */ real code") == " real code")
    }
    
    @Test func stateResetsAfterCloseOnSameLine() {
        let interceptor = SwiftMultiLineCommentInterceptor()
        _ = interceptor.intercept(line: "/* start")
        _ = interceptor.intercept(line: "still inside */")
        let afterClose = interceptor.intercept(line: "now normal")
        #expect(afterClose == "now normal")
    }
}
