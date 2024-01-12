//
//  LanguageTableViewCell.swift
//  Cantoboard
//
//  Created by Alex Man on 19/4/23.
//

import UIKit

class LanguageTableViewCell: UITableViewCell {
    var isEnabled = true {
        didSet {
            setEnabled()
        }
    }
    
    convenience init(languageName: String) {
        self.init()
        textLabel?.attributedText = languageName.toHKAttributedString
        selectionStyle = .none
    }
    
    convenience init(languageName: String, checked: Bool, isEnabled: Bool) {
        self.init()
        textLabel?.attributedText = languageName.toHKAttributedString
        editingAccessoryType = checked ? .checkmark : .none
        self.isEnabled = isEnabled
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setEnabled()
    }
    
    func setEnabled() {
        for cellSubview in subviews {
            if cellSubview.isKind(of: NSClassFromString("UITableViewCellEditControl")!) {
                for subview in cellSubview.subviews {
                    if let imageView = subview as? UIImageView {
                        imageView.layer.opacity = isEnabled ? 1 : 0.5
                        break
                    }
                }
            } else if let button = cellSubview as? UIButton {
                button.isEnabled = isEnabled
            }
        }
        isUserInteractionEnabled = isEnabled
    }
}
