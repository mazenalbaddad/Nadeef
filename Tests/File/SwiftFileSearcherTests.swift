import Testing
import Foundation
@testable import nadeef

@Suite("SwiftFileSearcher")
struct SwiftFileSearcherTests {
    
    @Test func findsOnlySwiftFilesRecursivelyExcludingPodsAndHidden() {
        let root = TempDirectory.make()
        defer { TempDirectory.cleanup(root) }
        
        TempDirectory.writeFile(path: "\(root)/a.swift", contents: "class A {}")
        TempDirectory.writeFile(path: "\(root)/b.txt", contents: "not swift")
        TempDirectory.writeFile(path: "\(root)/.hidden.swift", contents: "class Hidden {}")
        TempDirectory.writeFile(path: "\(root)/sub/c.swift", contents: "class C {}")
        TempDirectory.writeFile(path: "\(root)/Pods/skipped.swift", contents: "class Skipped {}")
        
        let searcher = SwiftFileSearcher(logger: SilentLogger())
        let files = searcher.startSearching(from: root)
        
        let names = Set(files.map { $0.name })
        #expect(names == ["a.swift", "c.swift"])
    }
    
    @Test func returnsEmptyForMissingDirectory() {
        let searcher = SwiftFileSearcher(logger: SilentLogger())
        let files = searcher.startSearching(from: "/tmp/nadeef-does-not-exist-\(UUID().uuidString)")
        #expect(files.isEmpty)
    }
    
    @Test func resolvedPathsMatchOnDisk() {
        let root = TempDirectory.make()
        defer { TempDirectory.cleanup(root) }
        
        TempDirectory.writeFile(path: "\(root)/only.swift", contents: "struct X {}")
        
        let searcher = SwiftFileSearcher(logger: SilentLogger())
        let files = searcher.startSearching(from: root)
        
        #expect(files.count == 1)
        #expect(files.first?.path == "\(root)/only.swift")
    }
}
