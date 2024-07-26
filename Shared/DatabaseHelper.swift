//
// SQLiteAdapter.swift
// dictionary
//
// Created by New on 28.06.2024.
//

import Foundation
import SQLite3

typealias StatmentModifier = (_ statement: OpaquePointer?) -> Void

class DatabaseHelper{
    let CURENT_VERSION:Int64 = 1
    public var userVersion: Int64 {
        get {
            var version:Int64 = 0
            query(queryStatementString: "PRAGMA user_version", statmentModifier: nil, rowParser: { queryStatement in
                version = sqlite3_column_int64(queryStatement, 0)
            }, exitOnFirst: true)
            return version
        }
        set { execSQL(sql: "PRAGMA user_version = \(newValue)") }
            }
    init(){
        db = openDatabase()
        if ( userVersion < CURENT_VERSION){
            onUpgrade(oldVersion:userVersion)
            userVersion = CURENT_VERSION
        }
    }
    
    let dataPath: String = "dictionary"
    var db: OpaquePointer?
    
    // Create DB
    func openDatabase()->OpaquePointer?{
        let filePath = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent(dataPath)
        NSLog(filePath.absoluteString)
        var db: OpaquePointer? = nil
        if sqlite3_open(filePath.path, &db) != SQLITE_OK{
            NSLog("Cannot open DB.")
            return nil
        }
        else{
            // print("DB successfully created.")
            return db
        }
    }
    
    // Create users table
    func execSQL(sql: String) {
        
        var executeStatement: OpaquePointer? = nil
        
        if sqlite3_prepare_v2(db, sql, -1, &executeStatement, nil) == SQLITE_OK {
            if sqlite3_step(executeStatement) == SQLITE_DONE {
                // print("Sql executed successfully.")
            } else {
                NSLog("SQL failed." + sql)
            }
        } else {
            NSLog("SQL failed." + sql)
        }
        
        sqlite3_finalize(executeStatement)
    }
    var DATABASE_NAME = "dictionary.db";
    var TABLE_NAME_TOPIC = "topic";
    var TABLE_NAME_TRANSLATION = "translation";
    var TABLE_NAME_WORD = "word";
    var TABLE_NAME_WORD_TOPIC = "word_topic";
    var TABLE_NAME_CONFIGURATION_PRESET = "configuration_preset";
    var COLUMN_ID = "id";
    var COLUMN_LANGUAGE = "language";
    var WORD_COLUMN_WORD = "word";
    var WORD_COLUMN_ADDITIONAL_INFORMATION = "additional_information";
    var WORD_COLUMN_ARTICLE = "article";
    var WORD_COLUMN_KNOWLEDGE = "knowledge";
    
    var TOPIC_COLUMN_NAME = "name";
    var TOPIC_COLUMN_LEVEL = "level";
    var TOPIC_COLUMN_ROOT_ID = "root";
    
    var TRANSLATION_COLUMN_WORD_ID = "word_id";
    var TRANSLATION_COLUMN_TRANSLATION = "translation";
    
    var CONFIGURATION_PRESET_DATA = "data";
    
    
    func dropTables() {
        execSQL(sql: "DROP TABLE IF EXISTS " + TABLE_NAME_WORD_TOPIC);
        execSQL(sql: "DROP TABLE IF EXISTS " + TABLE_NAME_TRANSLATION);
        execSQL(sql: "DROP TABLE IF EXISTS " + TABLE_NAME_WORD);
        execSQL(sql: "DROP TABLE IF EXISTS " + TABLE_NAME_TOPIC);
        execSQL(sql: "DROP TABLE IF EXISTS " + TABLE_NAME_CONFIGURATION_PRESET);
    }
    
    func onUpgrade(oldVersion: Int64) {
        dropTables();
        onCreate();
    }
    
    func onCreate() {
        execSQL(sql: "CREATE TABLE " + TABLE_NAME_TOPIC + " (" + COLUMN_ID + " INTEGER PRIMARY KEY AUTOINCREMENT, " + COLUMN_LANGUAGE + " TEXT NOT NULL, " +
                TOPIC_COLUMN_NAME + " TEXT NOT NULL, " + TOPIC_COLUMN_LEVEL + " INTEGER, " + TOPIC_COLUMN_ROOT_ID + " INTEGER);");
        execSQL(sql: "CREATE TABLE " + TABLE_NAME_WORD + " (" + COLUMN_ID + " INTEGER PRIMARY KEY AUTOINCREMENT, " + COLUMN_LANGUAGE + " TEXT NOT NULL, " + WORD_COLUMN_WORD + " TEXT NOT NULL, " +
                WORD_COLUMN_ADDITIONAL_INFORMATION + " TEXT, " + WORD_COLUMN_ARTICLE + " TEXT, " + WORD_COLUMN_KNOWLEDGE + " REAL);");
        execSQL(sql: "CREATE TABLE " + TABLE_NAME_TRANSLATION + " (" + COLUMN_ID + " INTEGER PRIMARY KEY AUTOINCREMENT, " + COLUMN_LANGUAGE + " TEXT NOT NULL, " +
                TRANSLATION_COLUMN_TRANSLATION + " TEXT NOT NULL, " + TRANSLATION_COLUMN_WORD_ID + " INTEGER," +
                "CONSTRAINT fk_word FOREIGN KEY (" + TRANSLATION_COLUMN_WORD_ID + ") REFERENCES " + TABLE_NAME_WORD + "(" + COLUMN_ID + ")" +
                ");");
        execSQL(sql: "CREATE TABLE " + TABLE_NAME_WORD_TOPIC + " (" + TRANSLATION_COLUMN_WORD_ID + " INTEGER, " + COLUMN_ID + " INTEGER, " +
                "CONSTRAINT fk_topic FOREIGN KEY (" + TRANSLATION_COLUMN_WORD_ID + ") REFERENCES " + TABLE_NAME_TRANSLATION + "(" + COLUMN_ID + ")," +
                "CONSTRAINT fk_word FOREIGN KEY (" + COLUMN_ID + ") REFERENCES " + TABLE_NAME_WORD + "(" + COLUMN_ID + ")" +
                ");");
         execSQL(sql: "CREATE TABLE " + TABLE_NAME_CONFIGURATION_PRESET + " (" + COLUMN_ID + " TEXT PRIMARY KEY, " + CONFIGURATION_PRESET_DATA + " BLOB" + ");");
        execSQL(sql: "CREATE UNIQUE INDEX " + TABLE_NAME_TOPIC + "_unique1 " + " ON " + TABLE_NAME_TOPIC + " (" + COLUMN_LANGUAGE + ", " + TOPIC_COLUMN_LEVEL + ", " + TOPIC_COLUMN_ROOT_ID + ", " + TOPIC_COLUMN_NAME + ");");
        execSQL(sql: "CREATE UNIQUE INDEX " + TABLE_NAME_WORD + "_unique1 " + " ON " + TABLE_NAME_WORD + " (" + COLUMN_LANGUAGE + ", " + WORD_COLUMN_WORD + ", " + WORD_COLUMN_ARTICLE + ", " + WORD_COLUMN_ADDITIONAL_INFORMATION + ");");
        execSQL(sql: "CREATE UNIQUE INDEX " + TABLE_NAME_TRANSLATION + "_unique1 " + " ON " + TABLE_NAME_TRANSLATION + " (" + TRANSLATION_COLUMN_WORD_ID + ", " + COLUMN_LANGUAGE + ", " + TRANSLATION_COLUMN_TRANSLATION + ");");
        execSQL(sql: "CREATE UNIQUE INDEX " + TABLE_NAME_WORD_TOPIC + "_unique1 " + " ON " + TABLE_NAME_WORD_TOPIC + " (" + COLUMN_ID + ", " + TRANSLATION_COLUMN_WORD_ID + ");");
    }
    
    func insert(insertStatementString: String, statmentModifier: StatmentModifier) -> Int64{
        var insertStatement: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, insertStatementString, -1, &insertStatement, nil) == SQLITE_OK {
            statmentModifier(insertStatement)
            
            if sqlite3_step(insertStatement) == SQLITE_DONE {
                // print("Inserted successfully." + insertStatementString)
                sqlite3_finalize(insertStatement)
                return 0
            } else {
                NSLog("Could not add.")
                return -1
            }
        } else {
            NSLog("INSERT statement is failed.")
            return -1
        }
    }
    
    func update(updateStatementString: String, statmentModifier: StatmentModifier) -> Bool {
        var insertStatement: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, updateStatementString, -1, &insertStatement, nil) == SQLITE_OK {
            statmentModifier(insertStatement)
            
            if sqlite3_step(insertStatement) == SQLITE_DONE {
                // print("Updated successfully.")
                sqlite3_finalize(insertStatement)
                return true
            } else {
                NSLog("Could not update.")
                return false
            }
        } else {
            NSLog("UPDATE statement is failed.")
            return false
        }
    }
    
    func delete(deleteStatementString: String, statmentModifier: StatmentModifier) -> Bool {
        var deleteStatement: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, deleteStatementString, -1, &deleteStatement, nil) == SQLITE_OK {
            statmentModifier(deleteStatement)
            if sqlite3_step(deleteStatement) == SQLITE_DONE {
                // print("Deleted successfully.")
                sqlite3_finalize(deleteStatement)
                return true
            } else {
                NSLog("Could not delete.")
                return false
            }
        } else {
            NSLog("DELETE statement is failed.")
            return false
        }
    }
    func query(queryStatementString: String, statmentModifier: StatmentModifier?, rowParser: StatmentModifier, exitOnFirst: Bool = false) {
        var queryStatement: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
            if statmentModifier != nil {
                statmentModifier!(queryStatement)
            }
            while sqlite3_step(queryStatement) == SQLITE_ROW {
                rowParser(queryStatement)
                if exitOnFirst {
                    break
                }
            }
        } else {
            NSLog("SELECT statement is failed.")
        }
        sqlite3_finalize(queryStatement)
    }
}
