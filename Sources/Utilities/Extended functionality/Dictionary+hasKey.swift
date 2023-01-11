//
//  File.swift
//  
//
//  Created by Johan Nyman on 2022-12-31.
//

import Foundation

public extension Dictionary {

    func hasKey(_ key: Key) -> Bool {
        index(forKey: key) != nil
    }

}
