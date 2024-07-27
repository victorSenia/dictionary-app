//
//  WordView.swift
//  dictionary
//
//  Created by New on 05.07.2024.
//

import Foundation
import SwiftUI

struct EditWordViewOrEmpty: View {
    @State var word: Word?
    var body: some View {
        if word != nil {
            EditWordView(word: word!, language: word!.language)
        }
        else {
            EmptyView()
        }
    }
}
struct EditWordView: View {
    
    @Environment(\.presentationMode) var presentationMode
    @State var word: Word
    @State var language: String
    
    @State var topicToEdit: Topic?
    @State private var action: NavigationLinkType?
    var body: some View {
        NavigationLink(destination: EditTopicViewOrEmpty(topicToEdit: $topicToEdit), tag: .topic, selection: $action) {
            EmptyView()
        }
        List {
            Section(header: Text("Word")) {
                HStack {
                    TextField("language", text: $language)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 40, alignment: .leading)
                        .autocapitalization(.none)
                    VStack{
                        TextField("article", text: $word.article)
                            .textFieldStyle(.roundedBorder)
                            .autocapitalization(.none)
                        TextField("word", text: $word.word)
                            .textFieldStyle(.roundedBorder)
                            .autocapitalization(.none)
                        TextField("additionalInformation", text: $word.additionalInformation)
                            .textFieldStyle(.roundedBorder)
                            .autocapitalization(.none)
                    }
                }
            }
            EditTranslationsView(translations: $word.translations, translationsCount: $word.translations.count)
            EditTopicsView(topics: $word.topics, language: $language, topicsCount: $word.topics.count, topicToEdit: $topicToEdit, action: $action)
        }
        .listStyle(.plain)
        .onChange(of: language, perform: {language in
            word.language = language
        })
        .navigationBarTitle("Word", displayMode: .inline)
        .navigationBarItems(trailing: Button {
            databaseWordProvider.updateWordFully(updatedWord: word)
            player.findWords(criteria: criteriaHolder.criteria)
            presentationMode.wrappedValue.dismiss()
        } label: {
            Label("Save", systemImage: "checkmark.circle")
        })
    }
}

struct EditTranslationView: View {
    @Binding var translation: Translation;
    
    var body: some View {
        HStack {
            TextField("Language", text: $translation.language)
                .textFieldStyle(.roundedBorder)
                .frame(width: 40, alignment: .leading)
                .autocapitalization(.none)
            TextField("Translation", text: $translation.translation)
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.none)
        }
    }
}
struct EditTranslationsView: View {
    @Binding var translations: [Translation]
    @State var translationsCount: Int
    
    var body: some View {
        Section(header: Text("Translations")) {
            ForEach(0..<translationsCount, id: \.self) {index in
                HStack {
                    EditTranslationView(translation: $translations[index])
                    Button {
                        translations.remove(at: index)
                        translationsCount -= 1
                    } label: {
                        Label("", systemImage: "trash.fill")
                    }
                    .buttonStyle(.bordered)
                }
            }
            Button {
                translations.append(Translation(translation: "", language: ""))
                translationsCount += 1
            } label: {
                Label("Add translation", systemImage: "plus")
            }
            
        }
    }
}


struct EditTopicViewOrEmpty: View {
    @State var topicToEdit: Binding<Topic?>
    
    var body: some View {
        if topicToEdit.wrappedValue != nil {
            EditTopicView(topic: topicToEdit.wrappedValue!, rootTopic: topicToEdit.wrappedValue!.root)
        }
        else {
            EmptyView()
        }
    }
}
struct EditTopicsView: View {
    @Binding var topics: [Topic]
    @Binding var language: String
    @State var topicsCount: Int
    @State var searchPart = ""
    @State var topicsForLanguage: [Topic] = [];
    
    @State var topicSelected: Topic?
    var topicToEdit: Binding<Topic?>
    var action: Binding<NavigationLinkType?>
    func editTopic(index: Int) {
        topicToEdit.wrappedValue = topics[index]
        action.wrappedValue = .topic
    }
    
    func deleteTopic(index: Int) {
        topics.remove(at: index)
        topicsCount -= 1
    }
    
    var body: some View {
        Section(header: Text("Topics")) {
            ForEach(0..<topicsCount, id: \.self) {index in
                if #available(macOS 12.0, *) {
                    Text(topics[index].name)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                deleteTopic(index: index)
                            } label: {
                                Label("Delete", systemImage: "trash.fill")
                            }
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button {
                                editTopic(index: index)
                            } label: {
                                Label("Edit", systemImage: "square.and.pencil")
                            }
                            .tint(.green)
                        }
                } else {
                    Text(topics[index].name)
                    Button {
                        deleteTopic(index: index)
                    } label: {
                        Label("Delete", systemImage: "trash.fill")
                    }
                    Button {
                        editTopic(index: index)
                    } label: {
                        Label("Edit", systemImage: "square.and.pencil")
                    }
                }
            }
            SearchTopicsView(searchPart: $searchPart, filteredTopics: topicsForLanguage, selection: $topicSelected, topics: $topicsForLanguage, createAction: {
                topicToEdit.wrappedValue = Topic(name: searchPart, language: language, level: 2)
                action.wrappedValue = .topic
            })
        }
        .onAppear {
            topicsForLanguage = getTopicsForLanguage()
        }
        .onChange(of: language, perform: {_ in
            topicsCount = 0
            topics.removeAll()
            topicsForLanguage = getTopicsForLanguage()
        })
        .onChange(of: topics, perform: {_ in
            topicsForLanguage = getTopicsForLanguage()
        })
        .onChange(of: topicSelected, perform: {topic in
            if topic != nil {
                topics.append(topic!)
                topicsCount += 1
                topicSelected = nil
            }
        })
    }
    func getTopicsForLanguage() -> [Topic] {
        return databaseWordProvider.findTopics(language: language, level: 2).filter({t in
            !topics.contains(t)
        })
    }
}

struct EditTopicView: View {
    @Environment(\.presentationMode) var presentationMode
    @State var topic: Topic
    @State var rootTopic: Topic?
    
    @State var topicsForLanguage: [Topic] = [];
    
    @State var topicSelected: Topic?;
    @State var searchPart: String = "";
    @State var topicToEdit: Topic?
    @State var action: NavigationLinkType?
    func editRootTopic() {
        topicToEdit = rootTopic!
        action = .rootTopic
    }
    
    var body: some View {
        NavigationLink(destination: EditTopicViewOrEmpty(topicToEdit: $topicToEdit), tag: .rootTopic, selection: $action) {
            EmptyView()
        }
        List {
            TextField("name", text: $topic.name)
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.none)
                .onAppear {
                    topicsForLanguage = getRootTopicsForLanguage()
                }
                .onChange(of: topicSelected, perform: {t in
                    if t != nil {
                        rootTopic = t
                        topicSelected = nil
                    }
                })
                .onChange(of: rootTopic, perform: {t in
                    topic.root = t
                    topicsForLanguage = getRootTopicsForLanguage()
                })
            if topic.level > 1 {
                if rootTopic != nil {
                    if #available(macOS 12.0, *) {
                        Text(rootTopic!.name)
                            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                Button {
                                    editRootTopic()
                                } label: {
                                    Label("Edit", systemImage: "square.and.pencil")
                                }
                                .tint(.green)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button (role: .destructive){
                                    rootTopic = nil
                                } label: {
                                    Label("Delete", systemImage: "trash.fill")
                                }
                            }
                    } else {
                        Text(rootTopic!.name)
                        Button {
                            editRootTopic()
                        } label: {
                            Label("Edit", systemImage: "square.and.pencil")
                        }
                        Button {
                            rootTopic = nil
                        } label: {
                            Label("Delete", systemImage: "trash.fill")
                        }
                    }
                }
                Section (header: Text("Root topics")){
                    SearchTopicsView(searchPart: $searchPart, filteredTopics: topicsForLanguage, selection: $topicSelected, topics: $topicsForLanguage, createAction: {
                        topicToEdit = Topic(name: searchPart, language: topic.language, level: 1)
                        action = .rootTopic
                    })
                }
            }
        }.listStyle(.plain)
            .navigationBarTitle(topic.level > 1 ? "Topic" : "Root topic", displayMode: .inline)
            .navigationBarItems(trailing: Button {
                databaseWordProvider.updateTopic(topic: &topic)
                presentationMode.wrappedValue.dismiss()
            } label: {
                Label("Save", systemImage: "checkmark.circle")
            })
    }
    func getRootTopicsForLanguage() -> [Topic] {
        return databaseWordProvider.findRootTopics(language: topic.language).filter({t in
            rootTopic != t
        })
    }
}
