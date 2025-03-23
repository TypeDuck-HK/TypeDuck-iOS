//
//  SpeechProvider.swift
//  CantoboardFramework
//
//  Created by Alex Man on 21/3/25.
//

import AVFoundation

class SpeechProvider {
    private static let synthesizer = AVSpeechSynthesizer()
    private static let cantoneseVoice = AVSpeechSynthesisVoice.speechVoices()
                                            .filter({ $0.language == "zh-HK" })
                                            .max(by: { $0.quality.rawValue < $1.quality.rawValue })
                                            ?? AVSpeechSynthesisVoice(language: "zh-HK")
    static func speak(_ text: String) {
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = cantoneseVoice
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.85
        synthesizer.speak(utterance)
    }
}
