import Testing
import Foundation
@testable import Nadeef

@Suite("SwiftPreviewCollector")
struct SwiftPreviewCollectorTests {
    
    private func makeCollector(contents: [String: [String]]) -> (SwiftPreviewCollector, [SwiftFile]) {
        let reader = FakeFileReader(contents: contents)
        let collector = SwiftPreviewCollector(fileReader: reader)
        let files = contents.keys.sorted().map { SwiftFile(name: ($0 as NSString).lastPathComponent, path: $0) }
        return (collector, files)
    }
    
    @Test func collectsSinglePreviewBlock() throws {
        let (collector, files) = makeCollector(contents: [
            "View.swift": [
                "#Preview {",
                "    Text(\"Hi\")",
                "}"
            ]
        ])
        let objects = try collector.collectObjects(from: files)
        #expect(objects.count == 1)
        let system = try #require(objects.first as? SystemObject)
        #expect(system.codeBlocks.count == 1)
        #expect(system.codeBlocks.first?.metadata.type == "#Preview")
    }
    
    @Test func collectsMultiplePreviews() throws {
        let (collector, files) = makeCollector(contents: [
            "View.swift": [
                "#Preview(\"light\") {",
                "    Text(\"A\")",
                "}",
                "#Preview(\"dark\") {",
                "    Text(\"B\")",
                "}"
            ]
        ])
        let objects = try collector.collectObjects(from: files)
        #expect(objects.first?.codeBlocks.count == 2)
    }
    
    @Test func filesWithoutPreviewsProduceNoObjects() throws {
        let (collector, files) = makeCollector(contents: [
            "View.swift": [
                "struct View {",
                "}"
            ]
        ])
        let objects = try collector.collectObjects(from: files)
        #expect(objects.isEmpty)
    }
}
