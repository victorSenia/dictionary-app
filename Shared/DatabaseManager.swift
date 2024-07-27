//
// DatabaseManager.swift
// dictionary
//
// Created by New on 01.07.2024.
//

import Foundation
import SQLite3

class DatabaseManager: DatabaseHelper {
    
    var PAGE_SIZE = 200
    
    func translationColumns() -> [String] {
        return [COLUMN_ID, COLUMN_LANGUAGE, TRANSLATION_COLUMN_WORD_ID, TRANSLATION_COLUMN_TRANSLATION]
    }
    func mapTranslationFromSql(queryStatement: OpaquePointer!, wordsMap: inout [Int64: Word]) {
        let id = sqlite3_column_int64(queryStatement, 0)
        let language = String(describing: String(cString: sqlite3_column_text(queryStatement, 1)))
        let translation = String(describing: String(cString: sqlite3_column_text(queryStatement, 3)))
        addTranslationToWord(w: &wordsMap[sqlite3_column_int64(queryStatement, 2)]!, t: Translation(id: id, translation: translation, language: language))
        
    }
    func addTranslationToWord(w: inout Word,t: Translation){
        w.translations.append(t)
    }
    
    func wordColumns () -> [String] {
        return [COLUMN_ID, COLUMN_LANGUAGE, WORD_COLUMN_WORD, WORD_COLUMN_ADDITIONAL_INFORMATION, WORD_COLUMN_ARTICLE]
    }
    func mapWordFromSql(queryStatement: OpaquePointer!, words: inout [Word]) {
        let id = sqlite3_column_int64(queryStatement, 0)
        let language = String(describing: String(cString: sqlite3_column_text(queryStatement, 1)))
        let word = String(describing: String(cString: sqlite3_column_text(queryStatement, 2)))
        let article = String(describing: String(cString: sqlite3_column_text(queryStatement, 3)))
        let additionalInformation = String(describing: String(cString: sqlite3_column_text(queryStatement, 4)))
        let wordObject = Word(id: id, word: word, additionalInformation: additionalInformation, article: article, language: language)
        words.append(wordObject)
    }
    
    func topicColumns () -> [String] {
        return [COLUMN_ID, COLUMN_LANGUAGE, TOPIC_COLUMN_LEVEL, TOPIC_COLUMN_NAME, TOPIC_COLUMN_ROOT_ID]
    }
    func mapTopicFromSql(queryStatement: OpaquePointer!, topics: inout [Topic], loadedTopics: inout [Int64: Topic] ) {
        let id = sqlite3_column_int64(queryStatement, 0)
        if let topic = loadedTopics[id] {
            topics.append(topic)
        } else {
            let language = String(describing: String(cString: sqlite3_column_text(queryStatement, 1)))
            let level = sqlite3_column_int(queryStatement, 2)
            let name = String(describing: String(cString: sqlite3_column_text(queryStatement, 3)))
            
            let topic = Topic(id: id, name: name, language: language, level: level)
            if sqlite3_column_type(queryStatement, 4) != SQLITE_NULL {
                if let root = loadedTopics[sqlite3_column_int64(queryStatement, 4)] {
                    topic.root = root
                }
            }
            topics.append(topic)
            loadedTopics[topic.id!] = topic
        }
    }
    func insertFully(word: Word) -> Int64{
        let wordId = insertWord(word: word)
        word.id = wordId
        for i in 0..<word.translations.count {
            insertTranslation(translation: &word.translations[i], wordId: wordId)
        }
        for i in 0..<word.topics.count {
            insertWordTopicLink(wordId: wordId, topicId: insertTopic(topic: &word.topics[i]))
        }
        return wordId
    }
    
    func executeInTransaction(action: () -> Void) {
        sqlite3_exec(db, "BEGIN EXCLUSIVE TRANSACTION", nil, nil, nil);
        action()
        if (sqlite3_exec(db, "COMMIT TRANSACTION", nil, nil, nil) != SQLITE_OK) {
            NSLog("SQL Error: %s",sqlite3_errmsg(db));
        }
        
    }
    
    func insertWord(word: Word) -> Int64 {
        if let id = getWordId(word: word){
            return id
        }
        let columns = [COLUMN_LANGUAGE, WORD_COLUMN_WORD, WORD_COLUMN_ARTICLE, WORD_COLUMN_ADDITIONAL_INFORMATION, WORD_COLUMN_KNOWLEDGE]
        insert(insertStatementString: insertQuery(tableName: TABLE_NAME_WORD, columns: columns), statmentModifier: {insertStatement in
            sqlite3_bind_text(insertStatement, 1, (word.language as NSString).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 2, (word.word as NSString).utf8String, -1, nil)
            bindNullOrTextValue(insertStatement: insertStatement, index: 3, value: word.article)
            bindNullOrTextValue(insertStatement: insertStatement, index: 4, value: word.additionalInformation)
            sqlite3_bind_double(insertStatement, 5, word.knowledge)
        })
        return getWordId(word: word)!
    }
    
    func bindNullOrTextValue(insertStatement: OpaquePointer!, index: Int32, value: String?) {
        if let article = value {
            sqlite3_bind_text(insertStatement, index, (article as NSString).utf8String, -1, nil)}
        else{
            sqlite3_bind_null(insertStatement, index)
        }
    }
    func insertTopic(topic: inout Topic) -> Int64 {
        if let id = topic.id {
            return id
        }
        if let id = getTopicId(topic: topic) {
            topic.id = id
            return id
        }
        var rootId: Int64? = nil
        if var root = topic.root {
            rootId = insertTopic(topic: &root)
        }
        let columns = [COLUMN_LANGUAGE, TOPIC_COLUMN_LEVEL, TOPIC_COLUMN_NAME, TOPIC_COLUMN_ROOT_ID]
        insert(insertStatementString: insertQuery(tableName: TABLE_NAME_TOPIC, columns: columns), statmentModifier: {insertStatement in
            sqlite3_bind_text(insertStatement, 1, (topic.language as NSString).utf8String, -1, nil)
            sqlite3_bind_int(insertStatement, 2, topic.level)
            sqlite3_bind_text(insertStatement, 3, (topic.name as NSString).utf8String, -1, nil)
            if rootId != nil {
                sqlite3_bind_int64(insertStatement, 4, rootId!)
            }else{
                sqlite3_bind_null(insertStatement, 4)
            }
        })
        topic.id = getTopicId(topic: topic)
        return topic.id!
    }
    
    func getTopicId(topic: Topic) -> Int64? {
        if topic.root != nil {
            insertTopic(topic: &topic.root!)
        }
        return getId(table: TABLE_NAME_TOPIC, whereClause: COLUMN_LANGUAGE + " = ? AND " + TOPIC_COLUMN_NAME + " = ? AND " + TOPIC_COLUMN_LEVEL + " = ?" + andNullOrEquals(column: TOPIC_COLUMN_ROOT_ID, value: topic.root), statmentModifier: {insertStatement in
            sqlite3_bind_text(insertStatement, 1, (topic.language as NSString).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 2, (topic.name as NSString).utf8String, -1, nil)
            sqlite3_bind_int(insertStatement, 3, topic.level)
            if let root = topic.root {
                sqlite3_bind_int64(insertStatement, 4, root.id!)
            }
        })
    }
    
    func andNullOrEquals(column: String, value: AnyObject?) -> String {
        return " AND " + nullOrEquals(column: column, value: value)
    }
    
    func nullOrEquals(column: String, value: AnyObject?) -> String {
        if value != nil {
            return column + " = ? "
        }
        return column + " IS NULL "
    }
    
    func andNullOrEquals(column: String, value: String?) -> String {
        return " AND " + nullOrEquals(column: column, value: value)
    }
    
    func nullOrEquals(column: String, value: String?) -> String {
        if value != nil {
            return column + " = ? "
        }
        return column + " IS NULL "
    }
    func getTranslationId(translation: Translation, wordId: Int64) -> Int64? {
        let whereClause: String = COLUMN_LANGUAGE + " = ? AND " + TRANSLATION_COLUMN_WORD_ID + " = ? AND " + TRANSLATION_COLUMN_TRANSLATION + " = ?"
        return getId(table: TABLE_NAME_TRANSLATION, whereClause: whereClause, statmentModifier: {insertStatement in
            sqlite3_bind_text(insertStatement, 1, (translation.language as NSString).utf8String, -1, nil)
            sqlite3_bind_int64(insertStatement, 2, wordId)
            sqlite3_bind_text(insertStatement, 3, (translation.translation as NSString).utf8String, -1, nil)
        })
    }
    
    func getWordId(word: Word) -> Int64? {
        let whereClause = COLUMN_LANGUAGE + " = ? AND " + WORD_COLUMN_WORD + " = ? " +
        andNullOrEquals(column: WORD_COLUMN_ARTICLE, value: word.article) +
        andNullOrEquals(column: WORD_COLUMN_ADDITIONAL_INFORMATION, value: word.additionalInformation)
        return
        getId(table: TABLE_NAME_WORD, whereClause: whereClause
              , statmentModifier: {insertStatement in
            sqlite3_bind_text(insertStatement, 1, (word.language as NSString).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 2, (word.word as NSString).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 3, (word.article as NSString).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 4, (word.additionalInformation as NSString).utf8String, -1, nil)
        })
    }
    
    func getId(table: String, whereClause: String?, statmentModifier: StatmentModifier?) -> Int64? {
        var id: Int64? = nil
        let queryStatementString = selectQuery(table: table, columns: [COLUMN_ID], whereClause: whereClause)
        query(queryStatementString: queryStatementString, statmentModifier: statmentModifier, rowParser: {statement in
            id = sqlite3_column_int64(statement, 0)
        }, exitOnFirst: true)
        return id
    }
    
    func selectQuery(table: String, columns: [String]? = nil, whereClause: String?, distinct: Bool = false) -> String {
        var queryStatementString = "SELECT " + (distinct ? "DISTINCT ": "") + (columns != nil ? columns!.joined(separator: ", "): "*") + " FROM " + table
        if whereClause != nil && !whereClause!.isEmpty {
            queryStatementString = queryStatementString + " WHERE " + whereClause!
        }
        return queryStatementString
    }
    
    func insertTranslation(translation: inout Translation, wordId: Int64) -> Int64 {
        if let id = getTranslationId(translation: translation, wordId: wordId) {
            return id
        }
        let columns = [TRANSLATION_COLUMN_WORD_ID, COLUMN_LANGUAGE, TRANSLATION_COLUMN_TRANSLATION]
        insert(insertStatementString: insertQuery(tableName: TABLE_NAME_TRANSLATION, columns: columns), statmentModifier: {insertStatement in
            sqlite3_bind_int64(insertStatement, 1, wordId)
            sqlite3_bind_text(insertStatement, 2, (translation.language as NSString).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 3, (translation.translation as NSString).utf8String, -1, nil)
        })
        translation.id = getTranslationId(translation: translation, wordId: wordId)
        return translation.id!
    }
    
    func insertQuery(tableName: String, columns:[String]) -> String {
        return "INSERT INTO " + tableName + " (" +
        columns.joined(separator: ", ") + ") VALUES (" + createPlaceholders(length: columns.count) + ")"
    }
    
    func updateQuery(tableName: String, columns:[String], whereClause: String?) -> String {
        return "UPDATE " + tableName + " SET " +
        columns.joined(separator: "=?, ") + "=?" + (whereClause != nil ? " WHERE " + whereClause! : "")
    }
    
    func deleteQuery(tableName: String, whereClause: String?) -> String {
        return "DELETE FROM " + tableName + (whereClause != nil ? " WHERE " + whereClause! : "")
    }
    
    func insertWordTopicLink(wordId: Int64, topicId: Int64) {
        if let id = getId(table: TABLE_NAME_WORD_TOPIC, whereClause: COLUMN_ID + " = ? AND " + TRANSLATION_COLUMN_WORD_ID + " = ?", statmentModifier: { statement in
            sqlite3_bind_int64(statement, 1, topicId)
            sqlite3_bind_int64(statement, 2, wordId)
        }) {
            return
        }
        let columns = [COLUMN_ID, TRANSLATION_COLUMN_WORD_ID]
        insert(insertStatementString: insertQuery(tableName: TABLE_NAME_WORD_TOPIC, columns: columns), statmentModifier: {insertStatement in
            sqlite3_bind_int64(insertStatement, 1, topicId)
            sqlite3_bind_int64(insertStatement, 2, wordId)
        })
    }
    
    func deleteWordTopicLink(wordId: Int64, topicId: Int64) {
        delete(deleteStatementString: deleteQuery(tableName: TABLE_NAME_WORD_TOPIC, whereClause: COLUMN_ID + " = ? AND " + TRANSLATION_COLUMN_WORD_ID + " = ?"), statmentModifier:{statement in
            sqlite3_bind_int64(statement, 1, topicId)
            sqlite3_bind_int64(statement, 2, wordId)
        })
    }
    func fetchWordsSql(criteria: WordCriteria, rowParser: StatmentModifier) {
        var sql = "SELECT DISTINCT w." + wordColumns().joined(separator: ", w.") + " FROM " + TABLE_NAME_WORD + " w"
        var whereClause = ""
        let topicIds: [Int64] = getTopicIds(languageFrom: criteria.languageFrom, rootId: criteria.rootTopic, topicsOr: criteria.topicsOr)
        if topicIds.count > 0
        {
            sql += " INNER JOIN " + TABLE_NAME_WORD_TOPIC + " t ON w." + COLUMN_ID + " = t." + TRANSLATION_COLUMN_WORD_ID + " AND t." + COLUMN_ID + " IN (" + createPlaceholders(length: topicIds.count) + ")"
        }
        if (criteria.languageFrom != nil) {
            whereClause += " w." + COLUMN_LANGUAGE + " = ?"
        }
        query(queryStatementString: sql + (!whereClause.isEmpty ? " WHERE " + whereClause : ""), statmentModifier: {insertStatement in
            var index: Int32 = 1
            if topicIds.count > 0 {
                for topicId in topicIds {
                    sqlite3_bind_int64(insertStatement, index, topicId)
                    index += 1
                }
            }
            if (criteria.languageFrom != nil) {
                sqlite3_bind_text(insertStatement, index, (criteria.languageFrom! as NSString).utf8String, -1, nil)
            }
        }, rowParser: rowParser)
    }
    
    
    func fetchTranslationsSql(languages: [String]?, wordIds: ArraySlice<Int64>, rowParser: StatmentModifier) {
        var selection = TRANSLATION_COLUMN_WORD_ID + " IN (" + createPlaceholders(length: wordIds.count) + ")"
        if (languages != nil && !languages!.isEmpty) {
            selection += " AND " + COLUMN_LANGUAGE + " IN (" + createPlaceholders(length: languages!.count) + ")"
        }
        let queryStatementString = selectQuery(table: TABLE_NAME_TRANSLATION, columns: translationColumns(), whereClause: selection)
        query(queryStatementString: queryStatementString, statmentModifier: { statement in
            var index: Int32 = 1
            if wordIds.count > 0 {
                for wordId in wordIds {
                    sqlite3_bind_int64(statement, index, wordId)
                    index += 1
                }
            }
            if languages != nil && languages!.count > 0 {
                for language in languages! {
                    sqlite3_bind_text(statement, index, (language as NSString).utf8String, -1, nil)
                    index += 1
                }
            }
        }, rowParser: rowParser)
    }
    
    func getTopicIds(languageFrom: String?, rootId: Int64?, topicsOr: [Int64]?) -> [Int64] {
        if topicsOr != nil && !topicsOr!.isEmpty {
            return topicsOr!
        }
        var ids: [Int64] = []
        fetchTopics(columns: [COLUMN_ID], language: languageFrom, level: nil, rootId: rootId, topicIds: topicsOr, rowParser: {statement in
            
        })
        return ids
    }
    
    func fetchTopics(columns: [String], language: String?, level: Int32?, rootId: Int64?, topicIds:[Int64]?, rowParser: StatmentModifier) {
        
        var selection = " 1 = 1"
        if (language != nil) {
            selection += " AND " + COLUMN_LANGUAGE + "= ?"
        }
        if (level != nil) {
            selection += " AND " + TOPIC_COLUMN_LEVEL + "= ?"
        }
        if (rootId != nil) {
            selection += " AND " + TOPIC_COLUMN_ROOT_ID + "= ?"
        }
        if (topicIds != nil && !topicIds!.isEmpty) {
            selection += " AND " + COLUMN_ID + " IN (" + createPlaceholders(length: topicIds!.count) + ")"
        }
        let queryStatementString = selectQuery(table: TABLE_NAME_TOPIC, columns: columns, whereClause: selection)
        query(queryStatementString: queryStatementString, statmentModifier: { statement in
            var index: Int32 = 1
            if (language != nil) {
                sqlite3_bind_text(statement, index, (language! as NSString).utf8String, -1, nil)
                index += 1
            }
            if (level != nil) {
                sqlite3_bind_int(statement, index, level!)
                index += 1
            }
            if (rootId != nil) {
                sqlite3_bind_int64(statement, index, rootId!)
                index += 1
            }
            if topicIds != nil && topicIds!.count > 0 {
                for topicId in topicIds! {
                    sqlite3_bind_int64(statement, index, topicId)
                    index += 1
                }
            }
        }, rowParser: rowParser)
    }
    func getTopics(language: String?, rootId: Int64?, level: Int32) -> [Topic] {
        var loadedTopics:[Int64: Topic] = [:]
        if (rootId == nil && level > 1) {
            let rootTopics = findRootTopics(language: language)
            if !rootTopics.isEmpty {
                loadedTopics = Dictionary(uniqueKeysWithValues: rootTopics.map{ ($0.id!, $0) })
            }
        }
        var topics: [Topic] = []
        fetchTopics(columns: topicColumns(), language: language, level: level, rootId: rootId, topicIds: nil, rowParser: {statement in
            mapTopicFromSql(queryStatement: statement, topics: &topics, loadedTopics: &loadedTopics)
        })
        return topics
    }
    
    func findRootTopics(language: String?) -> [Topic] {
        return getTopics(language: language, rootId: nil, level: 1)
    }
    
    func getTopicsForWord(wordId: Int64, language: String, level: Int32, loadedTopics: inout [Int64:Topic] ) -> [Topic] {
        var topics: [Topic] = []
        let columns = "t." + topicColumns().joined(separator: ", t.")
        query(queryStatementString: "SELECT " + columns + " FROM " + TABLE_NAME_TOPIC + " t " +
              " INNER JOIN " + TABLE_NAME_WORD_TOPIC + " tw " +
              " ON t." + COLUMN_ID + " = tw." + COLUMN_ID +
              " AND tw." + TRANSLATION_COLUMN_WORD_ID + "= ?" +
              " AND t." + COLUMN_LANGUAGE + "= ?" +
              " AND t." + TOPIC_COLUMN_LEVEL + "= ?"
              ,
              statmentModifier: {statement in
            
            sqlite3_bind_int64(statement, 1, wordId)
            sqlite3_bind_text(statement, 2, (language as NSString).utf8String, -1, nil)
            sqlite3_bind_int(statement, 3, level)
        },
              rowParser: {statement in
            mapTopicFromSql(queryStatement: statement, topics: &topics, loadedTopics: &loadedTopics)
        })
        return topics
    }
    
    func languageFrom() -> [String] {
        let queryStatementString = selectQuery(table: TABLE_NAME_WORD, columns: [COLUMN_LANGUAGE], whereClause: nil, distinct: true)
        
        var languages: [String] = []
        query(queryStatementString: queryStatementString, statmentModifier: nil, rowParser: {statement in
            let language = String(describing: String(cString: sqlite3_column_text(statement, 0)))
            languages.append(language)
        })
        return languages
    }
    
    func languageTo(language: String?) -> [String] {
        
        var languages: [String] = []
        languageToSql(language: language, rowParser: {statement in
            let language = String(describing: String(cString: sqlite3_column_text(statement, 0)))
            languages.append(language)
        })
        return languages
    }
    
    func languageToSql(language: String?, rowParser: StatmentModifier) {
        if (language != nil) {
            let queryStatementString: String = "SELECT DISTINCT t." + COLUMN_LANGUAGE +
            " FROM " + TABLE_NAME_TRANSLATION + " t" + " INNER JOIN " + TABLE_NAME_WORD + " w " +
            "ON w." + COLUMN_ID + " = t." + TRANSLATION_COLUMN_WORD_ID +
            " AND w." + COLUMN_LANGUAGE + "= ?"
            query(queryStatementString: queryStatementString, statmentModifier: { statement in
                sqlite3_bind_text(statement, 1, (language! as NSString).utf8String, -1, nil)
            }, rowParser: rowParser)
        } else {
            query(queryStatementString: selectQuery(table: TABLE_NAME_TRANSLATION, columns: [COLUMN_LANGUAGE], whereClause: nil, distinct: true), statmentModifier: nil, rowParser: rowParser)
        }
    }
    
    func findWordsForLanguage(language: String?, rootId: Int64?) -> [Word] {
        var criteria = WordCriteria()
        criteria.languageFrom = language
        criteria.rootTopic = rootId
        return findWords(criteria: criteria, includeTopics: true)
    }
    
    func findWords(criteria: WordCriteria, includeTopics: Bool = false) -> [Word] {
        var words: [Word] = []
        fetchWordsSql(criteria: criteria, rowParser: {statement in
            mapWordFromSql(queryStatement: statement, words: &words)
        })
        fetchTranslationsAndTopics(words: &words, languages: criteria.languageTo, includeTopics: includeTopics, language: criteria.languageFrom)
        return words
    }
    func fetchTranslationsAndTopics(words: inout [Word], languages: [String]?, includeTopics: Bool = false, language: String?){
        var wordsMap = Dictionary(uniqueKeysWithValues: words.map{ ($0.id!, $0) })
        let wordIds = Array(wordsMap.keys)
        for var fromIndex in stride(from: 0, through: wordIds.count, by: PAGE_SIZE) {
            fetchTranslationsSql(languages: languages, wordIds: wordIds[fromIndex..<min(wordIds.count, fromIndex + PAGE_SIZE)], rowParser: {statment in
                mapTranslationFromSql(queryStatement: statment, wordsMap: &wordsMap)
            })
        }
        words = words.filter{ word in hasTranslations(w: word)}
        if (includeTopics && !words.isEmpty) {
            var loadedTopics = Dictionary(uniqueKeysWithValues: findRootTopics(language: language).map{ ($0.id!, $0) })
            for i in 0..<words.count {
                words[i].topics = getTopicsForWord(wordId: words[i].id!, language: words[i].language, level: 2, loadedTopics: &loadedTopics)//TODO
            }
        }
    }
    func hasTranslations(w: Word) -> Bool {
        return !w.translations.isEmpty
    }
    
    func createPlaceholders(length: Int) -> String {
        return [String](repeating: "?", count: length).joined(separator: ", ")
    }
    
    func deleteWord(id: Int64) -> Int {
        return deleteWords(wordIds: [id])
    }
    
    func deleteForLanguage(language: String) -> Int {
        let wordIds:[Int64] = getWordIdsForLanguage(language: language)
        for fromIndex in stride(from: 0, through: wordIds.count, by: PAGE_SIZE) {
            deleteWords(wordIds: wordIds[fromIndex..<min(wordIds.count, fromIndex + PAGE_SIZE)])
        }
        delete(deleteStatementString: deleteQuery(tableName: TABLE_NAME_TOPIC, whereClause: COLUMN_LANGUAGE + "= ?"), statmentModifier: { statement in
            sqlite3_bind_text(statement, 1, (language as NSString).utf8String, -1, nil)
        })
        return wordIds.count
    }
    
    func vacuum() {
        execSQL(sql: "VACUUM")
    }
    
    func deleteWords(wordIds: ArraySlice<Int64>) -> Int {
        let statmentModifier: StatmentModifier = { statement in
            var index: Int32 = 1
            if wordIds.count > 0 {
                for wordId in wordIds {
                    sqlite3_bind_int64(statement, index, wordId)
                    index += 1
                }
            }
        }
        delete(deleteStatementString: deleteQuery(tableName: TABLE_NAME_WORD, whereClause: COLUMN_ID + " IN (" + createPlaceholders(length: wordIds.count) + ")"), statmentModifier: statmentModifier)
        delete(deleteStatementString: deleteQuery(tableName:TABLE_NAME_TRANSLATION, whereClause: TRANSLATION_COLUMN_WORD_ID + " IN (" + createPlaceholders(length: wordIds.count) + ")"), statmentModifier: statmentModifier)
        delete(deleteStatementString: deleteQuery(tableName:TABLE_NAME_WORD_TOPIC, whereClause: TRANSLATION_COLUMN_WORD_ID + " IN (" + createPlaceholders(length: wordIds.count) + ")"), statmentModifier: statmentModifier)
        return wordIds.count
    }
    
    func getWordIdsForLanguage(language: String) -> [Int64] {
        var result: [Int64] = []
        query(queryStatementString: selectQuery(table: TABLE_NAME_WORD, columns: [COLUMN_ID], whereClause: COLUMN_LANGUAGE + "= ?", distinct: true), statmentModifier: {statement in
            sqlite3_bind_text(statement, 1, (language as NSString).utf8String, -1, nil)
        }, rowParser: {statement in
            result.append(sqlite3_column_int64(statement, 0))
        })
        return result
    }
    
    func findWord(id : Int64) -> Word? {
        var words = getSqlForWordById(id: id)
        if (!words.isEmpty) {
            fetchTranslationsAndTopics(words: &words, languages: nil, includeTopics: true, language: nil)
            return words[0]
        }
        return nil
    }
    
    func getSqlForWordById(id: Int64) -> [Word] {
        var words: [Word] = []
        query(queryStatementString: selectQuery(table: TABLE_NAME_WORD, columns: wordColumns(), whereClause: COLUMN_ID + "= ?", distinct: true), statmentModifier: {statement in
            sqlite3_bind_int64(statement, 1, id)
        }, rowParser: {statement in
            mapWordFromSql(queryStatement: statement, words: &words)
        })
        return words
    }
    
    func updateWord(word: Word) -> Bool {
        let columns = [COLUMN_LANGUAGE, WORD_COLUMN_WORD, WORD_COLUMN_ADDITIONAL_INFORMATION, WORD_COLUMN_ARTICLE, WORD_COLUMN_KNOWLEDGE]
        let updateStatementString = updateQuery(tableName: TABLE_NAME_WORD, columns: columns, whereClause: COLUMN_ID + " = ?")
        return update(updateStatementString: updateStatementString, statmentModifier: { statement in
            sqlite3_bind_text(statement, 1, (word.language as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 2, (word.word as NSString).utf8String, -1, nil)
            bindNullOrTextValue(insertStatement: statement, index: 3, value: word.additionalInformation)
            bindNullOrTextValue(insertStatement: statement, index: 4, value: word.article)
            sqlite3_bind_double(statement, 5, word.knowledge)
            sqlite3_bind_int64(statement, 6, word.id!)
        })
    }
    
    func updateTopic(topic: Topic) -> Bool {
        let columns = [COLUMN_LANGUAGE, TOPIC_COLUMN_LEVEL, TOPIC_COLUMN_ROOT_ID, TOPIC_COLUMN_NAME]
        let updateStatementString = updateQuery(tableName: TABLE_NAME_TOPIC, columns: columns, whereClause: COLUMN_ID + " = ?")
        return update(updateStatementString: updateStatementString, statmentModifier: { statement in
            sqlite3_bind_text(statement, 1, (topic.language as NSString).utf8String, -1, nil)
            sqlite3_bind_int(statement, 2, topic.level)
            if topic.root != nil {
                sqlite3_bind_int64(statement, 3, topic.root!.id!)
            } else {
                sqlite3_bind_null(statement, 3)
            }
            sqlite3_bind_text(statement, 4, (topic.name as NSString).utf8String, -1, nil)
            sqlite3_bind_int64(statement, 5, topic.id!)
        })
    }
    
    func updateTranslation(translation: Translation) -> Bool {
        let columns = [COLUMN_LANGUAGE, TRANSLATION_COLUMN_TRANSLATION]
        let updateStatementString = updateQuery(tableName: TABLE_NAME_TRANSLATION, columns: columns, whereClause: COLUMN_ID + " = ?")
        return update(updateStatementString: updateStatementString, statmentModifier: { statement in
            sqlite3_bind_text(statement, 1, (translation.language as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 2, (translation.translation as NSString).utf8String, -1, nil)
            sqlite3_bind_int64(statement, 3, translation.id!)
        })
        
    }
    
    func deleteTranslation(id: Int64) -> Bool {
        return delete(deleteStatementString: deleteQuery(tableName: TABLE_NAME_TRANSLATION, whereClause: COLUMN_ID + " = ?"), statmentModifier: { statement in
            sqlite3_bind_int64(statement, 1, id)
        })
    }
    
    // func encodeToString(data:[String:AnyObject]) -> String {
    // let jsonEncoder = JSONEncoder()
    // let jsonData = try jsonEncoder.encode(data)
    // return String(data: jsonData, encoding: String.Encoding.utf8)
    // }
    
    
    func insertConfigurationPreset(name: String, data:[String:AnyObject]) {
        
        let columns = [COLUMN_ID, CONFIGURATION_PRESET_DATA]
        
        insert(insertStatementString: insertQuery(tableName: TABLE_NAME_CONFIGURATION_PRESET, columns: columns), statmentModifier: { statement in
            sqlite3_bind_text(statement, 1, (name as NSString).utf8String, -1, nil)
            // sqlite3_bind_text(statement, 2, (encodeToString(data: data) as NSString).utf8String, -1, nil)
        })
        // guard book.image.withUnsafeBytes({ bufferPointer -> Int32 in
        // sqlite3_bind_blob(statement, 5, bufferPointer.baseAddress, Int32(book.image.count), SQLITE_TRANSIENT)
        // }) == SQLITE_OK else {
        // throw SQLiteError.bind(message: errorMessage)
        // }
    }
    
    func updateConfigurationPreset(name: String, data:[String:AnyObject]) -> Bool {
        let columns = [CONFIGURATION_PRESET_DATA]
        return update(updateStatementString: updateQuery(tableName: TABLE_NAME_CONFIGURATION_PRESET, columns: columns, whereClause: COLUMN_ID + " = ?"), statmentModifier: { statement in
            // sqlite3_bind_text(statement, 1, (encodeToString(data: data) as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 2, (name as NSString).utf8String, -1, nil)
        })
    }
    
    func deleteConfigurationPreset(name: String) -> Bool {
        return delete(deleteStatementString: deleteQuery(tableName: TABLE_NAME_CONFIGURATION_PRESET, whereClause: COLUMN_ID + " = ?"), statmentModifier: { statement in
            sqlite3_bind_text(statement, 1, (name as NSString).utf8String, -1, nil)
        })
    }
    
    func getConfigurationPreset(name: String) -> [String:AnyObject]? {
        let queryStatementString = selectQuery(table: TABLE_NAME_CONFIGURATION_PRESET, columns: [CONFIGURATION_PRESET_DATA], whereClause: COLUMN_ID + "= ?", distinct: true)
        var result: [String:AnyObject]? = nil
        query(queryStatementString: queryStatementString, statmentModifier: { statement in
            sqlite3_bind_text(statement, 1, (name as NSString).utf8String, -1, nil)
        }, rowParser: { statement in
            
            // result = sqlite3_column_blob(statement, 1)
        }, exitOnFirst: true)
        return result
    }
    
    func getConfigurationPresetNames() -> [String] {
        let queryStatementString = selectQuery(table: TABLE_NAME_CONFIGURATION_PRESET, columns: [COLUMN_ID], whereClause: nil, distinct: true)
        var result: [String] = []
        query(queryStatementString: queryStatementString, statmentModifier: nil, rowParser: { statement in
            result.append(String(describing: String(cString: sqlite3_column_text(statement, 1))))
        })
        return result
    }
    
}

