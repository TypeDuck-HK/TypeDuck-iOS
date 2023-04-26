//
//  FilterBarCell.swift
//  CantoboardFramework
//
//  Created by Alex Man on 4/25/23.
//

import Foundation
import UIKit
import CocoaLumberjackSwift

class FilterBarCell: UICollectionViewCell {
    static var reuseId: String = "FilterBarCell"
    
    private static let margin = UIEdgeInsets(top: 3, left: 8, bottom: 0, right: 8)
    private static let fontSizePerHeight: CGFloat = 18 / "＠".size(withFont: UIFont.systemFont(ofSize: 20)).height
    
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
    
    // Uncomment this to debug memory leak.
    private let c = InstanceCounter<FilterBarCell>()
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
    }
    
    func setup(_ text: String) {
        if label == nil {
            let label = UILabel()
            label.textAlignment = .center
            label.baselineAdjustment = .alignBaselines
            label.isUserInteractionEnabled = false

            self.contentView.addSubview(label)
            self.label = label
        }
        label?.attributedText = text.toHKAttributedString
        layout(bounds)
    }
    
    func free() {
        label?.text = nil
        label?.removeFromSuperview()
        label = nil
        
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
    }
    
    private func layout(_ bounds: CGRect) {
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
    
    static func computeCellSize(cellHeight: CGFloat, candidateText: String) -> CGSize {
        let fontSizeScale = Settings.cached.candidateFontSize.scale
        
        let candidateLabelHeight = cellHeight * 0.7
        let candidateFontSizeUnrounded = candidateLabelHeight * Self.fontSizePerHeight * fontSizeScale
        let candidateFontSize = candidateFontSizeUnrounded.roundTo(q: 4)
        
        let cellWidth = CandidateCell.estimateStringWidth(candidateText, ofSize: candidateFontSize)
        return Self.margin.wrap(widthOnly: CGSize(width: cellWidth, height: cellHeight))
    }
}
