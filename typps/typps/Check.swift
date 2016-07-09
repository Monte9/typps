//
//  Check.swift
//  typps
//
//  Created by Monte with Pillow on 7/8/16.
//  Copyright © 2016 Monte Thakkar. All rights reserved.
//

import Foundation
import RealmSwift

class Check: Object {
    
    dynamic var restaurantName = ""
    dynamic var imageURL = ""
    dynamic var createdAt = NSDate()
    dynamic var inputBillAmount: Float = 0
    dynamic var totalTipAmount = 0
    dynamic var isTaxIncluded = false
    dynamic var partySize = 0
    dynamic var finalCheckAmount: Float = 0
    
// Specify properties to ignore (Realm won't persist these)
    
//  override static func ignoredProperties() -> [String] {
//    return []
//  }
}
