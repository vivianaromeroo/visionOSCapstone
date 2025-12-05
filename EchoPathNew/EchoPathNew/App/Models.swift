import Foundation

struct Child: Codable {
    let id: String
    let shortId: String
    let firstName: String
    let lastName: String
    let animalPreference: String?
    let currentPath: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case shortId = "short_id"
        case firstName = "first_name"
        case lastName = "last_name"
        case animalPreference = "animal_preference"
        case currentPath = "current_path"
    }
}

struct Preferences: Codable {
    let volume: Int
    let subtitles: Bool
    let speechInputEnabled: Bool
    let animationIntensity: String
    let colorContrast: String
    let musicEnabled: Bool
    let voiceSpeed: String
    
    enum CodingKeys: String, CodingKey {
        case volume
        case subtitles
        case speechInputEnabled = "speech_input_enabled"
        case animationIntensity = "animation_intensity"
        case colorContrast = "color_contrast"
        case musicEnabled = "music_enabled"
        case voiceSpeed = "voice_speed"
    }
}

struct LoginResponse: Codable {
    let child: Child
    let preferences: Preferences
    let message: String
    let unitName: String?
    let lessonName: String?
    
    enum CodingKeys: String, CodingKey {
        case child
        case preferences
        case message
        case unitName = "unit_name"
        case lessonName = "lesson_name"
    }
}

struct LoginRequest: Codable {
    let shortId: String
    let dateOfBirth: String
    
    enum CodingKeys: String, CodingKey {
        case shortId = "short_id"
        case dateOfBirth = "date_of_birth"
    }
}

