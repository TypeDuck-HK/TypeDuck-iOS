//
//  Character+Extension.swift
//  KeyboardKit
//
//  Created by Alex Man on 2/11/21.
//

import Foundation

extension Character {
    var isEnglishLetter: Bool {
        isASCII && isLetter
    }
    
    var isDigit: Bool {
        isASCII && isNumber
    }
    
    var isEnglishLetterOrDigit: Bool {
        isEnglishLetter || isDigit
    }
    
    var isHalfwidthSentenceTerminal: Bool {
        // TODO Distingish apostrophe & single quote.
        isSentenceTerminal && unicodeScalars.first?.isHalfwidth ?? false
    }
    
    var isFullwidthSentenceTerminal: Bool {
        isSentenceTerminal && unicodeScalars.first?.isFullwidth ?? false
    }
    
    var isSentenceTerminal: Bool {
        unicodeScalars.first?.properties.isSentenceTerminal ?? false
    }
    
    var isTerminalPunctuation: Bool {
        unicodeScalars.first?.properties.isTerminalPunctuation ?? false
    }
    
    var couldBeFollowedBySmartFullStop: Bool {
        !isWhitespace && !isTerminalPunctuation && self != "-"
    }
    
    var couldBeFollowedBySmartSpace: Bool {
        if isTerminalPunctuation { return false }
        switch unicodeScalars.first?.properties.generalCategory {
        case .closePunctuation, .finalPunctuation: return false
        default: ()
        }
        switch self {
        case "'", "-", "/": return false
        default: return true
        }
    }
    
    var lowercasedChar: Character {
        lowercased().first ?? self
    }
    
    var isRimeSpecialChar: Bool {
        let isFixedRimeSpecialChar = self == "'" || self == "\"" || self == "/"
        let isModeDependentRimeSpecialChar = Settings.cached.toneInputMode == .longPress && isDigit
        return isFixedRimeSpecialChar || isModeDependentRimeSpecialChar
    }
    
    var isChineseChar: Bool {
        unicodeScalars.first?.properties.isIdeographic ?? false
    }
}
