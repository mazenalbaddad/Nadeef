//
//  NadeefProcessor.swift
//
//
//  Created by mazen baddad on 10/29/23.
//

import Foundation

struct ProcessResult {
    let totalFiles: Int
    let totalObjects: Int
    let unusedObjectNames: [String]
    let remainingReferences: [(name: String, referencedBy: [String])]
}

class NadeefProcessor {
    
    var configuration: NadeefConfiguration
    private let fileSearcher: FileSearcher
    private let collector: ObjectCollector
    private let referenceCounter: ReferenceCounter
    private let deallocator: ARCDeallocator
    private let logger: Logger
    
    init(
        configuration: NadeefConfiguration,
        fileSearcher: FileSearcher,
        collector: ObjectCollector,
        referenceCounter: ReferenceCounter,
        deallocator: ARCDeallocator,
        logger: Logger
    ) {
        self.configuration = configuration
        self.fileSearcher = fileSearcher
        self.collector = collector
        self.referenceCounter = referenceCounter
        self.deallocator = deallocator
        self.logger = logger
    }
    
    convenience init(configuration: NadeefConfiguration, logger: Logger = ConsoleLogger()) {
        let lineInterceptors = CompositeLineInterceptor(interceptors: [
            EmptyLineInterceptor(),
            SwiftSingleLineCommentInterceptor(),
            SwiftMultiLineCommentInterceptor()
        ])
        let fileReader = SwiftFileReader(lineInterceptor: lineInterceptors)
        let collector = SwiftCollector(
            fileReader: fileReader,
            collectors: [
                SwiftObjectCollector(fileReader: fileReader, configuration: configuration),
                SwiftPreviewCollector(fileReader: fileReader),
                SwiftGlobalLineCollector(fileReader: fileReader)
            ]
        )
        self.init(
            configuration: configuration,
            fileSearcher: SwiftFileSearcher(logger: logger),
            collector: collector,
            referenceCounter: ReferenceCounter(logger: logger),
            deallocator: ARCDeallocator(logger: logger),
            logger: logger
        )
    }
    
    @discardableResult
    func process() throws -> ProcessResult {
        let files = fileSearcher.startSearching(from: configuration.path)
        logger.log("TOTAL FILES COUNT \(files.count)")
        
        var objectsReferences = referenceCounter.searchReferences(for: try collector.collectObjects(from: files))
        logger.log("TOTAL OBJECTS COUNT \(objectsReferences.count)")
        
        let unusedObjects = deallocator.removeUnused(objects: &objectsReferences)
        
        let remaining: [(name: String, referencedBy: [String])] = objectsReferences.map { ref in
            let names = ref.references.compactMap { $0.value?.name }
            logger.log("\(ref.object.name) reference in \(names)")
            return (ref.object.name, names)
        }
        
        unusedObjects.forEach { logger.log("\($0) IS UNUSED") }
        logger.log("\(unusedObjects.count) UNUSED OBJECT")
        
        return ProcessResult(
            totalFiles: files.count,
            totalObjects: objectsReferences.count + unusedObjects.count,
            unusedObjectNames: unusedObjects,
            remainingReferences: remaining
        )
    }
}
