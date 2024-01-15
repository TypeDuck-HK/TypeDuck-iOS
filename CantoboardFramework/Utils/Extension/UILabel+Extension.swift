//
//  UILabel+Extension.swift
//  KeyboardKit
//
//  Created by Alex Man on 4/29/23.
//

import UIKit

extension UILabel {
    convenience init(text: String? = nil, color: UIColor = ButtonColor.dictionaryViewForegroundColor, font: UIFont) {
        self.init()
        self.attributedText = text?.toHKAttributedString
        self.textColor = color
        self.font = font.withSize(font.pointSize * Settings.cached.candidateFontSize.scale)
    }
    
    func numberOfLines(withWidth width: CGFloat) -> Int {
        guard let attributedText = attributedText, let font = font else { return 0 }
        let mutableAttributedString = NSMutableAttributedString(attributedString: attributedText)
        mutableAttributedString.addAttribute(.font, value: font, range: NSMakeRange(0, attributedText.length))
        
        let textStorage = NSTextStorage(attributedString: mutableAttributedString)
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)
        
        let textContainer = NSTextContainer(size: CGSize(width: width, height: .infinity))
        textContainer.lineFragmentPadding = 0
        textContainer.lineBreakMode = lineBreakMode
        layoutManager.addTextContainer(textContainer)
        
        var numberOfLines = 0
        layoutManager.enumerateLineFragments(forGlyphRange: NSMakeRange(0, layoutManager.numberOfGlyphs)) { _, _, _, _, _ in
            numberOfLines += 1
        }
        return numberOfLines
    }
}
