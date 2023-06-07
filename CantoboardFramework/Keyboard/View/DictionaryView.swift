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
    private var partOfSpeechStack: UIStackView!
    private var registerLabel: UILabel!
    private var labelStack: UIStackView!
    private var definitionLabel: UILabel!
    
    private var otherDataStack: UIStackView!
    private var otherLanguageStack: UIStackView!
    
    private static let otherData: KeyValuePairs<String, WritableKeyPath<CandidateCellInfo, String?>> = [
        "Standard Form": \.properties.normalized,
        "Written Form": \.properties.written,
        "Vernacular Form": \.properties.colloquial,
        "Synonym": \.properties.synonym,
    ]
    
    private static let litColReading: [String: String] = [
        "lit": "literary reading",
        "col": "vernacular reading",
    ]
    
    private static let register: [String: String] = [
        "wri": "written",
        "col": "vernacular",
        "for": "formal",
    ]
    
    private static let partOfSpeech: [String: String] = [
        "n": "noun",
        "v": "verb",
        "adj": "adjective",
        "adv": "adverb",
        "conj": "conjunction",
        "prep": "preposition",
        "pron": "pronoun",
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
        
        registerLabel = UILabel(color: ButtonColor.keyGrayedColor, font: .italicSystemFont(ofSize: 15))
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
        if let sandhi = info.sandhi, sandhi == "1" {
            pronunciationType.append("changed tone")
        }
        if let litColReading = info.litColReading, let type = Self.litColReading[litColReading] {
            pronunciationType.append(type)
        }
        if !pronunciationType.isEmpty {
            pronunciationTypeLabel.text = "(\(pronunciationType.joined(separator: ", ")))"
            titleStack.addArrangedSubview(pronunciationTypeLabel)
        }
        outerStack.addArrangedSubview(titleStack)
        
        definitionStack = SidedStackView(spacing: 12, alignment: .firstBaseline)
        if let partOfSpeech = info.properties.pos {
            partOfSpeechStack = UIStackView()
            partOfSpeechStack.translatesAutoresizingMaskIntoConstraints = false
            partOfSpeechStack.spacing = 4
            for pos in partOfSpeech.split(separator: " ") {
                let partOfSpeechLabel = UILabelWithPadding(color: ButtonColor.dictionaryViewGrayedColor, font: .systemFont(ofSize: 13, weight: .light))
                partOfSpeechLabel.layer.borderColor = ButtonColor.dictionaryViewGrayedColor.resolvedColor(with: traitCollection).cgColor
                partOfSpeechLabel.layer.borderWidth = 1
                partOfSpeechLabel.layer.cornerRadius = 2
                partOfSpeechLabel.text = Self.partOfSpeech[String(pos)] ?? String(pos)
                partOfSpeechStack.addArrangedSubview(partOfSpeechLabel)
            }
            definitionStack.addArrangedSubview(partOfSpeechStack)
        }
        if let register = info.properties.register, let reg = Self.register[register] {
            registerLabel.text = reg
            definitionStack.addArrangedSubview(registerLabel)
        }
        if let label = info.properties.label {
            labelStack = UIStackView()
            labelStack.translatesAutoresizingMaskIntoConstraints = false
            labelStack.spacing = 4
            for lbl in label.split(separator: " ") {
                let labelLabel = UILabel(color: ButtonColor.keyGrayedColor, font: .preferredFont(forTextStyle: .subheadline))
                labelLabel.text = "(\(lbl))"
                labelStack.addArrangedSubview(labelLabel)
            }
            definitionStack.addArrangedSubview(labelStack)
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
        
        for partOfSpeechLabel in partOfSpeechStack.arrangedSubviews {
            partOfSpeechLabel.layer.borderColor = ButtonColor.dictionaryViewGrayedColor.resolvedColor(with: traitCollection).cgColor
        }
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
