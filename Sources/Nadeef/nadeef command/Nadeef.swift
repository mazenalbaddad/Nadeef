//
//  File.swift
//  
//
//  Created by mazen baddad on 11/4/23.
//

import Foundation
@preconcurrency import ArgumentParser

struct Nadeef: ParsableCommand {

    static let nadeefVersion = "1.11.0"
    
    static let configuration: CommandConfiguration = CommandConfiguration(
        abstract: "finding unused objects",
        version: nadeefVersion,
        subcommands: [Swift.self]
    )
}
