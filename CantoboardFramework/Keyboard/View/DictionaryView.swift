//
//  DictionaryView.swift
//  CantoboardFramework
//
//  Created by Alex Man on 4/25/23.
//

import Foundation
import UIKit

// Custom navigation bar class that ignores all the touches except on the close button. This makes clicks on the pronounce button possible.
class DictionaryNavigationBar: UINavigationBar {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let _UIButtonBarButton = NSClassFromString("_UIButtonBarButton") else { return nil }
        let result = super.hitTest(point, with: event)
        return result?.isMember(of: _UIButtonBarButton) ?? false ? result : nil
    }
}

class DictionaryViewController: UIViewController {
    private var dictionaryView: DictionaryView!
    private var deferredInfo: CandidateInfo?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dictionaryView = DictionaryView()
        view.addSubview(dictionaryView)
        view.backgroundColor = ButtonColor.dictionaryViewBackgroundColor
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(dismissDictionary))
        
        let navigationBarHeight = navigationController?.navigationBar.frame.height ?? 0
        NSLayoutConstraint.activate([
            dictionaryView.topAnchor.constraint(equalTo: view.topAnchor, constant: -navigationBarHeight - 10),
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
            titleStackElements.append(PronunciationLabel(pronunciation: jyutping))
        }
        if let pronunciationType = entry.pronunciationType {
            let pronunciationTypeLabel = UILabel(color: ButtonColor.dictionaryViewGrayedColor, font: .preferredFont(forTextStyle: .footnote))
            pronunciationTypeLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
            pronunciationTypeLabel.attributedText = pronunciationType.toHKAttributedString
            titleStackElements.append(pronunciationTypeLabel)
        }
        addArrangedSubview(WrappableStackView(spacingX: 16 * Settings.cached.candidateFontSize.scale, spacingY: 10 * Settings.cached.candidateFontSize.scale, arrangedSubviews: titleStackElements))
        
        var definitionStackElements = [UIView]()
        var smallSpacingViews = Set<UIView>()
        if let partsOfSpeech = entry.formattedPartsOfSpeech {
            for (i, pos) in partsOfSpeech.enumerated() {
                let partOfSpeechLabel = UILabelWithPadding(color: ButtonColor.dictionaryViewGrayedColor, font: .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .footnote).pointSize, weight: .light))
                partOfSpeechLabel.layer.borderColor = ButtonColor.dictionaryViewGrayedColor.resolvedColor(with: traitCollection).cgColor
                partOfSpeechLabel.layer.borderWidth = 1
                partOfSpeechLabel.layer.cornerRadius = 2
                partOfSpeechLabel.attributedText = pos.toHKAttributedString
                partOfSpeechLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
                definitionStackElements.append(partOfSpeechLabel)
                if i != partsOfSpeech.endIndex - 1 {
                    smallSpacingViews.insert(partOfSpeechLabel)
                }
            }
        }
        if let registers = entry.formattedRegisters {
            for (i, reg) in registers.enumerated() {
                let registerLabel = UILabel(color: ButtonColor.dictionaryViewGrayedColor, font: .italicSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .subheadline).pointSize))
                registerLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
                registerLabel.attributedText = reg.toHKAttributedString
                definitionStackElements.append(registerLabel)
                if i != registers.endIndex - 1 {
                    smallSpacingViews.insert(registerLabel)
                }
            }
        }
        if let labels = entry.formattedLabels {
            for (i, lbl) in labels.enumerated() {
                let labelLabel = UILabel(color: ButtonColor.dictionaryViewGrayedColor, font: .preferredFont(forTextStyle: .subheadline))
                labelLabel.attributedText = lbl.toHKAttributedString
                labelLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
                definitionStackElements.append(labelLabel)
                if i != labels.endIndex - 1 {
                    smallSpacingViews.insert(labelLabel)
                }
            }
        }
        if let definition = entry.canonicalReference ?? entry.mainLanguage {
            let definitionLabel = UILabel(color: entry.canonicalReference == nil ? ButtonColor.dictionaryViewForegroundColor : ButtonColor.dictionaryViewGrayedColor, font: .preferredFont(forTextStyle: .body))
            definitionLabel.numberOfLines = 0
            definitionLabel.attributedText = definition.toHKAttributedString
            definitionStackElements.append(definitionLabel)
        }
        if !definitionStackElements.isEmpty {
            addArrangedSubview(WrappableStackView(spacingX: 12 * Settings.cached.candidateFontSize.scale, spacingY: 8 * Settings.cached.candidateFontSize.scale, arrangedSubviews: definitionStackElements, smallSpacingX: 4 * Settings.cached.candidateFontSize.scale, smallSpacingAfter: smallSpacingViews))
        }
        
        if let otherData = entry.otherData {
            addArrangedSubview(Self.createKeyValueStackView(otherData))
        }
        
        if let otherLanguages = entry.otherLanguagesWithNames {
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
