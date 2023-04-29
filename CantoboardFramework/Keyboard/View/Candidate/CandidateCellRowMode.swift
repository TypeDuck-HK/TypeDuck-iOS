//
//  CandidateCellRowMode.swift
//  CantoboardFramework
//
//  Created by Alex Man on 4/25/23.
//

import Foundation
import UIKit
import CocoaLumberjackSwift

class CandidateCellRowMode: CandidateCell, CandidateCellProtocol {
    static let reuseId: String = "CandidateCellRowMode"
    
    weak var keyHintLayer: KeyHintLayer?
    weak var romanizationLayer: CATextLayer?
    weak var translationLayer: CATextLayer?
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
    }
    
    func setup(_ text: String, _ comment: String?, showRomanization: Bool) {
        self.text = text
        self.showRomanization = showRomanization
        
        if label == nil {
            let label = UILabel()
            label.textAlignment = .center
            label.baselineAdjustment = .alignBaselines
            label.isUserInteractionEnabled = false

            self.contentView.addSubview(label)
            self.label = label
        }
        
        label?.attributedText = text.toHKAttributedString
        
        let labelColor = label?.textColor.resolvedColor(with: traitCollection).cgColor
        let font = UIFont.systemFont(ofSize: 10 /* ignored */)
        
        let keyCap = KeyCap(stringLiteral: text)
        if let hintText = keyCap.barHint {
            if keyHintLayer == nil {
                let keyHintLayer = KeyHintLayer()
                self.keyHintLayer = keyHintLayer
                layer.addSublayer(keyHintLayer)
                keyHintLayer.layoutSublayers()
                keyHintLayer.foregroundColor = labelColor
            }
            
            keyHintLayer?.setup(keyCap: keyCap, hintText: hintText)
        }
        
        if let comment = comment {
            let info = CandidateCellInfo(honzi: text, fromCSV: comment)
            self.info = info
            
            if showRomanization, let jyutping = info.jyutping {
                romanizationLayer ??= createAndAddTextLayer(color: labelColor, font: font)
                romanizationLayer?.string = jyutping
            } else {
                romanizationLayer?.removeFromSuperlayer()
                romanizationLayer = nil
            }
            
            if let mainLanguage = info.mainLanguage {
                translationLayer ??= createAndAddTextLayer(color: labelColor, font: font, truncationMode: .end)
                translationLayer?.string = mainLanguage
            } else {
                translationLayer?.removeFromSuperlayer()
                translationLayer = nil
            }
            
            if info.isDictionaryEntry {
                createAndAddIconLayer()
            } else {
                iconLayer?.removeFromSuperlayer()
                iconLayer = nil
            }
        }
        
        layout(bounds)
    }
    
    override func free() {
        super.free()
        
        keyHintLayer?.removeFromSuperlayer()
        keyHintLayer = nil
        
        romanizationLayer?.removeFromSuperlayer()
        romanizationLayer = nil
        
        translationLayer?.removeFromSuperlayer()
        translationLayer = nil
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if let keyHintLayer = keyHintLayer {
            layout(textLayer: keyHintLayer, atTopRightCornerWithInsets: KeyHintLayer.hintInsets)
        }
        if let iconLayer = iconLayer, !iconLayer.isHidden {
            let dimension = max(bounds.height * KeyHintLayer.recommendedHeightRatio, 10)
            iconLayer.frame = CGRect(x: bounds.width - dimension - KeyHintLayer.hintInsets.right, y: KeyHintLayer.hintInsets.top, width: dimension, height: dimension)
        }
    }
    
    override internal func layout(_ bounds: CGRect) {
        guard let label = label else { return }
        
        let margin = Self.margin
        let availableHeight = bounds.height - margin.top - margin.bottom
        let availableWidth = bounds.width - margin.left - margin.right
        let fontSizeScale = Settings.cached.candidateFontSize.scale
        
        let candidateLabelHeight = availableHeight * (showRomanization ? 0.5 : 0.6)
        let candidateFontSize = candidateLabelHeight * Self.fontSizePerHeight * fontSizeScale
        
        let candidateCommentHeight = availableHeight * (showRomanization ? 0.25 : 0.3)
        let candidateCommentFontSize = candidateCommentHeight * Self.fontSizePerHeight
        
        let labelFont = UIFont.systemFont(ofSize: candidateFontSize)
        let commentFont = UIFont.systemFont(ofSize: candidateCommentFontSize)
        
        label.font = labelFont
        romanizationLayer?.font = commentFont
        translationLayer?.font = commentFont
        
        if showRomanization {
            let romanizationFrame = CGRect(x: margin.left, y: margin.top, width: availableWidth, height: candidateCommentHeight)
            let textFrame = CGRect(x: margin.left, y: romanizationFrame.maxY, width: availableWidth, height: candidateLabelHeight)
            let translationFrame = CGRect(x: margin.left, y: textFrame.maxY, width: availableWidth, height: candidateCommentHeight)
            
            romanizationLayer?.frame = romanizationFrame
            label.frame = textFrame
            translationLayer?.frame = translationFrame
            
        } else {
            let textFrame = CGRect(x: margin.left, y: margin.top, width: availableWidth, height: candidateLabelHeight)
            let translationFrame = CGRect(x: margin.left, y: textFrame.maxY + availableHeight * 0.03, width: availableWidth, height: candidateCommentHeight)
            
            label.frame = textFrame
            translationLayer?.frame = translationFrame
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        let labelColor = label?.textColor.resolvedColor(with: traitCollection).cgColor
        keyHintLayer?.foregroundColor = labelColor
        romanizationLayer?.foregroundColor = labelColor
        translationLayer?.foregroundColor = labelColor
    }
    
    static func computeCellSize(cellHeight: CGFloat, candidateInfo info: CandidateCellInfo, showRomanization: Bool) -> CGSize {
        let fontSizeScale = Settings.cached.candidateFontSize.scale
        
        let candidateLabelHeight = cellHeight * (showRomanization ? 0.5 : 0.6)
        let candidateFontSizeUnrounded = candidateLabelHeight * Self.fontSizePerHeight * fontSizeScale
        let candidateFontSize = candidateFontSizeUnrounded.roundTo(q: 4)
        
        var cellWidth = Self.estimateStringWidth(info.honzi, ofSize: candidateFontSize)
        
        let candidateCommentHeight = cellHeight * (showRomanization ? 0.25 : 0.3)
        let candidateCommentFontSizeUnrounded = candidateCommentHeight * Self.fontSizePerHeight
        let candidateCommentFontSize = candidateCommentFontSizeUnrounded.roundTo(q: 4)
        
        if showRomanization, let jyutping = info.jyutping {
            let commentWidth = Self.estimateStringWidth(jyutping, ofSize: candidateCommentFontSize)
            cellWidth = max(cellWidth, commentWidth)
        }
        
        if let mainLanguage = info.mainLanguage {
            let commentWidth = mainLanguage.size(withFont: UIFont.systemFont(ofSize: candidateCommentFontSize)).width
            cellWidth = max(cellWidth, min(cellWidth + 70, commentWidth))
        }
        
        return Self.margin.wrap(widthOnly: CGSize(width: cellWidth, height: cellHeight))
    }
}
