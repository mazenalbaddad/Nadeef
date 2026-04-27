import Testing
@testable import Nadeef

@Suite("BlockCapture")
struct BlockCaptureTests {
    
    private func makeCapture(name: String = "X") -> BlockCapture {
        let metadata = CodeBlockMetadata(type: "class", name: name, parents: [], filePath: "test.swift", startingLine: 0)
        return BlockCapture(metadata: metadata)
    }
    
    @Test func nilBeforeAnyBraces() {
        let capture = makeCapture()
        capture.addLine("class X")
        #expect(capture.capture() == nil)
    }
    
    @Test func nilWhileUnbalanced() {
        let capture = makeCapture()
        capture.addLine("class X {")
        #expect(capture.capture() == nil)
    }
    
    @Test func capturesOnBalance() {
        let capture = makeCapture()
        capture.addLine("class X {")
        capture.addLine("}")
        let block = capture.capture()
        #expect(block != nil)
        #expect(block?.lines == ["class X {", "}"])
    }
    
    @Test func singleLineBalancedCaptures() {
        let capture = makeCapture()
        capture.addLine("class X {}")
        #expect(capture.capture() != nil)
    }
    
    @Test func nestedBracesCaptureOnlyAtOuterBalance() {
        let capture = makeCapture()
        capture.addLine("class X {")
        capture.addLine("  func f() {")
        capture.addLine("  }")
        #expect(capture.capture() == nil)
        capture.addLine("}")
        #expect(capture.capture() != nil)
    }
    
    @Test func bracesInsideStringsAreIgnored() {
        let capture = makeCapture()
        capture.addLine("class X {")
        capture.addLine(#"  let s = "{{{""#)
        capture.addLine(#"  let t = "}}}""#)
        #expect(capture.capture() == nil, "string-embedded braces must not balance the block")
        capture.addLine("}")
        #expect(capture.capture() != nil)
    }
    
    @Test func lineWithoutBracesDoesNotChangeState() {
        let capture = makeCapture()
        capture.addLine("class X {")
        capture.addLine("let a = 1")
        capture.addLine("let b = 2")
        #expect(capture.capture() == nil)
        capture.addLine("}")
        #expect(capture.capture() != nil)
    }
}
