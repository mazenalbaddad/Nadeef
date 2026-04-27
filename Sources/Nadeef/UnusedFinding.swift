//
//  UnusedFinding.swift
//  nadeef
//
//  Created by Mazen Albaddad on 21/04/2026.
//

import Foundation

struct UnusedFinding: Equatable {
    let name: String
    let kind: String
    let locations: [FindingLocation]
}

struct FindingLocation: Equatable {
    var path: String
    var startingLine: Int
}
