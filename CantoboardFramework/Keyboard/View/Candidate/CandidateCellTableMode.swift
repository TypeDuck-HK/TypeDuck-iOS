//
//  CandidateCellTableMode.swift
//  CantoboardFramework
//
//  Created by Alex Man on 4/25/23.
//

import Foundation
import UIKit
import CocoaLumberjackSwift

class CandidateCellTableMode: CandidateCell, CandidateCellProtocol {
    static let reuseId: String = "CandidateCellTableMode"
    
    private static let paddingText: CGFloat = 10
    private static let paddingComment: CGFloat = 5
    
    weak var keyHintLayer: KeyHintLayer?
    weak var romanizationLayer: CATextLayer?
    weak var translationLayer: CATextLayer?
    var commentLayers: [Weak<CATextLayer>] = []
    
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
            let info = CandidateCellInfo(fromCSV: comment)
            self.info = info
            
            if showRomanization, let jyutping = info.jyutping {
                romanizationLayer ??= createAndAddTextLayer(color: labelColor, font: font, alignmentMode: .left)
                romanizationLayer?.string = jyutping
            } else {
                romanizationLayer?.removeFromSuperlayer()
                romanizationLayer = nil
            }
            
            if let mainLanguage = info.mainLanguage {
                translationLayer ??= createAndAddTextLayer(color: labelColor, font: font, alignmentMode: .left, truncationMode: .end)
                translationLayer?.string = mainLanguage
            } else {
                translationLayer?.removeFromSuperlayer()
                translationLayer = nil
            }
            
            for (i, language) in info.otherLanguages.enumerated() {
                commentLayers[weak: i] ??= createAndAddTextLayer(color: labelColor, font: font, alignmentMode: .left, truncationMode: .end)
                commentLayers[i].ref?.string = language
            }
            if info.otherLanguages.endIndex > commentLayers.endIndex {
                for i in info.otherLanguages.endIndex..<commentLayers.endIndex {
                    commentLayers[i].ref?.removeFromSuperlayer()
                    commentLayers[i].ref = nil
                }
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
        
        for commentLayer in commentLayers {
            commentLayer.ref?.removeFromSuperlayer()
            commentLayer.ref = nil
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        guard let keyHintLayer = keyHintLayer else { return }
        layout(textLayer: keyHintLayer, atTopRightCornerWithInsets: KeyHintLayer.hintInsets)
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
        
        romanizationLayer?.font = commentFont
        label.font = labelFont
        translationLayer?.font = labelFont
        
        let labelWidth = Self.estimateStringWidth(text, ofSize: candidateFontSize)
        var labelY: CGFloat
        
        if showRomanization {
            let romanizationFrame = CGRect(x: margin.left, y: margin.top, width: availableWidth, height: candidateCommentHeight)
            let textFrame = CGRect(x: margin.left, y: romanizationFrame.maxY, width: labelWidth, height: candidateLabelHeight)
            let translationFrame = CGRect(x: margin.left + labelWidth + Self.paddingText, y: romanizationFrame.maxY, width: availableWidth - labelWidth - Self.paddingText, height: candidateLabelHeight)
            labelY = textFrame.maxY
            
            romanizationLayer?.frame = romanizationFrame
            label.frame = textFrame
            translationLayer?.frame = translationFrame
            
        } else {
            let textFrame = CGRect(x: margin.left, y: margin.top, width: availableWidth, height: candidateLabelHeight)
            let translationFrame = CGRect(x: margin.left + labelWidth + Self.paddingText, y: margin.top, width: availableWidth - labelWidth - Self.paddingText, height: candidateLabelHeight)
            labelY = textFrame.maxY + availableHeight * 0.03
            
            label.frame = textFrame
            translationLayer?.frame = translationFrame
        }
        
        if let otherLanguages = info?.otherLanguages, !otherLanguages.isEmpty {
            let widths = otherLanguages.map { Self.estimateStringWidth($0, ofSize: candidateCommentFontSize) }
            let totalWidth = widths.reduce(CGFloat.zero) { $0 + $1 }
            let widthRatio = min(1, (availableWidth - Self.paddingComment * CGFloat(otherLanguages.count - 1)) / totalWidth)
            
            var x = margin.left - Self.paddingComment
            for (comment, width) in zip(commentLayers, widths) {
                x += Self.paddingComment
                let width = width * widthRatio
                comment.ref?.font = commentFont
                comment.ref?.frame = CGRect(x: x, y: labelY, width: width, height: candidateLabelHeight)
                x += width
            }
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        let labelColor = label?.textColor.resolvedColor(with: traitCollection).cgColor
        keyHintLayer?.foregroundColor = labelColor
        romanizationLayer?.foregroundColor = labelColor
        translationLayer?.foregroundColor = labelColor
        for commentLayer in commentLayers {
            commentLayer.ref?.foregroundColor = labelColor
        }
    }
    
    static func computeCellSize(cellHeight: CGFloat, candidateText: String, info: CandidateCellInfo?, showRomanization: Bool) -> CGSize {
        let fontSizeScale = Settings.cached.candidateFontSize.scale
        
        let candidateLabelHeight = cellHeight * (showRomanization ? 0.5 : 0.6)
        let candidateFontSizeUnrounded = candidateLabelHeight * Self.fontSizePerHeight * fontSizeScale
        let candidateFontSize = candidateFontSizeUnrounded.roundTo(q: 4)
        
        var cellWidth = Self.estimateStringWidth(candidateText, ofSize: candidateFontSize)
        
        if let info = info {
            if let mainLanguage = info.mainLanguage {
                cellWidth += Self.paddingText + mainLanguage.size(withFont: UIFont.systemFont(ofSize: candidateFontSize)).width
            }
            
            let candidateCommentHeight = cellHeight * (showRomanization ? 0.25 : 0.3)
            let candidateCommentFontSizeUnrounded = candidateCommentHeight * Self.fontSizePerHeight
            let candidateCommentFontSize = candidateCommentFontSizeUnrounded.roundTo(q: 4)
            
            if showRomanization, let jyutping = info.jyutping {
                let commentWidth = Self.estimateStringWidth(jyutping, ofSize: candidateCommentFontSize)
                cellWidth = max(cellWidth, commentWidth)
            }
            
            if !info.otherLanguages.isEmpty {
                let commentWidth = info.otherLanguages.reduce(-Self.paddingComment) { sum, language in
                    sum + Self.paddingComment + language.size(withFont: UIFont.systemFont(ofSize: candidateCommentFontSize)).width
                }
                cellWidth = max(cellWidth, commentWidth)
            }
        }
        
        return Self.margin.wrap(widthOnly: CGSize(width: cellWidth, height: cellHeight))
    }
}
