import Testing
@testable import nadeef

@Suite("ObjectReference")
struct ObjectReferenceTests {
    
    private func makeConfig(roots: [String] = []) -> NadeefConfiguration {
        NadeefConfiguration(roots: roots)
    }
    
    @Test func nonSystemObjectExposesAddedReferences() {
        let target = ObjectFactory.makeSwift(name: "Target", body: ["class Target { } extension Target { }"], configuration: makeConfig())
        // Ensure target is not flagged as system (it has a non-extension block).
        let ref = ObjectReference(object: target)
        
        let a = ObjectFactory.makeSwift(name: "A", configuration: makeConfig())
        let b = ObjectFactory.makeSwift(name: "B", configuration: makeConfig())
        ref.add(reference: a)
        ref.add(reference: b)
        
        let names = ref.references.compactMap { $0.value?.name }
        #expect(Set(names) == ["A", "B"])
    }
    
    @Test func systemObjectReferencesAreReplacedWithSystemObject() {
        let config = makeConfig(roots: ["AppDelegate"])
        let appDelegate = ObjectFactory.makeSwift(name: "AppDelegate", configuration: config)
        let ref = ObjectReference(object: appDelegate)
        
        ref.add(reference: ObjectFactory.makeSwift(name: "Ignored", configuration: config))
        
        #expect(ref.references.count == 1)
        #expect(ref.references.first?.value is SystemObject)
    }
    
    @Test func clearReferencesDropsDeallocatedWeakBoxes() {
        let config = makeConfig()
        let target = ObjectFactory.makeSwift(name: "Target", configuration: config)
        let ref = ObjectReference(object: target)
        let survivor = ObjectFactory.makeSwift(name: "Survivor", configuration: config)
        
        do {
            let transient = ObjectFactory.makeSwift(name: "Transient", configuration: config)
            ref.add(reference: transient)
            ref.add(reference: survivor)
            #expect(ref.references.count == 2)
        }
        
        ref.clearReferences()
        let remaining = ref.references.compactMap { $0.value?.name }
        #expect(remaining == ["Survivor"])
    }
}
