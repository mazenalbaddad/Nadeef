import Testing
@testable import nadeef

@Suite("RootMatcher")
struct RootMatcherTests {
    
    // MARK: - Direct parent (":Parent") patterns
    
    @Test func directParentExactMatch() {
        let matcher = RootMatcher(roots: [":XCTestCase"])
        #expect(matcher.matches(name: "BaseTest", parents: ["XCTestCase"]))
    }
    
    @Test func directParentNoMatch() {
        let matcher = RootMatcher(roots: [":XCTestCase"])
        #expect(!matcher.matches(name: "MyView", parents: ["UIView"]))
    }
    
    @Test func wildcardParentPattern() {
        let matcher = RootMatcher(roots: [":*TestCase"])
        #expect(matcher.matches(name: "BaseTest", parents: ["XCTestCase"]))
        #expect(!matcher.matches(name: "BaseTest", parents: ["UIView"]))
    }
    
    @Test func matchesWhenAncestorsAreInParents() {
        let matcher = RootMatcher(roots: [":XCTestCase"])
        #expect(matcher.matches(name: "BasePage", parents: ["BaseTest", "XCTestCase"]))
    }
    
    // MARK: - Name patterns
    
    @Test func exactNameMatch() {
        let matcher = RootMatcher(roots: ["AppDelegate"])
        #expect(matcher.matches(name: "AppDelegate", parents: []))
        #expect(!matcher.matches(name: "MyClass", parents: []))
    }
    
    @Test func prefixPattern() {
        let matcher = RootMatcher(roots: ["App*"])
        #expect(matcher.matches(name: "AppDelegate", parents: []))
        #expect(!matcher.matches(name: "MyApp", parents: []))
    }
    
    @Test func suffixPattern() {
        let matcher = RootMatcher(roots: ["*_Previews"])
        #expect(matcher.matches(name: "ContentView_Previews", parents: []))
        #expect(!matcher.matches(name: "ContentView", parents: []))
    }
    
    @Test func containsPatternMiddle() {
        let matcher = RootMatcher(roots: ["*Test*"])
        #expect(matcher.matches(name: "MyTestCase", parents: []))
        #expect(!matcher.matches(name: "MyClass", parents: []))
    }
    
    @Test func containsPatternAtBoundaries() {
        let matcher = RootMatcher(roots: ["*Foo*"])
        #expect(matcher.matches(name: "FooBar", parents: []))
        #expect(matcher.matches(name: "BarFoo", parents: []))
        #expect(matcher.matches(name: "Foo", parents: []))
    }
    
    // MARK: - Roots list semantics
    
    @Test func emptyRootsNeverMatch() {
        let matcher = RootMatcher(roots: [])
        #expect(!matcher.matches(name: "AppDelegate", parents: ["UIResponder"]))
    }
    
    @Test func multiplePatternsAnyMatches() {
        let matcher = RootMatcher(roots: ["AppDelegate", ":XCTestCase"])
        #expect(matcher.matches(name: "AppDelegate", parents: []))
        #expect(matcher.matches(name: "BaseTest", parents: ["XCTestCase"]))
        #expect(!matcher.matches(name: "MyView", parents: ["UIView"]))
    }
}
