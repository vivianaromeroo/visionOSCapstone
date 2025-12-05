# EchoPath - visionOS Educational App

EchoPath is an immersive educational application built for visionOS that helps children learn sentence construction through interactive 3D gameplay. Children build sentences by dragging and dropping words while their chosen animal friend comes to life with animations.

## Features

### 🎮 Interactive Learning
- **Sentence Building Game**: Drag and drop words to construct sentences
- **Progressive Difficulty**: 3 lessons with 5 levels each, gradually increasing in complexity
- **Real-time Feedback**: Immediate feedback on correct and incorrect word placements

### 🐾 Animal Companions
- **Animal Selection**: Choose from Dog, Cat, or Horse
- **3D Animations**: Watch your animal friend perform unique animations when completing levels
- **Immersive Experience**: Full 3D environment using RealityKit

### 📚 Educational Content
- **Lesson 1 - Basic Actions**: Learn simple sentences with action words
- **Lesson 2 - Emotions**: Explore emotional vocabulary and expressions
- **Lesson 3 - Interactions**: Discover how words interact in sentences

### 🎯 User Experience
- **Tutorial Mode**: Optional tutorial video to help new users get started
- **Personalized Welcome**: Greeting with child's name and lesson information
- **Progress Tracking**: Visual indicators for lesson and level completion
- **Accessibility**: Support for various user preferences and settings

## Architecture

### Core Components

- **AppModel**: Central state management using `@Observable` macro
- **GameEngine**: Pure game logic engine managing lessons, levels, and sentence progression
- **AuthService**: Handles user authentication and API communication
- **AnimalAnimationHelper**: Manages smooth 3D animations for animal entities

### View Hierarchy

```
ContentView (Start Screen)
  └── LoginView
      └── WelcomeView
          └── AnimalPickerView
              ├── TutorialView (optional)
              └── GameView
                  └── LessonCompleteView
```

## Technologies

- **SwiftUI**: Modern declarative UI framework
- **RealityKit**: 3D graphics and spatial computing
- **AVKit**: Video playback for tutorials
- **Combine**: Reactive programming for state management
- **visionOS**: Apple's spatial computing platform

## Requirements

- **Xcode**: 15.0 or later
- **visionOS SDK**: 1.0 or later
- **Swift**: 6.0 or later
- **Device**: Apple Vision Pro (or visionOS Simulator)

## Setup Instructions

### 1. Clone the Repository

```bash
git clone <repository-url>
cd visionOSCapstone
```

### 2. Open in Xcode

```bash
open EchoPathNew/EchoPathNew.xcodeproj
```

### 3. Configure API Endpoint

The app connects to an authentication API. Update the base URL in `AuthService.swift` if needed:

```swift
private let baseURL = "https://echopathapi.ejvapps.online/api/auth/child-access/"
```

### 4. Build and Run

1. Select the `EchoPathNew` scheme
2. Choose a visionOS device or simulator
3. Press `Cmd + R` to build and run

## Project Structure

```
EchoPathNew/
├── App/
│   ├── AppModel.swift              # App-wide state management
│   ├── AuthService.swift           # Authentication API service
│   ├── GameEngine.swift            # Game logic and progression
│   ├── AnimalAnimationHelper.swift # 3D animation utilities
│   ├── Models.swift                # Data models
│   └── EchoPathNewApp.swift        # App entry point
├── Views/
│   ├── ContentView.swift           # Start screen
│   ├── LoginView.swift             # User authentication
│   ├── WelcomeView.swift           # Welcome screen
│   ├── AnimalPickerView.swift      # Animal selection
│   ├── TutorialView.swift          # Tutorial video player
│   ├── GameView.swift              # Main game interface
│   ├── LessonCompleteView.swift    # Completion screen
│   └── ImmersiveView.swift         # Immersive space
├── Resources/
│   ├── EchoPathTheme.swift         # Design system
│   └── Tutorial-VEED.mp4           # Tutorial video
├── 3DAssets/
│   ├── Cat.usdz                    # Cat 3D model
│   ├── Dog.usdz                    # Dog 3D model
│   └── Horse.usdz                  # Horse 3D model
└── Assets/
    └── Assets.xcassets/            # Images and icons
```

## API Integration

### Authentication

The app uses a REST API for user authentication:

**Endpoint**: `POST /api/auth/child-access/`

**Request Body**:
```json
{
  "short_id": "ABC123",
  "date_of_birth": "YYYY-MM-DD"
}
```

**Response**:
```json
{
  "child": {
    "id": "string",
    "short_id": "string",
    "first_name": "string",
    "last_name": "string",
    "animal_preference": "string",
    "current_path": "string"
  },
  "preferences": {
    "volume": 0,
    "subtitles": false,
    "speech_input_enabled": false,
    "animation_intensity": "string",
    "color_contrast": "string",
    "music_enabled": false,
    "voice_speed": "string"
  },
  "message": "string",
  "unit_name": "string",
  "lesson_name": "string"
}
```

## Game Flow

1. **Login**: Child enters ID and date of birth
2. **Welcome**: Personalized greeting with lesson information
3. **Animal Selection**: Choose favorite animal (Dog, Cat, or Horse)
4. **Tutorial** (optional): Watch tutorial video if enabled
5. **Gameplay**: 
   - Build sentences by dragging words to slots
   - Complete levels to unlock animal animations
   - Progress through lessons
6. **Completion**: Celebrate lesson completion with animated animal

## Design System

The app uses a cohesive pastel color palette defined in `EchoPathTheme.swift`:

- **Primary Colors**: Pastel Blue, Pastel Pink, Pastel Purple
- **Accent Colors**: Lavender, Sky Blue, Warm Pink
- **Typography**: Rounded system fonts with custom sizing
- **Components**: Custom button styles, text fields, and cards

## Development

### Adding New Lessons

To add a new lesson, modify `GameEngine.swift`:

1. Add lesson data to the `sentences` array
2. Add lesson name to `lessonNames` array
3. Create corresponding animations in `GameView.swift`

### Adding New Animals

1. Add `.usdz` model file to `3DAssets/` folder
2. Add animal name to `animals` array in `AnimalPickerView.swift`
3. Update animal emoji mapping in `WelcomeView.swift`

### Animation System

Animations are defined per lesson and level in `GameView.swift`. Each animation:
- Uses `AnimalAnimationHelper` for smooth transforms
- Combines position, rotation, and scale changes
- Respects the base side profile rotation

## Testing

Unit tests are available in `EchoPathNewTests/GameEngineTests.swift`. Run tests with:

```bash
Cmd + U
```

## Contributing

1. Create a feature branch
2. Make your changes
3. Ensure code follows existing style
4. Test on visionOS device or simulator
5. Submit a pull request

## License

[Add your license information here]

## Credits

- 3D Models: Custom animal models in USDZ format
- Design: Custom pastel theme and UI components
- API: EchoPath authentication service

## Support

For issues or questions, please open an issue in the repository.
