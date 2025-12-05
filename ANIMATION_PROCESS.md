# Animation Process Documentation

## Overview

The animation system in `GameView` uses transform-based animations (no rigging) to animate the animal model when a level is completed. The animal is hidden by default and only appears when all words in a sentence have been correctly placed.

## Key Components

### 1. Animal Model Setup

- **Location**: `GameView.swift` - `RealityView` make closure (lines 58-78)
- **Root Entity**: `animalRootEntity` - Contains the animal model and manages its transforms
- **Model Entity**: `animalEntity` - The actual 3D model loaded from `.usdz` file
- **Initial State**:
  - Position: `(0, -0.1, 0)` - Lowered slightly from center
  - Rotation: `-.pi / 2` around Y-axis - Side profile view (head toward right, feet down)
  - Scale: `(0, 0, 0)` - Hidden initially
- **Model Loading**: Loaded asynchronously in `loadAnimalModel()` function

### 2. Animation Trigger

**When animations play:**
- Animations trigger automatically when **all slots are filled** (sentence is complete)
- This is detected in `onChange(of: engine.currentStep)` modifier (lines 203-217)
- Condition: `isSentenceComplete && !hasPlayedCompletionAnimation && !showLessonComplete`

**Key State Variables:**
- `isSentenceComplete`: Computed property checking if `engine.currentStep == engine.currentSentence.count`
- `hasPlayedCompletionAnimation`: Boolean flag preventing animations from playing multiple times per level
- `showLessonComplete`: Boolean flag hiding animations when lesson complete screen is visible

**Animation Sequence:**
1. `hasPlayedCompletionAnimation` is set to `true`
2. `showAnimal()` is called to make the animal visible (scale animation from 0 to 1)
3. `playAnimation(for: level, lesson:)` is called with current level and lesson indices

### 3. Animal Visibility Management

**Show Animal** (`showAnimal()`, lines 618-629):
- Animates `animalRootEntity.scale` from `(0, 0, 0)` to `(1, 1, 1)`
- Duration: 0.5 seconds
- Uses `AnimalAnimationHelper.animateTransform()` for smooth interpolation

**Hide Animal** (`hideAnimal()`, lines 631-635):
- Immediately sets `animalRootEntity.scale` to `(0, 0, 0)`
- Called when:
  - Level changes (onChange of `engine.currentLevel`)
  - Lesson changes (onChange of `engine.currentLesson`)
  - Continuing to next lesson/level

### 4. Animation Routing

**Main Function**: `playAnimation(for level: Int, lesson: Int)` (lines 638-675)

**Routing Logic**: `performAnimation(for:level:lesson:animalRoot:animalModel:)` (lines 677-748)

The system routes to specific animations based on:
- **Lesson** (0-indexed): 0 = Basic Actions, 1 = Emotions, 2 = Interactions
- **Level** (0-indexed): 0-4 (5 levels per lesson)

**Animation Mapping:**

#### Lesson 1 — Basic Actions
- **Level 0**: `idleSwayAndBreathe()` - Idle (no animation, just waits)
- **Level 1**: `proudPose()` - Scale up to 1.1, hold, then reset
- **Level 2**: `runInPlace()` - Bounce in place (3 cycles)
- **Level 3**: `runAndEat()` - Run forward, pause briefly
- **Level 4**: `runEatAndShake()` - Run + eat, then playful Y-axis shake

#### Lesson 2 — Emotions
- **Level 0**: `idleSwayAndBreathe()` - Idle (no animation)
- **Level 1**: `happyBounceAndTilt()` - Happy bounce animation
- **Level 2**: `bigJump()` - Big jump (Y: 0 → 0.15 → 0)
- **Level 3**: `jumpAndWag()` - Jump + fast Y-axis wagging
- **Level 4**: `jumpFastWagAndHop()` - Jump + wag + small hop

#### Lesson 3 — Interactions
- **Level 0**: `idleSwayAndBreathe()` - Idle (no animation)
- **Level 1**: `smallHopAndShrink()` - Small hop + scale shrink (1 → 0.95 → 1)
- **Level 2**: `playBounces()` - 3 quick Y bounces
- **Level 3**: `moveForwardAndBounce()` - Move forward to "ball", bounce, then move back
- **Level 4**: `moveSpinAndHop()` - Move forward → 360° spin → hop

### 5. Animation Implementation

**Helper System**: `AnimalAnimationHelper` (separate file)

**Method**: `animateTransform(entity:targetTransform:duration:)`
- Uses manual interpolation with 60 steps per second
- Interpolates position, rotation (slerp), and scale
- Applies ease-in-out easing function
- Uses `Task.sleep()` for timing

**Key Features:**
- No rigging or skeletal animations
- All animations use transform manipulation (position, rotation, scale)
- Animations can target either `animalRootEntity` or `animalModel`
- Rotations are combined with base side profile rotation using quaternion multiplication

### 6. Animation State Management

**Preventing Animation Stacking:**
- `isAnimating` flag prevents new animations from starting while one is running
- `animationTask` stores the current animation task for cancellation
- Animations check `Task.isCancelled` and `showLessonComplete` before and during execution

**Animation Cancellation:**
- `stopAllAnimationsAndReset()` cancels any running animation task
- Called when:
  - Lesson complete screen appears
  - User navigates to next lesson/level

**Reset Logic:**
- `hasPlayedCompletionAnimation` is reset to `false` when:
  - Level changes (`onChange(of: engine.currentLevel)`)
  - Lesson changes (`onChange(of: engine.currentLesson)`)
- Animal is hidden when level/lesson changes

### 7. Base Side Profile Rotation

**Purpose**: Maintain consistent side profile view (head toward right, feet down)

**Implementation**:
- Base rotation: `-.pi / 2` around Y-axis (set on `animalRootEntity` creation)
- Animation rotations are combined with base rotation using `combineRotationWithBase()`
- Method: Quaternion multiplication (`baseSideProfileRotation * animationRotation`)

### 8. Animation Details by Function

#### `idleSwayAndBreathe()` (lines 767-771)
- **Current State**: No animation - just waits for specified duration
- **Removed Features**: Sway (Y rotation), Breathe (scale animation)
- **Duration**: 3.0 seconds

#### `proudPose()` (lines 773-792)
- Scales model to 1.1x original size
- Holds pose for half the duration
- Resets scale back to original
- **Duration**: 2.0 seconds

#### `runInPlace()` (lines 794-826)
- Performs 3 cycles of forward/up and back/down movement
- Returns to base position at end
- **Duration**: ~1.5 seconds (3 cycles × 0.5s)

#### `runAndEat()` (lines 828-852)
- Runs forward with bounce (2 cycles)
- Pauses briefly at end
- **Duration**: 3.0 seconds

#### `runEatAndShake()` (lines 854-878)
- Calls `runAndEat()` first
- Then performs playful Y-axis shake (3 oscillations)
- **Duration**: ~3.5 seconds

#### `happyBounceAndTilt()` (lines 881-901)
- Bounces up and down repeatedly
- **Duration**: 2.5 seconds (based on loop count)

#### `bigJump()` (lines 903-922)
- Single large jump (Y: 0 → 0.15 → 0)
- **Duration**: 1.5 seconds

#### `jumpAndWag()` (lines 924-948)
- Calls `bigJump()` first
- Then fast Y-axis wagging (tail wag simulation)
- **Duration**: 2.5 seconds

#### `jumpFastWagAndHop()` (lines 950-970)
- Calls `jumpAndWag()` first
- Then small hop at end
- **Duration**: 3.0 seconds

#### `smallHopAndShrink()` (lines 973-1010)
- Small hop up
- Scales model down to 0.95x while in air
- Returns down and scales back to 1.0x
- **Duration**: 1.5 seconds

#### `playBounces()` (lines 1012-1033)
- 3 quick bounces in succession
- **Duration**: 2.0 seconds

#### `moveForwardAndBounce()` (lines 1035-1064)
- Moves forward with bounce
- Bounces down
- Moves back to original position
- **Duration**: 2.5 seconds

#### `moveSpinAndHop()` (lines 1066-1103)
- Moves forward
- Performs 360° Y-axis spin (combined with base rotation)
- Small hop at end
- **Duration**: 3.0 seconds

### 9. Important Notes

1. **No Rigging**: All animations use transform manipulation only - no skeletal animation or rigging
2. **Side Profile**: Animal is always viewed from the side (head toward right)
3. **Visibility**: Animal is hidden until sentence completion
4. **Single Play**: Each animation plays only once per level completion
5. **Cancellation**: Animations can be cancelled when navigating away or showing lesson complete screen
6. **Base Position**: Animal root entity starts at `(0, -0.1, 0)` - slightly lowered
7. **Transform Interpolation**: Smooth interpolation using 60 steps per second with ease-in-out easing

### 10. Files Involved

- **`GameView.swift`**: Main animation logic, routing, and state management
- **`AnimalAnimationHelper.swift`**: Transform interpolation helper functions
- **`GameEngine.swift`**: Provides level/lesson indices and sentence completion state

