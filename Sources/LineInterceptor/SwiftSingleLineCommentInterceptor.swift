//
//  File.swift
//  nadeef
//
//  Created by Mazen Albaddad on 05/01/2026.
//

import Foundation

struct SwiftSingleLineCommentInterceptor: LineInterceptor {
    
    func intercept(line: String) -> String? {
        let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedLine.hasPrefix("//") {
            return nil
        }
        return line
    }
}
