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
    private static let otherData: KeyValuePairs<String, WritableKeyPath<CandidateEntry, String?>> = [
        "Standard Form 標準字形": \.properties.normalized,
        "Written Form 書面語": \.properties.written,
        "Vernacular Form 口語": \.properties.vernacular,
        "Collocation 配搭": \.properties.collocation,
    ]
    
    private static let litColReading: [String: String] = [
        "lit": "literary reading 文讀",
        "col": "colloquial reading 白讀",
    ]
    
    private static let register: [String: String] = [
        "wri": "written 書面語",
        "ver": "vernacular 口語",
        "for": "formal 公文體",
        "lzh": "classical Chinese 文言",
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
    
    public static let labels: [String: String] = [
        "abbrev": "abbreviation 簡稱",
        "astro": "astronomy 天文",
        "ChinMeta": "sexagenary cycle 干支",
        "horo": "horoscope 星座",
        "org": "organisation 機構",
        "person": "person 人名",
        "place": "place 地名",
        "reli": "religion 宗教",
        "rare": "rare 罕見",
        "composition": "compound 詞組",
    ]
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        axis = .vertical
        spacing = 16 * Settings.cached.candidateFontSize.scale
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup(entry: CandidateEntry) {
        for view in arrangedSubviews {
            removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        
        let entryLabel = UILabel(font: .preferredFont(forTextStyle: .title1))
        entryLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        entryLabel.attributedText = entry.honzi?.toHKAttributedString
        var titleStackElements: [UIView] = [entryLabel]
        if let jyutping = entry.jyutping {
            let pronunciationLabel = UILabel(color: ButtonColor.dictionaryViewGrayedColor, font: .preferredFont(forTextStyle: .body))
            pronunciationLabel.numberOfLines = 0
            pronunciationLabel.attributedText = jyutping.toHKAttributedString
            titleStackElements.append(pronunciationLabel)
        }
        var pronunciationType = [String]()
        if let sandhi = entry.sandhi, sandhi == "1" {
            pronunciationType.append("changed tone 變音")
        }
        if let litColReading = entry.litColReading, let type = Self.litColReading[litColReading] {
            pronunciationType.append(type)
        }
        if !pronunciationType.isEmpty {
            let pronunciationTypeLabel = UILabel(color: ButtonColor.dictionaryViewGrayedColor, font: .preferredFont(forTextStyle: .footnote))
            pronunciationTypeLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
            pronunciationTypeLabel.attributedText = "(\(pronunciationType.joined(separator: ", ")))".toHKAttributedString
            titleStackElements.append(pronunciationTypeLabel)
        }
        addArrangedSubview(WrappableStackView(spacingX: 16 * Settings.cached.candidateFontSize.scale, spacingY: 10 * Settings.cached.candidateFontSize.scale, arrangedSubviews: titleStackElements))
        
        var definitionStackElements = [UIView]()
        var smallSpacingViews = Set<UIView>()
        if let partOfSpeech = entry.properties.partOfSpeech {
            let partsOfSpeech = partOfSpeech.split(separator: " ")
            for (i, pos) in partsOfSpeech.enumerated() {
                let partOfSpeechLabel = UILabelWithPadding(color: ButtonColor.dictionaryViewGrayedColor, font: .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .footnote).pointSize, weight: .light))
                partOfSpeechLabel.layer.borderColor = ButtonColor.dictionaryViewGrayedColor.resolvedColor(with: traitCollection).cgColor
                partOfSpeechLabel.layer.borderWidth = 1
                partOfSpeechLabel.layer.cornerRadius = 2
                partOfSpeechLabel.attributedText = (Self.partOfSpeech[String(pos)] ?? String(pos)).toHKAttributedString
                partOfSpeechLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
                definitionStackElements.append(partOfSpeechLabel)
                if i != partsOfSpeech.endIndex - 1 {
                    smallSpacingViews.insert(partOfSpeechLabel)
                }
            }
        }
        if let register = entry.properties.register, let reg = Self.register[register] {
            let registerLabel = UILabel(color: ButtonColor.keyGrayedColor, font: .italicSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .subheadline).pointSize))
            registerLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
            registerLabel.attributedText = reg.toHKAttributedString
            definitionStackElements.append(registerLabel)
        }
        if let labels = entry.formattedLabels {
            for (i, lbl) in labels.enumerated() {
                let labelLabel = UILabel(color: ButtonColor.keyGrayedColor, font: .preferredFont(forTextStyle: .subheadline))
                labelLabel.attributedText = lbl.toHKAttributedString
                labelLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
                definitionStackElements.append(labelLabel)
                if i != labels.endIndex - 1 {
                    smallSpacingViews.insert(labelLabel)
                }
            }
        }
        if let definition = entry.mainLanguage {
            let definitionLabel = UILabel(font: .preferredFont(forTextStyle: .body))
            definitionLabel.numberOfLines = 0
            definitionLabel.attributedText = definition.toHKAttributedString
            definitionStackElements.append(definitionLabel)
        }
        if !definitionStackElements.isEmpty {
            addArrangedSubview(WrappableStackView(spacingX: 12 * Settings.cached.candidateFontSize.scale, spacingY: 8 * Settings.cached.candidateFontSize.scale, arrangedSubviews: definitionStackElements, smallSpacingX: 4 * Settings.cached.candidateFontSize.scale, smallSpacingAfter: smallSpacingViews))
        }
        
        let otherData = Self.otherData.compactMap { data -> (String, String)? in
            guard let value = entry[keyPath: data.value] else { return nil }
            return (data.key, value.replacingOccurrences(of: "，", with: "\n"))
        }
        if !otherData.isEmpty {
            addArrangedSubview(Self.createKeyValueStackView(otherData))
        }
        
        let otherLanguages = entry.otherLanguagesWithNames
        if !otherLanguages.isEmpty {
            let otherLanguageStack = UIStackView(arrangedSubviews: [
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
            keyLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
            valueLabel.numberOfLines = 0
            let stack = SidedStackView(spacing: 12 * Settings.cached.candidateFontSize.scale, alignment: .firstBaseline, arrangedSubviews: [keyLabel, valueLabel])
            if let firstKeyLabel = firstKeyLabel {
                layoutConstraints.append(keyLabel.widthAnchor.constraint(equalTo: firstKeyLabel.widthAnchor))
            } else {
                firstKeyLabel = keyLabel
            }
            return stack
        })
        stack.axis = .vertical
        stack.spacing = 6 * Settings.cached.candidateFontSize.scale
        NSLayoutConstraint.activate(layoutConstraints)
        return stack
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
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        layer.borderColor = ButtonColor.dictionaryViewGrayedColor.resolvedColor(with: traitCollection).cgColor
    }
}
