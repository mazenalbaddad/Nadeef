//
//  SwiftPreviewCollector.swift
//
//
//  Created by mazen baddad on 3/29/26.
//

import Foundation

class SwiftPreviewCollector: ObjectCollector {
    
    var fileReader: FileReader
    
    init(fileReader: FileReader) {
        self.fileReader = fileReader
    }
    
    func collectObjects(from files: Array<File>) throws -> Array<Object> {
        let previewObject = SystemObject(name: "Preview")
        for file in files {
            let lines = try fileReader.read(file: file)
            for block in collectPreviewBlocks(from: lines, filePath: file.path) {
                previewObject.add(codeBlock: block)
            }
        }
        return previewObject.codeBlocks.isEmpty ? [] : [previewObject]
    }
    
    private func collectPreviewBlocks(from lines: [String], filePath: String) -> [CodeBlock] {
        var codeBlocks: [CodeBlock] = []
        var blockCapture: BlockCapture?
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if blockCapture == nil && trimmed.hasPrefix("#Preview") {
                let metadata = CodeBlockMetadata(type: "#Preview", name: "Preview", filePath: filePath)
                blockCapture = BlockCapture(metadata: metadata)
            }
            blockCapture?.addLine(line)
            if let codeBlock = blockCapture?.capture() {
                codeBlocks.append(codeBlock)
                blockCapture = nil
            }
        }
        return codeBlocks
    }
}
