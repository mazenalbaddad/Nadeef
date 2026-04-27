//
//  Logger.swift
//  nadeef
//
//  Created by Mazen Baddad on 21/04/2026.
//

import Foundation

enum LogLevel: Int, Comparable, CustomStringConvertible {
    case debug = 0
    case info  = 1
    case warn  = 2
    case error = 3
    case quiet = 4

    static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var description: String {
        switch self {
        case .debug: return "debug"
        case .info:  return "info"
        case .warn:  return "warn"
        case .error: return "error"
        case .quiet: return "quiet"
        }
    }

    init?(name: String) {
        switch name.lowercased() {
        case "debug":            self = .debug
        case "info":             self = .info
        case "warn", "warning":  self = .warn
        case "error":            self = .error
        case "quiet", "silent":  self = .quiet
        default: return nil
        }
    }
}

protocol Logger {
    func log(level: LogLevel, _ message: @autoclosure () -> String)
}

extension Logger {
    func log(_ message: String) { log(level: .debug, message) }
    func debug(_ message: @autoclosure () -> String) { log(level: .debug, message()) }
    func info(_ message: @autoclosure () -> String)  { log(level: .info, message())  }
    func warn(_ message: @autoclosure () -> String)  { log(level: .warn, message())  }
    func error(_ message: @autoclosure () -> String) { log(level: .error, message()) }
}

struct ConsoleLogger: Logger {

    var minLevel: LogLevel

    init(minLevel: LogLevel = .warn) {
        self.minLevel = minLevel
    }

    func log(level: LogLevel, _ message: @autoclosure () -> String) {
        guard level != .quiet, level >= minLevel else { return }
        let line = "[\(level)] \(message())\n"
        FileHandle.standardError.write(Data(line.utf8))
    }
}

struct SilentLogger: Logger {
    func log(level: LogLevel, _ message: @autoclosure () -> String) {}
}
