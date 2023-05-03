//
//  SidedStackView.swift
//  CantoboardFramework
//
//  Created by Alex Man on 4/5/23.
//

import Foundation
import UIKit
import CocoaLumberjackSwift

class SidedStackView: UIStackView {
    var spacer: UIView
    var contentView: UIStackView
    
    init(axis: NSLayoutConstraint.Axis = .horizontal, spacing: CGFloat = 0, alignment: UIStackView.Alignment = .fill, arrangedSubviews: [UIView] = []) {
        contentView = UIStackView(arrangedSubviews: arrangedSubviews)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.axis = axis
        contentView.spacing = spacing
        contentView.alignment = alignment
        
        spacer = UIView()
        spacer.setContentHuggingPriority(.fittingSizeLevel, for: axis)
        spacer.setContentCompressionResistancePriority(.fittingSizeLevel, for: axis)
        
        super.init(frame: .zero)
        self.translatesAutoresizingMaskIntoConstraints = false
        self.axis = axis
        super.addArrangedSubview(contentView)
        super.addArrangedSubview(spacer)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var isSpaced: Bool = true {
        didSet {
            if isSpaced {
                super.addArrangedSubview(spacer)
            } else {
                super.removeArrangedSubview(spacer)
            }
        }
    }
    
    override var arrangedSubviews: [UIView] {
        contentView.arrangedSubviews
    }
    
    override func addArrangedSubview(_ view: UIView) {
        contentView.addArrangedSubview(view)
    }
    
    override func removeArrangedSubview(_ view: UIView) {
        contentView.removeArrangedSubview(view)
    }
}
