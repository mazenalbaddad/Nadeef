import Foundation
@testable import nadeef

/// In-memory file reader driven by a `path -> lines` dictionary.
final class FakeFileReader: FileReader {
    
    private var contents: [String: [String]]
    private(set) var reads: [String] = []
    
    init(contents: [String: [String]] = [:]) {
        self.contents = contents
    }
    
    func stub(path: String, lines: [String]) {
        contents[path] = lines
    }
    
    func read(file: File) throws -> [String] {
        reads.append(file.path)
        guard let lines = contents[file.path] else {
            throw RuntimeError("no stub for \(file.path)")
        }
        return lines
    }
}

/// In-memory logger that records every message.
final class RecordingLogger: Logger {
    
    private(set) var messages: [String] = []
    
    func log(_ message: String) {
        messages.append(message)
    }
}

enum TempDirectory {
    
    /// Creates a unique temporary directory and returns its path.
    /// Use `cleanup` to remove it.
    static func make(function: String = #function) -> String {
        let base = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let name = "nadeef-tests-\(sanitize(function))-\(UUID().uuidString)"
        let url = base.appendingPathComponent(name, isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url.path
    }
    
    static func cleanup(_ path: String) {
        try? FileManager.default.removeItem(atPath: path)
    }
    
    static func writeFile(path: String, contents: String) {
        let url = URL(fileURLWithPath: path)
        try? FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try? contents.write(to: url, atomically: true, encoding: .utf8)
    }
    
    static func makeSubdirectory(at path: String) {
        try? FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
    }
    
    private static func sanitize(_ name: String) -> String {
        name.replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .replacingOccurrences(of: " ", with: "_")
    }
}

enum CodeBlockFactory {
    
    static func make(
        type: String = "class",
        name: String,
        parents: [String] = [],
        filePath: String = "test.swift",
        lines: [String] = []
    ) -> CodeBlock {
        let metadata = CodeBlockMetadata(type: type, name: name, parents: parents, filePath: filePath)
        let block = CodeBlock(metadata: metadata)
        for line in lines {
            block.addLine(line)
        }
        return block
    }
}

enum ObjectFactory {
    
    static func makeSwift(
        name: String,
        parents: [String] = [],
        type: String = "class",
        body: [String]? = nil,
        configuration: NadeefConfiguration = NadeefConfiguration(roots: [])
    ) -> SwiftObject {
        let object = SwiftObject(name: name, configuration: configuration)
        let lines = body ?? ["\(type) \(name) { }"]
        object.add(codeBlock: CodeBlockFactory.make(type: type, name: name, parents: parents, lines: lines))
        return object
    }
}
