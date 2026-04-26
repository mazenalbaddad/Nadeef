//
//  SwiftFileReader.swift
//  
//
//  Created by mazen baddad on 9/3/23.
//

import Foundation

class SwiftFileReader: FileReader {
    
    private let lineInterceptor: LineInterceptor
    private let fileManager: FileManager
    
    init(lineInterceptor: LineInterceptor, fileManager: FileManager = .default) {
        self.lineInterceptor = lineInterceptor
        self.fileManager = fileManager
    }
    
    func read(file: File) throws -> [SourceLine] {
        guard fileManager.fileExists(atPath: file.path) else {
            throw RuntimeError("file expected at \(file.path) is missing")
        }
        guard let filePointer: UnsafeMutablePointer<FILE> = fopen(file.path, "r") else {
            preconditionFailure("Could not open file at \(file.path)")
        }
        var lines: [SourceLine] = []
        var lineByteArrayPointer: UnsafeMutablePointer<CChar>? = nil
        defer {
            fclose(filePointer)
            lineByteArrayPointer?.deallocate()
        }
        var lineCap: Int = 0
        var bytesRead = getline(&lineByteArrayPointer, &lineCap, filePointer)
        var physicalLine = 0
        
        while bytesRead > 0 {
            physicalLine += 1
            let line = String(cString: lineByteArrayPointer!)
            if let interceptedLine = lineInterceptor.intercept(line: line) {
                lines.append(SourceLine(lineNumber: physicalLine, text: interceptedLine))
            }
            bytesRead = getline(&lineByteArrayPointer, &lineCap, filePointer)
        }
        return lines
    }
}

class Mazen {
    
    
}
