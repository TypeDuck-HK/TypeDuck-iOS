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
        self.text = text
        self.textColor = color
        self.font = font.withSize(font.pointSize * Settings.cached.candidateFontSize.scale)
    }
}
