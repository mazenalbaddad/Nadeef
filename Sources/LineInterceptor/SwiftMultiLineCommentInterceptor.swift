//
//  File.swift
//  nadeef
//
//  Created by Mazen Albaddad on 05/01/2026.
//

import Foundation

class SwiftMultiLineCommentInterceptor: LineInterceptor {
    
    private var isInsideComment: Bool = false
    
    func intercept(line: String) -> String? {
        var result = ""
        var currentIndex = line.startIndex
        
        while currentIndex < line.endIndex {
            if isInsideComment {
                if let closeRange = line.range(of: "*/", range: currentIndex..<line.endIndex) {
                    isInsideComment = false
                    currentIndex = closeRange.upperBound
                } else {
                    break
                }
            } else {
                if let openRange = line.range(of: "/*", range: currentIndex..<line.endIndex) {
                    result += String(line[currentIndex..<openRange.lowerBound])
                    isInsideComment = true
                    currentIndex = openRange.upperBound
                } else {
                    result += String(line[currentIndex..<line.endIndex])
                    break
                }
            }
        }
        return result
    }
}
