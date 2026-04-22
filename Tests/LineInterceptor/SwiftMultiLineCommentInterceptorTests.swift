import Testing
@testable import Nadeef

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
    
    @Test func openCommentInsideStringIsIgnored() {
        let interceptor = SwiftMultiLineCommentInterceptor()
        let line = #"let s = "/* not a comment" + x"#
        #expect(interceptor.intercept(line: line) == line)
    }
    
    @Test func closeCommentInsideStringIsIgnored() {
        let interceptor = SwiftMultiLineCommentInterceptor()
        let line = #"let s = "closing */ inside string""#
        #expect(interceptor.intercept(line: line) == line)
    }
    
    @Test func openAndCloseCommentInsideStringIsIgnored() {
        let interceptor = SwiftMultiLineCommentInterceptor()
        let line = #"let s = "/* looks like a comment */""#
        #expect(interceptor.intercept(line: line) == line)
    }
    
    @Test func realCommentAfterStringContainingCommentMarkersIsStripped() {
        let interceptor = SwiftMultiLineCommentInterceptor()
        let line = #"let s = "/* in string */" /* real */ tail"#
        #expect(interceptor.intercept(line: line) == #"let s = "/* in string */"  tail"#)
    }
    
    @Test func escapedQuoteDoesNotEndString() {
        let interceptor = SwiftMultiLineCommentInterceptor()
        let line = #"let s = "he said \"/* hi */\" loudly""#
        #expect(interceptor.intercept(line: line) == line)
    }
    
    @Test func stringDoesNotCarryStateAcrossLines() {
        let interceptor = SwiftMultiLineCommentInterceptor()
        _ = interceptor.intercept(line: #"let s = "unterminated "#)
        let next = interceptor.intercept(line: "let x = /* comment */ 1")
        #expect(next == "let x =  1")
    }
}
