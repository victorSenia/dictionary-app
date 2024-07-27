//
//  dictionaryApp.swift
//  Shared
//
//  Created by New on 23.06.2024.
//

import SwiftUI

let databaseManager = DatabaseManager()
let databaseWordProvider = DatabaseWordProvider()
let player = Player(wordProvider: databaseWordProvider)
let criteriaHolder = CriteriaHolder()
let settings = Settings()

@main
struct dictionaryApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        //        Settings {
        //            SettingsView()
        //        }
    }
    
}
//https://github.com/Dougly/ViewsProgrammatically/blob/master/ViewsProgrammatically/ViewController.swift
