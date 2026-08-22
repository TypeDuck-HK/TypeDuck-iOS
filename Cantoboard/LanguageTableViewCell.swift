//
//  LanguageTableViewCell.swift
//  Cantoboard
//
//  Created by Alex Man on 19/4/23.
//

import UIKit

class LanguageTableViewCell: UITableViewCell {
    convenience init(languageName: String) {
        self.init()
        textLabel?.attributedText = languageName.toHKAttributedString
        selectionStyle = .none
    }
    
    convenience init(languageName: String, checked: Bool) {
        self.init()
        textLabel?.attributedText = languageName.toHKAttributedString
        editingAccessoryType = checked ? .checkmark : .none
    }
}
