import Testing
@testable import Nadeef

@Suite("CodeBlock")
struct CodeBlockTests {
    
    @Test func linesAreAppendedInOrder() {
        let block = CodeBlockFactory.make(name: "A")
        block.addLine("first")
        block.addLine("second")
        block.addLine("third")
        #expect(block.lines == ["first", "second", "third"])
    }
    
    @Test func concatenatedLinesJoinsWithSingleSpace() {
        let block = CodeBlockFactory.make(name: "A", lines: ["alpha", "beta", "gamma"])
        #expect(block.concatenatedLines == "alpha beta gamma")
    }
    
    @Test func concatenatedLinesEmptyByDefault() {
        let block = CodeBlockFactory.make(name: "A")
        #expect(block.concatenatedLines == "")
    }
    
    @Test func metadataPreserved() {
        let block = CodeBlockFactory.make(
            type: "struct",
            name: "Point",
            parents: ["Equatable"],
            filePath: "/tmp/Point.swift"
        )
        #expect(block.metadata.type == "struct")
        #expect(block.metadata.name == "Point")
        #expect(block.metadata.parents == ["Equatable"])
        #expect(block.metadata.filePath == "/tmp/Point.swift")
    }
}
