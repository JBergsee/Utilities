//
//  File.swift
//  
//
//  Created by Johan Nyman on 2022-02-05.
//

import Foundation


//TODO: Latitude to string and back
//TODO: Longitude to string and back


@objcMembers
public class Utilities {

    public static func minutesToTimeString(_ minutes:Int64) -> String {
        guard minutes >= 0 else { return ""}

        var hours = minutes/60
        if (hours >= 24) {hours -= 24}
        
        return String(format: "%02d:%02d", hours, minutes%60)
    }
    
    //Returns the value as a string with the given number of decimals
    static public func stringValueIfSet(_ value:Double, withDecimals:Int) -> String {
        guard value >= 0 else {return ""}
        
        return String(format: "%.\(withDecimals)f", value)
    }
    
    @objc
    public static func fmsCoordinateString(latitude:Double, longitude:Double) -> String {
        
        var latSeconds = Int(latitude * 3600)
        let latDegrees = Int(latSeconds / 3600)
        latSeconds = abs(latSeconds % 3600)
        let latMinutes = Int(latSeconds / 60)
        latSeconds %= 60
        
        var longSeconds = Int(longitude * 3600)
        let longDegrees = Int(longSeconds / 3600)
        longSeconds = abs(longSeconds % 3600)
        let longMinutes = Int(longSeconds / 60)
        longSeconds %= 60
        
        //"Normal text"
        /*
        NSString* result = [NSString stringWithFormat:@"%@ %02lld°%02lld'%02lld\" %@ %03d°%02lld'%02lld\"",
                            latDegrees >= 0 ? @"N" : @"S",
                            ABS(latDegrees),
                            latMinutes,
                            latSeconds,
                            longDegrees >= 0 ? @"E" : @"W",
                            ABS(longDegrees),
                            longMinutes,
                            longSeconds];
        */
        //Airbus FMS-like syntax
        let result = String(format:"%02d%02d.%01d%@ %03d%02d.%01d%@",
                            abs(latDegrees),
                            latMinutes,
                            latSeconds/6,
                            latDegrees >= 0 ? "N" : "S",
                            abs(longDegrees),
                            longMinutes,
                            longSeconds/6,
                            longDegrees >= 0 ? "E" : "W")
        return result
    }

}

public extension IntegerLiteralType {
    func toTimeString() -> String {
        return Utilities.minutesToTimeString(Int64(self))
    }
}
