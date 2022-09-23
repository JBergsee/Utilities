//
//  File.swift
//  
//
//  Created by Johan Nyman on 2022-02-05.
//

import Foundation

@objcMembers
public class Utilities {

    public static func timeStringWith<T : BinaryInteger>(minutes:T) -> String {
        guard minutes >= 0 else { return ""}

        var hours = minutes/60
        if (hours >= 24) {hours -= 24}
        
        return String(format: "%02d:%02d", Int(hours), Int(minutes)%60)
    }
    
    //Returns the value as a string with the given number of decimals
    static public func stringValueIfSet<T : BinaryFloatingPoint>(_ value:T, withDecimals:Int) -> String {
        guard value >= 0 else {return ""}
        return String(format: "%.\(withDecimals)f", Double(value))
    }

}

public extension BinaryInteger {
    func toTimeString() -> String {
        return Utilities.timeStringWith(minutes: self)
    }
}

public extension BinaryFloatingPoint {
    func toValueString(decimals: Int) -> String {
        return Utilities.stringValueIfSet(self, withDecimals: decimals)
    }
}
