import Testing
@testable import nadeef

@Suite("Object / SwiftObject / SystemObject")
struct ObjectTests {
    
    private func makeConfig(roots: [String] = []) -> NadeefConfiguration {
        NadeefConfiguration(roots: roots)
    }
    
    @Test func allParentsCombinesMetadataAndAncestors() {
        let object = ObjectFactory.makeSwift(
            name: "Child",
            parents: ["DirectParent"],
            configuration: makeConfig()
        )
        object.ancestors = ["Grandparent"]
        #expect(object.allParents == ["DirectParent", "Grandparent"])
    }
    
    @Test func addCodeBlockAppends() {
        let object = ObjectFactory.makeSwift(name: "X", configuration: makeConfig())
        object.add(codeBlock: CodeBlockFactory.make(type: "extension", name: "X"))
        #expect(object.codeBlocks.count == 2)
    }
    
    @Test func swiftObjectIsSystemWhenOnlyExtensions() {
        let object = SwiftObject(name: "String", configuration: makeConfig())
        object.add(codeBlock: CodeBlockFactory.make(type: "extension", name: "String"))
        object.add(codeBlock: CodeBlockFactory.make(type: "extension", name: "String"))
        #expect(object.systemObject)
    }
    
    @Test func swiftObjectIsNotSystemWhenItDefinesType() {
        let object = SwiftObject(name: "MyType", configuration: makeConfig())
        object.add(codeBlock: CodeBlockFactory.make(type: "class", name: "MyType"))
        #expect(!object.systemObject)
    }
    
    @Test func swiftObjectBecomesSystemViaRootPattern() {
        let config = makeConfig(roots: ["AppDelegate"])
        let object = SwiftObject(name: "AppDelegate", configuration: config)
        object.add(codeBlock: CodeBlockFactory.make(type: "class", name: "AppDelegate"))
        #expect(object.systemObject)
    }
    
    @Test func systemObjectAlwaysReportsSystem() {
        let object = SystemObject(name: "AnyName")
        #expect(object.systemObject)
    }
    
    @Test func emptyObjectIsSystemBecauseNoNonExtensionBlocks() {
        // SwiftObject with no code blocks has no non-extension blocks -> treated as system.
        let object = SwiftObject(name: "Empty", configuration: makeConfig())
        #expect(object.systemObject)
    }
}
