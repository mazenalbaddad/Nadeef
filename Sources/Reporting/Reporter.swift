//
//  ReportContext.swift
//  nadeef
//
//  Created by Mazen Albaddad on 21/04/2026.
//

import Foundation

protocol Reporter {
    func render(_ result: ProcessResult, context: ReportContext) throws -> String
}

struct ReportContext {
    let toolName: String
    let toolVersion: String
    let informationUri: String
    let projectRoot: String
    let generatedAt: Date
    
    init(
        toolName: String = "Nadeef",
        toolVersion: String = "1.0.0",
        informationUri: String = "https://github.com/MazenBaddad/Nadeef",
        projectRoot: String,
        generatedAt: Date = Date()
    ) {
        self.toolName = toolName
        self.toolVersion = toolVersion
        self.informationUri = informationUri
        self.projectRoot = projectRoot
        self.generatedAt = generatedAt
    }
    
    func relativePath(for absolutePath: String) -> String {
        guard !absolutePath.isEmpty else { return absolutePath }
        let root = projectRoot.hasSuffix("/") ? projectRoot : projectRoot + "/"
        if absolutePath.hasPrefix(root) {
            return String(absolutePath.dropFirst(root.count))
        }
        if absolutePath == projectRoot { return "" }
        return absolutePath
    }
}
