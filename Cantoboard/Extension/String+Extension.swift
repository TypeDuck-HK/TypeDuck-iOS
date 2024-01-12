//
//  String+Extension.swift
//  Cantoboard
//
//  Created by Alex Man on 13/1/24.
//

import Foundation
import UIKit

extension String {
    static let HKAttribute: [NSAttributedString.Key : Any] = [NSAttributedString.Key(kCTLanguageAttributeName as String): "zh-HK"]
    
    var toHKAttributedString: NSAttributedString {
        NSAttributedString(string: self, attributes: Self.HKAttribute)
    }
}
