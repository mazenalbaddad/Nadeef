//
//  SourceLine.swift
//
//
//  Created by mazen baddad on 4/26/26.
//

import Foundation

/// A line of text after interceptors, tagged with its **1-based** line number in the source file.
struct SourceLine: Equatable, Sendable {
    var lineNumber: Int
    var text: String
}
