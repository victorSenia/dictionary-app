//
//  WordProvider.swift
//  dictionary
//
//  Created by New on 07.07.2024.
//

import Foundation

protocol WordProvider {
    func findWords(criteria: WordCriteria) -> [Word]
}
class DatabaseWordProvider: WordProvider{
    var _databaseManager = databaseManager
    let CHUNK_SIZE = 500
    func findWords(criteria: WordCriteria) -> [Word] {
        _databaseManager.findWords(criteria: criteria)
    }
    
    func importWords(words: [Word]){
        for fromIndex in stride(from: 0, through: words.count, by: CHUNK_SIZE) {
            importWordsChunk( words: words[fromIndex..<min(words.count, fromIndex + CHUNK_SIZE)])
            print("imported from " + String(fromIndex) + " to " + String(min(words.count, fromIndex + CHUNK_SIZE)))
        }
    }
    func importWordsChunk(words: ArraySlice<Word>){
        _databaseManager.executeInTransaction(action: {
            for index in words.startIndex..<words.endIndex {
                words[index].id = nil
                for indexTranslation in 0..<words[index].translations.count {
                    words[index].translations[indexTranslation].id = nil
                }
                _databaseManager.insertFully(word: words[index])
            }
        })
    }
}
class ParseConfig {
    var fromLanguage:String = "de"
    var toLanguage:[String] = ["en","ru"]
    var separator:Character = "|"
    var translationSeparator:Character = ";"
    var additionalInfoSeparator:Character = ";"
    var topicDelimiter:String = ""
    var topicFlag:String = "\t"
    var rootName:String = "German most used"
}
class FileWordProvider: WordProvider{
    let configPrefix = "org.leo.dictionary.config.entity.ParseWords"
    var parseConfig = ParseConfig()
    var words: [Word] = []
    var rootTopic: Topic? = nil
    
    func findWords(criteria: WordCriteria) -> [Word]{
        if words.count == 0 {
            parseWords()
        }
        return words
    }
    func parseWords(){
        let lines = readString(fileName: "German_most_used.txt").split(separator: "\r\n")
        words.removeAll()
        var topics: [Topic] = []
        lines.forEach { line in
            if !line.isEmpty {
                if line.starts(with: configPrefix) {
                    parseConfigFunction(parts: line.split(separator: ":", omittingEmptySubsequences: false))
                    rootTopic = Topic(name: parseConfig.rootName, language: parseConfig.fromLanguage, level: 1)
                    topics = []
                }
                else if isTopicLine(line: line) {
                    let topic = parseTopic(line: line)
                    topics = topics.filter({t in t.level < topic.level})
                    topics.append(topic)
                } else {
                    let wordArray = line.split(separator: parseConfig.separator)
                    if wordArray.count == parseConfig.toLanguage.count + 1 {
                        let word = Word(word: String(wordArray[0].trimmingCharacters(in: .whitespaces)), language: parseConfig.fromLanguage)
                        word.translations = parseTranslation(parts: wordArray)
                        word.topics = topics
                        words.append(word)
                    }
                }
            }
        }
    }
    // let configPrefix = "org.leo.dictionary.config.entity.ParseWords:de:en; uk:die+; das+; der+:%5C%7C:%3B:%3B:%5Ct:"
    fileprivate func replaceRegexSymbols(_ a: String) -> String {
        return a.replacingOccurrences(of: "\\\\", with: "\\", options: .regularExpression, range: nil)
    }
    
    func parseConfigFunction(parts: [Substring]){
        parseConfig.fromLanguage = String(parts[1])
        parseConfig.toLanguage = parts[2].split(separator: ";").map({s in String(s).trimmingCharacters(in: .whitespaces)})
        
        // parseConfig.articles = String(parts[3])
        parseConfig.separator = Array(replaceRegexSymbols(decode(string: String(parts[4]))))[0]
        parseConfig.additionalInfoSeparator = Array(replaceRegexSymbols(decode(string: String(parts[5]))))[0]
        parseConfig.translationSeparator = Array(replaceRegexSymbols(decode(string: String(parts[6]))))[0]
        parseConfig.topicFlag = decode(string: String(parts[7]))
        parseConfig.rootName = decode(string: String(parts[9]))
        if parts.count > 8 {
            parseConfig.topicDelimiter = decode(string: String(parts[8]))
        }
    }
    func isTopicLine(line:Substring) -> Bool {
        return line.range(of: "^("+parseConfig.topicFlag + parseConfig.topicDelimiter+")+", options: .regularExpression) != nil
    }
    func parseTopic(line:Substring) -> Topic {
        var name = String(line)
        var level: Int32 = 1
        while isTopicLine(line: name.split(separator: "\r\n")[0]) {
            name = name.replacingOccurrences(of: "^("+parseConfig.topicFlag + parseConfig.topicDelimiter+")", with:"", options: .regularExpression)
            level += 1
        }
        var topic = Topic(name: name, language: parseConfig.fromLanguage, level: level)
        topic.root = rootTopic
        return topic
    }
    
    func parseTranslation(parts:[Substring])->[Translation]{
        var translations = [Translation]()
        var index:Int = 0
        for part in parts{
            if index != 0 {
                part.split(separator: parseConfig.translationSeparator).forEach { translation in
                    translations.append(Translation(translation: String(translation.trimmingCharacters(in: .whitespaces)), language: parseConfig.toLanguage[index - 1]))
                }
            }
            index += 1
        }
        return translations
    }
    
    func readString(fileName:String) -> String {
        do {
            // creating a path from the main bundle
            if let bundlePath = Bundle.main.path(forResource: fileName, ofType: nil) {
                let stringContent = try String(contentsOfFile: bundlePath)
                return stringContent
            }
        } catch {
            print(error)
        }
        return ""
    }
    func writeString() {
        do {
            // creating path from main bundle
            if let bundlePath = Bundle.main.path(forResource: "example.txt", ofType: nil) {
                
                let stringToWrite = "This is a string to write to a file."
                try? stringToWrite.write(toFile: bundlePath, atomically: true, encoding: .utf8)
                
                let stringContent = try String(contentsOfFile: bundlePath)
                print("Content string starts from here-----")
                print(stringContent)
                print("End at here-----")
            }
        } catch {
            print(error)
        }
    }
}
func encode(string: String) -> String {
    return string.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!
}
func decode(string: String) -> String {
    return string.removingPercentEncoding!
}
