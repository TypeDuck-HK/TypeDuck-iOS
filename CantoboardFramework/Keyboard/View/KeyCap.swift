//
//  KeyCap.swift
//  KeyboardKit
//
//  Created by Alex Man on 2/11/21.
//

import Foundation
import UIKit

/**
 This action enum specifies all currently supported keyboard
 actions and their standard behavior.
 
 Most actions have a standard behavior for a certain gesture
 when their used in system keyboards. This standard behavior
 is provided through `standardInputViewControllerAction` and
 `standardTextDocumentProxyAction`. Keyboard action handlers
 can choose to use these standard actions or ignore them.
 
 Many actions require manual handling since they do not have
 universal, app-agnostic behaviors. For instance, the `image`
 action depends on what you want to do with the tapped image.
 Actions like these are a way for you to express your intent,
 but require manual handling in a custom action handler.
*/
enum SpaceKeyMode: String {
    case space = "space"
    case fullWidthSpace = "fullWidthSpace"
    case select = "select"
    case nextPage = "next page"
    
    var isSpace: Bool {
        switch self {
        case .space, .fullWidthSpace: return true
        default: return false
        }
    }
}

enum ReturnKeyType: Int {
    case confirm = -1
    case `default` = 0
    case go = 1
    case google = 2
    case join = 3
    case next = 4
    case route = 5
    case search = 6
    case send = 7
    case yahoo = 8
    case done = 9
    case emergencyCall = 10

    @available(iOS 9.0, *)
    case `continue` = 11
    
    public init(_ returnKeyType: UIReturnKeyType) {
        self = ReturnKeyType(rawValue: returnKeyType.rawValue) ?? .default
    }
    
    /// Whether the return key should be accented, i.e. colored in `UIColor.systemBlue`.
    fileprivate var isProminent: Bool {
        switch self {
        case .continue, .next, .default, .confirm: return false
        default: return true
        }
    }
}

enum KeyCapType {
    case input, system, returnKey, space
}

enum ContextualKey: Equatable, ExpressibleByStringLiteral {
    case symbol
    case extraSymbol
    case url
    case character(String)
    
    public init(stringLiteral value: String) {
        self = .character(value)
    }
}

struct KeyCapHints: Equatable {
    let leftHint, rightHint, bottomHint: String?
    
    public init(rightHint: String) {
        self.init(leftHint: nil, rightHint: rightHint, bottomHint: nil)
    }
    
    public init(leftHint: String? = nil, rightHint: String? = nil, bottomHint: String? = nil) {
        self.leftHint = leftHint
        self.rightHint = rightHint
        self.bottomHint = bottomHint
    }
}

indirect enum KeyCap: Equatable, ExpressibleByStringLiteral {
    case
    none,
    backspace,
    toggleInputMode(_ toMode: InputMode, _ mainSchema: RimeSchema?, _ reverseLookupSchema: RimeSchema? = nil),
    character(String, KeyCapHints?, /* children key caps */ [KeyCap]?),
    cangjie(String, KeyCapHints?, /* children key caps */ [KeyCap]?, CangjieKeyCapMode),
    stroke(String),
    jyutPing10Keys(String),
    jyutPingInitialFinal(InitialFinalKeyboardView.KeyCapType, String),
    selectRomanization,
    emoji(String),
    keyboardType(KeyboardType),
    moveCursorBackward,
    moveCursorForward,
    returnKey(ReturnKeyType),
    nextKeyboard,
    space(SpaceKeyMode),
    shift(_ state: KeyboardShiftState),
    rime(RimeChar, KeyCapHints?, /* children key caps */ [KeyCap]?),
    contextual(ContextualKey),
    reverseLookup(RimeSchema),
    exportFile(String, String),
    singleQuote,
    doubleQuote,
    currency,
    dismissKeyboard,
    exit,
    placeholder(KeyCap),
    combo(/* Combo keycaps */ [String]), // e.g. combo(["A", "B"]) click once to insert A, click twice to replace A with B.
    keypadRimeDelimiter
    
    public init(stringLiteral value: String) {
        self = .character(value, nil, nil)
    }
    
    public init(_ char: String) {
        self = .character(char, nil, nil)
    }
    
    public init(rime char: RimeChar) {
        self = .rime(char, nil, nil)
    }
    
    var action: KeyboardAction {
        switch self {
        case .none: return .none
        case .backspace: return .backspace
        case .toggleInputMode(let toInputMode, _, _): return .toggleInputMode(toInputMode)
        case .character(let c, _, _): return .character(c)
        case .cangjie(let c, _, _, _): return .character(c)
        case .stroke(let c), .jyutPing10Keys(let c), .jyutPingInitialFinal(.punctuation, let c): return .character(c)
        case .jyutPingInitialFinal(.initial, let c), .jyutPingInitialFinal(.tone, let c): return .initialFinalTone(c)
        case .jyutPingInitialFinal(.final, let c): return .initialFinalTone("9\(c)0")
        case .emoji(let e): return .emoji(e)
        case .keyboardType(let type): return .keyboardType(type)
        case .moveCursorBackward: return .moveCursorBackward
        case .moveCursorForward: return .moveCursorForward
        case .returnKey: return .newLine
        case .nextKeyboard: return .nextKeyboard
        case .space(let spaceKeyMode): return .space(spaceKeyMode)
        case .shift(let shiftState): return .shift(shiftState)
        case .rime(let rc, _, _): return .rime(rc)
        case .reverseLookup(let s): return .reverseLookup(s)
        case .exportFile(let namePrefix, let path): return .exportFile(namePrefix, path)
        case .exit: return .exit
        case .currency: return .character(SessionState.main.currencySymbol)
        case .singleQuote: return .quote(false)
        case .doubleQuote: return .quote(true)
        case .dismissKeyboard: return .dismissKeyboard
        case .combo: return .none // Dynamically evaluated in KeyView.
        case .keypadRimeDelimiter: return .rime(.delimiter)
        case .selectRomanization: return .toggleTenKeysSpecialization
        default: return .none
        }
    }
    
    var character: Character? {
        switch self {
        case .character(let c, _, _): return c.first ?? nil
        default: return nil
        }
    }
    
    private var shouldUseCustomizedKeyColors: Bool {
        guard Settings.cached.cantoneseKeyboardLayout == .initialFinal && Settings.cached.jyutpingInitialFinalLayoutSettings.customizeKeyColor else { return false }
        if case .jyutPingInitialFinal = self { return true }
        return keyCapType != .input
    }
    
    var buttonBgColor: UIColor {
        if shouldUseCustomizedKeyColors {
            switch self {
            case .jyutPingInitialFinal(let type, _):
                switch type {
                case .initial: return Settings.cached.jyutpingInitialFinalLayoutSettings.initialKeyColor
                case .final: return Settings.cached.jyutpingInitialFinalLayoutSettings.finalKeyColor
                case .tone: return Settings.cached.jyutpingInitialFinalLayoutSettings.toneKeyColor
                case .punctuation: return Settings.cached.jyutpingInitialFinalLayoutSettings.punctuationKeyColor
                }
            case .space: return Settings.cached.jyutpingInitialFinalLayoutSettings.spaceKeyColor
            default: return Settings.cached.jyutpingInitialFinalLayoutSettings.systemKeyColor
            }
        }
        switch self {
        case .returnKey(let type) where type.isProminent: return UIColor.systemBlue
        case .shift(.uppercased), .shift(.capsLocked): return ButtonColor.shiftKeyHighlightedBackgroundColor
        case _ where keyCapType == .input || keyCapType == .space: return ButtonColor.inputKeyBackgroundColor
        default: return ButtonColor.systemKeyBackgroundColor
        }
    }
    
    var buttonBgHighlightedColor: UIColor {
        switch self {
        case _ where shouldUseCustomizedKeyColors: return buttonBgColor.blended(withFraction: 0.3, of: buttonBgColor.fgColor)
        case .shift(.uppercased), .shift(.capsLocked): return buttonBgColor
        case _ where keyCapType == .input || keyCapType == .space: return ButtonColor.inputKeyHighlightedBackgroundColor
        default: return ButtonColor.systemKeyHighlightedBackgroundColor
        }
    }
    
    var buttonBgHighlightedShadowColor: UIColor {
        switch keyCapType {
        case .input, .space: return ButtonColor.keyHighlightedShadowColor
        default: return ButtonColor.keyShadowColor
        }
    }
    
    var keyCapType: KeyCapType {
        switch self {
        case "\t": return .system
        case .character, .cangjie, .contextual, .currency, .singleQuote, .doubleQuote, .stroke, .jyutPing10Keys, .jyutPingInitialFinal, .rime, .combo: return .input
        case .space: return .space
        case .returnKey: return .returnKey
        default: return .system
        }
    }
    
    var keypadButtonBgHighlightedColor: UIColor {
        switch self {
        case .keyboardType, .backspace, .none, .returnKey: return ButtonColor.systemKeyHighlightedBackgroundColor
        default: return ButtonColor.inputKeyHighlightedBackgroundColor
        }
    }
    
    var buttonFgColor: UIColor {
        switch self {
        case _ where shouldUseCustomizedKeyColors: return buttonBgColor.fgColor
        case .returnKey(let type) where type.isProminent: return .white
        case .shift(.uppercased), .shift(.capsLocked): return ButtonColor.shiftKeyHighlightedForegroundColor
        default: return ButtonColor.keyForegroundColor
        }
    }
    
    var buttonHintFgColor: UIColor {
        return shouldUseCustomizedKeyColors ? buttonBgColor.fgColor.withAlphaComponent(0.7) : ButtonColor.keyHintColor
    }
    
    // TODO Return images < iOS 12
    var buttonImage: UIImage? {
        switch self {
        case "\t": return ButtonImage.tab
        case .backspace: return ButtonImage.backspace
        case .nextKeyboard: return ButtonImage.globe
        case .shift(.lowercased): return ButtonImage.shift
        case .shift(.uppercased): return ButtonImage.shiftFilled
        case .shift(.capsLocked): return ButtonImage.capLockFilled
        case .dismissKeyboard: return ButtonImage.dismissKeyboard
        case .keyboardType(.emojis): return ButtonImage.emojiKeyboardLight
        case .moveCursorBackward: return ButtonImage.moveCursorBackward
        case .moveCursorForward: return ButtonImage.moveCursorForward
        default: return nil
        }
    }
    
    var buttonText: String? {
        switch self {
        case .returnKey(.confirm): return LocalizedStrings.keyTitleConfirm
        case .returnKey(.go): return LocalizedStrings.keyTitleGo
        case .returnKey(.next): return LocalizedStrings.keyTitleNext
        case .returnKey(.send): return LocalizedStrings.keyTitleSend
        case .returnKey(.search), .returnKey(.google), .returnKey(.yahoo): return LocalizedStrings.keyTitleSearch
        case .returnKey(.continue): return LocalizedStrings.keyTitleContinue
        case .returnKey(.done): return LocalizedStrings.keyTitleDone
        case .returnKey(.emergencyCall): return LocalizedStrings.keyTitleSOS
        case .returnKey(.join): return LocalizedStrings.keyTitleJoin
        case .returnKey(.route): return LocalizedStrings.keyTitleRoute
        case .returnKey: return LocalizedStrings.keyTitleReturn
        case .space(.nextPage): return LocalizedStrings.keyTitleNextPage
        case .space(.select): return LocalizedStrings.keyTitleSelect
        case .space(.space): return LocalizedStrings.keyTitleSpace
        case .space(.fullWidthSpace): return LocalizedStrings.keyTitleFullWidthSpace
        case .keyboardType(.numeric): return "123"
        case .keyboardType(.symbolic): return "#+="
        case .keyboardType(.alphabetic): return "ABC"
        case .keyboardType(.numSymbolic): return ".?123"
        case .rime(.tone1, _, _): return "陰平"
        case .rime(.tone2, _, _): return "陰上"
        case .rime(.tone3, _, _): return "陰去"
        case .rime(.tone4, _, _): return "陽平"
        case .rime(.tone5, _, _): return "陽上"
        case .rime(.tone6, _, _): return "陽去"
        case .rime(.delimiter, _, _): return "分"
        case .rime(.sym, _, _): return "符"
        case .reverseLookup(let schema): return schema.signChar
        case .toggleInputMode(.english, _, /* reverseLookupSchema */ nil): return "英文"
        case .toggleInputMode(_, let mainSchema, _): return mainSchema?.shortName
        case .singleQuote: return "′"
        case .doubleQuote: return "″"
        case "（", "「", "『", "〈", "《", "｛", "【", "〔", "〚", "〖", "〘":
            if #available(iOS 17, *) {
                // In iOS 17 or above, most characters are automatically kerned.
                return String(character!)
            } else {
                return String(character!) + "⠀"
            }
        case "）", "」", "』", "〉", "》", "｝", "】", "〕", "〛", "〗", "〙":
            if #available(iOS 17, *) {
                return String(character!)
            } else {
                return "⠀" + String(character!)
            }
        case "［": return "［⠀"
        case "］": return "⠀］"
        case "｟": return "｟⠀"
        case "｠": return "⠀｠"
        case "〝": return "〝⠀"
        case "〞": return "⠀〞"
        case "〟": return "⠀〟"
        case "\t": return nil
        case "——": return "⸻"
        case .character(let text, _, _): return text
        case .cangjie(let letter, _, _, let cangjieKeyCapMode): return cangjieKeyCapMode == .cangjieRoot ? CangjieConstants.cangjieKeyCaps(letter) : letter
        case .stroke(let c):
            switch c.lowercased() {
            case "h": return "一"
            case "s": return "丨"
            case "p": return "丿"
            case "n": return "丶"
            case "z": return "乛"
            default: return nil
            }
        case .jyutPing10Keys(let c):
            switch c {
            case "A": return "A B C"
            case "D": return "D E F"
            case "G": return "G H I"
            case "J": return "J K L"
            case "M": return "M N O"
            case "P": return "P Q R S"
            case "T": return "T U V"
            case "W": return "W X Y Z"
            default: return nil
            }
        case .jyutPingInitialFinal(.initial, "G"): return "gw"
        case .jyutPingInitialFinal(.initial, "K"): return "kw"
        case .jyutPingInitialFinal(.initial, "N"): return "ng"
        case .jyutPingInitialFinal(.initial, "X"): return "＊"
        case .jyutPingInitialFinal(_, let c): return c
        case .selectRomanization: return "選拼音"
        case .exportFile(let namePrefix, _): return namePrefix.capitalized
        case .currency: return SessionState.main.currencySymbol
        case .exit: return "Exit"
        case .combo(let items): return items.joined()
        case .keypadRimeDelimiter: return "分隔"
        default: return nil
        }
    }
    
    var buttonTitleInset: UIEdgeInsets {
        switch self {
        case .cangjie(_, let hints, _, _) where hints != nil: return UIEdgeInsets(top: 4, left: 0, bottom: 0, right: 0)
        case _ where keyCapType == .input: return UIEdgeInsets(top: 2, left: 0, bottom: 0, right: 0)
        default: return .zero
        }
    }
    
    var buttonLeftHint: String? {
        switch self {
        case .character(_, let hints, _), .rime(_, let hints, _), .cangjie(_, let hints, _, _): return hints?.leftHint
        default: return nil
        }
    }
    
    var buttonRightHint: String? {
        switch self {
        case .character(_, let hint, _), .rime(_, let hint, _): return hint?.rightHint ?? barHint
        case .cangjie(let letter, _, _, let cangjieKeyCapMode): return cangjieKeyCapMode == .cangjieRoot ? letter : CangjieConstants.cangjieKeyCaps(letter)
        case .space: return "TypeDuck"
        case .jyutPingInitialFinal(.tone, "1"): return "陰平"
        case .jyutPingInitialFinal(.tone, "2"): return "陰上"
        case .jyutPingInitialFinal(.tone, "3"): return "陰去"
        case .jyutPingInitialFinal(.tone, "4"): return "陽平"
        case .jyutPingInitialFinal(.tone, "5"): return "陽上"
        case .jyutPingInitialFinal(.tone, "6"): return "陽去"
        default: return barHint
        }
    }
    
    var buttonBottomHint: String? {
        switch self {
        case .character(_, let hints, _), .rime(_, let hints, _), .cangjie(_, let hints, _, _): return hints?.bottomHint
        default: return nil
        }
    }
    
    var barHint: String? {
        switch self {
        case "，", "。", "．", "？", "！",
             "－", "／", "：", "；", "（", "）", "＠", "、", "⋯", "⋯⋯", "＆",
             "１", "２", "３", "４", "５", "６", "７", "８", "９", "０",
             "［", "］", "｛", "｝", "＃", "％", "＾", "＊", "＋", "＝",
             "＿", "￣", "＼", "｜", "～", "＜", "＞", "〈", "〉", "｟", "｠", "《", "》",
             "＄", "￥", "￦", "￡", "￠", "＂", "＇", "〝", "〞", "〟", "｀": return "全"
        case "′", "″", "×", "√", "∕", "÷", "∅": return "數"
        case "ʼ", "꞉", "ː", "͡", "˥", "˦", "˧", "˨", "˩": return "聲"
        case "ˈ", "ˌ", "ˋ", "ˎ", "ˊ", "ˏ", "ˉ", "ˍ", "ˆ", "ˇ": return "調"
        default: return nil
        }
    }
    
    var hasPopup: Bool {
        switch self {
        // For debugging
        case .keyboardType(.emojis): return true
        default: return keyCapType == .input
        }
    }
    
    func enqueueForSpeaking() {
        guard Settings.cached.accessibilitySettings.speechFeedbackEnabledForCharacters else { return }
        if let fileName = audioFileName {
            SpeechProvider.enqueue(.initialFinal, fileName)
        } else if let text = spokenText {
            SpeechProvider.enqueue(.character, text)
        }
    }
    
    var audioFileName: String? {
        switch self {
        case .jyutPingInitialFinal(.initial, "G"): return "gw"
        case .jyutPingInitialFinal(.initial, "K"): return "kw"
        case .jyutPingInitialFinal(.initial, "N"): return "ng"
        case .jyutPingInitialFinal(.initial, "X"): return nil // Speak spokenText ("百搭") with synthesizer
        case .jyutPingInitialFinal(.initial, let c): return c
        case .jyutPingInitialFinal(.final, let c): return "_" + c
        case .jyutPingInitialFinal(.tone, let c): return "__" + c
        default: return nil
        }
    }
    
    var spokenText: String? {
        switch self {
        case .rime(.delimiter, _, _): return "分隔"
        case .rime(.sym, _, _): return "符號"
        case .rime: return buttonText
        case .singleQuote, "'", "＇": return "單引號"
        case .doubleQuote, "\"", "＂": return "雙引號"
        case ".", "．": return "句點"
        case "｡", "。": return "句號"
        case ",", "，": return "逗號"
        case "､", "、": return "頓號"
        case "?", "？": return "問號"
        case "!", "！": return "感歎號"
        case ":", "：": return "冒號"
        case ";", "；": return "分號"
        case "…", "⋯", "⋯⋯": return "省略號"
        case "–", "—", "——": return "破折號"
        case "｢", "「": return "開引號"
        case "｣", "」": return "閂引號"
        case "(", "（": return "左括號"
        case ")", "）": return "右括號"
        case "[", "［": return "左方括號"
        case "]", "］": return "右方括號"
        case "{", "｛": return "左花括號"
        case "}", "｝": return "右花括號"
        case "/", "／": return "斜線"
        case "\\", "＼": return "反斜線"
        case "|", "｜": return "垂直線"
        case .character(let text, _, _) where text.first?.isUppercase ?? false: return "大階" + text
        case .character(let text, _, _): return text
        case .emoji(let text): return text
        case .stroke(let c):
            switch c.lowercased() {
            case "h": return "橫"
            case "s": return "豎"
            case "p": return "撇"
            case "n": return "點"
            case "z": return "折"
            default: return nil
            }
        case .jyutPingInitialFinal(.initial, "X"): return "百搭"
        case .jyutPingInitialFinal(.punctuation, let c): return KeyCap(c).spokenText
        case .cangjie, .jyutPing10Keys, .currency, .keypadRimeDelimiter: return buttonText
        default: return nil
        }
    }
    
    private static var logsPath: String = DataFileManager.logsDirectory
    private static let userDataPath: String = DataFileManager.userDataDirectory
    private static let tmpPath: String = FileManager.default.temporaryDirectory.path
    
    var withoutHints: KeyCap {
        switch self {
        case .character(let c, _, _): return KeyCap(c)
        // case .cangjie(let c, _): return .cangjie(c, false)
        default: return self
        }
    }
    
    var childrenKeyCaps: [KeyCap] {
        switch self {
        // For debugging
        case .keyboardType(.emojis): return [self, .exportFile("logs", Self.logsPath), .exportFile("user", Self.userDataPath), .exportFile("rime", Self.tmpPath), .exit]
        case .character(_, _, let keyCaps) where keyCaps != nil: return keyCaps!
        case .cangjie(_, _, let keyCaps, _) where keyCaps != nil: return keyCaps!
        case .rime(_, _, let keyCaps) where keyCaps != nil: return keyCaps!
        // 123 1st row
        case "1": return ["1", "一", "壹", "１", "①", "⑴", "⒈", "❶", "㊀", "㈠"]
        case "2": return ["貳", "2", "二", "２", "②", "⑵", "⒉", "❷", "㊁", "㈡"]
        case "3": return ["③", "叁", "3", "三", "３", "⑶", "⒊", "❸", "㊂", "㈢"]
        case "4": return ["⒋", "④", "肆", "4", "四", "４", "⑷", "❹", "㊃", "㈣"]
        case "5": return ["㊄", "⒌", "⑤", "伍", "5", "五", "５", "⑸", "❺", "㈤"]
        case "6": return ["❻", "⑹", "６", "六", "6", "陸", "⑥", "⒍", "㊅", "㈥"]
        case "7": return ["⑺", "７", "七", "7", "柒", "⑦", "⒎", "❼", "㊆", "㈦"]
        case "8": return ["８", "八", "8", "捌", "⑧", "⑻", "⒏", "❽", "㊇", "㈧"]
        case "9": return ["九", "9", "玖", "９", "⑨", "⑼", "⒐", "❾", "㊈", "㈨"]
        case "0": return ["0", "０", "〇", "零", "⓪", "🄀", "⓿", "十", "拾", "⑩", "⑽", "⒑", "➓", "㊉", "㈩"]
        // 123 2nd row
        case "-": return ["-", "－", "–", "—", "‑", "•", "˧"]
        case "/": return ["/", "／", "✓", "√", "∕", "÷", "ˊ", "ˏ"]
        case ":": return [":", "：", "꞉", "ː"]
        case ";": return [";", "；"]
        case "(": return ["（", "(", "⦅", "⸨", "｟", "͡"]
        case ")": return ["）", ")", "⦆", "⸩", "｠", "͡"]
        case .doubleQuote: return ["”", "“", "\"", "„", "＂", "〟", "〞", "〝", "″", "〃", "»", "«"]
        case "「": return ["「", "『", "“", "‘", "｢", "˥", "˦"]
        case "」": return ["」", "』", "”", "’", "｣", "˩", "˨"]
        // 123 3rd row
        case ".": return [".", "。", "．", "…", "⋯", "⋯⋯"]
        case ",": return [",", "，"]
        case "､": return ["､", "、"]
        case "^_^": return ["^‿^", "^_^", ">_<"]
        case "?": return ["?", "？", "¿"]
        case "!": return ["!", "！", "¡"]
        case .singleQuote: return ["`", "'", "’", "‘", "＇", "｀", "′", "ʼ", "ˌ", "ˈ", "›", "‹"]
        // 123 4rd row
        case "@": return ["@", "＠", "©", "®", "℗", "™", "℠", "∅"]
        // #+= 1st row
        case "[": return ["[", "［", "【", "〔", "〚", "〖", "〘"]
        case "]": return ["]", "］", "】", "〕", "〛", "〗", "〙"]
        case "{": return ["{", "｛"]
        case "}": return ["}", "｝"]
        case "#": return ["#", "＃", "♯", "♭", "♮"]
        case "%": return ["%", "％", "‰", "‱"]
        case "^": return ["^", "＾", "ˇ", "ˆ", "↓", "↑"]
        case "*": return ["*", "＊", "×", "※", "✗", "✓"]
        case "+": return ["+", "＋", "∓", "±"]
        case "=": return ["=", "≠", "≡", "≈", "≒", "≅", "＝"]
        // #+= 2nd row
        case "_": return ["_", "‾‾", "＿", "￣", "ˍ", "ˉ"]
        case "\\": return ["\\", "＼", "ˋ", "ˎ"]
        case "|": return ["|", "｜", "¦"]
        case "~": return ["~", "～", "﹏", "﹋"]
        case "<": return ["←", "↔", "＜", "〈", "<", "‹", "≤", "⩽", "≦", "⫹"]
        case ">": return ["→", "↔", "＞", "〉", ">", "›", "≥", "⩾", "≧", "⫺"]
        case "«": return ["«", "《", "⇐", "⇔"]
        case "»": return ["»", "》", "⇒", "⇔"]
        case "&": return ["&", "＆", "§", "¶"]
        case "•": return ["•", "·", "‣", "◦", "°", "○"]
        // #+= 4th row
        case "…": return ["…", "⋯"]
        // 123 2nd row full width
        case "—": return ["—", "–", "-", "－", "‑", "·", "˧"]
        case "／": return ["／", "/", "✓", "√", "∕", "÷", "ˊ", "ˏ"]
        case "：": return ["：", ":", "꞉", "ː"]
        case "；": return ["；", ";"]
        case "（": return ["(", "（", "⦅", "⸨", "｟", "͡"]
        case "）": return [")", "）", "⦆", "⸩", "｠", "͡"]
        // 123 3rd row full width
        case "。": return ["。", ".", "．", "…", "⋯", "⋯⋯"]
        case "，": return ["，", ","]
        case "、": return ["､", "、"]
        case "？": return ["？", "?", "¿"]
        case "！": return ["！", "!", "¡"]
        // #+= 1st row full width
        case "［": return ["［", "[", "【", "〔", "〚", "〖", "〘"]
        case "］": return ["］", "]", "】", "〕", "〛", "〗", "〙"]
        case "｛": return ["｛", "{"]
        case "｝": return ["｝", "}"]
        // #+= 2nd row full width
        case "＼": return ["＼", "\\", "ˋ", "ˎ"]
        case "｜": return ["｜", "|", "¦"]
        case "～": return ["～", "~", "﹏", "﹋"]
        case "〈": return ["←", "↔", "＜", "<", "〈", "‹", "≤", "⩽", "≦", "⫹"]
        case "〉": return ["→", "↔", "＞", ">", "〉", "›", "≥", "⩾", "≧", "⫺"]
        case "《": return ["《", "«", "⇐", "⇔"]
        case "》": return ["》", "»", "⇒", "⇔"]
        case "·": return ["·", "•", "‣", "◦", "°", "○"]
        // #+= 4th row full width
        case "⋯": return ["⋯", "…"]
        case .currency: return ["¢", "¤", "$", "€", "£", "¥", "₩", "₽", "￠", "￡", "￦", "￥", "＄"]
        case "'": return ["'", "＇"]
        case "\"": return ["\"", "＂"]
        case "a": return [self, "à", "á", "ā", "a̖", "a̗", "a̠", "â", "ä", "ǎ", "ɐ", "æ", "ã", "å", "ă", "ȧ", "ạ", "ả", "ą"]
        case "b": return [self, "ɓ", "ƀ"]
        case "c": return [self, "ç", "ć", "č", "ċ", "ĉ"]
        case "d": return [self, "ď", "ð", "ɗ", "đ", "ḑ", "ḋ", "ḍ"]
        case "e": return [self, "è", "é", "ē", "e̖", "e̗", "e̠", "ê", "ë", "ě", "ɛ", "ə", "ẽ", "ĕ", "ė", "ẹ", "ẻ", "ę"]
        case "f": return [self, "ḟ", "ƒ"]
        case "g": return [self, "ğ", "ġ", "ĝ", "ǧ", "ģ", "ɠ", "ǥ", "ɣ"]
        case "h": return [self, "ħ", "ĥ", "ȟ", "ḩ", "ḣ", "ḥ", "ʰ"]
        case "i": return [self, "ì", "í", "ī", "i̖", "i̗", "i̠", "î", "ï", "ǐ", "ɪ", "ĩ", "ĭ", "ị", "ỉ", "į", "ɨ", "ı"]
        case "j": return [self, "ĵ", "ǰ", "ɉ", "ȷ", "ʲ"]
        case "k": return [self, "ķ", "ḳ", "k̚"]
        case "l": return [self, "ł", "ļ", "ľ", "ḷ"]
        case "m": return [self, "m̀", "ḿ", "m̄", "m̖", "m̗", "m̠", "ṁ", "ṃ", "ɯ", "ɱ"]
        case "n": return [self, "ǹ", "ń", "n̄", "n̖", "n̗", "n̠", "ñ", "ň", "ņ", "ṅ", "ṇ", "ŋ", "ɲ", "ƞ"]
        case "o": return [self, "ò", "ó", "ō", "o̖", "o̗", "o̠", "ô", "ö", "ǒ", "ɔ", "œ", "ø", "ɵ", "õ", "ŏ", "ȍ", "ő", "ȯ", "ọ", "ỏ", "ǫ", "ơ"]
        case "p": return [self, "ṕ", "ṗ", "p̚", "ƥ"]
        case "q": return [self, "q̌", "q̇", "q̃", "ɋ"]
        case "r": return [self, "ř", "ŕ", "ŗ", "ṙ", "ṛ"]
        case "s": return [self, "ß", "ş", "ș", "ś", "ŝ", "š", "ṡ", "ṣ", "ʃ"]
        case "t": return [self, "ţ", "ț", "ṫ", "ṭ", "ť", "ƭ", "ŧ", "t̚", "þ", "θ"]
        case "u": return [self, "ù", "ú", "ū", "u̖", "u̗", "u̠", "û", "ü", "ǔ", "ʊ", "ũ", "ů", "ŭ", "ȕ", "ű", "u̇", "ụ", "ủ", "ų", "ư", "ʉ"]
        case "v": return [self, "ʋ", "ʌ"]
        case "w": return [self, "ẁ", "ẃ", "ŵ", "w̌", "ẅ", "ʷ"]
        case "x": return [self, "x̧", "ẋ", "x̣", "ẍ"]
        case "y": return [self, "ỳ", "ý", "ȳ", "ŷ", "y̌", "ÿ"]
        case "z": return [self, "ź", "ẑ", "ž", "z̧", "ż", "ẓ", "ƶ", "ʒ"]
        case "A": return [self, "À", "Á", "Ā", "A̖", "A̗", "A̠", "Â", "Ä", "Ǎ", "Ɐ", "Æ", "Ã", "Å", "Ă", "Ȧ", "Ạ", "Ả", "Ą"]
        case "B": return [self, "Ɓ", "Ƀ"]
        case "C": return [self, "Ç", "Ć", "Č", "Ċ", "Ĉ"]
        case "D": return [self, "Ď", "Ð", "Ɗ", "Đ", "Ḑ", "Ḋ", "Ḍ"]
        case "E": return [self, "È", "É", "Ē", "E̖", "E̗", "E̠", "Ê", "Ë", "Ě", "Ɛ", "Ə", "Ẽ", "Ĕ", "Ė", "Ẹ", "Ẻ", "Ę"]
        case "F": return [self, "Ḟ", "Ƒ"]
        case "G": return [self, "Ğ", "Ġ", "Ĝ", "Ǧ", "Ģ", "Ɠ", "Ǥ", "Ɣ"]
        case "H": return [self, "Ħ", "Ĥ", "Ȟ", "Ḩ", "Ḣ", "Ḥ", "ᴴ"]
        case "I": return [self, "Ì", "Í", "Ī", "I̖", "I̗", "I̠", "Î", "Ï", "Ǐ", "Ɪ", "Ĩ", "Ĭ", "Ị", "Ỉ", "Į", "Ɨ", "İ"]
        case "J": return [self, "Ĵ", "J̌", "Ɉ", "J̇", "ᴶ"]
        case "K": return [self, "Ķ", "Ḳ", "K̚"]
        case "L": return [self, "Ł", "Ļ", "Ľ", "Ḷ"]
        case "M": return [self, "M̀", "Ḿ", "M̄", "M̖", "M̗", "M̠", "Ṁ", "Ṃ", "Ɯ", "Ɱ"]
        case "N": return [self, "Ǹ", "Ń", "N̄", "N̖", "N̗", "N̠", "Ñ", "Ň", "Ņ", "Ṅ", "Ṇ", "Ŋ", "Ɲ", "Ƞ"]
        case "O": return [self, "Ò", "Ó", "Ō", "O̖", "O̗", "O̠", "Ô", "Ö", "Ǒ", "Ɔ", "Œ", "Ø", "Ɵ", "Õ", "Ŏ", "Ȍ", "Ő", "Ȯ", "Ọ", "Ỏ", "Ǫ", "Ơ"]
        case "P": return [self, "Ṕ", "Ṗ", "P̚", "Ƥ"]
        case "Q": return [self, "Q̌", "Q̇", "Q̃", "Ɋ"]
        case "R": return [self, "Ř", "Ŕ", "Ŗ", "Ṙ", "Ṛ"]
        case "S": return [self, "ẞ", "Ş", "Ș", "Ś", "Ŝ", "Š", "Ṡ", "Ṣ", "Ʃ"]
        case "T": return [self, "Ţ", "Ț", "Ṫ", "Ṭ", "Ť", "Ƭ", "Ŧ", "T̚", "Þ", "ϴ"]
        case "U": return [self, "Ù", "Ú", "Ū", "U̖", "U̗", "U̠", "Û", "Ü", "Ǔ", "Ʊ", "Ũ", "Ů", "Ŭ", "Ȕ", "Ű", "U̇", "Ụ", "Ủ", "Ų", "Ư", "Ʉ"]
        case "V": return [self, "Ʋ", "Ʌ"]
        case "W": return [self, "Ẁ", "Ẃ", "Ŵ", "W̌", "Ẅ", "ᵂ"]
        case "X": return [self, "X̧", "Ẋ", "X̣", "Ẍ"]
        case "Y": return [self, "Ỳ", "Ý", "Ȳ", "Ŷ", "Y̌", "Ÿ"]
        case "Z": return [self, "Ź", "Ẑ", "Ž", "Z̧", "Ż", "Ẓ", "Ƶ", "Ʒ"]
        case .jyutPingInitialFinal(.punctuation, "。"): return ["。", "."]
        case .jyutPingInitialFinal(.punctuation, "，"): return ["，", ","]
        case .jyutPingInitialFinal(.punctuation, "？"): return ["？", "?"]
        case .jyutPingInitialFinal(.punctuation, "！"): return ["！", "!"]
        default: return [self]
        }
    }
    
    var defaultChildKeyCapTitle: String? {
        switch self {
        case .character(",", KeyCapHints(rightHint: "符"), _): return "." // Contextual sym key in English mode
        case .character("，", KeyCapHints(rightHint: "符"), _): return "。" // Contextual sym key in Chinese mode
        case .character(".", KeyCapHints(rightHint: "/"), _): return nil // Contextual sym key in url mode
        default: return self.buttonText
        }
    }
    
    var isCombo: Bool {
        switch self {
        case .combo: return true
        default: return false
        }
    }
    
    var isContextual: Bool {
        switch self {
        case .contextual: return true
        default: return false
        }
    }
    
    var isKeyboardType: Bool {
        switch self {
        case .keyboardType: return true
        default: return false
        }
    }
    
    var isPlaceholder: Bool {
        switch self {
        case .placeholder: return true
        default: return false
        }
    }
    
    var isReverseLookup: Bool {
        switch self {
        case .reverseLookup: return true
        default: return false
        }
    }
    
    var isRimeTone: Bool {
        switch self {
        case .rime(let rc, _, _):
            return rc == .tone1 || rc == .tone2 || rc == .tone3 ||
                   rc == .tone4 || rc == .tone5 || rc == .tone6
        default: ()
        }
        return false
    }
    
    var isJyutpingInitialOrFinalOrTone: Bool {
        switch self {
        case .jyutPingInitialFinal(let keyCapType, _): return keyCapType != .punctuation
        default: return false
        }
    }
    
    var toJyutpingInitialFinalKeyCapType: InitialFinalKeyboardView.KeyCapType? {
        switch self {
        case .jyutPingInitialFinal(let keyCapType, _): return keyCapType
        default: return nil
        }
    }
    
    var unescaped: KeyCap {
        switch self {
        case .placeholder(let keyCap): return keyCap.unescaped
        default: return self
        }
    }
    
    private var toSpecialSymbol: SpecialSymbol? {
        for specialSymbol in SpecialSymbol.allCases {
            if specialSymbol.keyCaps.contains(self) {
                return specialSymbol
            }
        }
        return nil
    }
    
    func symbolTransform(state: KeyboardState) -> KeyCap {
        guard state.symbolShapeOverride == nil else { return self }
        if let specialSymbol = self.toSpecialSymbol {
            return specialSymbol.transform(keyCap: self, state: state)
        }
        return self
    }
}

enum SpecialSymbol: CaseIterable {
    case colon, dot, minus, slash,
         parenthesis, curlyBracket, squareBracket, angleBracket, doubleAngleBracket
    
    var keyCapPairs: [(half: KeyCap, full: KeyCap)] {
        switch self {
        case .colon: return [(half: ":", full: "：")]
        case .dot: return [(half: ".", full: "。")]
        case .minus: return [(half: "-", full: "—")]
        case .slash: return [(half: "/", full: "／")]
        case .parenthesis: return [(half: "(", full: "（"), (half: ")", full: "）")]
        case .curlyBracket: return [(half: "{", full: "｛"), (half: "}", full: "｝")]
        case .squareBracket: return [(half: "[", full: "［"), (half: "]", full: "］")]
        case .angleBracket: return [(half: "<", full: "〈"), (half: ">", full: "〉")]
        case .doubleAngleBracket: return [(half: "«", full: "《"), (half: "»", full: "》")]
        }
    }
    
    var keyCaps: [KeyCap] {
        return keyCapPairs.flatMap { return [$0.half, $0.full] }
    }
    
    func transform(keyCap: KeyCap, state: KeyboardState) -> KeyCap {
        let matchingKeyCap = keyCapPairs.first(where: { $0.half == keyCap || $0.full == keyCap })
        guard let matchingKeyCap = matchingKeyCap else { return keyCap }
        
        let shapeOverride = state.specialSymbolShapeOverride[self]
        
        switch shapeOverride {
        case .half: return matchingKeyCap.half
        case .full: return matchingKeyCap.full
        default: return keyCap
        }
    }
    
    func determineSymbolShape(textBefore: String) -> SymbolShape? {
        let symbolShape = Settings.cached.symbolShape
        switch symbolShape {
        case .smart:
            switch self {
            case .colon, .dot, .minus, .slash: return Self.determineSymbolShapeFromLastChar(textBefore: textBefore)
            case .parenthesis, .curlyBracket, .squareBracket, .angleBracket, .doubleAngleBracket:
                return determineSymbolShapeFromLastMatchingChar(textBefore: textBefore)
            }
        case .half: return .half
        case .full: return .full
        }
    }
    
    private static func determineSymbolShapeFromLastChar(textBefore: String) -> SymbolShape? {
        for c in textBefore.reversed() {
            if c.isEnglishLetterOrDigit {
                return .half
            } else if c.isChineseChar {
                return .full
            }
        }
        
        return nil
    }
    
    private func determineSymbolShapeFromLastMatchingChar(textBefore: String) -> SymbolShape? {
        let halfChars = keyCapPairs.compactMap { $0.half.character }
        let fullChars = keyCapPairs.compactMap { $0.full.character }
        
        for c in textBefore.reversed() {
            if halfChars.contains(c) {
                return .half
            } else if fullChars.contains(c) {
                return .full
            }
        }
        
        return nil
    }
}

let FrameworkBundle = Bundle(for: KeyView.self)

class ButtonImage {
    private static func imageAssets(_ key: String) -> UIImage {
        let config = UIImage.SymbolConfiguration(weight: .light)
        let image = UIImage(systemName: key) ?? UIImage(named: key, in: Bundle(for: ButtonImage.self), with: nil)!
        return image.applyingSymbolConfiguration(config)!
    }
    
    static let globe = imageAssets("globe")
    static let backspace = imageAssets("delete.left")
    static let backspaceFilled = imageAssets("delete.left.fill")
    static let shift = imageAssets("shift")
    static let shiftFilled = imageAssets("shift.fill")
    static let capLockFilled = imageAssets("capslock.fill")
    static let emojiKeyboardLight = imageAssets("face.smiling")
    static let emojiKeyboardDark = imageAssets("face.smiling.fill")
    static let moveCursorBackward = imageAssets("arrowtriangle.backward.fill")
    static let moveCursorForward = imageAssets("arrowtriangle.forward.fill")
    static let paneCollapseButtonImage = imageAssets("chevron.up")
    static let paneExpandButtonImage = imageAssets("chevron.down")
    static let paneScrollRightButtonImage = imageAssets("arrow.right")
    static let paneScrollToBeginningButtonImage = imageAssets("return.left")
    static let paneScrollUpButtonImage = imageAssets("triangle.up")
    static let paneScrollDownButtonImage = imageAssets("triangle.down")
    
    static let dismissKeyboard = imageAssets("keyboard.chevron.compact.down")
    static let clear = imageAssets("clear")
    static let clearFilled = imageAssets("clear.fill")
    static let tab = imageAssets("arrow.right.to.line")
    static let returnKey = imageAssets("return.left")
    static let info = imageAssets("info.circle")
    static let infoFilled = imageAssets("info.circle.fill")
    static let close = imageAssets("xmark")
    static let swipeDown = imageAssets("chevron.compact.down")
    static let pronounce = imageAssets("speaker.wave.2.circle.fill")
}

class ButtonColor {
    private static func colorAssets(_ key: String) -> UIColor {
        UIColor(named: key, in: FrameworkBundle, compatibleWith: nil)!
    }
    
    // Legacy theme (below iOS 26) background colors
    private static let legacyInputKeyBackgroundColor = colorAssets("inputKeyBackgroundColor")
    private static let legacySystemKeyBackgroundColor = colorAssets("systemKeyBackgroundColor")
    private static let legacyPopupBackgroundColor = colorAssets("popupBackgroundColor")
    
    // Legacy key colours during key press / for enabled state
    private static let legacyInputKeyHighlightedBackgroundColor = colorAssets("inputKeyHighlightedBackgroundColor")
    /// The temporary key color after swiping down a key on iPad
    private static let legacyKeyGrayedColor = colorAssets("keyGrayedColor")
    private static let legacySystemKeyHighlightedBackgroundColor = colorAssets("systemKeyHighlightedBackgroundColor")
    private static let legacyShiftKeyHighlightedBackgroundColor = colorAssets("shiftKeyHighlightedBackgroundColor")
    
    // Legacy key shadows. There are no key shadows in Liquid Glass theme, and the shadow height is set to 0,
    // meaning that setting the shadow color will not produce any visual effect, so they are left untouched
    // and there is no need for value redirections.
    static let keyShadowColor = colorAssets("keyShadowColor")
    static let keyHighlightedShadowColor = colorAssets("keyHighlightedShadowColor")
    
    // Legacy key text/image colors
    private static let legacyShiftKeyHighlightedForegroundColor = colorAssets("shiftKeyHighlightedForegroundColor")
    
    // Liquid Glass theme (iOS 26 or above) background colors
    private static let liquidGlassKeyBackgroundColor = colorAssets("liquidGlassKeyBackgroundColor")
    private static let liquidGlassKeyHighlightedBackgroundColor = colorAssets("liquidGlassKeyHighlightedBackgroundColor")
    
    // Key text colors applicable for both theme
    static let keyForegroundColor = colorAssets("keyForegroundColor")
    static let keyHintColor = colorAssets("keyHintColor")
    static let placeholderKeyForegroundColor = colorAssets("placeholderKeyForegroundColor")
    static let dictionaryViewBackgroundColor = colorAssets("dictionaryViewBackgroundColor")
    static let dictionaryViewForegroundColor = colorAssets("dictionaryViewForegroundColor")
    static let dictionaryViewGrayedColor = colorAssets("dictionaryViewGrayedColor")
    static let jyutpingInitialFinalDefaultInitialKeyColor = colorAssets("jyutpingInitialFinalDefaultInitialKeyColor")
    static let jyutpingInitialFinalDefaultFinalKeyColor = colorAssets("jyutpingInitialFinalDefaultFinalKeyColor")
    static let jyutpingInitialFinalDefaultToneKeyColor = colorAssets("jyutpingInitialFinalDefaultToneKeyColor")
    static let jyutpingInitialFinalDefaultPunctuationKeyColor = colorAssets("jyutpingInitialFinalDefaultPunctuationKeyColor")
    static let jyutpingInitialFinalDefaultSpaceKeyColor = colorAssets("jyutpingInitialFinalDefaultSpaceKeyColor")
    static let jyutpingInitialFinalDefaultSystemKeyColor = colorAssets("jyutpingInitialFinalDefaultSystemKeyColor")
    
    // Background colors redirection
    static var inputKeyBackgroundColor: UIColor {
        Settings.cached.shouldUseLiquidGlassTheme ? liquidGlassKeyBackgroundColor : legacyInputKeyBackgroundColor
    }
    static var systemKeyBackgroundColor: UIColor {
        Settings.cached.shouldUseLiquidGlassTheme ? liquidGlassKeyBackgroundColor : legacySystemKeyBackgroundColor
    }
    static var popupBackgroundColor: UIColor {
        Settings.cached.shouldUseLiquidGlassTheme ? liquidGlassKeyBackgroundColor : legacyPopupBackgroundColor
    }
    
    // Highlighted background colors redirection
    static var inputKeyHighlightedBackgroundColor: UIColor {
        Settings.cached.shouldUseLiquidGlassTheme ? liquidGlassKeyHighlightedBackgroundColor : legacyInputKeyHighlightedBackgroundColor
    }
    static var keyGrayedColor: UIColor {
        Settings.cached.shouldUseLiquidGlassTheme ? liquidGlassKeyHighlightedBackgroundColor : legacyKeyGrayedColor
    }
    static var systemKeyHighlightedBackgroundColor: UIColor {
        Settings.cached.shouldUseLiquidGlassTheme ? liquidGlassKeyHighlightedBackgroundColor : legacySystemKeyHighlightedBackgroundColor
    }
    static var shiftKeyHighlightedBackgroundColor: UIColor {
        // Liquid Glass theme doesn't use background color to indicate enabled state. Keep the original color.
        Settings.cached.shouldUseLiquidGlassTheme ? liquidGlassKeyBackgroundColor : legacyShiftKeyHighlightedBackgroundColor
    }
    
    // Text/image colors redirection
    static var shiftKeyHighlightedForegroundColor: UIColor {
        // Same text/image color as ordinary keys in Liquid Glass theme
        Settings.cached.shouldUseLiquidGlassTheme ? keyForegroundColor : legacyShiftKeyHighlightedForegroundColor
    }
}
