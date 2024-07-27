//
//  SpeechAnalyzer.swift
//  dictionary
//
//  Created by New on 22.07.2024.
//

import Foundation
import Speech
import SwiftUI

final class SpeechAnalyzer: NSObject, ObservableObject, SFSpeechRecognizerDelegate {
    private let audioEngine = AVAudioEngine()
    private let listeningTime = 2
    private var inputNode: AVAudioInputNode?
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioSession: AVAudioSession?
    
    @Published var recognizedText: String?
    @Published var isProcessing: Bool = false
    
    func start(identifier: String? = nil) {
        audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession?.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession?.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            NSLog("Couldn't configure the audio session properly")
        }
        
        inputNode = audioEngine.inputNode
        if identifier != nil {
            // Force specified locale
            speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: identifier!))
        }else{
            speechRecognizer = SFSpeechRecognizer()
        }
        
        NSLog("Supports on device recognition: \(speechRecognizer?.supportsOnDeviceRecognition == true ? "✅" : "🔴")")
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        // Disable partial results
        //         recognitionRequest?.shouldReportPartialResults = false
        
        if(settings.recognitionOnDevice && speechRecognizer?.supportsOnDeviceRecognition == true){
            // Enable on-device recognition
            recognitionRequest?.requiresOnDeviceRecognition = true
        }
        guard let speechRecognizer = speechRecognizer,
              speechRecognizer.isAvailable,
              let recognitionRequest = recognitionRequest,
              let inputNode = inputNode
        else {
            assertionFailure("Unable to start the speech recognition!")
            return
        }
        
        speechRecognizer.delegate = self
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            recognitionRequest.append(buffer)
        }
        
        var timerDidFinishTalk = createTimer()
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            self?.recognizedText = result?.bestTranscription.formattedString
            timerDidFinishTalk.invalidate()
            guard error != nil || result?.isFinal == true else {
                timerDidFinishTalk = (self?.createTimer())!
                return
            }
            if error != nil{
                NSLog("Speech recognition not possible. " + error!.localizedDescription)
            }
            self?.stop()
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
            isProcessing = true
        } catch {
            NSLog("Coudn't start audio engine!")
            stop()
        }
    }
    func createTimer() -> Timer {
        return Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false){ timer in
            NSLog("Timer fired!")
            self.stop()
        }
    }
    func didFinishTalk(){
        
    }
    func stop() {
        if isProcessing {
            NSLog("stop")
            recognitionTask?.cancel()
            
            audioEngine.stop()
            
            inputNode?.removeTap(onBus: 0)
            try? audioSession?.setActive(false)
            audioSession = nil
            inputNode = nil
            
            isProcessing = false
            
            recognitionRequest = nil
            recognitionTask = nil
            speechRecognizer = nil
        }
    }
    
    public func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            NSLog("✅ Available")
        } else {
            NSLog("🔴 Unavailable")
            recognizedText = "Text recognition unavailable. Sorry!"
            stop()
        }
    }
    func getSupportedLocales() -> Set<Locale> {
        return SFSpeechRecognizer.supportedLocales()
    }
    
    func getSupportsOnDeviceRecognition(identifier: String) -> Bool {
        let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: identifier))
        return speechRecognizer?.supportsOnDeviceRecognition == true
    }
}

struct SpeechRecognitionView: View {
    private enum Constans {
        static let recognizeButtonSide: CGFloat = 80
    }
    @State var word : Word?
    @ObservedObject private var speechAnalyzer = SpeechAnalyzer()
    var body: some View {
        VStack {
            Spacer()
            if word != nil {
                DetailsView(word: word)
                PlayerButton(action: playWord, systemName: "play.fill")
                    .padding()
            }
            Spacer()
            Text(speechAnalyzer.recognizedText ?? "Tap to begin")
                .padding()
            
            Button {
                toggleSpeechRecognition()
            } label: {
                Image(systemName: speechAnalyzer.isProcessing ? "waveform.circle.fill" : "waveform.circle")
                    .resizable()
                    .frame(width: Constans.recognizeButtonSide,
                           height: Constans.recognizeButtonSide,
                           alignment: .center)
                    .foregroundColor(speechAnalyzer.isProcessing ? .red : .gray)
                    .aspectRatio(contentMode: .fit)
            }
            .padding()
        }
        .contentShape(Rectangle())
        .gesture(DragGesture(minimumDistance: 10, coordinateSpace: .local)
                    .onEnded { value in
            let horizontalAmount = value.translation.width
            let verticalAmount = value.translation.height
            
            if abs(horizontalAmount) > abs(verticalAmount) {
                if horizontalAmount < 0 {
                    nextWord()
                }
                //                            print(horizontalAmount < 0 ? "left swipe" : "right swipe")
            } else {
                //                            print(verticalAmount < 0 ? "up swipe" : "down swipe")
            }
        })
        .onAppear(perform: nextWord)
    }
}

private extension SpeechRecognitionView {
    func toggleSpeechRecognition() {
        if speechAnalyzer.isProcessing {
            speechAnalyzer.stop()
        } else {
            speechAnalyzer.start(identifier: getIdentifier())
        }
    }
    
    func playWord() {
        if let word = word {
            player.toSpeech(language: word.language, text: word.word)
        }
    }
    func nextWord() {
        word = player.words[Int.random(in: 0..<player.words.count)]
    }
    func getIdentifier() -> String? {
        if let word = word {
            if let preset = settings.currentSpeechRecognition[word.language]{
                return preset
            }
            return word.language
        }
        return nil
    }
}
