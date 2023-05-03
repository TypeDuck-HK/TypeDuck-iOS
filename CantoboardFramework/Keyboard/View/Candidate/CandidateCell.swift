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
    private static let paddingText: CGFloat = 10
    private static let paddingComment: CGFloat = 5
    
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
    
    weak var mainStack, textStack, commentStack: UIStackView?
    weak var textStackSpacer, commentStackSpacer: UIView?
    weak var label: UILabel?
    weak var keyHintLayer: KeyHintLayer?
    weak var romanizationLabel: UILabel?
    weak var translationLabel: UILabel?
    var commentLabels: [Weak<UILabel>] = []
    weak var selectedRectLayer: CALayer?
    
    private var isWidthCalculated = false
    var layoutConstraint: NSLayoutConstraint?
    
    // Uncomment this to debug memory leak.
    private let c = InstanceCounter<CandidateCell>()
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        
        translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }
    
    func setup(_ text: String, _ comment: String?, showRomanization: Bool, mode: CandidatePaneView.Mode) {
        self.showRomanization = showRomanization
        self.mode = mode
        
        let mainStack, textStack, commentStack: UIStackView?
        
        if let oldMainStack = self.mainStack {
            for view in oldMainStack.arrangedSubviews {
                oldMainStack.removeArrangedSubview(view)
            }
            mainStack = oldMainStack
        } else {
            mainStack = UIStackView()
            mainStack!.translatesAutoresizingMaskIntoConstraints = false
            mainStack!.axis = .vertical
            contentView.addSubview(mainStack!)
            NSLayoutConstraint.activate([
                mainStack!.topAnchor.constraint(equalTo: topAnchor, constant: Self.margin.top),
                // bottomAnchor.constraint(equalTo: mainStack!.bottomAnchor, constant: Self.margin.bottom),
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
            textStack = UIStackView()
            textStack!.translatesAutoresizingMaskIntoConstraints = false
            textStack!.spacing = Self.paddingText
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
            commentStack = UIStackView()
            commentStack!.translatesAutoresizingMaskIntoConstraints = false
            commentStack!.spacing = Self.paddingComment
            self.commentStack = commentStack
        } else {
            commentStack = self.commentStack
        }
        
        if mode == .row {
            self.textStack?.removeFromSuperview()
            self.textStack = nil
            
            self.textStackSpacer?.removeFromSuperview()
            self.textStackSpacer = nil
            
            self.commentStack?.removeFromSuperview()
            self.commentStack = nil
            
            self.commentStackSpacer?.removeFromSuperview()
            self.commentStackSpacer = nil
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
                
                let textStackSpacer, commentStackSpacer: UIView
                textStackSpacer = self.textStackSpacer ?? UIView.createSpacer()
                textStack!.addArrangedSubview(textStackSpacer)
                mainStack!.addArrangedSubview(textStack!)
                self.textStackSpacer = textStackSpacer
                if !otherLanguages.isEmpty {
                    commentStackSpacer = self.commentStackSpacer ?? UIView.createSpacer()
                    commentStack!.addArrangedSubview(commentStackSpacer)
                    mainStack!.addArrangedSubview(commentStack!)
                    self.commentStackSpacer = commentStackSpacer
                }
            } else {
                for commentLabel in self.commentLabels {
                    commentLabel.ref?.text = nil
                    commentLabel.ref?.removeFromSuperview()
                    commentLabel.ref = nil
                }
                self.commentLabels.removeAll()
            }
        }
        
        isWidthCalculated = false
        layout(bounds)
        setNeedsLayout()
        layoutIfNeeded()
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
        
        textStackSpacer = nil
        commentStackSpacer = nil
        
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
        if let mainStack = mainStack {
            if let layoutConstraint = layoutConstraint {
                mainStack.removeConstraint(layoutConstraint)
            }
            layoutConstraint = mainStack.heightAnchor.constraint(equalToConstant: bounds.height)
            layoutConstraint?.isActive = true
        }
        let availableHeight = bounds.height - Self.margin.top - Self.margin.bottom
        
        let candidateTextHeight = availableHeight * (isFilterCell ? 0.7 : showRomanization ? 0.5 : 0.6)
        let candidateTextFont = UIFont.systemFont(ofSize: candidateTextHeight * Self.fontSizePerHeight * Settings.cached.candidateFontSize.scale)
        
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
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        if !isWidthCalculated {
            setNeedsLayout()
            layoutIfNeeded()
            layoutAttributes.frame = layoutAttributes.frame.with(width: contentView.systemLayoutSizeFitting(layoutAttributes.size).width + 1)
            isWidthCalculated = true
        }
        return layoutAttributes
    }
}
