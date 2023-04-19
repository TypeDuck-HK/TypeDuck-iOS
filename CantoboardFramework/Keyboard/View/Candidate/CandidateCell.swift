//
//  CandidateCell.swift
//  CantoboardFramework
//
//  Created by Alex Man on 8/25/21.
//

import Foundation
import UIKit
import CocoaLumberjackSwift

class CandidateCell: UICollectionViewCell {
    static var reuseId: String = "CandidateCell"
    
    private static let margin = UIEdgeInsets(top: 3, left: 8, bottom: 0, right: 8)
    private static let fontSizePerHeight: CGFloat = 18 / "＠".size(withFont: UIFont.systemFont(ofSize: 20)).height
    
    var showRomanization: Bool = false
    var isFilterCell: Bool = false
    override var isSelected: Bool {
        didSet {
            if isSelected {
                if selectedRectLayer == nil {
                    let selectedRectLayer = CALayer()
                    selectedRectLayer.backgroundColor = ButtonColor.inputKeyBackgroundColor.resolvedColor(with: traitCollection).cgColor
                    selectedRectLayer.cornerRadius = 5
                    selectedRectLayer.zPosition = -1
                    layer.addSublayer(selectedRectLayer)
                    self.selectedRectLayer = selectedRectLayer
                    setNeedsLayout()
                }
            } else {
                selectedRectLayer?.removeFromSuperlayer()
                selectedRectLayer = nil
            }
        }
    }
    
    weak var label: UILabel?
    weak var keyHintLayer: KeyHintLayer?
    weak var romanizationLayer: CATextLayer?
    weak var translationLayer: CATextLayer?
    weak var commentLayer: CATextLayer?
    weak var selectedRectLayer: CALayer?
    
    var info: CandidateCellInfo?
    
    // Uncomment this to debug memory leak.
    private let c = InstanceCounter<CandidateCell>()
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
    }
    
    func setup(_ text: String, _ comment: String?, showRomanization: Bool) {
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
                if romanizationLayer == nil {
                    let romanizationLayer = CATextLayer()
                    self.romanizationLayer = romanizationLayer
                    layer.addSublayer(romanizationLayer)
                    romanizationLayer.alignmentMode = .center
                    romanizationLayer.allowsFontSubpixelQuantization = true
                    romanizationLayer.contentsScale = UIScreen.main.scale
                    romanizationLayer.foregroundColor = labelColor
                    romanizationLayer.font = font
                }
                romanizationLayer?.string = jyutping
            } else {
                romanizationLayer?.removeFromSuperlayer()
                romanizationLayer = nil
            }
            
            if let mainLanguage = info.mainLanguage {
                if translationLayer == nil {
                    let translationLayer = CATextLayer()
                    self.translationLayer = translationLayer
                    layer.addSublayer(translationLayer)
                    translationLayer.alignmentMode = .center
                    translationLayer.allowsFontSubpixelQuantization = true
                    translationLayer.contentsScale = UIScreen.main.scale
                    translationLayer.foregroundColor = labelColor
                    translationLayer.font = font
                    translationLayer.truncationMode = .end
                }
                translationLayer?.string = mainLanguage
            } else {
                translationLayer?.removeFromSuperlayer()
                translationLayer = nil
            }
        }
        
        layout(bounds)
    }
    
    func free() {
        label?.text = nil
        label?.removeFromSuperview()
        label = nil
        
        keyHintLayer?.removeFromSuperlayer()
        keyHintLayer = nil
        
        romanizationLayer?.removeFromSuperlayer()
        romanizationLayer = nil
        
        translationLayer?.removeFromSuperlayer()
        translationLayer = nil
        
        commentLayer?.removeFromSuperlayer()
        commentLayer = nil
        
        selectedRectLayer?.removeFromSuperlayer()
        selectedRectLayer = nil
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        layout(layoutAttributes.bounds)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if let selectedRectLayer = selectedRectLayer {
            selectedRectLayer.frame = bounds.insetBy(dx: 4, dy: 4)
        }
        
        guard let keyHintLayer = keyHintLayer else { return }
        layout(textLayer: keyHintLayer, atTopRightCornerWithInsets: KeyHintLayer.hintInsets)
    }
    
    private func layout(_ bounds: CGRect) {
        guard let label = label else { return }
        
        let margin = Self.margin
        let availableHeight = bounds.height - margin.top - margin.bottom
        let availableWidth = bounds.width - margin.left - margin.right
        let fontSizeScale = Settings.cached.candidateFontSize.scale
        
        if showRomanization {
            let candidateLabelHeight = availableHeight * (isFilterCell ? 0.7 : 0.5)
            let candidateFontSize = candidateLabelHeight * Self.fontSizePerHeight
            
            label.font = .systemFont(ofSize: candidateFontSize * fontSizeScale)
            
            let candidateCommentHeight = availableHeight * 0.25
            let candidateCommentFontSize = candidateCommentHeight * Self.fontSizePerHeight
            
            romanizationLayer?.fontSize = candidateCommentFontSize
            translationLayer?.fontSize = candidateCommentFontSize
            
            let romanizationFrame = CGRect(x: margin.left, y: margin.top, width: availableWidth, height: candidateCommentHeight)
            let textFrame = CGRect(x: margin.left, y: romanizationFrame.maxY, width: availableWidth, height: candidateLabelHeight)
            let translationFrame = CGRect(x: margin.left, y: textFrame.maxY, width: availableWidth, height: candidateCommentHeight)
            
            romanizationLayer?.frame = romanizationFrame
            label.frame = textFrame
            translationLayer?.frame = translationFrame
            
        } else {
            let candidateLabelHeight = availableHeight * (isFilterCell ? 0.7 : 0.6)
            let candidateFontSize = candidateLabelHeight * Self.fontSizePerHeight
            
            label.font = .systemFont(ofSize: candidateFontSize * fontSizeScale)
            
            let candidateCommentHeight = availableHeight * 0.3
            let candidateCommentFontSize = candidateCommentHeight * Self.fontSizePerHeight
            let translationTopPadding = availableHeight * 0.03
            
            translationLayer?.fontSize = candidateCommentFontSize
            
            let textFrame = CGRect(x: margin.left, y: margin.top, width: availableWidth, height: candidateLabelHeight)
            let translationFrame = CGRect(x: margin.left, y: textFrame.maxY + translationTopPadding, width: availableWidth, height: candidateCommentHeight)
            
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
        commentLayer?.foregroundColor = labelColor
        selectedRectLayer?.backgroundColor = ButtonColor.inputKeyBackgroundColor.resolvedColor(with: traitCollection).cgColor
    }
    
    private static var unitFontWidthCache: [CGFloat:(halfWidths: [CGFloat], fullWidth: CGFloat)] = [:]
    
    static func computeCellSize(cellHeight: CGFloat, minWidth: CGFloat, candidateText: String, comment: String?, showRomanization: Bool) -> CGSize {
        let fontSizeScale = Settings.cached.candidateFontSize.scale
        
        let candidateLabelHeight = cellHeight * (showRomanization ? 0.5 : 0.6)
        let candidateFontSizeUnrounded = candidateLabelHeight * Self.fontSizePerHeight * fontSizeScale
        let candidateFontSize = candidateFontSizeUnrounded.roundTo(q: 4)
        
        var cellWidth = estimateStringWidth(candidateText, ofSize: candidateFontSize)
        
        if let comment = comment {
            let info = CandidateCellInfo(fromCSV: comment)
            
            if showRomanization, let jyutping = info.jyutping {
                let candidateCommentHeight = cellHeight * 0.25
                let candidateCommentFontSizeUnrounded = candidateCommentHeight * Self.fontSizePerHeight
                let candidateCommentFontSize = candidateCommentFontSizeUnrounded.roundTo(q: 4)
                
                let commentWidth = estimateStringWidth(jyutping, ofSize: candidateCommentFontSize)
                cellWidth = max(cellWidth, commentWidth)
            }
            
            if let mainLanguage = info.mainLanguage {
                let candidateCommentHeight = cellHeight * (showRomanization ? 0.25 : 0.3)
                let candidateCommentFontSizeUnrounded = candidateCommentHeight * Self.fontSizePerHeight
                let candidateCommentFontSize = candidateCommentFontSizeUnrounded.roundTo(q: 4)
                
                let commentWidth = Settings.cached.languageState.main.isLatin ?
                    estimateStringWidth(mainLanguage, ofSize: candidateCommentFontSize) :
                    mainLanguage.size(withFont: UIFont.systemFont(ofSize: candidateCommentFontSize)).width
                cellWidth = max(cellWidth, min(cellWidth + 70, commentWidth))
            }
        }
        
        return Self.margin.wrap(widthOnly: CGSize(width: cellWidth, height: cellHeight)).with(minWidth: minWidth)
    }
    
    static func estimateStringWidth(_ s: String, ofSize fontSize: CGFloat) -> CGFloat {
        var unitWidth = unitFontWidthCache[fontSize]
        if unitWidth == nil {
            var halfWidths = Array(repeating: CGFloat.zero, count: 256)
            for b in UInt8.min...UInt8.max {
                let c = Character(UnicodeScalar(b))
                halfWidths[Int(b)] = String(c).size(withFont: UIFont.systemFont(ofSize: fontSize)).width
            }
            let fullWidth = "　".size(withFont: UIFont.systemFont(ofSize: fontSize)).width
            unitWidth = (halfWidths: halfWidths, fullWidth: fullWidth)
            unitFontWidthCache[fontSize] = unitWidth
        }
        
        let estimate = s.reduce(CGFloat.zero, { r, c in
            if c.isASCII {
                return r + unitWidth!.halfWidths[Int(c.asciiValue!)]
            } else {
                return r + unitWidth!.fullWidth
            }
        })

        return estimate
    }
}
