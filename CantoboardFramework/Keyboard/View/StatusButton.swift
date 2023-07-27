//
//  StatusButton.swift
//  CantoboardFramework
//
//  Created by Alex Man on 6/11/21.
//

import Foundation
import UIKit

extension CALayer {
    static let disableAnimationActions: [String : CAAction] =  [
        "backgroundColor": NSNull(),
        "bounds": NSNull(),
        "contents": NSNull(),
        "fontSize": NSNull(),
        "foregroundColor": NSNull(),
        "hidden": NSNull(),
        "onOrderIn": NSNull(),
        "onOrderOut": NSNull(),
        "position": NSNull(),
        "string": NSNull(),
        "sublayers": NSNull(),
    ]
}

class StatusButton: UIButton {
    static let statusInset: CGFloat = 4
    static let textPadding: CGFloat = 8
    
    private weak var statusSquareBg: CALayer?
    
    // Uncomment this to debug memory leak.
    private let c = InstanceCounter<StatusButton>()
    
    var isMini: Bool = false {
        didSet {
            setNeedsLayout()
        }
    }
    
    var shouldShowStatusBackground: Bool = true {
        didSet {
            setNeedsLayout()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let statusSquareBg = CALayer()
        statusSquareBg.actions = CALayer.disableAnimationActions
        statusSquareBg.frame = frame.insetBy(dx: Self.statusInset, dy: Self.statusInset)
        statusSquareBg.backgroundColor = ButtonColor.systemKeyBackgroundColor.resolvedColor(with: traitCollection).cgColor
        statusSquareBg.cornerRadius = 3
        statusSquareBg.masksToBounds = true
        layer.addSublayer(statusSquareBg)
        
        self.statusSquareBg = statusSquareBg
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        titleLabel?.font = .preferredFont(forTextStyle: isMini ? .footnote : .title2).multiplyPointSizeBy(scale: Settings.cached.candidateFontSize.statusScale)
        titleLabel?.adjustsFontSizeToFitWidth = true
        titleLabel?.textAlignment = .center
        if !isMini {
            titleLabel?.frame = bounds.insetBy(dx: Self.textPadding, dy: Self.textPadding)
            statusSquareBg?.frame = bounds.insetBy(dx: Self.statusInset, dy: Self.statusInset)
        }
        statusSquareBg?.isHidden = isMini || !shouldShowStatusBackground
        setTitleColor(isMini ? ButtonColor.keyHintColor : .label, for: .normal)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        statusSquareBg?.backgroundColor = ButtonColor.systemKeyBackgroundColor.resolvedColor(with: traitCollection).cgColor
    }
}
