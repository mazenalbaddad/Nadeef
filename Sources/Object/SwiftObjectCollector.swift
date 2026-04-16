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
        return Array(objects.values)
    }
    
    private func collectBlocks(from lines: [String], file: File) throws -> [CodeBlock] {
        var codeBlocks: [CodeBlock] = []
        var blockCapture: BlockCapture?
        for line in lines {
            if blockCapture == nil, let blockMetadata = codeBlockMetaData(from: line, filePath: file.path) {
                blockCapture = BlockCapture(metadata: blockMetadata)
            }
            blockCapture?.addLine(line)
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
    
    private func codeBlockMetaData(from input: String, filePath: String) -> CodeBlockMetadata? {
        var blockMetaData: CodeBlockMetadata?
        do {
            let objectRegex = "\\b(?:class|actor|struct|extension|protocol|enum)\\s+(?!(func\\s+|var\\s+|let\\s+))([A-Za-z_][A-Za-z0-9_]*)"
            let regex = try NSRegularExpression(pattern: objectRegex, options: [])
            let nsInput = input as NSString
            regex.enumerateMatches(in: input, options: [], range: NSRange(location: 0, length: nsInput.length)) { (match, _, _) in
                guard let match = match, match.numberOfRanges > 1, let blockType = nsInput.substring(with: match.range(at: 0)).components(separatedBy: .whitespaces).first else { return }
                let blockName = nsInput.substring(with: match.range(at: match.numberOfRanges-1))
                var blockParents: Array<String> = []
                
                let inheritanceRegex = #":\s*([^{\n]+)"#
                if let range = input.range(of: inheritanceRegex, options: .regularExpression) {
                    let match = input[range]
                    let parentList = match.replacingOccurrences(of: ":", with: "").components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                    blockParents = parentList
                }
                blockMetaData = CodeBlockMetadata(type: blockType, name: blockName, parents: blockParents, filePath: filePath)
            }
        } catch {
            return nil
        }
        return blockMetaData
    }
}
