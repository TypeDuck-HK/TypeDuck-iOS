//
//  Settings.swift
//  CantoboardFramework
//
//  Created by Alex Man on 2/23/21.
//

import Foundation

import CocoaLumberjackSwift

public enum InterfaceLanguage: String, Codable {
    case chinese = "chinese"
    case english = "english"
}

public enum CompositionMode: String, Codable {
    case multiStage = "multiStage"
    case immediate = "immediate"
}

public enum InputMode: String, Codable {
    case mixed = "mixed"
    case chinese = "chinese"
    case english = "english"
    
    var afterToggle: InputMode {
        switch self {
        case .mixed: return .english
        case .chinese: return .english
        case .english: return Settings.cached.isMixedModeEnabled ? .mixed : .chinese
        }
    }
}

public enum SymbolShape: String, Codable {
    case full = "full"
    case half = "half"
    case smart = "smart"
}

public enum SpaceAction: String, Codable {
    case insertCandidate = "insertCandidate"
    case insertText = "insertText"
    case nextPage = "nextPage"
}

public enum CantoneseKeyboardLayout: String, Codable {
    case qwerty = "qwerty"
    case tenKeys = "tenKeys"
    
    var toRimeSchema: RimeSchema {
        switch self {
        case .qwerty: return .jyutping
        case .tenKeys: return .jyutping10keys
        }
    }
}

public enum ToneInputMode: String, Codable {
    case longPress = "longPress"
    case vxq = "vxq"
}

public enum EnglishLocale: String, Codable {
    case us = "en_US"
    case gb = "en_GB"
    case ca = "en_CA"
    case au = "en_AU"
}

public enum CandidateFontSize: String, Codable {
    case small = "small"
    case normal = "normal"
    case large = "large"
    
    var scale: CGFloat {
        switch self {
        case .small: return 1
        case .normal: return 1.2
        case .large: return 1.5
        }
    }
    
    var statusScale: CGFloat {
        switch self {
        case .small: return 1
        case .normal: return 1.1
        case .large: return 1.25
        }
    }
}

public enum CandidateGap: String, Codable {
    case normal = "normal"
    case large = "large"
    
    var interitemSpacing: CGFloat {
        switch self {
        case .normal: return 0
        case .large: return 12
        }
    }
    
    var lineSpacing: CGFloat {
        switch self {
        case .normal: return 0
        case .large: return 8
        }
    }
}

public enum CangjieVersion: String, Codable {
    case cangjie3 = "cangjie3"
    case cangjie5 = "cangjie5"
    
    var toRimeSchema: RimeSchema {
        switch self {
        case .cangjie3: return .cangjie3
        case .cangjie5: return .cangjie5
        }
    }
}

public enum ShowRomanizationMode: String, Codable {
    case always = "always"
    case onlyInNonCantoneseMode = "onlyInNonCantoneseMode"
    case never = "never"
}

public enum FullWidthSpaceMode: String, Codable {
    case off = "off"
    case shift = "shift"
}

public enum Language: String, Codable, Comparable, CaseIterable {
    case eng = "eng"
    case hin = "hin"
    case ind = "ind"
    case nep = "nep"
    case urd = "urd"
    
    var isLatin: Bool {
        switch self {
        case .eng, .ind: return true
        default: return false
        }
    }
    
    var order: Int {
        switch self {
        case .eng: return 0
        case .hin: return 1
        case .ind: return 2
        case .nep: return 3
        case .urd: return 4
        }
    }
    
    var name: String {
        switch self {
        case .eng: return "English"
        case .hin: return "Hindi"
        case .ind: return "Indonesian"
        case .nep: return "Nepali"
        case .urd: return "Urdu"
        }
    }
    
    public static func <(lhs: Language, rhs: Language) -> Bool {
        return lhs.order < rhs.order
    }
}

public struct LanguageState: Codable, Equatable {
    public var selected: [Language]
    public var deselected: [Language]
    public var main: Language
    
    public init() {
        selected = [.eng]
        deselected = [.hin, .ind, .nep, .urd]
        main = .eng
    }
    
    enum CodingKeys: CodingKey {
        case languages
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        var languages = try container.decodeIfPresent([Language].self, forKey: .languages) ?? [.eng]
        if languages.isEmpty {
            languages = [.eng]
        }
        main = languages.removeFirst()
        languages.insert(main, at: languages.binarySearch(element: main))
        selected = languages
        deselected = Language.allCases.filter { !languages.contains($0) }
    }
    
    public func encode(to encoder: Encoder) throws {
        var languages = selected
        if let index = languages.firstIndex(of: main) {
            languages.remove(at: index)
        }
        languages.insert(main, at: 0)
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(languages, forKey: .languages)
    }
    
    mutating public func insert(at index: Int) -> Int {
        let element = deselected.remove(at: index)
        let newIndex = selected.binarySearch(element: element)
        selected.insert(element, at: newIndex)
        return newIndex
    }
    
    mutating public func delete(at index: Int) -> Int {
        let element = selected.remove(at: index)
        let newIndex = deselected.binarySearch(element: element)
        deselected.insert(element, at: newIndex)
        return newIndex
    }
    
    public func has(_ language: Language) -> Bool {
        selected.contains { $0 == language }
    }
    
    public var shouldDisplayEngTag: Bool {
        main == .ind
    }
}

// If any of these settings is changed, we have to redeploy Rime.
public struct RimeSettings: Codable, Equatable {
    public var enableCorrector: Bool
    
    public init() {
        enableCorrector = false
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        enableCorrector = try container.decodeIfPresent(Bool.self, forKey: .enableCorrector) ?? false
    }
}

public struct Settings: Codable, Equatable {
    private static let settingsKeyName = "Settings"
    private static let defaultInterfaceLanguage: InterfaceLanguage = {
        let languageCodes: Set = ["cdo", "cjy", "cmn", "cnp", "cpx", "csp", "czh", "czo", "gan", "hak", "hsn", "lzh", "mnp", "nan", "wuu", "yue", "zh"]
        return languageCodes.isDisjoint(with: Locale.preferredLanguages.compactMap { Locale(identifier: $0).languageCode }) ? .english : .chinese
    }()
    private static let defaultMixedModeEnabled: Bool = false
    private static let defaultAutoCapEnabled: Bool = true
    private static let defaultSmartEnglishSpaceEnabled: Bool = true
    private static let defaultSmartFullStopEnabled: Bool = true
    private static let defaultCandidateFontSize: CandidateFontSize = .normal
    private static let defaultCandidateGap: CandidateGap = .normal
    private static let defaultSymbolShape: SymbolShape = .smart
    private static let defaultSmartSymbolShapeDefault: SymbolShape = .full
    private static let defaultSpaceAction: SpaceAction = .insertCandidate
    private static let defaultCantoneseKeyboardLayout: CantoneseKeyboardLayout = .qwerty
    private static let defaultToneInputMode: ToneInputMode = .vxq
    private static let defaultRimeSettings: RimeSettings = RimeSettings()
    private static let defaultEnglishLocale: EnglishLocale = .gb
    private static let defaultShowRomanizationMode: ShowRomanizationMode = .always
    private static let defaultShowCodeInReverseLookup: Bool = true
    private static let defaultAudioFeedbackEnabled: Bool = true
    private static let defaultTapHapticFeedbackEnabled: Bool = false
    private static let defaultShowEnglishExactMatch: Bool = true
    private static let defaultCompositionMode: CompositionMode = .multiStage
    private static let defaultEnableCharPreview: Bool = true
    private static let defaultPressSymbolKeysEnabled: Bool = true
    private static let defaultEnableHKCorrection: Bool = true
    private static let defaultFullWidthSpaceMode: FullWidthSpaceMode = .shift
    private static let defaultEnablePredictiveText: Bool = false
    private static let defaultPredictiveTextOffensiveWord: Bool = false
    private static let defaultFullPadCandidateBar: Bool = true
    private static let defaultPadLeftSysKeyAsKeyboardType: Bool = false
    private static let defaultShowBottomLeftSwitchLangButton: Bool = false
    private static let defaultCangjieVersion: CangjieVersion = .cangjie5
    private static let defaultLanguageState: LanguageState = LanguageState()

    public var interfaceLanguage: InterfaceLanguage
    public var isMixedModeEnabled: Bool
    public var isAutoCapEnabled: Bool
    public var isSmartEnglishSpaceEnabled: Bool
    public var isSmartFullStopEnabled: Bool
    public var candidateFontSize: CandidateFontSize
    public var candidateGap: CandidateGap
    public var symbolShape: SymbolShape
    public var smartSymbolShapeDefault: SymbolShape
    public var spaceAction: SpaceAction
    public var cantoneseKeyboardLayout: CantoneseKeyboardLayout
    public var toneInputMode: ToneInputMode
    public var rimeSettings: RimeSettings
    public var englishLocale: EnglishLocale
    public var showRomanizationMode: ShowRomanizationMode
    public var showCodeInReverseLookup: Bool
    public var isAudioFeedbackEnabled: Bool
    public var isTapHapticFeedbackEnabled: Bool
    public var shouldShowEnglishExactMatch: Bool
    public var compositionMode: CompositionMode
    public var enableCharPreview: Bool
    public var isLongPressSymbolKeysEnabled: Bool
    public var enableHKCorrection: Bool
    public var fullWidthSpaceMode: FullWidthSpaceMode
    public var enablePredictiveText: Bool
    public var predictiveTextOffensiveWord: Bool
    public var fullPadCandidateBar: Bool
    public var padLeftSysKeyAsKeyboardType: Bool
    public var showBottomLeftSwitchLangButton: Bool
    public var cangjieVersion: CangjieVersion
    public var languageState: LanguageState
    
    public init() {
        interfaceLanguage = Self.defaultInterfaceLanguage
        isMixedModeEnabled = Self.defaultMixedModeEnabled
        isAutoCapEnabled = Self.defaultAutoCapEnabled
        isSmartEnglishSpaceEnabled = Self.defaultSmartEnglishSpaceEnabled
        isSmartFullStopEnabled = Self.defaultSmartFullStopEnabled
        candidateFontSize = Self.defaultCandidateFontSize
        candidateGap = Self.defaultCandidateGap
        symbolShape = Self.defaultSymbolShape
        smartSymbolShapeDefault = Self.defaultSmartSymbolShapeDefault
        spaceAction = Self.defaultSpaceAction
        cantoneseKeyboardLayout = Self.defaultCantoneseKeyboardLayout
        toneInputMode = Self.defaultToneInputMode
        rimeSettings = Self.defaultRimeSettings
        englishLocale = Self.defaultEnglishLocale
        showRomanizationMode = Self.defaultShowRomanizationMode
        showCodeInReverseLookup = Self.defaultShowCodeInReverseLookup
        isAudioFeedbackEnabled = Self.defaultAudioFeedbackEnabled
        isTapHapticFeedbackEnabled = Self.defaultTapHapticFeedbackEnabled
        shouldShowEnglishExactMatch = Self.defaultShowEnglishExactMatch
        compositionMode = Self.defaultCompositionMode
        enableCharPreview = Self.defaultEnableCharPreview
        isLongPressSymbolKeysEnabled = Self.defaultPressSymbolKeysEnabled
        enableHKCorrection = Self.defaultEnableHKCorrection
        fullWidthSpaceMode = Self.defaultFullWidthSpaceMode
        enablePredictiveText = Self.defaultEnablePredictiveText
        predictiveTextOffensiveWord = Self.defaultPredictiveTextOffensiveWord
        fullPadCandidateBar = Self.defaultFullPadCandidateBar
        padLeftSysKeyAsKeyboardType = Self.defaultPadLeftSysKeyAsKeyboardType
        showBottomLeftSwitchLangButton = Self.defaultShowBottomLeftSwitchLangButton
        cangjieVersion = Self.defaultCangjieVersion
        languageState = Self.defaultLanguageState
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.interfaceLanguage = try container.decodeIfPresent(InterfaceLanguage.self, forKey: .interfaceLanguage) ?? Settings.defaultInterfaceLanguage
        self.isMixedModeEnabled = try container.decodeIfPresent(Bool.self, forKey: .isMixedModeEnabled) ?? Settings.defaultMixedModeEnabled
        self.isAutoCapEnabled = try container.decodeIfPresent(Bool.self, forKey: .isAutoCapEnabled) ?? Settings.defaultAutoCapEnabled
        self.isSmartFullStopEnabled = try container.decodeIfPresent(Bool.self, forKey: .isSmartFullStopEnabled) ?? Settings.defaultSmartFullStopEnabled
        self.isSmartEnglishSpaceEnabled = try container.decodeIfPresent(Bool.self, forKey: .isSmartEnglishSpaceEnabled) ?? Settings.defaultSmartEnglishSpaceEnabled
        self.candidateFontSize = try container.decodeIfPresent(CandidateFontSize.self, forKey: .candidateFontSize) ?? Settings.defaultCandidateFontSize
        self.candidateGap = try container.decodeIfPresent(CandidateGap.self, forKey: .candidateGap) ?? Settings.defaultCandidateGap
        self.symbolShape = try container.decodeIfPresent(SymbolShape.self, forKey: .symbolShape) ?? Settings.defaultSymbolShape
        self.smartSymbolShapeDefault = try container.decodeIfPresent(SymbolShape.self, forKey: .smartSymbolShapeDefault) ?? Settings.defaultSmartSymbolShapeDefault
        self.spaceAction = try container.decodeIfPresent(SpaceAction.self, forKey: .spaceAction) ?? Settings.defaultSpaceAction
        self.cantoneseKeyboardLayout = try container.decodeIfPresent(CantoneseKeyboardLayout.self, forKey: .cantoneseKeyboardLayout) ?? Settings.defaultCantoneseKeyboardLayout
        self.toneInputMode = try container.decodeIfPresent(ToneInputMode.self, forKey: .toneInputMode) ?? Settings.defaultToneInputMode
        self.rimeSettings = try container.decodeIfPresent(RimeSettings.self, forKey: .rimeSettings) ?? Settings.defaultRimeSettings
        self.englishLocale = try container.decodeIfPresent(EnglishLocale.self, forKey: .englishLocale) ?? Settings.defaultEnglishLocale
        self.showRomanizationMode = try container.decodeIfPresent(ShowRomanizationMode.self, forKey: .showRomanizationMode) ?? Settings.defaultShowRomanizationMode
        self.showCodeInReverseLookup = try container.decodeIfPresent(Bool.self, forKey: .showCodeInReverseLookup) ?? Settings.defaultShowCodeInReverseLookup
        self.isAudioFeedbackEnabled = try container.decodeIfPresent(Bool.self, forKey: .isAudioFeedbackEnabled) ?? Settings.defaultAudioFeedbackEnabled
        self.isTapHapticFeedbackEnabled = try container.decodeIfPresent(Bool.self, forKey: .isTapHapticFeedbackEnabled) ?? Settings.defaultTapHapticFeedbackEnabled
        self.shouldShowEnglishExactMatch = try container.decodeIfPresent(Bool.self, forKey: .shouldShowEnglishExactMatch) ?? Settings.defaultShowEnglishExactMatch
        self.compositionMode = try container.decodeIfPresent(CompositionMode.self, forKey: .compositionMode) ?? Settings.defaultCompositionMode
        self.enableCharPreview = try container.decodeIfPresent(Bool.self, forKey: .enableCharPreview) ?? Settings.defaultEnableCharPreview
        self.isLongPressSymbolKeysEnabled = try container.decodeIfPresent(Bool.self, forKey: .isLongPressSymbolKeysEnabled) ?? Settings.defaultPressSymbolKeysEnabled
        self.enableHKCorrection = try container.decodeIfPresent(Bool.self, forKey: .enableHKCorrection) ?? Settings.defaultEnableHKCorrection
        self.fullWidthSpaceMode = try container.decodeIfPresent(FullWidthSpaceMode.self, forKey: .fullWidthSpaceMode) ?? Settings.defaultFullWidthSpaceMode
        self.enablePredictiveText = try container.decodeIfPresent(Bool.self, forKey: .enablePredictiveText) ?? Settings.defaultEnablePredictiveText
        self.predictiveTextOffensiveWord = try container.decodeIfPresent(Bool.self, forKey: .predictiveTextOffensiveWord) ?? Settings.defaultPredictiveTextOffensiveWord
        self.fullPadCandidateBar = try container.decodeIfPresent(Bool.self, forKey: .fullPadCandidateBar) ?? Settings.defaultFullPadCandidateBar
        self.padLeftSysKeyAsKeyboardType = try container.decodeIfPresent(Bool.self, forKey: .padLeftSysKeyAsKeyboardType) ?? Settings.defaultPadLeftSysKeyAsKeyboardType
        self.showBottomLeftSwitchLangButton = try container.decodeIfPresent(Bool.self, forKey: .showBottomLeftSwitchLangButton) ?? Settings.defaultShowBottomLeftSwitchLangButton
        self.cangjieVersion = try container.decodeIfPresent(CangjieVersion.self, forKey: .cangjieVersion) ?? Settings.defaultCangjieVersion
        self.languageState = try container.decodeIfPresent(LanguageState.self, forKey: .languageState) ?? Settings.defaultLanguageState
    }
    
    private static var _cached: Settings?
    
    public static var cached: Settings {
        get {
            if _cached == nil {
                return reload()
            }
            return _cached!
        }
    }
    
    public static func reload() -> Settings {
        if let saved = userDefaults.object(forKey: settingsKeyName) as? Data {
            let decoder = JSONDecoder()
            do {
                let setting = try decoder.decode(Settings.self, from: saved)
                _cached = setting
                return setting
            } catch {
                DDLogInfo("Failed to load \(saved). Falling back to default settings. Error: \(error)")
            }
        }
        
        _cached = Settings()
        return _cached!
    }
    
    public static func save(_ settings: Settings) {
        _cached = settings
        guard hasFullAccess else {
            DDLogInfo("Skip updating UserDefaults as we don't have full access.")
            return
        }
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(settings) {
            userDefaults.set(encoded, forKey: settingsKeyName)
        } else {
            DDLogInfo("Failed to save \(settings)")
        }
    }
    
    public static var hasFullAccess = true
    
    private static var userDefaults: UserDefaults = initUserDefaults()
    
    private static func initUserDefaults() -> UserDefaults {
        let suiteName = "group.hk.eduhk.typeduck"
        let appGroupDefaults = UserDefaults(suiteName: suiteName)
        if let appGroupDefaults = appGroupDefaults {
            DDLogInfo("Using UserDefaults \(suiteName).")
            return appGroupDefaults
        } else {
            DDLogInfo("Cannot open app group UserDefaults. Falling back to UserDefaults.standard.")
            return UserDefaults.standard
        }
    }
}
