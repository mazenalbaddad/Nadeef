//
//  JSONReporter.swift
//  nadeef
//
//  Created by Mazen Albaddad on 21/04/2026.
//

import Foundation

struct JSONReporter: Reporter {
    
    func render(_ result: ProcessResult, context: ReportContext) throws -> String {
        let payload = Payload(
            tool: context.toolName.lowercased(),
            toolVersion: context.toolVersion,
            generatedAt: ISO8601DateFormatter.nadeef.string(from: context.generatedAt),
            summary: Summary(
                totalFiles: result.totalFiles,
                totalObjects: result.totalObjects,
                unusedCount: result.unused.count
            ),
            unused: result.unused.map { finding in
                UnusedEntry(
                    name: finding.name,
                    kind: finding.kind,
                    locations: finding.locations.map {
                        LocationEntry(
                            path: context.relativePath(for: $0.path),
                            startingLine: $0.startingLine
                        )
                    }
                )
            }
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        let data = try encoder.encode(payload)
        return (String(data: data, encoding: .utf8) ?? "{}") + "\n"
    }
    
    private struct Payload: Encodable {
        let tool: String
        let toolVersion: String
        let generatedAt: String
        let summary: Summary
        let unused: [UnusedEntry]
    }
    
    private struct Summary: Encodable {
        let totalFiles: Int
        let totalObjects: Int
        let unusedCount: Int
    }
    
    private struct UnusedEntry: Encodable {
        let name: String
        let kind: String
        let locations: [LocationEntry]
    }
    
    private struct LocationEntry: Encodable {
        let path: String
        let startingLine: Int
    }
}

private extension ISO8601DateFormatter {
    static let nadeef: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}
