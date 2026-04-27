//
//  ARCDeallocator.swift
//
//
//  Created by Mazen Baddad on 30/08/2023.
//

import Foundation

class ARCDeallocator {
    
    private let logger: Logger
    
    init(logger: Logger = ConsoleLogger()) {
        self.logger = logger
    }
    
    @discardableResult
    func removeUnused(objects: inout [ObjectReference]) -> [UnusedFinding] {
        var findings: [UnusedFinding] = []
        var referenceChanged = false
        logger.debug("iteration \(objects.count)")
        for (i, ref) in objects.enumerated().reversed() {
            if ref.references.count < 1 {
                findings.append(makeFinding(for: ref.object))
                objects.remove(at: i)
                referenceChanged = true
            }
        }
        objects.forEach { $0.clearReferences() }
        if referenceChanged {
            findings += removeUnused(objects: &objects)
        }
        return findings
    }
    
    private func makeFinding(for object: Object) -> UnusedFinding {
        let primary = object.codeBlocks.first(where: { $0.metadata.type != "extension" })
            ?? object.codeBlocks.first
        let kind = primary?.metadata.type ?? "unknown"
        
        var seen = Set<String>()
        var locations: [FindingLocation] = []
        for block in object.codeBlocks {
            let path = block.metadata.filePath
            if seen.insert(path).inserted {
                locations.append(.init(path: path, startingLine: block.metadata.startingLine))
            }
        }
        return UnusedFinding(name: object.name, kind: kind, locations: locations)
    }
}
