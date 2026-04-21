//
//  SwiftFileSearcher.swift
//  
//
//  Created by mazen baddad on 6/30/23.
//

import Foundation

class SwiftFileSearcher: FileSearcher {
    
    var fileManager: FileManager
    private let logger: Logger
    
    init(fileManager: FileManager = FileManager.default, logger: Logger = ConsoleLogger()) {
        self.fileManager = fileManager
        self.logger = logger
    }
    
    func startSearching(from path: String?) -> Array<File> {
        let path = path ?? fileManager.currentDirectoryPath
        var swiftFiles: Array<File> = []
        do {
            let files = try fileManager.contentsOfDirectory(atPath: path)
            for file in files {
                let filePath = path + "/" + file
                guard !self.fileHidden(filePath: filePath) else { continue }
                if self.fileIsDirectoryType(filePath: filePath), file != "Pods" {
                    logger.debug("searching directory \(filePath)")
                    swiftFiles += startSearching(from: filePath)
                } else {
                    let fileExtension: String = "swift"
                    if self.fileExtension(filePath: filePath) == fileExtension {
                        logger.debug("added \(file)")
                        swiftFiles.append(SwiftFile(name: file, path: filePath))
                    }
                }
            }
        } catch {
            logger.warn("\(error)")
        }
        return swiftFiles
    }
}

