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
    private static let swipeDownIconAspectRatio: CGFloat = 2.8
    static let infoIconWidthRatio: CGFloat = 0.6
    private static let infoIconHeightRatio: CGFloat = 0.4
    private static let paddingText: CGFloat = 10
    private static let paddingComment: CGFloat = 8
    
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
    
    var infoIsHighlighted: Bool = false {
        didSet {
            infoImage?.image = infoIsHighlighted ? ButtonImage.infoFilled : ButtonImage.info
        }
    }
    
    var infoImageFrame: CGRect {
        CGRect(x: frame.maxX, y: frame.minY, width: frame.height * Self.infoIconWidthRatio, height: frame.height)
    }
    
    weak var mainStack, textStack, commentStack: SidedStackView?
    weak var label: UILabel?
    weak var keyHintLayer: KeyHintLayer?
    weak var romanizationLabel: UILabel?
    weak var translationLabel: UILabel?
    var commentLabels: [Weak<UILabel>] = []
    weak var selectedRectLayer: CALayer?
    weak var infoImage, chevronImage: UIImageView?
    
    // Uncomment this to debug memory leak.
    private let c = InstanceCounter<CandidateCell>()
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
    }
    
    func setup(_ text: String, _ comment: String?, showRomanization: Bool, mode: CandidatePaneView.Mode) {
        self.showRomanization = showRomanization
        self.mode = mode
        
        let mainStack, textStack, commentStack: SidedStackView?
        
        if let oldMainStack = self.mainStack {
            for view in oldMainStack.arrangedSubviews {
                oldMainStack.removeArrangedSubview(view)
            }
            mainStack = oldMainStack
        } else {
            mainStack = SidedStackView(axis: .vertical)
            contentView.addSubview(mainStack!)
            NSLayoutConstraint.activate([
                mainStack!.topAnchor.constraint(equalTo: topAnchor, constant: Self.margin.top),
                bottomAnchor.constraint(equalTo: mainStack!.bottomAnchor, constant: Self.margin.bottom),
                mainStack!.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Self.margin.left),
                trailingAnchor.constraint(equalTo: mainStack!.trailingAnchor, constant: Self.margin.right),
            ])
            self.mainStack = mainStack
        }
        
        if let oldTextStack = self.textStack {
            for view in oldTextStack.arrangedSubviews {
                oldTextStack.removeArrangedSubview(view)
            }
            textStack = oldTextStack
        } else if mode == .table {
            textStack = SidedStackView(spacing: Self.paddingText, alignment: .firstBaseline)
            self.textStack = textStack
        } else {
            textStack = self.textStack
        }
        
        if let oldCommentStack = self.commentStack {
            for view in oldCommentStack.arrangedSubviews {
                oldCommentStack.removeArrangedSubview(view)
            }
            commentStack = oldCommentStack
        } else if mode == .table {
            commentStack = SidedStackView(spacing: Self.paddingComment, alignment: .firstBaseline)
            self.commentStack = commentStack
        } else {
            commentStack = self.commentStack
        }
        
        if mode == .row {
            self.textStack?.removeFromSuperview()
            self.textStack = nil
            
            self.commentStack?.removeFromSuperview()
            self.commentStack = nil
        }
        
        let label = self.label ?? UILabel()
        label.textAlignment = mode == .row ? .center : .left
        label.attributedText = text.toHKAttributedString
        self.label = label
        
        let keyCap = KeyCap(stringLiteral: text)
        if let hintText = keyCap.barHint {
            if keyHintLayer == nil {
                let keyHintLayer = KeyHintLayer()
                keyHintLayer.layoutSublayers()
                keyHintLayer.foregroundColor = label.textColor.resolvedColor(with: traitCollection).cgColor
                layer.addSublayer(keyHintLayer)
                self.keyHintLayer = keyHintLayer
            }
            self.keyHintLayer?.setup(keyCap: keyCap, hintText: hintText)
        }
        
        if let comment = comment {
            let info = CandidateCellInfo(honzi: text, fromCSV: comment)
            self.info = info
            
            if showRomanization, let jyutping = info.jyutping {
                let romanizationLabel = self.romanizationLabel ?? UILabel()
                romanizationLabel.textAlignment = mode == .row ? .center : .left
                romanizationLabel.text = jyutping
                mainStack!.addArrangedSubview(romanizationLabel)
                self.romanizationLabel = romanizationLabel
            } else {
                self.romanizationLabel?.text = nil
                self.romanizationLabel?.removeFromSuperview()
                self.romanizationLabel = nil
            }
            
            let targetStack = mode == .row ? mainStack : textStack
            targetStack!.addArrangedSubview(label)
            
            if let mainLanguage = info.mainLanguage {
                let translationLabel = self.translationLabel ?? UILabel()
                translationLabel.textAlignment = mode == .row ? .center : .left
                translationLabel.text = mainLanguage
                targetStack!.addArrangedSubview(translationLabel)
                self.translationLabel = translationLabel
            } else {
                self.translationLabel?.text = nil
                self.translationLabel?.removeFromSuperview()
                self.translationLabel = nil
            }
            
            if mode == .table {
                let otherLanguages = info.otherLanguages
                for (i, language) in otherLanguages.enumerated() {
                    let commentLabel = self.commentLabels[weak: i] ?? UILabel()
                    commentLabel.textAlignment = .left
                    commentLabel.text = language
                    commentStack!.addArrangedSubview(commentLabel)
                    self.commentLabels[weak: i] = commentLabel
                }
                if otherLanguages.endIndex > self.commentLabels.endIndex {
                    for i in otherLanguages.endIndex..<self.commentLabels.endIndex {
                        self.commentLabels[i].ref?.removeFromSuperview()
                        self.commentLabels[i].ref = nil
                    }
                    self.commentLabels.removeLast(self.commentLabels.endIndex - otherLanguages.endIndex)
                }
                
                mainStack!.addArrangedSubview(textStack!)
                if !otherLanguages.isEmpty {
                    mainStack!.addArrangedSubview(commentStack!)
                }
            } else {
                for commentLabel in self.commentLabels {
                    commentLabel.ref?.text = nil
                    commentLabel.ref?.removeFromSuperview()
                    commentLabel.ref = nil
                }
                self.commentLabels.removeAll()
            }
            mainStack!.isSpaced = true
        } else {
            self.info = nil
            label.textAlignment = .center
            
            mainStack!.addArrangedSubview(label)
            mainStack!.isSpaced = false
            let spacer = UIView()
            spacer.heightAnchor.constraint(equalToConstant: 4).isActive = true
            mainStack!.addArrangedSubview(spacer)
        }
        
        let isDictionaryEntry = self.info?.isDictionaryEntry ?? false

        if isDictionaryEntry {
            let infoImage = self.infoImage ?? UIImageView()
            infoImage.image = ButtonImage.info
            infoImage.tintColor = label.textColor
            contentView.addSubview(infoImage)
            self.infoImage = infoImage
            
            if mode == .row {
                let chevronImage = self.chevronImage ?? UIImageView()
                chevronImage.image = ButtonImage.swipeDown
                chevronImage.tintColor = label.textColor
                contentView.addSubview(chevronImage)
                self.chevronImage = chevronImage
            }
        } else {
            self.infoImage?.image = nil
            self.infoImage?.removeFromSuperview()
            self.infoImage = nil
        }
        if mode == .table || !isDictionaryEntry {
            self.chevronImage?.image = nil
            self.chevronImage?.removeFromSuperview()
            self.chevronImage = nil
        }
        
        layout(bounds)
    }
    
    func free() {
        textStack?.arrangedSubviews.forEach { view in
            mainStack?.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        
        commentStack?.arrangedSubviews.forEach { view in
            mainStack?.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        
        mainStack?.arrangedSubviews.forEach { view in
            mainStack?.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        
        label?.text = nil
        label = nil
        
        keyHintLayer?.removeFromSuperlayer()
        keyHintLayer = nil
        
        romanizationLabel?.text = nil
        romanizationLabel = nil
        
        translationLabel?.text = nil
        translationLabel = nil
        
        for commentLabel in commentLabels {
            commentLabel.ref?.text = nil
            commentLabel.ref = nil
        }
        commentLabels.removeAll()
        
        selectedRectLayer?.removeFromSuperlayer()
        selectedRectLayer = nil
        
        infoImage?.image = nil
        infoImage?.removeFromSuperview()
        infoImage = nil
        
        chevronImage?.image = nil
        chevronImage?.removeFromSuperview()
        chevronImage = nil
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        layout(layoutAttributes.bounds)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if info?.isDictionaryEntry ?? false {
            if mode == .row {
                let dimension = bounds.height * KeyHintLayer.recommendedHeightRatio
                let x = bounds.width - Self.margin.right
                infoImage?.frame = CGRect(x: x, y: Self.margin.top, width: dimension, height: dimension)
                let width = dimension - 1.75
                let height = width / Self.swipeDownIconAspectRatio
                chevronImage?.frame = CGRect(x: x + 0.875, y: Self.margin.top + dimension - 0.75, width: width, height: height)
            } else {
                let x = bounds.width - Self.margin.right + (Self.infoIconWidthRatio - Self.infoIconHeightRatio) * bounds.height / 2
                let y = (1 - Self.infoIconHeightRatio) * bounds.height / 2
                let dimension = bounds.height * Self.infoIconHeightRatio
                infoImage?.frame = CGRect(x: x, y: y, width: dimension, height: dimension)
            }
        }
        
        if let selectedRectLayer = selectedRectLayer {
            var bounds = bounds
            if info?.isDictionaryEntry ?? false {
                bounds = bounds.insetBy(dx: 4, dy: 0)
                if mode == .row {
                    bounds.size.width += bounds.height * KeyHintLayer.recommendedHeightRatio - 2
                } else {
                    bounds.size.width -= 4
                }
            } else if keyHintLayer == nil {
                bounds = bounds.insetBy(dx: 4, dy: info == nil ? 4 : 0)
            }
            selectedRectLayer.frame = bounds
        }
        
        guard let keyHintLayer = keyHintLayer else { return }
        layout(textLayer: keyHintLayer, atTopRightCornerWithInsets: KeyHintLayer.hintInsets)
    }
    
    private func layout(_ bounds: CGRect) {
        let availableHeight = bounds.height - Self.margin.top - Self.margin.bottom
        
        let candidateTextHeight = availableHeight * (isFilterCell ? 0.7 : showRomanization ? 0.5 : 0.6)
        let candidateTextFont = UIFont.systemFont(ofSize: candidateTextHeight * Self.fontSizePerHeight)
        
        let candidateCommentHeight = availableHeight * (showRomanization ? 0.25 : 0.3)
        let candidateCommentFont = UIFont.systemFont(ofSize: candidateCommentHeight * Self.fontSizePerHeight)
        
        label?.font = candidateTextFont
        romanizationLabel?.font = candidateCommentFont
        translationLabel?.font = mode == .row ? candidateCommentFont : candidateTextFont
        
        for commentLabel in commentLabels {
            commentLabel.ref?.font = candidateCommentFont
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        keyHintLayer?.foregroundColor = label?.textColor.resolvedColor(with: traitCollection).cgColor
        selectedRectLayer?.backgroundColor = ButtonColor.inputKeyBackgroundColor.resolvedColor(with: traitCollection).cgColor
    }
    
    private static var unitFontWidthCache: [CGFloat: (halfWidths: [CGFloat], fullWidth: CGFloat)] = [:]
    
    static func computeCellSize(cellHeight: CGFloat, candidateInfo info: CandidateCellInfo, showRomanization: Bool, mode: CandidatePaneView.Mode) -> CGSize {
        let candidateLabelHeight = cellHeight * (showRomanization ? 0.5 : 0.6)
        let candidateFontSizeUnrounded = candidateLabelHeight * Self.fontSizePerHeight
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
            let commentWidth = mainLanguage.size(withFont: UIFont.systemFont(ofSize: mode == .row ? candidateCommentFontSize : candidateFontSize)).width
            cellWidth = mode == .row ? max(cellWidth, min(cellWidth + 70, commentWidth)) : cellWidth + Self.paddingText + commentWidth
        }
        
        if mode == .table {
            let otherLanguages = info.otherLanguages
            if !otherLanguages.isEmpty {
                let commentWidth = info.otherLanguages.reduce(-Self.paddingComment) { sum, language in
                    sum + Self.paddingComment + language.size(withFont: UIFont.systemFont(ofSize: candidateCommentFontSize)).width
                }
                cellWidth = max(cellWidth, commentWidth)
            }
        }
        
        return Self.margin.wrap(widthOnly: CGSize(width: cellWidth, height: cellHeight))
    }
    
    static func computeFilterCellSize(cellHeight: CGFloat, candidateText text: String) -> CGSize {
        let candidateLabelHeight = cellHeight * 0.7
        let candidateFontSizeUnrounded = candidateLabelHeight * Self.fontSizePerHeight
        let candidateFontSize = candidateFontSizeUnrounded.roundTo(q: 4)
        
        let cellWidth = estimateStringWidth(text, ofSize: candidateFontSize)
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
