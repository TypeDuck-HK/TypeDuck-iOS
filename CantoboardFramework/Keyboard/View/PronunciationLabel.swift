//
//  PronunciationLabel.swift
//  CantoboardFramework
//
//  Created by Alex Man on 16/1/24.
//

import UIKit
import AVFoundation

class PronunciationLabel: UILabel {
    private static let buttonDimension: CGFloat = 36
    private static let buttonPadding: CGFloat = 6
    private var pronunciation: String!
    private var pronounceButton: PronounceButton!
    
    convenience init(pronunciation: String) {
        self.init(color: ButtonColor.dictionaryViewGrayedColor, font: .preferredFont(forTextStyle: .body))
        numberOfLines = 0
        self.pronunciation = pronunciation
        
        let offset = max((Self.buttonDimension + Self.buttonPadding - font.lineHeight) / 2, 0)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = offset
        let attributedString = NSMutableAttributedString(string: pronunciation + "\u{2060}" /* word joiner */, attributes: String.HKAttributed(withParagraphStyle: paragraphStyle))
        let space = NSTextAttachment()
        space.bounds = CGRect(x: 0, y: 0, width: Self.buttonDimension + Self.buttonPadding, height: 1e-5)
        attributedString.append(NSAttributedString(attachment: space))
        attributedText = attributedString
        isUserInteractionEnabled = true
        
        pronounceButton = PronounceButton(pronunciation: pronunciation)
        addSubview(pronounceButton)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        guard let attributedText = attributedText, let font = font else { return }
        let mutableAttributedString = NSMutableAttributedString(attributedString: attributedText)
        mutableAttributedString.addAttribute(.font, value: font, range: NSMakeRange(0, attributedText.length))
        
        let textStorage = NSTextStorage(attributedString: mutableAttributedString)
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)
        
        let textContainer = NSTextContainer(size: bounds.size)
        textContainer.lineFragmentPadding = 0
        textContainer.lineBreakMode = lineBreakMode
        layoutManager.addTextContainer(textContainer)
        
        let glyphIndex = layoutManager.glyphRange(forCharacterRange: NSMakeRange(attributedText.length - 1, 1), actualCharacterRange: nil).location
        let lineFragmentRect = layoutManager.lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: nil)
        let glyphLocation = layoutManager.location(forGlyphAt: glyphIndex)
        
        pronounceButton.frame = CGRect(x: lineFragmentRect.minX + glyphLocation.x + Self.buttonPadding,
                                       y: lineFragmentRect.minY + glyphLocation.y - (font.lineHeight + Self.buttonDimension - Self.buttonPadding) / 2,
                                       width: Self.buttonDimension,
                                       height: Self.buttonDimension)
    }
}

class PronounceButton: UIButton {
    private let pronunciation: String!
    
    init(pronunciation: String) {
        self.pronunciation = pronunciation
        super.init(frame: .zero)
        
        if #available(iOS 15.0, *) {
            setImage(ButtonImage.pronounce.applyingSymbolConfiguration(UIImage.SymbolConfiguration(hierarchicalColor: ButtonColor.dictionaryViewGrayedColor)), for: .normal)
            setImage(ButtonImage.pronounce.applyingSymbolConfiguration(UIImage.SymbolConfiguration(hierarchicalColor: ButtonColor.dictionaryViewGrayedColor.withAlphaComponent(0.6))), for: .highlighted)
        } else {
            setImage(ButtonImage.pronounce, for: .normal)
            tintColor = ButtonColor.dictionaryViewGrayedColor.withAlphaComponent(0.75)
        }
        contentHorizontalAlignment = .fill
        contentVerticalAlignment = .fill
        contentMode = .scaleAspectFit
        addTarget(self, action: #selector(pronounce), for: .touchUpInside)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func pronounce() {
        guard Settings.hasFullAccess else {
            let alert = AlertController(title: LocalizedStrings.alert_VoiceFeaturesUnavailable_Title, message: LocalizedStrings.alert_VoiceFeaturesUnavailable_Message, preferredStyle: .alert)
            alert.addAction(AlertAction(title: LocalizedStrings.alert_OK, style: .default, handler: nil))
            let settingsAction = AlertAction(title: LocalizedStrings.alert_Settings, style: .default, handler: { _ in
                let selector = #selector(UIApplication.openURL_backport(_:))
                self.findElement({ $0.responds(to: selector) })?.perform(selector, with: URL(string: UIApplication.openSettingsURLString)!)
            })
            alert.addAction(settingsAction)
            alert.preferredAction = settingsAction
            findElement(DictionaryViewController.self)?.present(alert, animated: true, completion: nil)
            return
        }
        guard SpeechProvider.isCantoneseVoiceAvailable else {
            let alert = AlertController(title: LocalizedStrings.alert_NoCantoneseVoice_Title, message: LocalizedStrings.alert_NoCantoneseVoice_Message, preferredStyle: .alert)
            alert.addAction(AlertAction(title: LocalizedStrings.alert_OK, style: .default, handler: nil))
            let settingsAction = AlertAction(title: LocalizedStrings.alert_Settings, style: .default, handler: { _ in
                let selector = #selector(UIApplication.openURL_backport(_:))
                self.findElement({ $0.responds(to: selector) })?.perform(selector, with: URL(string: "App-P" + "refs:")!)
            })
            alert.addAction(settingsAction)
            alert.preferredAction = settingsAction
            findElement(DictionaryViewController.self)?.present(alert, animated: true, completion: nil)
            return
        }
        SpeechProvider.stop()
        SpeechProvider.speak(pronunciation, rateMultiplier: 0.8)
    }
}
