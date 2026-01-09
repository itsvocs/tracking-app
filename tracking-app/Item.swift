//
//  Item.swift
//  tracking-app
//
//  Created by Jo on 09.01.26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
