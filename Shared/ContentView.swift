//
// ContentView.swift
// Shared
//
// Created by New on 23.06.2024.
//
import SwiftUI
import Foundation

struct ContentView: View {
    @StateObject var wordState = WordState()
    @StateObject var wordToEditState = WordState()
    @StateObject var wordsState = WordListState()
    
    @StateObject var criteriaObject = criteriaHolder
    
    
    private enum Tabs: Hashable {
        case player, filter, settings, testing
    }
    var body: some View {
        if wordToEditState.word != nil {
            EditWordView(wordToEdit: wordToEditState)
        } else {
            TabView {
                PlayerView(wordState: wordState, wordsState: wordsState, player: player, wordToEditState: wordToEditState)
                    .onAppear {
                        player.findWords(criteria: criteriaObject.criteria)
                    }
                    .tabItem {
                        Label("Player", systemImage: "play.circle")
                    }
                    .tag(Tabs.player)
                FilterView(criteriaObject: criteriaObject, player: player)
                    .tabItem {
                        Label("Filter", systemImage: "magnifyingglass.circle")
                    }
                    .tag(Tabs.filter)
                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
                    .tag(Tabs.settings)
                DatabaseView(wordsState: wordsState, wordToEditState: wordToEditState)
                .tabItem {
                    Label("Database", systemImage: "star")
                }
                .tag(Tabs.testing)
            }
        }
        
    }
    
}

struct DatabaseView: View {
    @ObservedObject var wordsState : WordListState
    @ObservedObject var wordToEditState : WordState
    
    var body: some View {
        VStack {
            Menu {
                Button("Open in Preview", action: importWords)
                Button("Save as PDF", action: importWords)
            } label: {
                //                    Circle()
                //                        .fill(.gray.opacity(0.15))
                //                        .frame(width: 30, height: 30)
                //                        .overlay {
                Image(systemName: "ellipsis")
                    .font(.system(size: 13.0, weight: .semibold))
                    .foregroundColor(.pink)
                    .padding()
                //                        }
            }
            VStack{
                Button(action: importWords, label: {
                    Label("import", systemImage: "tray.and.arrow.down")
                })
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                Button(action: fileWords, label: {
                    Label("file", systemImage: "doc.plaintext")
                })
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                Button(action: databaseWords, label: {
                    Label("database", systemImage: "archivebox")
                })
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                Button(action: newWord, label: {
                    Label("new Word", systemImage: "plus")
                })
                    .buttonStyle(.bordered)
                    .controlSize(.large)
            }
        }
    }
    
    func importWords() {
        DispatchQueue.global(qos: .userInitiated).async {
            databaseWordProvider.importWords(words: wordsState.words)
        }
        
    }
    func newWord() {
        wordToEditState.word = Word(word: "", language: "")
    }
    func databaseWords() {
        player.wordProvider = databaseWordProvider
        //        DispatchQueue.main.async {
        // wordsState.words = wordsState.words
        // self.showToast(message: "Your Toast Message", font: .systemFont(ofSize: 12.0))
        //            print("This is run on the main queue, after the previous code in outer block")
        //        }
    }
    func fileWords()
    {
        let wordProvider = FileWordProvider()
        player.wordProvider = wordProvider
    }
}

class StateObjectHolder<T>: ObservableObject {
    @Published var value : T
    init(value: T) {
        self.value = value
    }
}
class WordState: ObservableObject {
    @Published var word : Word? = nil
}
class WordListState: ObservableObject {
    @Published var words : [Word] = []
}
struct PlayerView: View, UiUpdater {
    @ObservedObject var wordState: WordState
    @ObservedObject var wordToEditState: WordState
    @ObservedObject var wordsState: WordListState
    var player : Player
    init(wordState: WordState, wordsState: WordListState, player: Player, wordToEditState: WordState) {
        self.player = player
        self.wordState = wordState
        self.wordsState = wordsState
        self.wordToEditState = wordToEditState
        player.uiUpdater = self
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            HStack{
                Button(action: previousWord, label: {
                    Label("", systemImage: "backward.end.fill")
                })
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                Button(action: startSpeaking, label: {
                    Label("", systemImage: "playpause.fill")
                })
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                Button(action: nextWord, label: {
                    Label("", systemImage: "forward.end.fill")
                })
                    .buttonStyle(.bordered)
                    .controlSize(.large)
            }
            DetailsView(wordState: wordState)
            List(wordsState.words, id:\.word) { (word) in
                if #available(macOS 12.0, *) {
                    Text(word.toString())
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                print("Deleting conversation")
                            } label: {
                                Label("Delete", systemImage: "trash.fill")
                            }
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button {
                                playCurrent(word: word)
                            } label: {
                                Label("Play", systemImage: "play.circle")
                            }
                            .tint(.blue)
                            Button {
                                wordToEditState.word = databaseWordProvider._databaseManager.findWord(id: word.id!)
                                print("Editing word")
                            } label: {
                                Label("Edit", systemImage: "square.and.pencil")
                            }
                            .tint(.green)
                        }
                } else {HStack{
                    Text(word.toString())
                    HStack {
                    Button {
                        print("Deleting conversation")
                    } label: {
                        Label("Delete", systemImage: "trash.fill")
                    }
                    Button {
                        playCurrent(word: word)
                    } label: {
                        Label("Play", systemImage: "play.circle")
                    }
                    Button {
                        wordToEditState.word = databaseWordProvider._databaseManager.findWord(id: word.id!)
                        print("Editing word")
                    } label: {
                        Label("Edit", systemImage: "square.and.pencil")
                    }
                    }
                }
                }
            }
            .listStyle(.plain)
            .onChange(of: wordState.word ) { target in
                if let target = target {
                    withAnimation {
                        proxy.scrollTo(target.id, anchor: .center)
                    }
                }
            }
        }
    }
    
    func previousWord(){
        player.previousWord()
    }
    func nextWord(){
        player.nextWord()
    }
    func playCurrent(word: Word){
        if let index = wordsState.words.firstIndex(of: word) {
            player.playFromIndex(index: index)
        }
    }
    func updateWordListState(wordList: [Word]){
        DispatchQueue.main.async{
            wordsState.words = wordList
        }
    }
    func updateCurrentWordState(index:Int, word:Word){
        wordState.word = word
    }
    func startSpeaking(){
        player.startStopSpeaking()
    }
}
struct DetailsView: View {
    @ObservedObject var wordState: WordState
    
    var body: some View {
        if wordState.word != nil {
            Text(wordState.word!.word)
            VStack {
                ForEach(wordState.word!.translations) {
                    Text($0.translation)
                }
            }
        }
    }
}
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
