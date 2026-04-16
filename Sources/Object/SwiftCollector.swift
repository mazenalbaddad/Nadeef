//
//  SwiftCollector.swift
//
//
//  Created by mazen baddad on 3/29/26.
//

import Foundation

class SwiftCollector: ObjectCollector {
    
    var fileReader: FileReader
    private let collectors: [ObjectCollector]
    
    init(fileReader: FileReader, collectors: [ObjectCollector]) {
        self.fileReader = fileReader
        self.collectors = collectors
    }
    
    func collectObjects(from files: Array<File>) throws -> Array<Object> {
        var objects: [Object] = []
        for collector in collectors {
            objects += try collector.collectObjects(from: files)
        }
        return objects
    }
}
