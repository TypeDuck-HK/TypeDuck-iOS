//
//  CandidateOrganizer.swift
//  CantoboardFramework
//
//  Created by Alex Man on 3/19/21.
//

import Foundation
import CocoaLumberjackSwift

enum GroupByMode {
    case byFrequency, byRomanization, byRadical, byTotalStroke
    
    var title: String {
        switch self {
        case .byFrequency: return "詞頻"
        case .byRomanization: return "粵拼"
        case .byRadical: return "部首"
        case .byTotalStroke: return "筆畫"
        }
    }
}

protocol CandidateSource: AnyObject {
    func updateCandidates(reload: Bool, targetCandidatesCount: Int)
    func getNumberOfSections() -> Int
    func getCandidate(indexPath: IndexPath) -> String?
    func selectCandidate(indexPath: IndexPath) -> String?
    func unlearnCandidate(indexPath: IndexPath)
    func getCandidateComment(indexPath: IndexPath) -> String?
    func getCandidateCount(section: Int) -> Int
    func getSectionHeader(section: Int) -> String?
    var supportedGroupByModes: [GroupByMode] { get }
    var groupByMode: GroupByMode { get set }
    var isStatic: Bool { get }
}

extension CandidateSource {
    func updateCandidates(reload: Bool) {
        updateCandidates(reload: reload, targetCandidatesCount: 0)
    }
}

class InputEngineCandidateSource: CandidateSource {
    private static let unihanDict: LevelDbTable = LevelDbTable(DataFileManager.builtInUnihanDictDirectory, createDbIfMissing: false)
    private static let radicalChars = [Int](0..<214).map({ String(Character(Unicode.Scalar(0x2F00 + $0)!)) })
    
    private var candidatePaths: [[CandidatePath]] = []
    private var sectionHeaders: [String] = []
    private var curRimeCandidateIndex = 0, curEnglishCandidateIndex = 0
    private var hasLoadedAllBestRimeCandidates = false
    private var hasPopulatedBestEnglishCandidates = false, hasPopulatedWorstEnglishCandidates = false
    private weak var inputController: InputController?
    
    var isStatic: Bool { false }
    
    init(inputController: InputController) {
        self.inputController = inputController
    }
    
    private func resetCandidates() {
        curRimeCandidateIndex = 0
        curEnglishCandidateIndex = 0
        
        candidatePaths = []
        sectionHeaders = []
        
        hasLoadedAllBestRimeCandidates = false
        hasPopulatedBestEnglishCandidates = false
        hasPopulatedWorstEnglishCandidates = false
    }
    
    private func populateCandidates() {
        switch groupByMode {
        case .byFrequency: populateCandidatesByFreq()
        case .byRomanization: populateCandidatesByRomanization()
        case .byRadical: populateCandidatesByRadical()
        case .byTotalStroke: populateCandidatesByTotalStroke()
        }
    }
    
    private func populateCandidatesByFreq() {
        guard let inputController = inputController,
              let inputEngine = inputController.inputEngine else { return }
        let inputMode = inputController.state.inputMode
        let doesSchemaSupportMixedMode = inputEngine.rimeSchema.supportMixedMode
        let isInRimeOnlyMode = inputEngine.isForcingRimeMode || !doesSchemaSupportMixedMode
        let isEnglishActive = inputMode == .english || inputMode == .mixed && !isInRimeOnlyMode
        let englishCandidates = inputEngine.englishCandidates
        // English source might overlap with Rime source. Use this to dedup English candidates.
        var candidatesSet: Set<String> = Set()
        
        if candidatePaths.isEmpty {
            candidatePaths.append([])
        }
        
        let firstRimeCandidateLength = inputEngine.getRimeCandidate(0)?.count ?? 0
        // Experimenting new way to order candidates.
        let isRimeExactMatch = inputEngine.isRimeFirstCandidateCompleteMatch
        
        if !isRimeExactMatch { hasLoadedAllBestRimeCandidates = true }
        
        // Populate the best Rime candidates. It's in the best candidates set if the user input is the prefix of candidate's composition.
        while inputMode != .english &&
              !hasLoadedAllBestRimeCandidates &&
              curRimeCandidateIndex < inputEngine.rimeLoadedCandidatesCount {
            guard let candidate = inputEngine.getRimeCandidate(curRimeCandidateIndex) else {
                hasLoadedAllBestRimeCandidates = true
                break
            }
            
            if firstRimeCandidateLength - candidate.count > 0 {
                hasLoadedAllBestRimeCandidates = true
                break
            }
            
            // In Quick mode, filter out char with mismatching IICore
            if shouldCurrentRimeCandidateBeFiltered(inputEngine) {
                curRimeCandidateIndex += 1
                continue
            }
            
            candidatesSet.insert(candidate)
            candidatePaths[0].append(CandidatePath(source: .rime, index: curRimeCandidateIndex))
            curRimeCandidateIndex += 1
            // TODO, change N to change with candidate cell width. Show 1 English candidate at the end of the row.
            // For every N Rime candidates, mix an English candidate.
            if curRimeCandidateIndex % 4 == 0 && isEnglishActive {
                while curEnglishCandidateIndex < inputEngine.englishPrefectCandidatesStartIndex {
                    let hasAddedCandidate = appendEnglishCandidate(curEnglishCandidateIndex, candidatesSet)
                    curEnglishCandidateIndex += 1
                    if hasAddedCandidate { break }
                }
            }
        }
        
        // Do not populate remaining English candidates until all best Rime candidates are populated.
        if !hasLoadedAllBestRimeCandidates && inputMode != .english && !inputEngine.hasRimeLoadedAllCandidates { return }
        
        // If input is not an English word, insert best English candidates after populating Rime best candidates.
        if !hasPopulatedBestEnglishCandidates && isEnglishActive {
            for i in curEnglishCandidateIndex..<inputEngine.englishWorstCandidatesStartIndex {
                _ = appendEnglishCandidate(i, candidatesSet)
            }
            hasPopulatedBestEnglishCandidates = true
        }
        
        // Populate remaining Rime candidates.
        while inputMode != .english && curRimeCandidateIndex < inputEngine.rimeLoadedCandidatesCount {
            // In Quick mode, filter out char with mismatching IICore
            if shouldCurrentRimeCandidateBeFiltered(inputEngine) {
                curRimeCandidateIndex += 1
                continue
            }
            
            guard let candidate = inputEngine.getRimeCandidate(curRimeCandidateIndex) else {
                continue
            }
            candidatesSet.insert(candidate)
            candidatePaths[0].append(CandidatePath(source: .rime, index: curRimeCandidateIndex))
            curRimeCandidateIndex += 1
        }
        
        // Populate worst English candidates.
        if (inputMode == .english || inputEngine.hasRimeLoadedAllCandidates) && !hasPopulatedWorstEnglishCandidates && isEnglishActive {
            for i in inputEngine.englishWorstCandidatesStartIndex..<englishCandidates.count {
                _ = appendEnglishCandidate(i, candidatesSet)
            }
            hasPopulatedWorstEnglishCandidates = true
        }
    }
    
    private func shouldCurrentRimeCandidateBeFiltered(_ inputEngine: BilingualInputEngine) -> Bool {
        // In Quick mode, filter out char with mismatching IICore
        if inputEngine.rimeSchema == .quick {
            guard let candidate = inputEngine.getRimeCandidate(curRimeCandidateIndex) else {
                return true
            }
            
            let iicoreCombined = candidate.unicodeScalars
                .map({ $0.value })
                .compactMap({
                    // DDLogInfo("IICore: \(candidate) \(Self.unihanDict.getUnihanEntry($0))")
                    return Self.unihanDict.getUnihanEntry($0).iiCore
                })
                .reduce([.T, .G] as IICore, { $0.intersection($1) })
            
            let iicoreMask = Settings.cached.charForm == .traditional ? IICore.T : IICore.G
            if !iicoreCombined.contains(iicoreMask) {
                return true
            }
        }
        return false
    }
    
    private func appendEnglishCandidate(_ i: Int, _ insertedCandidates: Set<String>) -> Bool {
        guard let inputController = inputController,
              let inputEngine = inputController.inputEngine,
              inputController.state.reverseLookupSchema == nil &&
              !insertedCandidates.contains(inputEngine.englishCandidates[i]) &&
              inputController.state.inputMode != .chinese &&
              inputController.state.inputMode != .english && i < 7 || inputController.state.inputMode == .english
            else { return false }
        
        if inputController.state.inputMode != .chinese && !Settings.cached.shouldShowEnglishExactMatch &&
            inputEngine.englishCandidates[i] == inputEngine.englishComposition?.text {
            // Skip exact match in mixed mode.
            return false
        }
        
        if inputController.state.inputMode == .english && inputEngine.englishCandidates[i].contains(where: { $0.isChineseChar }) {
            // Do not return words with any CJK chars in English mode.
            return false
        }
        
        candidatePaths[0].append(CandidatePath(source: .english, index: i))
        return true
    }
    
    private func populateCandidatesByRomanization() {
        guard let inputController = inputController,
              let inputEngine = inputController.inputEngine,
              inputController.state.inputMode != .english else { return }
        
        while inputEngine.loadMoreRimeCandidates() {}
        
        var sections: [String] = []
        var candidateCount = Dictionary<String, Int>()
        var candidateGroupByRomanization = Dictionary<String, [Int]>()
        for i in 0..<inputEngine.rimeLoadedCandidatesCount {
            guard let romanization = CandidateInfo.getJyutping(inputEngine.getRimeCandidateComment(i)) else { continue }
            let firstCharRomanization = String(romanization.prefix(while: { $0 != " " }))
            
            if !candidateGroupByRomanization.keys.contains(firstCharRomanization) {
                candidateGroupByRomanization[firstCharRomanization] = []
                candidateCount[firstCharRomanization] = 0
                sections.append(firstCharRomanization)
            }
            candidateGroupByRomanization[firstCharRomanization]?.append(i)
            candidateCount[firstCharRomanization] = (candidateCount[firstCharRomanization] ?? 0) + 1
        }
        
        /*
        // Merge single buckets.
        var headersToRemove = Set<String>()
        for i in 0..<sections.count {
            let header = sections[i]
            guard candidateCount[header] == 1 else { continue }
            
            // If there are slibling romainization, do not merge the bucket.
            let headerWithoutTone = header.prefix(header.count - 1)
            guard sections.filter({ $0.starts(with: headerWithoutTone) }).count == 1 else { continue }
            
            headersToRemove.insert(header)
            let newHeader = String(header.first!)
            if !candidateGroupByRomanization.keys.contains(newHeader) {
                candidateGroupByRomanization[newHeader] = []
                sections.append(newHeader)
            }
            if let candidateIndices = candidateGroupByRomanization[header] {
                candidateGroupByRomanization[newHeader]?.append(contentsOf: candidateIndices)
            }
        }
        */
        
        // Show exact match (without tones) first. The rest in alphabetical order.
        let composingTextEnglishSuffix = inputEngine.rimeComposition?.text.filter({ $0.isEnglishLetter }).lowercased() ?? ""
        let bestSections = sections.filter({ composingTextEnglishSuffix.starts(with: $0.withoutTailingDigit) }).sorted(by: { a, b in
            if a.count == b.count {
                return a.compare(b) == .orderedAscending
            } else {
                return a.count > b.count
            }
        })
        sections = bestSections + sections.filter({ !composingTextEnglishSuffix.starts(with: $0.withoutTailingDigit) }).sorted()
        
        sectionHeaders = []
        for i in 0..<sections.count {
            let header = sections[i]
            guard let candidates = candidateGroupByRomanization[header]?.map({ CandidatePath(source: .rime, index: $0) }) else { continue }
            candidatePaths.append(candidates)
            sectionHeaders.append(header)
        }
    }
    
    private func populateCandidatesByRadical() {
        guard let inputController = inputController,
              let inputEngine = inputController.inputEngine,
              inputController.state.inputMode != .english else { return }
        
        while inputEngine.loadMoreRimeCandidates() {}
        
        var candidateGroupByRadical = Dictionary<UInt8, [Int]>()
        var radicalStrokes = Dictionary<Int, UInt8>()
        for i in 0..<inputEngine.rimeLoadedCandidatesCount {
            guard let candidate = inputEngine.getRimeCandidate(i),
                  let candidateFirstCharInUtf32 = candidate.first?.unicodeScalars.first?.value else { continue }
            
            let unihanEntry = Self.unihanDict.getUnihanEntry(candidateFirstCharInUtf32)
            let radical = unihanEntry.radical
            guard radical != 0 else { continue }
            if !candidateGroupByRadical.keys.contains(radical) {
                candidateGroupByRadical[radical] = []
            }
            candidateGroupByRadical[radical]?.append(i)
            radicalStrokes[i] = unihanEntry.radicalStroke
        }
        
        let candidateGroupByKeysSorted = candidateGroupByRadical.keys.sorted()
        sectionHeaders = []
        for i in 0..<candidateGroupByKeysSorted.count {
            let header = candidateGroupByKeysSorted[i]
            guard let candidates = candidateGroupByRadical[header]?
                    .sorted(by: { radicalStrokes[$0] ?? 0 < radicalStrokes[$1] ?? 0 })
                    .map({ CandidatePath(source: .rime, index: $0) }) else { continue }
            candidatePaths.append(candidates)
            if let radicalChar = Self.radicalChars[safe: Int(header) - 1] {
                sectionHeaders.append(radicalChar)
            }
        }
    }
    
    private func populateCandidatesByTotalStroke() {
        guard let inputController = inputController,
              let inputEngine = inputController.inputEngine,
              inputController.state.inputMode != .english else { return }
        
        while inputEngine.loadMoreRimeCandidates() {}
        
        var candidateGroupByTotalStroke = Dictionary<UInt8, [Int]>()
        for i in 0..<inputEngine.rimeLoadedCandidatesCount {
            guard let candidate = inputEngine.getRimeCandidate(i),
                  let candidateFirstCharInUtf32 = candidate.first?.unicodeScalars.first?.value else { continue }
            
            let unihanEntry = Self.unihanDict.getUnihanEntry(candidateFirstCharInUtf32)
            let totalStroke = unihanEntry.totalStroke
            guard totalStroke != 0 else { continue }
            if !candidateGroupByTotalStroke.keys.contains(totalStroke) {
                candidateGroupByTotalStroke[totalStroke] = []
            }
            candidateGroupByTotalStroke[totalStroke]?.append(i)
        }
        
        let candidateGroupByKeysSorted = candidateGroupByTotalStroke.keys.sorted()
        sectionHeaders = []
        for i in 0..<candidateGroupByKeysSorted.count {
            let header = candidateGroupByKeysSorted[i]
            guard let candidates = candidateGroupByTotalStroke[header]?.map({ CandidatePath(source: .rime, index: $0) }) else { continue }
            candidatePaths.append(candidates)
            sectionHeaders.append(String(header))
        }
    }
    
    func updateCandidates(reload: Bool, targetCandidatesCount: Int) {
        guard let inputEngine = inputController?.inputEngine,
              reload || groupByMode == .byFrequency else { return }
        if reload { resetCandidates() }
        
        repeat {
            _ = inputEngine.loadMoreRimeCandidates()
            populateCandidates()
        } while inputEngine.rimeLoadedCandidatesCount < targetCandidatesCount && !inputEngine.hasRimeLoadedAllCandidates
    }

    func getNumberOfSections() -> Int {
        return candidatePaths.count
    }
    
    func getSectionHeader(section: Int) -> String? {
        return sectionHeaders[safe: section]
    }
    
    func getCandidate(indexPath: IndexPath) -> String? {
        guard let candidatePath = getCandidatePath(indexPath: indexPath) else { return nil }
        
        switch candidatePath.source {
        case .rime: return inputController?.inputEngine.getRimeCandidate(candidatePath.index)
        case .english: return inputController?.inputEngine.englishCandidates[safe: candidatePath.index]
        }
    }
    
    private func getCandidatePath(indexPath: IndexPath) -> CandidatePath? {
        return candidatePaths[safe: indexPath.section]?[safe: indexPath.row]
    }
    
    func selectCandidate(indexPath: IndexPath) -> String? {
        guard let candidatePath = getCandidatePath(indexPath: indexPath) else { return nil }
        
        let selectedCandidate: String?
        switch candidatePath.source {
        case .rime: selectedCandidate = inputController?.inputEngine.selectRimeCandidate(candidatePath.index)
        case .english: selectedCandidate = inputController?.inputEngine.selectEnglishCandidate(candidatePath.index)
        }
        resetCandidates()
        return selectedCandidate
    }
    
    func unlearnCandidate(indexPath: IndexPath) {
        guard let candidatePath = getCandidatePath(indexPath: indexPath) else { return }
        
        switch candidatePath.source {
        case .rime: _ = inputController?.inputEngine.unlearnRimeCandidate(candidatePath.index)
        case .english:
            if let word = getCandidate(indexPath: indexPath) {
                _ = EnglishInputEngine.userDictionary.unlearn(word: word)
            }
        }
        resetCandidates()
    }
    
    func getCandidateComment(indexPath: IndexPath) -> String? {
        guard let candidatePath = getCandidatePath(indexPath: indexPath) else { return nil }
        
        switch candidatePath.source {
        case .rime: return inputController?.inputEngine.getRimeCandidateComment(candidatePath.index)
        default: return nil
        }
    }
    
    func getCandidateCount(section: Int) -> Int {
        return candidatePaths[safe: section]?.count ?? 0
    }
    
    var supportedGroupByModes: [GroupByMode] {
        [ .byFrequency, .byRomanization, .byRadical, .byTotalStroke ]
    }
    
    var groupByMode: GroupByMode = GroupByMode.byFrequency {
        didSet {
            guard oldValue != groupByMode else { return }
            updateCandidates(reload: true)
        }
    }
}

class AutoSuggestionCandidateSource: CandidateSource {
    private let candidates: [String]
    let cannotExpand: Bool
    var isStatic: Bool { true }
    
    init(_ candidates: [String], cannotExpand: Bool = false) {
        self.candidates = candidates
        self.cannotExpand = cannotExpand
    }
    
    func updateCandidates(reload: Bool, targetCandidatesCount: Int) {
    }
    
    func getNumberOfSections() -> Int {
        return 1
    }
    
    func getSectionHeader(section: Int) -> String? {
        return nil
    }
    
    func getCandidate(indexPath: IndexPath) -> String? {
        guard indexPath.section == 0 else { return nil }
        return candidates[safe: indexPath.row]
    }
    
    func selectCandidate(indexPath: IndexPath) -> String? {
        return getCandidate(indexPath: indexPath)
    }
    
    func unlearnCandidate(indexPath: IndexPath) {
    }
    
    func getCandidateComment(indexPath: IndexPath) -> String? {
        return nil
    }
    
    func getCandidateCount(section: Int) -> Int {
        return candidates.count
    }
    
    var supportedGroupByModes: [GroupByMode] { [ .byFrequency ] }
    
    var groupByMode: GroupByMode = .byFrequency
}

struct CandidatePath {
    enum Source {
        case english, rime
    }
    let source: Source
    let index: Int
}

enum AutoSuggestionType {
    case halfWidthPunctuation
    case fullWidthPunctuation
    case email
    case domain
    case keypadSymbols
    
    var replaceTextOnInsert: Bool {
        switch self {
        case .keypadSymbols: return true
        default: return false
        }
    }
}

extension PredictiveTextEngine {
    private static func initPredictiveTextEngine(charForm: CharForm) -> PredictiveTextEngine {
        if !DataFileManager.hasInstalled {
            fatalError("Data files not installed.")
        }
        
        let dictsPath = DataFileManager.builtInNGramDictDirectory
        let ngramFileName = charForm == .traditional ? "/zh_HK.ngram" : "/zh_CN.ngram"
        return PredictiveTextEngine(dictsPath + ngramFileName)
    }
    
    private static let hk = initPredictiveTextEngine(charForm: .traditional)
    private static let cn = initPredictiveTextEngine(charForm: .simplified)
    
    public static func getPredictiveTextEngine(charForm: CharForm) -> PredictiveTextEngine {
        return charForm == .traditional ? .hk : .cn
    }
}

// This class filter, group by and sort the candidates.
class CandidateOrganizer {
    private static let halfWidthPunctuationCandidateSource = AutoSuggestionCandidateSource([".", ",", "?", "!", "。", "，", "？", "！"], cannotExpand: true)
    private static let fullWidthPunctuationCandidateSource = AutoSuggestionCandidateSource(["。", "，", "、", "？", "！", ".", ",", "?", "!"], cannotExpand: true)
    private static let emailCandidateSource = AutoSuggestionCandidateSource(["gmail.com", "outlook.com", "icloud.com", "yahoo.com", "hotmail.com"])
    private static let domainCandidateSource = AutoSuggestionCandidateSource(["com", "org", "edu", "net", SessionState.main.localDomain, "hk", "tw", "mo", "cn", "uk", "jp"].unique())
    private static let keypadSymbolCandidateSource = AutoSuggestionCandidateSource([
        "。", "？", "！", "⋯⋯", "～", "#",
        "：", "、", "「」", "『』", "（）", "-",
        "——", "；", "@", "*", "_", "~",
        "%", "&", "．", "•", "/", "\\",
        "《》", "〈〉", "“”", "‘’", "〔〕", "【】",
        "［］", "[]", "｛｝", "{}", "()", "<>",
        "+", "-", "×", "÷", "=", "^",
        "$", "¥", "£", "€", "℃", "℉",
        ",", ".", ":", ";", "?", "!",
        "｜", "|", " ", "←", "↑", "→", "↓",
        "\"", "'", "…", "＄", "￥", "￡",
        "＋", "－", "／", "＼", "＝", "°",
        "＊", "＃", "＠", "％", "＆", "＿"].unique())
    enum GroupBy {
        case frequency, radical, stroke, tone
    }
    
    var onMoreCandidatesLoaded: ((CandidateOrganizer) -> Void)?
    var onReloadCandidates: ((CandidateOrganizer) -> Void)?
    var candidateSource: CandidateSource?
    var autoSuggestionType: AutoSuggestionType?
    var suggestionContextualText: String = ""
    
    private weak var inputController: InputController?
    private var predictiveTextEngine: PredictiveTextEngine
    
    init(inputController: InputController) {
        self.inputController = inputController
        predictiveTextEngine = PredictiveTextEngine.getPredictiveTextEngine(charForm: Settings.cached.charForm)
    }
    
    func requestMoreCandidates(section: Int) {
        guard section == 0, !(inputController?.inputEngine.hasRimeLoadedAllCandidates ?? false) else { return }
        if !(candidateSource?.isStatic ?? false) {
            updateCandidates(reload: false)
        }
    }
    
    func updateCandidates(reload: Bool, targetCandidatesCount: Int = 0) {
        guard let inputController = inputController else { return }
        if inputController.state.isInCaretMovingMode {
            candidateSource = nil
        } else if inputController.inputEngine.isComposing {
            candidateSource = InputEngineCandidateSource(inputController: inputController)
        } else if let autoSuggestionType = autoSuggestionType {
            switch autoSuggestionType {
            case .fullWidthPunctuation: candidateSource = Self.fullWidthPunctuationCandidateSource
            case .halfWidthPunctuation: candidateSource = Self.halfWidthPunctuationCandidateSource
            case .email: candidateSource = Self.emailCandidateSource
            case .domain: candidateSource = Self.domainCandidateSource
            case .keypadSymbols: candidateSource = Self.keypadSymbolCandidateSource
            }
            
            if Settings.cached.enablePredictiveText && !suggestionContextualText.isEmpty && inputController.state.inputMode != .english {
                let shouldFilterOffensiveWords = !Settings.cached.predictiveTextOffensiveWord
                let predictiveCandidates = predictiveTextEngine.predict(suggestionContextualText, filterOffensiveWords: shouldFilterOffensiveWords) as NSArray as? [String]
                if let predictiveCandidates = predictiveCandidates, !predictiveCandidates.isEmpty {
                    // DDLogInfo("Predictive text: \(suggestionContextualText) \(predictiveCandidates)")
                    candidateSource = AutoSuggestionCandidateSource(predictiveCandidates)
                }
            }
        } else {
            candidateSource = nil
        }
        
        candidateSource?.updateCandidates(reload: reload, targetCandidatesCount: targetCandidatesCount)
        
        if reload {
            onReloadCandidates?(self)
        } else {
            onMoreCandidatesLoaded?(self)
        }
    }

    func getNumberOfSections() -> Int {
        return candidateSource?.getNumberOfSections() ?? 0
    }
    
    func getCandidate(indexPath: IndexPath) -> String? {
        return candidateSource?.getCandidate(indexPath: indexPath)
    }
    
    func selectCandidate(indexPath: IndexPath) -> String? {
        let candidate = candidateSource?.selectCandidate(indexPath: indexPath)
        updateCandidates(reload: true)
        return candidate
    }
    
    func unlearnCandidate(indexPath: IndexPath) {
        candidateSource?.unlearnCandidate(indexPath: indexPath)
    }
    
    func getCandidateComment(indexPath: IndexPath) -> String? {
        return candidateSource?.getCandidateComment(indexPath: indexPath)
    }
    
    func getCandidateCount(section: Int) -> Int {
        return candidateSource?.getCandidateCount(section: section) ?? 0
    }
    
    func getSectionHeader(section: Int) -> String? {
        return candidateSource?.getSectionHeader(section: section)
    }
    
    var shouldCloseCandidatePaneOnCommit: Bool {
        true
    }
    
    var supportedGroupByModes: [GroupByMode] {
        candidateSource?.supportedGroupByModes ?? [ .byFrequency ]
    }
    
    var groupByMode: GroupByMode {
        get { candidateSource?.groupByMode ?? .byFrequency }
        set { candidateSource?.groupByMode = newValue }
    }
    
    var cannotExpand: Bool {
        (candidateSource as? AutoSuggestionCandidateSource)?.cannotExpand ?? false
    }
    
    // If there are any initial wildcards not followed by a final, show wildcard hint.
    var shouldDisplayWildcardHint: Bool {
        guard inputController?.inputEngine.rimeSchema == .jyutpingInitialFinal,
              let text = inputController?.inputEngine.rimeRawInput?.text else { return false }
        for index in text.indices {
            if text[index] == "X" { // wildcard
                let nextIndex = text.index(after: index)
                if nextIndex == text.endIndex || text[nextIndex] != "9" { // the start of a final
                    return true
                }
            }
        }
        return false
    }
}
