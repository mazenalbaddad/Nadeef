//
//  File.swift
//  
//
//  Created by mazen baddad on 11/4/23.
//

import Foundation
import ArgumentParser

extension Nadeef {
    
    struct Swift: ParsableCommand {
        
        static let configuration: CommandConfiguration = CommandConfiguration(abstract: "finding unused objects in swift files", version: "0.2.0")
        
        @Argument(help: "Searching relative path, defaults to the current directory") var path: String?
        @Flag(name: .shortAndLong, help: "Show logs while running") var logs: Bool = false
        
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
        
        func run() throws {
            try NadeefProcessor(configuration: NadeefConfiguration(path: path, logs: logs, roots: roots)).process()
        }
    }
}
