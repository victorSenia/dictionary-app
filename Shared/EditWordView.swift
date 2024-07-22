//
//  WordView.swift
//  dictionary
//
//  Created by New on 05.07.2024.
//

import Foundation
import SwiftUI


struct EditWordView: View {
    @ObservedObject var wordToEdit: WordState
    @StateObject var topicState = TopicState()
    @State var word: Word
    @State var language: String
    init(wordToEdit: WordState){
        self.wordToEdit = wordToEdit
        word = wordToEdit.word!
        language = wordToEdit.word!.language
    }
    
    var body: some View {
        if topicState.topic != nil {
            EditTopicView(topicToEdit: topicState, topic: topicState.topic!)
        } else {
            HStack {
                Button {
                    wordToEdit.word = nil
                } label: {
                    Label("Back", systemImage: "chevron.left")
                }.buttonStyle(.bordered)
                Spacer()
                
                Button {
                    wordToEdit.word = nil
                    databaseManager.updateWord(word: word)
                } label: {
                    Label("Save", systemImage: "checkmark.circle")
                }.buttonStyle(.bordered)
            }
            List {
                Section(header: Text("Word")) {
                    HStack {
                        TextField("language", text: $language)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 40, height: nil, alignment: .leading)
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
                EditTopicsView(topicToEdit: topicState, topics: $word.topics, language: $language, topicsCount: $word.topics.count)
            }
            .listStyle(.plain)
            .onChange(of: language, perform: {language in
                word.language = language
            })
        }
    }
}

struct EditTranslationView: View {
    @Binding var translation: Translation;
    
    var body: some View {
        HStack {
            TextField("Language", text: $translation.language)
                .textFieldStyle(.roundedBorder)
                .frame(width: 40, height: nil, alignment: .leading)
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

struct EditTopicsView: View {
    @ObservedObject var topicToEdit: TopicState
    @Binding var topics: [Topic]
    @Binding var language: String
    @State var topicsCount: Int
    @State var searchPart = ""
    
    @State var topicsForLanguage: [Topic] = [];
    
    @State var topicsSelected: Topic?;
    var body: some View {
        Section(header: Text("Topics")) {
            ForEach(0..<topicsCount, id: \.self) {index in
                if #available(macOS 12.0, *) {
                    Text(topics[index].name)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                topics.remove(at: index)
                                topicsCount -= 1
                                print("Deleting topic")
                            } label: {
                                Label("Delete", systemImage: "trash.fill")
                            }
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button {
//                                topicToEdit.topic = topics[index]
                                print("Editing topic")
                            } label: {
                                Label("Edit", systemImage: "square.and.pencil")
                            }
                            .tint(.green)
                        }
                } else {
                    Text(topics[index].name)
                    Button {
                        topics.remove(at: index)
                        topicsCount -= 1
                        print("Deleting topic")
                    } label: {
                        Label("Delete", systemImage: "trash.fill")
                    }
                    Button {
//                        topicToEdit.topic = topics[index]
                        print("Editing topic")
                    } label: {
                        Label("Edit", systemImage: "square.and.pencil")
                    }
                }
            }
            if !topicsForLanguage.isEmpty {
                SearchTopicsView(searchPart: $searchPart, selection: $topicsSelected, topics: $topicsForLanguage)
            }
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
        .onChange(of: topicsSelected, perform: {topic in
            if topic != nil {
                topics.append(topic!)
                topicsCount += 1
                topicsSelected = nil
            }
        })
    }
    func getTopicsForLanguage() -> [Topic] {
        return databaseWordProvider._databaseManager.getTopics(language: language, rootId: nil, level: 2).filter({t in
            !topics.contains(t)
        })
    }
}

class TopicState: ObservableObject {
    @Published var topic : Topic? = nil
}
struct EditTopicView: View {
    @ObservedObject var topicToEdit: TopicState
    @StateObject var topicState = TopicState()
    @State var topic: Topic
    
    @State var topicsForLanguage: [Topic] = [];
    
    @State var topicSelected: Topic?;
    @State var searchPart: String = "";
    var body: some View {
        if topicState.topic != nil {
            EditTopicView(topicToEdit: topicState, topic: topicState.topic!)
        }
        else{
            HStack {
                Button {
                    topicToEdit.topic = nil
                } label: {
                    Label("Back", systemImage: "chevron.left")
                }.buttonStyle(.bordered)
                Spacer()
                
                Button {
                    topicToEdit.topic = nil
                } label: {
                    Label("Save", systemImage: "checkmark.circle")
                }.buttonStyle(.bordered)
            }
            List {
                TextField("name", text: $topic.name)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                if topic.level > 1 {
                    Section(header: Text("Topics")) {
                        if let rootTopic = topic.root {
                            if #available(macOS 12.0, *) {
                                Text(rootTopic.name)
                                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                        Button {
                                            topicState.topic = rootTopic
                                            print("Editing topic")
                                        } label: {
                                            Label("Edit", systemImage: "square.and.pencil")
                                        }
                                        .tint(.green)
                                    }
                            } else {
                                Text(rootTopic.name)
                                Button {
                                    topicState.topic = rootTopic
                                    print("Editing topic")
                                } label: {
                                    Label("Edit", systemImage: "square.and.pencil")
                                }
                            }
                        }
                        if !topicsForLanguage.isEmpty {
                            SearchTopicsView(searchPart: $searchPart, selection: $topicSelected, topics: $topicsForLanguage)
                        }
                    }
                    .onAppear {
                        topicsForLanguage = getRootTopicsForLanguage()
                    }
                    .onChange(of: topicSelected, perform: {t in
                        if t != nil {
                            topic.root = t
                            topicSelected = nil
                            topicsForLanguage = getRootTopicsForLanguage()
                        }
                    })
                }
            }.listStyle(.plain)
        }
    }
    func getRootTopicsForLanguage() -> [Topic] {
        return databaseWordProvider._databaseManager.getTopics(language: topic.language, rootId: nil, level: 1).filter({t in
            topic.root != t
        })
    }
}
