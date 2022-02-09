//
//  File.swift
//  
//
//  Created by Johan Nyman on 2022-02-05.
//

import Foundation


//TODO: Latitude to string and back
//TODO: Longitude to string and back
//TODO: FMSString from lat and long

@objcMembers
public class Utilities {

    public static func minutesToTimeString(_ minutes:Int64) -> String {
        guard minutes >= 0 else { return ""}

        var hours = minutes/60
        if (hours >= 24) {hours -= 24}
        
        return String(format: "%02d:%02d", hours, minutes%60)
    }
    
    static public func stringValueIfSet(_ value:Double, withDecimals:Int) -> String {
        guard value >= 0 else {return ""}
        
        return String(format: "%.\(withDecimals)f", value)
    }

}
