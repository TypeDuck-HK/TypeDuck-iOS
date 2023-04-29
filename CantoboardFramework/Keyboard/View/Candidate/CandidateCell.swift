//
//  CandidateCell.swift
//  CantoboardFramework
//
//  Created by Alex Man on 8/25/21.
//

import Foundation
import UIKit
import CocoaLumberjackSwift

protocol CandidateCellProtocol: CandidateCell {
    static var reuseId: String { get }
    func setup(_ text: String, _ comment: String?, showRomanization: Bool)
    static func computeCellSize(cellHeight: CGFloat, candidateInfo info: CandidateCellInfo, showRomanization: Bool) -> CGSize
}

class CandidateCell: UICollectionViewCell {
    internal static let margin = UIEdgeInsets(top: 3, left: 8, bottom: 0, right: 8)
    internal static let fontSizePerHeight: CGFloat = 18 / "＠".size(withFont: UIFont.systemFont(ofSize: 20)).height
    
    var text: String = ""
    var showRomanization: Bool = false
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
    weak var selectedRectLayer: CALayer?
    weak var iconLayer: CALayer?
    
    private static let infoImage = ButtonImage.info.cgImage
    
    // Uncomment this to debug memory leak.
    private let c = InstanceCounter<CandidateCell>()
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
    }
    
    internal final func createAndAddTextLayer(color: CGColor?, font: UIFont?, alignmentMode: CATextLayerAlignmentMode = .center, truncationMode: CATextLayerTruncationMode = .none) -> CATextLayer {
        let textLayer = CATextLayer()
        textLayer.alignmentMode = alignmentMode
        textLayer.allowsFontSubpixelQuantization = true
        textLayer.contentsScale = UIScreen.main.scale
        textLayer.foregroundColor = color
        textLayer.font = font
        textLayer.truncationMode = truncationMode
        layer.addSublayer(textLayer)
        return textLayer
    }
    
    internal final func createAndAddIconLayer() {
        let iconLayer = CALayer()
        iconLayer.contents = Self.infoImage
        iconLayer.contentsGravity = .resizeAspect
        layer.addSublayer(iconLayer)
        self.iconLayer = iconLayer
    }
    
    func free() {
        label?.text = nil
        label?.removeFromSuperview()
        label = nil
        
        selectedRectLayer?.removeFromSuperlayer()
        selectedRectLayer = nil
        
        iconLayer?.removeFromSuperlayer()
        iconLayer = nil
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
    }
    
    internal func layout(_ bounds: CGRect) {
        guard let label = label else { return }
        
        let margin = Self.margin
        let availableHeight = bounds.height - margin.top - margin.bottom
        let availableWidth = bounds.width - margin.left - margin.right
        let fontSizeScale = Settings.cached.candidateFontSize.scale
        
        let candidateLabelHeight = availableHeight * 0.7
        let candidateFontSize = candidateLabelHeight * Self.fontSizePerHeight
        
        label.font = .systemFont(ofSize: candidateFontSize * fontSizeScale)
        label.frame = CGRect(x: margin.left, y: margin.top, width: availableWidth, height: candidateLabelHeight)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        selectedRectLayer?.backgroundColor = ButtonColor.inputKeyBackgroundColor.resolvedColor(with: traitCollection).cgColor
    }
}

extension CandidateCell {
    private static var unitFontWidthCache: [CGFloat: (halfWidths: [UInt8: CGFloat], fullWidth: CGFloat)] = [:]
    
    internal static func estimateStringWidth(_ s: String, ofSize fontSize: CGFloat) -> CGFloat {
        var unitWidth = unitFontWidthCache[fontSize]
        if unitWidth == nil {
            let halfWidths = Dictionary(uniqueKeysWithValues: (32...126).map {
                ($0, String(UnicodeScalar($0)).size(withFont: UIFont.systemFont(ofSize: fontSize)).width)
            })
            let fullWidth = "　".size(withFont: UIFont.systemFont(ofSize: fontSize)).width
            unitWidth = (halfWidths: halfWidths, fullWidth: fullWidth)
            unitFontWidthCache[fontSize] = unitWidth
        }
        
        return s.reduce(CGFloat.zero) { r, c in
            if c.isASCII {
                return r + (unitWidth!.halfWidths[c.asciiValue!] ?? 0)
            } else {
                return r + unitWidth!.fullWidth
            }
        }
    }
}
