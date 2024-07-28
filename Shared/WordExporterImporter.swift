//
//  WordExporterImporter.swift
//  dictionary
//
//  Created by on 27.07.2024.
//

import Foundation

/**
 * format of word
 * <pre>
 * {@code
 * articlewordadditionalInformationtranslationstopics
 *
 * translations
 * language=translationlanguage=translation
 *
 * topics
 * level=namelevel=name
 * }
 * </pre>
 */
let MAIN_DIVIDER: Character = ":"
let CONFIGURATION_PREFIX: String = "CONFIGURATION_PREFIX"
let PARTS_DIVIDER: Character = ";"
let ELEMENT_DIVIDER: Character = "="
let LINE_SEPARATOR: Character = "\r\n"

func getDocumentsDirectory() -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    return paths[0]
}

class WordExporter {
    var result: String = ""
    var fileName: String = "example.txt"
    var url: URL?
    
    func writeString(stringToWrite: String) {
        do {
            let url = self.url != nil ? url! : getDocumentsDirectory().appendingPathComponent(fileName)
            try stringToWrite.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            NSLog(error.localizedDescription)
        }
    }
    
    func writeWords(list: [Word], allForLanguage: Bool, rootTopicNames: [String]) {
        if (allForLanguage) {
            writeWordsForTopic(list: list, rootTopic: nil)
            for currentRoot in rootTopicNames {
                writeWordsForTopic(list: list, rootTopic: currentRoot)
            }
        } else {
            if (rootTopicNames.isEmpty) {
                writeWordsForTopic(list: list, rootTopic: nil)//no topics
            } else if (rootTopicNames.count == 1) {
                for currentRoot in rootTopicNames {
                    writeWordsForTopic(list: list, rootTopic: currentRoot)
                }
            }
        }
        writeString(stringToWrite: result)
    }
    
    var rootTopicName: String?
    
    func writeWordsForTopic(list: [Word], rootTopic: String?) {
        rootTopicName = rootTopic
        writeConfiguration(language: list[0].language, rootTopicName: rootTopicName)
        for word in list {
            if (isRelevantForTopic(word: word)) {
                writeWord(word: word)
            }
        }
    }
    
    func isRelevantForTopic(word: Word) -> Bool {
        return (rootTopicName == nil && (word.topics.isEmpty || word.topics.contains(where:{t in isRelevantForTopic(topic: t)}))) ||
        (rootTopicName != nil && word.topics.contains(where:{t in isRelevantForTopic(topic: t)}))
    }
    
    func writeConfiguration(language: String, rootTopicName: String?) {
        result += (CONFIGURATION_PREFIX)
        result += String(MAIN_DIVIDER)
        result += (language)
        if (rootTopicName != nil) {
            result += String(MAIN_DIVIDER)
            result += (encode(string: rootTopicName))
        }
        result += String(LINE_SEPARATOR)
    }
    
    
    func writeWord(word: Word) {
        result += (encode(string: word.article))
        result += String(MAIN_DIVIDER)
        result += (encode(string: word.word))
        result += String(MAIN_DIVIDER)
        result += (encode(string: word.additionalInformation))
        result += String(MAIN_DIVIDER)
        writeTranslations(translations: word.translations)
        result += String(MAIN_DIVIDER)
        writeTopics(topics: word.topics)
        result += String(LINE_SEPARATOR)
    }
    
    func writeTopics(topics: [Topic]) {
        for topic in topics {
            if (isRelevantForTopic(topic: topic)) {
                writeTopic(topic: topic)
                result += String(PARTS_DIVIDER)
            }
        }
    }
    
    func isRelevantForTopic(topic: Topic) -> Bool {
        return (rootTopicName == nil && topic.root == nil) ||
        (rootTopicName != nil && topic.root != nil && rootTopicName == topic.root!.name)
    }
    
    func writeTopic(topic: Topic) {
        result += (String(topic.level))
        result += String(ELEMENT_DIVIDER)
        result += (encode(string: topic.name))
    }
    
    func writeTranslations(translations: [Translation]) {
        for translation in translations {
            writeTranslation(translation: translation)
            result += String(PARTS_DIVIDER)
        }
    }
    
    func writeTranslation(translation: Translation) {
        result += (translation.language)
        result += String(ELEMENT_DIVIDER)
        result += (encode(string: translation.translation))
    }
}

class WordImporter {
    let ARTICLE_INDEX: Int = 0
    let WORD_INDEX: Int = 1
    let ADDITIONAL_INFORMATION_INDEX: Int = 2
    let TRANSLATIONS_INDEX: Int = 3
    let TOPICS_INDEX: Int = 4
    let WORD_PARTS: Int = 5
    let TRANSLATION_PARTS: Int = 2
    let TRANSLATION_LANGUAGE_INDEX: Int = 0
    let TRANSLATION_TRANSLATION_INDEX: Int = 1
    let TOPIC_PARTS: Int = 2
    let TOPIC_LEVEL_INDEX: Int = 0
    let TOPIC_NAME_WORD_INDEX: Int = 1
    var language: String = ""
    var rootTopic: Topic?
    var fileName: String = "example.txt"
    var url: URL?
    
    func readString() -> String {
        do {
            let url = self.url != nil ? url! : getDocumentsDirectory().appendingPathComponent(fileName)
            let stringContent = try String(contentsOf: url)
            return stringContent
        } catch {
            NSLog(error.localizedDescription)
        }
        return ""
    }
    func readWords() -> [Word] {
        var words: [Word] = []
        NSLog("readWords started " + fileName)
        let lines = readString().split(separator: "\r\n")
        lines.forEach { line in
            if !line.isEmpty {
                if (line.starts(with: CONFIGURATION_PREFIX)) {
                    let parts = line.split(separator: MAIN_DIVIDER)
                    language = String(parts[1])
                    rootTopic = createTopicIfNeeded(parts: parts)
                }
                else {
                    let parts = line.split(separator: MAIN_DIVIDER, omittingEmptySubsequences: false)
                    if (parts.count != WORD_PARTS) {
                        NSLog("Wrong word format " + String(line))
                    }else{
                        let word = parseWord(parts: parts)
                        words.append(word)
                    }
                    
                }
            }
        }
        NSLog("readWords finished " + fileName)
        return words
    }
    
    func createTopicIfNeeded(parts: [Substring]) -> Topic? {
        if (parts.count > 2) {
            return Topic(name: decode(string: String(parts[2])), language: language, level: 1)
        }
        return nil
    }
    
    func parseWord(parts: [Substring]) -> Word {
        let word = Word(word: decode(string: String(parts[WORD_INDEX])), additionalInformation :decode(string: String(parts[ADDITIONAL_INFORMATION_INDEX])), article: decode(string: String(parts[ARTICLE_INDEX])), language: language)
        word.translations = parseTranslations(part: parts[TRANSLATIONS_INDEX])
        word.topics = parseTopics(part: parts[TOPICS_INDEX])
        return word
    }
    
    func parseTranslations(part: Substring) -> [Translation] {
        var translations: [Translation] = []
        let parts = part.split(separator: PARTS_DIVIDER)
        var translation: Translation?
        for string in parts {
            translation = parseTranslation(string: string)
            if (translation != nil) {
                translations.append(translation!)
            }
        }
        return translations
    }
    
    func parseTranslation(string: Substring) -> Translation? {
        if (string.isEmpty) {
            return nil
        }
        let parts = string.split(separator: ELEMENT_DIVIDER)
        if (parts.count != TRANSLATION_PARTS) {
            NSLog("Wrong translation format " + String(string))
            return nil
        }
        return Translation(translation: decode(string: String(parts[TRANSLATION_TRANSLATION_INDEX])), language: String(parts[TRANSLATION_LANGUAGE_INDEX]))
    }
    
    func parseTopics(part: Substring) -> [Topic] {
        var topics : [Topic] = []
        let parts = part.split(separator: PARTS_DIVIDER)
        var topic: Topic?
        for string in parts {
            topic = parseTopic(string: string)
            if (topic != nil) {
                topics.append(topic!)
            }
        }
        return topics
    }
    
    func parseTopic(string: Substring) -> Topic? {
        if (string.isEmpty) {
            return nil
        }
        let parts = string.split(separator: ELEMENT_DIVIDER)
        if (parts.count != TOPIC_PARTS) {
            NSLog("Wrong topic format " + String(string))
            return nil
        }
        let topic = Topic(name: decode(string: String(parts[TOPIC_NAME_WORD_INDEX])), language: language, level: Int32(parts[TOPIC_LEVEL_INDEX])!)
        topic.root = rootTopic
        return topic
    }
}

let allowedQueryParamAndKey : CharacterSet = {
    var allowedQueryParamAndKey = NSCharacterSet.urlQueryAllowed
    allowedQueryParamAndKey.remove(charactersIn: ";/?:@&=+$, ")
    return allowedQueryParamAndKey
}()

func encode(string: String?) -> String {
    if notEmptyString(string: string) {
        return string!.addingPercentEncoding(withAllowedCharacters: allowedQueryParamAndKey)!
    }
    return ""
}
func decode(string: String?) -> String {
    if notEmptyString(string: string) {
        return string!.removingPercentEncoding!.replacingOccurrences(of: "+", with: " ")
    }
    return ""
}

func notEmptyString(string: String?) -> Bool {
    return string != nil && !string!.isEmpty
}
