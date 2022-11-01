//
//  File.swift
//  
//
//  Created by Johan Nyman on 2022-11-01.
//

import Foundation

//Can be used to get paper Log Nr PPS_Flight summary string, or the NOTAM D) item (temporary times)
public extension String {
    func slice(from: String, to: String) -> String? {
        guard let fromRange = from.isEmpty ? startIndex..<startIndex : range(of: from) else { return nil }
        guard let toRange = to.isEmpty ? endIndex..<endIndex : range(of: to, range: fromRange.upperBound..<endIndex) else { return nil }
        return String(self[fromRange.upperBound..<toRange.lowerBound])
    }
}


//Simple use of subscripts in strings.
//Described here: https://stackoverflow.com/questions/24092884/get-nth-character-of-a-string-in-swift-programming-language

public extension String {

    var length: Int {
        return count
    }

    subscript (i: Int) -> String {
        return self[i ..< i + 1]
    }

    func substring(fromIndex: Int) -> String {
        return self[min(fromIndex, length) ..< length]
    }

    func substring(toIndex: Int) -> String {
        return self[0 ..< max(0, toIndex)]
    }

    subscript (r: Range<Int>) -> String {
        let range = Range(uncheckedBounds: (lower: max(0, min(length, r.lowerBound)),
                                            upper: min(length, max(0, r.upperBound))))
        let start = index(startIndex, offsetBy: range.lowerBound)
        let end = index(start, offsetBy: range.upperBound - range.lowerBound)
        return String(self[start ..< end])
    }
}
