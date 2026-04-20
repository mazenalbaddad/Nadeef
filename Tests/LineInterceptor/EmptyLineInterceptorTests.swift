import Testing
@testable import nadeef

@Suite("EmptyLineInterceptor")
struct EmptyLineInterceptorTests {
    
    private let interceptor = EmptyLineInterceptor()
    
    @Test func emptyStringBecomesNil() {
        #expect(interceptor.intercept(line: "") == nil)
    }
    
    @Test func spacesBecomeNil() {
        #expect(interceptor.intercept(line: "     ") == nil)
    }
    
    @Test func tabsBecomeNil() {
        #expect(interceptor.intercept(line: "\t\t") == nil)
    }
    
    @Test func newlineOnlyBecomesNil() {
        #expect(interceptor.intercept(line: "\n") == nil)
    }
    
    @Test func mixedWhitespaceBecomesNil() {
        #expect(interceptor.intercept(line: " \t \n") == nil)
    }
    
    @Test func nonEmptyLineIsPreservedVerbatim() {
        #expect(interceptor.intercept(line: "  let x = 1") == "  let x = 1")
    }
}
