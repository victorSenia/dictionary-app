//
// ContentView.swift
// Shared
//
// Created by New on 23.06.2024.
//
import SwiftUI
import Foundation

enum NavigationLinkType: Hashable {
    case word, topic, rootTopic
}
struct ContentView: View {
    @StateObject var wordsState = WordListState()
    
    @StateObject var criteriaObject = criteriaHolder
    
    private enum Tabs: Hashable {
        case player, filter, settings, testing, speechRecognition, wordMatcher
    }
    var body: some View {
        TabView {
            PlayerView( wordsState: wordsState, player: player)
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
            DatabaseView(wordsState: wordsState)
                .tabItem {
                    Label("Database", systemImage: "star")
                }
                .tag(Tabs.testing)
            SpeechRecognitionView()
                .tabItem {
                    Label("SpeechRecognition", systemImage: "waveform.circle")
                }
                .tag(Tabs.speechRecognition)
            WordMatcherView()
                .tabItem {
                    Label("WordMatcher", systemImage: "square.and.line.vertical.and.square")
                }
                .tag(Tabs.speechRecognition)
        }
    }
}

struct DatabaseView: View {
    @ObservedObject var wordsState : WordListState
    
    @State private var action: NavigationLinkType?
    @State private var isActive = false
    @State var word: Word? = nil
    
    var body: some View {
        NavigationView {
            VStack {
                NavigationLink(destination: EditWordViewOrEmpty(word: word), tag: .word, selection: $action) {
                    EmptyView()
                }
                Menu {
                    Button("Open in Preview", action: newWord)
                    Button("Save as PDF", action: newWord)
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
                List{
                    Section (header: Text("Use words from resourse")){
                        ForEach (Bundle.main.urls(forResourcesWithExtension: "txt", subdirectory: nil)!.map({url in
                            url.relativePath}), id: \.self){ file in
                                Button(action: { fileWordProvider(file:file) }, label: {
                                    Label(file, systemImage: "doc.plaintext")
                                })
                                    .buttonStyle(.bordered)
                                    .controlSize(.large)
                            }
                    }
                    DeleteLanguageView(wordsState: wordsState)
                    Button(action: databaseWords, label: {
                        Label("use database", systemImage: "archivebox")
                    })
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                    Button(action: newWord, label: {
                        Label("create new word", systemImage: "plus")
                    })
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                }
                .listStyle(.plain)
            }
            .navigationBarHidden(true)
            .navigationBarBackButtonHidden(true)
        }
    }
    
    
    func newWord() {
        word = Word(word: "", language: "")
        action = .word
    }
    func databaseWords() {
        player.wordProvider = databaseWordProvider
    }
    func fileWordProvider(file: String){
        let wordProvider = FileWordProvider()
        wordProvider.fileName = file
        player.wordProvider = wordProvider
        player.findWords(criteria: criteriaHolder.criteria)
    }
}

struct DeleteLanguageView: View {
    @ObservedObject var wordsState : WordListState
    @State var isPresentingConfirmDelete: Bool = false
    @State var languageToDelete: String = ""
    @State var languageInDatabase: [String] = databaseWordProvider.languageFrom().sorted()
    @State var languagesCount = databaseWordProvider.languageFrom().count
    
    var body: some View {
        Button(action: importWords, label: {
            Label("import", systemImage: "tray.and.arrow.down")
        })
            .buttonStyle(.bordered)
            .controlSize(.large)
        Section (header: Text("delete words for language")){
            ForEach(0..<languagesCount, id: \.self){ index in
                let language = languageInDatabase[index]
                Button(action: {
                    isPresentingConfirmDelete = true
                    languageToDelete = language
                }, label: {
                    Label(language, systemImage: "trash.fill")
                })
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    
            }.confirmationDialog("Are you sure you want to delete all for language " + languageToDelete + "?", isPresented: $isPresentingConfirmDelete, titleVisibility: Visibility.visible) {
                Button("Delete all words for language " + languageToDelete, role: .destructive) {
                    DispatchQueue.global(qos: .userInitiated).async {
                        databaseWordProvider.deleteForLanguage(language: languageToDelete)
                        updateLangagesFromDB()
                    }
                }
            }
        }
    }
    func updateLangagesFromDB() {
        DispatchQueue.main.async {
            languageInDatabase = databaseWordProvider.languageFrom().sorted()
            languagesCount = languageInDatabase.count
        }
    }
    func importWords() {
        DispatchQueue.global(qos: .userInitiated).async {
            databaseWordProvider.importWords(words: wordsState.words)
            updateLangagesFromDB()
        }
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
    init(word : Word? = nil) {
        self.word = word
    }
}
class WordListState: ObservableObject {
    @Published var words : [Word] = []
}
struct PlayerView: View, UiUpdater {
    
    @State private var action: NavigationLinkType?
    @State private var isActive = false
    @State var word: Word? = nil
    @ObservedObject var wordState = WordState()
    @ObservedObject var wordsState: WordListState
    @ObservedObject var player : Player
    @ObservedObject var playState : PlayingState
    init( wordsState: WordListState, player: Player) {
        self.player = player
        self.wordsState = wordsState
        self.playState = player.playState
        player.uiUpdater = self
    }
    var body: some View {
        NavigationView {
            ScrollViewReader { proxy in
                NavigationLink(destination: EditWordViewOrEmpty(word: word), tag: .word, selection: $action) {
                    EmptyView()
                }
                HStack{
                    PlayerButton(action: previousWord, systemName: "backward.end.fill")
                    PlayerButton(action: startStop, systemName: player.playState.isStoped ? "play.fill": "stop.fill")
                    PlayerButton(action: nextWord, systemName: "forward.end.fill")
                }
                DetailsView(wordState: wordState)
                List(wordsState.words, id: \.listId) { word in
                    if #available(macOS 12.0, *) {
                        Text(word.toString())
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    databaseWordProvider.deleteWord(id: word.id!)
                                    player.findWords(criteria: criteriaHolder.criteria)
                                    NSLog("Deleting word")
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
                                    self.word = databaseWordProvider.findWord(id: word.id!)!
                                    self.action = .word
                                    NSLog("Editing word")
                                } label: {
                                    Label("Edit", systemImage: "square.and.pencil")
                                }
                                .tint(.green)
                            }
                    } else {HStack{
                        Text(word.toString())
                        HStack {
                            Button {
                                NSLog("Deleting word")
                            } label: {
                                Label("Delete", systemImage: "trash.fill")
                            }
                            Button {
                                playCurrent(word: word)
                            } label: {
                                Label("Play", systemImage: "play.circle")
                            }
                            Button {
                                self.word = databaseWordProvider.findWord(id: word.id!)
                                NSLog("Editing word")
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
            .navigationBarHidden(true)
            .navigationBarBackButtonHidden(true)
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
    func startStop(){
        player.startStopSpeaking()
    }
}
struct PlayerButton: View{
    private enum Constans {
        static let playButtonSide: CGFloat = 30
    }
    let systemName: String
    let action: () -> Void
    public init(action: @escaping () -> Void, systemName: String){
        self.action = action
        self.systemName = systemName
    }
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
    }
}
struct DetailsView: View {
    @ObservedObject var wordState = WordState()
    
    var body: some View {
        if let word = wordState.word {
            Text(word.word).font(.title)
            VStack {
                ForEach(word.translations) {
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
