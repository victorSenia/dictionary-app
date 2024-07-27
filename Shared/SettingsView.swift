//
// SettingsView.swift
// dictionary
//
// Created by New on 03.07.2024.
//

import SwiftUI
import AVFoundation

struct SettingsView: View {
    private enum Tabs: Hashable {
        case general, speech, wordMatcher
    }
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    // Label("General", systemImage: "gear")
                }
                .tag(Tabs.general)
            SpeechSettingsView()
                .tabItem {
                    // Label("Advanced", systemImage: "star")
                }
                .tag(Tabs.speech)
            WordMatcherSettingsView()
                .tabItem {
                    // Label("Advanced", systemImage: "star")
                }
                .tag(Tabs.speech)
        }
        .tabViewStyle(.page(indexDisplayMode: .automatic))
        // .padding(20)
        // .frame(width: 375, height: 150)
    }
}
class Settings {
    @AppStorage("general.delayBefore") var generalDelayBefore = 100
    @AppStorage("general.delayAfterPerLetter") var generalDelayAfterPerLetter = 40
    @AppStorage("general.includeArticle") var generalIncludeArticle = true
    
    @AppStorage("repeat.times") var repeatTimes = 2
    @AppStorage("repeat.delayBefore") var repeatDelayBefore = 300
    
    @AppStorage("translation.active") var translationActive = true
    @AppStorage("translation.delayBefore") var translationDelayBefore = 500
    @AppStorage("translation.eachTime") var translationEachTime = true
    
    @AppStorage("speech.rate") var speechRate = 0.5
    @AppStorage("speech.pitch") var speechPitch = 0.8
    
    @AppStorage("current.index") var currentIndex = 0
    
    @AppStorage("current.voices") var currentVoicesData = Data()
    var voicesDecoded = false
    var currentVoicesDictionary: [String:String] = [:]
    var currentVoices: [String:String] {
        get {
            if(!voicesDecoded){
                guard let currentVoices = try? JSONDecoder().decode([String:String].self, from: currentVoicesData) else { return [:] }
                currentVoicesDictionary = currentVoices
                voicesDecoded = true
            }
            return currentVoicesDictionary
        }
        set {
            currentVoicesDictionary = newValue
            guard let currentVoices = try? JSONEncoder().encode(newValue) else { return }
            currentVoicesData = currentVoices
        }
    }
    
    @AppStorage("recognition.onDevice") var recognitionOnDevice = true
    
    @AppStorage("word.matcher.show.word") var wordMatcherShowWord = true
    @AppStorage("word.matcher.words.quantity") var wordMatcherWordsQuantity = 10
    
    @AppStorage("current.speech.recognition") var currentSpeechRecognitionData = Data()
    var speechRecognitionDecoded = false
    var currentSpeechRecognitionDictionary: [String:String] = [:]
    var currentSpeechRecognition: [String:String] {
        get {
            if(!speechRecognitionDecoded){
                guard let currentSpeechRecognition = try? JSONDecoder().decode([String:String].self, from: currentSpeechRecognitionData) else { return [:] }
                currentSpeechRecognitionDictionary = currentSpeechRecognition
                speechRecognitionDecoded = true
            }
            return currentSpeechRecognitionDictionary
        }
        set {
            currentSpeechRecognitionDictionary = newValue
            guard let currentSpeechRecognition = try? JSONEncoder().encode(newValue) else { return }
            currentSpeechRecognitionData = currentSpeechRecognition
        }
    }
    
    @AppStorage("current.criteria") var currentCriteriaData = Data()
    var currentCriteria: WordCriteria {
        get {
            guard let currentCriteria = try? JSONDecoder().decode(WordCriteria.self, from: currentCriteriaData) else { return WordCriteria() }
            return currentCriteria
        }
        set {
            guard let currentCriteria = try? JSONEncoder().encode(newValue) else { return }
            currentCriteriaData = currentCriteria
        }
    }
}
struct GeneralSettingsView: View {
    var body: some View {
        Form {
            Section(header: Text("General")){
                LabeledIntView(value: settings.$generalDelayBefore, key: "GeneralDelayBefore")
                LabeledIntView(value: settings.$generalDelayAfterPerLetter, key: "GeneralDelayAfterPerLetter")
                Toggle("generalIncludeArticle", isOn: settings.$generalIncludeArticle)
            }
            Section(header: Text("Repeat")){
                LabeledIntView(value: settings.$repeatTimes, key: "repeatTimes")
                LabeledIntView(value: settings.$repeatDelayBefore, key: "repeatDelayBefore")
            }
            Section(header: Text("Translation")){
                Toggle("translationActive", isOn: settings.$translationActive)
                LabeledIntView(value: settings.$translationDelayBefore, key: "translationDelayBefore")
                Toggle("translationEachTime", isOn: settings.$translationEachTime)
                // Slider(value: $fontSize, in: 9...96) {
                // Text("Font Size (\(fontSize, specifier: "%.0f") pts)")
                // }
                
            }
        }
        // .padding(20)
        // .frame(width: 350, height: 100)
    }
}

struct WordMatcherSettingsView: View {
    var body: some View {
        Form {
            Section(header: Text("word Matcher")){
                Toggle("ShowWord", isOn: settings.$wordMatcherShowWord)
                LabeledIntView(value: settings.$wordMatcherWordsQuantity, key: "Words Quantity")
            }
        }
    }
}

struct SettingGroupView: View {
    var key: LocalizedStringKey
    
    var body: some View {
        Text(key)
    }
}
struct LabeledIntView: View {
    var value: Binding<Int>
    var key: LocalizedStringKey
    var body: some View {
        HStack{
            Text(key).layoutPriority(2)
            if #available(macOS 12.0, *) {
                TextField(key, value: value, format: .number)
                    .multilineTextAlignment(.trailing)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
            } else {
                TextField(key, value: value, formatter: NumberFormatter())
                    .multilineTextAlignment(.trailing)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }
}

struct SpeechSettingsView: View {
    var body: some View {
        Form {
            Section(header: Text("Speech")){
                LabeledDoubleView(value: settings.$speechRate, key: "SpeechRate")
                LabeledDoubleView(value: settings.$speechPitch, key: "SpeechPitch")
            }
            VoiceSettingsView()
            
            Section(header: Text("Speech recognition")){
                Toggle("recognitionOnDevice", isOn: settings.$recognitionOnDevice)
            }
            SpeechRecognizerSettingsView()
        }
        // .padding(20)
        // .frame(width: 350, height: 100)
    }
}
struct LabeledDoubleView: View {
    var value: Binding<Double>
    var key: LocalizedStringKey
    var body: some View {
        HStack{
            Text(key).layoutPriority(2)
            if #available(macOS 12.0, *) {
                TextField(key, value: value, format: .number)
                    .multilineTextAlignment(.trailing)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
            } else {
                TextField(key, value: value, formatter: {
                    let nf = NumberFormatter()
                    nf.numberStyle = .decimal
                    return nf
                }())
                    .multilineTextAlignment(.trailing)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }
}

struct VoiceSettingsView: View {
    @State var language = ""
    @State var selected: String?
    @State var voices: [AVSpeechSynthesisVoice] = []
    var body: some View {
        Section (header: Text("Voices")){
            TextField("Language", text: $language)
                .textFieldStyle(.roundedBorder)
                .onChange(of: language, perform: {language in
                    if language.count == 2 {
                        let languageLowercased = language.lowercased()
                        selected = player.voiceRetriever.voices[language]
                        voices = AVSpeechSynthesisVoice.speechVoices().filter({voice in
                            voice.language.starts(with: languageLowercased)
                        })
                    }
                    else{
                        voices = []
                    }
                })
            Text("Languages in database")
            ForEach (getLanguages(), id: \.self) {languageInUse in
                Button {
                    language = languageInUse
                    selected = player.voiceRetriever.voices[languageInUse]
                } label: {
                    Text(languageInUse)
                }
                .listRowBackground(language == languageInUse ? selectedBackground() : nil)
            }
            if voices.count > 0 {
                Section(header: Text("Voices for language")){
                    Button {
                        player.voiceRetriever.voices.removeValue(forKey: language)
                        selected = nil
                    } label: {
                        Text("Use default")
                    }
                    .listRowBackground(selected == nil ? selectedBackground() : nil)
                    ForEach (voices, id: \.name){voice in
                        Button {
                            player.voiceRetriever.voices[language] = voice.identifier
                            settings.currentVoices = player.voiceRetriever.voices
                            selected = voice.identifier
                        } label: {
                            HStack {
                                Text(voice.language)
                                Text(voice.name)
                            }
                        }
                        .listRowBackground(voice.identifier == selected ? selectedBackground() : nil)
                    }
                }
            }
        }
    }
    func getLanguages() -> [String]{
        var languages:[String] = []
        languages.append(contentsOf: databaseWordProvider.languageFrom())
        languages.append(contentsOf: databaseWordProvider.languageTo(language: nil))
        return Array(Set(languages)).sorted()
    }
}

struct SpeechRecognizerSettingsView: View {
    @State var language = ""
    @State var selected: String?
    @State var locales: [Locale] = []
    var speechAnalyzer = SpeechAnalyzer()
    var body: some View {
        Section (header: Text("Speech recognizers")) {
            TextField("Language", text: $language)
                .textFieldStyle(.roundedBorder)
                .onChange(of: language, perform: {language in
                    if language.count == 2 {
                        let languageLowercased = language.lowercased()
                        selected = settings.currentSpeechRecognition[language]
                        locales = speechAnalyzer.getSupportedLocales().filter({locale in
                            locale.identifier.starts(with: languageLowercased)
                        })
                    }
                    else{
                        locales = []
                    }
                })
            Text("Languages in database")
            ForEach (getLanguages(), id: \.self) {languageInUse in
                Button {
                    language = languageInUse
                    selected = settings.currentSpeechRecognition[languageInUse]
                } label: {
                    Text(languageInUse)
                }
                .listRowBackground(language == languageInUse ? selectedBackground() : nil)
            }
            if locales.count > 0 {
                Section(header: Text("Speech recognizers for language")){
                    Button {
                        settings.currentSpeechRecognition.removeValue(forKey: language)
                        selected = nil
                    } label: {
                        Text("Use default")
                    }
                    .listRowBackground(selected == nil ? selectedBackground() : nil)
                    ForEach (locales, id: \.identifier ){ locale in
                        Button {
                            settings.currentSpeechRecognition[language] = locale.identifier
                            settings.currentSpeechRecognition = settings.currentSpeechRecognition
                            selected = locale.identifier
                        } label: {
                            HStack{
                                Text(locale.identifier)
                                Spacer()
                                Text("possible on device:")
                                Text(speechAnalyzer.getSupportsOnDeviceRecognition(identifier: locale.identifier) ? "✅" : "🔴")
                            }
                        }
                        .listRowBackground(locale.identifier == selected ? selectedBackground() : nil)
                    }
                }
            }
        }
    }
    func getLanguages() -> [String]{
        return databaseWordProvider.languageFrom().sorted()
    }
}
