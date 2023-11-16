//
//  DictionaryView.swift
//  CantoboardFramework
//
//  Created by Alex Man on 4/25/23.
//

import Foundation
import UIKit

class DictionaryViewController: UIViewController {
    private var dictionaryView: DictionaryView!
    private var deferredInfo: CandidateInfo?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dictionaryView = DictionaryView()
        view.addSubview(dictionaryView)
        view.backgroundColor = ButtonColor.dictionaryViewBackgroundColor
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(dismissDictionary))
        
        NSLayoutConstraint.activate([
            dictionaryView.topAnchor.constraint(equalTo: view.topAnchor, constant: -navigationController!.navigationBar.frame.height - 10),
            view.bottomAnchor.constraint(equalTo: dictionaryView.bottomAnchor),
            dictionaryView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: dictionaryView.trailingAnchor),
        ])
        
        if let info = deferredInfo {
            dictionaryView.setup(info: info)
            deferredInfo = nil
        }
    }
    
    func setup(info: CandidateInfo) {
        if isViewLoaded {
            dictionaryView.setup(info: info)
        } else {
            deferredInfo = info
        }
    }
    
    @objc func dismissDictionary() {
        dismiss(animated: true)
    }
}

class DictionaryView: UIScrollView {
    private var entryStack: UIStackView!
    private var entryViews: [Weak<DictionaryEntryView>] = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        
        entryStack = UIStackView()
        entryStack.translatesAutoresizingMaskIntoConstraints = false
        entryStack.axis = .vertical
        entryStack.spacing = 40 * Settings.cached.candidateFontSize.scale
        addSubview(entryStack)
        
        let widthConstraint = contentLayoutGuide.widthAnchor.constraint(equalTo: widthAnchor)
        widthConstraint.priority = .required
        NSLayoutConstraint.activate([
            entryStack.topAnchor.constraint(equalTo: contentLayoutGuide.topAnchor, constant: 20),
            contentLayoutGuide.bottomAnchor.constraint(equalTo: entryStack.bottomAnchor, constant: 20),
            entryStack.leadingAnchor.constraint(equalTo: contentLayoutGuide.leadingAnchor, constant: 20),
            contentLayoutGuide.trailingAnchor.constraint(equalTo: entryStack.trailingAnchor, constant: 20),
            widthConstraint,
        ])
    }
    
    func setup(info: CandidateInfo) {
        let entries = info.entries.filter(\.isDictionaryEntry)
        for (i, entry) in entries.enumerated() {
            let entryView = entryViews[weak: i] ?? DictionaryEntryView()
            entryView.setup(entry: entry)
            entryStack.addArrangedSubview(entryView)
            entryViews[weak: i] = entryView
        }
        if entries.endIndex < entryViews.endIndex {
            for i in entries.endIndex..<entryViews.endIndex {
                entryViews[i].ref?.removeFromSuperview()
                entryViews[i].ref = nil
            }
            entryViews.removeLast(entryViews.endIndex - entries.endIndex)
        }
        setContentOffset(CGPoint(x: 0, y: .min), animated: false)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class DictionaryEntryView: UIStackView {
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
    
    private static let otherData: KeyValuePairs<String, WritableKeyPath<CandidateEntry, String?>> = [
        "Standard Form": \.properties.normalized,
        "Written Form": \.properties.written,
        "Vernacular Form": \.properties.vernacular,
        "Word Form": \.properties.collocation,
    ]
    
    private static let litColReading: [String: String] = [
        "lit": "literary reading 文讀",
        "col": "colloquial reading 白讀",
    ]
    
    private static let register: [String: String] = [
        "wri": "written",
        "ver": "vernacular",
        "for": "formal",
        "lzh": "archaic",
    ]
    
    private static let partOfSpeech: [String: String] = [
        "n": "noun 名詞",
        "v": "verb 動詞",
        "adj": "adjective 形容詞",
        "adv": "adverb 副詞",
        "morph": "morpheme 語素",
        "mw": "measure word 量詞",
        "part": "particle 助詞",
        "oth": "other 其他",
        "x": "non-morpheme 非語素",
    ]
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        axis = .vertical
        spacing = 16 * Settings.cached.candidateFontSize.scale
        
        entryLabel = UILabel(font: .preferredFont(forTextStyle: .title1))
        pronunciationLabel = UILabel(color: ButtonColor.dictionaryViewGrayedColor, font: .preferredFont(forTextStyle: .body))
        pronunciationTypeLabel = UILabel(color: ButtonColor.dictionaryViewGrayedColor, font: .preferredFont(forTextStyle: .footnote))
        
        registerLabel = UILabel(color: ButtonColor.keyGrayedColor, font: .italicSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .subheadline).pointSize))
        definitionLabel = UILabel(font: .preferredFont(forTextStyle: .body))
        definitionLabel.numberOfLines = 0
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup(entry: CandidateEntry) {
        for view in arrangedSubviews {
            removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        
        titleStack = SidedStackView(spacing: 20 * Settings.cached.candidateFontSize.scale, alignment: .firstBaseline)
        entryLabel.text = entry.honzi
        titleStack.addArrangedSubview(entryLabel)
        if let jyutping = entry.jyutping {
            pronunciationLabel.text = jyutping
            titleStack.addArrangedSubview(pronunciationLabel)
        }
        var pronunciationType = [String]()
        if let sandhi = entry.sandhi, sandhi == "1" {
            pronunciationType.append("changed tone 變音")
        }
        if let litColReading = entry.litColReading, let type = Self.litColReading[litColReading] {
            pronunciationType.append(type)
        }
        if !pronunciationType.isEmpty {
            pronunciationTypeLabel.text = "(\(pronunciationType.joined(separator: ", ")))"
            titleStack.addArrangedSubview(pronunciationTypeLabel)
        }
        addArrangedSubview(titleStack)
        
        definitionStack = SidedStackView(spacing: 12 * Settings.cached.candidateFontSize.scale, alignment: .firstBaseline)
        if let partOfSpeech = entry.properties.partOfSpeech {
            partOfSpeechStack = UIStackView()
            partOfSpeechStack.translatesAutoresizingMaskIntoConstraints = false
            partOfSpeechStack.spacing = 4 * Settings.cached.candidateFontSize.scale
            for pos in partOfSpeech.split(separator: " ") {
                let partOfSpeechLabel = UILabelWithPadding(color: ButtonColor.dictionaryViewGrayedColor, font: .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .footnote).pointSize, weight: .light))
                partOfSpeechLabel.layer.borderColor = ButtonColor.dictionaryViewGrayedColor.resolvedColor(with: traitCollection).cgColor
                partOfSpeechLabel.layer.borderWidth = 1
                partOfSpeechLabel.layer.cornerRadius = 2
                partOfSpeechLabel.text = Self.partOfSpeech[String(pos)] ?? String(pos)
                partOfSpeechStack.addArrangedSubview(partOfSpeechLabel)
            }
            definitionStack.addArrangedSubview(partOfSpeechStack)
        }
        if let register = entry.properties.register, let reg = Self.register[register] {
            registerLabel.text = reg
            definitionStack.addArrangedSubview(registerLabel)
        }
        if let label = entry.properties.label {
            labelStack = UIStackView()
            labelStack.translatesAutoresizingMaskIntoConstraints = false
            labelStack.spacing = 4 * Settings.cached.candidateFontSize.scale
            for lbl in label.split(separator: " ") {
                let labelLabel = UILabel(color: ButtonColor.keyGrayedColor, font: .preferredFont(forTextStyle: .subheadline))
                labelLabel.text = "(\(lbl))"
                labelStack.addArrangedSubview(labelLabel)
            }
            definitionStack.addArrangedSubview(labelStack)
        }
        if let definition = entry.mainLanguage {
            definitionLabel.text = definition
            definitionStack.addArrangedSubview(definitionLabel)
        }
        if !definitionStack.arrangedSubviews.isEmpty {
            addArrangedSubview(definitionStack)
        }
        
        let otherData = Self.otherData.compactMap { data -> (String, String)? in
            guard let value = entry[keyPath: data.value] else { return nil }
            return (data.key, value.replacingOccurrences(of: "，", with: "\n"))
        }
        if !otherData.isEmpty {
            otherDataStack = Self.createKeyValueStackView(otherData)
            addArrangedSubview(otherDataStack)
        }
        
        let otherLanguages = entry.otherLanguagesWithNames
        if !otherLanguages.isEmpty {
            otherLanguageStack = UIStackView(arrangedSubviews: [
                UILabel(text: "More Languages", font: .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .headline).pointSize, weight: .medium)),
                Self.createKeyValueStackView(otherLanguages),
            ])
            otherLanguageStack.axis = .vertical
            otherLanguageStack.spacing = 8 * Settings.cached.candidateFontSize.scale
            addArrangedSubview(otherLanguageStack)
        }
    }
    
    private static func createKeyValueStackView(_ data: [(String, String)]) -> UIStackView {
        var firstKeyLabel: UILabel?
        var layoutConstraints = [NSLayoutConstraint]()
        let stack = UIStackView(arrangedSubviews: data.map {
            let keyLabel = UILabel(text: $0.0, color: ButtonColor.dictionaryViewGrayedColor, font: .preferredFont(forTextStyle: .headline))
            let valueLabel = UILabel(text: $0.1, font: .preferredFont(forTextStyle: .body))
            keyLabel.textAlignment = .right
            let stack = SidedStackView(spacing: 12 * Settings.cached.candidateFontSize.scale, arrangedSubviews: [keyLabel, valueLabel])
            if let firstKeyLabel = firstKeyLabel {
                layoutConstraints.append(keyLabel.widthAnchor.constraint(equalTo: firstKeyLabel.widthAnchor))
            } else {
                firstKeyLabel = keyLabel
            }
            return stack
        })
        stack.axis = .vertical
        stack.spacing = 4 * Settings.cached.candidateFontSize.scale
        NSLayoutConstraint.activate(layoutConstraints)
        return stack
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if let partOfSpeechStack = partOfSpeechStack {
            for partOfSpeechLabel in partOfSpeechStack.arrangedSubviews {
                partOfSpeechLabel.layer.borderColor = ButtonColor.dictionaryViewGrayedColor.resolvedColor(with: traitCollection).cgColor
            }
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
