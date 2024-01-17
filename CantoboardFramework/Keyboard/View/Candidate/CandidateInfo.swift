//
//  CandidateInfo.swift
//  CantoboardFramework
//
//  Created by Alex Man on 6/11/23.
//

import Foundation

struct CandidateInfo {
    let text: String
    let isReverseLookup: Bool
    let note: String
    let entries: [CandidateEntry]
    
    let entry: CandidateEntry?
    let hasDictionaryEntry: Bool
    let romanization: String
    let allEngTranslations: String?
    
    init(_ text: String, _ comment: String?) {
        self.text = text
        let comment = Comment(comment ?? "")
        isReverseLookup = comment.consume(0x0b /* \v */)
        note = comment.consumeUntil(0x0c /* \f */)
        entries = comment.isNotEmpty
            ? comment.consume(0x0d /* \r */)
                ? comment.string.split(separator: "\r").map { CandidateEntry(csv: String($0)) }
                : comment.string.split(separator: "\u{000c}" /* \f */).map {
                    CandidateEntry(honzi: text, jyutping: String($0.hasSuffix("; ") ? $0.prefix($0.count - 2) : $0))
                }
            : []
        
        entry = entries.first { $0.matchInputBuffer == "1" }
        hasDictionaryEntry = entries.contains { $0.isDictionaryEntry }
        romanization = entry?.jyutping ?? (isReverseLookup ? "" : note)
        if Settings.cached.languageState.has(.eng),
           entries.contains(where: { $0.properties.label?.split(separator: " ").contains("composition") ?? false }) {
            var translations: [(honzi: String, eng: String)] = []
            for entry in entries {
                if entry.matchInputBuffer == "1", let honzi = entry.honzi, let eng = entry.properties.definition.eng, !translations.contains(where: { $0.honzi == honzi }) {
                    translations.append((honzi, eng))
                }
            }
            if !translations.isEmpty {
                allEngTranslations = translations.map({ "\($0.honzi): \($0.eng)" }).joined(separator: " | ")
                return
            }
        }
        allEngTranslations = nil
    }
    
    static func getJyutping(_ comment: String?) -> String? {
        let comment = Comment(comment ?? "")
        _ = comment.consume(0x0b /* \v */)
        _ = comment.consumeUntil(0x0c /* \f */)
        return comment.isNotEmpty
            ? comment.consume(0x0d /* \r */)
                ? comment.string.lazy
                    .split(separator: "\r")
                    .compactMap({ CandidateEntry(csv: String($0), earlyExit: true).jyutping })
                    .first
                : comment.string.lazy
                    .split(separator: "\u{000c}" /* \f */)
                    .map({ String(String($0).hasSuffix("; ") ? $0.prefix($0.count - 2) : $0) })
                    .compactMap({ $0.isEmpty ? nil : $0 })
                    .first
            : nil
    }
}

private class Comment {
    private let comment: ContiguousArray<CChar>
    private let length: Int
    private var i = 0
    
    init(_ input: String) {
        comment = input.utf8CString
        length = comment.count - 1 // ignore null terminator
    }
    
    var isNotEmpty: Bool { i < length }
    
    func consume(_ char: CChar) -> Bool {
        if isNotEmpty && comment[i] == char {
            i += 1
            return true
        }
        return false
    }
    
    func consumeUntil(_ char: CChar) -> String {
        let start = i
        while isNotEmpty {
            if comment[i] == char {
                let result = comment[start..<i] + [0]
                i += 1
                return String(cString: Array(result))
            } else {
                i += 1
            }
        }
        return String(cString: Array(comment[start..<i] + [0]))
    }
    
    var string: String { String(cString: Array(comment[i...])) }
}
