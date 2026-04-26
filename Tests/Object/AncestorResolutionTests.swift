import Testing
@testable import Nadeef

@Suite("Ancestor resolution")
struct AncestorResolutionTests {
    
    private func makeObject(name: String, parents: [String]) -> SwiftObject {
        let config = NadeefConfiguration(roots: [":XCTestCase"])
        let object = SwiftObject(name: name, configuration: config)
        let metadata = CodeBlockMetadata(type: "class", name: name, parents: parents, filePath: "test.swift", startingLine: 0)
        let block = CodeBlock(metadata: metadata)
        block.addLine("class \(name) { }")
        object.add(codeBlock: block)
        return object
    }
    
    @Test func directParentIsRoot() {
        let object = makeObject(name: "BaseTest", parents: ["XCTestCase"])
        #expect(object.systemObject)
    }
    
    @Test func transitiveTwoLevels() {
        let baseTest = makeObject(name: "BaseTest", parents: ["XCTestCase"])
        let basePage = makeObject(name: "BasePage", parents: ["BaseTest"])
        basePage.ancestors = baseTest.codeBlocks.flatMap { $0.metadata.parents }
        #expect(basePage.systemObject, "BasePage should be root via BaseTest -> XCTestCase")
    }
    
    @Test func transitiveThreeLevels() {
        let a = makeObject(name: "A", parents: ["XCTestCase"])
        let b = makeObject(name: "B", parents: ["A"])
        let c = makeObject(name: "C", parents: ["B"])
        b.ancestors = a.codeBlocks.flatMap { $0.metadata.parents }
        c.ancestors = b.codeBlocks.flatMap { $0.metadata.parents } + b.ancestors
        #expect(c.systemObject, "C should be root via B -> A -> XCTestCase")
    }
    
    @Test func noFalsePositiveForUnrelatedParent() {
        let object = makeObject(name: "MyView", parents: ["UIView"])
        #expect(!object.systemObject)
    }
    
    @Test func unrelatedObjectNotAffected() {
        _ = makeObject(name: "BaseTest", parents: ["XCTestCase"])
        let myView = makeObject(name: "MyView", parents: ["UIView"])
        myView.ancestors = []
        #expect(!myView.systemObject)
    }
    
    @Test func emptyAncestorsDefaultBehavior() {
        let object = makeObject(name: "BasePage", parents: ["BaseTest"])
        #expect(!object.systemObject, "Without ancestors set, only direct parents are checked")
    }
}
