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
    @Environment(\.dismiss) private var dismiss
    
    init(animal: String) {
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
                setupScene(content: content)
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
                    lessonName: engine.lessonNames[completedLessonIndex],
                    hasNextLesson: hasNextLessonAvailable,
                    onContinue: {
                        showLessonComplete = false
                        engine.nextLevel()
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
            sceneUpdateTrigger += 1
        }
        .onChange(of: engine.droppedWords) { _, _ in
            sceneUpdateTrigger += 1
        }
        .onChange(of: engine.currentStep) { _, _ in
            updateSlotAppearance()
        }
    }
    
    // MARK: - Navigation Handlers
    private func handleNextButton() {
        // Check if we're completing a lesson (on last level of current lesson)
        if engine.isLastLevelInLesson {
            // Show lesson completion screen
            completedLessonIndex = engine.currentLesson
            // Check if there's a next lesson available (not the last lesson in unit)
            hasNextLessonAvailable = !engine.isLastLessonInUnit
            showLessonComplete = true
        } else {
            // Just moving to next level within the same lesson
            engine.nextLevel()
            sceneUpdateTrigger += 1
        }
    }
    
    private func handleSkipLevel() {
        // Check if we're completing a lesson (on last level of current lesson)
        if engine.isLastLevelInLesson {
            // Show lesson completion screen
            completedLessonIndex = engine.currentLesson
            // Check if there's a next lesson available (not the last lesson in unit)
            hasNextLessonAvailable = !engine.isLastLessonInUnit
            showLessonComplete = true
        } else {
            // Just moving to next level within the same lesson
            engine.nextLevel()
            sceneUpdateTrigger += 1
        }
    }
    
    // MARK: - Scene Setup
    private func setupScene(content: RealityViewContent) {
        // Clear existing entities
        content.entities.removeAll()
        wordEntities.removeAll()
        slotEntities.removeAll()
        
        // Create slot entities (drop targets) - arranged in a grid (max 4 per row)
        let slotsPerRow: Int = 4
        let slotSpacingX: Float = 0.15
        let slotSpacingY: Float = -0.08  // Vertical spacing between rows
        let totalSlots = engine.currentSentence.count
        
        for (index, _) in engine.currentSentence.enumerated() {
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
        let wordSpacing: Float = 0.12
        let wordStartX: Float = -Float(engine.availableWords.count - 1) * wordSpacing / 2
        
        for (wordIndex, word) in engine.availableWords.enumerated() {
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
    
    // MARK: - Entity Creation
    private func createSlotEntity(index: Int) -> Entity {
        let parent = Entity()
        parent.name = "Slot_\(index)"
        
        // Create box for slot - all slots have the same color
        let boxMesh = MeshResource.generateBox(size: [0.12, 0.06, 0.01])
        let slotColor: UIColor = Color.lavender.uiColor
        let material = SimpleMaterial(color: slotColor.withAlphaComponent(0.7), isMetallic: false)
        let box = ModelEntity(mesh: boxMesh, materials: [material])
        box.generateCollisionShapes(recursive: true)
        box.components.set(InputTargetComponent(allowedInputTypes: .indirect))
        box.name = "SlotBox_\(index)"
        
        // Add white outline for active slot
        let isActive = index == engine.currentStep
        if isActive {
            let outlineMesh = MeshResource.generateBox(size: [0.125, 0.065, 0.011]) // Slightly larger
            let outlineMaterial = SimpleMaterial(color: .white, isMetallic: false)
            let outlineBox = ModelEntity(mesh: outlineMesh, materials: [outlineMaterial])
            outlineBox.position = SIMD3<Float>(0, 0, -0.0005) // Behind the main box
            outlineBox.name = "SlotOutline_\(index)"
            parent.addChild(outlineBox)
        }
        
        // Create text for slot (only show word if dropped, no hints)
        if let droppedWord = engine.droppedWords[index] {
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
        
        // Check if dropped near any slot
        // Use a common coordinate space - the entity's parent or the entity itself
        let coordinateSpace = draggedEntity.parent ?? draggedEntity
        let dragPosition = value.convert(value.location3D, from: .local, to: coordinateSpace)
        var wasDropped = false
        
        for (index, slotEntity) in slotEntities {
            let slotPosition = slotEntity.position(relativeTo: coordinateSpace)
            
            let distance = length(dragPosition - slotPosition)
            let threshold: Float = 0.15 // Distance threshold for "dropped on"
            
            if distance < threshold {
                // Word is dropped on this slot
                let wasInAvailable = engine.availableWords.contains(word)
                engine.handleDrop(word, at: index)
                // If word was correctly placed, it will be removed from availableWords
                if !engine.availableWords.contains(word) && wasInAvailable {
                    // Remove word entity from scene immediately
                    draggedEntity.removeFromParent()
                    wordEntities.removeValue(forKey: word)
                }
                wasDropped = true
                sceneUpdateTrigger += 1
                break
            }
        }
        
        // If not dropped on a slot, return to original position
        if !wasDropped, let originalPos = originalPosition {
            draggedEntity.position = originalPos
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
        // Update slot outlines and text based on current step and dropped words
        for (index, slotEntity) in slotEntities {
            let isActive = index == engine.currentStep
            
            // Update outline - add or remove white outline for active slot
            let outlineName = "SlotOutline_\(index)"
            if let existingOutline = slotEntity.children.first(where: { $0.name == outlineName }) {
                if !isActive {
                    // Remove outline if slot is no longer active
                    existingOutline.removeFromParent()
                }
            } else if isActive {
                // Add outline if slot is now active
                let outlineMesh = MeshResource.generateBox(size: [0.125, 0.065, 0.011])
                let outlineMaterial = SimpleMaterial(color: .white, isMetallic: false)
                let outlineBox = ModelEntity(mesh: outlineMesh, materials: [outlineMaterial])
                outlineBox.position = SIMD3<Float>(0, 0, -0.0005)
                outlineBox.name = outlineName
                slotEntity.addChild(outlineBox)
            }
            
            // Keep box color consistent (no color change based on active state)
            if let box = slotEntity.children.first(where: { $0.name == "SlotBox_\(index)" }) as? ModelEntity {
                let slotColor: UIColor = Color.lavender.uiColor
                let material = SimpleMaterial(color: slotColor.withAlphaComponent(0.4), isMetallic: false)
                box.model?.materials = [material]
            }
            
            // Update text - only show if word is dropped
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
}

#Preview {
    GameView(animal: "Dog")
}

