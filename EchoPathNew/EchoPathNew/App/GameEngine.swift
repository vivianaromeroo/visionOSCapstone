import SwiftUI

@Observable
class GameEngine {
    let animal: String

    let sentences: [[[[String]]]]
    let lessonNames: [String]
    let unitName: String = "My Animal Friend"

    var currentUnit: Int = 0
    var currentLesson: Int = 0
    var currentLevel: Int = 0
    var droppedWords: [String?]
    var availableWords: [String]
    var currentStep: Int
    var feedback: String

    // Convenience
    var currentSentence: [String] {
        guard currentUnit >= 0 && currentUnit < sentences.count,
              currentLesson >= 0 && currentLesson < sentences[currentUnit].count,
              currentLevel >= 0 && currentLevel < sentences[currentUnit][currentLesson].count else {
            return []
        }
        return sentences[currentUnit][currentLesson][currentLevel]
    }
    
    var currentLessonName: String {
        guard currentLesson >= 0 && currentLesson < lessonNames.count else {
            return "Lesson"
        }
        return lessonNames[currentLesson]
    }
    
    var isLastLevelInLesson: Bool {
        guard currentUnit >= 0 && currentUnit < sentences.count,
              currentLesson >= 0 && currentLesson < sentences[currentUnit].count else {
            return true
        }
        return currentLevel >= sentences[currentUnit][currentLesson].count - 1
    }
    
    var isLastLessonInUnit: Bool {
        guard currentUnit >= 0 && currentUnit < sentences.count else {
            return true
        }
        return currentLesson >= sentences[currentUnit].count - 1
    }

    init(animal: String) {
        self.animal = animal
        
        let lesson1: [[String]] = [
            [animal] as [String],
            ["Big", animal.lowercased()],
            ["The", "big", animal.lowercased(), "runs"],
            ["The", "big", animal.lowercased(), "runs", "and", "eats"],
            ["The", "big", animal.lowercased(), "runs", "and", "eats", "a", "bone"]
        ]
        
        let lesson2: [[String]] = [
            [animal] as [String],
            ["Happy", animal.lowercased()],
            ["The", "happy", animal.lowercased(), "jumps"],
            ["The", "happy", animal.lowercased(), "jumps", "and", "wags", "tail"],
            ["The", "happy", animal.lowercased(), "jumps", "and", "wags", "tail", "fast"]
        ]
        
        let lesson3: [[String]] = [
            [animal] as [String],
            ["Small", animal.lowercased()],
            ["The", "small", animal.lowercased(), "plays"],
            ["The", "small", animal.lowercased(), "plays", "with", "a", "ball"],
            ["The", "small", animal.lowercased(), "plays", "with", "a", "ball", "and", "toy"]
        ]
        
        self.sentences = [[lesson1, lesson2, lesson3]]
        self.lessonNames = ["Basic Actions", "Emotions", "Interactions"]
        
        self.currentUnit = 0
        self.currentLesson = 0
        self.currentLevel = 0
        
        let initial = sentences[0][0][0]
        self.droppedWords = Array(repeating: nil, count: initial.count)
        self.availableWords = initial.shuffled()
        self.currentStep = 0
        self.feedback = ""
    }

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

    func nextLevel() {
        guard currentUnit >= 0 && currentUnit < sentences.count else {
            return
        }
        guard currentLesson >= 0 && currentLesson < sentences[currentUnit].count else {
            return
        }
        
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
        else if currentUnit < sentences.count - 1 {
            currentUnit += 1
            currentLesson = 0
            currentLevel = 0
            resetLevel()
        }
    }
    
    var hasNext: Bool {
        guard currentUnit >= 0 && currentUnit < sentences.count else {
            return false
        }
        guard currentLesson >= 0 && currentLesson < sentences[currentUnit].count else {
            return false
        }
        
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

    func resetLevel() {
        let sentence = currentSentence
        guard !sentence.isEmpty else {
            droppedWords = []
            availableWords = []
            currentStep = 0
            feedback = ""
            return
        }
        droppedWords = Array(repeating: nil, count: sentence.count)
        availableWords = sentence.shuffled()
        currentStep = 0
        feedback = ""
    }
}
