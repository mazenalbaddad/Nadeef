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
                UnusedFinding(name: "Foo", kind: "class", paths: ["/repo/Sources/Foo.swift", "/repo/Sources/Foo+Extra.swift"]),
                UnusedFinding(name: "Bar", kind: "struct", paths: ["/repo/Sources/Bar.swift"])
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
        
        #expect(decoded["version"] as? String == "1")
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
    
    @Test func unusedEntriesUseRelativePaths() throws {
        let (result, context) = sample()
        let rendered = try JSONReporter().render(result, context: context)
        let decoded = try decode(rendered)
        let unused = decoded["unused"] as? [[String: Any]] ?? []
        
        #expect(unused.count == 2)
        #expect(unused[0]["name"] as? String == "Foo")
        #expect(unused[0]["kind"] as? String == "class")
        #expect(unused[0]["paths"] as? [String] == ["Sources/Foo.swift", "Sources/Foo+Extra.swift"])
        #expect(unused[1]["name"] as? String == "Bar")
        #expect(unused[1]["paths"] as? [String] == ["Sources/Bar.swift"])
    }
    
    @Test func entriesHaveNoLineField() throws {
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
