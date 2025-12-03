//
//  GameEngine.swift
//  EchoPathNew
//
//  Created by Jose Blanco on 4/24/25.
//

// MARK: - GameEngine.swift
import SwiftUI

/// A pure game engine with observable state using the @Observable macro
@Observable
class GameEngine {
    let animal: String

    // MARK: - Data Structure
    // Structure: [Unit][Lesson][Level] -> [String] (sentence words)
    // For now, we have 1 unit, so this is [[Lesson][Level] -> [String]]
    // But we'll structure it as [Unit][Lesson][Level] for future expansion
    let sentences: [[[[String]]]]
    let lessonNames: [String]  // Names for each lesson
    let unitName: String = "My Animal Friend"

    // MARK: - State (all published automatically)
    var currentUnit: Int = 0  // Currently always 0 (Unit 1)
    var currentLesson: Int = 0  // 0-2 (3 lessons)
    var currentLevel: Int = 0  // 0-4 (5 levels per lesson)
    var droppedWords: [String?]
    var availableWords: [String]
    var currentStep: Int
    var feedback: String

    // Convenience
    var currentSentence: [String] { 
        sentences[currentUnit][currentLesson][currentLevel]
    }
    
    var currentLessonName: String {
        lessonNames[currentLesson]
    }
    
    var isLastLevelInLesson: Bool {
        currentLevel >= sentences[currentUnit][currentLesson].count - 1
    }
    
    var isLastLessonInUnit: Bool {
        currentLesson >= sentences[currentUnit].count - 1
    }

    // MARK: - Initialization
    init(animal: String) {
        self.animal = animal
        
        // Build sentences structure: Unit 1 -> 3 Lessons -> 5 Levels each
        // Lesson 1: Basic Actions
        let lesson1: [[String]] = [
            [animal] as [String],  // Level 1
            ["Big", animal.lowercased()],  // Level 2
            ["The", "big", animal.lowercased(), "runs"],  // Level 3
            ["The", "big", animal.lowercased(), "runs", "and", "eats"],  // Level 4
            ["The", "big", animal.lowercased(), "runs", "and", "eats", "a", "bone"]  // Level 5
        ]
        
        // Lesson 2: Emotions
        let lesson2: [[String]] = [
            [animal] as [String],  // Level 1
            ["Happy", animal.lowercased()],  // Level 2
            ["The", "happy", animal.lowercased(), "jumps"],  // Level 3
            ["The", "happy", animal.lowercased(), "jumps", "and", "wags", "tail"],  // Level 4
            ["The", "happy", animal.lowercased(), "jumps", "and", "wags", "tail", "fast"]  // Level 5
        ]
        
        // Lesson 3: Interactions
        let lesson3: [[String]] = [
            [animal] as [String],  // Level 1
            ["Small", animal.lowercased()],  // Level 2
            ["The", "small", animal.lowercased(), "plays"],  // Level 3
            ["The", "small", animal.lowercased(), "plays", "with", "a", "ball"],  // Level 4
            ["The", "small", animal.lowercased(), "plays", "with", "a", "ball", "and", "toy"]  // Level 5
        ]
        
        // Unit 1 contains all 3 lessons
        // Structure: [Unit][Lesson][Level] -> [String]
        self.sentences = [[lesson1, lesson2, lesson3]]
        self.lessonNames = ["Basic Actions", "Emotions", "Interactions"]
        
        // Start at Unit 1, Lesson 1, Level 1 (all 0-indexed)
        self.currentUnit = 0
        self.currentLesson = 0
        self.currentLevel = 0
        
        // Use literal indices since properties aren't fully initialized yet
        let initial = sentences[0][0][0]
        self.droppedWords = Array(repeating: nil, count: initial.count)
        self.availableWords = initial.shuffled()
        self.currentStep = 0
        self.feedback = ""
    }

    // MARK: - Game Logic
    /// Handles a dropped (or selected) word into the given slot index
    func handleDrop(_ word: String, at index: Int) {
        guard index == currentStep else { return }
        if word == currentSentence[index] {
            droppedWords[index] = word
            availableWords.removeAll { $0 == word }
            feedback = "Correct!"
            currentStep += 1
        } else {
            feedback = "Incorrect. Try again."
        }
    }

    /// Advance to the next level (if any)
    /// Progresses: Level -> Lesson -> Unit
    func nextLevel() {
        // Check if we can advance within the current lesson
        if currentLevel < sentences[currentUnit][currentLesson].count - 1 {
            currentLevel += 1
            resetLevel()
        }
        // Check if we can advance to the next lesson
        else if currentLesson < sentences[currentUnit].count - 1 {
            currentLesson += 1
            currentLevel = 0
            resetLevel()
        }
        // Check if we can advance to the next unit (future expansion)
        else if currentUnit < sentences.count - 1 {
            currentUnit += 1
            currentLesson = 0
            currentLevel = 0
            resetLevel()
        }
        // Otherwise, we're at the end
    }
    
    /// Check if there's a next level/lesson/unit available
    var hasNext: Bool {
        if currentLevel < sentences[currentUnit][currentLesson].count - 1 {
            return true
        }
        if currentLesson < sentences[currentUnit].count - 1 {
            return true
        }
        if currentUnit < sentences.count - 1 {
            return true
        }
        return false
    }

    /// Reset the current level state
    func resetLevel() {
        droppedWords = Array(repeating: nil, count: currentSentence.count)
        availableWords = currentSentence.shuffled()
        currentStep = 0
        feedback = ""
    }
}
