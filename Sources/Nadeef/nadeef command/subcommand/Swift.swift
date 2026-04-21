//
//  Swift.swift
//
//  Created by mazen baddad on 11/4/23.
//

import Foundation
import ArgumentParser

extension Nadeef {
    
    struct Swift: ParsableCommand {
        
        private static var toolVersion: String = "1.0.0"
        
        static let configuration: CommandConfiguration = CommandConfiguration(
            abstract: "Find unused objects in Swift files.",
            version: toolVersion
        )
        
        enum Format: String, ExpressibleByArgument, CaseIterable {
            case human, json, sarif
        }
        
        @Argument(help: "Search path, defaults to the current directory.")
        var path: String?
        
        @Option(help: """
            Specify root objects that should not be marked as unused.
            Supports patterns:
              "Name"         exact match
              "pre*"         starts with "pre"
              "*suffix"      ends with "suffix"
              "*text*"       contains "text"
              ":Parent"      inherits from or conforms to "Parent"
              ":*Parent"     inherits from or conforms to any type ending with "Parent"
              ... And so on
            Example: --roots AppDelegate --roots ":XCTestCase" --roots "*_Previews"
            """)
        var roots: [String] = []
        
        @Option(name: .long, help: "Output format for stdout: human | json | sarif. Default: human.")
        var format: Format = .human
        
        @Option(name: .long, help: "Also write a JSON report to this path.")
        var outputJson: String?
        
        @Option(name: .long, help: "Also write a SARIF 2.1.0 report to this path.")
        var outputSarif: String?
        
        @Option(name: .long, help: "Project root used to make file paths relative in JSON/SARIF output. Defaults to the search path.")
        var projectRoot: String?
        
        @Option(name: .long, help: "Log level for stderr: debug | info | warn | error | quiet. Default: warn.")
        var logLevel: String = "info"
        
        @Flag(name: .long, help: "Exit with status 1 when unused objects are found (useful for CI gating).")
        var failOnFindings: Bool = false
        
        func run() throws {
            guard let parsedLevel = LogLevel(name: logLevel) else {
                throw ValidationError("--log-level must be one of: debug, info, warn, error, quiet")
            }
            let logger = ConsoleLogger(minLevel: parsedLevel)
            
            do {
                let configuration = NadeefConfiguration(path: path, roots: roots)
                let processor = NadeefProcessor(configuration: configuration, logger: logger)
                let result = try processor.process()
                
                let resolvedProjectRoot = projectRoot
                    ?? path
                    ?? FileManager.default.currentDirectoryPath
                let context = ReportContext(toolVersion: Self.toolVersion, projectRoot: resolvedProjectRoot)
                
                try emitStdout(result: result, context: context)
                try emitSideOutputs(result: result, context: context)
                
                if failOnFindings && !result.unused.isEmpty {
                    logger.error("\(result.unused.count) unused object(s) found; failing as requested by --fail-on-findings.")
                    throw ExitCode(1)
                }
            } catch let error as ExitCode {
                throw error
            } catch let error as ValidationError {
                throw error
            } catch {
                logger.error("\(error)")
                throw ExitCode(2)
            }
        }
        
        private func emitStdout(result: ProcessResult, context: ReportContext) throws {
            let reporter: Reporter
            switch format {
            case .human: reporter = HumanReporter()
            case .json:  reporter = JSONReporter()
            case .sarif: reporter = SARIFReporter()
            }
            let rendered = try reporter.render(result, context: context)
            FileHandle.standardOutput.write(Data(rendered.utf8))
        }
        
        private func emitSideOutputs(result: ProcessResult, context: ReportContext) throws {
            if let path = outputJson {
                let rendered = try JSONReporter().render(result, context: context)
                try write(rendered, to: path)
            }
            if let path = outputSarif {
                let rendered = try SARIFReporter().render(result, context: context)
                try write(rendered, to: path)
            }
        }
        
        private func write(_ contents: String, to path: String) throws {
            let url = URL(fileURLWithPath: path)
            let directory = url.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try contents.write(to: url, atomically: true, encoding: .utf8)
        }
    }
}
