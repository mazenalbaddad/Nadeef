//
//  File.swift
//  
//
//  Created by mazen baddad on 10/28/23.
//

import Foundation

struct CodeBlockMetadata {
    var type: String
    var name: String
    var parents: Array<String> = []
    var filePath: String
    var startingLine: Int
}
