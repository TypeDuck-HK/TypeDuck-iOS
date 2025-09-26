//
//  ButtonHintLayer.swift
//  KeyboardKit
//
//  Created by Alex Man on 2/15/21.
//

import Foundation
import UIKit

class KeyHintLayer: CATextLayer {
    static let fontSizePerHeight: CGFloat = 10 / "＠".size(withFont: UIFont.systemFont(ofSize: 10)).height
    static let recommendedHeightRatio: CGFloat = 0.3
    
    static let buttonFloatingInsets = UIEdgeInsets(top: 0.5, left: 1, bottom: 1, right: 0.5)
    static let hintInsets = UIEdgeInsets(top: 1, left: 2.5, bottom: 1, right: 2.5)
    
    private var contentSize: CGSize = .zero
    
    override init() {
        super.init()
        
        actions = CALayer.disableAnimationActions
        
        allowsFontSubpixelQuantization = true
        contentsScale = UIScreen.main.scale
    }
    
    func setup(keyCap: KeyCap?, hintText: String) {
        string = hintText.toHKAttributedString(withFont: font as? UIFont ?? .systemFont(ofSize: fontSize), withForegroundColor: foregroundColor.map { UIColor(cgColor: $0) })
    }
    
    override init(layer: Any) {
        super.init(layer: layer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("Not supported.")
    }
    
    override var font: CFTypeRef? {
        didSet {
            guard let font = font as? UIFont else { return }
            addAttributeToString(.font, font)
        }
    }
    
    override var fontSize: CGFloat {
        didSet {
            let newFont: UIFont
            if let font = font as? UIFont {
                newFont = font.withSize(fontSize)
            } else {
                newFont = .systemFont(ofSize: fontSize)
            }
            addAttributeToString(.font, newFont)
        }
    }
    
    override var foregroundColor: CGColor? {
        didSet {
            guard let foregroundColor = foregroundColor else { return }
            addAttributeToString(.foregroundColor, UIColor(cgColor: foregroundColor))
        }
    }
    
    private func addAttributeToString(_ attribute: NSAttributedString.Key, _ value: Any) {
        guard let attributedString = string as? NSAttributedString else { return }
        let mutableAttributedString = NSMutableAttributedString(attributedString: attributedString)
        mutableAttributedString.addAttribute(attribute, value: value, range: NSMakeRange(0, attributedString.length))
        string = mutableAttributedString
    }
}
