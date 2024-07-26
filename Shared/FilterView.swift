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
//        VStack {
//            Button(action: {
//                player.findWords(criteria: criteriaObject.criteria)
//            }, label: {
//                Spacer()
//                Label("filter", systemImage: "magnifyingglass")
//                Spacer()
//            })
//                .buttonStyle(.bordered)
//                .controlSize(.regular)
//                .padding([.leading, .trailing])
//
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
                languagesFrom = databaseWordProvider.languageFrom()
                languagesTo = databaseWordProvider.languageTo(language: language)
                rootTopics = databaseWordProvider.findRootTopics(language: language)
                topics = databaseWordProvider.findTopicsWithRoot(language: language, rootId: rootTopic != nil ? rootTopic!.id : nil, level: 2)
            }
            .onChange(of: language, perform: {_ in
                languagesTo = databaseWordProvider.languageTo(language: language)
                rootTopics = databaseWordProvider.findRootTopics(language: language)
                topics = databaseWordProvider.findTopics(language: language, level: 2)
                criteriaObject.criteria.languageFrom = language
                settings.currentCriteria = criteriaObject.criteria
            })
            .onChange(of: rootTopic, perform: {_ in
                topics = databaseWordProvider.findTopicsWithRoot(language: language, rootId: rootTopic != nil ? rootTopic!.id : nil, level: 2)
                criteriaObject.criteria.rootTopic = rootTopic != nil ? rootTopic!.id : nil
                settings.currentCriteria = criteriaObject.criteria
            })
            .onChange(of: languagesToSelected, perform: {l in
                criteriaObject.criteria.languageTo = l != nil ? [l!] : nil
                settings.currentCriteria = criteriaObject.criteria
            })
            .onChange(of: topicsSelected, perform: {t in
                criteriaObject.criteria.topicsOr = t != nil ? [t!.id!] : []
                settings.currentCriteria = criteriaObject.criteria
            })
//        }
    }
}
class CriteriaHolder: ObservableObject {
    @Published var criteria = settings.currentCriteria
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
                SearchTopicsView(searchPart: $searchPart, filteredTopics: topics, selection: $selection, topics: $topics)
            }
        }
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
