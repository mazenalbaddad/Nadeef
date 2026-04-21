import Testing
@testable import Nadeef

@Suite("SwiftCollector")
struct SwiftCollectorTests {
    
    private struct StubCollector: ObjectCollector {
        var fileReader: FileReader
        let objects: [Object]
        
        func collectObjects(from files: Array<File>) throws -> Array<Object> {
            objects
        }
    }
    
    @Test func aggregatesAllChildCollectorsInOrder() throws {
        let reader = FakeFileReader()
        let a = ObjectFactory.makeSwift(name: "A")
        let b = ObjectFactory.makeSwift(name: "B")
        let c = ObjectFactory.makeSwift(name: "C")
        
        let composite = SwiftCollector(
            fileReader: reader,
            collectors: [
                StubCollector(fileReader: reader, objects: [a]),
                StubCollector(fileReader: reader, objects: [b, c])
            ]
        )
        
        let result = try composite.collectObjects(from: [])
        #expect(result.map(\.name) == ["A", "B", "C"])
    }
    
    @Test func emptyChildListYieldsEmptyResult() throws {
        let composite = SwiftCollector(fileReader: FakeFileReader(), collectors: [])
        let result = try composite.collectObjects(from: [])
        #expect(result.isEmpty)
    }
    
    @Test func propagatesErrorsFromChildCollectors() {
        struct ThrowingCollector: ObjectCollector {
            var fileReader: FileReader
            func collectObjects(from files: Array<File>) throws -> Array<Object> {
                throw RuntimeError("boom")
            }
        }
        let composite = SwiftCollector(
            fileReader: FakeFileReader(),
            collectors: [ThrowingCollector(fileReader: FakeFileReader())]
        )
        #expect(throws: RuntimeError.self) {
            try composite.collectObjects(from: [])
        }
    }
}
