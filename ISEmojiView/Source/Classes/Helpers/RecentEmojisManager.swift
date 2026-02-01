//
//  RecentEmojisManager.swift
//  ISEmojiView
//
//  Created by Beniamin Sarkisyan on 01/08/2018.
//

import Foundation

private let recentEmojisKey = "ISEmojiView.recent"
private let recentEmojisFreqStorageKey = "ISEmojiView.recent-freq"

final internal class RecentEmojisManager {
    
    // MARK: - Public variables
    
    static let sharedInstance = RecentEmojisManager()
    
    internal var maxCountOfCenetEmojis: Int = 0
    
    // MARK: - Private cache
    
    private var cachedRecentEmojis: [Emoji]?
    private var cachedFreqData: [String: Int]?
    
    // MARK: - Public functions
    
    internal func add(emoji: Emoji, selectedEmoji: String) -> Bool {
        guard maxCountOfCenetEmojis > 0 else {
            return false
        }
        
        var emojis = recentEmojis()
        var freqData = recentEmojisFreqData()
        
        emoji.selectedEmoji = selectedEmoji
        
        if let freq = freqData[selectedEmoji] {
            freqData[selectedEmoji] = freq+1
        } else {
            freqData[selectedEmoji] = 0
            
        }
        
        guard emojis.firstIndex(of: emoji) == nil else {
                UserDefaults.standard.set(freqData, forKey: recentEmojisFreqStorageKey)
                // Update cache
                cachedFreqData = freqData
                invalidateEmojiCache()
                return true
        }

        if emojis.count > maxCountOfCenetEmojis {
            emojis.removeLast(emojis.count-maxCountOfCenetEmojis)
        }
        
        if emojis.count > 0 && emojis.count == maxCountOfCenetEmojis {
            let toRemove = emojis.removeLast()
            let newIndex = maxCountOfCenetEmojis/3
            let oldOne = emojis[newIndex].selectedEmoji ?? ""
            emojis.insert(emoji, at: newIndex)
            freqData[selectedEmoji] = (freqData[oldOne] ?? 0) + 1
            freqData.removeValue(forKey: toRemove.selectedEmoji ?? "")
        } else {
            emojis.append(emoji)
        }
        
        if let data = try? JSONEncoder().encode(emojis) {
            UserDefaults.standard.set(data, forKey: recentEmojisKey)
        }
        
        UserDefaults.standard.set(freqData, forKey: recentEmojisFreqStorageKey)
        
        // Invalidate cache after adding
        cachedFreqData = freqData
        invalidateEmojiCache()
        
        return true
    }
    
    private func invalidateEmojiCache() {
        cachedRecentEmojis = nil
    }
    
    internal func recentEmojisFreqData() -> [String: Int] {
        if let cached = cachedFreqData {
            return cached
        }
        guard let data = UserDefaults.standard.dictionary(forKey: recentEmojisFreqStorageKey) as? [String: Int] else {
            return [:]
        }
        cachedFreqData = data
        return data
    }
    
    internal func recentEmojis() -> [Emoji] {
        // Return cached if available
        if let cached = cachedRecentEmojis {
            return cached
        }
        
        guard let data = UserDefaults.standard.data(forKey: recentEmojisKey) else {
            return []
        }
        
        guard let emojis = try? JSONDecoder().decode([Emoji].self, from: data) else {
            return []
        }
        let freqData = recentEmojisFreqData()
        let seq = emojis.sorted {
            let left = freqData[$0.selectedEmoji ?? ""] ?? 0
            let right = freqData[$1.selectedEmoji ?? ""] ?? 0
            return left > right
        }
        
        // Cache the result
        cachedRecentEmojis = seq
        
        return seq
    }
    
}
