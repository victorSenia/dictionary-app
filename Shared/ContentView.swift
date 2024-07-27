//
// ContentView.swift
// Shared
//
// Created by New on 23.06.2024.
//
import SwiftUI
import Foundation

struct ContentView: View {
    private enum Tabs: Hashable {
        case player, filter, settings, database, speechRecognition, wordMatcher
    }
    var body: some View {
        TabView {
            PlayerView(player: player)
                .onAppear {
                    player.findWords(criteria: criteriaHolder.criteria)
                }
                .tabItem {
                    Label("Player", systemImage: "play.circle")
                }
                .tag(Tabs.player)
            FilterView()
                .tabItem {
                    Label("Filter", systemImage: "magnifyingglass.circle")
                }
                .tag(Tabs.filter)
            //            SettingsView()
            //                .tabItem {
            //                    Label("Settings", systemImage: "gear")
            //                }
            //                .tag(Tabs.settings)
            DatabaseView()
                .tabItem {
                    Label("Database", systemImage: "star")
                }
                .tag(Tabs.database)
            SpeechRecognitionView()
                .tabItem {
                    Label("SpeechRecognition", systemImage: "waveform.circle")
                }
                .tag(Tabs.speechRecognition)
            WordMatcherView()
                .tabItem {
                    Label("WordMatcher", systemImage: "square.and.line.vertical.and.square")
                }
                .tag(Tabs.wordMatcher)
        }
    }
}

class WordState: ObservableObject {
    @Published var word : Word? = nil
    init(word : Word? = nil) {
        self.word = word
    }
}
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
