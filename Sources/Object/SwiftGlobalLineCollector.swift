import Foundation

class SwiftGlobalLineCollector: ObjectCollector {

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
                let metadata = CodeBlockMetadata(type: "global", name: "Global", filePath: file.path)
                let block = CodeBlock(metadata: metadata)
                for line in globalLines {
                    block.addLine(line)
                }
                globalObject.add(codeBlock: block)
            }
        }
        return globalObject.codeBlocks.isEmpty ? [] : [globalObject]
    }

    private func collectGlobalLines(from lines: [String]) -> [String] {
        var globalLines: [String] = []
        var depth = 0
        for line in lines {
            let braces = countBraces(in: line)
            if depth == 0 && braces.open == 0 && braces.close == 0 {
                globalLines.append(line)
            } else {
                depth += braces.open - braces.close
            }
        }
        return globalLines
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
