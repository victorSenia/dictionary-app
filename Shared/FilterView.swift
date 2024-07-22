//
// FilterView.swift
// dictionary
//
// Created by New on 04.07.2024.
//

import SwiftUI

struct FilterView: View {
    @ObservedObject var criteriaObject: CriteriaHolder;
    @State var language: String?;
    @State var rootTopic: Topic?;
    @State var languagesFrom: [String] = [];
    @State var languagesTo: [String] = [];
    @State var languagesToSelected: String?;
    @State var topicsSelected: Topic?;
    @State var rootTopics: [Topic] = [];
    @State var topics: [Topic] = [];
    var player : Player
    
    var body: some View {
        VStack {
            Button(action: {
                player.findWords(criteria: criteriaObject.criteria)
            }, label: {
                Label("filter", systemImage: "magnifyingglass")
                Spacer()
            })
                .buttonStyle(.bordered)
                .controlSize(.regular)
            List {
                if languagesFrom.count > 1 {
                    StringsView(selection: $language, values: $languagesFrom, title: "Language from")
                }
                if rootTopics.count > 1 {
                    TopicsView(selection: $rootTopic, topics: $rootTopics, title: "Root topic")
                }
                if topics.count > 1 {
                    TopicsView(selection: $topicsSelected, topics: $topics, title: "Topics")
                }
                if languagesTo.count > 1 {
                    StringsView(selection: $languagesToSelected, values: $languagesTo, title: "Language to")
                }
            }
            .listStyle(.plain)
            .onAppear {
                languagesFrom = databaseManager.languageFrom()
                languagesTo = databaseManager.languageTo(language: language)
                rootTopics = databaseManager.findRootTopics(language: language)
                topics = databaseManager.getTopics(language: language, rootId: rootTopic != nil ? rootTopic!.id : nil, level: 2)
            }
            .onChange(of: language, perform: {_ in
                languagesTo = databaseManager.languageTo(language: language)
                rootTopics = databaseManager.findRootTopics(language: language)
                topics = databaseManager.getTopics(language: language, rootId: nil, level: 2)
                criteriaObject.criteria.languageFrom = language
            })
            .onChange(of: rootTopic, perform: {_ in
                topics = databaseManager.getTopics(language: language, rootId: rootTopic != nil ? rootTopic!.id : nil, level: 2)
                criteriaObject.criteria.rootTopic = rootTopic != nil ? rootTopic!.id : nil
            })
            .onChange(of: languagesToSelected, perform: {l in
                criteriaObject.criteria.languageTo = l != nil ? [l!] : nil
            })
            .onChange(of: topicsSelected, perform: {t in
                criteriaObject.criteria.topicsOr = t != nil ? [t!.id!] : []
            })
        }
    }
}
class CriteriaHolder: ObservableObject {
    @Published var criteria = WordCriteria()
}

struct TopicsView: View {
    @State var searchPart = "";
    
    @State var filteredTopics: [Topic] = []
    @Binding var selection: Topic?;
    
    @Binding var topics: [Topic]
    var title: LocalizedStringKey
    
    var body: some View {
        
        Section(header: Text(title)){
            Button(action: {
                selection = nil
                searchPart = ""
            }, label: {
                Text("All topics")
                Spacer()
            })
                .buttonStyle(.bordered)
                .controlSize(.regular)
            if !topics.isEmpty {
                SearchTopicsView(searchPart: $searchPart, selection: $selection, topics: $topics)
            }
        }
    }
}
let showFilterForRowsMoreThan = 5
struct SearchTopicsView: View {
    @Binding var searchPart: String;
    
    @State var filteredTopics: [Topic] = []
    @Binding var selection: Topic?;
    
    @Binding var topics: [Topic]
    
    var body: some View {
        if topics.count > showFilterForRowsMoreThan {
        TextField("Search", text: $searchPart)
            .textFieldStyle(.roundedBorder)
            .onChange(of: searchPart, perform: {searchPart in
                filteredTopics = searchPart.isEmpty ? topics : topics.filter({$0.name.localizedStandardContains(searchPart)})
            })
            .onAppear(perform: {
                filteredTopics = topics
            })
            .onChange(of: topics, perform: {topics in
                filteredTopics = topics
                selection = nil
                searchPart = ""
            })
        }
        ForEach(filteredTopics, id: \.name) {topic in
            Button(action: {
                selection = topic
            }, label: {
                Text(topic.name)
            })
                .listRowBackground(selection == topic ? selectedBackground() : nil)
        }
    }
}
func selectedBackground() -> some View {
    return (Rectangle().foregroundColor(.gray))
    //    return RoundedRectangle(cornerRadius: 8).foregroundColor(.gray).shadow(color: Color("Shadow"), radius: 8, x: 0, y: 4)
}
struct StringsView: View {
    
    @Binding var selection: String?;
    
    @Binding var values: [String]
    var title: LocalizedStringKey
    var body: some View {
        Section(header: Text(title)){
            ForEach(values, id: \.self) {value in
                Button(action: {
                    selection = value
                }, label: {
                    Text(value)
                })
                    .listRowBackground(selection == value ? selectedBackground() : nil)
            }
            .onChange(of: values, perform: {_ in
                selection = nil
            })
        }
    }
}
