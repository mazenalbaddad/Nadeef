import Testing
import Foundation
@testable import Nadeef

@Suite("NadeefProcessor (integration)")
struct NadeefProcessorTests {
    
    @Test func endToEndFindsOrphanAndKeepsReferencedAndRoot() throws {
        let root = TempDirectory.make()
        defer { TempDirectory.cleanup(root) }
        
        TempDirectory.writeFile(
            path: "\(root)/AppDelegate.swift",
            contents: """
            class AppDelegate {
                let helper = Helper()
            }
            """
        )
        TempDirectory.writeFile(
            path: "\(root)/Helper.swift",
            contents: """
            class Helper {
            }
            """
        )
        TempDirectory.writeFile(
            path: "\(root)/Orphan.swift",
            contents: """
            class Orphan {
            }
            """
        )
        
        let configuration = NadeefConfiguration(path: root, roots: ["AppDelegate"])
        let processor = NadeefProcessor(configuration: configuration, logger: SilentLogger())
        let result = try processor.process()
        
        #expect(result.totalFiles == 3)
        #expect(result.unusedObjectNames.contains("Orphan"))
        #expect(!result.unusedObjectNames.contains("Helper"))
        #expect(!result.unusedObjectNames.contains("AppDelegate"))
    }
    
    @Test func roguePatternsAreHonored() throws {
        let root = TempDirectory.make()
        defer { TempDirectory.cleanup(root) }
        
        TempDirectory.writeFile(
            path: "\(root)/ContentView_Previews.swift",
            contents: """
            class ContentView_Previews {
            }
            """
        )
        
        let configuration = NadeefConfiguration(path: root, roots: ["*_Previews"])
        let processor = NadeefProcessor(configuration: configuration, logger: SilentLogger())
        let result = try processor.process()
        
        #expect(!result.unusedObjectNames.contains("ContentView_Previews"))
    }
    
    @Test func threadsLoggerMessagesForObservability() throws {
        let root = TempDirectory.make()
        defer { TempDirectory.cleanup(root) }
        
        TempDirectory.writeFile(
            path: "\(root)/Orphan.swift",
            contents: "class Orphan { }"
        )
        
        let logger = RecordingLogger()
        let configuration = NadeefConfiguration(path: root, roots: [])
        let processor = NadeefProcessor(configuration: configuration, logger: logger)
        _ = try processor.process()
        
        #expect(logger.messages.contains(where: { $0.contains("total files count") }))
        #expect(logger.messages.contains(where: { $0.contains("Orphan is unused") }))
    }
}
