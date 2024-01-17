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
    var pronOrder: String?
    var sandhi: String?
    var litColReading: String?
    var properties = Properties()

    struct Properties {
        var partOfSpeech: String?
        var register: String?
        var label: String?
        var normalized: String?
        var written: String?
        var vernacular: String?
        var collocation: String?
        var definition = Definition()
    }
    
    struct Definition {
        var eng: String?
        var urd: String?
        var nep: String?
        var hin: String?
        var ind: String?
    }
    
    static let columns: [WritableKeyPath<Self, String?>] = [
        \.matchInputBuffer, \.honzi, \.jyutping, \.pronOrder, \.sandhi, \.litColReading,
        \.properties.partOfSpeech, \.properties.register, \.properties.label, \.properties.normalized, \.properties.written, \.properties.vernacular, \.properties.collocation,
        \.properties.definition.eng, \.properties.definition.urd, \.properties.definition.nep, \.properties.definition.hin, \.properties.definition.ind,
    ]
    
    static let earlyExitColumns: [WritableKeyPath<Self, String?>] = [\.matchInputBuffer, \.honzi, \.jyutping]
    
    private let isJyutpingOnly: Bool
    
    static let checkColumns: [WritableKeyPath<Self, String?>] = [
        \.properties.partOfSpeech, \.properties.register, \.properties.normalized, \.properties.written, \.properties.vernacular, \.properties.collocation,
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
        var column = columnIterator.next()!
        var value = ""
        while let char = charIterator.next() {
            if isQuoted {
                if char == "\"" {
                    if charIterator.peek() == "\"" {
                        _ = charIterator.next()
                        value += "\""
                    } else {
                        isQuoted = false
                    }
                } else {
                    value += String(char)
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
                value = ""
            } else {
                value += String(char)
            }
        }
        if value != "" {
            self[keyPath: column] = value
        }
        if let jyutpingWithoutSpace = jyutping {
            var prevChar: Character?
            value = ""
            for char in jyutpingWithoutSpace {
                if let prevChar = prevChar, prevChar.isDigit {
                    value += " "
                }
                value += String(char)
                prevChar = char
            }
            jyutping = value
        }
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
    
    var mainLanguage: String? {
        getDefinition(of: Settings.cached.languageState.main)
    }
    
    var mainLanguageOrEng: String? {
        mainLanguage ?? (Settings.cached.languageState.has(.eng) ? getDefinition(of: .eng) : nil)
    }
    
    var otherLanguages: [String] {
        let main = Settings.cached.languageState.main
        return Settings.cached.languageState.selected.compactMap { $0 == main || $0 == .eng ? nil : getDefinition(of: $0) }
    }
    
    var otherLanguagesWithNames: [(name: String, value: String)] {
        let main = Settings.cached.languageState.main
        return Settings.cached.languageState.selected.compactMap {
            guard $0 != main, let definition = getDefinition(of: $0) else { return nil }
            return ($0.name, definition)
        }
    }
    
    var formattedLabels: [String]? {
        properties.label?.split(separator: " ").map { "(\($0))" }
    }
    
    var joinedLabels: String? {
        formattedLabels?.joined(separator: " ")
    }
    
    var otherLanguagesOrLabels: [String] {
        isDictionaryEntry ? otherLanguages : formattedLabels ?? []
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
        for language in Settings.cached.languageState.selected {
            if getDefinition(of: language) != nil {
                return true
            }
        }
        return false
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
