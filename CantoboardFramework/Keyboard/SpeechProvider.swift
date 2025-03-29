//
//  SpeechProvider.swift
//  CantoboardFramework
//
//  Created by Alex Man on 21/3/25.
//

import AVFoundation
import CocoaLumberjackSwift

class SpeechProvider {
    private static let synthesizer = {
        let synthesizer = AVSpeechSynthesizer()
        synthesizer.delegate = speechDelegate
        return synthesizer
    }()
    
    private static let cantoneseVoice = AVSpeechSynthesisVoice.speechVoices()
                                            .filter({ $0.language == "zh-HK" })
                                            .max(by: { $0.quality.rawValue < $1.quality.rawValue })
                                            ?? AVSpeechSynthesisVoice(language: "zh-HK")
    
    fileprivate static var audioPlayer: AVAudioPlayer!
    
    private static let speechDelegate = SpeechDelegate()
    
    static func speak(_ text: String, rateMultiplier: Float = 1) {
        guard let voice = cantoneseVoice else {
            speakEnqueued()
            return
        }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * rateMultiplier
        synthesizer.speak(utterance)
    }
    
    static func play(initialFinalResource: String) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: "\(DataFileManager.dataResourceDirectory)/InitialFinal/\(initialFinalResource).mp3"))
            audioPlayer.delegate = speechDelegate
            audioPlayer.play()
        } catch {
            DDLogError(error)
            speakEnqueued()
        }
    }
    
    enum SpeechType {
        case candidate, committedText, character, initialFinal
    }
    
    private static var inClosureAndHasNotStopped = false
    
    private static var speechQueue: [(type: SpeechType, textOrResource: String)] = []
    
    static func enqueue(_ type: SpeechType, _ textOrResource: String) {
        if inClosureAndHasNotStopped {
            stop()
            inClosureAndHasNotStopped = false
        }
        speechQueue.append((type, textOrResource))
    }
    
    private static var lastSpeechType: SpeechType?
    
    fileprivate static func speakEnqueued() {
        guard !speechQueue.isEmpty else {
            lastSpeechType = nil
            return
        }
        let (type, textOrResource) = speechQueue.removeFirst()
        if lastSpeechType == .committedText && type == .character {
            // Skip the character since it may have already been included in the committed text.
            speakEnqueued()
            return
        } else {
            lastSpeechType = type
        }
        if type == .initialFinal {
            play(initialFinalResource: textOrResource)
        } else {
            speak(textOrResource)
        }
    }
    
    static func queueAndSpeak(_ closure: () -> Void) {
        inClosureAndHasNotStopped = true
        closure()
        inClosureAndHasNotStopped = false
        speakEnqueued()
    }
    
    static func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        audioPlayer = nil
        speechQueue.removeAll()
    }
}

private class SpeechDelegate: NSObject, AVSpeechSynthesizerDelegate, AVAudioPlayerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        SpeechProvider.speakEnqueued()
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        SpeechProvider.audioPlayer = nil
        SpeechProvider.speakEnqueued()
    }
}
