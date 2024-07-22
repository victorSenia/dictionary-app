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
        case general, advanced
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
                .tag(Tabs.advanced)
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
    var initialized = false
    var currentVoicesDictionary: [String:String] = [:]
    var currentVoices: [String:String] {
        get {
            if(!initialized){
            guard let currentVoices = try? JSONDecoder().decode([String:String].self, from: currentVoicesData) else { return [:] }
                currentVoicesDictionary = currentVoices
                initialized = true
            }
            return currentVoicesDictionary
        }
        set {
            currentVoicesDictionary = newValue
            guard let currentVoices = try? JSONEncoder().encode(newValue) else { return }
            currentVoicesData = currentVoices
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
                //                .keyboardType(.numberPad)
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
            // Slider(value: $fontSize, in: 9...96) {
            // Text("Font Size (\(fontSize, specifier: "%.0f") pts)")
            // }
            VoiceSettingsView()
        }
        // .padding(20)
        // .frame(width: 350, height: 100)
    }
}
struct LabeledDoubleView: View {
    var value: Binding<Double>
    var key: LocalizedStringKey
    // public init<F>(_ titleKey: LocalizedStringKey, value: Binding<F.FormatInput?>, format: F, prompt: Text? = nil) where F : ParseableFormatStyle, F.FormatOutput == String
    var body: some View {
        HStack{
            Text(key).layoutPriority(2)
            if #available(macOS 12.0, *) {
                TextField(key, value: value, format: .number)
                    .multilineTextAlignment(.trailing)
                    .textFieldStyle(.roundedBorder)
                //                .keyboardType(.numberPad)
            } else {
                TextField(key, value: value, formatter: {
                    var nf = NumberFormatter()
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
        List {
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
            Section(header: Text("Languages in database")){
                ForEach (getLanguages(), id: \.self) {languageInUse in
                    Button {
                        language = languageInUse
                        selected = player.voiceRetriever.voices[languageInUse]
                    } label: {
                        Text(languageInUse)
                    }
                    .listRowBackground(language == languageInUse ? selectedBackground() : nil)
                }}
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
        languages.append(contentsOf: databaseWordProvider._databaseManager.languageFrom())
        languages.append(contentsOf: databaseWordProvider._databaseManager.languageTo(language: nil))
        return Array(Set(languages)).sorted()
    }
}
