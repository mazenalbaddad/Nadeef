//
//  SARIFReporter.swift
//  nadeef
//
//  Created by Mazen Albaddad on 21/04/2026.
//

import Foundation

struct SARIFReporter: Reporter {
    
    static let ruleID = "nadeef.unused-object"
    
    func render(_ result: ProcessResult, context: ReportContext) throws -> String {
        let rule = Rule(
            id: Self.ruleID,
            name: "UnusedObject",
            shortDescription: Message(text: "Unused Swift object"),
            fullDescription: Message(text: "This Swift type (class, struct, enum, protocol, actor, or extension) appears to be defined but never referenced anywhere else in the scanned sources."),
            helpUri: context.informationUri,
            defaultConfiguration: RuleConfiguration(level: "warning")
        )
        
        let results = result.unused.map { finding -> SARIFResult in
            let locations = finding.locations.map { loc -> Location in
                let region = loc.startingLine > 0 ? Region(startLine: loc.startingLine) : nil
                return Location(physicalLocation: PhysicalLocation(
                    artifactLocation: ArtifactLocation(
                        uri: context.relativePath(for: loc.path),
                        uriBaseId: "SRCROOT"
                    ),
                    region: region
                ))
            }
            return SARIFResult(
                ruleId: Self.ruleID,
                level: "warning",
                message: Message(text: "'\(finding.name)' (\(finding.kind)) appears to be unused."),
                locations: locations
            )
        }
        
        let document = SARIFDocument(
            version: "2.1.0",
            schema: "https://json.schemastore.org/sarif-2.1.0.json",
            runs: [
                Run(
                    tool: Tool(driver: Driver(
                        name: context.toolName,
                        version: context.toolVersion,
                        informationUri: context.informationUri,
                        rules: [rule]
                    )),
                    results: results,
                    originalUriBaseIds: [
                        "SRCROOT": ArtifactLocation(
                            uri: "file://" + ensureTrailingSlash(context.projectRoot),
                            uriBaseId: nil
                        )
                    ]
                )
            ]
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        let data = try encoder.encode(document)
        return (String(data: data, encoding: .utf8) ?? "{}") + "\n"
    }
    
    private func ensureTrailingSlash(_ path: String) -> String {
        path.hasSuffix("/") ? path : path + "/"
    }
    
    // MARK: - SARIF 2.1.0 schema subset
    
    private struct SARIFDocument: Encodable {
        let version: String
        let schema: String
        let runs: [Run]
        enum CodingKeys: String, CodingKey {
            case version
            case schema = "$schema"
            case runs
        }
    }
    
    private struct Run: Encodable {
        let tool: Tool
        let results: [SARIFResult]
        let originalUriBaseIds: [String: ArtifactLocation]
    }
    
    private struct Tool: Encodable {
        let driver: Driver
    }
    
    private struct Driver: Encodable {
        let name: String
        let version: String
        let informationUri: String
        let rules: [Rule]
    }
    
    private struct Rule: Encodable {
        let id: String
        let name: String
        let shortDescription: Message
        let fullDescription: Message
        let helpUri: String
        let defaultConfiguration: RuleConfiguration
    }
    
    private struct RuleConfiguration: Encodable {
        let level: String
    }
    
    private struct SARIFResult: Encodable {
        let ruleId: String
        let level: String
        let message: Message
        let locations: [Location]
    }
    
    private struct Location: Encodable {
        let physicalLocation: PhysicalLocation
    }
    
    private struct PhysicalLocation: Encodable {
        let artifactLocation: ArtifactLocation
        let region: Region?
    }
    
    private struct Region: Encodable {
        let startLine: Int
    }
    
    private struct ArtifactLocation: Encodable {
        let uri: String
        let uriBaseId: String?
    }
    
    private struct Message: Encodable {
        let text: String
    }
}
