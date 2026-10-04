import Testing
import Foundation
@testable import Nadeef

@Suite("SwiftGlobalLineCollector")
struct SwiftGlobalLineCollectorTests {
    
    private func makeCollector(contents: [String: [String]]) -> (SwiftGlobalLineCollector, [SwiftFile]) {
        let reader = FakeFileReader(contents: contents)
        let collector = SwiftGlobalLineCollector(fileReader: reader)
        let files = contents.keys.sorted().map { SwiftFile(name: ($0 as NSString).lastPathComponent, path: $0) }
        return (collector, files)
    }
    
    @Test func collectsTopLevelLines() throws {
        let (collector, files) = makeCollector(contents: [
            "F.swift": [
                "import Foundation",
                "let x = 1",
                "class A {",
                "    let y = 2",
                "}",
                "let z = 3"
            ]
        ])
        let objects = try collector.collectObjects(from: files)
        let lines = objects.first?.codeBlocks.first?.lines ?? []
        #expect(lines == ["import Foundation", "let x = 1", "let z = 3"])
    }
    
    @Test func ignoresBracesInsideStrings() throws {
        let (collector, files) = makeCollector(contents: [
            "F.swift": [
                "let s = \"{{{\"",
                "let t = \"}}}\""
            ]
        ])
        let objects = try collector.collectObjects(from: files)
        let lines = objects.first?.codeBlocks.first?.lines ?? []
        #expect(lines.count == 2)
    }
    
    @Test func returnsEmptyWhenNoGlobalLines() throws {
        let (collector, files) = makeCollector(contents: [
            "F.swift": [
                "class A {",
                "    let x = 1",
                "}"
            ]
        ])
        let objects = try collector.collectObjects(from: files)
        #expect(objects.isEmpty)
    }
    
    @Test func tracksNestedBraceDepth() throws {
        let (collector, files) = makeCollector(contents: [
            "F.swift": [
                "class A {",
                "    func f() {",
                "        let x = 1",
                "    }",
                "}",
                "let afterType = 1"
            ]
        ])
        let objects = try collector.collectObjects(from: files)
        let lines = objects.first?.codeBlocks.first?.lines ?? []
        #expect(lines == ["let afterType = 1"])
    }
    
    @Test func collectsFreeFunctionBodies() throws {
        let (collector, files) = makeCollector(contents: [
            "F.swift": [
                "func payload(_ model: Encodable) -> Data? {",
                "    try? JSONEncoder().encode(EncodableBox(model))",
                "}",
                "struct EncodableBox: Encodable {",
                "    let value: Encodable",
                "}"
            ]
        ])
        let objects = try collector.collectObjects(from: files)
        let lines = objects.first?.codeBlocks.first?.lines ?? []
        #expect(lines == [
            "func payload(_ model: Encodable) -> Data? {",
            "    try? JSONEncoder().encode(EncodableBox(model))",
            "}"
        ])
    }

    @Test func collectsSingleLineGlobalClosures() throws {
        let (collector, files) = makeCollector(contents: [
            "F.swift": ["let make = { Factory() }"]
        ])
        let objects = try collector.collectObjects(from: files)
        let lines = objects.first?.codeBlocks.first?.lines ?? []
        #expect(lines == ["let make = { Factory() }"])
    }

    @Test func skipsTypeWithMultiLineHeader() throws {
        let (collector, files) = makeCollector(contents: [
            "F.swift": [
                "struct A:",
                "    Equatable,",
                "    Hashable {",
                "    let x = 1",
                "}",
                "let afterType = 1"
            ]
        ])
        let objects = try collector.collectObjects(from: files)
        let lines = objects.first?.codeBlocks.first?.lines ?? []
        #expect(lines == ["let afterType = 1"])
    }

    @Test func skipsSingleLineTypesAndExtensions() throws {
        let (collector, files) = makeCollector(contents: [
            "F.swift": [
                "struct Empty {}",
                "extension Empty { func f() {} }",
                "let afterTypes = 1"
            ]
        ])
        let objects = try collector.collectObjects(from: files)
        let lines = objects.first?.codeBlocks.first?.lines ?? []
        #expect(lines == ["let afterTypes = 1"])
    }

    @Test func systemObjectWrapsGlobalLines() throws {
        let (collector, files) = makeCollector(contents: [
            "F.swift": ["let x = 1"]
        ])
        let objects = try collector.collectObjects(from: files)
        #expect(objects.first is SystemObject)
        #expect(objects.first?.name == "GlobalScope")
    }
}
