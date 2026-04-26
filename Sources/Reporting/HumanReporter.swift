//
//  HumanReporter.swift
//  nadeef
//
//  Created by Mazen Albaddad on 21/04/2026.
//


import Foundation

struct HumanReporter: Reporter {
    
    func render(_ result: ProcessResult, context: ReportContext) -> String {
        var lines: [String] = []
        lines.append("Nadeef scan")
        lines.append("  files scanned  : \(result.totalFiles)")
        lines.append("  objects found  : \(result.totalObjects)")
        lines.append("  unused objects : \(result.unused.count)")
        
        if result.unused.isEmpty {
            lines.append("")
            lines.append("No unused objects found.")
        } else {
            lines.append("")
            lines.append("Unused objects:")
            for finding in result.unused {
                lines.append("  - \(finding.name) (\(finding.kind))")
                for location in finding.locations {
                    let relative = context.relativePath(for: location.path)
                    let suffix = location.startingLine > 0 ? ":\(location.startingLine)" : ""
                    lines.append("      \(relative)\(suffix)")
                }
            }
        }
        return lines.joined(separator: "\n") + "\n"
    }
}
