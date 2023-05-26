//
//  CandidateCellInfo.swift
//  CantoboardFramework
//
//  Created by Alex Man on 12/4/23.
//

import Foundation

struct CandidateCellInfo {
    let honzi: String
    var jyutping: String?
    var pronOrder: String?
    var sandhi: String?
    var litColReading: String?
    var freq: String?
    var freq2: String?
    var definition = Definition()

    struct Definition {
        var eng: String?
        var disambiguation: String?
        var pos: String?
        var register: String?
        var label: String?
        var written: String?
        var colloquial: String?
        var languages = Languages()
    }
    
    struct Languages {
        var urd: String?
        var nep: String?
        var hin: String?
        var ind: String?
    }
    
    static let columns: [WritableKeyPath<Self, String?>] = [
        \.jyutping, \.pronOrder, \.sandhi, \.litColReading, \.freq, \.freq2,
        \.definition.eng, \.definition.disambiguation, \.definition.pos, \.definition.register, \.definition.label, \.definition.written, \.definition.colloquial,
        \.definition.languages.urd, \.definition.languages.nep, \.definition.languages.hin, \.definition.languages.ind,
    ]
    
    private let isJyutpingOnly: Bool
    
    static let checkColumns: [WritableKeyPath<Self, String?>] = [
        \.sandhi, \.litColReading, \.definition.pos, \.definition.register, \.definition.label, \.definition.written, \.definition.colloquial,
    ]
    
    init(honzi: String, fromCSV csv: String? = nil) {
        self.honzi = honzi
        guard let csv = csv, csv.contains(",") else {
            if csv != "" {
                jyutping = csv
            }
            isJyutpingOnly = true
            return
        }
        isJyutpingOnly = false
        var charIterator = PeekableIterator(csv.makeIterator())
        var columnIterator = Self.columns.makeIterator()
        var isQuoted = false
        var column = columnIterator.next()!
        var value = ""
        while let char = charIterator.next(), char != "," {
            value += String(char)
            if char.isDigit && charIterator.peek() != "," {
                value += " "
            }
        }
        if value != "" {
            self[keyPath: column] = value
        }
        column = columnIterator.next()!
        value = ""
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
                if value != "" {
                    self[keyPath: column] = value
                }
                guard let newColumn = columnIterator.next() else {
                    break
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
    }
    
    private func getDefinition(of language: Language) -> String? {
        switch language {
        case .eng: return self.definition.eng
        case .hin: return self.definition.languages.hin
        case .ind: return self.definition.languages.ind
        case .nep: return self.definition.languages.nep
        case .urd: return self.definition.languages.urd
        }
    }
    
    var mainLanguage: String? {
        getDefinition(of: Settings.cached.languageState.main)
    }
    
    var otherLanguages: [String] {
        let main = Settings.cached.languageState.main
        return Settings.cached.languageState.selected.compactMap { $0 == main ? nil : getDefinition(of: $0) }
    }
    
    var otherLanguagesWithNames: [(name: String, value: String)] {
        let main = Settings.cached.languageState.main
        return Settings.cached.languageState.selected.compactMap {
            guard $0 != main, let definition = getDefinition(of: $0) else { return nil }
            return ($0.name, definition)
        }
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
        return mainLanguage != nil || !otherLanguages.isEmpty
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