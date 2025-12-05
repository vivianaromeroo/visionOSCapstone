import Foundation
import SwiftUI
import UniformTypeIdentifiers
import RealityKit
import RealityKitContent

struct AnimalPickerView: View {
    @Environment(AppModel.self) private var appModel
    @State private var selectedAnimal: String = "Dog"
    let animals = ["Dog", "Cat", "Horse"]
    @State private var modelEntity: ModelEntity?
    
    @State private var rotationAngle: Float = 0
    @State private var rootEntity = Entity()
    @State private var spinningTimer: Timer?

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient.backgroundGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 25) {
                    Text("What is your favorite animal?")
                        .pastelTitle()
                        .multilineTextAlignment(.center)
                    
                    Spacer()
                    
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
                    .frame(width: 450, height: 300)
                    .cornerRadius(30)
                    
                    Picker("Animal", selection: $selectedAnimal) {
                        ForEach(animals, id: \.self) { animal in
                            Text(animal)
                                .font(.system(size: 30, weight: .semibold, design: .rounded))
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)
                    .frame(height: 50)
                    .cornerRadius(25)
                    
                    NavigationLink(destination: destinationView) {
                        Text("Continue")
                            .frame(maxWidth: .infinity)
                            .font(.system(size: 35))
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
            
            let bounds = modelEntity.visualBounds(relativeTo: nil)
            let maxDimension = max(bounds.extents.x, bounds.extents.y, bounds.extents.z)
            let scaleFactor = 0.15 / maxDimension
            modelEntity.scale = SIMD3(repeating: scaleFactor)
            
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
    
    @ViewBuilder
    private var destinationView: some View {
        if appModel.showTutorial {
            TutorialView(animal: selectedAnimal)
        } else {
            GameView(animal: selectedAnimal)
        }
    }
}

@MainActor
private func makePreviewModel() -> AppModel {
    let model = AppModel()
    model.showTutorial = true
    return model
}

#Preview {
    AnimalPickerView()
        .environment(makePreviewModel())
}

