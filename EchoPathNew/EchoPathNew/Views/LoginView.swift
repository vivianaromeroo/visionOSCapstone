//
//  LoginView.swift
//  EchoPathNew
//
//  Created by Admin2  on 4/28/25.
//

import SwiftUI

struct LoginView: View {
    @State private var field1: String = ""
    @State private var field2: Date = Date()
    @State private var isAuthenticated: Bool = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case field1
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
                    .padding(.bottom, 20)
                    
                    // Input fields in pastel card
                    VStack(spacing: 25) {
                        // First field
                        VStack(alignment: .center, spacing: 12) {
                            Text("Enter Child's ID")
                                .font(.system(size: 35, weight: .semibold, design: .rounded))
                                .foregroundColor(.lavender)
                                .padding(.bottom, 5)
                            
                            TextField("", text: $field1)
                                .textFieldStyle(PastelTextFieldStyle())
                                .keyboardType(.numberPad)
                                .focused($focusedField, equals: .field1)
                                .foregroundColor(.black)
                                .frame(width: 350, height: 70)
                                .font(.system(size: 30, design: .rounded))
                                .padding(.bottom, 10)
                        }
                        
                        // Second field
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
                    
                    // Login button
                    Button(action: handleLogin) {
                        Text("Login")
                            .frame(maxWidth: .infinity)
                            .disabled(!canLogin)
                            .font(.system(size: 35))
                    }
                    .buttonStyle(PastelPrimaryButtonStyle())
                    .padding(.horizontal, 40)
                    .padding(.top, 20)
                    
                    Spacer()
                    
                    // Status message
                    if !field1.isEmpty {
                        Text("Enter ID and select date to login")
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
        !field1.isEmpty
    }
    
    private func handleLogin() {
        // Handle login logic here
        // Navigate to AnimalPickerView
        // You can add actual authentication logic here later
        isAuthenticated = true
    }
}

#Preview(windowStyle: .automatic) {
    LoginView()
}

