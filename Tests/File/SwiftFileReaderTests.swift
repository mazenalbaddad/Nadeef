import Testing
import Foundation
@testable import nadeef

@Suite("SwiftFileReader")
struct SwiftFileReaderTests {
    
    private struct PassthroughInterceptor: LineInterceptor {
        func intercept(line: String) -> String? { line }
    }
    
    @Test func readsAllLinesWithPassthroughInterceptor() throws {
        let root = TempDirectory.make()
        defer { TempDirectory.cleanup(root) }
        
        let path = "\(root)/Sample.swift"
        TempDirectory.writeFile(path: path, contents: "line1\nline2\nline3\n")
        
        let reader = SwiftFileReader(lineInterceptor: PassthroughInterceptor())
        let lines = try reader.read(file: SwiftFile(name: "Sample.swift", path: path))
        let stripped = lines.map { $0.trimmingCharacters(in: .newlines) }
        #expect(stripped == ["line1", "line2", "line3"])
    }
    
    @Test func interceptorChainFiltersLines() throws {
        let root = TempDirectory.make()
        defer { TempDirectory.cleanup(root) }
        
        let path = "\(root)/Sample.swift"
        TempDirectory.writeFile(path: path, contents: "// comment\nlet x = 1\n\n")
        
        let chain = CompositeLineInterceptor(interceptors: [
            SwiftSingleLineCommentInterceptor(),
            EmptyLineInterceptor()
        ])
        let reader = SwiftFileReader(lineInterceptor: chain)
        let lines = try reader.read(file: SwiftFile(name: "Sample.swift", path: path))
        #expect(lines.count == 1)
        #expect(lines.first?.contains("let x = 1") == true)
    }
    
    @Test func throwsWhenFileMissing() {
        let reader = SwiftFileReader(lineInterceptor: PassthroughInterceptor())
        let missing = SwiftFile(name: "missing.swift", path: "/tmp/nadeef-missing-\(UUID().uuidString).swift")
        #expect(throws: RuntimeError.self) {
            try reader.read(file: missing)
        }
    }
}
