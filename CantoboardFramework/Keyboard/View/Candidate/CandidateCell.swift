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
    
    var keyboardState: KeyboardState?
    var mode: CandidatePaneView.Mode = .row
    var isFilterCell: Bool = false
    var info: CandidateInfo?
    
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
    
    weak var mainStack, codeStack, textStack, commentStack: SidedStackView?
    weak var label: UILabel?
    weak var keyHintLayer: KeyHintLayer?
    weak var reverseLookupLabel: UILabel?
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
    
    func setup(_ text: String, _ comment: String?, _ keyboardState: KeyboardState, _ mode: CandidatePaneView.Mode) {
        self.keyboardState = keyboardState
        self.mode = mode
        
        let mainStack, codeStack, textStack, commentStack: SidedStackView?
        
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
        
        if let oldCodeStack = self.codeStack {
            for view in oldCodeStack.arrangedSubviews {
                oldCodeStack.removeArrangedSubview(view)
            }
            codeStack = oldCodeStack
        } else if mode == .table {
            codeStack = SidedStackView(spacing: Self.paddingComment, alignment: .firstBaseline)
            self.codeStack = codeStack
        } else {
            codeStack = self.codeStack
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
        label.lineBreakMode = .byClipping
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
        
        let info = CandidateInfo(text, comment)
        self.info = info
        let entry = info.entry
        
        if isFilterCell {
            mainStack!.contentView.alignment = .center
            mainStack!.addArrangedSubview(label)
        } else {
            mainStack!.contentView.alignment = .fill
            
            var codeLabels: [UILabel] = []
            
            if keyboardState.showCodeInReverseLookup {
                let reverseLookupLabel = self.reverseLookupLabel ?? UILabel()
                reverseLookupLabel.textAlignment = mode == .row ? .center : .left
                reverseLookupLabel.attributedText = (info.note.isEmpty ? "⠀" : info.note).toHKAttributedString
                reverseLookupLabel.textColor = ButtonColor.keyHintColor
                codeLabels.append(reverseLookupLabel)
                self.reverseLookupLabel = reverseLookupLabel
            } else {
                self.reverseLookupLabel?.attributedText = nil
                self.reverseLookupLabel?.removeFromSuperview()
                self.reverseLookupLabel = nil
            }
            
            if keyboardState.showRomanization, mode == .row || !info.romanization.isEmpty || !keyboardState.showCodeInReverseLookup {
                let romanizationLabel = self.romanizationLabel ?? UILabel()
                romanizationLabel.textAlignment = mode == .row ? .center : .left
                romanizationLabel.attributedText = (info.romanization.isEmpty ? "⠀" : info.romanization).toHKAttributedString
                codeLabels.append(romanizationLabel)
                self.romanizationLabel = romanizationLabel
            } else {
                self.romanizationLabel?.attributedText = nil
                self.romanizationLabel?.removeFromSuperview()
                self.romanizationLabel = nil
            }
            
            if mode == .row {
                for label in codeLabels {
                    mainStack!.addArrangedSubview(label)
                }
            } else {
                for label in codeLabels.reversed() {
                    codeStack!.addArrangedSubview(label)
                }
            }
            
            let targetStack = mode == .row ? mainStack : textStack
            targetStack!.addArrangedSubview(label)
            
            if let entry = entry, let mainLanguage = mode == .row ? entry.mainLanguageOrLabel : entry.mainLanguage {
                let translationLabel = self.translationLabel ?? UILabel()
                translationLabel.textAlignment = mode == .row ? .center : .left
                translationLabel.attributedText = mainLanguage.toHKAttributedString
                translationLabel.textColor = entry.isDictionaryEntry ? ButtonColor.keyForegroundColor : ButtonColor.keyHintColor
                targetStack!.addArrangedSubview(translationLabel)
                self.translationLabel = translationLabel
            } else {
                self.translationLabel?.attributedText = nil
                self.translationLabel?.removeFromSuperview()
                self.translationLabel = nil
            }
            
            if mode == .table, let entry = entry {
                let otherLanguages = entry.otherLanguagesOrLabels
                for (i, language) in otherLanguages.enumerated() {
                    let commentLabel = self.commentLabels[weak: i] ?? UILabel()
                    commentLabel.textAlignment = .left
                    commentLabel.attributedText = language.toHKAttributedString
                    commentLabel.textColor = entry.isDictionaryEntry ? ButtonColor.keyForegroundColor : ButtonColor.keyHintColor
                    commentStack!.addArrangedSubview(commentLabel)
                    self.commentLabels[weak: i] = commentLabel
                }
                if otherLanguages.endIndex < self.commentLabels.endIndex {
                    for i in otherLanguages.endIndex..<self.commentLabels.endIndex {
                        self.commentLabels[i].ref?.removeFromSuperview()
                        self.commentLabels[i].ref = nil
                    }
                    self.commentLabels.removeLast(self.commentLabels.endIndex - otherLanguages.endIndex)
                }
            } else {
                for commentLabel in self.commentLabels {
                    commentLabel.ref?.attributedText = nil
                    commentLabel.ref?.removeFromSuperview()
                    commentLabel.ref = nil
                }
                self.commentLabels.removeAll()
            }
            if mode == .table {
                if !codeLabels.isEmpty {
                    mainStack!.addArrangedSubview(codeStack!)
                }
                mainStack!.addArrangedSubview(textStack!)
                if !self.commentLabels.isEmpty {
                    mainStack!.addArrangedSubview(commentStack!)
                }
            }
        }
        
        let hasDictionaryEntry = info.hasDictionaryEntry
        if hasDictionaryEntry {
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
        if mode == .table || !hasDictionaryEntry {
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
        
        label?.attributedText = nil
        label = nil
        
        keyHintLayer?.removeFromSuperlayer()
        keyHintLayer = nil
        
        romanizationLabel?.attributedText = nil
        romanizationLabel = nil
        
        translationLabel?.attributedText = nil
        translationLabel = nil
        
        for commentLabel in commentLabels {
            commentLabel.ref?.attributedText = nil
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
        let heightRatio = 1 / (keyboardState?.numLinesInCandidateBar ?? 4)
        
        let hasDictionaryEntry = info?.hasDictionaryEntry ?? false
        if hasDictionaryEntry {
            if mode == .row {
                let dimension = bounds.height * heightRatio
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
            if hasDictionaryEntry {
                bounds = bounds.insetBy(dx: 4, dy: 0)
                if mode == .row {
                    bounds.size.width += bounds.height * heightRatio - 2
                } else {
                    bounds.size.width -= 4
                }
            } else if keyHintLayer == nil {
                if let info = info, info.entry != nil || !info.note.isEmpty || !info.romanization.isEmpty {
                    bounds = bounds.insetBy(dx: 4, dy: 0)
                } else {
                    bounds = bounds.insetBy(dx: 4, dy: 4)
                }
            }
            selectedRectLayer.frame = bounds
        }
        
        guard let keyHintLayer = keyHintLayer else { return }
        layout(textLayer: keyHintLayer, atTopRightCornerWithInsets: KeyHintLayer.hintInsets, heightRatio: heightRatio)
    }
    
    private func layout(_ bounds: CGRect) {
        guard let keyboardState = keyboardState else { return }
        
        let availableHeight = bounds.height - Self.margin.top - Self.margin.bottom
        let numLines = keyboardState.numLines(for: mode)
        
        let candidateTextHeight = availableHeight * (isFilterCell ? 0.7 : 2 / numLines)
        let candidateTextFont = UIFont.systemFont(ofSize: candidateTextHeight * Self.fontSizePerHeight)
        
        let candidateCommentHeight = availableHeight / numLines
        let candidateCommentFont = UIFont.systemFont(ofSize: candidateCommentHeight * Self.fontSizePerHeight)
        
        label?.font = candidateTextFont
        reverseLookupLabel?.font = candidateCommentFont
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
    
    static func computeCellSize(cellHeight: CGFloat, candidateInfo info: CandidateInfo, keyboardState: KeyboardState, mode: CandidatePaneView.Mode) -> CGSize {
        let numLines = keyboardState.numLines(for: mode)
        let candidateLabelHeight = cellHeight / numLines * 2
        let candidateFontSizeUnrounded = candidateLabelHeight * Self.fontSizePerHeight
        let candidateFontSize = candidateFontSizeUnrounded.roundTo(q: 4)
        
        let candidateCommentHeight = cellHeight / numLines
        let candidateCommentFontSizeUnrounded = candidateCommentHeight * Self.fontSizePerHeight
        let candidateCommentFontSize = candidateCommentFontSizeUnrounded.roundTo(q: 4)
        
        var cellWidth = estimateStringWidth(info.text, ofSize: candidateFontSize)
        
        var noteWidth: CGFloat = 0
        if keyboardState.showCodeInReverseLookup, !info.note.isEmpty {
            noteWidth = estimateStringWidth(info.note, ofSize: candidateCommentFontSize)
        }
        
        var romanizationWidth: CGFloat = 0
        if keyboardState.showRomanization, !info.romanization.isEmpty {
            romanizationWidth = estimateStringWidth(info.romanization, ofSize: candidateCommentFontSize)
        }
        
        switch mode {
        case .row: cellWidth = max(cellWidth, noteWidth, romanizationWidth)
        case .table: cellWidth = max(cellWidth, noteWidth + (info.note.isEmpty || info.romanization.isEmpty ? 0 : Self.paddingComment) + romanizationWidth)
        }
        
        let entry = info.entry
        if let entry = entry, let mainLanguage = mode == .row ? entry.mainLanguageOrLabel : entry.mainLanguage {
            let commentWidth = mainLanguage.size(withFont: UIFont.systemFont(ofSize: mode == .row ? candidateCommentFontSize : candidateFontSize)).width
            cellWidth = mode == .row ? max(cellWidth, min(cellWidth + 70, commentWidth)) : cellWidth + Self.paddingText + commentWidth
        }
        
        if mode == .table, let entry = entry {
            let otherLanguages = entry.otherLanguagesOrLabels
            if !otherLanguages.isEmpty {
                let commentWidth = otherLanguages.reduce(-Self.paddingComment) { sum, language in
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
