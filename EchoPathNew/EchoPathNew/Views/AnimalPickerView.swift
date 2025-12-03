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
            VStack(spacing: 20) {
                Text("What is your favorite animal?")
                    .font(.extraLargeTitle2)
                    .padding()
                
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
                .frame(width: 200, height: 350)
                
                Picker("Animal", selection: $selectedAnimal) {
                    ForEach(animals, id: \.self) { animal in
                        Text(animal)
                            .font(.largeTitle)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                .frame(height: 60)
                
                NavigationLink(destination: GameView(animal: selectedAnimal)) {
                    Text("Continue")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
            }
            .padding()
            .cornerRadius(20)
        }
        .onDisappear {
            spinningTimer?.invalidate()
        }
    }
    
    func loadModel(named name: String) async {
        rootEntity.children.removeAll()
        
        do {
            let modelEntity = try await ModelEntity(named: "\(name).usdz")
            
            modelEntity.position = SIMD3(0, -0.1, -0.1)
            let bounds = modelEntity.visualBounds(relativeTo: nil)
            let maxDimension = max(bounds.extents.x, bounds.extents.y, bounds.extents.z)
            let scaleFactor = 0.15 / maxDimension
            modelEntity.scale = SIMD3(repeating: scaleFactor)
            
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

