//
//  DictionaryView.swift
//  CantoboardFramework
//
//  Created by Alex Man on 4/25/23.
//

import Foundation
import UIKit

class DictionaryView: UIScrollView {
    private var rectView: UIView!
    private var outerStack: UIStackView!
    
    private var titleStack: SidedStackView!
    private var entryLabel: UILabel!
    private var pronunciationLabel: UILabel!
    private var pronunciationTypeLabel: UILabel!
    
    private var definitionStack: SidedStackView!
    private var partOfSpeechLabel: UILabel!
    private var labelLabel: UILabel!
    private var definitionLabel: UILabel!
    
    private var otherDataStack: UIStackView!
    private var otherLanguageStack: UIStackView!
    
    private static let otherData: KeyValuePairs<String, WritableKeyPath<CandidateCellInfo, String?>> = [
        "Register": \.definition.register,
        "Written Form": \.definition.written,
        "Vernacular Form": \.definition.colloquial,
    ]
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        
        rectView = UIView()
        rectView.translatesAutoresizingMaskIntoConstraints = false
        rectView.layer.cornerRadius = 12
        rectView.backgroundColor = ButtonColor.dictionaryViewBackgroundColor
        addSubview(rectView)
        
        outerStack = UIStackView()
        outerStack.translatesAutoresizingMaskIntoConstraints = false
        outerStack.axis = .vertical
        outerStack.spacing = 16
        rectView.addSubview(outerStack)
        
        entryLabel = UILabel(font: .preferredFont(forTextStyle: .title1))
        pronunciationLabel = UILabel(color: ButtonColor.dictionaryViewGrayedColor, font: .preferredFont(forTextStyle: .body))
        pronunciationTypeLabel = UILabel(color: ButtonColor.dictionaryViewGrayedColor, font: .preferredFont(forTextStyle: .footnote))
        
        partOfSpeechLabel = UILabelWithPadding(color: ButtonColor.dictionaryViewGrayedColor, font: .systemFont(ofSize: 14, weight: .light))
        partOfSpeechLabel.layer.borderColor = ButtonColor.dictionaryViewGrayedColor.resolvedColor(with: traitCollection).cgColor
        partOfSpeechLabel.layer.borderWidth = 1
        partOfSpeechLabel.layer.cornerRadius = 2
        labelLabel = UILabel(color: ButtonColor.keyGrayedColor, font: .preferredFont(forTextStyle: .footnote))
        definitionLabel = UILabel(font: .preferredFont(forTextStyle: .body))
        definitionLabel.numberOfLines = 0
        
        NSLayoutConstraint.activate([
            rectView.topAnchor.constraint(equalTo: contentLayoutGuide.topAnchor, constant: 8),
            contentLayoutGuide.bottomAnchor.constraint(equalTo: rectView.bottomAnchor, constant: 8),
            rectView.leadingAnchor.constraint(equalTo: contentLayoutGuide.leadingAnchor, constant: 8),
            contentLayoutGuide.trailingAnchor.constraint(equalTo: rectView.trailingAnchor),
            
            outerStack.topAnchor.constraint(equalTo: rectView.topAnchor, constant: 20),
            rectView.bottomAnchor.constraint(equalTo: outerStack.bottomAnchor, constant: 20),
            outerStack.leadingAnchor.constraint(equalTo: rectView.leadingAnchor, constant: 20),
            rectView.trailingAnchor.constraint(equalTo: outerStack.trailingAnchor, constant: 20),
            
            contentLayoutGuide.widthAnchor.constraint(equalTo: widthAnchor),
        ])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup(info: CandidateCellInfo) {
        for view in outerStack.arrangedSubviews {
            outerStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        
        titleStack = SidedStackView(spacing: 20, alignment: .firstBaseline)
        entryLabel.text = info.honzi
        titleStack.addArrangedSubview(entryLabel)
        if let jyutping = info.jyutping {
            pronunciationLabel.text = jyutping
            titleStack.addArrangedSubview(pronunciationLabel)
        }
        var pronunciationType = [String]()
        if let sandhi = info.sandhi, sandhi != "0" {
            pronunciationType.append("sandhi")
        }
        if let vernacular = info.litColReading, vernacular != "0" {
            pronunciationType.append("vernacular")
        }
        if !pronunciationType.isEmpty {
            pronunciationTypeLabel.text = "(\(pronunciationType.joined(separator: ", ")))"
            titleStack.addArrangedSubview(pronunciationTypeLabel)
        }
        outerStack.addArrangedSubview(titleStack)
        
        definitionStack = SidedStackView(spacing: 12, alignment: .firstBaseline)
        if let partOfSpeech = info.definition.pos {
            partOfSpeechLabel.text = partOfSpeech
            definitionStack.addArrangedSubview(partOfSpeechLabel)
        }
        if let label = info.definition.label {
            labelLabel.text = "(\(label))"
            definitionStack.addArrangedSubview(labelLabel)
        }
        if let definition = info.mainLanguage {
            definitionLabel.text = definition
            definitionStack.addArrangedSubview(definitionLabel)
        }
        if !definitionStack.arrangedSubviews.isEmpty {
            outerStack.addArrangedSubview(definitionStack)
        }
        
        let otherData = Self.otherData.compactMap { data -> (String, String)? in
            guard let value = info[keyPath: data.value] else { return nil }
            return (data.key, value)
        }
        if !otherData.isEmpty {
            otherDataStack = Self.createKeyValueStackView(otherData)
            outerStack.addArrangedSubview(otherDataStack)
        }
        
        let otherLanguages = info.otherLanguagesWithNames
        if !otherLanguages.isEmpty {
            otherLanguageStack = UIStackView(arrangedSubviews: [
                UILabel(text: "More Languages", font: .systemFont(ofSize: 17, weight: .medium)),
                Self.createKeyValueStackView(otherLanguages),
            ])
            otherLanguageStack.axis = .vertical
            otherLanguageStack.spacing = 8
            outerStack.addArrangedSubview(otherLanguageStack)
        }
    }
    
    private static func createKeyValueStackView(_ data: [(String, String)]) -> UIStackView {
        var firstKeyLabel: UILabel?
        var layoutConstraints = [NSLayoutConstraint]()
        let stack = UIStackView(arrangedSubviews: data.map {
            let keyLabel = UILabel(text: $0.0, color: ButtonColor.dictionaryViewGrayedColor, font: .preferredFont(forTextStyle: .headline))
            let valueLabel = UILabel(text: $0.1, font: .preferredFont(forTextStyle: .body))
            keyLabel.textAlignment = .right
            let stack = SidedStackView(spacing: 12, arrangedSubviews: [keyLabel, valueLabel])
            if let firstKeyLabel = firstKeyLabel {
                layoutConstraints.append(keyLabel.widthAnchor.constraint(equalTo: firstKeyLabel.widthAnchor))
            } else {
                firstKeyLabel = keyLabel
            }
            return stack
        })
        stack.axis = .vertical
        stack.spacing = 4
        NSLayoutConstraint.activate(layoutConstraints)
        return stack
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        partOfSpeechLabel.layer.borderColor = ButtonColor.dictionaryViewGrayedColor.resolvedColor(with: traitCollection).cgColor
    }
}

class UILabelWithPadding: UILabel {
    private static let padding = UIEdgeInsets(top: 0, left: 2, bottom: 0, right: 2)
    
    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: Self.padding))
    }

    override var intrinsicContentSize: CGSize {
        super.intrinsicContentSize.extend(margin: Self.padding)
    }
}
