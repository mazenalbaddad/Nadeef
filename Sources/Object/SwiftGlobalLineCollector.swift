import Foundation

class SwiftGlobalLineCollector: ObjectCollector {

    private static let typeDeclarationRegex = try! NSRegularExpression(pattern: SwiftObjectCollector.typeDeclarationPattern)

    var fileReader: FileReader

    init(fileReader: FileReader) {
        self.fileReader = fileReader
    }

    func collectObjects(from files: [File]) throws -> [Object] {
        let globalObject = SystemObject(name: "GlobalScope")
        for file in files {
            let lines = try fileReader.read(file: file)
            let globalLines = collectGlobalLines(from: lines)
            if !globalLines.isEmpty {
                let startLine = globalLines.first?.lineNumber ?? 0
                let metadata = CodeBlockMetadata(type: "global", name: "Global", filePath: file.path, startingLine: startLine)
                let block = CodeBlock(metadata: metadata)
                for sourceLine in globalLines {
                    block.addLine(sourceLine.text)
                }
                globalObject.add(codeBlock: block)
            }
        }
        return globalObject.codeBlocks.isEmpty ? [] : [globalObject]
    }

    /// Top-level lines outside type declarations, including the bodies of free functions,
    /// global closures and computed globals, so the types they use count as referenced.
    private func collectGlobalLines(from lines: [SourceLine]) -> [SourceLine] {
        var globalLines: [SourceLine] = []
        var depth = 0
        var insideType = false
        var typeBodyOpened = false
        for sourceLine in lines {
            let braces = countBraces(in: sourceLine.text)
            if depth == 0 && !insideType && declaresType(sourceLine.text) {
                insideType = true
                typeBodyOpened = false
            }
            if !insideType {
                globalLines.append(sourceLine)
            }
            depth = max(0, depth + braces.open - braces.close)
            if insideType {
                typeBodyOpened = typeBodyOpened || braces.open > 0
                if typeBodyOpened && depth == 0 {
                    insideType = false
                }
            }
        }
        return globalLines
    }

    private func declaresType(_ line: String) -> Bool {
        Self.typeDeclarationRegex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) != nil
    }

    private func countBraces(in line: String) -> (open: Int, close: Int) {
        var openIndices: [Int] = []
        var closeIndices: [Int] = []
        var quoteIndices: [Int] = []

        for (i, char) in line.enumerated() {
            if char == "{" { openIndices.append(i) }
            if char == "}" { closeIndices.append(i) }
            if char == "\"" { quoteIndices.append(i) }
        }

        guard !openIndices.isEmpty || !closeIndices.isEmpty else {
            return (0, 0)
        }

        if quoteIndices.isEmpty {
            return (openIndices.count, closeIndices.count)
        }

        let quotedRanges = rangesFromIndices(quoteIndices)
        let open = openIndices.filter { idx in
            !quotedRanges.contains { $0 ~= idx }
        }.count
        let close = closeIndices.filter { idx in
            !quotedRanges.contains { $0 ~= idx }
        }.count
        return (open, close)
    }

    private func rangesFromIndices(_ indices: [Int]) -> [ClosedRange<Int>] {
        var ranges: [ClosedRange<Int>] = []
        var lastIndex: Int?
        for index in indices {
            if let last = lastIndex {
                ranges.append(last...index)
                lastIndex = nil
            } else {
                lastIndex = index
            }
        }
        return ranges
    }
}
