//
//  Settings.swift
//  Cantoboard
//
//  Created by Alex Man on 16/10/21.
//

import UIKit
import CantoboardFramework

struct Section {
    var header: String?
    var options: [Option]
    
    fileprivate init(_ header: String? = nil, _ options: [Option] = []) {
        self.header = header
        self.options = options
    }
}

protocol Option {
    var title: String { get }
    var description: String? { get }
    var videoUrl: String? { get }
    func dequeueCell(with controller: MainViewController) -> UITableViewCell
    func cellDidSelect()
}

private class Switch: Option {
    var title: String
    var description: String?
    var videoUrl: String?
    var key: WritableKeyPath<Settings, Bool>
    var value: Bool
    
    private var controller: MainViewController!
    private var control: UISwitch!
    
    init(_ title: String, _ key: WritableKeyPath<Settings, Bool>, _ description: String? = nil, _ videoUrl: String? = nil) {
        self.title = title
        self.key = key
        self.value = Settings.cached[keyPath: key]
        self.description = description
        self.videoUrl = videoUrl
    }
    
    func dequeueCell(with controller: MainViewController) -> UITableViewCell {
        self.controller = controller
        control = UISwitch()
        control.isOn = value
        control.addTarget(self, action: #selector(updateSettings), for: .valueChanged)
        return OptionTableViewCell(option: self, optionView: control)
    }
    
    func cellDidSelect() {}
    
    @objc func updateSettings() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        value = control.isOn
        controller.settings[keyPath: key] = value
        controller.view.endEditing(true)
        Settings.save(controller.settings)
        controller.rebuildCells()
    }
}

private class Segment<T: Equatable>: Option {
    var title: String
    var description: String?
    var videoUrl: String?
    var key: WritableKeyPath<Settings, T>
    var value: T
    var options: KeyValuePairs<String, T>
    
    private var controller: MainViewController!
    private var control: UISegmentedControl!
    
    init(_ title: String, _ key: WritableKeyPath<Settings, T>, _ options: KeyValuePairs<String, T>, _ description: String? = nil, _ videoUrl: String? = nil) {
        self.title = title
        self.key = key
        self.value = Settings.cached[keyPath: key]
        self.options = options
        self.description = description
        self.videoUrl = videoUrl
    }
    
    func dequeueCell(with controller: MainViewController) -> UITableViewCell {
        self.controller = controller
        control = UISegmentedControl(items: options.map { $0.key })
        control.setTitleTextAttributes(String.HKAttribute, for: .normal)
        control.selectedSegmentIndex = options.firstIndex(where: { $1 == value })!
        control.apportionsSegmentWidthsByContent = key != \.interfaceLanguage && Settings.cached.interfaceLanguage == .english
        control.addTarget(self, action: #selector(updateSettings), for: .valueChanged)
        return OptionTableViewCell(option: self, optionView: control)
    }
    
    func cellDidSelect() {}
    
    @objc func updateSettings() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        value = options[control.selectedSegmentIndex].value
        controller.settings[keyPath: key] = value
        controller.view.endEditing(true)
        Settings.save(controller.settings)
        controller.rebuildCells()
    }
}

private class ColorPicker<T: UIColor>: Option {
    var title: String
    var description: String?
    var videoUrl: String?
    var key: WritableKeyPath<Settings, T>
    var value: T
    
    var controller: MainViewController!
    var colorPreview: UIView!
    var colorPickerDelegate: ColorPickerDelegate<T>?
    
    init(_ title: String, _ key: WritableKeyPath<Settings, T>, _ description: String? = nil, _ videoUrl: String? = nil) {
        self.title = title
        self.key = key
        self.value = Settings.cached[keyPath: key]
        self.description = description
        self.videoUrl = videoUrl
    }
    
    func dequeueCell(with controller: MainViewController) -> UITableViewCell {
        self.controller = controller
        colorPreview = RoundedUIView()
        colorPreview.backgroundColor = value
        let cell = OptionTableViewCell(option: self, optionView: colorPreview)
        cell.selectionStyle = .default
        NSLayoutConstraint.activate([
            colorPreview.widthAnchor.constraint(greaterThanOrEqualToConstant: 24),
            colorPreview.widthAnchor.constraint(equalTo: colorPreview.heightAnchor),
            colorPreview.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 8),
        ])
        return cell
    }
    
    func cellDidSelect() {
        if #available(iOS 14.0, *) {
            let colorPickerDelegate = colorPickerDelegate ?? ColorPickerDelegate(colorPicker: self)
            self.colorPickerDelegate = colorPickerDelegate
            let colorPicker = UIColorPickerViewController()
            colorPicker.title = title
            colorPicker.selectedColor = value
            colorPicker.supportsAlpha = false
            colorPicker.delegate = colorPickerDelegate
            colorPicker.modalPresentationStyle = .popover
            colorPicker.popoverPresentationController?.sourceView = colorPreview
            controller.present(colorPicker, animated: true)
        } else {
            // Never mind
        }
    }
}

private class RoundedUIView: UIView {
    override public func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = frame.width / 2
        layer.masksToBounds = true
        layer.borderColor = UIColor.separator.cgColor
        layer.borderWidth = 1
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        layer.borderColor = UIColor.separator.cgColor
    }
}

private class ColorPickerDelegate<T: UIColor>: NSObject, UIColorPickerViewControllerDelegate {
    let colorPicker: ColorPicker<T>!
    
    init(colorPicker: ColorPicker<T>) {
        self.colorPicker = colorPicker
    }
    
    @available(iOS 14.0, *)
    func colorPickerViewController(_ viewController: UIColorPickerViewController, didSelect color: UIColor, continuously: Bool) {
        colorPicker.colorPreview.backgroundColor = color
        guard let color = color as? T else { return }
        colorPicker.value = color
        colorPicker.controller.settings[keyPath: colorPicker.key] = colorPicker.value
        colorPicker.controller.view.endEditing(true)
        Settings.save(colorPicker.controller.settings)
    }
}

extension Settings {
    static var interfaceLanguageOption: Option {
        Segment(LocalizedStrings.interfaceLanguage, \.interfaceLanguage, [
            LocalizedStrings.interfaceLanguage_chinese: .chinese,
            LocalizedStrings.interfaceLanguage_english: .english,
        ])
    }
    
    static func buildSections() -> [Section] {
        let isPad = UIDevice.current.userInterfaceIdiom == .pad
        let isQwerty = Settings.cached.cantoneseKeyboardLayout == .qwerty
        let inputMethodOptions: [Option?] = [
            isQwerty ? Switch(LocalizedStrings.mixedMode, \.isMixedModeEnabled) : nil,
            isPad ? nil : Switch(LocalizedStrings.longPressSymbolKeys, \.isLongPressSymbolKeysEnabled, LocalizedStrings.longPressSymbolKeys_description, "long_press_symbols"),
            Switch(LocalizedStrings.smartFullStop, \.isSmartFullStopEnabled,
                   LocalizedStrings.smartFullStop_description, "smart_full_stop"),
            Switch(LocalizedStrings.audioFeedback, \.isAudioFeedbackEnabled),
            isPad ? nil : Switch(LocalizedStrings.tapHapticFeedback, \.isTapHapticFeedbackEnabled),
            isPad ? nil : Switch(LocalizedStrings.enableCharPreview, \.enableCharPreview),
            Switch(LocalizedStrings.enableSystemLexicon, \.enableSystemLexicon),
            Segment(LocalizedStrings.candidateFontSize, \.candidateFontSize, [
                    LocalizedStrings.candidateFontSize_small: .small,
                    LocalizedStrings.candidateFontSize_normal: .normal,
                    LocalizedStrings.candidateFontSize_large: .large,
            ]),
            Segment(LocalizedStrings.candidateGap, \.candidateGap, [
                    LocalizedStrings.candidateGap_normal: .normal,
                    LocalizedStrings.candidateGap_large: .large,
            ]),
            Segment(LocalizedStrings.candidateSelectMode, \.candidateSelectMode, [
                    LocalizedStrings.candidateSelectMode_expandDownward: .expandDownward,
                    LocalizedStrings.candidateSelectMode_scrollRight: .scrollRight,
            ]),
            Segment(LocalizedStrings.symbolShape, \.symbolShape, [
                    LocalizedStrings.symbolShape_half: .half,
                    LocalizedStrings.symbolShape_full: .full,
                    LocalizedStrings.symbolShape_smart: .smart,
            ]),
        ]
        let padSection = Section(
            LocalizedStrings.padSettings,
            [
                Segment(LocalizedStrings.candidateBarStyle, \.fullPadCandidateBar, [
                        LocalizedStrings.candidateBarStyle_full: true,
                        LocalizedStrings.candidateBarStyle_ios: false,
                ]),
                Segment(LocalizedStrings.padLeftSysKey, \.padLeftSysKeyAsKeyboardType, [
                        LocalizedStrings.padLeftSysKey_default: false,
                        LocalizedStrings.padLeftSysKey_keyboardType: true,
                    ],
                    LocalizedStrings.padLeftSysKey_description
                ),
            ]
        )
        let jyutpingInitialFinalLayoutSettingsSection = Section(
            LocalizedStrings.jyutpingInitialFinalLayoutSettings,
            [
                Switch(LocalizedStrings.customizeKeyColor, \.jyutpingInitialFinalLayoutSettings.customizeKeyColor),
            ] + (Settings.cached.jyutpingInitialFinalLayoutSettings.customizeKeyColor ? [
                ColorPicker(LocalizedStrings.initialKeyColor, \.jyutpingInitialFinalLayoutSettings.initialKeyColor),
                ColorPicker(LocalizedStrings.finalKeyColor, \.jyutpingInitialFinalLayoutSettings.finalKeyColor),
                ColorPicker(LocalizedStrings.toneKeyColor, \.jyutpingInitialFinalLayoutSettings.toneKeyColor),
                ColorPicker(LocalizedStrings.punctuationKeyColor, \.jyutpingInitialFinalLayoutSettings.punctuationKeyColor),
                ColorPicker(LocalizedStrings.spaceKeyColor, \.jyutpingInitialFinalLayoutSettings.spaceKeyColor),
                ColorPicker(LocalizedStrings.systemKeyColor, \.jyutpingInitialFinalLayoutSettings.systemKeyColor),
            ] : [])
        )
        let reverseLookupSettingsSection = Section(
            LocalizedStrings.reverseLookupSettings,
            [
                Switch(LocalizedStrings.showCodeInReverseLookup, \.showCodeInReverseLookup),
                Segment(LocalizedStrings.cangjieVersion, \.cangjieVersion, [
                        LocalizedStrings.cangjieVersion_cangjie3: .cangjie3,
                        LocalizedStrings.cangjieVersion_cangjie5: .cangjie5,
                    ]
                ),
                Segment(LocalizedStrings.cangjieKeyCapMode, \.cangjieKeyCapMode, [
                        LocalizedStrings.cangjieKeyCapMode_letter: .letter,
                        LocalizedStrings.cangjieKeyCapMode_cangjieRoot: .cangjieRoot,
                    ]
                ),
            ]
        )
        
        return [
            Section(LocalizedStrings.inputMethodSettings, inputMethodOptions.compactMap({ $0 })),
            isPad ? padSection : nil,
            Section(
                LocalizedStrings.chineseInputSettings,
                [
                    Switch(LocalizedStrings.enablePredictiveText, \.enablePredictiveText,
                           LocalizedStrings.enablePredictiveText_description),
                    Segment(LocalizedStrings.compositionMode, \.compositionMode, [
                            LocalizedStrings.compositionMode_immediate: .immediate,
                            LocalizedStrings.compositionMode_multiStage: .multiStage,
                        ],
                        LocalizedStrings.compositionMode_description
                    ),
                    Segment(LocalizedStrings.spaceAction, \.spaceAction, [
                            LocalizedStrings.spaceAction_nextPage: .nextPage,
                            LocalizedStrings.spaceAction_insertCandidate: .insertCandidate,
                            LocalizedStrings.spaceAction_insertText: .insertText,
                    ]),
                    Segment(LocalizedStrings.showRomanizationMode, \.showRomanizationMode, [
                            LocalizedStrings.showRomanizationMode_never: .never,
                            LocalizedStrings.showRomanizationMode_always: .always,
                            LocalizedStrings.showRomanizationMode_onlyInNonCantoneseMode: .onlyInNonCantoneseMode,
                    ]),
                    Segment(LocalizedStrings.charForm, \.charForm, [
                            LocalizedStrings.charForm_traditional: .traditional,
                            LocalizedStrings.charForm_simplified: .simplified,
                    ]),
                ] + (isQwerty ? [
                    Switch(LocalizedStrings.enableCompletion, \.rimeSettings.enableCompletion),
                    Switch(LocalizedStrings.enableCorrector, \.rimeSettings.enableCorrector,
                           LocalizedStrings.enableCorrector_description, "autocorrect"),
                ] : []) + [
                    Switch(LocalizedStrings.enableSentence, \.rimeSettings.enableSentence),
                    Switch(LocalizedStrings.enableLearning, \.rimeSettings.enableLearning,
                           LocalizedStrings.enableLearning_description, "4_memory"),
                    Segment(LocalizedStrings.cantoneseKeyboardLayout, \.cantoneseKeyboardLayout, [
                            LocalizedStrings.cantoneseKeyboardLayout_qwerty: .qwerty,
                            LocalizedStrings.cantoneseKeyboardLayout_tenKeys: .tenKeys,
                            LocalizedStrings.cantoneseKeyboardLayout_initialFinal: .initialFinal,
                        ]
                    ),
                ] + (isQwerty ? [
                    Segment(LocalizedStrings.toneInputMode, \.toneInputMode, [
                            LocalizedStrings.toneInputMode_vxq: .vxq,
                            LocalizedStrings.toneInputMode_longPress: .longPress,
                        ],
                        LocalizedStrings.toneInputMode_description, "tone_input_mode"
                    ),
                ] : [])
            ),
            Settings.cached.cantoneseKeyboardLayout == .initialFinal ? jyutpingInitialFinalLayoutSettingsSection : nil,
            isQwerty ? reverseLookupSettingsSection : nil,
            Section(
                LocalizedStrings.englishInputSettings,
                [
                    Switch(LocalizedStrings.autoCap, \.isAutoCapEnabled),
                    Segment(LocalizedStrings.englishLocale, \.englishLocale, [
                            LocalizedStrings.englishLocale_au: .au,
                            LocalizedStrings.englishLocale_ca: .ca,
                            LocalizedStrings.englishLocale_gb: .gb,
                            LocalizedStrings.englishLocale_us: .us,
                    ]),
                ]
            ),
        ].compactMap({ $0 })
    }
}
