import SwiftUI

struct WelcomeView: View {
    @Environment(AppModel.self) private var appModel
    @State private var navigateToAnimalPicker: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient.backgroundGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    Spacer()
                    
                    VStack(spacing: 20) {
                        if let firstName = appModel.child?.firstName {
                            Text("Hi there, \(firstName)!")
                                .pastelTitle()
                                .multilineTextAlignment(.center)
                                .padding(.bottom, 10)
                        }
                        
                        if let welcomeMessage = appModel.welcomeMessage {
                            Text(welcomeMessage)
                                .pastelSubtitle()
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 60)
                                .padding(.bottom, 20)
                        }
                        
                        VStack {
                            Text(animalEmoji)
                                .font(.system(size: 120))
                                .padding(.top, 10)
                            
                            if let unitName = appModel.unitName, let lessonName = appModel.lessonName {
                                VStack(spacing: 8) {
                                    Text(unitName)
                                        .font(.system(size: 32, weight: .semibold, design: .rounded))
                                        .foregroundColor(.lavender)
                                    
                                    Text(lessonName)
                                        .font(.system(size: 28, weight: .medium, design: .rounded))
                                        .foregroundColor(.white.opacity(0.9))
                                }
                            } else if let unitName = appModel.unitName {
                                Text(unitName)
                                    .font(.system(size: 32, weight: .semibold, design: .rounded))
                                    .foregroundColor(.lavender)
                            }
                        }
                        .padding(30)
                        .background(LinearGradient.backgroundGradient)
                        .cornerRadius(20)
                    }
                    
                    Button(action: {
                        navigateToAnimalPicker = true
                    }) {
                        HStack(spacing: 15) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 30))
                            Text("Play")
                                .font(.system(size: 35, weight: .semibold, design: .rounded))
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                    }
                    .buttonStyle(PastelPrimaryButtonStyle())
                    .padding(.horizontal, 40)
                    .padding(.bottom, 60)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationDestination(isPresented: $navigateToAnimalPicker) {
                AnimalPickerView()
            }
        }
    }
    
    private var animalEmoji: String {
        guard let preference = appModel.child?.animalPreference?.lowercased() else {
            return "⭐"
        }
        
        switch preference {
        case "cat":
            return "🐱"
        case "dog":
            return "🐶"
        case "horse":
            return "🐴"
        default:
            return "⭐"
        }
    }
}

@MainActor
private func makePreviewModel() -> AppModel {
    let model = AppModel()
    model.child = Child(
        id: "1",
        shortId: "ABC123",
        firstName: "Liam",
        lastName: "Martinez",
        animalPreference: "cat",
        currentPath: nil
    )
    model.welcomeMessage = "Welcome back! Today's lesson is..."
    model.unitName = "My Animal Friend"
    model.lessonName = "Basic Actions"
    return model
}

#Preview(windowStyle: .automatic) {
    WelcomeView()
        .environment(makePreviewModel())
}

