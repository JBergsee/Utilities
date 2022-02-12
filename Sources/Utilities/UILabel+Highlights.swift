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
    
    func makeBold(text:String?) {
        self.highlightText(text, font: nil, color: nil, bold: true)
    }
    
    func highlight(text:String?) {
        self.highlightText(text, font: nil, color: .red, bold: true)
    }
    
    func stabiloBoss(text:String?) {
        guard let labelText = self.attributedText?.mutableCopy() as? NSMutableAttributedString, let target = text, !target.isEmpty else {
            return
        }

        let range: NSRange = labelText.mutableString.range(of: target, options: .caseInsensitive)

        labelText.addAttribute(.backgroundColor, value: UIColor.systemYellow, range: range)

        self.attributedText = labelText
    }
    
    func highlightTextInArray(_ textArray: [String], font: UIFont? = nil, color: UIColor? = nil, bold:Bool = true) {
        textArray.forEach { text in
            self.highlightText(text, font: font, color: color, bold: bold)
        }
    }
        
    func highlightText(_ text: String?, font: UIFont? = nil, color: UIColor? = nil, bold:Bool = true) {
        guard let labelText = self.attributedText?.mutableCopy() as? NSMutableAttributedString, let target = text, !target.isEmpty else {
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
        self.attributedText = labelText
    }

}
