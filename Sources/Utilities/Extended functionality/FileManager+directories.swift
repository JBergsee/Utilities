//
//  File.swift
//
//
//  Created by Johan Nyman on 2022-11-01.
//

import Foundation

public extension FileManager {
    @objc static var documentsDirectory: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let dir = paths[0]
        //Create it if doesn't exist, fail (graciously) if it does.
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: [:])
        return dir
    }
    
    @objc static var applicationSupportDirectory: URL {
        let paths = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let dir = paths[0]
        //Create it if doesn't exist, fail (graciously) if it does.
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: [:])
        return dir
    }
}
