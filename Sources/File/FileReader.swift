//
//  FileReader.swift
//  
//
//  Created by Mazen Baddad on 29/08/2023.
//

import Foundation

protocol FileReader {
    func read(file: File) throws -> Array<CodeBlock>
}
