//
//  LocalizedStrings.swift
//  CantoboardFramework
//
//  Created by Alex Man on 8/21/21.
//

import Foundation

class LocalizedStrings {
    private static func localizedString(_ stringKeyName: String) -> String  {
        return NSLocalizedString(stringKeyName, bundle: Bundle(path: Bundle(for: LocalizedStrings.self).path(forResource: Settings.cached.interfaceLanguage == .chinese ? "zh-HK" : "en", ofType: "lproj")!)!, comment: "Key Title of " + stringKeyName)
    }
    
    static var keyTitleNextPage: String { localizedString("KeyNextPage") }
    static var keyTitleSelect: String { localizedString("KeySelect") }
    static var keyTitleSpace: String { localizedString("KeySpace") }
    static var keyTitleFullWidthSpace: String { localizedString("KeyFullWidthSpace") }
    static var keyTitleConfirm: String { localizedString("KeyConfirm") }
    static var keyTitleGo: String { localizedString("KeyGo") }
    static var keyTitleNext: String { localizedString("KeyNext") }
    static var keyTitleSend: String { localizedString("KeySend") }
    static var keyTitleSearch: String { localizedString("KeySearch") }
    static var keyTitleContinue: String { localizedString("KeyContinue") }
    static var keyTitleDone: String { localizedString("KeyDone") }
    static var keyTitleSOS: String { localizedString("KeySOS") }
    static var keyTitleJoin: String { localizedString("KeyJoin") }
    static var keyTitleRoute: String { localizedString("KeyRoute") }
    static var keyTitleReturn: String { localizedString("KeyReturn") }
    
    static var wildcardHint: String { localizedString("WildcardHint") }
    
    static var alert_VoiceFeaturesUnavailable_Title: String { localizedString("Alert.VoiceFeaturesUnavailable.Title") }
    static var alert_VoiceFeaturesUnavailable_Message: String { localizedString("Alert.VoiceFeaturesUnavailable.Message") }
    static var alert_NoCantoneseVoice_Title: String { localizedString("Alert.NoCantoneseVoice.Title") }
    static var alert_NoCantoneseVoice_Message: String { localizedString("Alert.NoCantoneseVoice.Message") }
    static var alert_OK: String { localizedString("Alert.OK") }
    static var alert_Settings: String { localizedString("Alert.Settings") }
}
