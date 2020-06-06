//
//  APNs.swift
//  APNs
//
//  Created by Sven on 2020/4/23.
//  Copyright © 2020 zhuxiaoliang. All rights reserved.
//

import Foundation

extension UserDefaults {

    
    var lastP8Data: Data? {
        get { return data(forKey: #function) }
        set { set(newValue, forKey: #function) }
    }
    var lastP8Path: String? {
        get { return string(forKey: #function) }
        set { set(newValue, forKey: #function) }
    }
}
