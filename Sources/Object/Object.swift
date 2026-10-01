//
//  File 2.swift
//  
//
//  Created by Mazen Baddad on 30/08/2023.
//

import Foundation

class Object {
    var name: String
    var codeBlocks: Array<CodeBlock> = []
    var ancestors: [String] = []
    private var configuration: NadeefConfiguration
    private lazy var rootMatcher = RootMatcher(roots: configuration.roots)

    var allParents: [String] {
        codeBlocks.flatMap { $0.metadata.parents } + ancestors
    }
    
    var systemObject: Bool {
        return rootMatcher.matches(name: name, parents: allParents)
    }
    
    init(name: String, configuration: NadeefConfiguration) {
        self.name = name
        self.configuration = configuration
    }
    
    func add(codeBlock: CodeBlock) {
        self.codeBlocks.append(codeBlock)
    }
}

class SystemObject: Object {
    
    override var systemObject: Bool {
        return true
    }
    
    init(name: String = "System") {
        super.init(name: name, configuration: .init(roots: []))
    }
}

class SwiftObject: Object {
    
    private static let swiftTestingAttributeRegex = try! NSRegularExpression(pattern: #"^\s*@(Test|Suite)\b"#)
    /// Caches `isSwiftTestingSuite`, since `systemObject` is read on every ARC pass; cleared when a code block is added.
    private var cachedIsSwiftTestingSuite: Bool?
    
    override var systemObject: Bool {
        return super.systemObject || codeBlocks.filter({ $0.metadata.type != "extension"}).isEmpty || isSwiftTestingSuite
    }
    
    override func add(codeBlock: CodeBlock) {
        super.add(codeBlock: codeBlock)
        cachedIsSwiftTestingSuite = nil
    }
    
    /// Swift Testing discovers `@Suite`/`@Test` types through macros, so nothing references them in source.
    private var isSwiftTestingSuite: Bool {
        if let cached = cachedIsSwiftTestingSuite {
            return cached
        }
        let result = codeBlocks.contains { block in
            block.lines.contains { line in
                Self.swiftTestingAttributeRegex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) != nil
            }
        }
        cachedIsSwiftTestingSuite = result
        return result
    }
}
