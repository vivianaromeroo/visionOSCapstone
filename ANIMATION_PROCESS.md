# Animal Animation Process - Complete Walkthrough

## Overview
This document explains the complete animation system for the animal in GameView, from trigger to completion, including all transformations.

---

## 1. ANIMATION TRIGGER

### What Triggers an Animation:
The animation is triggered when **all slots in a sentence are filled** (sentence is complete).

### Trigger Mechanism:
```swift
.onChange(of: engine.currentStep) { oldStep, newStep in
    // Check if sentence is now complete
    if isSentenceComplete && !hasPlayedCompletionAnimation && !showLessonComplete {
        hasPlayedCompletionAnimation = true
        Task {
            await playAnimation(for: engine.currentLevel, lesson: engine.currentLesson)
        }
    }
}
```

### Conditions That Must Be Met:
1. ✅ `isSentenceComplete` = `engine.currentStep == engine.currentSentence.count`
2. ✅ `!hasPlayedCompletionAnimation` = Animation hasn't been played for this level yet
3. ✅ `!showLessonComplete` = Lesson complete screen is not showing

### State Variables:
- `hasPlayedCompletionAnimation: Bool` - Tracks if animation has played for current level
- `isAnimating: Bool` - Prevents overlapping animations
- `animationTask: Task<Void, Never>?` - Holds reference to running animation

---

## 2. INITIALIZATION PHASE

### Step 1: Guard Checks
```swift
func playAnimation(for level: Int, lesson: Int) async {
    // Don't start if already animating or lesson complete screen showing
    guard !isAnimating && !showLessonComplete else { return }
    
    // Cancel any existing animation
    animationTask?.cancel()
    
    // Ensure entities exist
    guard let animalRoot = animalRootEntity,
          let animalModel = animalEntity else { return }
}
```

### Step 2: Reset All Transforms
**Function: `resetAnimalTransforms()`**

This function sets the animal to its base state before animation:

#### Root Entity Reset:
```swift
animalRoot.transform = Transform(
    scale: SIMD3(repeating: 1.0),
    rotation: baseSideProfileRotation,  // -90° Y rotation (side profile)
    translation: SIMD3<Float>(0, 0, 0)
)
animalRoot.position = SIMD3<Float>(0, 0, 0)
animalRoot.scale = SIMD3(repeating: 1.0)
```

**Transformations Applied:**
- Position: `(0, 0, 0)` - Origin
- Scale: `(1.0, 1.0, 1.0)` - Normal size
- Rotation: `baseSideProfileRotation` = `-90°` around Y-axis (head toward right, side profile view)

#### Model Entity Reset:
```swift
animalModel.transform = Transform(
    scale: originalModelScale,  // Preserved from loading
    rotation: identityRotation,  // (0, 0, 0, 1) - No rotation
    translation: originalModelPosition  // Preserved from loading
)
```

**Transformations Applied:**
- Position: Preserved from model loading (centered)
- Scale: Preserved from model loading (0.15 / maxDimension)
- Rotation: Identity quaternion `(ix: 0, iy: 0, iz: 0, r: 1)` - No rotation (inherits from root)

---

## 3. ANIMATION ROUTING

### Step 3: Route to Specific Animation
**Function: `performAnimation(for:level:lesson:animalRoot:animalModel:)`**

Routes to the correct animation based on lesson and level:

```
Lesson 0 (Basic Actions):
  Level 0 → idleSwayAndBreathe()
  Level 1 → proudPose()
  Level 2 → runInPlace()
  Level 3 → runAndEat()
  Level 4 → runEatAndShake()

Lesson 1 (Emotions):
  Level 0 → idleSwayAndBreathe()
  Level 1 → happyBounceAndTilt()
  Level 2 → bigJump()
  Level 3 → jumpAndWag()
  Level 4 → jumpFastWagAndHop()

Lesson 2 (Interactions):
  Level 0 → idleSwayAndBreathe()
  Level 1 → smallHopAndShrink()
  Level 2 → playBounces()
  Level 3 → moveForwardAndBounce()
  Level 4 → moveSpinAndHop()
```

---

## 4. ANIMATION EXECUTION

### Base Side Profile Rotation
All animations start with the root entity rotated `-90°` around Y-axis:
```swift
baseSideProfileRotation = simd_quatf(angle: -.pi / 2, axis: SIMD3(0, 1, 0))
```
This gives the side profile view (head toward right, feet down).

### Rotation Combination
When animations need to rotate the root, they combine with base rotation:
```swift
func combineRotationWithBase(_ animationRotation: simd_quatf) -> simd_quatf {
    return baseSideProfileRotation * animationRotation
}
```

---

## 5. DETAILED ANIMATION EXAMPLES

### Example 1: idleSwayAndBreathe (Lesson 1, Level 1)

**Two Parallel Animations:**

#### Animation A: Sway (Root Entity - Y Rotation)
```
Cycle 1:
  Start: baseSideProfileRotation (-90° Y)
  → Animate to: combineRotationWithBase(+5° Y) = -90° + 5° = -85° Y
    Duration: 0.5s
    Transformation: Root.rotation changes from -90° to -85° around Y-axis
  
  → Animate to: combineRotationWithBase(-5° Y) = -90° - 5° = -95° Y
    Duration: 0.5s
    Transformation: Root.rotation changes from -85° to -95° around Y-axis

Cycle 2: (repeat)
Cycle 3: (repeat)

Final:
  → Return to: baseSideProfileRotation (-90° Y)
    Duration: 0.5s
    Transformation: Root.rotation resets to -90° around Y-axis
```

#### Animation B: Breathing (Model Entity - Scale)
```
Cycle 1:
  Start: originalScale (e.g., 0.15)
  → Animate to: originalScale + 0.05 = 0.20
    Duration: 0.5s
    Transformation: Model.scale increases uniformly
  
  → Animate to: originalScale = 0.15
    Duration: 0.5s
    Transformation: Model.scale decreases back

Cycle 2: (repeat)
Cycle 3: (repeat)
```

**Total Duration:** ~3.0 seconds (3 cycles × 2 animations × 0.5s)

---

### Example 2: proudPose (Lesson 1, Level 2)

**Sequential Transformations:**

```
Step 1: Scale Up
  Start: Model.scale = originalScale (e.g., 0.15)
  Target: Model.scale = originalScale × 1.1 = 0.165
  Duration: 1.0s (duration × 0.5)
  Transformation: Uniform scale increase (breathing effect)
  
  Applied to: animalModel entity
  Interpolation: Linear scale interpolation

Step 2: Head Tilt
  Start: Model.rotation = identity (0, 0, 0, 1)
  Target: Model.rotation = -5° around X-axis
  Duration: 1.0s (duration × 0.5)
  Transformation: Rotate head up (proud look)
  
  Applied to: animalModel entity
  Interpolation: SLERP (spherical linear interpolation)

Step 3: Reset
  Start: Model.rotation = -5° X, Model.scale = 1.1×
  Target: Model.rotation = identity, Model.scale = original
  Duration: 0.2s
  Transformation: Return to neutral state
  
  Applied to: animalModel entity
```

**Total Duration:** ~2.2 seconds

---

### Example 3: runInPlace (Lesson 1, Level 3)

**Repeated Cycle Animation:**

```
Cycle (repeated for duration × 2 = 4 times):
  Step 1: Move Forward and Up
    Start: Root.position = (0, 0, 0)
    Target: Root.position = (0, 0.02, 0.05)
    Duration: 0.25s
    Transformations:
      - Y: 0 → 0.02 (bounce up)
      - Z: 0 → 0.05 (move forward)
      - X: 0 (no change)
    
    Applied to: animalRoot entity
    
  Step 2: Move Back and Down
    Start: Root.position = (0, 0.02, 0.05)
    Target: Root.position = (0, 0, 0)
    Duration: 0.25s
    Transformations:
      - Y: 0.02 → 0 (bounce down)
      - Z: 0.05 → 0 (move back)
      - X: 0 (no change)
    
    Applied to: animalRoot entity

Final:
  → Reset to: (0, 0, 0)
  Duration: 0.2s
```

**Total Duration:** ~2.2 seconds (4 cycles × 0.5s + reset)

---

### Example 4: runAndEat (Lesson 1, Level 4)

**Sequential Animations:**

```
Phase 1: Run (2 cycles)
  Cycle 1:
    - Forward: (0, 0.02, 0.05) over 0.3s
    - Back: (0, 0, 0) over 0.3s
  Cycle 2:
    - Forward: (0, 0.02, 0.05) over 0.3s
    - Back: (0, 0, 0) over 0.3s

Phase 2: Eating Motion
  Step 1: Head Down
    Start: Model.rotation = identity
    Target: Model.rotation = +15° around X-axis
    Duration: 0.5s
    Transformation: Rotate head down (eating motion)
    Applied to: animalModel entity
    
  Step 2: Head Up
    Start: Model.rotation = +15° X
    Target: Model.rotation = identity
    Duration: 0.5s
    Transformation: Return head to neutral
    Applied to: animalModel entity
```

**Total Duration:** ~3.0 seconds

---

## 6. TRANSFORMATION INTERPOLATION

### AnimalAnimationHelper.animateTransform()

This helper function smoothly interpolates between start and end transforms:

```swift
static func animateTransform(
    entity: Entity,
    targetTransform: Transform,
    duration: TimeInterval
) async {
    let startTransform = entity.transform
    let steps = 60  // 60 frames per second
    let stepDuration = duration / Double(steps)
    
    for i in 0...steps {
        let progress = Double(i) / Double(steps)
        let t = easeInOut(progress)  // Smooth easing curve
        
        // Interpolate position (linear)
        currentPos = startPos + (targetPos - startPos) * Float(t)
        
        // Interpolate rotation (SLERP)
        currentRotation = simd_slerp(startRotation, targetRotation, Float(t))
        
        // Interpolate scale (linear)
        currentScale = startScale + (targetScale - startScale) * Float(t)
        
        // Apply combined transform
        entity.transform = Transform(
            scale: currentScale,
            rotation: currentRotation,
            translation: currentPos
        )
        
        // Wait for next frame
        await Task.sleep(nanoseconds: stepDuration * 1_000_000_000)
    }
}
```

### Easing Function:
```
easeInOut(t) = {
    if t < 0.5: 2 * t²
    else: 1 - pow(-2 * t + 2, 2) / 2
}
```
Creates smooth acceleration and deceleration (S-curve).

---

## 7. TRANSFORMATION BREAKDOWN BY COMPONENT

### Position Transformations (Translation):
- **X-axis**: Usually 0 (side profile, no lateral movement)
- **Y-axis**: Vertical movement (bouncing, jumping)
  - Examples: `0 → 0.02` (small bounce), `0 → 0.15` (big jump)
- **Z-axis**: Forward/backward movement (running, approaching)
  - Examples: `0 → 0.05` (small step), `0 → 0.15` (big step forward)

### Rotation Transformations:
- **Root Entity Rotations (Y-axis)**: 
  - Base: `-90°` (side profile)
  - Sway: `-90° ± 5°` (idle)
  - Wag: `-90° ± 15°` (happy wag)
  - Spin: `-90° + 360°` (full rotation)
  
- **Model Entity Rotations**:
  - **X-axis**: Head tilt (pitch)
    - `-5°` (head up - proud)
    - `+15°` (head down - eating)
  - **Y-axis**: Usually inherited from root
  - **Z-axis**: Head tilt (roll)
    - `±7°` (happy tilt)

### Scale Transformations:
- **Uniform Scale**:
  - Breathing: `scale → scale + 0.05 → scale` (subtle)
  - Proud: `scale → scale × 1.1` (10% larger)
  - Shrink: `scale → scale × 0.95` (5% smaller)

---

## 8. CLEANUP PHASE

### After Animation Completes:

```
Step 1: Small Delay
  await Task.sleep(nanoseconds: 100_000_000)  // 0.1 seconds
  Purpose: Ensure all interpolation is complete

Step 2: Reset Model Rotation
  resetModelRotation()
  - Sets Model.rotation to identity quaternion
  - Clears any X/Y/Z rotations

Step 3: Force Complete Reset
  resetAnimalTransforms()
  - Resets root to base side profile rotation
  - Resets model to identity rotation
  - Ensures clean state for next animation

Step 4: Mark Animation Complete
  isAnimating = false
  - Allows new animations to start
```

---

## 9. CANCELLATION HANDLING

### When Animation is Cancelled:

```
Scenario: User clicks "Next Level" while animation is running

1. animationTask?.cancel()  // Cancel the Task
2. isAnimating = false      // Allow new animations
3. resetAnimalTransforms()  // Force immediate reset
4. resetModelRotation()     // Clear any partial rotations
5. showLessonComplete = true  // Show completion screen
```

### Guard Clauses Prevent:
- Starting animation if one is already running
- Starting animation if lesson complete screen is showing
- Continuing animation after cancellation

---

## 10. TRANSFORMATION HIERARCHY

### Entity Structure:
```
animalRootEntity (Entity)
  ├─ position: (0, 0, 0)
  ├─ rotation: baseSideProfileRotation (-90° Y)
  ├─ scale: (1.0, 1.0, 1.0)
  └─ child: animalModel (ModelEntity)
       ├─ position: (centered from loading)
       ├─ rotation: identity (inherits from parent)
       └─ scale: (0.15, 0.15, 0.15) - from loading
```

### How Transformations Stack:
- **Root transformations** affect the entire animal (position, overall rotation)
- **Model transformations** are relative to root (head movements, breathing)
- **Combined effect**: Model transform × Root transform = Final position/rotation

---

## 11. COMPLETE FLOW DIAGRAM

```
User fills all slots
    ↓
engine.currentStep changes
    ↓
.onChange detects completion
    ↓
Check: isSentenceComplete? && !hasPlayedCompletionAnimation?
    ↓ YES
Set hasPlayedCompletionAnimation = true
    ↓
Call playAnimation(level, lesson)
    ↓
Guard checks pass?
    ↓ YES
Cancel any existing animation
    ↓
resetAnimalTransforms()
  - Root: position (0,0,0), rotation (-90° Y), scale (1,1,1)
  - Model: identity rotation, preserved scale/position
    ↓
Set isAnimating = true
    ↓
Create animationTask
    ↓
Call performAnimation()
    ↓
Route to specific animation function
  (idleSwayAndBreathe, proudPose, etc.)
    ↓
Execute animation transformations
  - Multiple steps with interpolation
  - Each step uses AnimalAnimationHelper
  - 60 frames/second with easing
    ↓
Animation completes
    ↓
Wait 0.1s
    ↓
resetModelRotation()
  - Clear all model rotations
    ↓
resetAnimalTransforms()
  - Return to base state
    ↓
Set isAnimating = false
    ↓
DONE - Animal ready for next animation
```

---

## 12. KEY TRANSFORMATION CONSTANTS

```swift
// Base Orientation
baseSideProfileRotation = -90° around Y-axis
  → Animal faces right (side profile)

// Rotation Angles
swayAngle = ±5°      // Gentle idle sway
wagAngle = ±15°      // Happy tail wag
shakeAngle = ±10°    // Playful shake
tiltAngle = -5° (X)  // Proud head up
eatAngle = +15° (X)  // Eating head down
tiltAngle = ±7° (Z)  // Happy head tilt

// Movement Distances
bounceHeight = 0.02  // Small bounce
jumpHeight = 0.15    // Big jump
moveDistance = 0.05  // Small step
forwardDistance = 0.15  // Large step

// Scale Changes
breatheScale = +0.05    // Breathing effect
proudScale = ×1.1       // 10% larger
shrinkScale = ×0.95     // 5% smaller
```

---

## Summary

1. **Trigger**: Sentence completion detected via `onChange(of: currentStep)`
2. **Initialize**: Reset all transforms to base state
3. **Route**: Select animation based on lesson/level
4. **Execute**: Interpolate transforms over time (60 fps with easing)
5. **Cleanup**: Reset to base state after completion
6. **Cancel**: Handle interruptions gracefully with immediate reset

All transformations use smooth interpolation with easing for natural-looking animations!

