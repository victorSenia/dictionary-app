//
//  WordMatcher.swift
//  dictionary
//
//  Created by New on 24.07.2024.
//

import Foundation
import SwiftUI

struct WordMatcherView: View {
    
    @State var selected: WordMatcherElement?
    @ObservedObject private var wordMatcherState = WordMatcherState()
    var body: some View {
        HStack {
            if wordMatcherState.elements.count == 2 {
                VStack {
                    ForEach(0..<wordMatcherState.elements[0].count, id: \.self) {index in
                        ElementView(action: selectElement, wordMatcherElement: wordMatcherState.elements[0][index])
                    }
                }
                VStack(spacing: 10) {
                    ForEach(0..<wordMatcherState.elements[1].count, id: \.self) {index in
                        ElementView(action: selectElement, wordMatcherElement: wordMatcherState.elements[1][index])
                    }
                }
            }
        }
        .padding()
        .contentShape(Rectangle())
        .gesture(DragGesture(minimumDistance: 10, coordinateSpace: .local)
                    .onEnded { value in
            let horizontalAmount = value.translation.width
            let verticalAmount = value.translation.height
            
            if abs(horizontalAmount) > abs(verticalAmount) {
                if horizontalAmount < 0 {
                    fillElements()
                }
                //                            print(horizontalAmount < 0 ? "left swipe" : "right swipe")
            } else {
                //                            print(verticalAmount < 0 ? "up swipe" : "down swipe")
            }
        })
        .onAppear(perform: fillElements)
    }
}

struct ElementView: View {
    let action : (_: WordMatcherElement) -> Void
    @ObservedObject var wordMatcherElement : WordMatcherElement
    var body: some View {
        Button {
            action(wordMatcherElement)
        } label: {
            Text(wordMatcherElement.type == .translation || settings.wordMatcherShowWord ? wordMatcherElement.text : "")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.bordered)
        .foregroundColor(wordMatcherElement.selected ? Color.green : Color.primary)
        .opacity(wordMatcherElement.hidden ? 0 : 1)
    }
}
private extension WordMatcherView {
    func fillElements() {
        wordMatcherState.elements = [
            [WordMatcherElement](repeating: WordMatcherElement(), count: settings.wordMatcherWordsQuantity),
            [WordMatcherElement](repeating: WordMatcherElement(), count: settings.wordMatcherWordsQuantity)]
        for i in 0..<settings.wordMatcherWordsQuantity {
            let word = player.words[Int.random(in: 0..<player.words.count)]
            wordMatcherState.elements[0][i] = WordMatcherElement(type: .word, text: word.word, language: word.language)
            let translation = word.translations[Int.random(in: 0..<word.translations.count)]
            wordMatcherState.elements[1][i] = WordMatcherElement(type: .translation, text: translation.translation, language: translation.language, matches: wordMatcherState.elements[0][i])
            wordMatcherState.elements[0][i].matches = wordMatcherState.elements[1][i]
        }
        wordMatcherState.elements[1].shuffle()
    }
    
    func selectElement(element:WordMatcherElement) {
        if element.type == .word {
            player.toSpeechNoResult(language: element.language, text: element.text)
        }
        if selected == nil {
            element.selected = true
            selected = element
        } else if selected!.type == element.type {
            selected!.selected = false
            element.selected = true
            selected = element
        } else {
            if selected!.matches === element {
                selected!.hidden = true
                selected = nil
                element.hidden = true
                for e in wordMatcherState.elements[0] {
                    if !e.hidden {
                        return
                    }
                }
                fillElements()
            }
            else {
                selected!.selected = false
                selected = nil
            }
            
        }
    }
}

class WordMatcherState: ObservableObject {
    @Published var elements: [[WordMatcherElement]] = []
}

enum ElementType: Hashable {
    case word, translation
}
class WordMatcherElement: ObservableObject {
    var type: ElementType
    @Published var text: String
    @Published var selected: Bool = false
    @Published var hidden: Bool = false
    var language: String
    var matches: WordMatcherElement?
    init(type: ElementType = .word, text: String = "", language: String = "", matches: WordMatcherElement? = nil) {
        self.type = type
        self.text = text
        self.language = language
        self.matches = matches
    }
}
