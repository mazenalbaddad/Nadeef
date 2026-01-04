//
//  File 2.swift
//  
//
//  Created by Mazen Baddad on 30/08/2023.
//

import Foundation

class ReferenceCounter {
    
    private let identifierRegex = try! NSRegularExpression(
        pattern: #"\b[A-Z][a-zA-Z0-9_]*\b"#,
        options: []
    )
    
    func searchReferences(for objects: [Object]) -> [ObjectReference] {
        let nonSystemObjects = objects.filter { !$0.systemObject }
        let objectNameSet = Set(nonSystemObjects.map { $0.name })
        var objectReferenceMap: [String: ObjectReference] = [:]
        for object in objects {
            objectReferenceMap[object.name] = ObjectReference(object: object)
        }
        
        for object in objects {
            print("REFERENCE COUNTING \(object.name)")
            let referencedNames = extractReferencedNames(from: object, knownNames: objectNameSet)
            for referencedName in referencedNames where referencedName != object.name {
                if let referencedObjectRef = objectReferenceMap[referencedName] {
                    referencedObjectRef.add(reference: object)
                }
            }
        }
        return objects.compactMap { objectReferenceMap[$0.name] }
    }
    
    private func extractReferencedNames(from object: Object, knownNames: Set<String>) -> Set<String> {
        var foundNames: Set<String> = []
        for codeBlock in object.codeBlocks {
            let text = codeBlock.concatenatedLines
            let range = NSRange(text.startIndex..., in: text)
            let matches = identifierRegex.matches(in: text, options: [], range: range)
            
            for match in matches {
                if let matchRange = Range(match.range, in: text) {
                    let identifier = String(text[matchRange])
                    if knownNames.contains(identifier) {
                        foundNames.insert(identifier)
                    }
                }
            }
        }
        return foundNames
    }
}
