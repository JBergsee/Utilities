//
//  UILabel+Highlight.swift
//  FlightBriefing
//
//  Created by Johan Nyman on 2022-01-06.
//  Copyright © 2022 JN Avionics. All rights reserved.
//

import Foundation
import UIKit

@objc
public extension UILabel {
    
    func resetAttributes() {
        let plainText = text
        attributedText = nil
        text = nil
        text = plainText
    }

    /// Writes the supplied string in bold if present in the label
    func makeBold(text: String?) {
        highlightText(text, bold: true)
    }

    /// Writes the supplied text in red bold if present in the label
    @available(*, deprecated, renamed: "boldRed")
    func highlight(text:String?) {
        self.highlightText(text, color: .red, bold: true)
    }

    /// Writes the supplied text in red bold if present in the label
    func boldRed(text: String?) {
        highlightText(text, color: .red, bold: true)
    }

    ///Gives the supplied text a yellow background if present in the label.
    func stabiloBoss(text: String?, excludeIn: String? = nil) {
        highlightText(text, bold: false, backgroundColor: .systemYellow, excludeIn: excludeIn)
    }

    /// Writes the supplied text fragments of the array in bold, or using the given font and color if supplied
    func highlightTextInArray(_ textArray: [String], font: UIFont? = nil, color: UIColor? = nil, bold: Bool = true) {
        textArray.forEach { text in
            highlightText(text, font: font, color: color, bold: bold)
        }
    }

    /// Writes the supplied text in bold, or using the given font, color and backgroundcolor if supplied
    func highlightText(_ text: String?, font: UIFont? = nil, color: UIColor? = nil, bold: Bool = true, backgroundColor: UIColor? = nil, excludeIn: String? = nil) {
        
        guard let labelText = attributedText?.mutableCopy() as? NSMutableAttributedString,
              let target = text,
              !target.isEmpty else {
            return
        }


        //Assemble attributes
        
        var attributes: [NSAttributedString.Key: Any] = [:]
        if let color {
            attributes[.foregroundColor] = color
        }
        if let backgroundColor {
            attributes[.backgroundColor] = backgroundColor
        }
        if let font {
            attributes[.font] = font
        }
        if (bold) {
            //Get the supplied font or the labels font
            let boldFont = font ?? self.font

            //get the fontDescriptor, with trait "bold"
            if let boldFontDescriptor = boldFont?.fontDescriptor.withSymbolicTraits(.traitBold) {
                //Setting size to '0.0' will preserve the textSize
                attributes[.font] = UIFont(descriptor: boldFontDescriptor, size: 0.0)
            }
        }

        //Find the range(s)

        //let ranges: [Range<String.Index>]? = text?.ranges(of: target)
        //let range: NSRange = labelText.mutableString.range(of: target, options: .caseInsensitive)

        let ranges = self.text?.ranges(ofText: target, excludeText: excludeIn ?? "")
        ranges?.forEach({ range in
            labelText.addAttributes(attributes, range: range)
        })

        attributedText = labelText
    }

}

public extension String {
    func ranges(ofText searchText: String, excludeText: String = "") -> [NSRange] {


        //Get all ranges of excludeText
        var excludeRanges: [NSRange] = []
        var currentStart = startIndex
        while currentStart < endIndex {
            if let range = self.range(of: excludeText, options: .caseInsensitive, range: currentStart..<endIndex) {
                let convertedRange = NSRange(range, in: self)
                excludeRanges.append(convertedRange)
                currentStart = range.upperBound
            } else {
                currentStart = endIndex
            }
        }

        //Get all ranges of searchText
        var ranges: [NSRange] = []
        currentStart = startIndex
        while currentStart < endIndex {
            if let range = self.range(of: searchText, options: .caseInsensitive, range: currentStart..<endIndex) {
                let convertedRange = NSRange(range, in: self)
                //Check if it is included in any of the excludeRanges
                //Not optimal, I know, but it's late and I'm tired...
                var excluded = false
                for exRange in excludeRanges {
                    if exRange.contains(range: convertedRange) {
                        excluded = true
                        break
                    }
                }
                //Only add if not excluded
                if (!excluded) {
                    ranges.append(convertedRange)
                }
                
                currentStart = range.upperBound
            } else {
                currentStart = endIndex
            }
        }

        return ranges
    }
}

extension NSRange {
    /// Returns true if `range` is completely within the receiver
    func contains(range: NSRange) -> Bool {
        let startsInRange: Bool = range.location >= self.location
        let endsInRange: Bool = range.location+range.length <= self.location+self.length
        return startsInRange && endsInRange
    }
}
