//
//  OptionTableViewCell.swift
//  Cantoboard
//
//  Created by Alex Man on 14/1/24.
//

import UIKit

class OptionTableViewCell: UITableViewCell {
    private var title: String!
    private var titleLabel: UILabel!
    private var accessory: UIView!
    private var accessoryBottomConstraint, titleLabelTopConstraint, titleLabelBottomConstraint: NSLayoutConstraint!
    
    convenience init(option: Option, optionView: UIView) {
        self.init()
        
        optionView.translatesAutoresizingMaskIntoConstraints = false
        accessory = optionView
        if option.description != nil || option.videoUrl != nil {
            let button = UIButton()
            button.translatesAutoresizingMaskIntoConstraints = false
            button.setImage(CellImage.faq, for: .normal)
            button.isUserInteractionEnabled = false
            
            let stackView = UIStackView(arrangedSubviews: [accessory, button])
            stackView.translatesAutoresizingMaskIntoConstraints = false
            stackView.spacing = 8
            accessory = stackView
        } else {
            selectionStyle = .none
        }
        contentView.addSubview(accessory)
        
        titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.preferredFont(forTextStyle: .body)
        titleLabel.numberOfLines = 0
        
        contentView.addSubview(titleLabel)
        
        title = option.title
        
        accessoryBottomConstraint = contentView.bottomAnchor.constraint(equalTo: accessory.bottomAnchor, constant: 6)
        titleLabelTopConstraint = titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6)
        titleLabelBottomConstraint = contentView.bottomAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6)
        
        NSLayoutConstraint.activate([
            accessoryBottomConstraint,
            contentView.trailingAnchor.constraint(equalTo: accessory.trailingAnchor, constant: 20),
            
            titleLabelTopConstraint,
            titleLabelBottomConstraint,
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            contentView.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 20),
        ])
        
        layout()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layout()
    }
    
    private func layout() {
        let accessorySize = {
            if let stackView = accessory as? UIStackView {
                CGSize(width: stackView.arrangedSubviews.reduce(-stackView.spacing, { $0 + $1.intrinsicContentSize.width + stackView.spacing }), height: stackView.arrangedSubviews.map(\.intrinsicContentSize.height).max()!)
            } else {
                accessory.intrinsicContentSize
            }
        }()
        let font = titleLabel.font!
        let rawOffset = (accessorySize.height + 12 - font.lineHeight) / 2
        let offset = max(rawOffset, 0)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = offset
        var attributes = String.HKAttribute
        attributes[.paragraphStyle] = paragraphStyle
        
        let attributedString = NSMutableAttributedString(string: title, attributes: attributes)
        let space = NSTextAttachment()
        space.bounds = CGRect.init(x: 0, y: 0, width: accessorySize.width + 4, height: 1e-5)
        attributedString.append(NSAttributedString(attachment: space))
        titleLabel.attributedText = attributedString
        
        accessoryBottomConstraint.constant = max(-rawOffset, 0) + 6
        titleLabelTopConstraint.constant = offset
        titleLabelBottomConstraint.constant = offset
    }
}
