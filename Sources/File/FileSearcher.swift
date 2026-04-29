//
//  FileSearcher.swift
//  
//
//  Created by mazen baddad on 6/30/23.
//

import Foundation

protocol FileSearcher {
    var fileManager: FileManager {get}
    func startSearching(from path: String?) -> Array<File>
}

extension FileSearcher {
    
    func fileAttributes(filePath path: String) -> [FileAttributeKey: Any] {
        let attributes = try? fileManager.attributesOfItem(atPath: path)
        return attributes ?? [:]
    }
    
    func fileHidden(filePath path: String) -> Bool {
        let fileAttributes = self.fileAttributes(filePath: path)
        let extensionHidden = fileAttributes[.extensionHidden] as? Bool ?? false
        return extensionHidden || fileHasDotPrefix(filePath: path)
    }
    
    private func fileHasDotPrefix(filePath path: String) -> Bool {
        let url = URL(fileURLWithPath: path)
        return url.lastPathComponent.hasPrefix(".")
    }
    
    func fileIsDirectoryType(filePath path: String) -> Bool {
        var isDirectory: ObjCBool = false
        fileManager.fileExists(atPath: path, isDirectory: &isDirectory)
        return isDirectory.boolValue
    }
    
    func fileExtension(filePath path: String) -> String? {
        return NSURL(fileURLWithPath: path).pathExtension
    }
    
}
