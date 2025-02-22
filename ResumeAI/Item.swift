//
//  Item.swift
//  ResumeAI
//
//  Created by Chaman on 22/02/25.
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
