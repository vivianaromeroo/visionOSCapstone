//
//  AnimalPickerView.swift
//  EchoPathNew
//
//  Created by Admin2  on 4/22/25.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers
import RealityKit
import RealityKitContent

struct AnimalPickerView: View {
    @State private var selectedAnimal: String = "Dog"
    let animals = ["Dog", "Cat", "Horse"]
    @State private var modelEntity: ModelEntity?
    
    @State private var rotationAngle: Float = 0
    @State private var rootEntity = Entity()
    @State private var spinningTimer: Timer?

    var body: some View {
        NavigationStack {
            ZStack {
                // Soft gradient background
                LinearGradient.backgroundGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 25) {
                    // Title with puzzle pieces
                    Text("What is your favorite animal?")
                        .pastelTitle()
                        .multilineTextAlignment(.center)
                        .padding(.top, 20)
                    
                    Spacer()
                    
                    // 3D Model in card
                    RealityView { content in
                        content.add(rootEntity)
                        
                        Task {
                            await loadModel(named: selectedAnimal)
                            startSpinning()
                        }
                    } update: { [selectedAnimal] content in
                        Task {
                            await loadModel(named: selectedAnimal)
                        }
                    }
                    .frame(width: 450, height: 350)
                    .cornerRadius(30)
                    .overlay(
                        RoundedRectangle(cornerRadius: 30)
                            .stroke(Color.red, lineWidth: 3)
                    )
                    
                    // Picker styled
                    Picker("Animal", selection: $selectedAnimal) {
                        ForEach(animals, id: \.self) { animal in
                            Text(animal)
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)
                    .frame(height: 50)
                    .cornerRadius(25)
                    
                    // Continue button
                    NavigationLink(destination: GameView(animal: selectedAnimal)) {
                        Text("Continue")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PastelPrimaryButtonStyle())
                    .padding(.horizontal, 40)
                    
                    Spacer()
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 20)
            }
        }
        .onDisappear {
            spinningTimer?.invalidate()
        }
    }
    
    func loadModel(named name: String) async {
        rootEntity.children.removeAll()
        
        do {
            let modelEntity = try await ModelEntity(named: "\(name).usdz")
            
            // 1. Scale to a reasonable size
            let bounds = modelEntity.visualBounds(relativeTo: nil)
            let maxDimension = max(bounds.extents.x, bounds.extents.y, bounds.extents.z)
            let scaleFactor = 0.15 / maxDimension
            modelEntity.scale = SIMD3(repeating: scaleFactor)
            
            // 2. Recenter the model so its center is at (0,0,0),
            //    then nudge it upward slightly so it appears higher in the card
            let centeredY: Float = -bounds.center.y * scaleFactor + 0
            
            modelEntity.position = SIMD3(
                -bounds.center.x * scaleFactor,
                centeredY,
                -bounds.center.z * scaleFactor
            )
            
            rootEntity.addChild(modelEntity)
        } catch {
            print("❌ MODEL LOADING ERROR: \(error)")
        }
    }

    func startSpinning() {
        spinningTimer?.invalidate()
        
        spinningTimer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { _ in
            rotationAngle += 0.02
            rootEntity.transform.rotation = simd_quatf(angle: rotationAngle, axis: SIMD3(0, 1, 0))
        }
    }
}

#Preview {
    AnimalPickerView()
}

