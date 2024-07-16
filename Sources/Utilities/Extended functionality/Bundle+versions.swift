//
//  Bundle+versions.swift
//  
//
//  Created by Johan Bergsee on 2024-05-06.
//  
//

import Foundation

public extension Bundle {

    var version: String {
        return infoDictionary?["CFBundleShortVersionString"] as? String ?? "[x.x]"
    }

    var buildNbr: String {
        return infoDictionary?["CFBundleVersion"] as? String ?? "[xxx]"
    }
}
