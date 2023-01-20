//
//  File.swift
//  
//
//  Created by Johan Nyman on 2022-11-01.
//

import Foundation


public extension Date {
   func toString(using formatter: DateFormatter) -> String {
      return formatter.string(from: self)
   }
}

//From here https://medium.com/geekculture/new-date-formatter-api-f2e6da01d407
public extension DateFormatter {
   static let MMddyy: DateFormatter = {
      let formatter = DateFormatter()
      formatter.timeZone = TimeZone(abbreviation: "UTC") //TimeZone.current
      formatter.dateFormat = "MM/dd/yy"
      return formatter
   }()
    
    static let HHmm: DateFormatter = {
       let formatter = DateFormatter()
       formatter.timeZone = TimeZone(abbreviation: "UTC") //TimeZone.current
       formatter.dateFormat = "HH:mm"
       return formatter
    }()
    
    static let ddHHmm: DateFormatter = {
       let formatter = DateFormatter()
       formatter.timeZone = TimeZone(abbreviation: "UTC") //TimeZone.current
       formatter.dateFormat = "ddHHmm"
       return formatter
    }()
    
    static let yyyy_MM_dd: DateFormatter = {
       let formatter = DateFormatter()
       formatter.timeZone = TimeZone(abbreviation: "UTC") //TimeZone.current
       formatter.dateFormat = "yyyy'-'MM'-'dd" //ex: 2013-07-28
       return formatter
    }()
    
    static let dateAndTime: DateFormatter = {
       let formatter = DateFormatter()
       formatter.timeZone = TimeZone(abbreviation: "UTC") //TimeZone.current
       formatter.dateFormat = "yyyy'-'MM'-'dd' 'HH:mm" //ex: 2012-07-28 20:39
       return formatter
    }()
}
