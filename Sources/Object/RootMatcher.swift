//
//  RootMatcher.swift
//  nadeef
//
//  Created by Mazen Albaddad on 12/28/2025.
//

import Foundation

/// Matches object names against root patterns
/// Supported patterns:
/// - "Name" → exact match
/// - "pre*" → starts with "pre"
/// - "*suffix" → ends with "suffix"
/// - "*text*" → contains "text"
/// - ":Parent" → inherits from or conforms to "Parent"
/// - ":*Parent" → inherits from or conforms to any type ending with "Parent"
struct RootMatcher {
    
    private let roots: [String]
    
    init(roots: [String]) {
        self.roots = roots
    }
    
    func matches(name: String, parents: [String]) -> Bool {
        for root in roots {
            if matchesPattern(root, name: name, parents: parents) {
                return true
            }
        }
        return false
    }
    
    private func matchesPattern(_ pattern: String, name: String, parents: [String]) -> Bool {
        if pattern.hasPrefix(":") {
            // Pattern for inheritance/conformance: ":Parent"
            let targetParentName = String(pattern.dropFirst())
            for parentName in parents {
                if isRoot(pattern: targetParentName, name: parentName) {
                    return true
                }
            }
            return false
        } else {
            return isRoot(pattern: pattern, name: name)
        }
    }
    
    private func isRoot(pattern: String, name: String) -> Bool {
        // Prefix pattern: "pre*"
        if pattern.hasSuffix("*") && !pattern.hasPrefix("*") {
            let prefix = String(pattern.dropLast())
            return name.hasPrefix(prefix)
        }
        
        // Suffix pattern: "*suffix"
        if pattern.hasPrefix("*") && !pattern.hasSuffix("*") {
            let suffix = String(pattern.dropFirst())
            return name.hasSuffix(suffix)
        }
        
        // Contains pattern: "*text*"
        if pattern.hasPrefix("*") && pattern.hasSuffix("*") && pattern.count > 2 {
            let text = String(pattern.dropFirst().dropLast())
            return name.contains(text)
        }
        //exact match
        return name == pattern
    }
}

