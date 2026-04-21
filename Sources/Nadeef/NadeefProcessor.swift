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
    let unused: [UnusedFinding]
    let remainingReferences: [(name: String, referencedBy: [String])]
    
    var unusedObjectNames: [String] { unused.map(\.name) }
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
        logger.info("total files count \(files.count)")
        
        var objectsReferences = referenceCounter.searchReferences(for: try collector.collectObjects(from: files))
        logger.info("total objects count \(objectsReferences.count)")
        
        let unusedFindings = deallocator.removeUnused(objects: &objectsReferences)
        
        let remaining: [(name: String, referencedBy: [String])] = objectsReferences.map { ref in
            let names = ref.references.compactMap { $0.value?.name }
            logger.debug("\(ref.object.name) reference in \(names)")
            return (ref.object.name, names)
        }
        
        unusedFindings.forEach { logger.info("\($0.name) is unused (\($0.paths.joined(separator: ", ")))") }
        logger.info("\(unusedFindings.count) unused objects")
        
        return ProcessResult(
            totalFiles: files.count,
            totalObjects: objectsReferences.count + unusedFindings.count,
            unused: unusedFindings,
            remainingReferences: remaining
        )
    }
}
