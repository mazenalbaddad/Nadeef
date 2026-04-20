import Testing
@testable import nadeef

@Suite("ReferenceCounter")
struct ReferenceCounterTests {
    
    private func makeObject(
        name: String,
        body: [String],
        roots: [String] = []
    ) -> SwiftObject {
        ObjectFactory.makeSwift(
            name: name,
            body: body,
            configuration: NadeefConfiguration(roots: roots)
        )
    }
    
    private func references(of name: String, in refs: [ObjectReference]) -> [String] {
        refs.first(where: { $0.object.name == name })?
            .references
            .compactMap { $0.value?.name }
            ?? []
    }
    
    @Test func recordsCrossReferencesBetweenObjects() {
        let a = makeObject(name: "A", body: ["class A { let b = B() }"])
        let b = makeObject(name: "B", body: ["class B { }"])
        
        let refs = ReferenceCounter(logger: SilentLogger()).searchReferences(for: [a, b])
        
        #expect(references(of: "B", in: refs) == ["A"])
    }
    
    @Test func ignoresSelfReferences() {
        let a = makeObject(name: "A", body: ["class A { static let shared = A() }"])
        
        let refs = ReferenceCounter(logger: SilentLogger()).searchReferences(for: [a])
        
        // A is system (no other references to it, and only one object) — but we still should not
        // add A to its own references list. Read references as the raw weak list via assertion on
        // the referenced-by side: A is not in anyone else's refs.
        let noOneReferencesA = references(of: "A", in: refs).filter { $0 == "A" }.isEmpty
        #expect(noOneReferencesA)
    }
    
    @Test func identifierBoundariesPreventSubstringMatches() {
        // "Bar" must not match "Barbell".
        let a = makeObject(name: "A", body: ["class A { let x = Barbell() }"])
        let bar = makeObject(name: "Bar", body: ["class Bar { }"])
        
        let refs = ReferenceCounter(logger: SilentLogger()).searchReferences(for: [a, bar])
        #expect(references(of: "Bar", in: refs).isEmpty)
    }
    
    @Test func systemObjectsShowSingleSystemReference() {
        let root = makeObject(name: "AppDelegate", body: ["class AppDelegate { }"], roots: ["AppDelegate"])
        let child = makeObject(name: "Child", body: ["class Child { let a = AppDelegate() }"])
        
        let refs = ReferenceCounter(logger: SilentLogger()).searchReferences(for: [root, child])
        let appDelegateRefs = refs.first(where: { $0.object.name == "AppDelegate" })
        #expect(appDelegateRefs?.references.count == 1)
        #expect(appDelegateRefs?.references.first?.value is SystemObject)
    }
    
    @Test func returnsOneReferencePerInputObject() {
        let a = makeObject(name: "A", body: ["class A { }"])
        let b = makeObject(name: "B", body: ["class B { }"])
        let c = makeObject(name: "C", body: ["class C { }"])
        
        let refs = ReferenceCounter(logger: SilentLogger()).searchReferences(for: [a, b, c])
        #expect(refs.map(\.object.name) == ["A", "B", "C"])
    }
    
    @Test func referencingNonSystemObjectRecordsEachReferrerOnce() {
        let used = makeObject(name: "Used", body: ["class Used { }"])
        let a = makeObject(name: "A", body: ["class A { let u = Used() }"])
        let b = makeObject(name: "B", body: ["class B { let u = Used() }"])
        
        let refs = ReferenceCounter(logger: SilentLogger()).searchReferences(for: [used, a, b])
        #expect(Set(references(of: "Used", in: refs)) == ["A", "B"])
    }
}
