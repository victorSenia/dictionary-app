//
// FilterView.swift
// dictionary
//
// Created by New on 04.07.2024.
//

import SwiftUI

struct FilterView: View {
    @ObservedObject var _criteriaHolder = criteriaHolder;
    @State var language: String? = criteriaHolder.criteria.languageFrom
    @State var rootTopic: Int64? = criteriaHolder.criteria.rootTopic
    @State var languagesToSelected: String? = criteriaHolder.criteria.languageTo != nil && !criteriaHolder.criteria.languageTo!.isEmpty ? criteriaHolder.criteria.languageTo![0] : nil
    @State var topicsSelected: Int64? = criteriaHolder.criteria.topicsOr != nil && !criteriaHolder.criteria.topicsOr!.isEmpty ? criteriaHolder.criteria.topicsOr![0] : nil
    @State var languagesFrom: [String] = [];
    @State var languagesTo: [String] = [];
    @State var rootTopics: [Topic] = [];
    @State var topics: [Topic] = [];
    
    var body: some View {
        VStack{
            Text("")
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
                languagesFrom = player.wordProvider.languageFrom()
                languagesTo = player.wordProvider.languageTo(language: language)
                rootTopics = player.wordProvider.findRootTopics(language: language)
                topics = player.wordProvider.findTopicsWithRoot(language: language, rootId: rootTopic, level: 2)
            }
            .onChange(of: language, perform: {_ in
                languagesTo = player.wordProvider.languageTo(language: language)
                rootTopics = player.wordProvider.findRootTopics(language: language)
                topics = player.wordProvider.findTopics(language: language, level: 2)
                _criteriaHolder.criteria.languageFrom = language
                settings.currentCriteria = _criteriaHolder.criteria
            })
            .onChange(of: rootTopic, perform: {_ in
                topics = player.wordProvider.findTopicsWithRoot(language: language, rootId: rootTopic, level: 2)
                _criteriaHolder.criteria.rootTopic = rootTopic
                settings.currentCriteria = _criteriaHolder.criteria
            })
            .onChange(of: languagesToSelected, perform: {l in
                _criteriaHolder.criteria.languageTo = l != nil ? [l!] : nil
                settings.currentCriteria = _criteriaHolder.criteria
            })
            .onChange(of: topicsSelected, perform: {t in
                _criteriaHolder.criteria.topicsOr = t != nil ? [t!] : []
                settings.currentCriteria = _criteriaHolder.criteria
            })
        }
    }
}
class CriteriaHolder: ObservableObject {
    @Published var criteria = settings.currentCriteria
}

struct TopicsView: View {
    @State var searchPart = "";
    
    @State var filteredTopics: [Topic] = []
    @Binding var selection: Int64?;
    @State var selectedTopic: Topic?
    
    @Binding var topics: [Topic]
    var title: LocalizedStringKey
    
    var body: some View {
        Section(header: Text(title)){
            Button(action: {
                selectedTopic = nil
                searchPart = ""
            }, label: {
                Text("All topics")
                Spacer()
            })
                .buttonStyle(.bordered)
                .controlSize(.regular)
            if !topics.isEmpty {
                SearchTopicsView(searchPart: $searchPart, filteredTopics: topics, selection: $selectedTopic, topics: $topics)
                    .onChange(of: selectedTopic, perform: {t in
                        selection = t != nil ? t!.id : nil
                    })
            }
        }
        .onAppear(perform: {
            if selection != nil {
                selectedTopic = topics.first(where: {t in t.id == selection})
                if selectedTopic == nil {
                    selection = nil
                }
            }
        })
    }
}
let showFilterForRowsMoreThan = 5
struct SearchTopicsView: View {
    @Binding var searchPart: String;
    
    @State var filteredTopics: [Topic]
    @Binding var selection: Topic?
    
    @Binding var topics: [Topic]
    var createAction: (() -> Void)?
    
    var body: some View {
        if topics.count > showFilterForRowsMoreThan || createAction != nil {
            HStack {
                TextField("Search", text: $searchPart)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                    .onChange(of: searchPart, perform: {searchPart in
                        filteredTopics = searchPart.isEmpty ? topics : topics.filter({$0.name.localizedStandardContains(searchPart)})
                    })
                if createAction != nil && !searchPart.isEmpty {
                    Button(action: {
                        createAction!()
                    }, label: {
                        Image(systemName: "plus")
                    }).buttonStyle(.bordered)
                }
            }
        }
        ForEach(filteredTopics, id: \.name) {topic in
            Button(action: {
                selection = topic
            }, label: {
                Text(topic.name)
            })
                .listRowBackground(selection == topic ? selectedBackground() : nil)
        }
        .onChange(of: topics, perform: {topics in
            filteredTopics = topics
            selection = nil
            searchPart = ""
        })
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
