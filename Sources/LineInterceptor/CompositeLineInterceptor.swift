//
//  CompositeLineInterceptor.swift
//  nadeef
//
//  Created by Mazen Albaddad on 06/01/2026.
//

import Foundation
struct CompositeLineInterceptor: LineInterceptor {
    
    private var interceptors: [LineInterceptor]
    
    init(interceptors: [LineInterceptor]) {
        self.interceptors = interceptors
    }
    
    func intercept(line: String) -> String? {
        var currentLine: String? = line
        for index in interceptors.indices {
            guard let input = currentLine else { return nil }
            currentLine = interceptors[index].intercept(line: input)
        }
        return currentLine
    }
}
