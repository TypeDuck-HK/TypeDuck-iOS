//
//  LocalizedStrings.swift
//  Cantoboard
//
//  Created by Alex Man on 16/10/21.
//

import Foundation
import CantoboardFramework

class LocalizedStrings {
    private static func localizedString(_ stringKeyName: String) -> String {
        NSLocalizedString(stringKeyName, bundle: Bundle(path: Bundle.main.path(forResource: Settings.cached.interfaceLanguage == .chinese ? "zh-HK" : "en", ofType: "lproj")!)!, comment: stringKeyName)
    }
    
    static var installTypeDuck: String { localizedString("installTypeDuck") }
    static var installTypeDuck_settings: String { localizedString("installTypeDuck.settings") }
    static var installTypeDuck_description: String { localizedString("installTypeDuck.description") }
    
    static var interfaceLanguage: String { localizedString("interfaceLanguage") }
    static var interfaceLanguage_chinese: String { localizedString("interfaceLanguage.chinese") }
    static var interfaceLanguage_english: String { localizedString("interfaceLanguage.english") }
    
    static var testKeyboard: String { localizedString("testKeyboard") }
    static var testKeyboard_placeholder: String { localizedString("testKeyboard.placeholder") }
    
    static var displayLanguages: String { localizedString("displayLanguages") }
    static var displayLanguages_eng: String { localizedString("displayLanguages.eng") }
    static var displayLanguages_hin: String { localizedString("displayLanguages.hin") }
    static var displayLanguages_ind: String { localizedString("displayLanguages.ind") }
    static var displayLanguages_nep: String { localizedString("displayLanguages.nep") }
    static var displayLanguages_urd: String { localizedString("displayLanguages.urd") }
    static var displayLanguages_description: String { localizedString("displayLanguages.description") }
    static var moreLanguages: String { localizedString("moreLanguages") }
    
    static var inputMethodSettings: String { localizedString("inputMethodSettings") }
    static var mixedMode: String { localizedString("inputMethodSettings.mixedMode") }
    static var longPressSymbolKeys: String { localizedString("inputMethodSettings.longPressSymbolKeys") }
    static var longPressSymbolKeys_description: String { localizedString("inputMethodSettings.longPressSymbolKeys.description") }
    static var smartFullStop: String { localizedString("inputMethodSettings.smartFullStop") }
    static var smartFullStop_description: String { localizedString("inputMethodSettings.smartFullStop.description") }
    static var audioFeedback: String { localizedString("inputMethodSettings.audioFeedback") }
    static var tapHapticFeedback: String { localizedString("inputMethodSettings.tapHapticFeedback") }
    static var enableCharPreview: String { localizedString("inputMethodSettings.enableCharPreview") }
    static var candidateFontSize: String { localizedString("inputMethodSettings.candidateFontSize") }
    static var candidateFontSize_small: String { localizedString("inputMethodSettings.candidateFontSize.small") }
    static var candidateFontSize_normal: String { localizedString("inputMethodSettings.candidateFontSize.normal") }
    static var candidateFontSize_large: String { localizedString("inputMethodSettings.candidateFontSize.large") }
    static var candidateGap: String { localizedString("inputMethodSettings.candidateGap") }
    static var candidateGap_normal: String { localizedString("inputMethodSettings.candidateGap.normal") }
    static var candidateGap_large: String { localizedString("inputMethodSettings.candidateGap.large") }
    static var symbolShape: String { localizedString("inputMethodSettings.symbolShape") }
    static var symbolShape_half: String { localizedString("inputMethodSettings.symbolShape.half") }
    static var symbolShape_full: String { localizedString("inputMethodSettings.symbolShape.full") }
    static var symbolShape_smart: String { localizedString("inputMethodSettings.symbolShape.smart") }
    
    static var padSettings: String { localizedString("padSettings") }
    static var candidateBarStyle: String { localizedString("padSettings.candidateBarStyle") }
    static var candidateBarStyle_full: String { localizedString("padSettings.candidateBarStyle.full") }
    static var candidateBarStyle_ios: String { localizedString("padSettings.candidateBarStyle.ios") }
    static var padLeftSysKey: String { localizedString("padSettings.leftSysKey") }
    static var padLeftSysKey_description: String { localizedString("padSettings.leftSysKey.description") }
    static var padLeftSysKey_default: String { localizedString("padSettings.leftSysKey.default") }
    static var padLeftSysKey_keyboardType: String { localizedString("padSettings.leftSysKey.keyboardType") }
    
    static var chineseInputSettings: String { localizedString("chineseInputSettings") }
    static var enablePredictiveText: String { localizedString("chineseInputSettings.enablePredictiveText") }
    static var enablePredictiveText_description: String { localizedString("chineseInputSettings.enablePredictiveText.description") }
    static var compositionMode: String { localizedString("chineseInputSettings.compositionMode") }
    static var compositionMode_immediate: String { localizedString("chineseInputSettings.compositionMode.immediate") }
    static var compositionMode_multiStage: String { localizedString("chineseInputSettings.compositionMode.multiStage") }
    static var compositionMode_description: String { localizedString("chineseInputSettings.compositionMode.description") }
    static var spaceAction: String { localizedString("chineseInputSettings.spaceAction") }
    static var spaceAction_nextPage: String { localizedString("chineseInputSettings.spaceAction.nextPage") }
    static var spaceAction_insertCandidate: String { localizedString("chineseInputSettings.spaceAction.insertCandidate") }
    static var spaceAction_insertText: String { localizedString("chineseInputSettings.spaceAction.insertText") }
    static var showRomanizationMode: String { localizedString("chineseInputSettings.showRomanizationMode") }
    static var showRomanizationMode_never: String { localizedString("chineseInputSettings.showRomanizationMode.never") }
    static var showRomanizationMode_always: String { localizedString("chineseInputSettings.showRomanizationMode.always") }
    static var showRomanizationMode_onlyInNonCantoneseMode: String { localizedString("chineseInputSettings.showRomanizationMode.onlyInNonCantoneseMode") }
    static var showCodeInReverseLookup: String { localizedString("chineseInputSettings.showCodeInReverseLookup") }
    static var enableCompletion: String { localizedString("chineseInputSettings.enableCompletion") }
    static var enableCorrector: String { localizedString("chineseInputSettings.enableCorrector") }
    static var enableCorrector_description: String { localizedString("chineseInputSettings.enableCorrector.description") }
    static var enableSentence: String { localizedString("chineseInputSettings.enableSentence") }
    static var enableLearning: String { localizedString("chineseInputSettings.enableLearning") }
    static var enableLearning_description: String { localizedString("chineseInputSettings.enableLearning.description") }
    static var cantoneseKeyboardLayout: String { localizedString("chineseInputSettings.cantoneseKeyboardLayout") }
    static var cantoneseKeyboardLayout_qwerty: String { localizedString("chineseInputSettings.cantoneseKeyboardLayout.qwerty") }
    static var cantoneseKeyboardLayout_tenKeys: String { localizedString("chineseInputSettings.cantoneseKeyboardLayout.tenKeys") }
    static var toneInputMode: String { localizedString("chineseInputSettings.toneInputMode") }
    static var toneInputMode_vxq: String { localizedString("chineseInputSettings.toneInputMode.vxq") }
    static var toneInputMode_longPress: String { localizedString("chineseInputSettings.toneInputMode.longPress") }
    static var toneInputMode_description: String { localizedString("chineseInputSettings.toneInputMode.description") }
    static var cangjieVersion: String { localizedString("chineseInputSettings.cangjieVersion") }
    static var cangjie3: String { localizedString("chineseInputSettings.cangjie3") }
    static var cangjie5: String { localizedString("chineseInputSettings.cangjie5") }
    
    static var englishInputSettings: String { localizedString("englishInputSettings") }
    static var autoCap: String { localizedString("englishInputSettings.autoCap") }
    static var englishLocale: String { localizedString("englishInputSettings.englishLocale") }
    static var englishLocale_au: String { localizedString("englishInputSettings.englishLocale.au") }
    static var englishLocale_ca: String { localizedString("englishInputSettings.englishLocale.ca") }
    static var englishLocale_gb: String { localizedString("englishInputSettings.englishLocale.gb") }
    static var englishLocale_us: String { localizedString("englishInputSettings.englishLocale.us") }
    
    static var other: String { localizedString("other") }
    static var other_onboarding: String { localizedString("other.onboarding") }
    static var other_faq: String { localizedString("other.faq") }
    static var other_about: String { localizedString("other.about") }
    
    static var onboarding_skip: String { localizedString("onboarding.skip") }
    static var onboarding_jumpToSettings: String { localizedString("onboarding.jumpToSettings") }
    static var onboarding_done: String { localizedString("onboarding.done") }
    
    static var onboarding_0_heading: String { localizedString("onboarding.0.heading") }
    static var onboarding_0_content: String { localizedString("onboarding.0.content") }
    static var onboarding_1_heading: String { localizedString("onboarding.1.heading") }
    static var onboarding_1_content: String { localizedString("onboarding.1.content") }
    static var onboarding_2_heading: String { localizedString("onboarding.2.heading") }
    static var onboarding_2_content: String { localizedString("onboarding.2.content") }
    static var onboarding_3_heading: String { localizedString("onboarding.3.heading") }
    static var onboarding_3_content: String { localizedString("onboarding.3.content") }
    static var onboarding_3_footnote: String { localizedString("onboarding.3.footnote") }
    static var onboarding_4_heading: String { localizedString("onboarding.4.heading") }
    static var onboarding_4_content: String { localizedString("onboarding.4.content") }
    static var onboarding_5_heading: String { localizedString("onboarding.5.heading") }
    static var onboarding_5_content: String { localizedString("onboarding.5.content") }
    static var onboarding_5_footnote: String { localizedString("onboarding.5.footnote") }
    static var onboarding_5_installed_heading: String { localizedString("onboarding.5.installed.heading") }
    static var onboarding_5_installed_content: String { localizedString("onboarding.5.installed.content") }
    
    static var about_links: String { localizedString("about.links") }
    static var about_description: String { localizedString("about.description") }
    static var about_typeduckSite: String { localizedString("about.typeduckSite") }
    static var about_jyutpingSite: String { localizedString("about.jyutpingSite") }
    static var about_sourceCode: String { localizedString("about.sourceCode") }
    static var about_cantoboard: String { localizedString("about.cantoboard") }
    static var about_credit: String { localizedString("about.credit") }
}
