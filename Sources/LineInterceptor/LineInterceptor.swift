//
//  LineInterceptor.swift
//  nadeef
//
//  Created by Mazen Albaddad on 05/01/2026.
//

import Foundation

protocol LineInterceptor {
    func intercept(line: String) -> String?
}
