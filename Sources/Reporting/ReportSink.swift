//
//  ReportSink.swift
//  nadeef
//
//  Created by Mazen Albaddad on 22/04/2026.
//

import Foundation

protocol ReportSink {
    func emit(_ result: ProcessResult, context: ReportContext) throws
}

struct StdoutSink: ReportSink {
    let reporter: Reporter
    
    func emit(_ result: ProcessResult, context: ReportContext) throws {
        let rendered = try reporter.render(result, context: context)
        FileHandle.standardOutput.write(Data(rendered.utf8))
    }
}

struct FileSink: ReportSink {
    let reporter: Reporter
    let path: String
    
    func emit(_ result: ProcessResult, context: ReportContext) throws {
        let rendered = try reporter.render(result, context: context)
        let url = URL(fileURLWithPath: path)
        let directory = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try rendered.write(to: url, atomically: true, encoding: .utf8)
    }
}
