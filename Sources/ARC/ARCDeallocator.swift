//
//  File 2.swift
//  
//
//  Created by Mazen Baddad on 30/08/2023.
//

import Foundation

class ARCDeallocator  {
    
    private let logger: Logger
    
    init(logger: Logger = ConsoleLogger()) {
        self.logger = logger
    }
    
    /// Iteratively strips objects that nothing else references. Returns the
    /// names of the removed objects in the order they were discovered.
    @discardableResult
    func removeUnused(objects: inout [ObjectReference]) -> [String] {
        var names: [String] = []
        var referenceChanged = false
        logger.log("iteration \(objects.count)")
        for (i, object) in objects.enumerated().reversed() {
            if object.references.count < 1 {
                names.append(object.object.name)
                objects.remove(at: i)
                referenceChanged = true
            }
        }
        objects.forEach { $0.clearReferences() }
        if referenceChanged {
            names += removeUnused(objects: &objects)
        }
        return names
    }
}
