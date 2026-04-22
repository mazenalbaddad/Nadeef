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
        let chars = Array(line)
        var i = 0
        var isInsideString = false
        
        while i < chars.count {
            let char = chars[i]
            
            if isInsideComment {
                if char == "*", i + 1 < chars.count, chars[i + 1] == "/" {
                    isInsideComment = false
                    i += 2
                } else {
                    i += 1
                }
                continue
            }
            
            if isInsideString {
                result.append(char)
                if char == "\\", i + 1 < chars.count {
                    result.append(chars[i + 1])
                    i += 2
                    continue
                }
                if char == "\"" {
                    isInsideString = false
                }
                i += 1
                continue
            }
            
            if char == "\"" {
                isInsideString = true
                result.append(char)
                i += 1
                continue
            }
            
            if char == "/", i + 1 < chars.count, chars[i + 1] == "*" {
                isInsideComment = true
                i += 2
                continue
            }
            
            result.append(char)
            i += 1
        }
        return result
    }
}

struct Stuff {
    
}
