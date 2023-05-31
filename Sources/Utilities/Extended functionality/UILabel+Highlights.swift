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
        highlightText(text, font: nil, color: nil, bold: true)
    }

    /// Writes the supplied text in red bold if present in the label
    @available(*, deprecated, renamed: "boldRed")
    func highlight(text:String?) {
        self.highlightText(text, font: nil, color: .red, bold: true)
    }

    /// Writes the supplied text in red bold if present in the label
    func boldRed(text: String?) {
        highlightText(text, font: nil, color: .red, bold: true)
    }

    ///Gives the supplied text a yellow background if present in the label.
    func stabiloBoss(text: String?) {
        guard let labelText = attributedText?.mutableCopy() as? NSMutableAttributedString, let target = text, !target.isEmpty else {
            return
        }

        let range: NSRange = labelText.mutableString.range(of: target, options: .caseInsensitive)

        labelText.addAttribute(.backgroundColor, value: UIColor.systemYellow, range: range)

        attributedText = labelText
    }

    /// Writes the supplied text fragments of the array in bold, or using the given font and color if supplied
    func highlightTextInArray(_ textArray: [String], font: UIFont? = nil, color: UIColor? = nil, bold: Bool = true) {
        textArray.forEach { text in
            highlightText(text, font: font, color: color, bold: bold)
        }
    }

    /// Writes the supplied text in bold, or using the given font and color if supplied
    func highlightText(_ text: String?, font: UIFont? = nil, color: UIColor? = nil, bold: Bool = true) {
        
        guard let labelText = attributedText?.mutableCopy() as? NSMutableAttributedString,
              let target = text,
              !target.isEmpty else {
            return
        }

        let range: NSRange = labelText.mutableString.range(of: target, options: .caseInsensitive)
        
        var attributes: [NSAttributedString.Key: Any] = [:]
        if let color = color {
            attributes[.foregroundColor] = color
        }
        if let font = font {
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
        labelText.addAttributes(attributes, range: range)
        attributedText = labelText
    }

}
