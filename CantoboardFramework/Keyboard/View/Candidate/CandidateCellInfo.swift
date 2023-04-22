//
//  CandidateCellInfo.swift
//  CantoboardFramework
//
//  Created by Alex Man on 12/4/23.
//

import Foundation

struct CandidateCellInfo {
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
    
    init(fromCSV csv: String) {
        guard csv.contains(",") else {
            jyutping = csv
            return
        }
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
    
    var mainLanguage: String? {
        switch Settings.cached.languageState.main {
        case .eng: return self.definition.eng
        case .hin: return self.definition.languages.hin
        case .ind: return self.definition.languages.ind
        case .nep: return self.definition.languages.nep
        case .urd: return self.definition.languages.urd
        }
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
