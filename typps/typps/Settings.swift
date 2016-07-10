//
//  Settings.swift
//  typps
//
//  Created by Monte with Pillow on 7/8/16.
//  Copyright © 2016 Monte Thakkar. All rights reserved.
//

import Foundation
import RealmSwift

class Settings: Object {

    dynamic var isTaxEnabled = false
    dynamic var tipPercent = 20
    dynamic var partySize = 1
    dynamic var currentPartySize = 1
    
}
