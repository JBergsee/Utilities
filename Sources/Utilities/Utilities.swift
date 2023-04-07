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
    /// Returns a string in format HH:mm or empty string if the value is less than 0
    func toTimeString() -> String {
        return Utilities.timeStringWith(minutes: self)
    }
}

public extension BinaryFloatingPoint {
    /// Rounds a positive or zero value to the given number of `decimals` places and returns as String.
    /// Negative values will return empty string.
    func toValueString(decimals: Int) -> String {
        return Utilities.stringValueIfSet(self, withDecimals: decimals)
    }
}
