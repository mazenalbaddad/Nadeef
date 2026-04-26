//
//  File.swift
//  
//
//  Created by mazen baddad on 10/30/23.
//

import Foundation

class SwiftObjectCollector: ObjectCollector {
    
    var fileReader: FileReader
    var configuration: NadeefConfiguration
    
    init(fileReader: FileReader, configuration: NadeefConfiguration) {
        self.fileReader = fileReader
        self.configuration = configuration
    }
    
    func collectObjects(from files: Array<File>) throws -> Array<Object> {
        var objects: [String: Object] = [:]
        for file in files {
            let lines = try fileReader.read(file: file)
            let codeBlocks = try collectBlocks(from: lines, file: file)
            for block in codeBlocks {
                if objects[block.metadata.name] == nil {
                    objects[block.metadata.name] = SwiftObject(name: block.metadata.name, configuration: configuration)
                }
                objects[block.metadata.name]?.add(codeBlock: block)
            }
        }
        resolveAncestors(for: objects)
        return Array(objects.values)
    }
    
    private func resolveAncestors(for objects: [String: Object]) {
        let directParents = objects.mapValues { $0.codeBlocks.flatMap { $0.metadata.parents } }
        for object in objects.values {
            var visited = Set<String>()
            var queue = object.codeBlocks.flatMap { $0.metadata.parents }
            var ancestors: [String] = []
            while !queue.isEmpty {
                let current = queue.removeFirst()
                guard visited.insert(current).inserted else { continue }
                if let grandparents = directParents[current] {
                    ancestors.append(contentsOf: grandparents)
                    queue.append(contentsOf: grandparents)
                }
            }
            object.ancestors = ancestors
        }
    }
    
    private func collectBlocks(from lines: [SourceLine], file: File) throws -> [CodeBlock] {
        var codeBlocks: [CodeBlock] = []
        var blockCapture: BlockCapture?
        for sourceLine in lines {
            if blockCapture == nil, let blockMetadata = codeBlockMetaData(from: sourceLine.text, filePath: file.path, startingLine: sourceLine.lineNumber) {
                blockCapture = BlockCapture(metadata: blockMetadata)
            }
            blockCapture?.addLine(sourceLine.text)
            if let codeBlock = blockCapture?.capture() {
                codeBlocks.append(codeBlock)
                blockCapture = nil
            }
        }
        if blockCapture != nil {
            throw RuntimeError("\(file.name) contains an object that connot be captured, make sure this file is compilable and there's no extra open/close curly braces")
        }
        return codeBlocks
    }
    
    private func codeBlockMetaData(from input: String, filePath: String, startingLine: Int) -> CodeBlockMetadata? {
        var blockMetaData: CodeBlockMetadata?
        do {
            let objectRegex = "\\b(?:class|actor|struct|extension|protocol|enum)\\s+(?!(func\\s+|var\\s+|let\\s+))([A-Za-z_][A-Za-z0-9_]*)"
            let regex = try NSRegularExpression(pattern: objectRegex, options: [])
            let nsInput = input as NSString
            regex.enumerateMatches(in: input, options: [], range: NSRange(location: 0, length: nsInput.length)) { (match, _, _) in
                guard let match = match, match.numberOfRanges > 1, let blockType = nsInput.substring(with: match.range(at: 0)).components(separatedBy: .whitespaces).first else { return }
                let blockName = nsInput.substring(with: match.range(at: match.numberOfRanges-1))
                var blockParents: Array<String> = []
                
                let cleanedInput = self.stripGenericParameters(from: input)
                let inheritanceRegex = #":\s*([^{\n]+)"#
                if let range = cleanedInput.range(of: inheritanceRegex, options: .regularExpression) {
                    let match = cleanedInput[range]
                    let parentList = match.replacingOccurrences(of: ":", with: "").components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                    blockParents = parentList
                }
                blockMetaData = CodeBlockMetadata(type: blockType, name: blockName, parents: blockParents, filePath: filePath, startingLine: startingLine)
            }
        } catch {
            return nil
        }
        return blockMetaData
    }
    
    private func stripGenericParameters(from input: String) -> String {
        var result = ""
        var depth = 0
        for char in input {
            if char == "<" {
                depth += 1
            } else if char == ">" && depth > 0 {
                depth -= 1
            } else if depth == 0 {
                result.append(char)
            }
        }
        return result
    }
}
