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
    private var configuration: NadeefConfiguration
    private lazy var rootMatcher = RootMatcher(roots: configuration.roots)

    var allParents: [String] {
        codeBlocks.flatMap { $0.metadata.parents }
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
    
    init() {
        super.init(name: "System", configuration: .init(logs: false, roots: []))
    }
}

class SwiftObject: Object {
    
    override var systemObject: Bool {
        return super.systemObject || codeBlocks.filter({ $0.metadata.type != "extension"}).isEmpty
    }
}
