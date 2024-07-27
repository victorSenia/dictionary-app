//
//  WordProvider.swift
//  dictionary
//
//  Created by New on 07.07.2024.
//

import Foundation

protocol WordProvider {
    func findWords(criteria: WordCriteria) -> [Word]
    func languageFrom() -> [String]
    func languageTo(language: String?) -> [String]
    func findTopics(language: String?, level: Int32) -> [Topic]
    func findTopicsWithRoot(language: String?, rootId: Int64?, level: Int32) -> [Topic]
    func findRootTopics(language: String?) -> [Topic]
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
            NSLog("imported from " + String(fromIndex) + " to " + String(min(words.count, fromIndex + CHUNK_SIZE)))
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
    func deleteForLanguage(language: String){
        _databaseManager.executeInTransaction(action: {
            _databaseManager.deleteForLanguage(language: language)
        })
        _databaseManager.vacuum()
    }
    func updateWordFully(updatedWord: Word){
        _databaseManager.executeInTransaction(action: {
            if updatedWord.id != nil {
                let oldWord = _databaseManager.findWord(id: updatedWord.id!);
                if (oldWord != nil) {
                    updateWord(updatedWord: updatedWord, oldWord: oldWord!);
                } else {
                    _databaseManager.insertFully(word: updatedWord);
                }
            } else {
                _databaseManager.insertFully(word: updatedWord)
            }
        })
    }
    func updateTopic(topic: inout Topic){
        _databaseManager.executeInTransaction(action: {
            if topic.id != nil {
                _databaseManager.updateTopic(topic: topic)
            } else {
                _databaseManager.insertTopic(topic: &topic)
            }
        })
    }
    
    
    private func findTranslationById(word: Word, id: Int64) -> Translation? {
        for  translation in word.translations {
            if (translation.id == id) {
                return translation;
            }
        }
        return nil;
    }
    
    private func findTopicById(word: Word, id: Int64) -> Topic? {
        for topic in word.topics {
            if topic.id == id {
                return topic;
            }
        }
        return nil;
    }
    
    public func findTopics(language: String?, level: Int32) -> [Topic] {
        return _databaseManager.getTopics(language: language, rootId: nil, level: level);
    }
    
    public func findTopicsWithRoot(language: String?, rootId: Int64?, level: Int32) -> [Topic] {
        return _databaseManager.getTopics(language: language, rootId: rootId, level: level);
    }
    
    public func findRootTopics(language: String?) -> [Topic]{
        return _databaseManager.findRootTopics(language: language);
    }
    
    public func languageFrom() -> [String] {
        return _databaseManager.languageFrom();
    }
    
    public func languageTo(language: String?) -> [String] {
        return _databaseManager.languageTo(language: language);
    }
    
    public func updateWord(updatedWord: Word) {
        _databaseManager.executeInTransaction(action: {
            _databaseManager.updateWord(word: updatedWord);
        })
    }
    
    private func updateWord(updatedWord: Word, oldWord: Word) -> Word {
        if (oldWord != updatedWord) {
            _databaseManager.updateWord(word: updatedWord);
        }
        for translationIndex in updatedWord.translations.indices {
            var translation = updatedWord.translations[translationIndex]
            if (translation.id == nil) {
                _databaseManager.insertTranslation(translation: &translation, wordId: updatedWord.id!);
            } else if (translation != findTranslationById(word: oldWord, id: translation.id!)) {
                _databaseManager.updateTranslation(translation: translation);
            }
        }
        for translation in oldWord.translations {
            if (findTranslationById(word: updatedWord, id: translation.id!) == nil) {
                _databaseManager.deleteTranslation(id: translation.id!);
            }
        }
        for topicIndex in updatedWord.topics.indices {
            var topic = updatedWord.topics[topicIndex]
            if (topic.id == nil) {
                _databaseManager.insertWordTopicLink(wordId: updatedWord.id!, topicId: _databaseManager.insertTopic(topic: &topic));
            } else if (findTranslationById(word: oldWord, id: topic.id!) == nil) {
                _databaseManager.insertWordTopicLink(wordId: updatedWord.id!, topicId: topic.id!);
            }
        }
        for topic in oldWord.topics {
            if (findTopicById(word: updatedWord, id: topic.id!) == nil) {
                _databaseManager.deleteWordTopicLink(wordId: updatedWord.id!, topicId: topic.id!);
            }
        }
        return updatedWord;
    }
    
    
    public func findWord(id: Int64) -> Word? {
        return _databaseManager.findWord(id: id);
    }
    
    public func getWordsForLanguage(language: String, rootTopic: Int64?) -> [Word] {
        return _databaseManager.findWordsForLanguage(language: language, rootId: rootTopic);
    }
    
    
    public func deleteWord(id: Int64) {
        _databaseManager.executeInTransaction(action: {
            _databaseManager.deleteWord(id: id)
        });
    }
    
    public func insertConfigurationPreset(name: String, data: [String:AnyObject]) {
        _databaseManager.executeInTransaction(action: {
            _databaseManager.insertConfigurationPreset(name: name, data: data)
        });
    }
    
    public func updateConfigurationPreset(name: String, data: [String:AnyObject]) {
        _databaseManager.executeInTransaction(action: {
            _databaseManager.updateConfigurationPreset(name: name, data: data)
        });
    }
    
    public func deleteConfigurationPreset(name: String) {
        _databaseManager.executeInTransaction(action: {
            _databaseManager.deleteConfigurationPreset(name: name)
        });
    }
    
    public func getConfigurationPresetNames() -> [String] {
        return _databaseManager.getConfigurationPresetNames();
    }
    
    public func getConfigurationPreset(name: String) -> [String:AnyObject]? {
        return _databaseManager.getConfigurationPreset(name: name);
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
    func findTopics(language: String?, level: Int32) -> [Topic] {
        return findTopicsWithRoot(language: language, rootId: nil, level: level)
    }
    
    func findTopicsWithRoot(language: String?, rootId: Int64?, level: Int32) -> [Topic] {
        var topics: [Topic] = []
        //        words.forEach({w in
        //            w.topics.forEach({t in
        //                if !topics.contains(t) {
        //                    topics.append(t)
        //                }
        //            })
        //        })
        return topics
    }
    
    func findRootTopics(language: String?) -> [Topic] {
        return rootTopic != nil ? [rootTopic!] : []
    }
    
    func languageFrom() -> [String] {
        return [parseConfig.fromLanguage]
    }
    
    func languageTo(language: String?) -> [String] {
        return parseConfig.toLanguage
    }
    
    let configPrefix = "org.leo.dictionary.config.entity.ParseWords"
    var parseConfig = ParseConfig()
    var words: [Word] = []
    var rootTopic: Topic? = nil
    var fileName: String = "German_most_used.txt"
    
    func findWords(criteria: WordCriteria) -> [Word]{
        if words.count == 0 {
            parseWords()
        }
        return words
    }
    func parseWords(){
        NSLog("parseWords started " + fileName)
        let lines = readString(fileName: fileName).split(separator: "\r\n")
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
                        var word = Word(word: String(wordArray[0].trimmingCharacters(in: .whitespaces)), language: parseConfig.fromLanguage)
                        if let indexOf = words.firstIndex(of: word){
                            word = words[indexOf]
                            let translations = parseTranslation(parts: wordArray)
                            for translation in translations {
                                if !word.translations.contains(translation){
                                    word.translations.append(translation)
                                }
                            }
                            for topic in topics {
                                if !word.topics.contains(topic){
                                    word.topics.append(topic)
                                }
                            }
                        }
                        else {
                            word.translations = parseTranslation(parts: wordArray)
                            word.topics = topics
                            words.append(word)}
                    }
                }
            }
        }
        NSLog("parseWords ended " + fileName)
    }
    func replaceRegexSymbols(_ a: String) -> String {
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
        if parts.count > 9 {
            parseConfig.topicDelimiter = decode(string: String(parts[8]))
            parseConfig.rootName = decode(string: String(parts[9]))
        }
    }
    func topicRegex() -> String {
        return "^("+parseConfig.topicFlag + parseConfig.topicDelimiter+")"
    }
    
    func isTopicLine(line:Substring) -> Bool {
        return line.range(of: topicRegex() + "+", options: .regularExpression) != nil
    }
    func parseTopic(line:Substring) -> Topic {
        var name = String(line)
        var level: Int32 = 1
        while isTopicLine(line: name.split(separator: "\r\n")[0]) {
            name = name.replacingOccurrences(of: topicRegex(), with:"", options: .regularExpression)
            level += 1
        }
        let topic = Topic(name: name, language: parseConfig.fromLanguage, level: level)
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
            NSLog(error.localizedDescription)
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
            NSLog(error.localizedDescription)
        }
    }
}
func encode(string: String) -> String {
    return string.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!
}
func decode(string: String) -> String {
    return string.removingPercentEncoding!.replacingOccurrences(of: "+", with: " ")
}
