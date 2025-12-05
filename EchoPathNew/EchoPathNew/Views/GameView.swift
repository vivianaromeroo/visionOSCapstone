//
//  GameView.swift
//  EchoPathNew
//
//  Created by Admin2  on 4/22/25.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers
import RealityKit
import RealityKitContent

struct GameView: View {
    @State private var engine: GameEngine
    @State private var wordEntities: [String: Entity] = [:]
    @State private var slotEntities: [Int: Entity] = [:]
    @State private var draggedWord: String? = nil
    @State private var draggedEntity: Entity? = nil
    @State private var originalPosition: SIMD3<Float>? = nil
    @State private var sceneUpdateTrigger: Int = 0
    @State private var showLessonComplete: Bool = false
    @State private var completedLessonIndex: Int = 0
    @State private var hasNextLessonAvailable: Bool = false
    @State private var animalEntity: ModelEntity? = nil
    @State private var animalRootEntity: Entity? = nil
    @State private var animationTask: Task<Void, Never>? = nil
    @State private var isAnimating: Bool = false
    @State private var hasPlayedCompletionAnimation: Bool = false // Track if we've played animation for this level
    @Environment(\.dismiss) private var dismiss
    
    private let animal: String
    
    // Computed property to check if sentence is complete
    private var isSentenceComplete: Bool {
        engine.currentStep == engine.currentSentence.count
    }
    
    init(animal: String) {
        self.animal = animal
        _engine = State(wrappedValue: GameEngine(animal: animal))
    }
    
    // Computed property for next button text
    private var nextButtonText: String {
        if !engine.isLastLevelInLesson {
            return "Next Level"
        } else if !engine.isLastLessonInUnit {
            return "Next Lesson"
        } else {
            return "Complete!"
        }
    }
    
    var body: some View {
        ZStack {
            // RealityKit 3D Scene - Full screen, interactive
            RealityView { content in
                // Add animal root entity immediately (same pattern as AnimalPickerView)
                if animalRootEntity == nil {
                    let rootEntity = Entity()
                    rootEntity.name = "AnimalRoot"
                    // Set base rotation for side profile view (head toward right, feet down)
                    rootEntity.transform.rotation = simd_quatf(angle: -.pi / 2, axis: SIMD3(0, 0.5, 0))
                    // Set position - lower the animal (negative Y = down)
                    rootEntity.position = SIMD3<Float>(0, -0.1, 0)
                    // Hide animal initially - will be shown when lesson is complete
                    rootEntity.scale = SIMD3(repeating: 0.0)
                    animalRootEntity = rootEntity
                    content.add(rootEntity)
                    
                    // Load model in task
                    Task {
                        await loadAnimalModel()
                    }
                } else if let existingRoot = animalRootEntity {
                    content.add(existingRoot)
                }
                
                setupScene(content: content)
            } update: { content in
                // Ensure animal is still in content when scene updates
                if let animalRoot = animalRootEntity, animalRoot.parent == nil {
                    content.add(animalRoot)
                }
                // Don't trigger animation here - it's handled by onChange modifiers
            }
            .id(sceneUpdateTrigger) // Force re-render when trigger changes
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .gesture(
                DragGesture()
                    .targetedToAnyEntity()
                    .onChanged { value in
                        handleDragChanged(value: value)
                    }
                    .onEnded { value in
                        handleDragEnded(value: value)
                    }
            )
            
            // Unit/Lesson/Level title at top and Controls at bottom (hidden when lesson complete)
            if !showLessonComplete {
                VStack {
                    // Title card with puzzle piece accent
                    HStack(spacing: 10) {
                        VStack(spacing: 6) {
                            Text(engine.unitName)
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.pastelPurple.opacity(0.9))
                            
                            Text("Lesson \(engine.currentLesson + 1): \(engine.currentLessonName)")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(.pastelPurple)
                            
                            Text("Level \(engine.currentLevel + 1)")
                                .font(.system(size: 18, weight: .medium, design: .rounded))
                                .foregroundColor(.pastelPurple.opacity(0.8))
                        }
                    }
                    .padding(20)
                    .background(Color.neutralBackground.opacity(0.9))
                    .cornerRadius(25)
                    .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 6)
                    .padding(.top, 15)
                    .allowsHitTesting(false)
                    
                    Spacer()
                    
                    // Controls at bottom
                    HStack(spacing: 12) {
                        if engine.currentStep == engine.currentSentence.count {
                            Button(nextButtonText) {
                                handleNextButton()
                            }
                            .buttonStyle(PastelPrimaryButtonStyle())
                        }
                        
                        // Development/Testing: Skip to next level
                        Button("Skip Level") {
                            handleSkipLevel()
                        }
                        .buttonStyle(PastelSecondaryButtonStyle(color: .pastelPink))
                        
                        Button("Reset Level") {
                            engine.resetLevel()
                            sceneUpdateTrigger += 1
                        }
                        .buttonStyle(PastelSecondaryButtonStyle(color: .warmPink))
                    }
                    .padding(15)
                    .background(Color.neutralBackground.opacity(0.9))
                    .cornerRadius(25)
                    .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 6)
                    .padding(.bottom, 20)
                }
            }
            
            // Lesson Complete Overlay
            if showLessonComplete {
                LessonCompleteView(
                    lessonName: (completedLessonIndex >= 0 && completedLessonIndex < engine.lessonNames.count) 
                        ? engine.lessonNames[completedLessonIndex] 
                        : "Lesson",
                    hasNextLesson: hasNextLessonAvailable,
                    onContinue: {
                        // Only proceed if there's actually a next lesson available
                        guard hasNextLessonAvailable else {
                            return
                        }
                        
                        showLessonComplete = false
                        // Reset animal orientation before continuing to next lesson
                        animationTask?.cancel()
                        isAnimating = false
                        // Reset completion animation flag for the new lesson
                        hasPlayedCompletionAnimation = false
                        // Hide animal - will appear again when new lesson is complete
                        hideAnimal()
                        
                        // Advance to next lesson (this will move to lesson + 1, level 0)
                        engine.nextLevel()
                        
                        // Force scene update after state changes
                        sceneUpdateTrigger += 1
                    },
                    onExit: {
                        // Navigate back to title screen (ContentView)
                        // Dismiss will pop back through the navigation stack
                        dismiss()
                    }
                )
            }
        }
        .navigationTitle("Sentence Builder")
        .onChange(of: engine.availableWords) { _, _ in
            // Update word entities without recreating entire scene
            sceneUpdateTrigger += 1
        }
        .onChange(of: engine.droppedWords) { _, _ in
            // Update slot appearance without recreating entire scene
            sceneUpdateTrigger += 1
        }
        .onChange(of: engine.currentStep) { oldStep, newStep in
            updateSlotAppearance()
            
            // Check if sentence is now complete and we haven't played animation yet
            if isSentenceComplete && !hasPlayedCompletionAnimation && !showLessonComplete {
                // Play animation when sentence is completed
                hasPlayedCompletionAnimation = true
                Task {
                    // First, make the animal visible
                    await showAnimal()
                    // Then play the animation
                    await playAnimation(for: engine.currentLevel, lesson: engine.currentLesson)
                }
            }
        }
        .onChange(of: engine.currentLevel) { oldLevel, newLevel in
            // Reset completion animation flag when level changes
            hasPlayedCompletionAnimation = false
            // Hide animal when level changes - will appear again when new level is complete
            hideAnimal()
        }
        .onChange(of: engine.currentLesson) { oldLesson, newLesson in
            // Reset completion animation flag when lesson changes
            hasPlayedCompletionAnimation = false
            // Hide animal when lesson changes - will appear again when new lesson is complete
            hideAnimal()
        }
        .onChange(of: showLessonComplete) { _, isShowing in
            // When lesson complete screen appears, immediately cancel animations and reset
            if isShowing {
                stopAllAnimationsAndReset()
            }
        }
        .onAppear {
            // Don't trigger animation automatically on load - wait for user interaction
            // Animation will be triggered when level/lesson changes or when explicitly needed
        }
    }
    
    // MARK: - Navigation Handlers
    private func handleNextButton() {
        // Check if we're completing a lesson (on last level of current lesson)
        if engine.isLastLevelInLesson {
            // Stop all animations and force immediate reset
            stopAllAnimationsAndReset()
            
            // Show lesson completion screen
            completedLessonIndex = engine.currentLesson
            hasNextLessonAvailable = !engine.isLastLessonInUnit
            showLessonComplete = true
        } else {
            // Just moving to next level within the same lesson
            // Reset the completion animation flag for the new level
            hasPlayedCompletionAnimation = false
            // Hide animal - will appear again when new level is complete
            hideAnimal()
            engine.nextLevel()
            sceneUpdateTrigger += 1
        }
    }
    
    // Force stop all animations
    private func stopAllAnimationsAndReset() {
        // Cancel any running animation task
        animationTask?.cancel()
        isAnimating = false
    }
    
    private func handleSkipLevel() {
        // Play animation before skipping if it hasn't been played yet
        Task {
            // If animation hasn't been played for this level, play it first
            if !hasPlayedCompletionAnimation {
                hasPlayedCompletionAnimation = true
                await showAnimal()
                await playAnimation(for: engine.currentLevel, lesson: engine.currentLesson)
            }
            
            // Wait a brief moment after animation completes
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            // Now proceed with skip logic
            if engine.isLastLevelInLesson {
                // Stop all animations and force immediate reset
                stopAllAnimationsAndReset()
                
                // Show lesson completion screen
                completedLessonIndex = engine.currentLesson
                hasNextLessonAvailable = !engine.isLastLessonInUnit
                showLessonComplete = true
            } else {
                // Just moving to next level within the same lesson
                // Reset the completion animation flag for the new level
                hasPlayedCompletionAnimation = false
                // Hide animal - will appear again when new level is complete
                hideAnimal()
                engine.nextLevel()
                sceneUpdateTrigger += 1
            }
        }
    }
    
    // MARK: - Scene Setup
    private func setupScene(content: RealityViewContent) {
        // Remove only word and slot entities, preserve animal
        for (_, entity) in wordEntities {
            entity.removeFromParent()
        }
        for (_, entity) in slotEntities {
            entity.removeFromParent()
        }
        wordEntities.removeAll()
        slotEntities.removeAll()
        
        // Animal root entity is already created and added in RealityView closure
        // Create slot entities (drop targets) - arranged in a grid (max 4 per row)
        
        // Safety check: ensure sentence is valid before accessing
        let currentSentence = engine.currentSentence
        guard !currentSentence.isEmpty else {
            print("⚠️ Warning: Empty sentence in setupScene, skipping slot creation")
            return
        }
        
        let slotsPerRow: Int = 4
        let slotSpacingX: Float = 0.15
        let slotSpacingY: Float = -0.08  // Vertical spacing between rows
        let totalSlots = currentSentence.count
        
        for (index, _) in currentSentence.enumerated() {
            let slotEntity = createSlotEntity(index: index)
            
            // Calculate row and column
            let row = index / slotsPerRow
            let col = index % slotsPerRow
            
            // Calculate position for this row
            let slotsInRow = min(slotsPerRow, totalSlots - row * slotsPerRow)
            let startX: Float = -Float(slotsInRow - 1) * slotSpacingX / 2
            
            slotEntity.position = SIMD3<Float>(
                startX + Float(col) * slotSpacingX,
                0.1 + Float(row) * slotSpacingY,
                0.0  // Move closer to camera
            )
            slotEntities[index] = slotEntity
            content.add(slotEntity)
        }
        
        // Create word entities (draggable) - arranged in a word bank
        let availableWords = engine.availableWords
        
        // Safety check: ensure available words are valid before accessing
        guard !availableWords.isEmpty else {
            print("⚠️ Warning: Empty availableWords in setupScene, skipping word creation")
            return
        }
        
        let wordSpacing: Float = 0.12
        let wordStartX: Float = -Float(availableWords.count - 1) * wordSpacing / 2
        
        for (wordIndex, word) in availableWords.enumerated() {
            let wordEntity = createWordEntity(word: word)
            wordEntity.position = SIMD3<Float>(
                wordStartX + Float(wordIndex) * wordSpacing,
                -0.1,
                0.0  // Move closer to camera
            )
            wordEntities[word] = wordEntity
            content.add(wordEntity)
        }
    }
    
    // MARK: - Animal Model Loading
    private func loadAnimalModel() async {
        guard let rootEntity = animalRootEntity else {
            print("❌ Animal root entity not found")
            return
        }
        
        // Remove existing model child if any
        rootEntity.children.removeAll()
        
        do {
            // Load model entity (same approach as AnimalPickerView)
            let modelEntity = try await ModelEntity(named: "\(animal).usdz")
            
            // 1. Scale to a reasonable size (same as AnimalPickerView)
            let bounds = modelEntity.visualBounds(relativeTo: nil)
            let maxDimension = max(bounds.extents.x, bounds.extents.y, bounds.extents.z)
            let scaleFactor = 0.15 / maxDimension
            modelEntity.scale = SIMD3(repeating: scaleFactor)
            
            // 2. Recenter the model so its center is at (0,0,0) (same as AnimalPickerView)
            let centeredY: Float = -bounds.center.y * scaleFactor + 0
            
            modelEntity.position = SIMD3(
                -bounds.center.x * scaleFactor,
                centeredY,
                -bounds.center.z * scaleFactor
            )
            
            // 3. No rotation on model - side profile rotation is applied to root entity
            
            // Add model to existing root entity
            rootEntity.addChild(modelEntity)
            
            // Store reference to model entity
            animalEntity = modelEntity
            
            print("✅ Animal model loaded: \(animal)")
            
            // Don't start animation automatically - it will be triggered when level/lesson changes
        } catch {
            print("❌ ANIMAL MODEL LOADING ERROR: \(error.localizedDescription)")
            print("   Attempted to load: \(animal).usdz")
        }
    }
    
    // MARK: - Entity Creation
    private func createSlotEntity(index: Int) -> Entity {
        let parent = Entity()
        parent.name = "Slot_\(index)"
        
        // Create box for slot - pink for active slot, lavender for others
        // Increased depth (Z axis) from 0.01 to 0.06 to make it easier to drag words into
        let boxMesh = MeshResource.generateBox(size: [0.12, 0.06, 0.06])
        let isActive = index == engine.currentStep
        let slotColor: UIColor = isActive ? Color.pastelPink.uiColor : Color.lavender.uiColor
        let material = SimpleMaterial(color: slotColor.withAlphaComponent(0.5), isMetallic: false)
        let box = ModelEntity(mesh: boxMesh, materials: [material])
        box.generateCollisionShapes(recursive: true)
        box.components.set(InputTargetComponent(allowedInputTypes: .indirect))
        box.name = "SlotBox_\(index)"
        
        // Create text for slot (only show word if dropped, no hints)
        // Safety check: ensure index is within bounds of droppedWords array
        if index >= 0 && index < engine.droppedWords.count,
           let droppedWord = engine.droppedWords[index] {
            let textMesh = MeshResource.generateText(
                droppedWord,
                extrusionDepth: 0.002,
                font: .systemFont(ofSize: 0.03)
            )
            let textMaterial = SimpleMaterial(color: .white, isMetallic: false)
            let textEntity = ModelEntity(mesh: textMesh, materials: [textMaterial])
            let bounds = textEntity.visualBounds(relativeTo: nil)
            textEntity.position = SIMD3(-bounds.center.x, -bounds.center.y, 0.006)
            textEntity.name = "SlotText_\(index)"
            parent.addChild(textEntity)
        }
        
        parent.addChild(box)
        parent.generateCollisionShapes(recursive: true)
        parent.components.set(InputTargetComponent(allowedInputTypes: .indirect))
        
        return parent
    }
    
    private func createWordEntity(word: String) -> Entity {
        let parent = Entity()
        parent.name = "Word_\(word)"
        
        // Create box for word
        let boxMesh = MeshResource.generateBox(size: [0.1, 0.05, 0.01])
        let material = SimpleMaterial(color: .cyan.withAlphaComponent(0.5), isMetallic: false)
        let box = ModelEntity(mesh: boxMesh, materials: [material])
        box.generateCollisionShapes(recursive: true)
        box.components.set(InputTargetComponent(allowedInputTypes: .indirect))
        
        // Create text for word
        let textMesh = MeshResource.generateText(
            word,
            extrusionDepth: 0.002,
            font: .systemFont(ofSize: 0.03)
        )
        let textMaterial = SimpleMaterial(color: .white, isMetallic: false)
        let textEntity = ModelEntity(mesh: textMesh, materials: [textMaterial])
        let bounds = textEntity.visualBounds(relativeTo: nil)
        textEntity.position = SIMD3(-bounds.center.x, -bounds.center.y, 0.006)
        
        parent.addChild(box)
        parent.addChild(textEntity)
        parent.generateCollisionShapes(recursive: true)
        parent.components.set(InputTargetComponent(allowedInputTypes: .indirect))
        
        return parent
    }
    
    // MARK: - Drag Handling
    private func handleDragChanged(value: EntityTargetValue<DragGesture.Value>) {
        let entity = value.entity
        
        // Find the word entity parent (the entity stored in wordEntities)
        var targetEntity: Entity? = nil
        var word: String? = nil
        
        // Check if this entity itself is a word entity
        if let w = getWordFromEntity(entity), let storedEntity = wordEntities[w], storedEntity == entity {
            targetEntity = entity
            word = w
        } else if let parent = entity.parent {
            // Check if parent is a word entity
            if let w = getWordFromEntity(parent), let storedEntity = wordEntities[w], storedEntity == parent {
                targetEntity = parent
                word = w
            } else if let grandparent = parent.parent, let w = getWordFromEntity(grandparent), let storedEntity = wordEntities[w], storedEntity == grandparent {
                // Check grandparent (in case we're hitting a deeply nested child)
                targetEntity = grandparent
                word = w
            }
        }
        
        guard let target = targetEntity, let w = word else { 
            // Not a word entity, ignore
            return 
        }
        
        // Store original position on first drag
        if draggedWord == nil {
            draggedWord = w
            draggedEntity = target
            originalPosition = target.position
        }
        
        // Update position during drag - use same conversion as TestView
        if let parent = target.parent {
            target.position = value.convert(value.location3D, from: .local, to: parent)
        } else {
            // Fallback - use the entity itself as coordinate space
            target.position = value.convert(value.location3D, from: .local, to: target)
        }
    }
    
    private func handleDragEnded(value: EntityTargetValue<DragGesture.Value>) {
        guard let word = draggedWord,
              let draggedEntity = draggedEntity else {
            resetDragState()
            return
        }
        
        // Use a common coordinate space - the entity's parent or the entity itself
        let coordinateSpace = draggedEntity.parent ?? draggedEntity
        let dragPosition = value.convert(value.location3D, from: .local, to: coordinateSpace)
        
        // Find the closest slot by X/Z distance (ignore Y axis)
        var closestSlotIndex: Int? = nil
        var closestDistance: Float = Float.greatestFiniteMagnitude
        var closestSlotPosition: SIMD3<Float>? = nil
        let threshold: Float = 0.28 // More generous threshold (0.25-0.30 range)
        
        for (index, slotEntity) in slotEntities {
            let slotPosition = slotEntity.position(relativeTo: coordinateSpace)
            
            // Calculate X/Z distance only (ignore Y axis)
            let dx = dragPosition.x - slotPosition.x
            let dz = dragPosition.z - slotPosition.z
            let xzDistance = sqrt(dx * dx + dz * dz)
            
            if xzDistance < threshold && xzDistance < closestDistance {
                closestDistance = xzDistance
                closestSlotIndex = index
                closestSlotPosition = slotPosition
            }
        }
        
        // If a slot is close enough, snap to it and handle the drop
        if let slotIndex = closestSlotIndex,
           let slotPosition = closestSlotPosition {
            // Snap the dragged entity to the exact slot position
            draggedEntity.position = slotPosition
            
            // Handle the drop
            let wasInAvailable = engine.availableWords.contains(word)
            engine.handleDrop(word, at: slotIndex)
            
            // If word was correctly placed, it will be removed from availableWords
            if !engine.availableWords.contains(word) && wasInAvailable {
                // Remove word entity from scene immediately
                draggedEntity.removeFromParent()
                wordEntities.removeValue(forKey: word)
            }
            
            sceneUpdateTrigger += 1
        } else {
            // No slot is close enough, return to original position
            if let originalPos = originalPosition {
                draggedEntity.position = originalPos
            }
        }
        
        resetDragState()
    }
    
    private func resetDragState() {
        draggedWord = nil
        draggedEntity = nil
        originalPosition = nil
    }
    
    // MARK: - Helper Functions
    private func getWordFromEntity(_ entity: Entity) -> String? {
        // Check if entity name starts with "Word_"
        let entityName = entity.name
        if !entityName.isEmpty && entityName.hasPrefix("Word_") {
            return String(entityName.dropFirst(5))
        }
        // Check parent
        if let parent = entity.parent {
            let parentName = parent.name
            if !parentName.isEmpty && parentName.hasPrefix("Word_") {
                return String(parentName.dropFirst(5))
            }
        }
        return nil
    }
    
    private func updateSlotAppearance() {
        // Update slot text based on current step and dropped words
        for (index, slotEntity) in slotEntities {
            let isActive = index == engine.currentStep
            
            // Update box color - pink for active slot, lavender for others
            if let box = slotEntity.children.first(where: { $0.name == "SlotBox_\(index)" }) as? ModelEntity {
                let slotColor: UIColor = isActive ? Color.pastelPink.uiColor : Color.lavender.uiColor
                let material = SimpleMaterial(color: slotColor.withAlphaComponent(0.4), isMetallic: false)
                box.model?.materials = [material]
            }
            
            // Update text - only show if word is dropped
            // Safety check: ensure index is within bounds of droppedWords array
            guard index >= 0 && index < engine.droppedWords.count else {
                // Index out of bounds - remove text if it exists and continue
                if let textEntity = slotEntity.children.first(where: { $0.name == "SlotText_\(index)" }) {
                    textEntity.removeFromParent()
                }
                continue
            }
            
            if let droppedWord = engine.droppedWords[index] {
                // Check if text entity already exists
                if let textEntity = slotEntity.children.first(where: { $0.name == "SlotText_\(index)" }) as? ModelEntity {
                    // Update existing text
                    let textMesh = MeshResource.generateText(
                        droppedWord,
                        extrusionDepth: 0.002,
                        font: .systemFont(ofSize: 0.03)
                    )
                    let textMaterial = SimpleMaterial(color: .white, isMetallic: false)
                    textEntity.model = ModelComponent(mesh: textMesh, materials: [textMaterial])
                    let bounds = textEntity.visualBounds(relativeTo: nil)
                    textEntity.position = SIMD3(-bounds.center.x, -bounds.center.y, 0.006)
                } else {
                    // Create new text entity
                    let textMesh = MeshResource.generateText(
                        droppedWord,
                        extrusionDepth: 0.002,
                        font: .systemFont(ofSize: 0.03)
                    )
                    let textMaterial = SimpleMaterial(color: .white, isMetallic: false)
                    let textEntity = ModelEntity(mesh: textMesh, materials: [textMaterial])
                    let bounds = textEntity.visualBounds(relativeTo: nil)
                    textEntity.position = SIMD3(-bounds.center.x, -bounds.center.y, 0.006)
                    textEntity.name = "SlotText_\(index)"
                    slotEntity.addChild(textEntity)
                }
            } else {
                // Remove text entity if word is removed
                if let textEntity = slotEntity.children.first(where: { $0.name == "SlotText_\(index)" }) {
                    textEntity.removeFromParent()
                }
            }
        }
    }
    
    // MARK: - Animal Visibility
    
    private func showAnimal() async {
        guard let animalRoot = animalRootEntity else { return }
        
        // Animate scale from 0 to 1 to make animal appear
        var transform = animalRoot.transform
        transform.scale = SIMD3(repeating: 1.0)
        await AnimalAnimationHelper.animateTransform(
            entity: animalRoot,
            targetTransform: transform,
            duration: 0.5
        )
    }
    
    private func hideAnimal() {
        guard let animalRoot = animalRootEntity else { return }
        // Immediately hide the animal by setting scale to 0
        animalRoot.scale = SIMD3(repeating: 0.0)
    }
    
    // MARK: - Animal Animations
    func playAnimation(for level: Int, lesson: Int) async {
        // Don't start new animation if one is already running or if lesson complete screen is showing
        guard !isAnimating && !showLessonComplete else {
            return
        }
        
        // Cancel any existing animation
        animationTask?.cancel()
        
        guard let animalRoot = animalRootEntity,
              let animalModel = animalEntity else {
            return
        }
        
        // Mark as animating
        isAnimating = true
        
        // Create new animation task
        animationTask = Task {
            // Check if cancelled or lesson complete screen is showing before starting
            guard !Task.isCancelled && !showLessonComplete else {
                isAnimating = false
                return
            }
            
            await performAnimation(for: level, lesson: lesson, animalRoot: animalRoot, animalModel: animalModel)
            
            // Check again after animation completes
            guard !Task.isCancelled && !showLessonComplete else {
                isAnimating = false
                return
            }
            
            isAnimating = false
        }
        
        await animationTask?.value
    }
    
    private func performAnimation(for level: Int, lesson: Int, animalRoot: Entity, animalModel: ModelEntity) async {
        
        // Base position is (0, 0, 0) same as AnimalPickerView
        // Animations will move from this position
        
        // Lesson 1 — Basic Actions
        if lesson == 0 {
            switch level {
            case 0: // Level 1: Idle (no animation)
                await idleSwayAndBreathe(animalRoot: animalRoot, duration: 3.0)
                
            case 1: // Level 2: Proud pose
                await proudPose(animalRoot: animalRoot, animalModel: animalModel, duration: 2.0)
                
            case 2: // Level 3: Run-in-place
                await runInPlace(animalRoot: animalRoot, duration: 2.0)
                
            case 3: // Level 4: Run + eating motion
                await runAndEat(animalRoot: animalRoot, animalModel: animalModel, duration: 3.0)
                
            case 4: // Level 5: Run + eating + playful shake
                await runEatAndShake(animalRoot: animalRoot, animalModel: animalModel, duration: 3.5)
                
            default:
                break
            }
        }
        // Lesson 2 — Emotions
        else if lesson == 1 {
            switch level {
            case 0: // Level 1: Idle animation
                await idleSwayAndBreathe(animalRoot: animalRoot, duration: 3.0)
                
            case 1: // Level 2: Happy bounce
                await happyBounceAndTilt(animalRoot: animalRoot, animalModel: animalModel, duration: 2.5)
                
            case 2: // Level 3: Big jump
                await bigJump(animalRoot: animalRoot, duration: 1.5)
                
            case 3: // Level 4: Jump + wag
                await jumpAndWag(animalRoot: animalRoot, animalModel: animalModel, duration: 2.5)
                
            case 4: // Level 5: Jump + fast wag + small hop
                await jumpFastWagAndHop(animalRoot: animalRoot, animalModel: animalModel, duration: 3.0)
                
            default:
                break
            }
        }
        // Lesson 3 — Interactions
        else if lesson == 2 {
            switch level {
            case 0: // Level 1: Idle
                await idleSwayAndBreathe(animalRoot: animalRoot, duration: 3.0)
                
            case 1: // Level 2: Small hop + shrink scale
                await smallHopAndShrink(animalRoot: animalRoot, animalModel: animalModel, duration: 1.5)
                
            case 2: // Level 3: Play bounces
                await playBounces(animalRoot: animalRoot, duration: 2.0)
                
            case 3: // Level 4: Move forward to "ball" and bounce back
                await moveForwardAndBounce(animalRoot: animalRoot, duration: 2.5)
                
            case 4: // Level 5: Move forward → 360° spin → hop
                await moveSpinAndHop(animalRoot: animalRoot, animalModel: animalModel, duration: 3.0)
                
            default:
                break
            }
        }
    }
    
    // MARK: - Animation Helper Functions
    
    // Base side profile rotation constant (head toward right)
    // Combine Y rotation for side profile (-90°) with potential X rotation if needed for feet orientation
    private let baseSideProfileRotation: simd_quatf = {
        let yRotation = simd_quatf(angle: -.pi / 2, axis: SIMD3(0, 1, 0)) // Side profile: head toward right
        // If feet need to point down, we might need X rotation, but let's try without first
        return yRotation
    }()
    
    // Helper to combine animation rotation with base side profile rotation
    private func combineRotationWithBase(_ animationRotation: simd_quatf) -> simd_quatf {
        // Multiply base rotation with animation rotation to combine them
        return baseSideProfileRotation * animationRotation
    }
    
    // Lesson 1 Animations
    private func idleSwayAndBreathe(animalRoot: Entity, duration: Float) async {
        // No animation - animal remains still
        // Wait for the specified duration
        try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
    }
    
    private func proudPose(animalRoot: Entity, animalModel: ModelEntity, duration: Float) async {
        // Scale up to 1.1
        let originalScale = animalModel.scale.x
        var transform = animalModel.transform
        transform.scale = SIMD3(repeating: originalScale * 1.1)
        await AnimalAnimationHelper.animateTransform(
            entity: animalModel,
            targetTransform: transform,
            duration: TimeInterval(duration * 0.5)
        )
        
        // Hold pose, then reset scale
        try? await Task.sleep(nanoseconds: UInt64(duration * 0.5 * 1_000_000_000))
        transform.scale = SIMD3(repeating: originalScale)
        await AnimalAnimationHelper.animateTransform(
            entity: animalModel,
            targetTransform: transform,
            duration: 0.2
        )
    }
    
    private func runInPlace(animalRoot: Entity, duration: Float) async {
        let bounceHeight: Float = 0.02
        let moveDistance: Float = 0.05
        let basePosition = animalRoot.position
        
        // Run a few cycles then stop (not infinite loop)
        let cycles = 3
        for _ in 0..<cycles {
            // Move along X axis (left/right) and up
            var transform = animalRoot.transform
            transform.translation = SIMD3<Float>(basePosition.x + moveDistance, basePosition.y + bounceHeight, basePosition.z)
            await AnimalAnimationHelper.animateTransform(
                entity: animalRoot,
                targetTransform: transform,
                duration: 0.25
            )
            // Move back and down
            transform.translation = basePosition
            await AnimalAnimationHelper.animateTransform(
                entity: animalRoot,
                targetTransform: transform,
                duration: 0.25
            )
        }
        // Return to base position
        var finalTransform = animalRoot.transform
        finalTransform.translation = basePosition
        await AnimalAnimationHelper.animateTransform(
            entity: animalRoot,
            targetTransform: finalTransform,
            duration: 0.2
        )
    }
    
    private func runAndEat(animalRoot: Entity, animalModel: ModelEntity, duration: Float) async {
        let bounceHeight: Float = 0.02
        let moveDistance: Float = 0.05
        let baseRootTransform = animalRoot.transform
        let basePosition = baseRootTransform.translation
        
        // Run (bounce) along X axis
        for _ in 0..<2 {
            var transform = baseRootTransform
            transform.translation = SIMD3<Float>(basePosition.x + moveDistance, basePosition.y + bounceHeight, basePosition.z)
            await AnimalAnimationHelper.animateTransform(
                entity: animalRoot,
                targetTransform: transform,
                duration: 0.3
            )
            transform.translation = basePosition
            await AnimalAnimationHelper.animateTransform(
                entity: animalRoot,
                targetTransform: transform,
                duration: 0.3
            )
        }
        
        // Pause briefly
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second pause
        
        // Return to original position
        var finalTransform = animalRoot.transform
        finalTransform.translation = basePosition
        await AnimalAnimationHelper.animateTransform(
            entity: animalRoot,
            targetTransform: finalTransform,
            duration: 0.2
        )
    }
    
    private func runEatAndShake(animalRoot: Entity, animalModel: ModelEntity, duration: Float) async {
        let baseRootTransform = animalRoot.transform
        let basePosition = baseRootTransform.translation
        
        // Run + eating (from previous)
        await runAndEat(animalRoot: animalRoot, animalModel: animalModel, duration: 2.0)
        
        // Playful shake (Y oscillation) - combine with base side profile rotation
        let shakeAngle: Float = 10.0 * .pi / 180.0
        let baseTransform = animalRoot.transform
        for _ in 0..<3 {
            var transform = baseTransform
            let shakeRotation = simd_quatf(angle: shakeAngle, axis: SIMD3(0, 1, 0))
            transform.rotation = combineRotationWithBase(shakeRotation)
            await AnimalAnimationHelper.animateTransform(
                entity: animalRoot,
                targetTransform: transform,
                duration: 0.15
            )
            let shakeRotationNeg = simd_quatf(angle: -shakeAngle, axis: SIMD3(0, 1, 0))
            transform.rotation = combineRotationWithBase(shakeRotationNeg)
            await AnimalAnimationHelper.animateTransform(
                entity: animalRoot,
                targetTransform: transform,
                duration: 0.15
            )
        }
        
        // Return to original position and rotation
        var finalTransform = animalRoot.transform
        finalTransform.translation = basePosition
        finalTransform.rotation = baseRootTransform.rotation
        await AnimalAnimationHelper.animateTransform(
            entity: animalRoot,
            targetTransform: finalTransform,
            duration: 0.2
        )
    }
    
    // Lesson 2 Animations
    private func happyBounceAndTilt(animalRoot: Entity, animalModel: ModelEntity, duration: Float) async {
        let bounceHeight: Float = 0.03
        let baseRootTransform = animalRoot.transform
        let basePosition = baseRootTransform.translation
        
        // Bounce animation (in place)
        for _ in 0..<Int(duration * 2) {
            var transform = baseRootTransform
            transform.translation = SIMD3<Float>(basePosition.x, basePosition.y + bounceHeight, basePosition.z)
            await AnimalAnimationHelper.animateTransform(
                entity: animalRoot,
                targetTransform: transform,
                duration: 0.4
            )
            transform.translation = basePosition
            await AnimalAnimationHelper.animateTransform(
                entity: animalRoot,
                targetTransform: transform,
                duration: 0.4
            )
        }
        
        // Return to original position
        var finalTransform = animalRoot.transform
        finalTransform.translation = basePosition
        await AnimalAnimationHelper.animateTransform(
            entity: animalRoot,
            targetTransform: finalTransform,
            duration: 0.2
        )
    }
    
    private func bigJump(animalRoot: Entity, duration: Float) async {
        let jumpHeight: Float = 0.15
        let baseTransform = animalRoot.transform
        let basePosition = baseTransform.translation
        
        // Jump up
        var transform = baseTransform
        transform.translation = SIMD3<Float>(basePosition.x, basePosition.y + jumpHeight, basePosition.z)
        await AnimalAnimationHelper.animateTransform(
            entity: animalRoot,
            targetTransform: transform,
            duration: TimeInterval(duration * 0.5)
        )
        // Come down
        transform.translation = basePosition
        await AnimalAnimationHelper.animateTransform(
            entity: animalRoot,
            targetTransform: transform,
            duration: TimeInterval(duration * 0.5)
        )
    }
    
    private func jumpAndWag(animalRoot: Entity, animalModel: ModelEntity, duration: Float) async {
        let baseRootTransform = animalRoot.transform
        let basePosition = baseRootTransform.translation
        
        // Jump
        await bigJump(animalRoot: animalRoot, duration: 1.0)
        
        // Fast wag (Y oscillations) - combine with base side profile rotation
        let wagAngle: Float = 15.0 * .pi / 180.0
        let baseTransform = animalRoot.transform
        for _ in 0..<Int((duration - 1.0) * 4) {
            var transform = baseTransform
            let wagRotation = simd_quatf(angle: wagAngle, axis: SIMD3(0, 1, 0))
            transform.rotation = combineRotationWithBase(wagRotation)
            await AnimalAnimationHelper.animateTransform(
                entity: animalRoot,
                targetTransform: transform,
                duration: 0.1
            )
            let wagRotationNeg = simd_quatf(angle: -wagAngle, axis: SIMD3(0, 1, 0))
            transform.rotation = combineRotationWithBase(wagRotationNeg)
            await AnimalAnimationHelper.animateTransform(
                entity: animalRoot,
                targetTransform: transform,
                duration: 0.1
            )
        }
        
        // Return to original position and rotation
        var finalTransform = animalRoot.transform
        finalTransform.translation = basePosition
        finalTransform.rotation = baseRootTransform.rotation
        await AnimalAnimationHelper.animateTransform(
            entity: animalRoot,
            targetTransform: finalTransform,
            duration: 0.2
        )
    }
    
    private func jumpFastWagAndHop(animalRoot: Entity, animalModel: ModelEntity, duration: Float) async {
        let baseRootTransform = animalRoot.transform
        let basePosition = baseRootTransform.translation
        
        // Jump + wag
        await jumpAndWag(animalRoot: animalRoot, animalModel: animalModel, duration: 2.0)
        
        // Small hop (in place)
        let hopHeight: Float = 0.05
        let baseTransform = animalRoot.transform
        var transform = baseTransform
        transform.translation = SIMD3<Float>(basePosition.x, basePosition.y + hopHeight, basePosition.z)
        await AnimalAnimationHelper.animateTransform(
            entity: animalRoot,
            targetTransform: transform,
            duration: 0.3
        )
        transform.translation = basePosition
        await AnimalAnimationHelper.animateTransform(
            entity: animalRoot,
            targetTransform: transform,
            duration: 0.3
        )
        
        // Return to original position
        var finalTransform = animalRoot.transform
        finalTransform.translation = basePosition
        finalTransform.rotation = baseRootTransform.rotation
        await AnimalAnimationHelper.animateTransform(
            entity: animalRoot,
            targetTransform: finalTransform,
            duration: 0.2
        )
    }
    
    // Lesson 3 Animations
    private func smallHopAndShrink(animalRoot: Entity, animalModel: ModelEntity, duration: Float) async {
        let hopHeight: Float = 0.05
        let originalScale = animalModel.scale.x
        let baseRootTransform = animalRoot.transform
        let baseModelTransform = animalModel.transform
        let basePosition = baseRootTransform.translation
        
        // Small hop (in place)
        var rootTransform = baseRootTransform
        rootTransform.translation = SIMD3<Float>(basePosition.x, basePosition.y + hopHeight, basePosition.z)
        await AnimalAnimationHelper.animateTransform(
            entity: animalRoot,
            targetTransform: rootTransform,
            duration: TimeInterval(duration * 0.3)
        )
        
        // Shrink scale while in air
        var modelTransform = baseModelTransform
        modelTransform.scale = SIMD3(repeating: originalScale * 0.95)
        await AnimalAnimationHelper.animateTransform(
            entity: animalModel,
            targetTransform: modelTransform,
            duration: TimeInterval(duration * 0.2)
        )
        
        // Come down and scale back
        rootTransform.translation = basePosition
        await AnimalAnimationHelper.animateTransform(
            entity: animalRoot,
            targetTransform: rootTransform,
            duration: TimeInterval(duration * 0.3)
        )
        modelTransform.scale = SIMD3(repeating: originalScale)
        await AnimalAnimationHelper.animateTransform(
            entity: animalModel,
            targetTransform: modelTransform,
            duration: TimeInterval(duration * 0.2)
        )
    }
    
    private func playBounces(animalRoot: Entity, duration: Float) async {
        let bounceHeight: Float = 0.06
        let baseTransform = animalRoot.transform
        let basePosition = baseTransform.translation
        let bounceDuration = TimeInterval(duration / 6.0)
        
        // 3 quick bounces (in place)
        for _ in 0..<3 {
            var transform = baseTransform
            transform.translation = SIMD3<Float>(basePosition.x, basePosition.y + bounceHeight, basePosition.z)
            await AnimalAnimationHelper.animateTransform(
                entity: animalRoot,
                targetTransform: transform,
                duration: bounceDuration
            )
            transform.translation = basePosition
            await AnimalAnimationHelper.animateTransform(
                entity: animalRoot,
                targetTransform: transform,
                duration: bounceDuration
            )
        }
        
        // Return to original position
        var finalTransform = animalRoot.transform
        finalTransform.translation = basePosition
        await AnimalAnimationHelper.animateTransform(
            entity: animalRoot,
            targetTransform: finalTransform,
            duration: 0.2
        )
    }
    
    private func moveForwardAndBounce(animalRoot: Entity, duration: Float) async {
        let forwardDistance: Float = 0.15
        let bounceHeight: Float = 0.08
        let baseTransform = animalRoot.transform
        let basePosition = baseTransform.translation
        
        // Move forward and bounce up
        var transform = baseTransform
        transform.translation = SIMD3<Float>(basePosition.x, basePosition.y + bounceHeight, basePosition.z + forwardDistance)
        await AnimalAnimationHelper.animateTransform(
            entity: animalRoot,
            targetTransform: transform,
            duration: TimeInterval(duration * 0.4)
        )
        
        // Bounce back down
        transform.translation = SIMD3<Float>(basePosition.x, basePosition.y, basePosition.z + forwardDistance)
        await AnimalAnimationHelper.animateTransform(
            entity: animalRoot,
            targetTransform: transform,
            duration: TimeInterval(duration * 0.2)
        )
        
        // Move back to original position
        transform.translation = basePosition
        await AnimalAnimationHelper.animateTransform(
            entity: animalRoot,
            targetTransform: transform,
            duration: TimeInterval(duration * 0.4)
        )
    }
    
    private func moveSpinAndHop(animalRoot: Entity, animalModel: ModelEntity, duration: Float) async {
        let forwardDistance: Float = 0.15
        let hopHeight: Float = 0.08
        let baseTransform = animalRoot.transform
        let basePosition = baseTransform.translation
        
        // Move forward
        var transform = baseTransform
        transform.translation = SIMD3<Float>(basePosition.x, basePosition.y, basePosition.z + forwardDistance)
        await AnimalAnimationHelper.animateTransform(
            entity: animalRoot,
            targetTransform: transform,
            duration: TimeInterval(duration * 0.3)
        )
        
        // 360° spin (on root Y axis) - combine with base side profile rotation
        let spinAngle: Float = 2.0 * .pi
        let spinRotation = simd_quatf(angle: spinAngle, axis: SIMD3(0, 1, 0))
        transform.rotation = combineRotationWithBase(spinRotation)
        await AnimalAnimationHelper.animateTransform(
            entity: animalRoot,
            targetTransform: transform,
            duration: TimeInterval(duration * 0.4)
        )
        
        // Hop
        transform.translation = SIMD3<Float>(basePosition.x, basePosition.y + hopHeight, basePosition.z + forwardDistance)
        await AnimalAnimationHelper.animateTransform(
            entity: animalRoot,
            targetTransform: transform,
            duration: TimeInterval(duration * 0.15)
        )
        transform.translation = SIMD3<Float>(basePosition.x, basePosition.y, basePosition.z + forwardDistance)
        await AnimalAnimationHelper.animateTransform(
            entity: animalRoot,
            targetTransform: transform,
            duration: TimeInterval(duration * 0.15)
        )
        
        // Return to original position and rotation
        transform.translation = basePosition
        transform.rotation = baseTransform.rotation
        await AnimalAnimationHelper.animateTransform(
            entity: animalRoot,
            targetTransform: transform,
            duration: TimeInterval(duration * 0.2)
        )
    }
}

#Preview {
    GameView(animal: "Dog")
}

