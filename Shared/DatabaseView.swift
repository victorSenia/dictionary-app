//
//  DatabaseView.swift
//  dictionary
//
//  Created by New on 27.07.2024.
//

import SwiftUI
import Foundation

import UIKit
import UniformTypeIdentifiers

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
                    Section (header: Text("Other functions")){
                        Button(action: databaseWords, label: {
                            Label("use database", systemImage: "archivebox")
                        })
                            .controlSize(.large)
                        Button(action: newWord, label: {
                            Label("create new word", systemImage: "plus")
                        })
                            .controlSize(.large)
                    }
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
    @State var showingImportFilePicker = false
    @State var showingExportFilePicker = false
    @State var isPresentingConfirmDelete: Bool = false
    @State var isPresentingAlert: Bool = false
    @State var languageToDelete: String = ""
    @State var languageToExport: String = ""
    @State var languageInDatabase: [String] = databaseWordProvider.languageFrom().sorted()
    @State var languagesCount = databaseWordProvider.languageFrom().count
    
    var body: some View {
        Button(action: importWords, label: {
            Label("Import current words", systemImage: "tray.and.arrow.down")
        })
            .controlSize(.large)
            .alert("Import finished", isPresented: $isPresentingAlert) {}
        Section (header: Text("delete words for language")){
            ForEach(0..<languagesCount, id: \.self){ index in
                let language = languageInDatabase[index]
                Button(action: {
                    languageToDelete = language
                    isPresentingConfirmDelete = true
                }, label: {
                    Label(language, systemImage: "trash.fill")
                })
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
        Section (header: Text("export words for language")){
            ForEach(0..<languagesCount, id: \.self){ index in
                let language = languageInDatabase[index]
                Button(action: {
                    showingExportFilePicker = true
                    languageToExport = language
                    //TODO choose rootTopic and file name
                }, label: {
                    Label(language, systemImage: "tray.and.arrow.up.fill")
                })
                    .controlSize(.large)
            }
        }
        .sheet(isPresented: $showingExportFilePicker) {
            FilePickerView(types: [UTType.folder], action: {url in
                exportWordsFromDb(url: url, language: languageToExport, rootTopic: nil)
            }, urlModifier: {url in
                return url.appendingPathComponent("export_" + languageToExport + ".txt")
            })
        }
        Section (header: Text("import words from file to database")){
            Button(action: {
                showingImportFilePicker = true
            }, label: {
                Label("import Words", systemImage: "tray.and.arrow.down.fill")
            })
                .controlSize(.large)
                .sheet(isPresented: $showingImportFilePicker) {
                    FilePickerView(types: UTType.types(tag: "txt", tagClass: UTTagClass.filenameExtension, conformingTo: nil), action: {url in
                        importWordsToDb(url: url)
                    }, urlModifier: nil)
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
            isPresentingAlert = true
        }
    }
    func importWordsToDb(url: URL) {
        let importer = WordImporter()
        importer.url = url
        let words = importer.readWords()
        databaseWordProvider.importWords(words: words)
        updateLangagesFromDB()
        isPresentingAlert = true
    }
    func exportWordsFromDb(url: URL, language: String, rootTopic: Topic?) {
        let exporter = WordExporter()
        exporter.url = url
        if (rootTopic != nil) {
            exporter.writeWords(list: databaseWordProvider.getWordsForLanguage(language: language, rootTopic: rootTopic!.id), allForLanguage: false, rootTopicNames: [rootTopic!.name])
        } else {
            exporter.writeWords(list: databaseWordProvider.getWordsForLanguage(language: language, rootTopic: nil), allForLanguage: true, rootTopicNames: databaseWordProvider.findRootTopics(language: language).map({t in t.name}))
        }
    }
}

class FilePickerViewController: UIDocumentPickerViewController, UIDocumentPickerDelegate, UINavigationControllerDelegate {
    var action: ((_ url: URL) -> Void)? = nil
    var urlModifier: ((_ url: URL) -> URL)? = nil
    
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard var url = urls.first else {
            return
        }
        if urlModifier != nil {
            url = urlModifier!(url)
        }
        guard url.startAccessingSecurityScopedResource() else {
            return
        }
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        if action != nil {
            action!(url)
        }
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        dismiss(animated: false, completion: nil)
    }
}
struct FilePickerView: UIViewControllerRepresentable {
    let types : [UTType]
    let action: ((_ url: URL) -> Void)?
    let urlModifier: ((_ url: URL) -> URL)?
    
    func makeUIViewController(context: Context) -> FilePickerViewController {
        let documentPicker: FilePickerViewController = FilePickerViewController(forOpeningContentTypes: types)
        documentPicker.delegate = documentPicker
        documentPicker.action = action
        documentPicker.urlModifier = urlModifier
        documentPicker.allowsMultipleSelection = false
        return documentPicker
    }
    
    func updateUIViewController(_ uiViewController: FilePickerViewController, context: Context) {
    }
}
