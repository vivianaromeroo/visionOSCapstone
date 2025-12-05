import SwiftUI

struct LoginView: View {
    @Environment(AppModel.self) private var appModel
    @State private var field1: String = ""
    @State private var field2: Date = Date()
    @State private var isAuthenticated: Bool = false
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var showTutorial: Bool = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case field1
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient.backgroundGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    HStack(spacing: 15) {
                        Text("Login")
                            .pastelTitle()
                    }
                    .padding(.bottom, 10)
                    
                    VStack(spacing: 25) {
                        VStack(alignment: .center, spacing: 12) {
                            Text("Enter Child's ID")
                                .font(.system(size: 35, weight: .semibold, design: .rounded))
                                .foregroundColor(.lavender)
                                .padding(.bottom, 5)
                            
                            TextField("", text: $field1)
                                .textFieldStyle(PastelTextFieldStyle())
                                .keyboardType(.default)
                                .autocapitalization(.allCharacters)
                                .focused($focusedField, equals: .field1)
                                .foregroundColor(.black)
                                .frame(width: 350, height: 70)
                                .font(.system(size: 30, design: .rounded))
                                .padding(.bottom, 10)
                        }
                        
                        VStack(alignment: .center, spacing: 12) {
                            Text("Enter Child's Date of Birth")
                                .font(.system(size: 35, weight: .semibold, design: .rounded))
                                .foregroundColor(.lavender)
                                .padding(.bottom, 5)
                            
                            DatePicker("", selection: $field2, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .frame(height: 70)
                                .font(.system(size: 30, design: .rounded))
                                .scaleEffect(1.6)
                                .accentColor(.white)
                        }
                    }
                    .padding(.horizontal, 40)
                    
                    Toggle(isOn: $showTutorial) {
                        Text("Play tutorial")
                            .font(.system(size: 28, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .pastelPurple))
                    .padding(.horizontal, 525)
                    .padding(.top, 10)
                    
                    Button(action: handleLogin) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Login")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .disabled(!canLogin || isLoading)
                        .font(.system(size: 35))
                    }
                    .buttonStyle(PastelPrimaryButtonStyle())
                    .padding(.horizontal, 40)
                    .padding(.top, 10)
                    
                    Spacer()
                    
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .pastelBody()
                            .foregroundColor(.red)
                            .padding(.bottom, 40)
                    } else if !field1.isEmpty && !isLoading {
                        Text("Enter ID and select date to login")
                            .pastelBody()
                            .padding(.bottom, 40)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationDestination(isPresented: $isAuthenticated) {
                WelcomeView()
            }
        }
    }
    
    private var canLogin: Bool {
        !field1.isEmpty
    }
    
    private func handleLogin() {
        errorMessage = nil
        isLoading = true
        
        Task {
            do {
                let response = try await AuthService.shared.login(
                    shortId: field1.trimmingCharacters(in: .whitespacesAndNewlines),
                    dateOfBirth: field2
                )
                
                appModel.child = response.child
                appModel.preferences = response.preferences
                appModel.welcomeMessage = "Welcome back! Today's lesson is..."
                appModel.unitName = "My Animal Friend"
                appModel.lessonName = "Basic Actions"
                appModel.showTutorial = showTutorial
                
                await MainActor.run {
                    isLoading = false
                    isAuthenticated = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    if let authError = error as? AuthError {
                        errorMessage = authError.errorDescription ?? "Login failed"
                    } else {
                        errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }
}

#Preview(windowStyle: .automatic) {
    LoginView()
        .environment(AppModel())
}

