//
//  Logger.swift
//  nadeef
//
//  Abstraction over process output so the pipeline can be silenced in tests.
//

import Foundation

protocol Logger {
    func log(_ message: String)
}

struct ConsoleLogger: Logger {
    func log(_ message: String) {
        print(message)
    }
}

struct SilentLogger: Logger {
    func log(_ message: String) {}
}
