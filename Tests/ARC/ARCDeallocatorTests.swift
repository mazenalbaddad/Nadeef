import Testing
@testable import Nadeef

@Suite("ARCDeallocator")
struct ARCDeallocatorTests {
    
    private func makeObject(name: String, roots: [String] = []) -> SwiftObject {
        ObjectFactory.makeSwift(
            name: name,
            body: ["class \(name) { }"],
            configuration: NadeefConfiguration(roots: roots)
        )
    }
    
    @Test func removesObjectsWithNoReferences() {
        let orphan = makeObject(name: "Orphan")
        var refs = [ObjectReference(object: orphan)]
        
        let removed = ARCDeallocator(logger: SilentLogger()).removeUnused(objects: &refs)
        
        #expect(removed.map(\.name) == ["Orphan"])
        #expect(removed.first?.kind == "class")
        #expect(removed.first?.locations == [FindingLocation(path: "test.swift", startingLine: 0)])
        #expect(refs.isEmpty)
    }
    
    @Test func keepsReferencedObjects() {
        let kept = makeObject(name: "Kept")
        let keptRef = ObjectReference(object: kept)
        keptRef.add(reference: makeObject(name: "Holder"))
        var refs = [keptRef]
        
        let removed = ARCDeallocator(logger: SilentLogger()).removeUnused(objects: &refs)
        
        #expect(removed.isEmpty)
        #expect(refs.count == 1)
    }
    
    @Test func neverRemovesSystemObjects() {
        let root = makeObject(name: "AppDelegate", roots: ["AppDelegate"])
        var refs = [ObjectReference(object: root)]
        
        let removed = ARCDeallocator(logger: SilentLogger()).removeUnused(objects: &refs)
        
        #expect(removed.isEmpty)
        #expect(refs.count == 1)
    }
    
    @Test func cascadesRemovalWhenReferrerBecomesUnused() {
        // A is referenced only by B; B is referenced by nothing. Scope B locally so the only
        // strong owner is its ObjectReference — once B's ObjectReference is removed, the
        // weak reference from A drops and A becomes unused on the next iteration.
        let a = makeObject(name: "A")
        let aRef = ObjectReference(object: a)
        var refs: [ObjectReference] = [aRef]
        do {
            let b = makeObject(name: "B")
            aRef.add(reference: b)
            refs.append(ObjectReference(object: b))
        }
        
        let removed = ARCDeallocator(logger: SilentLogger()).removeUnused(objects: &refs)
        
        #expect(Set(removed.map(\.name)) == ["A", "B"])
        #expect(refs.isEmpty)
    }
    
    @Test func returnsEmptyForEmptyInput() {
        var refs: [ObjectReference] = []
        let removed = ARCDeallocator(logger: SilentLogger()).removeUnused(objects: &refs)
        #expect(removed.isEmpty)
    }
    
    @Test func findingCarriesAllDistinctCodeBlockPaths() {
        let object = ObjectFactory.makeSwift(
            name: "Orphan",
            type: "class",
            body: ["class Orphan { }"],
            configuration: NadeefConfiguration(roots: [])
        )
        object.codeBlocks[0].metadata.filePath = "Sources/Foo.swift"
        object.add(codeBlock: CodeBlockFactory.make(
            type: "extension",
            name: "Orphan",
            filePath: "Sources/Foo+Extra.swift",
            lines: ["extension Orphan { }"]
        ))
        // Duplicate path should be de-duplicated, preserving first-seen order.
        object.add(codeBlock: CodeBlockFactory.make(
            type: "extension",
            name: "Orphan",
            filePath: "Sources/Foo.swift",
            lines: ["extension Orphan { }"]
        ))
        var refs = [ObjectReference(object: object)]
        
        let removed = ARCDeallocator(logger: SilentLogger()).removeUnused(objects: &refs)
        
        #expect(removed == [UnusedFinding(
            name: "Orphan",
            kind: "class",
            locations: [
                FindingLocation(path: "Sources/Foo.swift", startingLine: 0),
                FindingLocation(path: "Sources/Foo+Extra.swift", startingLine: 0)
            ]
        )])
    }
    
    @Test func findingKindPrefersNonExtensionBlock() {
        let object = ObjectFactory.makeSwift(
            name: "Helper",
            type: "extension",
            body: ["extension Helper { }"],
            configuration: NadeefConfiguration(roots: [])
        )
        object.codeBlocks[0].metadata.filePath = "Ext.swift"
        object.add(codeBlock: CodeBlockFactory.make(
            type: "struct",
            name: "Helper",
            filePath: "Def.swift",
            lines: ["struct Helper { }"]
        ))
        var refs = [ObjectReference(object: object)]
        
        let removed = ARCDeallocator(logger: SilentLogger()).removeUnused(objects: &refs)
        
        #expect(removed.first?.kind == "struct")
        #expect(removed.first?.locations == [
            FindingLocation(path: "Ext.swift", startingLine: 0),
            FindingLocation(path: "Def.swift", startingLine: 0)
        ])
    }
}
