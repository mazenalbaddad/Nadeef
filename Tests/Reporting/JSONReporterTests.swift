import Testing
import Foundation
@testable import Nadeef

@Suite("JSONReporter")
struct JSONReporterTests {
    
    private func sample(projectRoot: String = "/repo") -> (ProcessResult, ReportContext) {
        let result = ProcessResult(
            totalFiles: 10,
            totalObjects: 5,
            unused: [
                UnusedFinding(
                    name: "Foo",
                    kind: "class",
                    locations: [
                        FindingLocation(path: "/repo/Sources/Foo.swift", startingLine: 0),
                        FindingLocation(path: "/repo/Sources/Foo+Extra.swift", startingLine: 0)
                    ]
                ),
                UnusedFinding(
                    name: "Bar",
                    kind: "struct",
                    locations: [FindingLocation(path: "/repo/Sources/Bar.swift", startingLine: 0)]
                )
            ],
            remainingReferences: []
        )
        let context = ReportContext(
            toolVersion: "0.3.0",
            projectRoot: projectRoot,
            generatedAt: Date(timeIntervalSince1970: 0)
        )
        return (result, context)
    }
    
    private func decode(_ rendered: String) throws -> [String: Any] {
        let data = Data(rendered.utf8)
        let object = try JSONSerialization.jsonObject(with: data)
        return object as? [String: Any] ?? [:]
    }
    
    @Test func emitsStableSchemaVersionAndToolMetadata() throws {
        let (result, context) = sample()
        let rendered = try JSONReporter().render(result, context: context)
        let decoded = try decode(rendered)
        
        #expect(decoded["tool"] as? String == "nadeef")
        #expect(decoded["toolVersion"] as? String == "0.3.0")
        #expect(decoded["generatedAt"] as? String == "1970-01-01T00:00:00Z")
    }
    
    @Test func summaryContainsCounts() throws {
        let (result, context) = sample()
        let rendered = try JSONReporter().render(result, context: context)
        let decoded = try decode(rendered)
        let summary = decoded["summary"] as? [String: Any] ?? [:]
        
        #expect(summary["totalFiles"] as? Int == 10)
        #expect(summary["totalObjects"] as? Int == 5)
        #expect(summary["unusedCount"] as? Int == 2)
    }
    
    @Test func unusedEntriesUseRelativePathsAndLocations() throws {
        let (result, context) = sample()
        let rendered = try JSONReporter().render(result, context: context)
        let decoded = try decode(rendered)
        let unused = decoded["unused"] as? [[String: Any]] ?? []
        
        #expect(unused.count == 2)
        #expect(unused[0]["name"] as? String == "Foo")
        #expect(unused[0]["kind"] as? String == "class")
        let fooLocs = unused[0]["locations"] as? [[String: Any]] ?? []
        #expect(fooLocs.map { $0["path"] as? String } == ["Sources/Foo.swift", "Sources/Foo+Extra.swift"])
        #expect(fooLocs.map { $0["startingLine"] as? Int } == [0, 0])
        #expect(unused[1]["name"] as? String == "Bar")
        let barLocs = unused[1]["locations"] as? [[String: Any]] ?? []
        #expect(barLocs.map { $0["path"] as? String } == ["Sources/Bar.swift"])
        #expect(barLocs.map { $0["startingLine"] as? Int } == [0])
    }
    
    @Test func entriesHaveNoTopLevelLineOrFileField() throws {
        let (result, context) = sample()
        let rendered = try JSONReporter().render(result, context: context)
        let decoded = try decode(rendered)
        let unused = decoded["unused"] as? [[String: Any]] ?? []
        
        #expect(unused.first?["line"] == nil)
        #expect(unused.first?["file"] == nil)
    }
    
    @Test func rendersEmptyUnusedArrayWhenNothingFound() throws {
        let result = ProcessResult(totalFiles: 0, totalObjects: 0, unused: [], remainingReferences: [])
        let context = ReportContext(projectRoot: "/repo", generatedAt: Date(timeIntervalSince1970: 0))
        let rendered = try JSONReporter().render(result, context: context)
        let decoded = try decode(rendered)
        
        #expect((decoded["unused"] as? [Any])?.isEmpty == true)
    }
}
