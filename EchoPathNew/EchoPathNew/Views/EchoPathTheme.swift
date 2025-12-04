//
//  EchoPathTheme.swift
//  EchoPathNew
//
//  Centralized design system matching the title screen aesthetic
//

import SwiftUI
import UIKit

// MARK: - Color Palette Extension
extension Color {
    static let pastelBlue = Color(hex: "9CCBFF")
    static let pastelPink = Color(hex: "FFB6D9")
    static let pastelPurple = Color(hex: "A88CFF")
    static let lavender = Color(hex: "D8C8FF")
    static let skyBlue = Color(hex: "B7E3FF")
    static let warmPink = Color(hex: "FF8DB5")
    static let neutralBackground = Color(hex: "F8F8F8")
    
    // Helper initializer for hex colors
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    // Helper to convert SwiftUI Color to UIColor for RealityKit
    var uiColor: UIColor {
        UIColor(self)
    }
}

// MARK: - Gradients
extension LinearGradient {
    static let primaryGradient = LinearGradient(
        colors: [Color.pastelBlue, Color.pastelPurple],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let secondaryGradient = LinearGradient(
        colors: [Color.pastelPink, Color.pastelPurple],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let backgroundGradient = LinearGradient(
        colors: [Color.skyBlue.opacity(0.3), Color.lavender.opacity(0.3)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Custom Button Styles
struct PastelPrimaryButtonStyle: ButtonStyle {
    var isEnabled: Bool = true
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 20, weight: .semibold, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 30)
            .padding(.vertical, 15)
            .background(
                Group {
                    if isEnabled {
                        LinearGradient.primaryGradient
                    } else {
                        LinearGradient(colors: [Color.gray.opacity(0.5)], startPoint: .leading, endPoint: .trailing)
                    }
                }
            )
            .cornerRadius(28)
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct PastelSecondaryButtonStyle: ButtonStyle {
    var color: Color = .pastelBlue
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 18, weight: .medium, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 25)
            .padding(.vertical, 12)
            .background(color)
            .cornerRadius(25)
            .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Card Modifier
struct PastelCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 25
    
    func body(content: Content) -> some View {
        content
            .padding(25)
            .background(Color.neutralBackground.opacity(0.8))
            .cornerRadius(cornerRadius)
            .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
    }
}

extension View {
    func pastelCard(cornerRadius: CGFloat = 25) -> some View {
        modifier(PastelCardModifier(cornerRadius: cornerRadius))
    }
}

// MARK: - Text Styles
extension Text {
    func pastelTitle() -> some View {
        self
            .font(.system(size: 66, weight: .bold, design: .rounded))
            .foregroundColor(.white)
    }
    
    func pastelSubtitle() -> some View {
        self
            .font(.system(size: 35, weight: .semibold, design: .rounded))
            .foregroundColor(.white.opacity(0.8))
    }
    
    func pastelBody() -> some View {
        self
            .font(.system(size: 16, weight: .regular, design: .rounded))
            .foregroundColor(.gray.opacity(0.7))
    }
}

// MARK: - Input Field Style
struct PastelTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(15)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.pastelPurple.opacity(0.3), lineWidth: 2)
            )
    }
}
