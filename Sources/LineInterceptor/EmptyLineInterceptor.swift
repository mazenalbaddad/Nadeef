//
//  File.swift
//  nadeef
//
//  Created by Mazen Albaddad on 05/01/2026.
//

import Foundation

struct EmptyLineInterceptor: LineInterceptor {
    
    func intercept(line: String) -> String? {
        if line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return nil
        }
        return line
    }
}
