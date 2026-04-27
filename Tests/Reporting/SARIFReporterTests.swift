import Testing
import Foundation
@testable import Nadeef

@Suite("SARIFReporter")
struct SARIFReporterTests {
    
    private func sampleResult(paths: [String] = ["/repo/Sources/Orphan.swift"]) -> ProcessResult {
        ProcessResult(
            totalFiles: 2,
            totalObjects: 2,
            unused: [
                UnusedFinding(
                    name: "Orphan",
                    kind: "class",
                    locations: paths.map { FindingLocation(path: $0, startingLine: 0) }
                )
            ],
            remainingReferences: []
        )
    }
    
    private func decode(_ rendered: String) throws -> [String: Any] {
        let data = Data(rendered.utf8)
        return (try JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]
    }
    
    @Test func rendersSpecVersionAndSchema() throws {
        let context = ReportContext(projectRoot: "/repo")
        let rendered = try SARIFReporter().render(sampleResult(), context: context)
        let decoded = try decode(rendered)
        
        #expect(decoded["version"] as? String == "2.1.0")
        #expect(decoded["$schema"] as? String == "https://json.schemastore.org/sarif-2.1.0.json")
    }
    
    @Test func rulesIncludeUnusedObjectRule() throws {
        let context = ReportContext(projectRoot: "/repo")
        let rendered = try SARIFReporter().render(sampleResult(), context: context)
        let decoded = try decode(rendered)
        let runs = decoded["runs"] as? [[String: Any]] ?? []
        let driver = (runs.first?["tool"] as? [String: Any])?["driver"] as? [String: Any]
        let rules = driver?["rules"] as? [[String: Any]] ?? []
        
        #expect(rules.count == 1)
        #expect(rules.first?["id"] as? String == SARIFReporter.ruleID)
        #expect(rules.first?["name"] as? String == "UnusedObject")
    }
    
    @Test func resultHasRelativeUriAndNoRegion() throws {
        let context = ReportContext(projectRoot: "/repo")
        let rendered = try SARIFReporter().render(sampleResult(), context: context)
        let decoded = try decode(rendered)
        let runs = decoded["runs"] as? [[String: Any]] ?? []
        let results = runs.first?["results"] as? [[String: Any]] ?? []
        let first = results.first ?? [:]
        
        #expect(first["ruleId"] as? String == SARIFReporter.ruleID)
        #expect(first["level"] as? String == "warning")
        
        let location = (first["locations"] as? [[String: Any]])?.first ?? [:]
        let physical = location["physicalLocation"] as? [String: Any] ?? [:]
        let artifact = physical["artifactLocation"] as? [String: Any] ?? [:]
        
        #expect(artifact["uri"] as? String == "Sources/Orphan.swift")
        #expect(artifact["uriBaseId"] as? String == "SRCROOT")
        #expect(physical["region"] == nil)
    }
    
    @Test func emitsOneLocationPerCodeBlockPath() throws {
        let context = ReportContext(projectRoot: "/repo")
        let rendered = try SARIFReporter().render(sampleResult(paths: [
            "/repo/Sources/Orphan.swift",
            "/repo/Sources/Orphan+Extra.swift"
        ]), context: context)
        let decoded = try decode(rendered)
        let results = ((decoded["runs"] as? [[String: Any]])?.first?["results"] as? [[String: Any]]) ?? []
        let locations = results.first?["locations"] as? [[String: Any]] ?? []
        
        let uris = locations.compactMap {
            (($0["physicalLocation"] as? [String: Any])?["artifactLocation"] as? [String: Any])?["uri"] as? String
        }
        #expect(uris == ["Sources/Orphan.swift", "Sources/Orphan+Extra.swift"])
    }
    
    @Test func messageContainsNameAndKind() throws {
        let context = ReportContext(projectRoot: "/repo")
        let rendered = try SARIFReporter().render(sampleResult(), context: context)
        let decoded = try decode(rendered)
        let runs = decoded["runs"] as? [[String: Any]] ?? []
        let results = runs.first?["results"] as? [[String: Any]] ?? []
        let message = (results.first?["message"] as? [String: Any])?["text"] as? String ?? ""
        
        #expect(message.contains("Orphan"))
        #expect(message.contains("class"))
    }
    
    @Test func originalUriBaseIdsAnchorsSrcroot() throws {
        let context = ReportContext(projectRoot: "/repo")
        let rendered = try SARIFReporter().render(sampleResult(), context: context)
        let decoded = try decode(rendered)
        let runs = decoded["runs"] as? [[String: Any]] ?? []
        let bases = runs.first?["originalUriBaseIds"] as? [String: Any] ?? [:]
        let srcroot = bases["SRCROOT"] as? [String: Any] ?? [:]
        
        #expect((srcroot["uri"] as? String)?.hasPrefix("file://") == true)
        #expect((srcroot["uri"] as? String)?.hasSuffix("/") == true)
    }
    
    @Test func emptyFindingsProducesNoResults() throws {
        let result = ProcessResult(totalFiles: 0, totalObjects: 0, unused: [], remainingReferences: [])
        let rendered = try SARIFReporter().render(result, context: ReportContext(projectRoot: "/repo"))
        let decoded = try decode(rendered)
        let runs = decoded["runs"] as? [[String: Any]] ?? []
        let results = runs.first?["results"] as? [[String: Any]] ?? []
        #expect(results.isEmpty)
    }
}
