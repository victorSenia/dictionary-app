//
//  Player.swift
//  dictionary
//
//  Created by New on 07.07.2024.
//

import Foundation
import AVFoundation
import SwiftUI

protocol UiUpdater{
    func updateCurrentWordState(index: Int, word: Word)
}
class Player: NSObject, ObservableObject, AVSpeechSynthesizerDelegate{
    var uiUpdater: UiUpdater?
    
    @Published var words:[Word] = []
    // Create a speech synthesizer.
    let synthesizer = AVSpeechSynthesizer()
    let voiceRetriever = VoiceRetriever()
    @ObservedObject var playState = PlayingState()
    var wordProvider: WordProvider
    override init() {
        wordProvider = FileWordProvider()
        super.init()
        setupInit()
    }
    init(wordProvider: WordProvider) {
        self.wordProvider = wordProvider
        super.init()
        setupInit()
    }
    func setupInit(){
        synthesizer.delegate = self
    }
    
    func checkIndexLimits(index: Int) -> Int{
        if index < 0 {
            return words.count - 1
        }
        if index > words.count - 1 {
            return 0
        }
        return index
    }
    
    func findWords(criteria: WordCriteria){
        words = []
        words = wordProvider.findWords(criteria: criteria)
        
    }
    func resetPlayerState() {
        playState.current = nil
        playState.didFinish = nil
        playState.repetition = 1
        playState.plaingTranslation = false
    }
    
    func selectAndSpeekWord() {
        if words.count > 0 {
            playState.isStoped = false
            resetPlayerState()
            selectWord()
            speakWord()
        }
    }
    
    func speechDidFinish(didFinish: AVSpeechUtterance) {
        if !playState.isStoped && playState.didFinish == didFinish{
            if !playState.plaingTranslation {
                playState.plaingTranslation = true
                speakTranslation()
            }
            else if playState.repetition < settings.repeatTimes {
                playState.repetition += 1
                playState.plaingTranslation = false
                speakWord()
            }
            else {
                playFromIndex(index: playState.index + 1)
            }
        }
    }
    func playFromIndex(index: Int){
        setIndex(index: index)
        selectAndSpeekWord()
    }
    func stopAndPlayFromIndex(index: Int){
        stopSpeaking()
        DispatchQueue.main.async {
            self.playFromIndex(index: index)
        }
    }
    func nextWord(){
        stopAndPlayFromIndex(index: playState.index + 1)
    }
    func previousWord(){
        stopAndPlayFromIndex(index: playState.index - 1)
    }
    func selectWord(){
        playState.current = words[playState.index]
        if let ui = uiUpdater {
            ui.updateCurrentWordState(index: playState.index, word: playState.current!)
        }
    }
    func speakWord(){
        if let word = playState.current {
            toSpeech(language: word.language, text: word.word)
        }
    }
    
    func speakTranslation(){
        if let word = playState.current {
            let translarions: [Translation] = word.translations
            // let translation = translarions[Int.random(in: 0..<translarions.count)]
            let translation = translarions[0]
            toSpeech(language: translation.language, text: translation.translation)
        }
    }
    func setIndex(index: Int){
        playState.index = checkIndexLimits(index: index)
        settings.currentIndex = playState.index
        playState.current = nil
    }
    func startStopSpeaking() {
        if playState.isStoped {
            setIndex(index: playState.index)
            selectAndSpeekWord()
        } else {
            stopSpeaking()
        }
    }
    func speechSynthesizer(_: AVSpeechSynthesizer, didFinish: AVSpeechUtterance){
        speechDidFinish(didFinish: didFinish)
    }
    
    func toSpeech(language:String, text: String){
        // Create an utterance.
        let utterance = createUtterance(language: language, text: text)
        playState.didFinish = utterance
        // Tell the synthesizer to speak the utterance.
        synthesizer.speak(utterance)
    }
    func toSpeechNoResult(language:String, text: String){
        // Create an utterance.
        let utterance = createUtteranceNoDelay(language: language, text: text)
        // Tell the synthesizer to speak the utterance.
        synthesizer.speak(utterance)
    }
    func stopSpeaking(at: AVSpeechBoundary){
        synthesizer.stopSpeaking(at: at)
        playState.isStoped = true
    }
    
    func stopSpeaking(){
        if !playState.isStoped {
            DispatchQueue.main.async {
                self.stopSpeaking(at: AVSpeechBoundary.immediate)
            }
        }
    }
    func createUtterance(language:String, text: String) -> AVSpeechUtterance {
        let preUtteranceDelay = playState.plaingTranslation ? settings.translationDelayBefore : settings.generalDelayBefore
        let postUtteranceDelay = playState.plaingTranslation ? 0.1 : Double(settings.generalDelayAfterPerLetter) / 1000 * Double(text.count)
        //        return createUtterance(language: language, text: text, preUtteranceDelay: Double(preUtteranceDelay) / 1000, postUtteranceDelay: postUtteranceDelay)
        return createUtterance(language: language, text: text, preUtteranceDelay: 0.0, postUtteranceDelay: 0.0)
    }
    func createUtteranceNoDelay(language:String, text: String) -> AVSpeechUtterance {
        return createUtterance(language: language, text: text, preUtteranceDelay: 0.0, postUtteranceDelay: 0.0)
    }
    
    func createUtterance(language:String, text: String, preUtteranceDelay: TimeInterval, postUtteranceDelay: TimeInterval) -> AVSpeechUtterance {
        // Create an utterance.
        let utterance = AVSpeechUtterance(string: text)
        
        // Configure the utterance.
        utterance.rate = Float(settings.speechRate)
        utterance.preUtteranceDelay = preUtteranceDelay
        utterance.postUtteranceDelay = postUtteranceDelay
        utterance.pitchMultiplier = Float(settings.speechPitch)
        // utterance.volume = 0.8
        
        // Retrieve the voice.
        let voice = voiceRetriever.voiceForLanguage(language: language)
        
        // Assign the voice to the utterance.
        utterance.voice = voice
        return utterance
    }
}
class PlayingState : ObservableObject {
    @Published var index: Int = settings.currentIndex
    @Published var isStoped: Bool = true
    var current: Word?
    var repetition: Int = 1
    var plaingTranslation: Bool = false
    var didFinish: AVSpeechUtterance?
}
class VoiceRetriever {
    var voices = settings.currentVoices
    func voiceForLanguage (language: String) -> AVSpeechSynthesisVoice {
        if let voiceIdentifier = voices[language] {
            return AVSpeechSynthesisVoice(identifier: voiceIdentifier)!
        }
        return AVSpeechSynthesisVoice(language: language)!
    }
}
