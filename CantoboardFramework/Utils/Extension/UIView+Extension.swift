//
//  UIView+Extension.swift
//  CantoboardFramework
//
//  Created by Alex Man on 8/27/21.
//

import Foundation
import UIKit

internal extension UIView {
    func layout(textLayer: CATextLayer, atTopLeftCornerWithInsets insets: UIEdgeInsets) {
        guard !textLayer.isHidden,
              let superlayerBounds = textLayer.superlayer?.bounds
            else { return }
        
        let size = setupFontAndTextLayerSize(textLayer: textLayer, superlayerBounds: superlayerBounds)
        
        textLayer.alignmentMode = .left
        textLayer.frame = CGRect(origin: CGPoint(x: insets.left, y: insets.top), size: size)
    }
    
    func layout(textLayer: CATextLayer, atTopRightCornerWithInsets insets: UIEdgeInsets, heightRatio: CGFloat = KeyHintLayer.recommendedHeightRatio) {
        guard !textLayer.isHidden,
              let superlayerBounds = textLayer.superlayer?.bounds
            else { return }
        
        let size = setupFontAndTextLayerSize(textLayer: textLayer, superlayerBounds: superlayerBounds, heightRatio: heightRatio)
        
        textLayer.alignmentMode = .right
        textLayer.frame = CGRect(origin: CGPoint(x: superlayerBounds.width - size.width - insets.right, y: insets.top), size: size)
    }
    
    func layout(textLayer: CATextLayer, atBottomCenterWithInsets insets: UIEdgeInsets) {
        guard !textLayer.isHidden,
              let superlayerBounds = textLayer.superlayer?.bounds
            else { return }
        
        let size = setupFontAndTextLayerSize(textLayer: textLayer, superlayerBounds: superlayerBounds, minHeight: 5)
        
        textLayer.alignmentMode = .center
        textLayer.frame = CGRect(origin: CGPoint(x: 0, y: superlayerBounds.height - size.height - insets.bottom), size: size)
    }
    
    private func setupFontAndTextLayerSize(textLayer: CATextLayer, superlayerBounds: CGRect, minHeight: CGFloat = 10, heightRatio: CGFloat = KeyHintLayer.recommendedHeightRatio) -> CGSize {
        guard let attributedString = textLayer.string as? NSAttributedString else { return .zero }
        // let wightAdjustmentRatio: CGFloat = UIScreen.main.bounds.size.isPortrait && bounds ? 1 : 1.25
        var height = superlayerBounds.height * heightRatio // * wightAdjustmentRatio
        height = max(height, minHeight)
        
        let hasFullWidthChar = attributedString.string.contains(where: { $0.isChineseChar })
        let fullWidthMultipler = hasFullWidthChar ? 0.8 : 1
        
        let font = UIFont.systemFont(ofSize: KeyHintLayer.fontSizePerHeight * height * fullWidthMultipler)
        let mutableAttributedString = NSMutableAttributedString(attributedString: attributedString)
        mutableAttributedString.addAttribute(.font, value: font, range: NSMakeRange(0, attributedString.length))
        textLayer.string = mutableAttributedString
        return attributedString.string.size(withFont: font).with(newWidth: superlayerBounds.width)
    }
    
    func layout(textLayer: CATextLayer, centeredWithYOffset yOffset: CGFloat, height: CGFloat) {
        guard !textLayer.isHidden,
              let superlayerBounds = textLayer.superlayer?.bounds
            else { return }
        
        textLayer.fontSize = KeyHintLayer.fontSizePerHeight * height
        textLayer.alignmentMode = .center
        
        let size = CGSize(width: superlayerBounds.width, height: height)
        
        textLayer.frame = CGRect(origin: CGPoint(x: 0, y: yOffset), size: size)
    }
    
    func layout(textLayer: CATextLayer, centeredWithYOffset yOffset: CGFloat) {
        guard !textLayer.isHidden,
              let superlayerBounds = textLayer.superlayer?.bounds
            else { return }
        
        textLayer.alignmentMode = .center
        textLayer.frame = CGRect(origin: CGPoint(x: 0, y: yOffset), size: superlayerBounds.size)
    }
    
    func findElement<T: UIResponder>(_ type: T.Type) -> T? {
        var responder = next
        while let curr = responder, !(curr is T) {
            responder = curr.next
        }
        return responder as? T
    }
}
