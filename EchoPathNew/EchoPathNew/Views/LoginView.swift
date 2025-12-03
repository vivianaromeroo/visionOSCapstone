//
//  LoginView.swift
//  EchoPathNew
//
//  Created by Admin2  on 4/28/25.
//

import SwiftUI

struct LoginView: View {
    @State private var field1: String = ""
    @State private var field2: String = ""
    @State private var isAuthenticated: Bool = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case field1
        case field2
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Soft gradient background
                LinearGradient.backgroundGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // Title with puzzle piece accent
                    HStack(spacing: 15) {
                        Text("Login")
                            .pastelTitle()
                    }
                    .padding(.top, 60)
                    
                    Spacer()
                    
                    // Input fields in pastel card
                    VStack(spacing: 25) {
                        // First field
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Enter Numbers")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundColor(.pastelPurple)
                            
                            TextField("", text: $field1)
                                .textFieldStyle(PastelTextFieldStyle())
                                .keyboardType(.numberPad)
                                .focused($focusedField, equals: .field1)
                                .frame(height: 60)
                                .font(.system(size: 20, design: .rounded))
                        }
                        
                        // Second field
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Enter Numbers")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundColor(.pastelPurple)
                            
                            TextField("", text: $field2)
                                .textFieldStyle(PastelTextFieldStyle())
                                .keyboardType(.numberPad)
                                .focused($focusedField, equals: .field2)
                                .frame(height: 60)
                                .font(.system(size: 20, design: .rounded))
                        }
                    }
                    .padding(.horizontal, 40)
                    
                    // Login button
                    Button(action: handleLogin) {
                        Text("Login")
                            .frame(maxWidth: .infinity)
                            .disabled(!canLogin)
                    }
                    .buttonStyle(PastelPrimaryButtonStyle(isEnabled: canLogin))
                    .padding(.horizontal, 40)
                    .padding(.top, 10)
                    
                    Spacer()
                    
                    // Status message
                    if !field1.isEmpty || !field2.isEmpty {
                        Text("Enter numbers to login")
                            .pastelBody()
                            .padding(.bottom, 40)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationDestination(isPresented: $isAuthenticated) {
                AnimalPickerView()
            }
        }
    }
    
    private var canLogin: Bool {
        !field1.isEmpty && !field2.isEmpty
    }
    
    private func handleLogin() {
        // Handle login logic here
        print("Field 1: \(field1)")
        print("Field 2: \(field2)")
        
        // Navigate to AnimalPickerView
        // You can add actual authentication logic here later
        isAuthenticated = true
    }
}

#Preview(windowStyle: .automatic) {
    LoginView()
}

