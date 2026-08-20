//
//  CandidateEntry.swift
//  CantoboardFramework
//
//  Created by Alex Man on 12/4/23.
//

import Foundation

struct CandidateEntry {
    var matchInputBuffer: String?
    var honzi: String?
    var jyutping: String?
    fileprivate var canonicalHonzi: String?
    fileprivate var canonicalJyutping: String?
    fileprivate var componentsHonzi: String? // unused in UI
    fileprivate var componentsJyutping: String? // unused in UI
    var pronLabel: String?
    var litColReading: String?
    var properties = Properties()

    struct Properties {
        fileprivate var partOfSpeech: String?
        fileprivate var register: String?
        fileprivate var label: String?
        var written: String?
        var vernacular: String?
        var collocation: String?
        fileprivate var definition = Definition()
    }
    
    struct Definition {
        fileprivate var eng: String?
        fileprivate var urd: String?
        fileprivate var nep: String?
        fileprivate var hin: String?
        fileprivate var ind: String?
    }
    
    private static let columns: [WritableKeyPath<Self, String?>] = [
        \.matchInputBuffer, \.honzi, \.jyutping, \.canonicalHonzi, \.canonicalJyutping,
        \.componentsHonzi, \.componentsJyutping, \.pronLabel, \.litColReading,
        \.properties.partOfSpeech, \.properties.register, \.properties.label, \.properties.written, \.properties.vernacular, \.properties.collocation,
        \.properties.definition.eng, \.properties.definition.hin, \.properties.definition.urd, \.properties.definition.nep, \.properties.definition.ind,
    ]
    
    private static let earlyExitColumns: [WritableKeyPath<Self, String?>] = [\.matchInputBuffer, \.honzi, \.jyutping]
    
    private let isJyutpingOnly: Bool
    
    private static let checkColumns: [WritableKeyPath<Self, String?>] = [
        \.properties.partOfSpeech, \.properties.register, \.properties.written, \.properties.vernacular, \.properties.collocation,
    ]
    
    init(honzi: String? = nil, jyutping: String? = nil) {
        isJyutpingOnly = true
        self.matchInputBuffer = "1"
        self.honzi = honzi
        self.jyutping = jyutping
    }
    
    init(csv: String, earlyExit: Bool = false) {
        isJyutpingOnly = false
        var charIterator = PeekableIterator(csv.makeIterator())
        var columnIterator = (earlyExit ? Self.earlyExitColumns : Self.columns).makeIterator()
        var isQuoted = false
        guard var column = columnIterator.next() else { return }
        var value = ""
        while let char = charIterator.next() {
            if isQuoted {
                if char == "\"" {
                    if charIterator.peek() == "\"" {
                        _ = charIterator.next()
                        value.append("\"")
                    } else {
                        isQuoted = false
                    }
                } else {
                    value.append(char)
                }
            } else if value == "" && char == "\"" {
                isQuoted = true
            } else if char == "," {
                guard let newColumn = columnIterator.next() else {
                    break
                }
                if value != "" {
                    self[keyPath: column] = value
                }
                column = newColumn
                value.removeAll()
            } else {
                value.append(char)
            }
        }
        if value != "" {
            self[keyPath: column] = value
        }
        
        // Transformations
        jyutping = jyutping.map(Self.formatJyutping)
        canonicalJyutping = canonicalJyutping.map(Self.formatJyutping)
    }
    
    private func getDefinition(of language: Language) -> String? {
        switch language {
        case .eng: return self.properties.definition.eng
        case .hin: return self.properties.definition.hin
        case .ind: return self.properties.definition.ind
        case .nep: return self.properties.definition.nep
        case .urd: return self.properties.definition.urd
        }
    }
    
    var pronunciationType: String? {
        var types = pronLabel?
            .split(separator: "|")
            .map({ Constants.pronunciationLabels[String($0)] ?? String($0) })
            .unique()
            ?? []
        if let litColReading = litColReading,
           let dirRange = litColReading.rangeOfCharacter(from: CharacterSet(charactersIn: "<>")),
           let litOrCol = Constants.litColReadings[String(litColReading[..<dirRange.lowerBound])] {
            let dir = litColReading[dirRange]
            let relatedReadings = litColReading[dirRange.upperBound...]
            types.append("""
            \(litOrCol) \(dir) \(
                relatedReadings
                    .split(separator: "|")
                    .map({ String($0) })
                    .map(Self.formatGlyphonString)
                    .joined(separator: "/")
            )
            """)
        }
        return types.isEmpty ? nil : "(\(types.joined(separator: ", ")))"
    }
    
    var canonicalReference: String? {
        canonicalHonzi
            .flatMap({ canonicalHonzi in
                canonicalJyutping.flatMap({ canonicalJyutping in "→\(canonicalHonzi)(\(canonicalJyutping))" })
                    ?? "→\(canonicalHonzi)"
            })
            ?? canonicalJyutping.flatMap({ canonicalJyutping in "→\(canonicalJyutping)" })
    }
    
    var formattedPartsOfSpeech: [String]? {
        properties.partOfSpeech?
            .split(separator: "|")
            .map({ Constants.partsOfSpeech[String($0)] ?? String($0) })
            .unique()
            .nonEmptyOrNil
    }
    
    var formattedRegisters: [String]? {
        properties.register?
            .split(separator: "|")
            .map({ Constants.registers[String($0)] ?? String($0) })
            .unique()
            .nonEmptyOrNil
    }
    
    var formattedLabels: [String]? {
        properties.label?
            .split(separator: "|")
            .compactMap({
                $0.lazy
                    .split(separator: "_")
                    .compactMap({ Constants.labels[String($0)] })
                    .first
            })
            .map({ "(\($0))" })
            .unique()
            .nonEmptyOrNil
    }
    
    var mainLanguage: String? {
        getDefinition(of: Settings.cached.languageState.main)
    }
    
    var fallbackLanguage: String? {
        getDefinition(of: .eng)
    }
    
    var mainOrFallbackLanguage: String? {
        mainLanguage ?? (Settings.cached.languageState.has(.eng) ? fallbackLanguage : nil)
    }
    
    var otherData: [(name: String, value: String)]? {
        Constants.otherData
            .compactMap({ data in
                guard let value = self[keyPath: data.value] else { return nil }
                return (data.key, value.replacingOccurrences(of: "|", with: "\n"))
            })
            .nonEmptyOrNil
    }
    
    var otherLanguages: [String]? {
        if canonicalReference != nil { return nil }
        let main = Settings.cached.languageState.main
        let shouldExcludeEnglish = mainLanguage == nil
        return Settings.cached.languageState.selected
            .compactMap({
                $0 == main || shouldExcludeEnglish && $0 == .eng ? nil : getDefinition(of: $0)
            })
            .nonEmptyOrNil
    }
    
    var otherLanguagesWithNames: [(name: String, value: String)]? {
        let main = Settings.cached.languageState.main
        return Settings.cached.languageState.selected
            .compactMap({
                guard $0 != main, let definition = getDefinition(of: $0) else { return nil }
                return ($0.name, definition)
            })
            .nonEmptyOrNil
    }
    
    var joinedLabels: String? {
        formattedLabels?.joined(separator: " ")
    }
    
    var otherLanguagesOrLabels: [String]? {
        isDictionaryEntry ? otherLanguages : formattedLabels
    }
    
    var isDictionaryEntry: Bool {
        if isJyutpingOnly {
            return false
        }
        for column in Self.checkColumns {
            if self[keyPath: column] != nil {
                return true
            }
        }
        if canonicalReference != nil {
            return true
        }
        for language in Settings.cached.languageState.selected {
            if getDefinition(of: language) != nil {
                return true
            }
        }
        return false
    }
}

extension CandidateEntry {
    private struct Constants {
        static let otherData: KeyValuePairs<String, WritableKeyPath<CandidateEntry, String?>> = [
            "Written Form 書面語": \.properties.written,
            "Vernacular Form 口語": \.properties.vernacular,
            "Collocation 配搭": \.properties.collocation,
        ]
        
        static let pronunciationLabels: [String: String] = [
            "sandhi": "changed tone 變音",
            "semantic_reading": "semantic reading 訓讀",
            "creative_reading": "creative reading 生造音",
        ]
        
        static let litColReadings: [String: String] = [
            "lit": "literary reading 文讀",
            "col": "colloquial reading 白讀",
        ]
        
        static let registers: [String: String] = [
            "cmn": "written 書面語",
            "yue": "vernacular 口語",
            "lzh": "formal 公文體",
            "och": "classical Chinese 文言",
            "sit": "chars. for proper noun 專有名詞用字",
        ]
        
        static let partsOfSpeech: [String: String] = [
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
        
        static let labels: [String: String] = [
            "abbrev": "abbreviation 簡稱",
            "astro": "astronomy 天文",
            "ChinMeta": "sexagenary cycle 干支",
            "horo": "horoscope 星座",
            "org": "organisation 機構",
            "person": "person 人名",
            "place": "place 地名",
            "pop": "popular culture 流行文化",
            "reli": "religion 宗教",
            "rare": "rare 罕見",
            "composition": "compound 詞組",
        ]
    }
}

extension CandidateEntry {
    private static func formatJyutping(_ jyutpingWithoutSpace: String) -> String {
        var prevChar: Character?
        var value = ""
        for char in jyutpingWithoutSpace {
            if let prevChar = prevChar, prevChar.isDigit {
                value.append(" ")
            }
            value.append(char)
            prevChar = char
        }
        return value
    }
    
    private static func formatGlyphonString(_ string: String) -> String {
        if string.first?.isASCII ?? true { return formatJyutping(string) }
        var honzi = ""
        var jyutping = ""
        var isParsingJyutping = false
        for char in string {
            if char.asciiValue == nil {
                if jyutping != "" { jyutping.append(" ") }
                isParsingJyutping = false
            }
            if char == "." {
                isParsingJyutping = true
                continue
            }
            if isParsingJyutping {
                jyutping.append(char)
            } else {
                honzi.append(char)
            }
        }
        return "\(honzi)(\(jyutping))"
    }
}

struct PeekableIterator<Iterator: IteratorProtocol>: IteratorProtocol {
    typealias Element = Iterator.Element
    
    private var iterator: Iterator
    private var nextElement: Element?
    
    init(_ iterator: Iterator) {
        self.iterator = iterator
    }
    
    mutating func peek() -> Element? {
        if nextElement == nil {
            nextElement = iterator.next()
        }
        return nextElement
    }
    
    mutating func next() -> Element? {
        guard let result = nextElement else {
            return iterator.next()
        }
        nextElement = nil
        return result
    }
}
