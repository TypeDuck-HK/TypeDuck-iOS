//
//  KeyboardViewLayout.swift
//  CantoboardFramework
//
//  Created by Alex Man on 8/24/21.
//

import Foundation
import UIKit

enum GroupLayoutDirection {
    case left, middle, right
}

protocol KeyboardViewLayout {
    static var numOfRows: Int { get };
    
    static var letters: [[[KeyCap]]] { get };
    static var numbersHalf: [[[KeyCap]]] { get };
    static var symbolsHalf: [[[KeyCap]]] { get };
    static var numbersFull: [[[KeyCap]]] { get };
    static var symbolsFull: [[[KeyCap]]] { get };
    
    static func layoutKeyViews(keyRowView: KeyRowView, leftKeys: [KeyView], middleKeys: [KeyView], rightKeys: [KeyView], layoutConstants: LayoutConstants) -> [CGRect]
    static func getContextualKeys(key: ContextualKey, keyboardState: KeyboardState) -> KeyCap?
    static func getKeyHeight(atRow: Int, layoutConstants: LayoutConstants) -> CGFloat
    static func getSwipeDownKeyCap(keyCap: KeyCap, keyboardState: KeyboardState) -> KeyCap?
    static func isSwipeDownKeyShiftMorphing(keyCap: KeyCap) -> Bool
}

class CommonContextualKeys {
    static func getContextualKeys(key: ContextualKey, keyboardState: KeyboardState) -> KeyCap? {
        switch key {
        case .symbol:
            let keyCap: KeyCap = {
                switch keyboardState.keyboardContextualType {
                case .chinese: return .character("，", KeyCapHints(rightHint: "符"), ["，", "。", "？", "！", "、", ".", ",", KeyCap(rime: .sym)])
                case .english: return .character(",", KeyCapHints(rightHint: "符"), [",", ".", "?", "!", "。", "，", KeyCap(rime: .sym)])
                case .url: return .character(".", KeyCapHints(rightHint: "/"), ["/", ".", ".com", ".net", ".org", ".edu"])
                }
            }()
            if keyboardState.shouldDisplayRimeDelimiterKey {
                var childrenKeyCaps = keyCap.childrenKeyCaps
                childrenKeyCaps.insert(KeyCap(rime: .delimiter), at: 0)
                return .rime(.delimiter, keyCap.rawButtonHints, childrenKeyCaps)
            }
            return keyCap
        case .extraSymbol:
            switch keyboardState.keyboardType {
            case .alphabetic: return keyboardState.keyboardContextualType.halfWidthSymbol ? "." : "。"
            default: return "`"
            }
        case ",": return keyboardState.keyboardContextualType.halfWidthSymbol ? "," : "，"
        case ".": return keyboardState.keyboardContextualType.halfWidthSymbol ? "." : "。"
        case .padKeyboardType(let type):
            switch keyboardState.keyboardContextualType {
            case .url:
                let domains = [".com", "." + SessionState.main.localDomain, ".hk", ".tw", ".mo", ".cn", ".uk", ".jp", ".kr", ".net", ".edu", ".org"].unique()
                var childrenKeyCaps = domains.map(KeyCap.init(_:))
                if keyboardState.shouldDisplayRimeDelimiterKey {
                    childrenKeyCaps.insert(KeyCap(rime: .delimiter), at: 0)
                    return .rime(.delimiter, KeyCapHints(rightHint: ".com"), childrenKeyCaps)
                }
                return .character(".com", nil, childrenKeyCaps)
            default: return keyboardState.shouldDisplayRimeDelimiterKey ? KeyCap(rime: .delimiter) : .keyboardType(type)
            }
        default: return nil
        }
    }
}

class CommonSwipeDownKeys {
    static func getSwipeDownKeyCapForPadShortOrFull4Rows(keyCap: KeyCap, keyboardState: KeyboardState) -> KeyCap? {
        let isInChineseContextualMode = !keyboardState.keyboardContextualType.halfWidthSymbol
        let keyCapCharacter: String?
        switch keyCap {
        case .character(let c, _, _), .cangjie(let c, _, _, _): keyCapCharacter = c.lowercased()
        case .currency: keyCapCharacter = "$"
        case .singleQuote: keyCapCharacter = "'"
        case .doubleQuote: keyCapCharacter = "\""
        default: keyCapCharacter = nil
        }
        switch keyCapCharacter {
        case "q": return "1"
        case "w": return "2"
        case "e": return "3"
        case "r": return "4"
        case "t": return "5"
        case "y": return "6"
        case "u": return "7"
        case "i": return "8"
        case "o": return "9"
        case "p": return "0"
        case "a": return "@"
        case "s": return "#"
        case "d": return KeyCap(SessionState.main.currencySymbol)
        case "f": return KeyCap(isInChineseContextualMode ? "／" : "/").symbolTransform(state: keyboardState)
        case "g": return KeyCap(isInChineseContextualMode ? "（" : "(").symbolTransform(state: keyboardState)
        case "h": return KeyCap(isInChineseContextualMode ? "）" : ")").symbolTransform(state: keyboardState)
        case "j": return "「"
        case "k": return "」"
        case "l": return .singleQuote
        case "z": return "%"
        case "x": return isInChineseContextualMode ? "—" : "-"
        case "c": return isInChineseContextualMode ? "～" : "~"
        case "v": return isInChineseContextualMode ? "⋯" : "…"
        case "b": return isInChineseContextualMode ? "、" : "､"
        case "n": return isInChineseContextualMode ? "；" : ";"
        case "m": return KeyCap(isInChineseContextualMode ? "：" : ":").symbolTransform(state: keyboardState)
        case ",": return "!"
        case ".": return "?"
        case "，": return "！"
        case "。": return "？"
        case "@": return "^"
        case "#": return "_"
        case "$": return isInChineseContextualMode ? "｜" : "|"
        case "/": return "\\"
        case "／": return "＼"
        case "(": return "["
        case ")": return "]"
        case "（": return "［"
        case "）": return "］"
        case "｢": return "{"
        case "｣": return "}"
        case "「": return "｛"
        case "」": return "｝"
        case "'": return .doubleQuote
        case "%": return "*"
        case "-", "—": return "&"
        case "~", "～": return "+"
        case "…", "⋯": return "="
        case "､": return "•"
        case "、": return "·"
        case ";": return "<"
        case "；": return "《"
        case ":": return ">"
        case "：": return "》"
        default: return nil
        }
    }
}

extension LayoutIdiom {
    var keyboardViewLayout: KeyboardViewLayout.Type {
        switch self {
        case .phone: return PhoneKeyboardViewLayout.self
        case .pad(.padShort): return PadShortKeyboardViewLayout.self
        case .pad(.padFull4Rows): return PadFull4RowsKeyboardViewLayout.self
        case .pad(.padFull5Rows): return PadFull5RowsKeyboardViewLayout.self
        }
    }
}
