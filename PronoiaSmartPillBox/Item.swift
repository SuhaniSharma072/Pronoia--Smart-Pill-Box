//
//  Item.swift
//  PronoiaSmartPillBox
//
//  Created by Suhani Sharmaa on 8/23/26.
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
