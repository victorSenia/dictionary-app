//
//  WordModels.swift
//  dictionary
//
//  Created by New on 07.07.2024.
//

import Foundation

class Word: Identifiable, Equatable {
    static func == (lhs: Word, rhs: Word) -> Bool {
        return lhs.word == rhs.word && lhs.additionalInformation == rhs.additionalInformation && lhs.language == rhs.language && lhs.article == rhs.article
    }
    init(id: Int64? = nil, word: String, additionalInformation: String = "", article: String = "", language: String) {
        self.id = id
        self.word = word
        self.additionalInformation = additionalInformation
        self.article = article
        self.language = language
    }
    var id: Int64?
    var listId: String {get{
        return id != nil ? String(id!) : word
    }}
    
    var word: String
    var additionalInformation: String = ""
    var article: String = ""
    var language: String
    var knowledge: Float64 = 0.0
    var translations: [Translation] = []
    var topics: [Topic] = []
    func toString()->String{
        return word + " - " + translations.map { t in
            t.translation
        }.joined(separator: ", ")
    }
}
class Translation: Identifiable, Equatable {
    static func == (lhs: Translation, rhs: Translation) -> Bool {
        return lhs.translation == rhs.translation && lhs.language == rhs.language
    }
    
    init(id: Int64? = nil, translation: String, language: String) {
        self.id = id
        self.translation = translation
        self.language = language
    }
    var id: Int64?
    var translation: String
    var language: String
}
class Topic: Identifiable, Equatable {
    static func == (lhs: Topic, rhs: Topic) -> Bool {
        lhs.name == rhs.name && lhs.language == rhs.language && lhs.level == rhs.level && lhs.root == rhs.root
    }
    
    init(id: Int64? = nil, name: String, language: String, level: Int32) {
        self.id = id
        self.name = name
        self.language = language
        self.level = level
    }
    
    var id: Int64?
    var name: String
    var language: String
    var level: Int32
    var root: Topic?
}
class WordCriteria: Decodable, Encodable, Equatable {
    static func == (lhs: WordCriteria, rhs: WordCriteria) -> Bool {
        return lhs.languageFrom == rhs.languageFrom && lhs.topicsOr == rhs.topicsOr && lhs.rootTopic == rhs.rootTopic && lhs.languageTo == rhs.languageTo
    }
    
    var languageFrom: String?
    var topicsOr: [Int64]?
    var rootTopic: Int64?
    var languageTo: [String]?
}
