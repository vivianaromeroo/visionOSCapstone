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
            VStack(spacing: 30) {
                // Title
                Text("Login")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.primary)
                    .padding(.top, 60)
                
                Spacer()
                
                // Input fields
                VStack(spacing: 25) {
                    // First field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Enter Numbers")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.secondary)
                        
                        TextField("", text: $field1)
                            .textFieldStyle(.plain)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .keyboardType(.numberPad)
                            .focused($focusedField, equals: .field1)
                            .frame(height: 60)
                            .font(.system(size: 24))
                    }
                    
                    // Second field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Enter Numbers")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.secondary)
                        
                        TextField("", text: $field2)
                            .textFieldStyle(.plain)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .keyboardType(.numberPad)
                            .focused($focusedField, equals: .field2)
                            .frame(height: 60)
                            .font(.system(size: 24))
                    }
                }
                .padding(.horizontal, 40)
                
                // Login button
                Button(action: handleLogin) {
                    Text("Login")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(canLogin ? Color.accentColor : Color.gray)
                        .cornerRadius(12)
                        .disabled(!canLogin)
                }
                .padding(.horizontal, 40)
                .padding(.top, 20)
                
                Spacer()
                
                // Status message
                if !field1.isEmpty || !field2.isEmpty {
                    Text("Enter numbers to login")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .padding(.bottom, 40)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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

