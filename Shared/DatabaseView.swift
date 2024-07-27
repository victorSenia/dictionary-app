//
//  DatabaseView.swift
//  dictionary
//
//  Created by New on 27.07.2024.
//

import SwiftUI
import Foundation

struct DatabaseView: View {
    
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
                    LoadResourcesView()
                    DeleteLanguageView()
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
        }
    }
    
    
    func newWord() {
        word = Word(word: "", language: "")
        action = .word
    }
    func databaseWords() {
        player.wordProvider = databaseWordProvider
    }
}

struct LoadResourcesView: View {
    @State var isPresentingAlert: Bool = false
    @State var fileName: String = ""
    
    var body: some View {
        Section (header: Text("Use words from resourse")){
            ForEach (Bundle.main.urls(forResourcesWithExtension: "txt", subdirectory: nil)!.map({url in
                url.relativePath}), id: \.self){ file in
                    Button(action: { fileWordProvider(file:file) }, label: {
                        Label(file, systemImage: "doc.plaintext")
                    })
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                }
                .alert("Words were parsed from file " + fileName, isPresented: $isPresentingAlert) {}
        }
    }
    func fileWordProvider(file: String){
        criteriaHolder.criteria.languageTo = nil
        fileName = file
        let wordProvider = FileWordProvider()
        wordProvider.fileName = file
        player.wordProvider = wordProvider
        DispatchQueue.global(qos: .userInitiated).async {
            wordProvider.parseWords()
            DispatchQueue.main.async {
                isPresentingAlert = true
            }
        }
    }
}

struct DeleteLanguageView: View {
    @State var isPresentingConfirmDelete: Bool = false
    @State var isPresentingAlert: Bool = false
    @State var languageToDelete: String = ""
    @State var languageInDatabase: [String] = databaseWordProvider.languageFrom().sorted()
    @State var languagesCount = databaseWordProvider.languageFrom().count
    
    var body: some View {
        Button(action: importWords, label: {
            Label("import", systemImage: "tray.and.arrow.down")
        })
            .buttonStyle(.bordered)
            .controlSize(.large)
            .alert("Import finished", isPresented: $isPresentingAlert) {}
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
            player.findWords(criteria: criteriaHolder.criteria)
            databaseWordProvider.importWords(words: player.words)
            updateLangagesFromDB()
            DispatchQueue.main.async {
                isPresentingAlert = true
            }
        }
    }
}
