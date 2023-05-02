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
    private static let paddingBetweenLanguages: CGFloat = 10
    
    var showRomanization: Bool = false
    var mode: CandidatePaneView.Mode = .row
    var isFilterCell: Bool = false
    var info: CandidateCellInfo?
    
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
    var commentLayers: [Weak<CATextLayer>] = []
    weak var selectedRectLayer: CALayer?
    
    // Uncomment this to debug memory leak.
    private let c = InstanceCounter<CandidateCell>()
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
    }
    
    func setup(_ text: String, _ comment: String?, showRomanization: Bool, mode: CandidatePaneView.Mode) {
        self.showRomanization = showRomanization
        self.mode = mode
        
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
            
            if mode == .table {
                for (i, language) in info.otherLanguages.enumerated() {
                    commentLayers[weak: i] ??= createAndAddTextLayer(color: labelColor, font: font, truncationMode: .end)
                    commentLayers[i].ref?.string = language
                }
                if info.otherLanguages.endIndex > commentLayers.endIndex {
                    for i in info.otherLanguages.endIndex..<commentLayers.endIndex {
                        commentLayers[i].ref?.removeFromSuperlayer()
                        commentLayers[i].ref = nil
                    }
                }
            }
        }
        
        layout(bounds)
    }
    
    private func createAndAddTextLayer(color: CGColor?, font: UIFont?, truncationMode: CATextLayerTruncationMode = .none) -> CATextLayer {
        let textLayer = CATextLayer()
        textLayer.alignmentMode = .center
        textLayer.allowsFontSubpixelQuantization = true
        textLayer.contentsScale = UIScreen.main.scale
        textLayer.foregroundColor = color
        textLayer.font = font
        textLayer.truncationMode = truncationMode
        layer.addSublayer(textLayer)
        return textLayer
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
        
        for commentLayer in commentLayers {
            commentLayer.ref?.removeFromSuperlayer()
            commentLayer.ref = nil
        }
        
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
            let candidateLabelHeight = availableHeight * 0.5 // assert(!isFilterCell)
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
        for commentLayer in commentLayers {
            commentLayer.ref?.foregroundColor = labelColor
        }
        selectedRectLayer?.backgroundColor = ButtonColor.inputKeyBackgroundColor.resolvedColor(with: traitCollection).cgColor
    }
    
    private static var unitFontWidthCache: [CGFloat: (halfWidths: [CGFloat], fullWidth: CGFloat)] = [:]
    
    static func computeCellSize(cellHeight: CGFloat, candidateInfo info: CandidateCellInfo, showRomanization: Bool, mode: CandidatePaneView.Mode) -> CGSize {
        let fontSizeScale = Settings.cached.candidateFontSize.scale
        
        let candidateLabelHeight = cellHeight * (showRomanization ? 0.5 : 0.6)
        let candidateFontSizeUnrounded = candidateLabelHeight * Self.fontSizePerHeight * fontSizeScale
        let candidateFontSize = candidateFontSizeUnrounded.roundTo(q: 4)
        
        var cellWidth = estimateStringWidth(info.honzi, ofSize: candidateFontSize)
        
        let candidateCommentHeight = cellHeight * (showRomanization ? 0.25 : 0.3)
        let candidateCommentFontSizeUnrounded = candidateCommentHeight * Self.fontSizePerHeight
        let candidateCommentFontSize = candidateCommentFontSizeUnrounded.roundTo(q: 4)
        
        if showRomanization, let jyutping = info.jyutping {
            let commentWidth = estimateStringWidth(jyutping, ofSize: candidateCommentFontSize)
            cellWidth = max(cellWidth, commentWidth)
        }
        
        if let mainLanguage = info.mainLanguage {
            let commentWidth = mainLanguage.size(withFont: UIFont.systemFont(ofSize: candidateCommentFontSize)).width
            cellWidth = max(cellWidth, min(cellWidth + 70, commentWidth))
        }
        
        return Self.margin.wrap(widthOnly: CGSize(width: cellWidth, height: cellHeight))
    }
    
    static func estimateStringWidth(_ s: String, ofSize fontSize: CGFloat) -> CGFloat {
        var unitWidth = unitFontWidthCache[fontSize]
        if unitWidth == nil {
            let halfWidths = (UInt8.min...UInt8.max).map {
                String(UnicodeScalar($0)).size(withFont: UIFont.systemFont(ofSize: fontSize)).width
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
