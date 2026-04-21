import Testing
import Foundation
@testable import Nadeef

@Suite("SwiftObjectCollector")
struct SwiftObjectCollectorTests {
    
    private func makeCollector(contents: [String: [String]]) -> (SwiftObjectCollector, [SwiftFile]) {
        let reader = FakeFileReader(contents: contents)
        let collector = SwiftObjectCollector(
            fileReader: reader,
            configuration: NadeefConfiguration(roots: [])
        )
        let files = contents.keys.sorted().map { SwiftFile(name: ($0 as NSString).lastPathComponent, path: $0) }
        return (collector, files)
    }
    
    // MARK: - Type detection
    
    @Test func detectsClass() throws {
        let (collector, files) = makeCollector(contents: [
            "A.swift": ["class A {", "}"]
        ])
        let objects = try collector.collectObjects(from: files)
        #expect(objects.count == 1)
        #expect(objects.first?.name == "A")
        #expect(objects.first?.codeBlocks.first?.metadata.type == "class")
    }
    
    @Test func detectsStructActorProtocolEnumExtension() throws {
        let (collector, files) = makeCollector(contents: [
            "S.swift": ["struct S {", "}"],
            "A.swift": ["actor A {", "}"],
            "P.swift": ["protocol P {", "}"],
            "E.swift": ["enum E {", "}"],
            "X.swift": ["extension X {", "}"]
        ])
        let objects = try collector.collectObjects(from: files)
        let typesByName = Dictionary(
            uniqueKeysWithValues: objects.map { ($0.name, $0.codeBlocks.first?.metadata.type ?? "") }
        )
        #expect(typesByName == ["S": "struct", "A": "actor", "P": "protocol", "E": "enum", "X": "extension"])
    }
    
    @Test func ignoresClassFuncDeclaration() throws {
        // `class func` is a type method, not a type declaration.
        let (collector, files) = makeCollector(contents: [
            "A.swift": [
                "class Real {",
                "    class func factory() -> Real { Real() }",
                "}"
            ]
        ])
        let objects = try collector.collectObjects(from: files)
        #expect(objects.count == 1)
        #expect(objects.first?.name == "Real")
    }
    
    // MARK: - Inheritance parsing
    
    @Test func parsesMultipleParents() throws {
        let (collector, files) = makeCollector(contents: [
            "A.swift": ["class A: B, C, D {", "}"]
        ])
        let objects = try collector.collectObjects(from: files)
        let parents = objects.first?.codeBlocks.first?.metadata.parents ?? []
        #expect(parents == ["B", "C", "D"])
    }
    
    @Test func stripsGenericsBeforeParsingParents() throws {
        let (collector, files) = makeCollector(contents: [
            "Box.swift": ["class Box<T: Codable>: Holder<T> {", "}"]
        ])
        let objects = try collector.collectObjects(from: files)
        let parents = objects.first?.codeBlocks.first?.metadata.parents ?? []
        #expect(parents == ["Holder"])
        #expect(objects.first?.name == "Box")
    }
    
    @Test func noInheritanceYieldsEmptyParents() throws {
        let (collector, files) = makeCollector(contents: [
            "A.swift": ["class A {", "}"]
        ])
        let objects = try collector.collectObjects(from: files)
        #expect(objects.first?.codeBlocks.first?.metadata.parents == [])
    }
    
    // MARK: - Multi-file aggregation
    
    @Test func mergesBlocksWithSameNameAcrossFiles() throws {
        let (collector, files) = makeCollector(contents: [
            "A.swift": ["class Foo {", "}"],
            "B.swift": ["extension Foo {", "}"]
        ])
        let objects = try collector.collectObjects(from: files)
        #expect(objects.count == 1)
        #expect(objects.first?.codeBlocks.count == 2)
    }
    
    // MARK: - Ancestor resolution
    
    @Test func resolveAncestorsTwoLevels() throws {
        let (collector, files) = makeCollector(contents: [
            "A.swift": ["class A: Root {", "}"],
            "B.swift": ["class B: A {", "}"]
        ])
        let objects = try collector.collectObjects(from: files)
        let b = objects.first(where: { $0.name == "B" })
        #expect(b?.ancestors.contains("Root") == true)
    }
    
    @Test func resolveAncestorsThreeLevels() throws {
        let (collector, files) = makeCollector(contents: [
            "A.swift": ["class A: Root {", "}"],
            "B.swift": ["class B: A {", "}"],
            "C.swift": ["class C: B {", "}"]
        ])
        let objects = try collector.collectObjects(from: files)
        let c = objects.first(where: { $0.name == "C" })
        #expect(c?.ancestors.contains("Root") == true)
        #expect(c?.ancestors.contains("A") == true)
    }
    
    @Test func resolveAncestorsHandlesCycles() throws {
        let (collector, files) = makeCollector(contents: [
            "A.swift": ["class A: B {", "}"],
            "B.swift": ["class B: A {", "}"]
        ])
        // Must terminate and not infinite loop.
        let objects = try collector.collectObjects(from: files)
        #expect(objects.count == 2)
    }
    
    // MARK: - Error handling
    
    @Test func throwsOnUnbalancedBraces() {
        let (collector, files) = makeCollector(contents: [
            "Bad.swift": ["class Bad {"]
        ])
        #expect(throws: RuntimeError.self) {
            try collector.collectObjects(from: files)
        }
    }
    
    @Test func emptyFileProducesNoObjects() throws {
        let (collector, files) = makeCollector(contents: [
            "Empty.swift": []
        ])
        let objects = try collector.collectObjects(from: files)
        #expect(objects.isEmpty)
    }
}
