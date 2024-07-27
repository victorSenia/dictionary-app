//
//  PlayerView.swift
//  dictionary
//
//  Created by New on 27.07.2024.
//

import SwiftUI
import Foundation


enum NavigationLinkType: Hashable {
    case word, topic, rootTopic, settings
}
struct PlayerView: View, UiUpdater {
    
    @State var action: NavigationLinkType?
    @State var wordToEdit: Word? = nil
    @ObservedObject var wordState = WordState()
    @ObservedObject var _player = player
    @ObservedObject var playState : PlayingState
    init(player : Player) {
        _player = player
        playState = player.playState
        player.uiUpdater = self
    }
    var body: some View {
        NavigationView {
            ScrollViewReader { proxy in
                NavigationLink(destination: EditWordViewOrEmpty(word: wordToEdit), tag: .word, selection: $action) {
                    EmptyView()
                }
                NavigationLink(destination: SettingsView().navigationBarTitle("Setting", displayMode: .inline), tag: .settings, selection: $action) {
                    EmptyView()
                }
                ZStack(alignment: .trailing) {
                    HStack{
                        Spacer()
                        PlayerButton(action: previousWord, systemName: "backward.end.fill")
                        PlayerButton(action: startStop, systemName: playState.isStoped ? "play.fill": "stop.fill")
                        PlayerButton(action: nextWord, systemName: "forward.end.fill")
                        Spacer()
                    }
                    Button {
                        action = .settings
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }.padding()
                }
                if wordState.word != nil {
                    DetailsView(word: wordState.word)
                }
                WordsListView(proxy : proxy, action: $action, wordToEdit: $wordToEdit, _player: _player, wordState: wordState)
            }
            .navigationBarHidden(true)
        }
    }
    
    func previousWord(){
        _player.previousWord()
    }
    func nextWord(){
        _player.nextWord()
    }
    func updateCurrentWordState(index:Int, word:Word){
        wordState.word = word
    }
    func startStop(){
        _player.startStopSpeaking()
    }
}
struct WordsListView: View{
    var proxy : ScrollViewProxy
    @Binding var action: NavigationLinkType?
    @Binding var wordToEdit: Word?
    @ObservedObject var _player : Player
    @ObservedObject var wordState : WordState
    var body: some View {
        List(_player.words, id: \.listId) { word in
            if #available(macOS 12.0, *) {
                Text(word.toString())
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        if word.id != nil {
                            Button(role: .destructive) {
                                deleteWord(id: word.id!)
                            } label: {
                                Label("Delete", systemImage: "trash.fill")
                            }
                        }
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                        Button {
                            playCurrent(word: word)
                        } label: {
                            Label("Play", systemImage: "play.circle")
                        }
                        .tint(.blue)
                        if word.id != nil {
                            Button {
                                editWord(id: word.id!)
                            } label: {
                                Label("Edit", systemImage: "square.and.pencil")
                            }
                            .tint(.green)
                        }
                    }
            } else {
                HStack {
                    Text(word.toString())
                    HStack {
                        if word.id != nil {
                            Button {
                                deleteWord(id: word.id!)
                            } label: {
                                Label("Delete", systemImage: "trash.fill")
                            }
                        }
                        Button {
                            playCurrent(word: word)
                        } label: {
                            Label("Play", systemImage: "play.circle")
                        }
                        if word.id != nil {
                            Button {
                                editWord(id: word.id!)
                            } label: {
                                Label("Edit", systemImage: "square.and.pencil")
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .onChange(of: wordState.word ) { target in
            if let target = target {
                withAnimation {
                    proxy.scrollTo(target.listId, anchor: .center)
                }
            }
        }
    }
    func editWord(id: Int64) {
        self.wordToEdit = databaseWordProvider.findWord(id: id)!
        self.action = .word
    }
    
    func deleteWord(id: Int64) {
        databaseWordProvider.deleteWord(id: id)
        _player.findWords(criteria: criteriaHolder.criteria)
    }
    func playCurrent(word: Word){
        if let index = _player.words.firstIndex(of: word) {
            _player.playFromIndex(index: index)
        }
    }
}
struct PlayerButton: View{
    private enum Constans {
        static let playButtonSide: CGFloat = 30
    }
    let action: () -> Void
    let systemName: String
    var body: some View {
        Button(action: action, label: {
            Image(systemName: systemName)
                .resizable()
                .frame(width: Constans.playButtonSide,
                       height: Constans.playButtonSide,
                       alignment: .center)
                .aspectRatio(contentMode: .fit)
        })
            .buttonStyle(.bordered)
            .controlSize(.large)
            .clipShape(Capsule())
    }
}
struct DetailsView: View {
    var word: Word?
    
    var body: some View {
        if word != nil {
            Text(word!.word).font(.title)
            VStack {
                ForEach(word!.translations) {
                    Text($0.translation)
                }
            }
        }
    }
}
