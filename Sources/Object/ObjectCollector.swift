//
//  File.swift
//  
//
//  Created by mazen baddad on 10/29/23.
//

import Foundation

protocol ObjectCollector {
    var fileReader: FileReader { get }
    func collectObjects(from files: Array<File>) throws -> Array<Object>
}
