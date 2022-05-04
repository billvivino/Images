//
//  Models.swift
//  Images
//
//  Created by Bill Vivino on 5/2/22.
//

import Foundation

struct ImageDataStruct: Codable, Hashable {
    var url: String
    var created: String
    var updated: String
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(url)
        hasher.combine(created)
        hasher.combine(updated)
    }
}
