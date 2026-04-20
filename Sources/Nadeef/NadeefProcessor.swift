//
//  File.swift
//  
//
//  Created by mazen baddad on 10/29/23.
//

import Foundation

class NadeefProcessor {
    
    var configuration: NadeefConfiguration
    
    init(configuration: NadeefConfiguration) {
        self.configuration = configuration
    }
    
    func process() throws {
        let fileSearcher = SwiftFileSearcher()
        let files = fileSearcher.startSearching(from: configuration.path)
        print("TOTAL FILES COUNT ", files.count)
        
        let lineInterceptors = CompositeLineInterceptor(interceptors: [EmptyLineInterceptor(),
                                                                       SwiftSingleLineCommentInterceptor(),
                                                                       SwiftMultiLineCommentInterceptor()])
        let swiftFileReader = SwiftFileReader(lineInterceptor: lineInterceptors)
        let swiftCollector = SwiftCollector(fileReader: swiftFileReader,
                                            collectors: [SwiftObjectCollector(fileReader: swiftFileReader, configuration: configuration),
                                                         SwiftPreviewCollector(fileReader: swiftFileReader),
                                                         SwiftGlobalLineCollector(fileReader: swiftFileReader)]
        )
        
        let referenceCounter = ReferenceCounter()
        var objectsReferences = referenceCounter.searchReferences(for: try swiftCollector.collectObjects(from: files))
        print("TOTAL OBJECTS COUNT ", objectsReferences.count)

        let arcDeallocator = ARCDeallocator()
        let unusedObjects = arcDeallocator.removeUnused(objects: &objectsReferences)
        
        objectsReferences.forEach({ print($0.object.name, "reference in ", $0.references.compactMap({$0.value?.name})) })

        unusedObjects.forEach({ print("\($0) IS UNUSED")})
        print("\(unusedObjects.count) UNUSED OBJECT")
    }
}
