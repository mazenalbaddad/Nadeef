//
//  SwiftFileReader.swift
//  
//
//  Created by mazen baddad on 9/3/23.
//

import Foundation

class SwiftFileReader: FileReader {
    
    private let lineInterceptor: LineInterceptor
    
    init(lineInterceptor: LineInterceptor) {
        self.lineInterceptor = lineInterceptor
    }
    
    func read(file: File) throws -> [String] {
        guard FileManager.default.fileExists(atPath: file.path) else {
            preconditionFailure("file expected at \(file.path) is missing")
        }
        guard let filePointer:UnsafeMutablePointer<FILE> = fopen(file.path, "r") else {
            preconditionFailure("Could not open file at \(file.path)")
        }
        var lines: [String] = []
        var lineByteArrayPointer: UnsafeMutablePointer<CChar>? = nil
        defer {
            fclose(filePointer)
            lineByteArrayPointer?.deallocate()
        }
        var lineCap: Int = 0
        var bytesRead = getline(&lineByteArrayPointer, &lineCap, filePointer)
        
        while (bytesRead > 0) {
            let line = String.init(cString: lineByteArrayPointer!)
            if let interceptedLine = lineInterceptor.intercept(line: line) {
                lines.append(interceptedLine)
            }
            bytesRead = getline(&lineByteArrayPointer, &lineCap, filePointer)
        }
        return lines
    }
}
