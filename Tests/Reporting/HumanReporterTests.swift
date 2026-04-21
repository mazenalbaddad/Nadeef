import Testing
import Foundation
@testable import Nadeef

@Suite("HumanReporter")
struct HumanReporterTests {
    
    @Test func rendersSummaryAndFindingsWithRelativePaths() {
        let result = ProcessResult(
            totalFiles: 3,
            totalObjects: 2,
            unused: [
                UnusedFinding(
                    name: "Orphan",
                    kind: "struct",
                    paths: ["/repo/Sources/Orphan.swift", "/repo/Sources/Orphan+Extra.swift"]
                )
            ],
            remainingReferences: []
        )
        let context = ReportContext(projectRoot: "/repo")
        let rendered = HumanReporter().render(result, context: context)
        
        #expect(rendered.contains("files scanned  : 3"))
        #expect(rendered.contains("objects found  : 2"))
        #expect(rendered.contains("unused objects : 1"))
        #expect(rendered.contains("- Orphan (struct)"))
        #expect(rendered.contains("Sources/Orphan.swift"))
        #expect(rendered.contains("Sources/Orphan+Extra.swift"))
    }
    
    @Test func rendersCleanMessageWhenNothingFound() {
        let result = ProcessResult(totalFiles: 0, totalObjects: 0, unused: [], remainingReferences: [])
        let rendered = HumanReporter().render(result, context: ReportContext(projectRoot: "/repo"))
        
        #expect(rendered.contains("No unused objects found."))
    }
}
