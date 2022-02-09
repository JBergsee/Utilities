//
//  File.swift
//  
//
//  Created by Johan Nyman on 2022-02-05.
//

import Foundation

public extension Double
{
    func toRadians() -> Double { return self * Double.pi / 180 }
    func toDegrees() -> Double { return self * 180 / Double.pi }
}


public extension FileManager {
    static var documentsDirectory: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    static var applicationSupportDirectory: URL {
        let paths = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        return paths[0]
    }
}
